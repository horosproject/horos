/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyRead3.c                                                  */
/*	Function : contains all the reading functions                           */
/*	Authors  : Matthieu Funk                                                */
/*                 Christian Girard                                             */
/*                 Jean-Francois Vurlod                                         */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 12.1990	version 1.0                                     */
/*                 04.1991	version 1.1                                     */
/*                 12.1991	version 1.2                                     */
/*                 06.1993	version 2.0                                     */
/*                 06.1994	version 3.0                                     */
/*                 06.1995	version 3.1                                     */
/*                 02.1996	version 3.3                                     */
/*                 02.1999	version 3.6                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                 10.2001      version 3.71 MAJ Dicom par CHG                  */
/*                                                                              */
/* 	(C) 1990-2001 The University Hospital of Geneva                         */
/*	All Rights Reserved                                                     */
/*                                                                              */
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
#include "jinclude12.h"
#include "jpeglib12.h"
#include "jerror12.h"

#ifdef MAYO_WAVE
#include "Mayo.h"	/* interface for wavelet decompressor */
#define TO_SWAP_MAYO
#endif /* MAYO_WAVE */

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif

/********************************************************************************/
/*									 	*/
/*	Needed for the error manager of the JPEG lossy library			*/
/*										*/
/********************************************************************************/

struct SErrorMgr 
{
  struct jpeg_error_mgr pub;	/* "public" fields */

  jmp_buf setjmp_buffer;	/* for return to caller */
}; /* struct */

typedef struct SErrorMgr *SErrorMgrP;

/********************************************************************************/
/*									 	*/
/* Here's the routine that will replace the standard error_exit method: 	*/
/* for JPEG lossy								*/
/*									 	*/
/********************************************************************************/

METHODDEF(void)
my_error_exit (j_common_ptr ioCInfo)
{
  /* ioCInfo->err really points to a SErrorMgr struct, so coerce pointer */
  SErrorMgrP theErr = (SErrorMgrP) ioCInfo->err;

  /* Always display the message. */
  /* We could postpone this until after returning, if we chose. */
  (*ioCInfo->err->output_message) (ioCInfo);

  /* Return control to the setjmp point */
#ifdef Mac
  longjmp (theErr->setjmp_buffer, 1);
#endif

} /* endofunction my_error_exit */

/********************************************************************************/
/*									 	*/
/*	ExtractJPEGlossy : gets and decode JPEG lossy pixel data		*/
/*	Nota : the PAPYRUS toolkit JPEG utility is based in part on the work of	*/
/*	the Independent JPEG Group (see copyright file included)		*/
/* 	return : the image							*/
/*										*/
/********************************************************************************/

static short  alreadyUncompressing = FALSE;

