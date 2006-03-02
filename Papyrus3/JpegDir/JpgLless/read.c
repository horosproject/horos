/*
 * read.c --
 *
 * Code for reading and processing JPEG markers.  Large parts are grabbed
 * from the IJG software, so:
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
#include "jpeg.h"
#include "mcu.h"
#include "io.h"
#include "proto.h"

/*
 * To fix a memory leak (memory malloc'd then never freed) in the original
 * version of lossless JPEG decompression, memory is allocated for 4 
 * Huffman tables once here, then pointers set later as needed
 */

HuffmanTable HuffmanTableMemory[4];

/* 
 * Enumerate all the JPEG marker codes
 */
typedef enum {
      M_SOF0 = 0xc0,
      M_SOF1 = 0xc1,
      M_SOF2 = 0xc2,
      M_SOF3 = 0xc3,

      M_SOF5 = 0xc5,
      M_SOF6 = 0xc6,
      M_SOF7 = 0xc7,

      M_JPG = 0xc8,
      M_SOF9 = 0xc9,
      M_SOF10 = 0xca,
      M_SOF11 = 0xcb,

      M_SOF13 = 0xcd,
      M_SOF14 = 0xce,
      M_SOF15 = 0xcf,

      M_DHT = 0xc4,

      M_DAC = 0xcc,

      M_RST0 = 0xd0,
      M_RST1 = 0xd1,
      M_RST2 = 0xd2,
      M_RST3 = 0xd3,
      M_RST4 = 0xd4,
      M_RST5 = 0xd5,
      M_RST6 = 0xd6,
      M_RST7 = 0xd7,

      M_SOI = 0xd8,
      M_EOI = 0xd9,
      M_SOS = 0xda,
      M_DQT = 0xdb,
      M_DNL = 0xdc,
      M_DRI = 0xdd,
      M_DHP = 0xde,
      M_EXP = 0xdf,

      M_APP0 = 0xe0,
      M_APP15 = 0xef,

      M_JPG0 = 0xf0,
      M_JPG13 = 0xfd,
      M_COM = 0xfe,

      M_TEM = 0x01,

      M_ERROR = 0x100
} JpegMarker;


/*
 *--------------------------------------------------------------
 *
 * Get2bytes --
 *
 *	Get a 2-byte unsigned integer (e.g., a marker parameter length
 *	field)
 *
 * Results:
 *	Next two byte of input as an integer.
 *
 * Side effects:
 *	Bitstream is parsed.
 *
 *--------------------------------------------------------------
 */
static Uint Get2bytes ()
{
    int a;

    a = GetJpegChar();
    return (a << 8) + GetJpegChar();
}

/*
 *--------------------------------------------------------------
 *
 * SkipVariable --
 *
 *	Skip over an unknown or uninteresting variable-length marker
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Bitstream is parsed over marker.
 *
 *
 *--------------------------------------------------------------
 */
static void SkipVariable ()
{
    int length;

    length = Get2bytes () - 2;

    while (length--) {
	GetJpegChar();
    }
}

/*
 *--------------------------------------------------------------
 *
 * GetDht --
 *
 *	Process a DHT marker
 *
 * Results:
 *	None
 *
 * Side effects:
 *	A huffman table is read.
 *	Exits on error.
 *
 *--------------------------------------------------------------
 */
static void GetDht (DecompressInfo *dcPtr)
{
    int length;
    Uchar bits[17];
    Uchar huffval[256];
    int i, index, count;
    HuffmanTable **htblptr;

    length = Get2bytes () - 2;

    while (length) {
	index = GetJpegChar();

	bits[0] = 0;
	count = 0;
	for (i = 1; i <= 16; i++) {
	    bits[i] = GetJpegChar();
	    count += bits[i];
	}

	if (count > 256) {
	    fprintf (stderr, "Bogus DHT counts");
	    return; /* MAL exit(1); */
	}

	for (i = 0; i < count; i++)
	    huffval[i] = GetJpegChar();

	length -= 1 + 16 + count;

	if (index & 0x10) {	/* AC table definition */
           fprintf(stderr,"Huffman table for lossless JPEG is not defined.\n");
	} else {		/* DC table definition */
	    htblptr = &dcPtr->dcHuffTblPtrs[index];
	}

	if (index < 0 || index >= 4) {
	    fprintf (stderr, "Bogus DHT index %d", index);
	    return; /* MAL exit(1); */
	}

	if (*htblptr == NULL) {
	 /* *htblptr = (HuffmanTable *) malloc (sizeof (HuffmanTable)); +++*/
	    *htblptr = &HuffmanTableMemory[index];
             if (*htblptr==NULL) {
                fprintf(stderr,"Can't malloc HuffmanTable\n");
                return; /* MAL exit(-1); */
             }
	}

	MEMCPY((*htblptr)->bits, bits, sizeof ((*htblptr)->bits));
	MEMCPY((*htblptr)->huffval, huffval, sizeof ((*htblptr)->huffval));
    }
}

