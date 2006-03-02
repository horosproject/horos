/*
 * huffcoptimisebug.c --
 *
 * Code for JPEG lossless encoding.  Many parts are grabbed from the IJG
 * software, so:
 *
 * Copyright (C) 1991, 1992, Thomas G. Lane.
 * Part of the Independent JPEG Group's software.
 * See the file Copyright for more details.
 *
 * Copyright (c) 1993 Brian C. Smith, The Regents of the University
 * of California
 * All rights reserved.
 * 
 * Copyright (c) 1994 Kongji Huang and Brian C. Smith.
 * Cornell University
 * All rights reserved.
 * 
 * Copyright (c) 1997 OSIRIS Team. Digital Imaging Unit
 * University Hospital of Geneva
 * changes made by David Bandon
 * All rights reserved
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CORNELL UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF CORNELL
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * CORNELL UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND CORNELL UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "jpeg.h"
#include "mcu.h"
#include "io.h"
#include "proto.h"
#include "predict.h"
#include "jpegless.h"


/* Papyrus 3 redefined basic types */
#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#ifndef PapyEalloc3H
#include "PapyEalloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapyFileSystem3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PapyDef3.h"
#endif

#ifndef PapyEalloc3H
#include "Papaloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapFSys3.h"
#endif

#endif 				/* FILENAME83 defined */


#define RST0	0xD0		/* RST0 marker code */
#define	MIN_BUF_FREE	512	/* Min Buffer free for EncodeOneBlock */
#define NUM_HUFF_TBLS 4		/* Max # of Huffman tables can be */
				/* used in one scan. */

/*
 * Lookup table for number of bits is a 8 bit value.  Initialized
 * in HuffEncoderInit.
 */
int numBitsTable [256];

static int bmask[] = {0x0000,
	 0x00000001, 0x00000003, 0x00000007, 0x0000000F,
	 0x0000001F, 0x0000003F, 0x0000007F, 0x000000FF,
	 0x000001FF, 0x000003FF, 0x000007FF, 0x00000FFF,
	 0x00001FFF, 0x00003FFF, 0x00007FFF, 0x0000FFFF,
	 0x0001FFFF, 0x0003FFFF, 0x0007FFFF, 0x000FFFFF,
	 0x001FFFFF, 0x003FFFFF, 0x007FFFFF, 0x00FFFFFF,
	 0x01FFFFFF, 0x03FFFFFF, 0x07FFFFFF, 0x0FFFFFFF,
	 0x1FFFFFFF, 0x3FFFFFFF, 0x7FFFFFFF, 0xFFFFFFFF};

/*
 * Static variables for output buffering.
 */
static int huffPutBuffer;		/* current bit-accumulation buffer */
static int huffPutBits;			/* # of bits now in it             */

/*
 * Global variables for output buffering.
 */

PapyUChar outputBuffer[JPEG_BUF_SIZE];	
PapyULong numOutputBytes;                     /* bytes in the output buffer      */

/*
 * Static varible to count the times each category symbol occurs. 
 * Array freqCountPtrs[i][tblNo] is the frequency table of PSV (i-1) 
 * to build the Huffman table tblNo.
 */
static long *freqCountPtrs[7][NUM_HUFF_TBLS];

/*
 *--------------------------------------------------------------
 *
 * FlushBytes --
 *
 *	Output the bytes we've accumulated so far to the output
 *	file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The numOutputBytes is reset.
 *
 *--------------------------------------------------------------
 */
void 
FlushBytes ()
{
    if (numOutputBytes)
	WriteJpegData ((PapyUChar *)outputBuffer, numOutputBytes);
    numOutputBytes = 0L;
}

/*
 *--------------------------------------------------------------
 *
 * EmitByteNoFlush --
 *
 *	Write a single byte out to the output buffer.
 *	Assumes the caller is checking for flushing the buffer.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The output buffer may get flushed.
 *
 *--------------------------------------------------------------
 */
#define EmitByteNoFlush(val)  {									\
    if (numOutputBytes >= JPEG_BUF_SIZE)						\
       FlushBytes();		  									\
    outputBuffer[numOutputBytes++] = (PapyUChar)(val);				\
}

/*
 *--------------------------------------------------------------
 *
 * EmitBits --
 *
 *	Code for outputting bits to the file
 *
 *	Only the right 24 bits of huffPutBuffer are used; the valid
 *	bits are left-justified in this part.  At most 16 bits can be
 *	passed to EmitBits in one call, and we never retain more than 7
 *	bits in huffPutBuffer between calls, so 24 bits are
 *	sufficient.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	huffPutBuffer and huffPutBits are updated.
 *
 *--------------------------------------------------------------
 */
#define EmitBits(code,size) {										\
    int putBuffer;													\
    int putBits;													\
    /*																\
     * if size is 0, caller used an invalid Huffman table entry		\
     */																\
    assert (size != 0);												\
    /*																\
     * Mask off any excess bits in code.							\
     */																\
    putBits = (size);												\
    putBuffer = ((code) & bmask[putBits]);							\
    putBits += huffPutBits;											\
    putBuffer <<= 24 - putBits;										\
    putBuffer |= huffPutBuffer;										\
    while (putBits >= 8) {											\
	int c;															\
	c = (putBuffer >> 16) & 0xFF;									\
	/*																\
	 * Output whole bytes we've accumulated with byte stuffing		\
	 */																\
	EmitByteNoFlush (c);											\
	if (c == 0xFF) {												\
	    EmitByteNoFlush (0);										\
	}																\
	putBuffer <<= 8;												\
	putBits -= 8;													\
    }																\
    /*																\
     * Update global variables										\
     */																\
    huffPutBuffer = putBuffer;										\
    huffPutBits = putBits;											\
}

/*
 *--------------------------------------------------------------
 *
 * FlushBits --
 *
 *	Flush any remaining bits in the bit buffer. Used before emitting
 *	a marker.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	huffPutBuffer and huffPutBits are reset
 *
 *--------------------------------------------------------------
 */
static void 
FlushBits ()
{
    /*
     * The first call forces output of any partial bytes.
     * We can then zero the buffer.
     */
    EmitBits((Ushort) 0x7F,7);
    huffPutBuffer = 0;
    huffPutBits = 0;
}

