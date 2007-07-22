/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyWrite3.c                                                 */
/*	Function : contains all the writing stuff                               */
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
/* 	(C) 1990-2001                                                           */
/*	The University Hospital of Geneva                                       */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/


#ifdef Mac
#pragma segment papy3
#endif


/* ------------------------- includes -----------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <fcntl.h>		/* open */

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif


//#include "jpegless.h"       	/* interface for JPEG lossless decompressor */
//#include "jpeglib.h"	    	/* interface for JPEG lossy decompressor */
#include "jinclude16.h"
#include "jpeglib16.h"
#include "jerror16.h"

#ifdef MAYO_WAVE
#include "Mayo.h"	 	/* interface for MAYO/SPIHT wavelet compression */
#define TO_SWAP_MAYO
#endif




/********************************************************************************/
/*										*/
/*	Put2Bytes : puts a 2-Bytes value (USS, SS or AT) in the write buffer.	*/
/*										*/
/********************************************************************************/

void
Put2Bytes (PapyUShort inS, unsigned char *ioBufP, PapyULong *ioPosP)

/*unsigned short inS;					 the value to put */
/*unsigned char *ioBufP;			   the buffer to write to */
/*unsigned long *ioPosP;	       the current position in the buffer */

{
  PapyUChar *theCharP;
  
    
  theCharP  = ioBufP;
  theCharP += *ioPosP;
  *ioPosP  += 2;
    
  /* put the element according to the little-endian transfert syntax */
  *theCharP       = (unsigned char)  inS;
  *(theCharP + 1) = (unsigned char) (inS >> 8);
    
} /* endof Put2Bytes */


/********************************************************************************/
/*										*/
/*	Put4Bytes : puts a 4-Byte value (UL, SL or FL) in the write buffer.	*/
/*										*/
/********************************************************************************/

void
Put4Bytes (PapyULong inLong, unsigned char *ioBufP, PapyULong *ioPosP)

/*PapyULong 	inLong;					 the value to put */
/*unsigned char	*ioBufP;			   the buffer to write to */
/*PapyULong	*ioPosP;	       the current position in the buffer */

{
  PapyUChar *theCharP;
    
    
  theCharP  =  ioBufP;
  theCharP += *ioPosP;
  *ioPosP  += 4;

  /* put the element according to the little endian syntax */
  *theCharP       = (unsigned char)  inLong;
  *(theCharP + 1) = (unsigned char) (inLong >> 8);
  *(theCharP + 2) = (unsigned char) (inLong >> 16);
  *(theCharP + 3) = (unsigned char) (inLong >> 24);
    
} /* endof Put4Bytes */


/********************************************************************************/
/*										*/
/*	Put8Bytes : puts a 8-Byte value (FD) in the write buffer.		*/
/*										*/
/********************************************************************************/

void
Put8Bytes (PapyFloatDouble inFlDbl, unsigned char *ioBufP, PapyULong *ioPosP)

/*PapyFloatDouble inFlDbl;				 the value to put */
/*unsigned char	*ioBufP;			   the buffer to write to */
/*PapyULong	*ioPosP;	       the current position in the buffer */

{
  unsigned char   *theCharDoubleP;
  PapyUChar      *theCharP;
  PapyShort	  i;
  
    
  theCharDoubleP = (unsigned char *) &inFlDbl;
    
  theCharP  = ioBufP;
  theCharP += *ioPosP;
  *ioPosP  += 8;
    
  /* loop on the bytes of the float double to code it */
  for (i = 0; i < 4; i++)
  { 
    *theCharP       = * theCharDoubleP;
    *(theCharP + 1) = *(theCharDoubleP + 1);
    theCharP       += 2;
    theCharDoubleP += 2;
  } /* for */

} /* endof Put8Bytes */


/********************************************************************************/
/*										*/
/*	PutString : puts a string in the write buffer				*/
/*										*/
/********************************************************************************/

void
PutString (char *inCharP, enum EV_R_T inVR, unsigned char *ioBufP, PapyULong *ioPosP)

/*char 		*inCharP;		                the value to put */
/*enum EV_R_T 	inVR;	       is it an ASCII text or an ASCII numeric ? */
/*unsigned char *ioBufP;		          the buffer to write to */
/*PapyULong 	*ioPosP;	      the current position in the buffer */

{
  int 		theSize, i, theHasNull = FALSE;
  PapyChar	*theChP, *theCP, *theDupP;
  

  theSize = (int) strlen (inCharP);
    
  /* duplicate the string */
  theChP = (char *) ecalloc3 ((PapyULong) (theSize + 2), (PapyULong) sizeof (char));
  theChP = strcpy (theChP, inCharP);
    
  /* if the string has not an even length it must be padded ... */
  if ((theSize % 2) != 0)
    /* ...either with a NULL char ... */
    if (inVR == UI) 
    {
      theChP [theSize] = 0x00;
      strcat (theChP, "\0");
      theHasNull = TRUE;
    }
    /* ... or with a single SPACE */
    else theChP = strcat (theChP, " ");

  /* put the char in the order of occurence (left to right) */
  theCP    = theChP;
  theDupP  = (PapyChar *) ioBufP;
  theDupP += *ioPosP;
  for (i = 0; i < (int) strlen (theChP); i++, theCP++, theDupP++)
    *theDupP = *theCP;
 
  (*ioPosP) += (PapyULong) strlen (theChP);
    
  /* case of an odd UI string. Necessary as the NULL char is never taken into acount */
  if (theHasNull)
  {
    (*ioPosP) ++;
    *theDupP = 0x00;
  }
    
  /* free the allocated string */    
  efree3 ((void **) &theChP);
    
} /* endof PutString */



/********************************************************************************/
/*										*/
/*	Put1ByteImage : puts a 1-Bytes image (OB) in the write buffer.		*/
/*										*/
/********************************************************************************/

void
Put1ByteImage (char *inImP, unsigned char *ioBufP, PapyULong *ioPosP, PapyULong inSize)

/*char		*inImP;				     pointer to the image */
/*unsigned char *ioBufP;			   the buffer to write to */
/*PapyULong	*ioPosP;	       the current position in the buffer */
/*PapyULong	inSize;			   the size of the element to put */

{
  PapyUChar	*theUCharSP;
  PapyUChar	*theUCharBP;
  PapyULong	i;

  /* position the pointer to its position in the destination buffer */
  theUCharBP  = ioBufP;
  theUCharBP += (*ioPosP);
    
  /* initialize the pointer to the image to copy */
  theUCharSP = (PapyUChar *) inImP;
    
  /* copy the elements to the buffer */
  for (i = 0L; i < inSize; i++, theUCharBP++, theUCharSP++)
    *theUCharBP = *theUCharSP;
      
  /* move the pointer to the current position in the buffer */
  *ioPosP += inSize;
    
} /* endof Put1ByteImage */



/********************************************************************************/
/*										*/
/*	Put2BytesImage : puts a 2-Bytes image (OW) in the write buffer.		*/
/*										*/
/********************************************************************************/

void
Put2BytesImage (PapyUShort *inImP, PapyUChar *ioBufP, PapyULong *ioPosP, PapyULong inSize)

/*PapyUShort	*inImP;				     pointer to the image */
/*unsigned char *ioBufP;			   the buffer to write to */
/*PapyULong	*ioPosP;	       the current position in the buffer */
/*PapyULong	inSize;		  the size in bytes of the element to put */

{
  PapyUShort		*theUShortP;
  PapyULong		theNbOfShort, i;
  PapyUChar	        *theUCharP;
    

  /* position the pointer to its position in the destination buffer */
  theUCharP  = ioBufP;
  theUCharP += *ioPosP;

  /* copy the elements to the buffer */
  theNbOfShort = inSize / 2;

  for (i = 0L, theUShortP = inImP; i < theNbOfShort; theUShortP++, i++)
  {
    *theUCharP       = (unsigned char) *theUShortP;
    *(theUCharP + 1) = (unsigned char) ((*theUShortP) >> 8);
    
    /* increment */
    theUCharP += 2;
      
  } /* for */

  /* move the pointer to the current position in the buffer */
  *ioPosP += inSize;
    
} /* endof Put2BytesImage */



/********************************************************************************/
/*										*/
/*	PutValue : puts a value in the write buffer				*/
/*										*/
/********************************************************************************/

void
PutValue (UValue_T *inValP, enum EV_R_T inVR, unsigned char *ioBufP, PapyULong *ioPosP)

/*UValue_T 	*inValP;				 the value to put */
/*enum EV_R_T 	inVR;			    ASCII text or ASCII numeric ? */
/*unsigned char	*ioBufP;			   the buffer to write to */
/*PapyULong 	*ioPosP;		 the position in the write buffer */

