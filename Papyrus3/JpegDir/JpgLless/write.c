/*
 * write.c --
 *
 * Code for writing JPEG files.  Large parts are grabbed
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
/*
#include <malloc.h>
*/
#include <string.h>
#include "jpeg.h"
#include "mcu.h"
#include "io.h"
#include "proto.h"

/* Papyrus 3 redefined basic types */
#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyEalloc3H
#include "PapyEalloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapyFileSystem3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyEalloc3H
#include "Papaloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapFSys3.h"
#endif

#endif

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
 * EmitMarker --
 *
 *		  Emit a marker code into the output stream.
 *
 * Results:
 *		  None.
 *
 * Side effects:
 *		  None.
 *
*--------------------------------------------------------------
 */
static void
EmitMarker (JpegMarker mark)
{
	EmitByte (0xFF);
	EmitByte (mark);
}
/*
*--------------------------------------------------------------
 *
 * Emit2bytes --
 *
 *		  Emit a 2-byte integer; these are always MSB first in JPEG
 *		  files
 *
 * Results:
 *			None.
 *
 * Side effects:
 *			None.
 *
*--------------------------------------------------------------
 */
static void
Emit2bytes (int value)
{
	EmitByte ((value >> 8) & 0xFF);
	EmitByte (value & 0xFF);
}
/*
*--------------------------------------------------------------
 *
 * EmitDht --
 *
 *			Emit a DHT marker, follwed by the huffman data.
 *
 * Results:
 *			None
 *
 * Side effects:
 *			None
 *
*--------------------------------------------------------------
 */
static void
EmitDht (CompressInfo *cPtr, int index, int isAc)
{
	HuffmanTable *htbl;
	int length, i;
	if (isAc) {
		/* printf("Not a huffman table for lossless mode\n"); */
	} else {
			htbl = cPtr->dcHuffTblPtrs[index];
	}
	if (htbl == NULL) {
		/* printf ("Huffman table 0x%02x was not defined\n", index); exit (1); */
	}
	if (!htbl->sentTable) {
			EmitMarker (M_DHT);
			length = 0;
			for (i = 1; i <= 16; i++)
				length += htbl->bits[i];
Emit2bytes (length + 2 + 1 + 16); EmitByte (index);
for (i = 1; i <= 16; i++) EmitByte (htbl->bits[i]);
for (i = 0; i < length; i++) EmitByte (htbl->huffval[i]);
				htbl->sentTable = 1;
	}
}
/*
*--------------------------------------------------------------
 *
 * EmitDri --
 *
 *				Emit a DRI marker
 *
 * Results:
 *				None.
 *
 * Side effects:
 *				Exit on too big restart interval.
 *
*--------------------------------------------------------------
 */
static void
EmitDri (CompressInfo *cPtr)
{
	int restartInterval;
restartInterval = cPtr->restartInRows * cPtr->imageWidth;
	/*
* DIS only specifies 16 bits to store this value, so
		*/
	if (restartInterval > 65535) {
		/* printf("Error: Restart interval is too big.\n"); 
		printf("It should be less than %d rows.\n", 65535/cPtr->imageWidth); */
			return; /* MAL exit(1); */
	}
	EmitMarker (M_DRI);
	Emit2bytes (4);     /* length */
	Emit2bytes ((int)restartInterval);
}
/*
*--------------------------------------------------------------
 *
 * EmitSof --
 *
 *				Emit a SOF marker plus data.
 *
 * Results:
 *				None.
 *
 * Side effects:
 *				None.
 *
*--------------------------------------------------------------
 */
static void
EmitSof (CompressInfo *cPtr, JpegMarker code)
{
	int i;
	EmitMarker (code);
	Emit2bytes (3 * cPtr->numComponents + 2 + 5 + 1);   /* length */
	if ((cPtr->imageHeight > 65535) ||
		(cPtr->imageWidth > 65535)) {
		/* printf ("Maximum image dimension for JFIF is 65535 pixels\n"); */
		return; /* MAL exit(1); */
	}
	EmitByte (cPtr->dataPrecision);
	Emit2bytes ((int)cPtr->imageHeight);
	Emit2bytes ((int)cPtr->imageWidth);
	EmitByte (cPtr->numComponents);
	for (i = 0; i < cPtr->numComponents; i++) {
EmitByte (cPtr->compInfo[i].componentId);
EmitByte ((cPtr->compInfo[i].hSampFactor << 4) + cPtr->compInfo[i].vSampFactor);
		EmitByte (0);   /* Tq shall be 0 for lossless */
	}
}
/*
 *--------------------------------------------------------------
 *
 * EmitSos --
 *
 *		Emit a SOS marker plus data.
 *
 * Results:
 *		None.
 *
 * Side effects:
 *		None.
 *
 *--------------------------------------------------------------
 */
static void
EmitSos (CompressInfo *cPtr)
{
	int i;
	EmitMarker (M_SOS);
Emit2bytes (2*cPtr->compsInScan + 2 + 1 + 3);       /* length */ 
EmitByte (cPtr->compsInScan);                       /* Ns     */ 
for (i = 0; i < cPtr->compsInScan; i++) {           /* Cs,Td,Ta */ 
EmitByte (cPtr->curCompInfo[i]->componentId);
		EmitByte ((cPtr->curCompInfo[i]->dcTblNo << 4));
	}
	EmitByte (cPtr->Ss);        /* the PSV */
EmitByte (0);               /* Spectral selection end  - Se */ 
EmitByte(cPtr->Pt & 0x0F);  /* the point transform parameter */  
}
/*
 *--------------------------------------------------------------
 *
 * WriteFileTrailer --
 *
 *		Write the End of image marker at the end of a JPEG file.
 *
 *			XXX: This is hardwored into stdout.
 *
 * Results:
 *			None.
 *
 * Side effects:
 *			None.
 *
 *--------------------------------------------------------------
 */
void
WriteFileTrailer (CompressInfo *cPtr)
{
	EmitMarker (M_EOI);
}
/*
 *--------------------------------------------------------------
 *
 * WriteScanHeader --
 *
 *			Write the start of a scan (everything through the SOS marker).
 *
 * Results:
 *			None.
 *
 * Side effects:
 *			None.
 *
 *--------------------------------------------------------------
 */
void
WriteScanHeader (CompressInfo *cPtr)
{
	int i;
	/*
		* Emit Huffman tables.  Note that EmitDht takes care of
		* suppressing duplicate tables.
		*/
	for (i = 0; i < cPtr->compsInScan; i++) {
			EmitDht (cPtr, cPtr->curCompInfo[i]->dcTblNo, 0);
	}
	/*
* Emit DRI if required --- note that DRI value could change for each * scan. If it doesn't, a tiny amount of space is wasted in
* multiple-scan files. We assume DRI will never be nonzero for one * scan and zero for a later one.
		*/
	if (cPtr->restartInRows)
			EmitDri (cPtr);
	EmitSos (cPtr);
}
/*
 *--------------------------------------------------------------
 *
 * WriteFileHeader --
 *
 *			Write the file header.
 *
 * Results:
 *		None.
 *
 * Side effects:
 *		None.
 *
*--------------------------------------------------------------
 */
void
WriteFileHeader (CompressInfo *cPtr)
{
	EmitMarker (M_SOI); /* first the SOI */
	EmitSof (cPtr, M_SOF3);
}
