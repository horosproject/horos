/*
 * pmreadoptimise.c -- 
 * 
 * Code for loading mcu (Minimum Code Unit).
 * mcu is loaded only if the psv optimisation is enabled (optimize = 1)
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
#include "jpeg.h"
#include "mcu.h"
#include "proto.h"
#include "jpegless.h"
#include "io.h"


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

#define PM_MAXVAL 65536
        
int readimBufferOffset = 0;


/*
 *--------------------------------------------------------------
 *
 * PmRead --
 *
 *		        Read the source image file pointed by inFile.
 *
 * Results:
 *		Source image parameters such as width, height, sample
 *		        precision and number of color components are passed
 *		        out by enInfo.
 *
 * Side effects:
 *		        Source image is read into mcuTable, input image size
 *		        is counted in inputFileBytes.
 *
 *--------------------------------------------------------------
 */
void
PmRead (CompressInfo *enInfo, int optimi)
{
	int 				maxMcu;
	JpegComponentInfo 	*compPtr;
	int 				ci, i, j, c;
	MCU					mcu;
	
		/*
		* Initialize inputFileBytes to 2 bytes since magic number is 2 bytes. 
		* Read magic number, cols, rows, and max color level. Convert the
		* color level to precision bits.
		*/
		
	inputFileBytes=0;
	enInfo->numComponents = 1; /* Be careful: image must be grayscale */

	enInfo->compInfo = (JpegComponentInfo *) emalloc3 (enInfo->numComponents * sizeof (JpegComponentInfo));
	
		/*
		* Because JPEG standard (DIS) defined downsampling, in our 
      	* CompressInfo structure, we have sampling factor and an 
      	* index array MCUmembership, in case a MCU contains several 
    	* samples of one color component. But in lossless JPEG, one 
        * normally don't use downsampling.
		*/
		
	for (ci = 0; ci < enInfo->numComponents; ci++) 
	{
		compPtr = &(enInfo->compInfo[ci]);
		compPtr->componentId = ci;
		compPtr->componentIndex = ci;
		compPtr->hSampFactor = 1;
		compPtr->vSampFactor = 1;
	}
		/*
		* Set curCompInfo equal to compInfo since these is only 
		* one scan.
		*/
	enInfo->compsInScan = enInfo->numComponents;
	
	for (ci = 0; ci < enInfo->compsInScan; ci++) 
	{ 
		enInfo->curCompInfo[ci] = &(enInfo->compInfo[ci]);
	}
	/*
	 * Prepare array indexing MCU components into curCompInfo. 
	 */
	if (enInfo->compsInScan == 1) { enInfo->MCUmembership [0] = 0; } 
	else 
	{
		if (enInfo->compsInScan > 4) 
		{ 
		  return; /* MAL exit(-1); */
		}
		for (ci = 0; ci < enInfo->compsInScan; ci++) 
		{ 
			enInfo->MCUmembership [ci] = ci;
		}
	} /* else */ 
	   /*
		* Alloc mcuTable. Read source image into the table.
		* Apply point transform if Pt!=0. Update the input 
		* file size - inputFileBytes.
		*/ 
		
    /* really needed some initialization of these @!?! global variables ... */
    numMCU = 0;
    readimBufferOffset = 0;
    
	maxMcu = enInfo->imageWidth * enInfo->imageHeight; 
	inputFileBytes = 0; 

	/* if the psv optimisation is enabled, mcu is loaded */
	
	if (optimi == 1)
	{
		InitMcuTable (maxMcu, enInfo->compsInScan);

		for (i = 0; i < maxMcu; i++) 
		{
			mcu = MakeMCU ();
			for (j = 0; j < enInfo->compsInScan; j++) 
			{ 
			  if (enInfo->dataPrecision == 8) 
			    mcu [j] = (Ushort)  readimBuffer [readimBufferOffset++]; 
			  else 
			    mcu [j] = (Ushort) readim16Buffer [readimBufferOffset++];
        c = (int)mcu [j];  /* unix compatibility */
			  if ( c == EOF ) { return; }	
			  if (enInfo->Pt != 0) { mcu[j] >>= enInfo->Pt; }
			} /* end for j */
		} /* end for i */
	} /* end if optimi */
   
    if (enInfo->dataPrecision == 8) 
      inputFileBytes += maxMcu * enInfo->compsInScan;
    else 
      inputFileBytes += maxMcu * enInfo->compsInScan * 2;


} /* end of function PmRead */