/*
 *--------------------------------------------------------------
 *
 * EncodeOneDiff --
 *
 *	Encode a single difference value.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
#define EncodeOneDiff(diff,dctbl) {													\
    register int temp, temp2;														\
    register short nbits;															\
    int bMagCat16;                                           \
    /*																				\
     * Encode the DC coefficient difference per section F.1.2.1						\
     */																				\
    temp = temp2 = diff;															\
    if (temp < 0) {																	\
	temp = -temp;																	\
	/*																				\
	 * For a negative input, want temp2 = bitwise complement of						\
	 * abs(input).  This code assumes we are on a two's complement					\
	 * machine.																		\
	 */																				\
	temp2--;																		\
    }																				\
    /*																				\
     * Find the number of bits needed for the magnitude of the coefficient			\
     */																				\
    nbits=0;																		\
    if (temp) {																		\
	while (temp >= 256) {															\
            nbits += 8;																\
	    temp >>= 8;																	\
	}																				\
        nbits += numBitsTable[temp&0xff];											\
    }																				\
    /*																				\
     * Emit the Huffman-coded symbol for the number of bits							\
     */																				\
    EmitBits(dctbl->ehufco[nbits],dctbl->ehufsi[nbits]);							\
    /* TCC special case for regular magnitude category 16     \
     * if the huffman code is 8 bits or less, and the difference    \
     * magnitude is 16 bits, we know that this is a regular magnitude     \
     * category 16 code, and not a special >8bit one that handles     \
     * large negative numbers                                         \
     */                                         \
    bMagCat16 = (nbits == 16) && !(dctbl->ehufco[nbits] & 0xff00) &&  \
                     (dctbl->ehufsi[nbits] < 9);               \
     \
     /*																				\
     * Emit that number of bits of the value, if positive,							\
     * or the complement of its magnitude, if negative.								\
     */																				\
    if (nbits && !bMagCat16)             \
      EmitBits ((Ushort) temp2, nbits);    \
}

/*
 *--------------------------------------------------------------
 *
 * HuffEncoderInit --
 *
 *	Initialize for a Huffman-compressed scan.
 *
 * Results:
 *	None
 *
 * Side effects:
 *	None
 *
 *--------------------------------------------------------------
 */
void 
HuffEncoderInit (CompressInfo *cPtr)
{
    short i, nbits, temp;
    /*JpegComponentInfo *compptr;*/

    /*
     * Initialize static variables
     */
    huffPutBuffer = 0;
    huffPutBits   = 0;

    /*
     * Initialize the output buffer
     */
    numOutputBytes = 0L;

    /*
     * Initialize restart stuff
     */
    cPtr->restartRowsToGo = cPtr->restartInRows;
    cPtr->nextRestartNum  = 0;
    
    /*
     * Initialize number of bits lookup table.
     */
    for (i = 0; i < 256; i++) 
    {
	  temp = i;
	  nbits = 1;
	  while (temp >>= 1) 
	  {
	    nbits++;
	  }
	  numBitsTable [i] = nbits;
    } /* for */ 

} /* endof function HuffEncoderInit */


/*
 *--------------------------------------------------------------
 *
 * EmitRestart --
 *
 *	Emit a restart marker & resynchronize predictions.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Any remaining bits are flushed.
 *
 *--------------------------------------------------------------
 */
static void 
EmitRestart (CompressInfo *cPtr)
{

    FlushBits ();

    EmitByteNoFlush (0xFF);
    EmitByteNoFlush (RST0 + cPtr->nextRestartNum);

    /*
     * Update restart state
     */
    cPtr->restartRowsToGo = cPtr->restartInRows;
    cPtr->nextRestartNum++;
    cPtr->nextRestartNum &= 7;
}