{
  switch (inVR)
  {
    case SS :
      Put2Bytes (inValP->ss, ioBufP, ioPosP);
      break;
    
    case USS :
    case AT :
      Put2Bytes (inValP->us, ioBufP, ioPosP);
      break;      
    
    case SL :
      Put4Bytes (inValP->sl, ioBufP, ioPosP);
      break;
    
    case UL :
      Put4Bytes (inValP->ul, ioBufP, ioPosP);
      break;
    
    case FL :
      Put4Bytes ((PapyULong) inValP->fl, ioBufP, ioPosP);
      break;
    
    case FD :
      Put8Bytes (inValP->fd, ioBufP, ioPosP);
      break;
    
    case AE :
    case AS :
    case CS :
    case DA :
    case DS :
    case DT :
    case IS :
    case LO :
    case LT :
    case PN :
    case SH :
    case ST :
    case TM :
    case UI :
    case UT :
      PutString (inValP->a, inVR, ioBufP, ioPosP);
      break;
    
    case SQ :
      break;
    
    default :	/* values of type OB & OW must be put using Put1/2Byte(s)Image */
      break;      
  } /* switch ...value representation */
    
} /* endof PutValue */



/********************************************************************************/
/*										*/
/*	Write_File : ,								*/
/*										*/
/*	return : return 0 if no problem					 	*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/
   
PapyShort
WriteFile (j_compress_ptr inCinfo, PapyULong inDataCount, PAPY_FILE inFp, 
           PapyUChar *outJpegDP, int inSaveJpeg)
{
//  void* dest = (void*) inCinfo->dest;
//  
//  
//  inFp = inFp;	/* no comment */
//
//  if (inSaveJpeg)
//    if (Papy3FWrite (inFp, (PapyULong *) &inDataCount, 1L, (void *) dest->buffer) != 0) 
//      return (-1);
//
//  memcpy (outJpegDP, dest->buffer, inDataCount);

  return (1);

} /* endof WriteFile */

/********************************************************************************/
/*                                                                              */
/*	JPEGLossyEncodeImage :                                                  */
/*                                                                              */
/*	return : return 0 if no problem                                         */
/*		 standard error message otherwise                               */
/*                                                                              */
/********************************************************************************/

PapyShort JPEGLossyEncodeImage (PapyShort inFileNb, int inQuality, PapyUChar *outJpegFilename, PapyUChar *inImageBuffP, PapyUChar **outJPEGDataP, PapyULong *outJPEGsizeP,int inImageHeight, int inImageWidth, int inDepth, int inSaveJpeg)
{
//  struct jpeg_compress_struct	theCInfo;
//  struct jpeg_error_mgr 	theJerr;
//  PAPY_FILE		        theFp = NULL;
//
///* #ifdef SAVE_JPEG		*/
//  void 			*theFSSpecP; 
//  PAPY_FILE		theVRefNum;
//  char			theFilename [512];
///* #endif             */
//
//  JSAMPROW		theRowPointer [1];		/* pointer to JSAMPLE row[s] */
//  int			theRowStride;			/* physical row width in image buffer */
//  unsigned int		j;
//  PapyULong		theDataCount;
//  PapyUChar		*theJPEGBuffP;
//  PapyUShort		*theImBuffP;
//
//
//  /* Temporary routine for Compression evaluation (DAB) */
//#ifdef SAVE_RAW
//  PAPY_FILE		theFps;	
//  void 			*theFSSpecsP;
//  PAPY_FILE		theVRefNums;
//  char			theFilenames [20];
//  long			theSizer;
//  PapyUChar		*theValTempP, *theFinalValP, *theFinaleValP;
//  PapyUChar		theHigh, theLow;
//  int			is, js;
//  
//  
//  strcpy((char *) theFilenames, "data.raw");
//
//  theFSSpecsP   = NULL;
//  theValTempP   = (PapyUChar *) inImageBuffP;
//  theFinalValP  = (PapyUChar *) inImageBuffP;
//  theFinaleValP = (PapyUChar *) inImageBuffP;
//
//#ifdef TO_SWAP
//  if (inDepth == 16)
//  {
//    for (js = 0; js < inImageHeight; js++) 
//    {
//      for (is = 0; is < inImageWidth; is++) 
//      {
//	theLow        = *theValTempP;
//	theValTempP++;
//	theHigh       = *theValTempP;
//	theValTempP++;
//	*theFinalValP = theHigh;
//	theFinalValP++;
//	*theFinalValP = theLow;
//	theFinalValP++;
//      } /* for ...is */
//    } /* for ...js */
//  } /* if ... depth = 16 */
//#endif /* TO_SWAP */
//
//  if (Papy3FCreate ((char *) theFilenames, theVRefNums, &theFps, &theFSSpecsP) != 0) 
//    RETURN (papFileCreationFailed);
//
//  if (Papy3FOpen ((char *) theFilenames, 'w', theVRefNums, &theFps, &theFSSpecsP) != 0) 
//    RETURN (papOpenFile);
//
//  if (inDepth == 16) 
//    theSizer = (long) (inImageWidth * inImageHeight * 2);
//  else 
//    theSizer = (long) (inImageWidth * inImageHeight);
//
//  if (Papy3FWrite (theFps, (PapyULong *) &theSizer, 1L, (void *) theFinaleValP) != 0) 
//    RETURN (papWriteFile);
//
//  Papy3FClose (&theFps);
//  
//#endif /* SAVE_RAW */
//
//
//  /* Step 1: allocate and initialize JPEG compression object */
//
//  theCInfo.err = jpeg_std_error (&theJerr);
//  jpeg_create_compress (&theCInfo); 
//
//  /* Step 2: specify data destination (eg, a file) */
//
///* #ifdef SAVE_JPEG */
//
//  if (inSaveJpeg)
//  {
//    if (outJpegFilename == NULL)
//      strcpy ((char *) theFilename, "data.jpeg");
//    else
//      strcpy ((char *) theFilename, (const char *) outJpegFilename);
//    theFSSpecP = NULL;
//    if (Papy3FCreate ((char *) theFilename, theVRefNum, &theFp, &theFSSpecP) != 0) 
//      RETURN (papFileCreationFailed);
//
//    if (Papy3FOpen ((char *) theFilename, 'w', theVRefNum, &theFp, &theFSSpecP) != 0) 
//      RETURN (papOpenFile);
//  } /* endif */
//
///* #endif */
//
//  jpeg_stdio_dest ((j_compress_ptr) &theCInfo, (PAPY_FILE *) &theFp); 
//
//  /* Step 3: set parameters for compression */
//
//  theCInfo.image_width  = inImageWidth; 	/* image width and height, in pixels */
//  theCInfo.image_height = inImageHeight;
//
//  if (gArrPhotoInterpret [inFileNb] == MONOCHROME1 ||
//    gArrPhotoInterpret [inFileNb] == MONOCHROME2)
//  {
//    theCInfo.input_components = 1;		/* # of color components per pixel */
//    theCInfo.in_color_space   = JCS_GRAYSCALE; 	/* colorspace of input image */
//  }
//
//  if (gArrPhotoInterpret [inFileNb] == RGB)
//  {
//    theCInfo.input_components = 3;		/* # of color components per pixel */
//    theCInfo.in_color_space = JCS_RGB;
//  /* theCInfo.out_color_space = JCS_YCbCr; */
//  }
//
//  jpeg_set_defaults ((j_compress_ptr) &theCInfo);
//  jpeg_set_quality (&theCInfo, inQuality, TRUE); /* limit to baseline-JPEG values */
//
//  /* Step 4: Start compressor */
//
//  jpeg_start_compress (&theCInfo, TRUE); 
//
//  /* Step 5: while (scan lines remain to be written) */
//  if (inDepth == 16)
//    theImBuffP = (PapyUShort *) inImageBuffP;
//
//
//  theRowStride = inImageWidth * theCInfo.input_components;
//  j = 0;
//  while (j < theCInfo.image_height) 
//  {
//    /* printf("next_scanline; %d", j); */
//    if (inDepth == 8)
//      theRowPointer [0] = (unsigned char *) (& inImageBuffP [j * theRowStride]);
//    else
//      theRowPointer [0] = (unsigned char *) (& theImBuffP [j * theRowStride]);
//    
//    /*(void) jpeg_write_scanlines(&theCInfo, theRowPointer, 1); */
//    j += (int) jpeg_write_scanlines (&theCInfo, theRowPointer, 1);
//  } /* while */
//
//  /* Step 6: Finish compression */
//
//  jpeg_finish_compress (&theCInfo);
//
//    /* Step 5b: Fill JPEG Buffer */
//
//  theDataCount = (PapyULong) ((inImageWidth * inImageHeight) - 
//			      theCInfo.dest->free_in_buffer + 5);
//  theJPEGBuffP = (PapyUChar *) ecalloc3 ((PapyULong) theDataCount, (PapyULong) sizeof (PapyUChar));
//  WriteFile (&theCInfo, theDataCount, (PAPY_FILE) theFp, (PapyUChar *) theJPEGBuffP, inSaveJpeg);
//  *outJPEGDataP = (PapyUChar *) theJPEGBuffP;
//  *outJPEGsizeP = theDataCount;
//
///* #ifdef SAVE_JPEG */
//  if (inSaveJpeg)
//    Papy3FClose (&theFp);
///* #endif */
//
//  /* We can use jpeg_abort to release memory and reset global_state */
//  jpeg_abort( (j_common_ptr) &theCInfo);
//
//  /* Step 7: release JPEG compression object */
//
//  jpeg_destroy_compress (&theCInfo);
//
  return (0);

} /* endof JPEGLossyEncodeImage */