/*
 *--------------------------------------------------------------
 *
 * GetDri --
 *
 *	Process a DRI marker
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Exits on error.
 *	Bitstream is parsed.
 *
 *--------------------------------------------------------------
 */
static void GetDri (DecompressInfo *dcPtr)
{
    if (Get2bytes () != 4) {
	fprintf (stderr, "Bogus length in DRI");
	return; /* MAL exit(1); */
    }

    dcPtr->restartInterval = (Ushort) Get2bytes ();
}

/*
 *--------------------------------------------------------------
 *
 * GetApp0 --
 *
 *	Process an APP0 marker.
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Bitstream is parsed
 *
 *--------------------------------------------------------------
 */
static void GetApp0 ()
{
    int length;

    length = Get2bytes () - 2;
    while (length-- > 0)	/* skip any remaining data */
	(void)GetJpegChar();
}

/*
 *--------------------------------------------------------------
 *
 * GetSof --
 *
 *	Process a SOFn marker
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Bitstream is parsed
 *	Exits on error
 *	dcPtr structure is filled in
 *
 *--------------------------------------------------------------
 */
static int GetSof (DecompressInfo *dcPtr, int code)
{
    int length;
    short ci;
    int c;
    JpegComponentInfo *compptr;
    
    code = code;

    length = Get2bytes ();

    dcPtr->dataPrecision = GetJpegChar();
    dcPtr->imageHeight = Get2bytes ();
    dcPtr->imageWidth = Get2bytes ();
    dcPtr->numComponents = GetJpegChar();

    /*
     * We don't support files in which the image height is initially
     * specified as 0 and is later redefined by DNL.  As long as we
     * have to check that, might as well have a general sanity check.
     */
    if ((dcPtr->imageHeight <= 0 ) ||
	(dcPtr->imageWidth <= 0) || 
	(dcPtr->numComponents <= 0)) {
	fprintf (stderr, "Empty JPEG image (DNL not supported)");
	return 0; /* MAL exit(1); */
    }

    if ((dcPtr->dataPrecision<MinPrecisionBits) ||
        (dcPtr->dataPrecision>MaxPrecisionBits)) {
	fprintf (stderr, "Unsupported JPEG data precision");
	return 0; /* MAL exit(1); */
    }

    if (length != (dcPtr->numComponents * 3 + 8)) {
	fprintf (stderr, "Bogus SOF length");
	return 0; /* MAL exit(1); */
    }

    for (ci = 0; ci < dcPtr->numComponents; ci++) {
	compptr = &dcPtr->compInfo[ci];
	compptr->componentIndex = ci;
	compptr->componentId = GetJpegChar();
	c = GetJpegChar();
	compptr->hSampFactor = (c >> 4) & 15;
	compptr->vSampFactor = (c) & 15;
	(void) GetJpegChar(); /* skip Tq */
    }

	return 1;

}/*endof GetSof */


/*
 *--------------------------------------------------------------
 *
 * GetSos --
 *
 *	Process a SOS marker
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Bitstream is parsed.
 *	Exits on error.
 *
 *--------------------------------------------------------------
 */
static void GetSos (DecompressInfo *dcPtr)
{
    int length;
    int i, ci, n, c, cc;
    JpegComponentInfo *compptr;

    length = Get2bytes ();

    /* 
     * Get the number of image components.
     */
    n = GetJpegChar();
    dcPtr->compsInScan = n;
    length -= 3;

    if (length != (n * 2 + 3) || n < 1 || n > 4) {
	fprintf (stderr, "Bogus SOS length");
	return; /* MAL exit(1); */
    }


    for (i = 0; i < n; i++) {
	cc = GetJpegChar();
	c = GetJpegChar();
	length -= 2;

	for (ci = 0; ci < dcPtr->numComponents; ci++)
	    if (cc == dcPtr->compInfo[ci].componentId) {
		break;
	    }

	if (ci >= dcPtr->numComponents) {
	    fprintf (stderr, "Invalid component number in SOS");
	    return; /* MAL exit(1); */
	}

	compptr = &dcPtr->compInfo[ci];
	dcPtr->curCompInfo[i] = compptr;
	compptr->dcTblNo = (c >> 4) & 15;
    }

    /*
     * Get the PSV, skip Se, and get the point transform parameter.
     */
    dcPtr->Ss = GetJpegChar(); 
    (void)GetJpegChar();
    c = GetJpegChar(); 
    dcPtr->Pt = c & 0x0F;
}/*endof GetSos */


/*
 *--------------------------------------------------------------
 *
 * GetSoi --
 *
 *	Process an SOI marker
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Bitstream is parsed.
 *	Exits on error.
 *
 *--------------------------------------------------------------
 */
static void GetSoi (DecompressInfo *dcPtr)
{

    /*
     * Reset all parameters that are defined to be reset by SOI
     */
    dcPtr->restartInterval = 0;
}

