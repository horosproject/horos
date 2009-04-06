/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyRead3.c                                                  */
/*	Function : contains all the reading functions                           */
/********************************************************************************/

#define DEBUG 0

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <math.h>

#include "setjmp.h"
//#include "jpegless.h"       /* interface for JPEG lossless decompressor */
//#include "jpeglib.h"	    /* interface for JPEG lossy decompressor */
#include "jinclude8.h"
#include "jpeglib8.h"
#include "jerror8.h"
#include "jpeg_memsrc.h"

#ifdef MAYO_WAVE
#include "Mayo.h"	/* interface for wavelet decompressor */
#define TO_SWAP_MAYO
#endif /* MAYO_WAVE */

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif

extern void PapyrusLockFunction( int lock);

/********************************************************************************/
/*									 	*/
/*	ExtractJPEGlossy : gets and decode JPEG lossy pixel data		*/
/*	Nota : the PAPYRUS toolkit JPEG utility is based in part on the work of	*/
/*	the Independent JPEG Group (see copyright file included)		*/
/* 	return : the image							*/
/*										*/
/********************************************************************************/

PapyShort
ExtractJPEGlossy8 (PapyShort inFileNb, PapyUChar *ioImage8P, PapyULong inPixelStart, PapyULong *inOffsetTableP, int inImageNb, int inDepth, int mode)
{
  struct jpeg_decompress_struct	theCInfo;
  PapyUChar			theTmpBuf [256];
  PapyUChar			*theTmpBufP;
  PapyUShort		theGroup, theElement;
  PapyShort			theErr = 0;
  PapyULong			i, thePos, theLimit, theLength;
  int 				theRowStride;	 	/* physical row width in output buffer */
  PapyUChar			*theWrkChP; 		/* ptr to the image */
  PapyUChar			*theWrkCh8P; 		/* ptr to the image 8 bits */
  PapyUShort		*theWrkCh16P; 		/* ptr to the image 16 bits */
  PapyUShort		*theBuffer16P;
  PapyUChar			*theBuffer8P;
	struct jpeg_error_mgr			theJErr;
   
  /* position the file pointer to the begining of the image */
  
  Papy3FSeek (gPapyFile [inFileNb], SEEK_SET, (PapyLong) (inPixelStart + inOffsetTableP [inImageNb - 1]));
  
  /* read 8 chars from the file */
  theTmpBufP = (PapyUChar *) &theTmpBuf [0];
  i = 8L; 					/* grNb, elemNb & elemLength */
  if ((theErr = (PapyShort) Papy3FRead (gPapyFile [inFileNb], &i, 1L, theTmpBufP)) < 0)
  {
    Papy3FClose (&gPapyFile [inFileNb]);
    RETURN (theErr);
  } /* if */
    
  thePos     = 0L;
  theGroup   = Extract2Bytes (inFileNb, theTmpBufP, &thePos);
  theElement = Extract2Bytes (inFileNb, theTmpBufP, &thePos);
  theLength  = Extract4Bytes (inFileNb, theTmpBufP, &thePos);
  
  /* Pixel data fragment not found when expected */
  if ((theGroup != 0xFFFE) || (theElement != 0xE000))
  {
	RETURN (papBadArgument);
  }
  /* We set up the normal JPEG error routines, then override error_exit. */
  theCInfo.err 		 = jpeg_std_error (&theJErr);
  
  /* initialize the JPEG decompression object */
  jpeg_create_decompress (&theCInfo);

  /* specify the data source */
//  jpeg_stdio_src (&theCInfo, gPapyFile [inFileNb]);
	
	unsigned char *jpegPointer = (unsigned char*) malloc( theLength);
  if( jpegPointer && theLength)
	{
	  if ((theErr = (PapyShort) Papy3FRead (gPapyFile [inFileNb], &theLength, 1L, jpegPointer)) < 0)
	  {
		Papy3FClose (&gPapyFile [inFileNb]);
		RETURN (theErr);
	  } /* if */
	  
	  PapyrusLockFunction( 0);
	  
	  jpeg_memory_src( &theCInfo, jpegPointer, theLength);
	  
	  /* read file parameter */
	  (void) jpeg_read_header (&theCInfo, TRUE);

	  if (theCInfo.data_precision == 12)
	  {
		jpeg_destroy_decompress (&theCInfo);
		PapyrusLockFunction( 1);
		return papBadArgument;
	  }

	  if (gArrPhotoInterpret [inFileNb] == MONOCHROME1 ||
		  gArrPhotoInterpret [inFileNb] == MONOCHROME2)
		theCInfo.out_color_space = JCS_GRAYSCALE;

		switch (theCInfo.num_components)
		{
			case 1:
				theCInfo.jpeg_color_space = JCS_GRAYSCALE;
				theCInfo.out_color_space = JCS_GRAYSCALE;
			break;
			
			case 3:
			
				if( mode == UNKNOWN_COLOR)
				{
					
				}
				else
				{
					if( mode == RGB) theCInfo.jpeg_color_space = JCS_RGB;
					else
					if(	mode == YBR_FULL_422 ||
								mode == YBR_RCT ||
								mode == YBR_ICT ||
								mode == YBR_PARTIAL_422 ||
								mode == YBR_FULL) theCInfo.jpeg_color_space = JCS_YCbCr;
					else if (theCInfo.saw_JFIF_marker)
					{
						theCInfo.jpeg_color_space = JCS_YCbCr; /* JFIF implies YCbCr */
					}
					else if (theCInfo.saw_Adobe_marker)
					{
						switch (theCInfo.Adobe_transform)
						{
							case 0:
								theCInfo.jpeg_color_space = JCS_RGB;
							break;
							case 1:
								theCInfo.jpeg_color_space = JCS_YCbCr;
							break;
							default:
								theCInfo.jpeg_color_space = JCS_YCbCr; /* assume it's YCbCr */
							break;
						}
					}
					else theCInfo.jpeg_color_space = JCS_RGB;
				}
				
				theCInfo.out_color_space = JCS_RGB;
			break;
		}
	  /* theCInfo.out_color_space = JCS_YCbCr; */
	  
	  /* start the decompressor (set the decompression default params) */
	  (void) jpeg_start_decompress (&theCInfo);

	  /* JSAMPLEs per row in output buffer */
	  theRowStride = theCInfo.output_width * theCInfo.output_components;
	  if (inDepth == 16) 
		theRowStride *= 2;
		
	  /* allocate a one-row-high sample array that will go away when done with image */  
	  if (inDepth == 16)
	  {
		theBuffer16P = (PapyUShort *) emalloc3 ((PapyULong) theRowStride);
		theWrkCh16P = (PapyUShort *) ioImage8P;
	  }
	  else
	  {
		theBuffer8P = (PapyUChar *) emalloc3 ((PapyULong) theRowStride);
		theWrkCh8P  = (PapyUChar *) ioImage8P;
	  }

	  theWrkChP = (PapyUChar *) ioImage8P;

	  theLimit = theCInfo.output_width * theCInfo.output_components;

	  /* decompress the image line by line 8 bits */
	  if (inDepth == 8)
	  {
		while (theCInfo.output_scanline < theCInfo.output_height) 
		{
		  (void) jpeg_read_scanlines (&theCInfo, (JSAMPARRAY) &theWrkChP, 1);
		  theWrkChP += theLimit;

		} /* while ...line by line decompression of the image */
		
		/* frees the row used by the decompressor */
		efree3 ((void **) &theBuffer8P);
	  } /* if ...depth = 8 */

	  /* decompress the image line by line 16 bits */
	  else if (inDepth == 16)
	  {
		while (theCInfo.output_scanline < theCInfo.output_height) 
		{
		  (void) jpeg_read_scanlines (&theCInfo, (JSAMPARRAY) &theWrkCh16P, 1);
		  theWrkCh16P += theLimit;

		} /* while ...line by line decompression of the image */
		
		/* frees the row used by the decompressor */
		efree3 ((void **) &theBuffer16P);
	  } /* else ...depth = 16 bits */
	
  /* tell the JPEG decompressor we have finish the decompression */  
  (void) jpeg_finish_decompress (&theCInfo);
  
  /* This is an important step since it will release a good deal of memory. */
  jpeg_destroy_decompress(&theCInfo);

	 free( jpegPointer);
	 
	 PapyrusLockFunction( 1);
	}
  return theErr;

} /* endof ExtractJPEGlossy */