/********************************************************************************/
/*										*/
/*	WaveletEncodeImage : ,							*/
/*										*/
/*	return : return 0 if no problem					 	*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

#ifdef MAYO_WAVE
PapyShort
WaveletEncodeImage (int inRatio, int inLevels, PapyUChar *inImageBuffP, PapyUChar **outWavDataP, 
		    PapyULong *outWavsizeP, int inHeight, int inWidth, int inDepth, enum EModality inModality ) 
{
  MayoCompressedImage	*theCompressedP; 
  MayoRawImage		theRaw;  
  int			theBytes, j, i;
  int			theOptions;
  PapyUChar	        *theDataP;
  PapyULong		theTotalSize, thePos;
  int			theVersion;
  int			theLength;
  PapyUChar	        *theValTempP, *theFinalValP;
  PapyUChar		theHigh, theLow;


  if (inDepth == 8) 
    theBytes = 1;
  else 
    theBytes = 2;

  /* Set up options */ 
  theOptions  = 0;
  theOptions |= MAYO_OPT_HVS ; /* Use Human Visualization optimizations */

  /* theOptions |= MAYO_OPT_BIN ;  */ /* Use Binary encoding */
  theOptions |= MAYO_OPT_WTYPE153 ; /* Use wavelet type 153 for compression */

  if (inModality == CT_IM) theOptions |= MAYO_OPT_CT; /* Use CT image optimizations */


  /* Set up compression ratios according to the modality */ 
  inRatio = 40;
  if (inModality == CR_IM || inModality == SEC_CAPT_IM) inRatio = 40;
  if (inModality == CT_IM || inModality == MR_IM)       inRatio = 20;
  if (inModality == US_IM || inModality == NM_IM)       inRatio = 15;

/* Set up the number of levels: 1 to 5
 * a higher value results in better quality, 
 * a lower value results in faster compression
 */

  inLevels = 5;

  /* Set up the MayoRawImage structure */ 
  theRaw.bytesperpixel = theBytes ; 
  theRaw.xsize 	       = inWidth ; 
  theRaw.ysize 	       = inHeight ; 
  theRaw.buf 	       = inImageBuffP ;  

  /* Swap bytes if it is a 16-bit image*/
#ifdef TO_SWAP_MAYO

  theValTempP  = (PapyUChar *) inImageBuffP;
  theFinalValP = (PapyUChar *) inImageBuffP;

  if (inDepth == 16)
  {
    for (j = 0; j < inHeight; j++) 
    {
      for (i = 0; i < inWidth; i++) 
      {
	theLow        = *theValTempP;
	theValTempP++;
	theHigh       = *theValTempP;
	theValTempP++;
	*theFinalValP = theHigh;
	theFinalValP++;
	*theFinalValP = theLow;
	theFinalValP++;
      } /* for ...i */
    } /* for ...j */
  } /* if ...depth = 16 */
#endif 

  /* Call the Compress function */ 
  theCompressedP = MayoCompressRaw (&theRaw, inRatio, theOptions, inLevels); 

  /* Fill Wav Buffer */

  /* *outWavDataP = (PapyUChar *) theCompressedP->buf; */
  /* *outWavsizeP = theCompressedP->length; */

  /*theTotalSize = theCompressedP->length + 2*sizeof(int);*/
  theTotalSize = theCompressedP->length + 8L;
  theDataP     = (PapyUChar *) emalloc3(theTotalSize);
  *outWavDataP = (PapyUChar *) theDataP;
  *outWavsizeP = theTotalSize;

  theLength    =  theCompressedP->length;
  theVersion   = theCompressedP->version;

  thePos = 0L;
  Put4Bytes ((PapyULong) theLength, theDataP, &thePos);
  Put4Bytes ((PapyULong) theVersion, theDataP, &thePos);
  
  theDataP += thePos;
  memcpy (theDataP, theCompressedP->buf, theCompressedP->length);

  efree3 ((void **) &(theCompressedP->buf));
  efree3 ((void **) &theCompressedP);

  return (0);
  
} /* endof waveletEncodeImage */
#endif


/********************************************************************************/
/*										*/
/*	Papy3PutElement : writes the value(s) of an element to the given group,	*/
/*	module or record.							*/
/*	return : return 0 if no problem					 	*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3PutElement (SElement *inGrOrModP, int inElement, void *inValP)

/*SElement 	*inGrOrModP;			   the group or module ID */
/*PapyShort	inElement;			       the element number */
/*void		*inValP;	        the value(s) to write on the file */

{
  SElement 	*theElemP;
  UValue_T 	*theValP;
  int		theErr;


  /* goto the specified element */
  theElemP = inGrOrModP + inElement;

  /* allocate room for the value to put */
  if (strcmp (theElemP->vm, "1") == 0)   /* Single Value */
  {
    if ((theErr = Papy3ClearElement (inGrOrModP, inElement, TRUE)) < 0) RETURN (theErr); 
    theElemP->nb_val = 1L;
    theValP = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
  } /* then */
  else                 	/* Multiple Values */
  {
    theElemP->nb_val++;
    if (theElemP->nb_val == 1L)
      theValP = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
    else
      theValP = (UValue_T *) erealloc3 (theElemP->value, 
				        (PapyULong) (sizeof (UValue_T) * theElemP->nb_val),
				        (PapyULong) (sizeof (UValue_T) * (theElemP->nb_val - 1L))); /* OLB */
  } /* else ...multiple value */
    
  theElemP->value = theValP;
    
  /* goto the place of the value to put */
  theValP = (theElemP->value + theElemP->nb_val - 1L);

   switch (theElemP->vr)
  {
    case OB :
    case OW :
    case UN :
      /* the elements of this type must be put using PapyPutImage for OB, OW */
      /* or Papy3PutUnknown for UN */
      RETURN (papElemNumber);
      break;
    case SS :
      theValP->ss = *(PapyShort *) inValP;
      break;
    case USS :
    case AT :
      theValP->us = *(PapyUShort *) inValP;
      break;
    case SL :
      theValP->sl = *(PapyLong  *) inValP;
      break;
    case UL :
      theValP->ul = *(PapyULong *) inValP;
      break;
    case FL :
      theValP->fl = *(PapyFloat *) inValP;
      break;
    case FD :
      theValP->fd = *(PapyFloatDouble *) inValP;
      break;
    case AE :
    case AS :
    case CS :
    case DA :
    case DS :
    case DT :
    case IS :
    case LO :
    case LT :
    case PN :
    case SH :
    case ST :
    case TM :
    case UI :
    case UT :
      theValP->a = PapyStrDup (*((char**) inValP));
      break;
    case SQ :
      theValP->sq = *(struct SPapy_List_ **) inValP;
      break;
    case RET :
      /* RETired element */
    default :
      break;
  } /* switch */

  RETURN (papNoError);
    
} /* endof Papy3PutElement */



/********************************************************************************/
/*										*/
/*	Papy3PutIcon : Put an icon for a given image number. This function 	*/
/*	must only be used when putting a compressed image in the file.		*/
/*	return : return 0 if no problem						*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3PutIcon (PapyShort inFileNb, PapyShort inImageNb, PapyUChar *inIconP)
{
  /**((gArrIcons [inFileNb]) + inImageNb - 1) = inIconP;*/
  gArrIcons [inFileNb] [inImageNb - 1] = inIconP;

  RETURN (papNoError);

} /* endof Papy3PutIcon */



/********************************************************************************/
/*										*/
/*	Papy3PutImage : writes the value(s) of an element of type OB or OW to	*/
/*	the given group or module (pixel data or curve elements). 		*/
/*	return : return 0 if no problem						*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3PutImage (PapyShort inFileNb, SElement *inGrOrModP, int inElement, PapyUShort *inValP, 
	       PapyUShort inRows, PapyUShort inColumns, PapyUShort inDepth, PapyULong inSize)
{
  SElement	*theElemP;
  int		theErr;
  enum EV_R_T 	theVR;
  PapyUChar	*theCompPixP;

#ifdef WRITE_RAW_FILE /* Temporary stuffs for compression evaluation. DAB */
  PAPY_FILE	theFp;	
  void 		*theFSSpecP;
  PAPY_FILE	theVRefNum;
  char		theFilename[20];
  long		theSizer;
  PapyUChar	*theValTempP, *theFinalValP, *theFinaleValP;
  PapyUChar	theHigh, theLow;
  int		i, j;
