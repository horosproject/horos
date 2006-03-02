/*
 * pnmtoljpoptimisebug.c --
 *
 * This is the main routine for the lossless JPEG encoder.
 *
 * Tranformations were made in order to integrate the lossless JPEG
 * in the Papyrus Toolkit and to increase the speed. 
 * Main options proposed by the Cornell Univ. were disabled, such as
 * Huffman table optimization. However this encoder is still JPEG compliant.
 * Two kinds of images are now supported by this lossless encoder:
 *		- 8-bits grayscale images,
 *		- 16-bits grayscale images.
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
#include <errno.h>

#include <string.h>
#include "jpeg.h"
#include "mcu.h"
#include "proto.h"
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

#endif


#define HEADERSIZE 1000

/*
 * Global and static variables 
 */
 
int 		    verbose;			/* If verbose!=0, the verbose flag is on.	 	*/
int 		    psvSet[7];			/* The PSV set 									*/			
int 		    numSelValue;		/* Number of elements in psvPSV 				*/
PapyULong 	    inputFileBytes;		/* Total input file bytes 						*/
PapyULong 	    outputFileBytes;	/* Total output file bytes 						*/
long 		    totalHuffSym[7];	/* Total bits of Huffman coded categroy symbols	*/
long 		    totalAddBits[7];	/* Total additional bits 						*/
static PAPY_FILE    OutFile;		/* Output file pointer 							*/
PapyUChar 	    *JPEGBuffer;		/* Buffer for JPEG Data 						*/
PapyUChar 	    *readimBuffer;		/* Buffer for input image  8 bytes				*/
PapyUShort 	    *readim16Buffer;/* Buffer for input image  16 bytes				*/


extern void PmRead (CompressInfo *, int);
extern void HuffOptimize (CompressInfo *, long *);
extern void LoadStdHuffTables (CompressInfo *);

/*
 *--------------------------------------------------------------
 *
 * WriteJpegData --
 *
 *	This is an interface routine to the JPEG library.  The
 *	library calls this routine to output a block of data.
 *
 * Results:
 *	Number of bytes written.  If this is less than numBytes,
 *	it indeicates an error.
 *
 * Side effects:
 *	The number of bytes output this time is added to
 *	outputFileBytes.
 *
 *--------------------------------------------------------------
 */
PapyULong WriteJpegData  (PapyUChar *buffer, PapyULong numBytes)
/* Data to write */
/* Number of bytes to write */
{
  PapyULong i;
    
  for (i=0; i<numBytes; i++)
  {
    JPEGBuffer[outputFileBytes] = buffer[i];
    outputFileBytes++;
  }			
  return numBytes;
}

/*
 *--------------------------------------------------------------
 *
 * JPEGLosslessEncodeImage --
 *
 * This is the routine used in the Papyrus Toolkit for Lossless encoder
 *
 * Results
 * JPEGBytes bytes of the JPEG data are written in JPEGInput
 *--------------------------------------------------------------
 */


void JPEGLosslessEncodeImage (PapyUShort *Image, PapyUChar **JPEGInput, PapyULong *JPEGBytes,int nbcols, int nbrows, int depth)
{
    JpegComponentInfo 	*compPtr;
    CompressInfo 	enInfo;
    int 		i, optimize;
    PapyULong 		CountBits, JPEGSize;
    

    if (depth == 8) 
      readimBuffer   = (PapyUChar *) Image;
    else 
      readim16Buffer = (PapyUShort *) Image; 

    optimize = 0;

    /* optimize is a flag used to enable or disabled the psv optimization
     * if optimize flag is on, a default psv (psv =1) is applied
     * ifnot the optimal psv is searched. Warning: such a config. is time consuming!
     */
	
    /*
     * zeroes the memory of the enInfo parameter.
     */
    MEMSET (&enInfo, 0, sizeof (enInfo));
    
    /*
     * default values
     */
    JPEGSize = 0;
    outputFileBytes = 0L;
    enInfo.imageWidth    = nbcols;
    enInfo.imageHeight   = nbrows;
    enInfo.dataPrecision = depth;
    enInfo.restartInRows = 0;
    enInfo.Pt            = 0;
    
    numSelValue = 7;
    for (i = 0; i < numSelValue; i++) {
        psvSet [i] = i + 1;
    }

    /* 
     * Load the mcu if necessary (optimize flag is on) and get ready for encoding.
     */

    PmRead (&enInfo, optimize);
    HuffEncoderInit (&enInfo);

    /*
     * Assign a Huffman table to be used by a component.
     * In non-optimal encoding, all components share one 
     * stardard Huffman table. 
     */
     for (i = 0; i < enInfo.compsInScan; i++) 
     {
       compPtr = enInfo.curCompInfo [i];
       compPtr->dcTblNo = 0;
     } /* for */

     /*
      * Load and prepare the standard Huffman table.
      */ 
     LoadStdHuffTables(&enInfo);
     for (i = 0; i < enInfo.compsInScan; i++) 
     {
       compPtr = enInfo.curCompInfo [i];
       FixHuffTbl ((enInfo.dcHuffTblPtrs) [compPtr->dcTblNo]);
     } /* for */

     /*
      * Apply a default psv if optimize flag is off
      * Select the best PSV using standard Huffman table if optimize flag is on
      */
     if (optimize == 0) enInfo.Ss = 1;
     else 
     {
       StdPickSelValue (&enInfo, (long *) &CountBits);
       JPEGSize = (CountBits >> 3) + HEADERSIZE;
     }
       
    /*
     * Write the frame and scan headers. Encode the image.
     * Clean up everything. 
     */
     
     /* Assign memory for JPEG data. Note that the space is redefined since
      * we do not know the required space before compression 
      */
     if (JPEGSize == 0) 
     {
     	if (enInfo.dataPrecision == 8) 
     	  JPEGSize = enInfo.imageWidth * enInfo.imageHeight;
     	else 
     	  JPEGSize = enInfo.imageWidth * enInfo.imageHeight * 4;
     }
	 
    JPEGBuffer = (PapyUChar *) ecalloc3 ((PapyULong) JPEGSize, (PapyULong) sizeof (PapyUChar));
    
    WriteFileHeader  (&enInfo); 
    WriteScanHeader  (&enInfo);
    HuffEncode 	     (&enInfo, (PapyUShort *) Image);
    /* FreeArray2D      ((char **) &mcuTable); */
    /* efree3((void **) &mcuTable[0]); */
	if (optimize == 1) efree3((void **) &mcuTable); 
    HuffEncoderTerm  ();
    WriteFileTrailer (&enInfo);
    FlushBytes       ();

    efree3 ((void **) &(enInfo.compInfo));
    efree3 ((void **) &(enInfo.dcHuffTblPtrs[0]));
    efree3 ((void **) &(enInfo.dcHuffTblPtrs[1]));

    *JPEGBytes = outputFileBytes;
    *JPEGInput = (PapyUChar *) JPEGBuffer;


} /* endof JPEGLosslessEncodeImage */