/*
 *--------------------------------------------------------------
 *
 * EncodeFirstRow --
 *
 *     Encode the first raster line of samples at the start of
 *     the scan and at the beginning of each restart interval.  
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
void
EncodeFirstRow(CompressInfo *cPtr, PapyUShort *ImageIn)
{
    register short curComp,ci;
    register int col,compsInScan,numCOL;
    register JpegComponentInfo *compptr;
    int Pr,Pt,diff;
    PapyUChar *ImageIn8b;

    Pr=cPtr->dataPrecision;
    Pt=cPtr->Pt;
    compsInScan=cPtr->compsInScan;
    numCOL=cPtr->imageWidth;
    
    if (cPtr->dataPrecision == 8) ImageIn8b = (Uchar *) ImageIn;
    
    if (cPtr->dataPrecision == 8) {
    /*
     * At the start of the scan or at the beginning of restart interval,
     * 1<<(Pr-Pt-1) is the predictor.
     */
    	for (curComp = 0; curComp < compsInScan; curComp++) {
      		 ci = cPtr->MCUmembership[curComp];
       		 compptr = cPtr->curCompInfo[ci];
       		 diff = ImageIn8b[0] - (1<<(Pr-Pt-1));
       		 EncodeOneDiff(diff,cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
   		 }

    /*
     * In rest of the first row, left neighboring pixel is the predictor. 
     */
    	for (col=1; col<numCOL; col++) {
       		 for (curComp = 0; curComp < compsInScan; curComp++) {
        	    ci = cPtr->MCUmembership[curComp];
        	    compptr = cPtr->curCompInfo[ci];

       		     diff = ImageIn8b[col]-ImageIn8b[col-1];
         		 EncodeOneDiff (diff, cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
       		 }
 	     }

    	if (cPtr->restartInRows) {
       cPtr->restartRowsToGo--;
   	 	}
    }
    else { /* 16 bits */
    	for (curComp = 0; curComp < compsInScan; curComp++) {
        ci = cPtr->MCUmembership[curComp];
        compptr = cPtr->curCompInfo[ci];
        diff = ImageIn[0] - (1<<(Pr-Pt-1));
        EncodeOneDiff(diff,cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
    }

    /*
     * In rest of the first row, left neighboring pixel is the predictor. 
     */
    for (col=1; col<numCOL; col++) {
        for (curComp = 0; curComp < compsInScan; curComp++) {
            ci = cPtr->MCUmembership[curComp];
            compptr = cPtr->curCompInfo[ci];

            diff = ImageIn[col]-ImageIn[col-1];
            EncodeOneDiff (diff, cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
        }
    }

    if (cPtr->restartInRows) {
       cPtr->restartRowsToGo--;
    }
    }
}

/*
 *--------------------------------------------------------------
 *
 * HuffEncode --
 *
 *      Encode and output Huffman-compressed image data.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
void
HuffEncode (CompressInfo *cPtr, PapyUShort *Image)
{
    register short curComp, ci;
    register int col,row;
    register JpegComponentInfo *compptr;
    register int diff;
    int predictor;
    int numCOL,numROW,compsInScan;
    int psv;
    PapyUChar *readim8b;
    PapyUShort *readim16b;

    numCOL=cPtr->imageWidth;
    numROW=cPtr->imageHeight;
    compsInScan=cPtr->compsInScan;
    psv=cPtr->Ss;

    
    if (cPtr->dataPrecision == 8) readim8b = (Uchar *) Image;
	else readim16b = (Ushort *) Image;

    EncodeFirstRow(cPtr,Image);
    
    if (cPtr->dataPrecision == 8) {
    
    readim8b += numCOL;

    for (row=1; row<numROW; row++) {
        if (cPtr->restartInRows) {
           if (cPtr->restartRowsToGo == 0) {
              EmitRestart (cPtr);
              EncodeFirstRow(cPtr,Image);
              readim8b += numCOL;
              continue;
           }
           cPtr->restartRowsToGo--;
        }

        /*
         * In the first column, the upper neighboring pixel
         * is the predictor. 
         */
        for (curComp = 0; curComp < compsInScan; curComp++) {
            ci = cPtr->MCUmembership[curComp];
            compptr = cPtr->curCompInfo[ci];
            diff = *readim8b - *(readim8b-numCOL);
            EncodeOneDiff (diff, cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
            readim8b++;
        }

        /*
         * In the rest of the column on this row, predictor is
         * calculated according to psv. 
         */
        for (col=1; col<numCOL; col++) {
            for (curComp = 0; curComp < compsInScan; curComp++) {
                ci = cPtr->MCUmembership[curComp];
                compptr = cPtr->curCompInfo[ci];

				if (psv == 5) predictor = *(readim8b-1) +((*(readim8b - numCOL) - *(readim8b-numCOL-1))>>1);
				else {
					if (psv == 1) predictor = *(readim8b-1);
					else {
						if (psv == 2) predictor = *(readim8b-numCOL);
						else {
							if (psv == 3) predictor = *(readim8b-numCOL-1);
							else {
								if (psv == 4) predictor = *(readim8b-1) + *(readim8b-numCOL) - *(readim8b-numCOL-1);
								else {
									if (psv == 0) predictor = 0; 
									else {
										if (psv == 7) predictor = (*(readim8b-1) + *(readim8b-numCOL))>>1;
										else {
											if (psv == 6) predictor = *(readim8b-numCOL)+((*(readim8b-1)-*(readim8b-numCOL-1))>>1);
											else {
												predictor = 0;
											} /* end else psv 6 */
										} /* end else psv 7 */
									} /* end else psv 0 */
								} /* end else psv 4 */
							} /* end else psv 3 */
						} /* end else psv 2 */
					} /* end else psv 1 */
				} /* end else psv 5*/
                diff= *readim8b - predictor;
                EncodeOneDiff (diff, cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
            } /* end for Curcomp */
        readim8b++;
        } /* end for row */
    } /* end 8 bits */
    
    }
    else { /* 16 bits */
    
    readim16b += numCOL;
    
     for (row=1; row<numROW; row++) {
        if (cPtr->restartInRows) {
           if (cPtr->restartRowsToGo == 0) {
              EmitRestart (cPtr);
              EncodeFirstRow(cPtr,Image);
              continue;
           }
           cPtr->restartRowsToGo--;
        }

        /*
         * In the first column, the upper neighboring pixel
         * is the predictor. 
         */
        for (curComp = 0; curComp < compsInScan; curComp++) {
            ci = cPtr->MCUmembership[curComp];
            compptr = cPtr->curCompInfo[ci];
           diff = *readim16b - *(readim16b-numCOL);
            EncodeOneDiff (diff, cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
            readim16b++;
        }

        /*
         * In the rest of the column on this row, predictor is
         * calculated according to psv. 
         */
        for (col=1; col<numCOL; col++) {
            for (curComp = 0; curComp < compsInScan; curComp++) {
                ci = cPtr->MCUmembership[curComp];
                compptr = cPtr->curCompInfo[ci];

				if (psv == 5) predictor = *(readim16b-1) +((*(readim16b - numCOL) - *(readim16b-numCOL-1))>>1);
				else {
					if (psv == 1) predictor = *(readim16b-1);
					else {
						if (psv == 2) predictor = *(readim16b-numCOL);
						else {
							if (psv == 3) predictor = *(readim16b-numCOL-1);
							else {
								if (psv == 4) predictor = *(readim16b-1) + *(readim16b-numCOL) - *(readim16b-numCOL-1);
								else {
									if (psv == 0) predictor = 0; 
									else {
										if (psv == 6) predictor = *(readim16b-numCOL)+((*(readim16b-1)-*(readim16b-numCOL-1))>>1);
										else {
											if (psv == 7) predictor = (*(readim16b-1) + *(readim16b-numCOL))>>1;
											else {
												predictor = 0;
											} /* end else psv 7 */
										} /* end else psv 6 */
									} /* end else psv 0 */
								} /* end else psv 4 */
							} /* end else psv 3 */
						} /* end else psv 2 */
					} /* end else psv 1 */
				} /* end else psv 5 */
                diff= *readim16b - predictor;
                EncodeOneDiff (diff, cPtr->dcHuffTblPtrs[compptr->dcTblNo]);
            } /* end for Curcomp */
        readim16b++;
        } /* end for row */

	 } /*end for col */ 
    
    } /* end else */
} /* end HuffCode */

/*
 *--------------------------------------------------------------
 *
 * HuffEncoderTerm --
 *
 *	Finish up at the end of a Huffman-compressed scan.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Any remaing bits are flushed.
 *
 *--------------------------------------------------------------
 */
void 
HuffEncoderTerm ()
{
    /*
     * Flush out the last data
     */
    FlushBits ();
    FlushBytes ();
}

/*
 *--------------------------------------------------------------
 *
 * Huffman coding optimization.
 *
 * This actually is optimization, in the sense that we find the
 * best possible Huffman table(s) for the given data. We first
 * scan the supplied data and count the number of uses of each
 * category symbol that is to be Huffman-coded. (This process 
 * must agree with the code above.)  Then we build an optimal
 * Huffman coding tree for the observed counts.
 *
 *--------------------------------------------------------------
 */

/*
 *--------------------------------------------------------------
 *
 * GenHuffCoding --
 *
 * 	Generate the optimal coding for the given counts. 
 *	This algorithm is explained in section K.2 of the
 *	JPEG standard. 
 *
 * Results:
 *      htbl->bits and htbl->huffval are costructed.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
void
GenHuffCoding (HuffmanTable *htbl, long *freq)
/* long freq[] */
{
#define MAX_CLEN 32     	/* assumed maximum initial code length */
  Uchar bits[MAX_CLEN+1];	/* bits[k] = # of symbols with code length k */
  short codesize[257];		/* codesize[k] = code length of symbol k */
  short others[257];		/* next symbol in current branch of tree */
  int c1, c2;
  int p, i, j;
  long v;

  MEMSET((void *)(bits), 0, sizeof(bits));
  MEMSET((void *)(codesize), 0, sizeof(codesize));
  for (i = 0; i < 257; i++)
      others[i] = -1;		/* init links to empty */

  /* 
   * Including the pseudo-symbol 256 in the Huffman procedure guarantees
   * that no real symbol is given code-value of all ones, because 256
   * will be placed in the largest codeword category.
   */
  freq[256] = 1;		/* make sure there is a nonzero count */

  /*
   * Huffman's basic algorithm to assign optimal code lengths to symbols 
   */
  for (;;) {

    /*
     * Find the smallest nonzero frequency, set c1 = its symbol.
     * In case of ties, take the larger symbol number.
     */
    c1 = -1;
    v = 1000000000L;
    for (i = 0; i <= 256; i++) {
      if (freq[i] && freq[i] <= v) {
	v = freq[i];
	c1 = i;
      }
    }

    /*
     * Find the next smallest nonzero frequency, set c2 = its symbol.
     * In case of ties, take the larger symbol number.
     */
    c2 = -1;
    v = 1000000000L;
    for (i = 0; i <= 256; i++) {
      if (freq[i] && freq[i] <= v && i != c1) {
	v = freq[i];
	c2 = i;
      }
    }

    /*
     * Done if we've merged everything into one frequency.
     */
    if (c2 < 0)
      break;
    
    /*
     * Else merge the two counts/trees.
     */
    freq[c1] += freq[c2];
    freq[c2] = 0;

    /*
     * Increment the codesize of everything in c1's tree branch.
     */
    codesize[c1]++;
    while (others[c1] >= 0) {
      c1 = others[c1];
      codesize[c1]++;
    }
    
    /*
     * chain c2 onto c1's tree branch 
     */
    others[c1] = c2;
    
    /*
     * Increment the codesize of everything in c2's tree branch.
     */
    codesize[c2]++;
    while (others[c2] >= 0) {
          c2 = others[c2];
          codesize[c2]++;
    }
  }

  /*
   * Now count the number of symbols of each code length.
   */
  for (i = 0; i <= 256; i++) {
    if (codesize[i]) {

      /*
       * The JPEG standard seems to think that this can't happen,
       * but I'm paranoid...
       */
      if (codesize[i] > MAX_CLEN) {
	fprintf(stderr, "Huffman code size table overflow: codesize[%d]=%d\n",
                i,codesize[i]);
        return; /* MAL exit(-1); */
      }

      bits[codesize[i]]++;
    }
  }

  /* 
   * JPEG doesn't allow symbols with code lengths over 16 bits, so if the pure
   * Huffman procedure assigned any such lengths, we must adjust the coding.
   * Here is what the JPEG spec says about how this next bit works:
   * Since symbols are paired for the longest Huffman code, the symbols are
   * removed from this length category two at a time.  The prefix for the pair
   * (which is one bit shorter) is allocated to one of the pair; then,
   * skipping the BITS entry for that prefix length, a code word from the next
   * shortest nonzero BITS entry is converted into a prefix for two code words
   * one bit longer.
   */
  
  for (i = MAX_CLEN; i > 16; i--) {
    while (bits[i] > 0) {
      j = i - 2;		/* find length of new prefix to be used */
      while (bits[j] == 0)
	j--;
      
      bits[i] -= 2;		/* remove two symbols */
      bits[i-1]++;		/* one goes in this length */
      bits[j+1] += 2;		/* two new symbols in this length */
      bits[j]--;		/* symbol of this length is now a prefix */
    }
  }

  /*
   * Remove the count for the pseudo-symbol 256 from
   * the largest codelength.
   */
  while (bits[i] == 0)		/* find largest codelength still in use */
    i--;
  bits[i]--;
  
  /*
   * Return final symbol counts (only for lengths 0..16).
   */
  MEMCPY((htbl->bits),(bits),sizeof(htbl->bits));
  
  /*
   * Return a list of the symbols sorted by code length. 
   * It's not real clear to me why we don't need to consider the codelength
   * changes made above, but the JPEG spec seems to think this works.
   */
  p = 0;
  for (i = 1; i <= MAX_CLEN; i++) {
    for (j = 0; j <= 255; j++) {
      if (codesize[j] == i) {
	htbl->huffval[p] = (Uchar) j;
	p++;
      }
    }
  }
}

/*
 *--------------------------------------------------------------
 *
 * AllPredCountOneDiff --
 *
 *      Count this difference value in all 7 frequency counting 
 *	tables. This function is called when processing the first
 *      row and first column of the image. Pixels in the first row
 *	always use the left neighbors or (1<Pr-Pt-1) as predictors;  
 *      and pixels in the first column always use the upper neighbors.
 *      So, these pixels's difference values are the same for all 
 *	seven PSVs. Thus, we compute this value once and count it
 *	for all PSVs.  
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      value is counted in all global counting tables,
 *	i.e. freqCountPtrs.
 *
 *--------------------------------------------------------------
 */
void
AllPredCountOneDiff(int value, int tblNo)
{
    register int temp, temp2;
    register short nbits; /*i;*/

    /*
     * Encode the DC coefficient difference per section F.1.2.1
     */
    temp = temp2 = value;
    if (temp < 0) {
        temp = -temp;
        /*
         * For a negative input, want temp2 = bitwise complement of
         * abs(input).  This code assumes we are on a two's complement
         * machine.
         */
        temp2--;
    }

    /*
     * Find the number of bits needed for the magnitude of the coefficient
     */
    nbits=0;
    if (temp) {
        while (temp >= 256) {
            nbits += 8;
            temp >>= 8;
        }
        nbits += numBitsTable[temp&0xff];
    }

    freqCountPtrs[0][tblNo][nbits]++;
    freqCountPtrs[1][tblNo][nbits]++;
    freqCountPtrs[2][tblNo][nbits]++;
    freqCountPtrs[3][tblNo][nbits]++;
    freqCountPtrs[4][tblNo][nbits]++;
    freqCountPtrs[5][tblNo][nbits]++;
    freqCountPtrs[6][tblNo][nbits]++;
}

#ifdef DEBUG

/*
 *--------------------------------------------------------------
 *
 * CountOneDiff --
 *
 *      Count the difference value in countTable.
 *
 * Results:
 *      diff is counted in countTable.
 *
 * Side effects:
 *      None. 
 *
 *--------------------------------------------------------------
 */
void
CountOneDiff(int diff, long *countTable)  
/*     long countTable[];*/
{
    register int temp, temp2;
    register short nbits;

    /*
     * Encode the DC coefficient difference per section F.1.2.1
     */
    temp = temp2 = diff;
    if (temp < 0) {
        temp = -temp;
        /*
         * For a negative input, want temp2 = bitwise complement of
         * abs(input).  This code assumes we are on a two's complement
         * machine.
         */
        temp2--;
    }

    /*
     * Find the number of bits needed for the magnitude of the coefficient
     */
    nbits=0;
    if (temp) {
        while (temp >= 256) {
            nbits += 8;
            temp >>= 8;
        }
        nbits += numBitsTable[temp&0xff];
    }
    countTable[nbits]++;
}

/*
 *--------------------------------------------------------------
 *
 * AllPredCountOneComp --
 *
 *      The sample, curRowBuf[col][curComp], is counted in the
 *	frequency counting tables, freqCountPts, of the 7 PSVs.        
 *
 * Results:
 *      None.
 *
 * Side effects:
 *	curRowBuf[col][curComp] is counted in freqCountPtrs[i][tblNo]
 *	for i=0 to 6. 
 *
 *--------------------------------------------------------------
 */
void
AllPredCountOneComp(int col, int curComp, int tblNo, MCU *curRowBuf, MCU *prevRowBuf)
{
    register int left,upper,diag,leftcol,r,curValue;

    leftcol=col-1;
    upper=prevRowBuf[col][curComp];
    left=curRowBuf[leftcol][curComp];
    diag=prevRowBuf[leftcol][curComp];
    curValue=curRowBuf[col][curComp];
    /* predictor 1 */
    r = curValue - left;
    CountOneDiff(r,freqCountPtrs[0][tblNo]);

    /* predictor 2 */
    r = curValue - upper;
    CountOneDiff(r,freqCountPtrs[1][tblNo]);

    /* predictor 3 */
    r = curValue - diag;
    CountOneDiff(r,freqCountPtrs[2][tblNo]);

    /* predictor 4 */
    r = curValue - (left+upper-diag);
    CountOneDiff(r,freqCountPtrs[3][tblNo]);

    /* predictor 5 */
    r = curValue - (left+((upper-diag)>>1));
    CountOneDiff(r,freqCountPtrs[4][tblNo]);

    /* predictor 6 */
    r = curValue - (upper+((left-diag)>>1));
    CountOneDiff(r,freqCountPtrs[5][tblNo]);

    /* predictor 7 */
    r = curValue - ((left+upper)>>1);
    CountOneDiff(r,freqCountPtrs[6][tblNo]);
}

#else /* DEBUG */

/*
 *--------------------------------------------------------------
 *
 * CountOneDiff (macro) --
 *
 *      Count the difference value in countTable.
 *
 * Results:
 *      diff is counted in countTable.
 *
 * Side effects:
 *      None. 
 *
 *--------------------------------------------------------------
 */
#define CountOneDiff(diff, countTable){							\
    register int temp, temp2;									\
    register short nbits;										\
																\
    temp = temp2 = diff;										\
    if (temp < 0) {												\
        temp = -temp;											\
        temp2--;												\
    }															\
																\
    nbits=0;													\
    if (temp) {													\
        while (temp >= 256) {									\
            nbits += 8;											\
            temp >>= 8;											\
        }														\
        nbits += numBitsTable[temp&0xff];						\
    }															\
    countTable[nbits]++;										\
}

/*
 *--------------------------------------------------------------
 *
 * AllPredCountOneComp (macro) --
 *
 *      The sample, curRowBuf[col][curComp], is counted in the
 *	frequency counting tables, freqCountPts, of the 7 PSVs.        
 *
 * Results:
 *      None.
 *
 * Side effects:
 *	curRowBuf[col][curComp] is counted in freqCountPtrs[i][tblNo]
 *	for i=0 to 6. 
 *
 *--------------------------------------------------------------
 */
#define AllPredCountOneComp(col,curComp,tblNo,curRowBuf,prevRowBuf) {	\
    register int left,upper,diag,leftcol,r,curValue;					\
																		\
    leftcol=col-1;														\
    upper=prevRowBuf[col][curComp];										\
    left=curRowBuf[leftcol][curComp];									\
    diag=prevRowBuf[leftcol][curComp];									\
    curValue=curRowBuf[col][curComp];									\
    /* predictor 1 */													\
    r = curValue - left;												\
    CountOneDiff(r,freqCountPtrs[0][tblNo]);							\
    /* predictor 2 */													\
    r = curValue - upper;												\
    CountOneDiff(r,freqCountPtrs[1][tblNo]);							\
    /* predictor 3 */													\
    r = curValue - diag;												\
    CountOneDiff(r,freqCountPtrs[2][tblNo]);							\
    /* predictor 4 */													\
    r = curValue - (left+upper-diag);									\
    CountOneDiff(r,freqCountPtrs[3][tblNo]);							\
    /* predictor 5 */													\
    r = curValue - (left+((upper-diag)>>1));							\
    CountOneDiff(r,freqCountPtrs[4][tblNo]);							\
    /* predictor 6 */													\
    r = curValue - (upper+((left-diag)>>1));							\
    CountOneDiff(r,freqCountPtrs[5][tblNo]);							\
    /* predictor 7 */													\
    r = curValue - ((left+upper)>>1);									\
    CountOneDiff(r,freqCountPtrs[6][tblNo]);							\
}