#endif

  
  theElemP = inGrOrModP + inElement;

  if ((theErr = Papy3ClearElement (inGrOrModP, inElement, TRUE)) < 0) RETURN (theErr); 
	
  /* these pixel datas have to be compressed using the JPEG lossless algorithm */
  if (theElemP->group == 0x7FE0 && theElemP->element == 0x0010 &&
      (gArrCompression [inFileNb] == JPEG_LOSSLESS || gArrCompression [inFileNb] == JPEG_LOSSY
#ifdef MAYO_WAVE
       || gArrCompression [inFileNb] == MAYO_WAVELET
#endif
      ) && inSize == 0L)
  {
    /* compressed images have a Value Representation of OB */
    theVR = OB;
	
#ifdef WRITE_RAW_FILE /* Temporary stuffs for compression evaluation. DAB */
#ifdef SWAP_DATA
/* That's time to write file! At first, swapped raw */

    strcpy((char *) theFilename, "TheFileSwap.raw");

    theFSSpecP    = NULL;
    theValTempP   = (PapyUChar *) inValP;
    theFinalValP  = (PapyUChar *) inValP;
    theFinaleValP = (PapyUChar *) inValP;
    
    for (j = 0; j < inRows; j++) 
    {
      for (i = 0; i < inColumns; i++) 
      {
        theLow        = *theValTempP;
        theValTempP++;
        theHigh       = *theValTempP;
        theValTempP++;
        *theFinalValP = theHigh;
        theFinalValP++;
        *theFinalValP = theLow;
        theFinalValP++;
      } /* for ...i */
    } /* for ...j */
    
    if (Papy3FCreate ((char *) theFilename, theVRefNum, &theFp, &theFSSpecP) != 0) 
      RETURN (papFileCreationFailed);

    if (Papy3FOpen ((char *) theFilename, 'w', theVRefNum, &theFp, &theFSSpecP) != 0)
      RETURN (papOpenFile);
	
    theSizer = (long) (inRows * inColumns * 2);	
    if (Papy3FWrite (theFp, (PapyULong *) &theSizer, 1L, (void *) theFinaleValP) != 0) 
      RETURN (papWriteFile);

    Papy3FClose (&theFp);
#endif /* SWAP_DATA */

#ifdef RAW_DATA
/* That's all folks for swapped raw. Let's do the raw data now! */

    strcpy((char *) theFilename, "TheFile.raw");

    theFSSpecP    = NULL;
    theValTempP   = (PapyUChar *) inValP;
    theFinalValP  = (PapyUChar *) inValP;
    theFinaleValP = (PapyUChar *) inValP;
    
    for (j = 0; j < inRows; j++) 
    {
      for (i = 0; i < inColumns; i++) 
      {
        theLow        = *theValTempP;
        theValTempP++;
        theHigh       = *theValTempP;
        theValTempP++;
        *theFinalValP = theHigh;
        theFinalValP++;
        *theFinalValP = theLow;
        theFinalValP++;
      } /* for ...i */
    } /* for ...j */
    
    if (Papy3FCreate ((char *) theFilename, theVRefNum, &theFp, &theFSSpecP) != 0)
      RETURN (papFileCreationFailed);

    if (Papy3FOpen ((char *) theFilename, 'w', theVRefNum, &theFp, &theFSSpecP) != 0) 
      RETURN (papOpenFile);
    
    theSizer = (long) (inRows * inColumns * 2);
    if (Papy3FWrite (theFp, (PapyULong *) &theSizer, 1L, (void *) theFinaleValP) != 0) 
      RETURN (papWriteFile);

    Papy3FClose (&theFp);
#endif /* RAW_DATA*/
#endif /* WRITE_RAW_FILE */


    /* call here the compression function */

    if (gArrCompression [inFileNb] == JPEG_LOSSY)
      JPEGLossyEncodeImage (inFileNb, 80, NULL, (PapyUChar *) inValP, (PapyUChar **) &theCompPixP, 
	 		    (PapyULong *) &inSize, (int) inRows, (int) inColumns, (int) inDepth, FALSE);
	
//    else if (gArrCompression [inFileNb] == JPEG_LOSSLESS)
//      JPEGLosslessEncodeImage ((PapyUShort *) inValP, (PapyUChar **) &theCompPixP,
//			       (PapyULong *) &inSize, (int) inColumns, (int) inRows, (int) inDepth);

#ifdef MAYO_WAVE
    else if (gArrCompression [inFileNb] == MAYO_WAVELET)
      if (WaveletEncodeImage (10, 5, (PapyUChar *) inValP, (PapyUChar **) &theCompPixP, 
		              (PapyULong *) &inSize,(int) inRows, (int) inColumns, (int) inDepth, 
			      (enum EModality) gFileModality[inFileNb] ) != 0)
	return (-1); 
#endif /* MAYO_WAVE */
   
    inValP = (PapyUShort *) theCompPixP;

      
  } /* if ...compression algorithm is JPEG lossless */
  /* else there is no compression to apply to the pixel datas */
  else
  {
    /* compressed images have a Value Representation of OB */
    if ((theElemP->group == 0x7FE0 && theElemP->element == 0x0010 &&
        (gArrCompression [inFileNb] == JPEG_LOSSLESS || 
	 gArrCompression [inFileNb] == JPEG_LOSSY 
#ifdef MAYO_WAVE                
         || gArrCompression [inFileNb] == MAYO_WAVELET
#endif                
        )) || theElemP->group == 0x0002)
      theVR = OB;
    /* uncompressed elements have a value representation of OW */
    else
    {
      theVR = OW;
      
      /* this is important for further encoding */
      if (gx0028BitsAllocated [inFileNb] == 0)
        gx0028BitsAllocated [inFileNb] = inDepth;
    } /* else ..uncompressed image */
      
    /* computes the size of the image if necessary (this is usefull to let people */
    /* send a compressed image to this routine) */
    if (inSize == 0L)
    {
      inSize  = (PapyULong) (inRows * inColumns);
      inSize *= (PapyULong) (inDepth / 8);
    } /* if */ 
  } /* else ...no compression */
    
  theElemP->nb_val = 1L;
  theElemP->vr     = theVR;
  theElemP->length = inSize;
  theElemP->value  = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
        
  if (theElemP->vr == OB)
    theElemP->value->a  = (char *) inValP;
  else
    theElemP->value->ow = inValP;

  RETURN (papNoError);

} /* endof Papy3PutImage */



/********************************************************************************/
/*										*/
/*	Papy3PutUnknown : writes the value(s) of an element of type UN to	*/
/*	the given group or module (pixel data or curve elements). 		*/
/*	return : return 0 if no problem						*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3PutUnknown (SElement *inGrOrModP, int inElement, PapyChar *inValP, 
	         PapyULong inSize)
{
  SElement	*theElemP;
  int		theErr;
  PapyULong	theLoop;

  
  theElemP = inGrOrModP + inElement;

  if ((theErr = Papy3ClearElement (inGrOrModP, inElement, TRUE)) < 0) RETURN (theErr); 
	
    
  theElemP->nb_val = 1L;
  theElemP->vr     = UN;
  theElemP->length = inSize;
  theElemP->value  = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
  
  /* allocate room for the value */
  theElemP->value->a  = (char *) ecalloc3 ((PapyULong) (inSize), (PapyULong) sizeof (char));

  /* copy the value to the element */
  for (theLoop = 0L; theLoop < inSize; theLoop++)
  {
    theElemP->value->a [theLoop] = inValP [theLoop];
  } /* for */

  RETURN (papNoError);

} /* endof Papy3PutUnknown */



/********************************************************************************/
/*										*/
/*	ComputeElementLength3 : computes the size of a given element.		*/
/* 	return : the size of the element					*/
/*										*/
/********************************************************************************/

PapyULong
ComputeElementLength3 (SElement *inElemP, PapyULong inPos, enum ETransf_Syntax inSyntax)

/*SElement 	*inElemP;				      the element */
/*unsigned long	inPos;		    which element ? (multiple value text) */

