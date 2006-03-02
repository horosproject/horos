/*
 * Decompoptimise.c --
 *
 * This is the routine that is called to decompress a frame of angiographic
 * image data. It is based on the program originally named ljpgtopnm.c.
 * Major portions taken from the Independetn JPEG Group' software, and
 * from the Cornell lossless JPEG code (the original copyright notices
 * for those packages appears below).
 * Adaptations were performed by the OSIRIS team in order to optimize the
 * speed. Only 8 or 16-bits grayscale images can be decompressed.
 * ---------------------------------------------------------------
 *
 * This is the main routine for the lossless JPEG decoder.  Large
 * parts are stolen from the IJG code, so:
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
 * Changes made by Yves Ligier and David Bandon
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
/*#include <ctype.h>*/
#include "io.h"
#include "jpeg.h"
#include "mcu.h"
#include "proto.h"


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


DecompressInfo dcInfo;
      
PAPY_FILE JpegInFile; 

/*
 *--------------------------------------------------------------
 *
 * ReadJpegData --
 *
 *	This is an interface routine to the JPEG library.  The
 *	JPEG library calls this routine to "get more data"
 *
 * Results:
 *	Number of bytes actually returned.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
PapyULong ReadJpegData (PapyUChar *buffer, PapyULong numBytes)
{
    PapyULong foo = 1L;
    PapyShort err;

    err = Papy3FRead (JpegInFile, (PapyULong *) &numBytes, (PapyULong) foo, (void *) buffer);
    if (err<0) {
    			return err;
    			}
    return numBytes;   
}

static short alreadyUncompressing = FALSE;

void JPEGLosslessDecodeImage (PAPY_FILE inFile, PapyUShort *image16, int depth, PapyULong length)
{ 
  while( alreadyUncompressing == TRUE)
  {
  }
  alreadyUncompressing = TRUE;

    /* Initialization */
    JpegInFile = inFile; 
    MEMSET (&dcInfo, 0, sizeof (dcInfo));
    inputBufferOffset = 0;

    /* Allocate input buffer */
    inputBuffer = (PapyUChar *) emalloc3 ((PapyULong)length+2000);
    if (inputBuffer == NULL)
	{
		alreadyUncompressing = FALSE;
		return;
	}
	
    /* Read input buffer */
    ReadJpegData ((PapyUChar *)inputBuffer, length);
    inputBuffer [length] = EOF;

    if (!ReadFileHeader (&dcInfo)) { alreadyUncompressing = FALSE; return;}/* Read JPEG File header */ 
    if (!ReadScanHeader (&dcInfo)) { alreadyUncompressing = FALSE;  return;}/* Read the scan header.  */
    
    /* 
     * Decode the image bits stream. Clean up everything when
     * finished decoding.
     */
    DecoderStructInit (&dcInfo);
    HuffDecoderInit (&dcInfo);
    DecodeImage (&dcInfo, (PapyUShort **) &image16, depth);

    /* Free input buffer */
    efree3 ((void **)&inputBuffer);
	
    alreadyUncompressing = FALSE;
	
    return;
}

void JPEGDecode_WithoutFile (PapyUShort *JPEGPix, PapyUShort *image16,int depth, PapyULong length)

{ 

    /* Initialization */
    MEMSET (&dcInfo, 0, sizeof (dcInfo));
    inputBufferOffset = 0;

    /* Allocate input buffer */
    inputBuffer = (PapyUChar *) JPEGPix;
    if (inputBuffer == NULL) { 
    							/* printf("Error with malloc\n"); */
    							return; /* MAL exit(-1); */
    						  }

    inputBuffer [length] = EOF;

    if (!ReadFileHeader (&dcInfo)) return;/* Read JPEG File header */ 
    if (!ReadScanHeader (&dcInfo)) return;/* Read the scan header.  */
    
    /* 
     * Decode the image bits stream. Clean up everything when
     * finished decoding.
     */
    DecoderStructInit (&dcInfo);
    HuffDecoderInit (&dcInfo);
    DecodeImage (&dcInfo, (PapyUShort **) &image16, depth);

    /* Free input buffer */
    /* efree3 ((void **)&inputBuffer); */
    
    return;
}