#endif /*else DEBUG*/

/*
 *--------------------------------------------------------------
 *
 * FreqCountSelValueSet --
 *
 *      Count the times each category symbol occurs in this
 *	image for each PSV in the psvSet.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The freqCountPtrs[i] has counted all category 
 *	symbols appeared in the image, where i is a
 *      element in psvSet.        
 *
 *--------------------------------------------------------------
 */
void 
FreqCountSelValueSet(CompressInfo *cPtr)
{
    register short curComp,ci,tblNo ;
    register int col,row;
    register JpegComponentInfo *compptr;
    register int r,i,curCountTblNo;
    int numCOL,numROW,compsInScan;
    int Pr,Pt;
    int predictor;
    MCU *prevRowBuf,*curRowBuf;

    numCOL=cPtr->imageWidth;
    numROW=cPtr->imageHeight;
    compsInScan=cPtr->compsInScan;
    Pr=cPtr->dataPrecision;
    Pt=cPtr->Pt;
    prevRowBuf=NULL;
    curRowBuf=mcuTable;

    for (row=0; row<numROW; row++) {
        for (col=0; col<numCOL; col++) {
            for (curComp = 0; curComp < compsInScan; curComp++) {
                ci = cPtr->MCUmembership[curComp];
                compptr = cPtr->curCompInfo[ci];
                tblNo=compptr->dcTblNo;

                for (i=0;i<numSelValue;i++) {
                    Predict(row,col,curComp,curRowBuf,prevRowBuf,Pr,Pt,
                        psvSet[i],&predictor);
                    r = curRowBuf[col][curComp]-predictor; 
                    curCountTblNo=psvSet[i]-1;
                    CountOneDiff(r,freqCountPtrs[curCountTblNo][tblNo]);
                }
            }
        }
        prevRowBuf=curRowBuf;
        curRowBuf+=numCOL;
    }
}