{
  PapyULong 	theSize = 0L;
  Item		*theWrkP;
  SElement	*theTmpElemP;
    

  theTmpElemP = inElemP;
  switch (theTmpElemP->vr)
  {
    case AT :
    case USS :
    case SS :
      theSize = 2L;
      break;
    case UL :
    case SL :
      theSize = 4L;
      break;
    case FL :
      theSize = 4L;
      break;
    case FD :
      theSize = 8L;
      break;
    case AE :
    case AS :
    case CS :
    case DA :
    case DS :
    case DT :
    case IS :
    case LO :
    case LT :
    case PN :
    case SH :
    case ST :
    case TM :
    case UI :
    case UT :
      if ((theTmpElemP->value + inPos)->a != NULL)
	theSize = strlen ((theTmpElemP->value + inPos)->a);
      break;
    case UN :
      /* unknown element */
      theSize = theTmpElemP->length;
      break;
    case OB :
      /* is it a compressed pixel data element */
      if (theTmpElemP->group == 0x7FE0 && theTmpElemP->element == 0x0010)
        /* add the lenght of the item delimiters */
        theSize += 24;
    case OW :
      /* for these elements the size is given when they are put */
      theSize += theTmpElemP->length;
      break;
    case SQ :
      /* if image sequence => inElemP length = size of the tmp files */
      if (theTmpElemP->group   == 0x0041 && 
          theTmpElemP->element == Papy3EnumToElemNb (theTmpElemP, papImageSequenceGr))
      {
        theWrkP = (Item *) theTmpElemP->value->sq;
        while (theWrkP != NULL)
        {				/* 8 is for the item delimiter */
          theSize += theWrkP->object->tmpFileLength + 8L;
          theWrkP  = theWrkP->next;
        } /* while ...loop on the tmp files */
          
      } /* if ...inElemP = image sequence */
      else theSize = ComputeSequenceLength3 (theTmpElemP->value->sq, inSyntax);
      break;
    default :
      theSize = 0;
      break;
  } /* switch ...inElemP->vr */
    
  RETURN (theSize);

} /* endof ComputeElementLength3 */



/********************************************************************************/
/*										*/
/*	ComputeGroupLength3 : computes the size of the given group.		*/
/* 	return : always return 0						*/
/*										*/
/********************************************************************************/

PapyShort
ComputeGroupLength3 (PapyShort inGroupNb, SElement *ioGroupP, PapyULong *outImSeqSizeP, 
		     enum ETransf_Syntax inSyntax)

/*int		inGroupNb;			    the enum group number */
/*SElement 	*ioGroupP;			     pointer to the group */
{
  SElement 	*theElemP;
  PapyULong 	theSize, theTotalSize, i, j, theGrSize;
    

  theTotalSize = 0L;
  theSize      = 0L;
  theGrSize    = gArrGroup [inGroupNb].size;
  /* the first elem is group size so start the loop with i = 1 */
  for (i = 1L, theElemP = ioGroupP + 1; i < theGrSize; i++, theElemP++)
  {
    /* no introduced value, so look for the type of the element */
    if (theElemP->nb_val == 0L)
    {
      if (theElemP->type_t == T2) theSize = 0L;
      else continue;

      theSize += theSize & 1;			/* increment if size is odd */
	    				 
      theTotalSize += theSize + 8L;		/* group + element + length = 8 */
      if (inSyntax == LITTLE_ENDIAN_EXPL && (theElemP->vr == OB || theElemP->vr == OW || theElemP->vr == SQ))
        theTotalSize += 4L;
	    
    } /* if ...no introduced value */
    else /* introduced value */
    {
       theSize = ComputeElementLength3 (theElemP, 0L, inSyntax);
       for (j = 1L; j < theElemP->nb_val; j++)
       {
         theSize += ComputeElementLength3 (theElemP, j, inSyntax);
         if ((theElemP->vr == AE) || (theElemP->vr == AS) || (theElemP->vr == CS) ||
             (theElemP->vr == DA) || (theElemP->vr == DS) || (theElemP->vr == DT) ||
             (theElemP->vr == IS) || (theElemP->vr == LO) || (theElemP->vr == LT) ||
             (theElemP->vr == PN) || (theElemP->vr == SH) || (theElemP->vr == ST) ||
             (theElemP->vr == TM) ||(theElemP->vr == UI))
           theSize += 1L;	 /* the 1 is for the \ separator of mult val */
        } /* for */
        
        theSize      += theSize & 1;	/* increment if size is odd */
        theTotalSize += theSize + 8L;	/* 8L: grNb+elemNb+valueLength  (implicit) */
        
        /* if group 2 (explicit VR) & VR = OB or */
        /* Little_Endian_Explicit & VR = OB, OW, SQ, UN or UT then add 4 to the total length */
        if ((theElemP->group == 0x0002 && theElemP->vr == OB) ||
            ((inSyntax == LITTLE_ENDIAN_EXPL) && 
             ((theElemP->vr == OB) ||
              (theElemP->vr == OW) || 
              (theElemP->vr == SQ)|| 
              (theElemP->vr == UN)|| 
              (theElemP->vr == UT))))
          theTotalSize += 4L;
	    
        /* if image sequence store the size of the element */
        if (theElemP->group == 0x0041 &&
            theElemP->element == Papy3EnumToElemNb (theElemP, papImageSequenceGr))
          *outImSeqSizeP = theSize;
	    
    } /* else ...there is an introduced value */
    
    /* if this is not a compressed pixel data element */
    if (!(theElemP->group == 0x7FE0 && theElemP->element == 0x0010 && theElemP->vr == OB))
      theElemP->length = theSize;
  } /* for */
    
  ioGroupP->nb_val    = 1L;
  ioGroupP->length    = 4L;
  ioGroupP->value     = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
  ioGroupP->value->ul = theTotalSize;

  RETURN (papNoError)
    
} /* endof ComputeGroupLength3 */


/********************************************************************************/
/*										*/
/*	ComputeSequenceLength3 : computes the size of the given sequence.	*/
/* 	return : the size of the element					*/
/*										*/
/********************************************************************************/

PapyULong
ComputeSequenceLength3 (Item *inSequenceP, enum ETransf_Syntax inSyntax)
{
  PapyShort	theEnumGrNb;
  PapyULong	theSeqSize = 0L;
  Item		*theItemListP, *theGrListP;
  
  
  /* loop on the list of items of the sequence */
  theItemListP = inSequenceP;
  while (theItemListP != NULL)
  {
    /* loop on the list of groups of the item */
    theGrListP = (Item *) theItemListP->object->item;
    while (theGrListP != NULL)
    {
      if (theGrListP->object->whoAmI == papGroup)
      {
        theEnumGrNb = Papy3ToEnumGroup (theGrListP->object->group->group);
 
        /* compute the size of the group */
        ComputeGroupLength3 (theEnumGrNb, theGrListP->object->group, NULL, inSyntax);
      
        /* kLength_length is the length of the group length element */
        theSeqSize += theGrListP->object->group->value->ul + kLength_length;
      }
      else
       theSeqSize += ComputeSequenceLength3 (theGrListP->object->item, inSyntax);

      /* get next element of the list of groups */
      theGrListP = theGrListP->next;

    } /* while ...loop on the list of groups of the item */
    
    /* add the size of the item delimiter */
    theSeqSize += 8L;
    
    /* go to the next item of the sequence */
    theItemListP = theItemListP->next;
    
  } /* while ...loop on the items of the sequence */
  
  
  return theSeqSize;

} /* endof ComputeSequenceLength3 */



/********************************************************************************/
/*										*/
/*	PutGroupInBuffer : put the elements of the given group in the buffer.	*/
/*	return : standard error message.					*/
/*									 	*/
/********************************************************************************/

PapyShort
PutGroupInBuffer (PapyShort inFileNb, PapyShort inImNb, int inGroupNb, SElement *inGroupP, 
		  unsigned char *ioBuffP, PapyULong *ioPosP, int inIsPtrSeq)