void compressJPEG (int inQuality, char* filename, unsigned char* inImageBuffP, int inImageHeight, int inImageWidth, int monochrome)
{
	struct jpeg_compress_struct	theCInfo;
	struct jpeg_error_mgr 	theJerr;

	JSAMPROW			theRowPointer [1];
	int					theRowStride;
	unsigned int		j;
	FILE				*outfile;

	/* Step 1: allocate and initialize JPEG compression object */

	theCInfo.err = jpeg_std_error (&theJerr);
	jpeg_create_compress (&theCInfo); 

	/* Step 2: specify data destination (eg, a file) */
	if ((outfile = fopen( filename, "wb")) == NULL)
	{
		printf("error");
	}
	jpeg_stdio_dest ((j_compress_ptr) &theCInfo, outfile); 

	/* Step 3: set parameters for compression */
	theCInfo.image_width  = inImageWidth;
	theCInfo.image_height = inImageHeight;

	if ( monochrome)
	{
		theCInfo.input_components = 1;
		theCInfo.in_color_space   = JCS_GRAYSCALE;
	}
	else
	{
		theCInfo.input_components = 3;
		theCInfo.in_color_space = JCS_RGB;
	}

	jpeg_set_defaults ((j_compress_ptr) &theCInfo);
	jpeg_set_quality (&theCInfo, inQuality, TRUE); /* limit to baseline-JPEG values */

	/* Step 4: Start compressor */

	jpeg_start_compress (&theCInfo, TRUE); 

	theRowStride = inImageWidth * theCInfo.input_components;
	j = 0;
	while (j < theCInfo.image_height) 
	{
	  theRowPointer [0] = (unsigned char *) (& inImageBuffP [j * theRowStride]);

	/*(void) jpeg_write_scanlines(&theCInfo, theRowPointer, 1); */
	j += (int) jpeg_write_scanlines (&theCInfo, theRowPointer, 1);
	} /* while */

	/* Step 6: Finish compression */

	jpeg_finish_compress (&theCInfo);

	/* We can use jpeg_abort to release memory and reset global_state */
	jpeg_abort( (j_common_ptr) &theCInfo);
	
	fclose(outfile);
	
	/* Step 7: release JPEG compression object */
	jpeg_destroy_compress (&theCInfo);

	return;
}