/*
 *--------------------------------------------------------------
 *
 * FreqCountAllSelValue --
 *
 *      Count the times each category symbol occurs in this
 *      image for all seven PSV.
 *      To do this all together is even faster than to use
 *      a loop to go through 4 only PSVs. 
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The freqCountPtrs[i] has counted all category symbols
 *      appeared in the image, where i goes from 0 to 6. 
 *
 *--------------------------------------------------------------
 */
void
FreqCountAllSelValue(CompressInfo *cPtr)
{
    register short curComp, ci;
    register int col,row;
    register JpegComponentInfo *compptr;
    register int r;
    int numCOL,numROW,compsInScan;
    int Pr,Pt,Ss; /*j;
    int predictor;*/
    MCU *prevRowBuf,*curRowBuf;

    numCOL=cPtr->imageWidth;
    numROW=cPtr->imageHeight;
    compsInScan=cPtr->compsInScan;
    Pr=cPtr->dataPrecision;
    Pt=cPtr->Pt;
    Ss=cPtr->Ss;
    prevRowBuf=NULL;
    curRowBuf=mcuTable;

    /*
     * Do some specical case checking such that we can reduce the
     * computations in the main loop.
     */ 

    /*
     * For the very first mcu in the scan, predictor is 1<<(Pr-Pt-1). 
     */
    for (curComp = 0; curComp < compsInScan; curComp++) {
        ci = cPtr->MCUmembership[curComp];
        compptr = cPtr->curCompInfo[ci];

        r = curRowBuf[0][curComp] - (1<<(Pr-Pt-1));
        AllPredCountOneDiff(r,compptr->dcTblNo);
    }

    /*
     * In rest of the first row, left neighboring pixel is the predictor. 
     */
    for (col=1; col<numCOL; col++) {
        for (curComp = 0; curComp < compsInScan; curComp++) {
            ci = cPtr->MCUmembership[curComp];
            compptr = cPtr->curCompInfo[ci];

            r = curRowBuf[col][curComp]-curRowBuf[col-1][curComp];
            AllPredCountOneDiff(r,compptr->dcTblNo);
        }
    }
    prevRowBuf=curRowBuf;
    curRowBuf+=numCOL;

    for (row=1; row<numROW; row++) {

        /*
         * For the first column, upper neighbor is the predictor. 
         */
        for (curComp = 0; curComp < compsInScan; curComp++) {
            ci = cPtr->MCUmembership[curComp];
            compptr = cPtr->curCompInfo[ci];

            r = curRowBuf[0][curComp]-prevRowBuf[0][curComp];
            AllPredCountOneDiff(r,compptr->dcTblNo);
        }
 
        /*
         * Call AllPredCountOneComp to count the rest samples on this row.  
         */
        for (col=1; col<numCOL; col++) {
            for (curComp = 0; curComp < compsInScan; curComp++) {
                ci = cPtr->MCUmembership[curComp];
                compptr = cPtr->curCompInfo[ci];

                AllPredCountOneComp(col,curComp,compptr->dcTblNo,
                                    curRowBuf,prevRowBuf);
            }
        }
        prevRowBuf=curRowBuf;
        curRowBuf+=numCOL;
    }
}