/*
inGroupP		is the pointer to the group to write to the buffer
ioBuffP			is the ready to write buffer
ioPosP			is the current position in the buffer
*/
{
  SElement	*theElemP;
  PapyShort	theErr, theFuncImNb, theSavedImNb;
  PapyUShort	theUS, theSavedUINOverlayNb = 0x0000;
  PapyULong	i, j, theItemDelimPos, theItemLength, theUL, theNbOfElem, theFilePos, thePosition;
  char		*theStringP, theString [4];
  Item		*theItemSeqP, *theItemGrP;
  int		theRecordID;
  PAPY_FILE	theFp;			/* the file pointer */

  /* saves the pos of the item delimiter */
  theItemDelimPos = *ioPosP - 8L;
  
  theFp = gPapyFile [inFileNb];
  /* useful for dicomdir and referenced offset */
  Papy3FTell (theFp, (PapyLong *) &theFilePos);
 
  /* side effect ? */
  theFuncImNb = inImNb;
  
  if (inGroupP->group == 0x6000)		/* multiple Overlay group ? */
  {
    if (gCurrentOverlay [inFileNb] > kMax_overlay) 
      RETURN (papTooMuchOverlays)
    else
    {
      for (i = 0, theElemP = inGroupP; i < gArrGroup [inGroupNb].size; i++, theElemP++)
        theElemP->group = gCurrentOverlay [inFileNb];
            
      gCurrentOverlay [inFileNb] += 2;
    } /* else */
  } /* if ...overlay group */
  else if (inGroupP->group == 0x6001)	/* multiple UINOverlay group ? */
  {
    if (gCurrentUINOverlay [inFileNb] > kMax_UIN_overlay) 
      RETURN (papTooMuchUINOverlays)
    else
    {
      for (i = 0, theElemP = inGroupP; i < gArrGroup [inGroupNb].size; i++, theElemP++)
        theElemP->group = gCurrentUINOverlay [inFileNb];
      
      gCurrentUINOverlay [inFileNb] += 2;
    } /* else */
  } /* if ...UIN overlay group */
  /* group 0x0004 is only needed by the DICOMDIR */
  else if (gIsPapyFile [inFileNb] == DICOMDIR && inGroupP->group == 0x0004)
  {
    /* useful when setting the NextDirRecordOffset or the NextLowerLevelOffset */
    theRecordID = Papy3GetRecordType (inGroupP);
  } /* else ...group 0x0004 */

  theNbOfElem = gArrGroup [inGroupNb].size;
  /* loop on the elements of the group and put them in the buffer */
  for (i = 0L, theElemP = inGroupP; i < theNbOfElem; i++, theElemP++)
  {
    /* there is an introduced value */
    if (theElemP->nb_val > 0L || theElemP->type_t == T2)
    {
      Put2Bytes (theElemP->group  , (unsigned char *) ioBuffP, ioPosP);
      Put2Bytes (theElemP->element, (unsigned char *) ioBuffP, ioPosP);
      
      /* LITTLE_ENDIAN_IMPLICIT VR and not group 2 */
      if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL && theElemP->group != 0x0002)
        Put4Bytes (theElemP->length , (unsigned char *) ioBuffP, ioPosP);
      /* LITTLE_ENDIAN_EXPLICIT VR or group 2 */
      else if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL || theElemP->group == 0x0002)
      {
        theStringP = (char *) &theString [0];
	switch (theElemP->vr)
	{
	  case AE : strcpy (theStringP, "AE"); break;
	  case AT : strcpy (theStringP, "AT"); break;
	  case AS : strcpy (theStringP, "AS"); break;
	  case CS : strcpy (theStringP, "CS"); break;
	  case DA : strcpy (theStringP, "DA"); break;
	  case DS : strcpy (theStringP, "DS"); break;
	  case DT : strcpy (theStringP, "DT"); break;
	  case FL : strcpy (theStringP, "FL"); break;
	  case FD : strcpy (theStringP, "FD"); break;
	  case IS : strcpy (theStringP, "IS"); break;
	  case LO : strcpy (theStringP, "LO"); break;
	  case LT : strcpy (theStringP, "LT"); break;
	  case OB : strcpy (theStringP, "OB"); break;
	  case OW : strcpy (theStringP, "OW"); break;
	  case PN : strcpy (theStringP, "PN"); break;
	  case SH : strcpy (theStringP, "SH"); break;
	  case SL : strcpy (theStringP, "SL"); break;
	  case SQ : strcpy (theStringP, "SQ"); break;
	  case SS : strcpy (theStringP, "SS"); break;
	  case ST : strcpy (theStringP, "ST"); break;
	  case TM : strcpy (theStringP, "TM"); break;
	  case UI : strcpy (theStringP, "UI"); break;
	  case UL : strcpy (theStringP, "UL"); break;
	  case UN : strcpy (theStringP, "UN"); break;
	  case UT : strcpy (theStringP, "UT"); break;
	  case USS: strcpy (theStringP, "US"); break;
	  case RET: strcpy (theStringP, "RE"); break;
	  default : strcpy (theStringP, "ZZ"); break;
	} /* switch ...VR */
	/* put the VR in the buffer */
	PutString (theStringP, theElemP->vr, (unsigned char *) ioBuffP, ioPosP); 
	  
	/* if the VR is OB, OW, SQ, UN or UT then put 2 bytes set to 0x0000 ... */
	/* ... and encode the element length on 4 bytes       */
	if ((theElemP->vr == OB) ||
	    (theElemP->vr == OW) ||
	    (theElemP->vr == SQ) ||
	    (theElemP->vr == UN) ||
	    (theElemP->vr == UT))
	{
	  /* put the 0x0000 value to the buffer */
	  theUS = 0x0000;
	  Put2Bytes (theUS, (unsigned char *) ioBuffP, ioPosP);
	  
	  /* if compressed pixel datas then put an undefined length */
	  if (gArrCompression [inFileNb] != NONE 	&& 
	      theElemP->group 	         == 0x7FE0	&& 
	      theElemP->element 	 == 0x0010	&&
	      theElemP->vr 		 == OB)
	    Put4Bytes (0xFFFFFFFF, (unsigned char *) ioBuffP, ioPosP);
	  /* or put the length of the element */
	  else
	    Put4Bytes (theElemP->length, (unsigned char *) ioBuffP, ioPosP);
	    
	} /* if ...VR = OB, OW, SQ, UN or UT */
	else
	  /* put the element length in the buffer (2 bytes length */
	  Put2Bytes ((PapyUShort) theElemP->length, (unsigned char *) ioBuffP, ioPosP);
      } /* else ...EXPLICIT VR or group 2*/
	
      if (theElemP->nb_val > 0L)
      {
        switch (theElemP->vr)
        {
	  case UL :
	    /* store the positions of the elements of the referenced directory record */
	    if (gIsPapyFile [inFileNb] == DICOMDIR && theElemP->group == 0x0004)
	    {
	      /* 0004,1200 */
	      if (theElemP->element == Papy3EnumToElemNb (theElemP, papOffsetofTheFirstDirectoryRecordGr))
	        gPosFirstPatientOffset [inFileNb] = *ioPosP;
		  
	      /* 0004,1202 */
	      else if (theElemP->element == Papy3EnumToElemNb (theElemP, papOffsetofTheLastDirectoryRecordGr))
	        gPosLastPatientOffset [inFileNb] = *ioPosP;

	      /* 0004,1400 */
	      else if (theElemP->element == Papy3EnumToElemNb (theElemP, papOffsetofNextDirectoryRecordGr))
	      {
	        if (theRecordID == 0)  /* PatientR */
	        {
		  if (gRefFirstPatientOffset [inFileNb] == 0L)
		  {
                    gRefFirstPatientOffset [inFileNb] = theFilePos + theItemDelimPos;
		    /*gRefFirstPatientOffset [inFileNb] = theFilePos + *ioPosP - 28L; */
                    /* Let save position */
                    thePosition = gPosFirstPatientOffset [inFileNb];   
		    Put4Bytes (gRefFirstPatientOffset [inFileNb], ioBuffP, &thePosition);	 
		  } /* if */
		  
                  gRefLastPatientOffset [inFileNb] = theFilePos + theItemDelimPos;
		  /*gRefLastPatientOffset [inFileNb] = theFilePos + *ioPosP - 28L;*/
                  /* Let save position */
                  thePosition = gPosLastPatientOffset [inFileNb];
		  Put4Bytes (gRefLastPatientOffset [inFileNb], ioBuffP, &thePosition);
	        } /* if ...recordId = 0 */
	        
	        /* it exist a previous same level record */
	        if (*(gPosNextDirRecordOffset [inFileNb] + theRecordID) != 0L)
	        {
                  *(gRefNextDirRecordOffset [inFileNb] + theRecordID) = theFilePos + theItemDelimPos;
	          /**(gRefNextDirRecordOffset [inFileNb] + theRecordID) = theFilePos + *ioPosP - 28L;*/
	          thePosition = *(gPosNextDirRecordOffset [inFileNb] + theRecordID);
	          /* put the offset in the buffer */
	          Put4Bytes (*(gRefNextDirRecordOffset [inFileNb] + theRecordID), ioBuffP, &thePosition);
	        } /* if */
	        
	        *(gPosNextDirRecordOffset [inFileNb] + theRecordID) = *ioPosP;
	        /* reinitialisation of the LowerLevel Directory record offset position */
	        *(gPosLowerLevelDirRecordOffset [inFileNb] + theRecordID + 1) = 0L;
	        *(gRefLowerLevelDirRecordOffset [inFileNb] + theRecordID + 1) = 0L;
	        /* reinitialisation of the previous Next Directory record offset position */
	        *(gPosNextDirRecordOffset [inFileNb] + theRecordID + 1) = 0L;
	        
	        /* set the lower level directory record offset for the first LowLevel directory */
	        if (theRecordID != 0 && *(gRefLowerLevelDirRecordOffset [inFileNb] + theRecordID) == 0)
	        {
	          *(gRefLowerLevelDirRecordOffset [inFileNb] + theRecordID) = theFilePos + theItemDelimPos;
	          /**(gRefLowerLevelDirRecordOffset [inFileNb] + theRecordID) = theFilePos + *ioPosP - 28L;*/
	          thePosition = *(gPosLowerLevelDirRecordOffset [inFileNb] + theRecordID - 1);
	          /* put the offset in the buffer */
	          Put4Bytes (*(gRefLowerLevelDirRecordOffset [inFileNb] + theRecordID), ioBuffP, &thePosition);
	        } /* if */ 
	      } /* else ...element 0004,1400 */

	      /* 0004,1420 */
	      else if (theElemP->element == Papy3EnumToElemNb (theElemP, papOffsetofReferencedLowerLevelDirectoryEntityGr))
	        *(gPosLowerLevelDirRecordOffset [inFileNb] + theRecordID) = *ioPosP;
		   
	    } /* if DicomDir */

	    /* store the positions of the elements of the pointer sequence */
	    if (theElemP->group == 0x0041)
	    {
	      if (theElemP->element == Papy3EnumToElemNb (theElemP, papImagePointerGr))
	        *(gPosImagePointer [inFileNb] + theFuncImNb)  += *ioPosP;
	      else if (theElemP->element == Papy3EnumToElemNb (theElemP, papPixelOffsetGr))
	        *(gPosPixelOffset [inFileNb] + theFuncImNb)   += *ioPosP;
	    } /* if ...group 41 */
	  case SS :
	  case USS :
	  case AT :
	  case SL :
	  case FL :
	  case FD :
	    for (j = 0; j < theElemP->nb_val; j++)
	      PutValue (theElemP->value + j, theElemP->vr, ioBuffP, ioPosP);
	    break;
	  case OB :
	    /* keep the position of the pixel data for the pointer sequence */
	    if (!inIsPtrSeq && theElemP->group == 0x7FE0 && theElemP->element == 0x0010)
	      *(gRefPixelOffset [inFileNb] + theFuncImNb) = *ioPosP;
	    
	    
	    
	    /* if it is a compressed image, put the required presentation items */
	    if (theElemP->group == 0x7FE0 && theElemP->element == 0x0010 && gArrCompression [inFileNb] != NONE)
	    {
	      /* first : an item tag for the Basic Offset Table */
      	      Put2Bytes (0xFFFE , (unsigned char *) ioBuffP, ioPosP);
      	      Put2Bytes (0xE000 , (unsigned char *) ioBuffP, ioPosP);
      	      /* the length of the Basic Offset Table is set to ZERO */
      	      Put4Bytes (0x00000000 , (unsigned char *) ioBuffP, ioPosP);
      	    
      	      /* then the first (and unique) fragment of Pixel Data with its item tag */
      	      Put2Bytes (0xFFFE , (unsigned char *) ioBuffP, ioPosP);
      	      Put2Bytes (0xE000 , (unsigned char *) ioBuffP, ioPosP);
      	      /* then the length of the pixel data element */
      	      Put4Bytes (theElemP->length , (unsigned char *) ioBuffP, ioPosP);
      	      
      	    } /* if ...it is a compressed pixel data element */
	    
	    
	    /* put the value of the element to the buffer */
	    Put1ByteImage  (theElemP->value->a , ioBuffP, ioPosP, theElemP->length);
	    
	    
	    /* if it is a compressed image, put the required sequence delimiter item */
	    if (theElemP->group == 0x7FE0 && theElemP->element == 0x0010 && gArrCompression [inFileNb] != NONE)
	    {
      	      /* ladies and gentlemen : the Sequence Delimiter Item tag */
      	      Put2Bytes (0xFFFE , (unsigned char *) ioBuffP, ioPosP);
      	      Put2Bytes (0xE0DD , (unsigned char *) ioBuffP, ioPosP);
      	      /* and its length */
      	      Put4Bytes (0x00000000 , (unsigned char *) ioBuffP, ioPosP);
      	      
      	    } /* if ...it is a compressed pixel data element */
	      
	    /* if it is the pointer sequence, free the icon image datas */
	    /* free also the compressed pixels datas */
	    if ((inIsPtrSeq && theElemP->group == 0x7FE0 && theElemP->element == 0x0010) ||
	        (!inIsPtrSeq && gArrCompression [inFileNb] != NONE && 
	         theElemP->group == 0x7FE0 && theElemP->element == 0x0010))
	      Papy3ClearElement (inGroupP, papPixelDataGr, TRUE);
	    break;
	  case OW :
	    /* keep the position of the pixel data for the pointer sequence */
	    if (!inIsPtrSeq && theElemP->group == 0x7FE0 && theElemP->element == 0x0010)
	      *(gRefPixelOffset [inFileNb] + theFuncImNb) = *ioPosP;
       
#ifdef Windows
            Put2BytesImage (theElemP->value->ow, ioBuffP, ioPosP, theElemP->length);
#else   //  Solaris , Mac
	    if (gx0028BitsAllocated [inFileNb] == 8 || gx0028BitsAllocated [inFileNb] == 24 ||
	        (inIsPtrSeq && theElemP->group == 0x7FE0 && theElemP->element == 0x0010))
	      Put1ByteImage  ((char *) theElemP->value->ow , ioBuffP, ioPosP, theElemP->length);
	    else
	      Put2BytesImage (theElemP->value->ow, ioBuffP, ioPosP, theElemP->length);
#endif
	    /* if it is the pointer sequence, free the icon image datas */
	    /* free also the compressed pixels datas */
	    if ((inIsPtrSeq && theElemP->group == 0x7FE0 && theElemP->element == 0x0010) ||
	        (!inIsPtrSeq && gArrCompression [inFileNb] != NONE && 
	         theElemP->group == 0x7FE0 && theElemP->element == 0x0010))
	      Papy3ClearElement (inGroupP, papPixelDataGr, TRUE);
	    break;
	  case AE :
	  case AS :
	  case CS :
	  case DA :
	  case DS :
	  case DT :
	  case IS :
	  case LO :
	  case LT :
	  case PN :
	  case SH :
	  case ST :
	  case TM :
	  case UI :
	  case UN :
	  case UT :
	    if (theElemP->value->a)
	    {
	      theStringP = (char *) emalloc3 ((PapyULong) (theElemP->length + theElemP->nb_val));
	      strcpy (theStringP, theElemP->value->a);
	      for (j = 1; j < theElemP->nb_val; j++)
	      {
	        strcat (theStringP, "\\");
	        strcat (theStringP, (theElemP->value + j)->a);
	      } /* for */
		  
	      PutString (theStringP, theElemP->vr, ioBuffP, ioPosP);
	      efree3 ((void **) &theStringP);
	    } /* if */
	    break;
	  case SQ :
	    /* if it is the image sequence do nothing  */
	    if (! (theElemP->group == 0x0041 && 
	    	   theElemP->element == Papy3EnumToElemNb (theElemP, papImageSequenceGr)))
	    {
	      /* if element is the pointer to the UIN overlays sequence */
	      if (inGroupNb == UINOVERLAY &&
	          theElemP->nb_val > 0L && 
	      	  theElemP->element == Papy3EnumToElemNb (theElemP, papUINOverlaySequenceGr))
	      {
	        /* stores the current UINOverlay number */
	        theSavedUINOverlayNb = gCurrentUINOverlay [inFileNb];
	        /* reset the UINOverlay counting */
	        gCurrentUINOverlay [inFileNb] = 0x6001;
	      } /* if ...UIN overlays sequence */
	        
	      /* save the previous value */
	      theSavedImNb = theFuncImNb;
	      theFuncImNb = 0;
	      theItemSeqP = (Item *) theElemP->value->sq;

	      /* loop on the items of the sequence */
	      while (theItemSeqP != NULL)
	      { 
	        /* put the item delimiter */
	        theUS = 0xFFFE;
	        Put2Bytes (theUS, ioBuffP, ioPosP);
	        theUS = 0xE000;
	        Put2Bytes (theUS, ioBuffP, ioPosP);
	        theUL = 0L;
	        theItemDelimPos = *ioPosP;	/* saves the pos of the length of the item */
	        Put4Bytes (theUL, ioBuffP, ioPosP);
	          
	        theItemGrP = (Item *) theItemSeqP->object->item;
                /* loop on the groups of the data set */
                while (theItemGrP != NULL)
	        {
                  if ((inGroupNb = Papy3ToEnumGroup (theItemGrP->object->group->group)) < 0)
		    RETURN (papGroupNumber)

	          /* put the content of the group in the write buffer */
	          theErr = PutGroupInBuffer (inFileNb, theFuncImNb, inGroupNb, 
	          			     (SElement *) theItemGrP->object->group,
	          			     ioBuffP, ioPosP, inIsPtrSeq);

	          /* get next item of the data set */
	          theItemGrP = theItemGrP->next;
	          
	        } /* while ...loop on the groups of the data set */
	        
	        /* get the next item of the sequence */
	        theItemSeqP = theItemSeqP->next;
	        /* and increment the position in the list */
	        theFuncImNb++;
	          
	        /* computes the length of the item */
	        theItemLength = *ioPosP - theItemDelimPos - 4L; /* -4 = size of item length */
	        Put4Bytes (theItemLength, ioBuffP, &theItemDelimPos);
	        
	      } /* while ...loop on the items of the sequence */
	        
	      /* restores the gCurrentUINOverlay number if needed */
	      if (theSavedUINOverlayNb != 0x0000) 
	        gCurrentUINOverlay [inFileNb] = theSavedUINOverlayNb;
	      /* and restore the previous value of theFuncImNb */
	      theFuncImNb = theSavedImNb;
	      
	    } /* if ...element <> image sequence */
	    break;
	  default :
	    break;
	    
        } /* switch ...value representation */
        
      } /* if ...nb_val > 0L */

    } /* then ...theElemP->nb_val > 0 or type_t = T2 */
      
    /* no introduced value */
    else 
      if (theElemP->type_t == T1 && gIsPapyFile [inFileNb] != DICOMDIR)
      {
	/* no default value => error */
	efree3 ((void **) &ioBuffP);
	RETURN (papElemOfTypeOneNotFilled);
 	    
      } /* if ... type_t = T1 */
      
  } /* for ...loop on the elements of the group */
  
  return 0;
  
} /* endof PutGroupInBuffer */