/*
 *--------------------------------------------------------------
 *
 * NextMarker --
 *
 *      Find the next JPEG marker Note that the output might not
 *	be a valid marker code but it will never be 0 or FF
 *
 * Results:
 *	The marker found.
 *
 * Side effects:
 *	Bitstream is parsed.
 *
 *--------------------------------------------------------------
 */
static int NextMarker ()
{
    int c, nbytes;

    nbytes = 0;
    do {
	/*
	 * skip any non-FF bytes
	 */
	do {
	    nbytes++;
	    c = GetJpegChar();
	} while (c != 0xFF);
	/*
	 * skip any duplicate FFs without incrementing nbytes, since
	 * extra FFs are legal
	 */
	do {
	    c = GetJpegChar();
	} while (c == 0xFF);
    } while (c == 0);		/* repeat if it was a stuffed FF/00 */

    return c;
}

/*
 *--------------------------------------------------------------
 *
 * ProcessTables --
 *
 *	Scan and process JPEG markers that can appear in any order
 *	Return when an SOI, EOI, SOFn, or SOS is found
 *
 * Results:
 *	The marker found.
 *
 * Side effects:
 *	Bitstream is parsed.
 *
 *--------------------------------------------------------------
 */
static JpegMarker ProcessTables (DecompressInfo *dcPtr)
{
  int c;

    while (1) {
	c = NextMarker ();

	switch (c) {
	case M_SOF0:
	case M_SOF1:
	case M_SOF2:
	case M_SOF3:
	case M_SOF5:
	case M_SOF6:
	case M_SOF7:
	case M_JPG:
	case M_SOF9:
	case M_SOF10:
	case M_SOF11:
	case M_SOF13:
	case M_SOF14:
	case M_SOF15:
	case M_SOI:
	case M_EOI:
	case M_SOS:
	    return ((JpegMarker)c);

	case M_DHT:
	    GetDht (dcPtr);
	    break;

	case M_DQT:
            fprintf(stderr,"Not a lossless JPEG file.\n");
	    break;

	case M_DRI:
	    GetDri (dcPtr);
	    break;

	case M_APP0:
	    GetApp0 ();
	    break;

	case M_RST0:		/* these are all parameterless */
	case M_RST1:
	case M_RST2:
	case M_RST3:
	case M_RST4:
	case M_RST5:
	case M_RST6:
	case M_RST7:
	case M_TEM:
	    fprintf (stderr, "Warning: unexpected marker 0x%02x", c);
	    break;

	default:		/* must be DNL, DHP, EXP, APPn, JPGn, COM,
				 * or RESn */
	    SkipVariable ();
	    break;
	}
    }
}/*endof ProcessTables */


/*
 *--------------------------------------------------------------
 *
 * ReadFileHeader --
 *
 *	Initialize and read the file header (everything through
 *	the SOF marker).
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Exit on error.
 *
 *--------------------------------------------------------------
 */
int ReadFileHeader (DecompressInfo *dcPtr)
{
    int c, c2;

    /*
     * Demand an SOI marker at the start of the file --- otherwise it's
     * probably not a JPEG file at all.
     */
    c = GetJpegChar();
    c2 = GetJpegChar();
    if ((c != 0xFF) || (c2 != M_SOI)) {
        if( c == EOF ) {
            fprintf(stderr, "Reached end of input file. All done!\n");
            /* fclose(outFile); */
            return 0; /* MAL exit(1); */
        } else {
	    fprintf (stderr, "Not a JPEG file. Found %02X %02X\n", c, c2);
		return 0;	/* MAL exit (1); */
        }
    }/*endif*/

    GetSoi (dcPtr);		/* OK, process SOI */

    /*
     * Process markers until SOF
     */
    c = ProcessTables (dcPtr);

    switch (c) {
    case M_SOF0:
    case M_SOF1:
    case M_SOF3:
	if (!GetSof (dcPtr, c)) return 0;
	break;

    default:
	fprintf (stderr, "Unsupported SOF marker type 0x%02x", c); return 0;
	break;
    }

	return 1;

}/*endof ReadFileHeader*/


/*
 *--------------------------------------------------------------
 *
 * ReadScanHeader --
 *
 *	Read the start of a scan (everything through the SOS marker).
 *
 * Results:
 *	1 if find SOS, 0 if find EOI
 *
 * Side effects:
 *	Bitstream is parsed, may exit on errors.
 *
 *--------------------------------------------------------------
 */
int ReadScanHeader (DecompressInfo *dcPtr)
{
    int c;

    /*
     * Process markers until SOS or EOI
     */
    c = ProcessTables (dcPtr);

    switch (c) {
    case M_SOS:
	GetSos (dcPtr);
	return 1;

    case M_EOI:
	return 0;

    default:
	fprintf (stderr, "Unexpected marker 0x%02x", c);
	break;
    }
    return 0;
}/*endof ReadScanHeader*/