/*
 *--------------------------------------------------------------
 *
 * FreqCountInit --
 *
 *	Allocate and zero the count tables.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Seven tables pointed by freqCountPtrs[][] have been 
 *	allocated and initiallized.  
 *
 *--------------------------------------------------------------
 */
void
FreqCountInit(CompressInfo *cPtr)
{
    int i,j,tbl;

    for (i = 0; i < NUM_HUFF_TBLS; i++) {
        for (j=0;j<7;j++)
            freqCountPtrs[j][i] = NULL;
    }

    /*
     * Create seven count tables for each Huffman table.
     * Initialize the table entries to zero.
     * Note that GenHuffCoding expects 257 entries in each table, 
     * although I think 17 will be enough.
     */
    for (i = 0; i < cPtr->compsInScan; i++) {
        tbl = cPtr->curCompInfo[i]->dcTblNo;
        for (j=0;j<7;j++) {
            if (freqCountPtrs[j][tbl] == NULL) {
               freqCountPtrs[j][tbl] = (long *) emalloc3 (257 *sizeof(long));
               MEMSET((void *)(freqCountPtrs[j][tbl]), 0, 257*sizeof(long));
            }
        }
    }
}

/*
 *--------------------------------------------------------------
 *
 * EmitBitsSum --
 *
 *	Find the number of bits emiting for a PSV (curCountTblNo+1).
 *	It includes the total bits of category symbols and additional
 *	bits.
 *
 * Results:
 *      Total "category symbol" and "additional bits" output bits
 *	for this PSV.
 *
 * Side effects:
 *	If in vervose mode, totalHuffSym and totalAddBits for
 *	this PSV is stored. These data are later output as statistics
 *	data.
 *
 *--------------------------------------------------------------
 */