PapyShort
ExtractJPEGlossy12 (PapyShort inFileNb, PapyUChar *ioImage8P, PapyULong inPixelStart, PapyULong *inOffsetTableP, int inImageNb, int inDepth)
{
  struct SErrorMgr		theJErr;		 /* the JPEG error manager var */
  struct jpeg_decompress_struct	theCInfo;
  PapyUChar			theTmpBuf [256];
  PapyUChar			*theTmpBufP;
  PapyUShort			theGroup, theElement;
  PapyShort			theErr = 0;
  PapyULong			i, thePos, theLimit;
  int 				theRowStride;	 	/* physical row width in output buffer */
  int				theLoop;
  PapyUChar			*theWrkChP; 		/* ptr to the image */
  PapyUChar			*theWrkCh8P; 		/* ptr to the image 8 bits */
  PapyUShort			*theWrkCh16P; 		/* ptr to the image 16 bits */
  PapyUShort			*theBuffer16P;
  PapyUChar			*theBuffer8P;
   
  while( alreadyUncompressing == TRUE)
  {
  }
  alreadyUncompressing = TRUE;
  fprintf(stdout, "ExtractJPEGlossy12\r");
  
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
  theGroup   = Extract2Bytes (theTmpBufP, &thePos, gArrTransfSyntax [inFileNb]);
  theElement = Extract2Bytes (theTmpBufP, &thePos, gArrTransfSyntax [inFileNb]);
    
  /* Pixel data fragment not found when expected */
  if ((theGroup != 0xFFFE) || (theElement != 0xE000)) RETURN (papBadArgument);
  
  /* We set up the normal JPEG error routines, then override error_exit. */
  theCInfo.err 		 = jpeg_std_error (&theJErr.pub);
//  theJErr.pub.error_exit = my_error_exit;
  /* Establish the setjmp return context for my_error_exit to use. */
//#ifdef Mac
//  if (setjmp (theJErr.setjmp_buffer)) 
//  {
//    jpeg_destroy_decompress (&theCInfo);
//    return 0;
//  }/* if */
//#endif

  /* initialize the JPEG decompression object */
  jpeg_create_decompress (&theCInfo);

  /* specify the data source */
  jpeg_stdio_src (&theCInfo, gPapyFile [inFileNb]);

  /* read file parameter */
  (void) jpeg_read_header (&theCInfo, TRUE);

  if (gArrPhotoInterpret [inFileNb] == MONOCHROME1 ||
      gArrPhotoInterpret [inFileNb] == MONOCHROME2)
    theCInfo.out_color_space = JCS_GRAYSCALE;

  if (gArrPhotoInterpret [inFileNb] == RGB)
    theCInfo.out_color_space = JCS_RGB;
  /* theCInfo.out_color_space = JCS_YCbCr; */

	  
  /* start the decompressor (set the decompression default params) */
  (void) jpeg_start_decompress (&theCInfo);

  /* JSAMPLEs per row in output buffer */
  theRowStride = theCInfo.output_width * theCInfo.output_components *2;
//  if (inDepth == 16) 
  //  theRowStride *= 2;
    
  /* allocate a one-row-high sample array that will go away when done with image */  
//  if (inDepth == 16)
  {
    theBuffer16P = (PapyUShort *) emalloc3 ((PapyULong) theRowStride);
    theWrkCh16P = (PapyUShort *) ioImage8P;
  }
//  else
//  {
//    theBuffer8P = (PapyUChar *) emalloc3 ((PapyULong) theRowStride);
//    theWrkCh8P  = (PapyUChar *) ioImage8P;
//  }

  theWrkChP = (PapyUChar *) ioImage8P;

  theLimit = theCInfo.output_width * theCInfo.output_components;

//  /* decompress the image line by line 8 bits */
  if (inDepth == 8)
  {
//    while (theCInfo.output_scanline < theCInfo.output_height) 
//    {
//      (void) jpeg_read_scanlines (&theCInfo, (JSAMPARRAY) &theBuffer8P, 1);
//      
//      /* put the scanline in the image */
//      for (theLoop = 0; theLoop < (int) theLimit; theLoop ++)
//      {
//      //  if (theCInfo.out_color_space == JCS_GRAYSCALE)
//        //  if (theBuffer8P [theLoop] > 255) 
//          //  theBuffer8P [theLoop] = 255;
//            
//        *theWrkChP = (PapyUChar) theBuffer8P [theLoop]; 
//        theWrkChP++;  
//      } /* for */
//
//    } /* while ...line by line decompression of the image */
//    
//    /* frees the row used by the decompressor */
//    efree3 ((void **) &theBuffer8P);
  } /* if ...depth = 8 */

  /* decompress the image line by line 16 bits */
  else if (inDepth == 16)
  {

    while (theCInfo.output_scanline < theCInfo.output_height) 
    {
	  jpeg_read_scanlines (&theCInfo, (JSAMPARRAY) &theWrkCh16P, 1);
	  theWrkCh16P += theLimit;

    } /* while ...line by line decompression of the image */
    
    /* frees the row used by the decompressor */
    efree3 ((void **) &theBuffer16P);
  } /* else ...depth = 16 bits */
    
  /* tell the JPEG decompressor we have finish the decompression */  
  (void) jpeg_finish_decompress (&theCInfo);
  
  /* MAL added : cf Example.c */
  /* Step 8: Release JPEG decompression object */

  /* This is an important step since it will release a good deal of memory. */
  jpeg_destroy_decompress(&theCInfo);
	
  alreadyUncompressing = FALSE;

  return theErr;

} /* endof ExtractJPEGlossy */