/********************************************************************************/
/*										*/
/*	Papy3GroupWrite : write a group in the opened file 			*/
/*	return : the group size							*/
/*		 standard error message otherwise				*/
/*									 	*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GroupWrite (PapyShort inFileNb, SElement *ioGroupP, int inFreeGr)

/*SElement		*ioGroupP;			   the group to write */
/*int			inFreeGr;     would we free the group after writing ? */

{
  int		theGroupNb;
  int 		theIsPtrSeq = FALSE; 	 /* is there a Ptr Sequence ? */
  char		*theTmpFilenameP, theStr [32];
  unsigned char	*theBuffP;
  PapyULong	theBytesToWrite, theFilePos;
  PapyULong	theBuffSize, theImSeqSize, n;
  PapyUShort	theUS;
  PapyShort	theErr, theImNb, kk;
  Item 		*theWrkItemP;
  PAPY_FILE	theTmpFp, theFp;			/* the file pointers */


  theFp = gPapyFile [inFileNb];

  if ((theGroupNb = Papy3ToEnumGroup (ioGroupP->group)) < 0)
    RETURN (papGroupNumber)
    
  /* computes the size of the group */
  theImSeqSize = 0L;
  (void) ComputeGroupLength3 (theGroupNb, ioGroupP, &theImSeqSize, gArrTransfSyntax [inFileNb]);

  /* element 0 is group size */
  theBuffSize = ioGroupP->value->ul + kLength_length;

  switch (ioGroupP->group)
  {
    case 0x0041 :
      /* if group 41, substract the size of the image sequence */
      /* that has to be written separately */
      theBuffSize -= theImSeqSize;
      
      /* if it is THE group 41 */
      if (ioGroupP == gArrMemFile [inFileNb]->next->next->object->group)
      {
        Papy3FTell (theFp, (PapyLong *) &theFilePos);
        /* loop on the images */
        for (kk = 0; kk < gArrNbImages [inFileNb]; kk++)
        {
          *(gPosImagePointer [inFileNb] + kk) = (PapyULong) theFilePos;
          *(gPosPixelOffset  [inFileNb] + kk) = (PapyULong) theFilePos;
        } /* for */
        
        /* there is a pointer sequence (so do not save the offset to the icon image) */
        theIsPtrSeq = TRUE;
      } /* if ...THE group 41 */
      break;
    
    default :
      break;
        
  } /* switch ...group number */
        
  /* allocate the write buffer */
  theBuffP = (unsigned char *) emalloc3 ((PapyULong) theBuffSize);
  n = 0L;		/* position in the write buffer */
      
  /* put the group in the write buffer */
  theErr = (int) PutGroupInBuffer (inFileNb, 0, theGroupNb, ioGroupP, theBuffP, &n, theIsPtrSeq);
    
  /* write the buffer to the file */
  if (WriteGroup3 (theFp, theBuffP, theBuffSize) < 0)
  {
    efree3 ((void **) &theBuffP);
    RETURN (papWriteGroup);
  } /* if */
    
  /* deletes the write buffer */
  efree3 ((void **) &theBuffP);
    
  /* if THE group 41, copy the temp files to the Papyrus file */
  if (ioGroupP->group == 0x0041 &&
      ioGroupP == gArrMemFile [inFileNb]->next->next->object->group)
  {
    theWrkItemP = gImageSequenceItem [inFileNb];
    theImNb = 0;

    theTmpFilenameP = (char *) ecalloc3 ((PapyULong) 256, (PapyULong) sizeof (char));

    while (theWrkItemP != NULL)
    {
      /* allocate room for the item delimiter */
      theBuffP = (unsigned char *) emalloc3 ((PapyULong) 8);
      /* put the item delimiter element */
      n = 0L;
      theUS = 0xFFFE;
      Put2Bytes (theUS, theBuffP, &n);
      theUS = 0xE000;
      Put2Bytes (theUS, theBuffP, &n);
      Put4Bytes (theWrkItemP->object->tmpFileLength, theBuffP, &n);
      /* write it to the Papyrus file */
      theBytesToWrite = 8L;

      if (Papy3FWrite (theFp, (PapyULong *) &theBytesToWrite, 1L, theBuffP) < 0)
      {
	      theErr = Papy3FClose (&theFp);
	      efree3 ((void **) &theBuffP);
 	      RETURN (papWriteFile)
      } /* if */
      efree3 ((void **) &theBuffP);
        
        
      /* save the file position this data set will occupy for the backward references */
      Papy3FTell (theFp, (PapyLong *)(gRefImagePointer [inFileNb] + theImNb));
        
      /* then updates the position of the pixel data accordingly */
      /* so that it is no more a relative value */
      *(gRefPixelOffset [inFileNb] + theImNb) += *(gRefImagePointer [inFileNb] + theImNb);	
      
      /* build the name of the temp file containing the data set */  
      strcpy (theTmpFilenameP, gPapFilename [inFileNb]);
      
      /* append the incremental number to the filename */
      Papy3FPrint (theStr, "%d", theWrkItemP->object->objID);
      strcat (theStr, ".dcm");
      strcat (theStr, "\0");
      
      if (theWrkItemP->object->objID      < 10)
        strcat (theTmpFilenameP, "000");
      else if (theWrkItemP->object->objID < 100)
        strcat (theTmpFilenameP, "00");
      else if (theWrkItemP->object->objID < 1000)
        strcat (theTmpFilenameP, "0");
      
      strcat (theTmpFilenameP, theStr);
  

      /* open the temp file */
      if (Papy3FOpen (theTmpFilenameP, 'r', 0, &theTmpFp, &theWrkItemP->object->file) != 0)
        RETURN (papOpenFile);
        
      /* get the size of the tmp file */
      theImSeqSize = theWrkItemP->object->tmpFileLength;
        
      /* allocate the copy buffer */
      theBuffP = (unsigned char *) ecalloc3 ((PapyULong) theImSeqSize, (PapyULong) sizeof (char));
        
      /* reads the datas from the temp file... */
      if ((theErr = (PapyShort) Papy3FRead (theTmpFp, &theImSeqSize, 1L, theBuffP)) < 0)
      {
	      Papy3FClose (&theTmpFp);
	      efree3 ((void **) &theBuffP);
	      RETURN (papReadFile);
      } /* if */
        
      /* ...and writes them to the Papyrus file */
      if (Papy3FWrite (theFp, &theImSeqSize, 1L, theBuffP) < 0)
      {
	theErr = Papy3FClose (&theTmpFp);
	efree3 ((void **) &theBuffP);
	RETURN (papWriteFile)
      } /* if */

      /* deletes the copy buffer */
      efree3 ((void **) &theBuffP);
        
      /* close the temp file and frees memory */
      Papy3FClose (&theTmpFp);

      /* get next item of the list = the next data set saved in a temp file */
      theWrkItemP = theWrkItemP->next;
      /* and increment the position in the list */
      theImNb++;
        
    } /* while ...loop on the tmp files */
      
    /* deletes the theTmpFilenameP */
    efree3 ((void **) &theTmpFilenameP);

  } /* if ...group 41 */ 

  if (inFreeGr == TRUE)
    if (ioGroupP->group == 0x0041)
    {
      if ((theErr = Papy3GroupFree (&ioGroupP, FALSE)) < 0) RETURN (theErr);
    }
    else if ((theErr = Papy3GroupFree (&ioGroupP, TRUE)) < 0) RETURN (theErr);

  return 0;
    
} /* endof Papy3GroupWrite */