long
EmitBitsSum(int curCountTblNo, HuffmanTable **htblPtr)
/*    HuffmanTable *htblPtr[4]; */
{
    int i,tbl;
    long addBitSum,symLenSum,totalBits;
   
    
    addBitSum=0;
    symLenSum=0;
    /* 
     * Count additional bits and Huffman symbol size.
     */
    for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
        if (freqCountPtrs[curCountTblNo][tbl] != NULL) {
           for (i=1;i<17;i++) {
               addBitSum+=freqCountPtrs[curCountTblNo][tbl][i]*i;
           }
           for (i=0;i<17;i++) {
               symLenSum+=freqCountPtrs[curCountTblNo][tbl][i]*
                          htblPtr[tbl]->ehufsi[i];
           }
        }
    }

    totalBits=symLenSum+addBitSum;
    if (verbose) {
       totalHuffSym[curCountTblNo]=symLenSum; 
       totalAddBits[curCountTblNo]=addBitSum; 
    }
    return (totalBits);
}

/*
 *--------------------------------------------------------------
 *
 * HuffOptimize --
 *
 *	Find the best coding parameters for a Huffman-coded scan.
 *	When called, the scan data has already been converted to
 *	a sequence of MCU groups of source image samples, which
 *	are stored in a "big" array, mcuTable.
 *
 *	It counts the times each category symbol occurs. Based on
 *	this counting, optimal Huffman tables are built. Then it
 *	uses this optimal Huffman table and counting table to find
 *	the best PSV. 
 *
 * Results:
 *	Optimal Huffman tables are retured in cPtr->dcHuffTblPtrs[tbl].
 *	Best PSV is retured in cPtr->Ss.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
void
HuffOptimize (CompressInfo *cPtr, long *bestTotalBits)
{
    int tbl,i;
    HuffmanTable *curHtblPtr[4];
    long curTotalBits;
    long curFreqCount[257];
    int curCountTblNo;
  
    FreqCountInit(cPtr);

    /*
     * Collect the frequency count in freqCountPtrs for each PSV.
     * Experiment data shows that when numSelValue > 4, 
     * FreqCountAllSelValue does a better job than FreqCountSelValueSet.
     */
    if (numSelValue>3) { 
       FreqCountAllSelValue(cPtr);
       }
    else {
       FreqCountSelValueSet(cPtr);
    }
 
    /* 
     * Generate optimal Huffman tables and find the best PSV.
     * Loop through each PSV is the psvSet. Whenever a better PSV
     * is found, its Huffman table is stored in cPtr->dcHuffTblPtrs;
     * and itself is stored in cPtr->Ss.
     */

    /*
     * Set curCountTblNo to the first PSV. Allocate memory,
     * and point bestHtblPtr to cPtr->dcHuffTblPtrs,
     */
    curCountTblNo=psvSet[0]-1;
    for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
        curHtblPtr[tbl]=NULL;
        if (freqCountPtrs[curCountTblNo][tbl] != NULL) {
           curHtblPtr[tbl]=(HuffmanTable *) emalloc3 (sizeof(HuffmanTable));
           if (cPtr->dcHuffTblPtrs[tbl] == NULL) {
              cPtr->dcHuffTblPtrs[tbl]=(HuffmanTable *)
                                         emalloc3 (sizeof(HuffmanTable));
           }
        }
    }
  
    /*
     * Generate the Huffman tables for the first PSV and count the
     * total output bits of category symbols and additional bits.
     */
    for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
        if (freqCountPtrs[curCountTblNo][tbl] != NULL) {

           /*
            * Make an extra copy of the freqency tables since
            * GenHuffCoding destroys it. We need these tables 
            * to count output bits next.
            */
           MEMCPY(curFreqCount,freqCountPtrs[curCountTblNo][tbl],
                  257*sizeof(long));
           GenHuffCoding(cPtr->dcHuffTblPtrs[tbl], curFreqCount);
           FixHuffTbl(cPtr->dcHuffTblPtrs[tbl]);
        }
    } 
    *bestTotalBits=EmitBitsSum(curCountTblNo,cPtr->dcHuffTblPtrs);
    cPtr->Ss=psvSet[0];
    

    /*
     * Generate the Huffman tables and count the output bits for the
     * remaining PSVs. Store the best one in cPtr pionted structure.
     */
    for (i=1; i<numSelValue; i++) {
        curCountTblNo=psvSet[i]-1;
        for (tbl=0; tbl<NUM_HUFF_TBLS; tbl++) {
            if (freqCountPtrs[curCountTblNo][tbl] != NULL) {
               MEMCPY(curFreqCount,freqCountPtrs[curCountTblNo][tbl],
                      257*sizeof(long));
               GenHuffCoding(curHtblPtr[tbl],curFreqCount);
               FixHuffTbl(curHtblPtr[tbl]);
            }
        }   
        curTotalBits=EmitBitsSum(curCountTblNo,curHtblPtr);

        if (curTotalBits<*bestTotalBits) {
           for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
               if (curHtblPtr[tbl] != NULL) {
                  swap(HuffmanTable *,cPtr->dcHuffTblPtrs[tbl],curHtblPtr[tbl]);
               }
           }
           *bestTotalBits=curTotalBits;
           cPtr->Ss=psvSet[i];
           /* printf("psv %d , total bytes %d \n", psvSet[i], *bestTotalBits); */
        }
    }

    /* 
     * Set sent_table FALSE so updated table will be
     * written to JPEG file.
     */
    for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
        if (cPtr->dcHuffTblPtrs[tbl] != NULL) {
           cPtr->dcHuffTblPtrs[tbl]->sentTable = 0;
        }
    }
           
  
    /*
     * Release the freqency Count tables, and temporary Huffman tables.
     */
    for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
        for (i=0;i<7;i++) {
            if (freqCountPtrs[i][tbl] != NULL) {
               efree3((void **) &freqCountPtrs[i][tbl]);
            }
        }
        if (curHtblPtr[tbl] != NULL) {
           efree3((void **) &curHtblPtr[tbl]);
        }
    }
}

/*
 *--------------------------------------------------------------
 *
 * StdPickSelValue --
 *
 *	Select the best PSV from the psvSet. Default Huffman
 *	tables and frequency counting tables are used in the
 *	selection procedure.
 *
 * Results:
 *	Chosen selection value is stored in cPtr->Ss
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
void
StdPickSelValue(CompressInfo *cPtr, long *bestTotalBits)
{
    int tbl,i;
    long curTotalBits;
    /*long curFreqCount[257];*/
    int curCountTblNo;
 
    FreqCountInit(cPtr);

    /*
     * Collect the frequency count in freqCountPtrs for each PSV.
     * Experiment data shows that when numSelValue > 4,
     * FreqCountAllSelValue does a better job than FreqCountSelValueSet.
     */
    if (numSelValue>3) { 
       FreqCountAllSelValue(cPtr);
       }
    else {
       FreqCountSelValueSet(cPtr);
    }

    /* 
     * Loop through each PSV in the psvSet, and store the PSV
     * which generates the least output bits in cPtr->Ss.
     */
    curCountTblNo=psvSet[0]-1;
    *bestTotalBits=EmitBitsSum(curCountTblNo,cPtr->dcHuffTblPtrs);
    cPtr->Ss=psvSet[0];
    for (i=1; i<numSelValue; i++) {
        curCountTblNo=psvSet[i]-1;
        curTotalBits=EmitBitsSum(curCountTblNo,cPtr->dcHuffTblPtrs);
        if (curTotalBits<*bestTotalBits) {
           *bestTotalBits=curTotalBits;
           cPtr->Ss=psvSet[i];
        }
    }

    /*
     * Release frequency counting tables.
     */
    for (tbl = 0; tbl < NUM_HUFF_TBLS; tbl++) {
        for (i=0;i<7;i++) {
            if (freqCountPtrs[i][tbl] != NULL) {
               efree3((void **) &freqCountPtrs[i][tbl]);
            }
        }
    }
}

/*
 *--------------------------------------------------------------
 *
 * AddHuffTable --
 *
 *	Huffman table setup routines. Copy bits and val tables 
 *	into a Huffman table.
 *
 * Results:
 *	bits and val are copied into htblprt.
 *	(*htblptr)->sentTable is set to 0.
 *
 * Side effects:
 *      None. 
 *
 *--------------------------------------------------------------
 */
void
AddHuffTable (HuffmanTable **htblptr, Uchar *bits, Uchar *val)
{
    if (*htblptr == NULL)
       *htblptr = (HuffmanTable *) (emalloc3 (sizeof(HuffmanTable)));

    MEMCPY((*htblptr)->bits, bits, sizeof((*htblptr)->bits));
    MEMCPY((*htblptr)->huffval, val, sizeof((*htblptr)->huffval));

    /*
     * Initialize sent_table FALSE so table will be written to JPEG file.
     * In an application where we are writing non-interchange JPEG files,
     * it might be desirable to save space by leaving default Huffman tables
     * out of the file.  To do that, just initialize sent_table = TRUE...
     */

    (*htblptr)->sentTable = 0;
}

/*
 *--------------------------------------------------------------
 *
 * LoadStdHuffTables --
 *
 *	Load the standard Huffman tables (cf. JPEG standard
 *	section K.3) into compression data structure pointed
 *	by cPtr.
 *	IMPORTANT: these are only valid for 8-bit data precision!
 *
 * Results:
 *      Standard Huffman table, bits and val, are copied into
 *	cPtr->dcHuffTblPtrs.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
void
LoadStdHuffTables (CompressInfo *cPtr)
{
    /* static Uchar dcLuminanceBits[17] =
      { 0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 };
    static Uchar dcLuminanceVal[] =
      { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }; */
      
    static Uchar dcLuminanceBits[17] =
      { 0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 };
    static Uchar dcLuminanceVal[17] =
      { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
 
    /* static Uchar dcChrominanceBits[17] =
      { 0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 };
    static Uchar dcChrominanceVal[] =
      { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }; */
    
    static Uchar dcChrominanceBits[17] =
      { /* 0-base */ 0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 };
    static Uchar dcChrominanceVal[17] =
      { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
      
 
    AddHuffTable(&(cPtr->dcHuffTblPtrs[0]),dcLuminanceBits,dcLuminanceVal);
    AddHuffTable(&(cPtr->dcHuffTblPtrs[1]),dcChrominanceBits,dcChrominanceVal);
}
