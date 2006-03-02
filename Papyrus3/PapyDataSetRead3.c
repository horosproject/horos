/********************************************************************************/
/*						                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyDataSetRead3.c                                           */
/*	Function : contains the functions that will manage the reading of 	*/
/*		   the Data Sets and the modules.		                */
/*	Authors  : Christian Girard                                             */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 07.1994	version 3.0                                     */
/*                 06.1995	version 3.1                                     */
/*                 02.1996	version 3.3                                     */
/*                 02.1999	version 3.6                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                 10.2001      version 3.71 MAJ Dicom par CHG                  */
/*                                                                              */
/* 	(C) 1994-2001 The University Hospital of Geneva                         */
/*	           All Rights Reserved                                          */
/*                                                                              */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes -----------------------------------------*/

#include <stdio.h>
#include <string.h>

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif



/********************************************************************************/
/*									 	*/
/*	ExtractGroup28Information : Extracts some elements from the group 28 	*/
/*	that will be needed further.						*/
/*	return : standard error message.					*/
/*										*/
/********************************************************************************/

PapyShort
ExtractGroup28Information (PapyShort inFileNb)
{
  char		thePhotoInterpret [16];
  PapyShort	theErr;
  int		theElemType, theNbIm = 1;
  PapyULong	theNbVal;
  UValue_T	*theValP;
  SElement	*theGroup28P;
  
    
  /* goto group 28 and read it */
  if ((theErr = Papy3GotoGroupNb (inFileNb, 0x0028)) < 0)
    RETURN (theErr); 
  if ((theErr = Papy3GroupRead (inFileNb, &theGroup28P)) < 0)
    RETURN (theErr);
  
  long test = malloc_size( theGroup28P);
  
  /* *** save the value of the needed elements *** */
  
  /* extract number of frames only if DICOM file */
  if (gIsPapyFile [inFileNb] == DICOM10 || gIsPapyFile [inFileNb] == DICOM_NOT10)
  {
    theValP = Papy3GetElement (theGroup28P, papNumberofFramesGr, &theNbVal, &theElemType);
    if (theValP != NULL)
      sscanf (theValP->a, "%d", &theNbIm);
    
    gArrNbImages [inFileNb] = (PapyShort) theNbIm;
  } /* if */
  
  /* number of ROWS */
  if( theGroup28P [papRowsGr].value == 0L) return -1; 
  gx0028Rows [inFileNb] = theGroup28P [papRowsGr].value->us;
  
  /* number of COLUMNS */
   if( theGroup28P [papColumnsGr].value == 0L) return -1; 
  gx0028Columns [inFileNb] = theGroup28P [papColumnsGr].value->us;
  
  /* the image format */
  if (theGroup28P [papImageFormatGr].nb_val > 0L)
    gx0028ImageFormat [inFileNb] = PapyStrDup (theGroup28P [papImageFormatGr].value->a);
  
  /* the BITS ALLOCATED */
  if (theGroup28P [papBitsAllocatedGr].nb_val > 0L)
  {
    gx0028BitsAllocated [inFileNb] = theGroup28P [papBitsAllocatedGr].value->us;
    
    /* 24 bits images (RGB) should be seen as 8 bits allocated by channel... */
    if (gx0028BitsAllocated [inFileNb] == 24)
      gx0028BitsAllocated [inFileNb] = 8;
  } /* if */
  
  /* the BITS STORED */  
  if (theGroup28P [papBitsStoredGr].nb_val > 0L)
    gx0028BitsStored [inFileNb] = theGroup28P [papBitsStoredGr].value->us;
    
  /* the photometric interpretation */
  theValP = Papy3GetElement (theGroup28P, papPhotometricInterpretationGr, &theNbVal, &theElemType);
  if (theValP != NULL)
    strcpy (thePhotoInterpret, theValP->a);
  else  /* default value */
    strcpy (thePhotoInterpret, "MONOCHROME2");
  
  /* free the group 28 */
  theErr = Papy3GroupFree (&theGroup28P, TRUE);
  
  /* set the PAPYRUS global var according to the extracted value */
  if (strcmp (thePhotoInterpret, "MONOCHROME1") == 0) 
    gArrPhotoInterpret [inFileNb] = MONOCHROME1;
  else if (strcmp (thePhotoInterpret, "MONOCHROME2") == 0) 
    gArrPhotoInterpret [inFileNb] = MONOCHROME2;
  else if (strcmp (thePhotoInterpret, "PALETTE COLOR") == 0) 
    gArrPhotoInterpret [inFileNb] = PALETTE;
  else if (strcmp (thePhotoInterpret, "RGB") == 0) 
    gArrPhotoInterpret [inFileNb] = RGB;
  else if (strcmp (thePhotoInterpret, "HSV") == 0) 
    gArrPhotoInterpret [inFileNb] = HSV;
  else if (strcmp (thePhotoInterpret, "ARGB") == 0) 
    gArrPhotoInterpret [inFileNb] = ARGB;
  else if (strcmp (thePhotoInterpret, "CMYK") == 0) 
    gArrPhotoInterpret [inFileNb] = CMYK;
  else if (strcmp (thePhotoInterpret, "YBR_FULL") == 0) 
    gArrPhotoInterpret [inFileNb] = YBR_FULL;
  else if (strcmp (thePhotoInterpret, "YBR_FULL_422") == 0) 
    gArrPhotoInterpret [inFileNb] = YBR_FULL_422;
  else if (strcmp (thePhotoInterpret, "YBR_PARTIAL_422") == 0) 
    gArrPhotoInterpret [inFileNb] = YBR_PARTIAL_422;
  else if (strcmp (thePhotoInterpret, "YBR_RCT") == 0) 
    gArrPhotoInterpret [inFileNb] = YBR_RCT;
  else if (strcmp (thePhotoInterpret, "YBR_ICT") == 0) 
    gArrPhotoInterpret [inFileNb] = YBR_ICT;

  RETURN (papNoError);
  
} /* endofmethod ExtractGroup28Information */



/********************************************************************************/
/*									 	*/
/*	ExtractFileMetaInformation3 : Extracts the file meta information for the*/
/*	given file. It reads group2 and extract the modality as well as the 	*/
/*	transfert syntax that will be used in the rest of the file		*/
/*	return : standard error message.					*/
/*										*/
/********************************************************************************/

PapyShort
ExtractFileMetaInformation3 (PapyShort inFileNb)
{
  int		found, i;
  PapyShort	theErr;
  PapyULong	theNbVal;
  PapyLong	theFilePos;
  int		theElemType, theElength;
  SElement	*theGroup2P, *theGroupTmpP;
  UValue_T	*theValP;
  
  
  if ((theErr = Papy3GroupRead (inFileNb, &theGroup2P)) < 0) RETURN (papReadGroup);
    
  
  /* extract the transfert syntax used for the rest of the file */
  theValP = Papy3GetElement (theGroup2P, papTransferSyntaxUIDGr, &theNbVal, &theElemType);
  if (theValP == NULL)
  {theErr = Papy3GroupFree (&theGroup2P, TRUE); RETURN (papElemOfTypeOneNotFilled);}
  
  /* 1.2.840.10008.1.20 is to avoid a bug with the old files... */
  if (strcmp (theValP->a, "1.2.840.10008.1.2") == 0 || strcmp (theValP->a, "1.2.840.10008.1.20") == 0)
  { 
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_IMPL;
    gArrCompression  [inFileNb] = NONE;
  }
  else if (strcmp (theValP->a, "1.2.840.10008.1.2.1") == 0) 
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = NONE;
  }
  else if (strcmp (theValP->a, "1.2.840.10008.1.2.2") == 0)
  {
    gArrTransfSyntax [inFileNb] = BIG_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = NONE;
  }
  else if (strcmp (theValP->a, "1.2.840.10008.1.2.5") == 0)
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = RLE;
  }
  else if ((strcmp (theValP->a, "1.2.840.10008.1.2.4.70") == 0) || 
	   (strcmp (theValP->a, "1.2.840.10008.1.2.4.57") == 0) ||
   	   (strcmp (theValP->a, "1.2.840.10008.1.2.4.58") == 0))
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = JPEG_LOSSLESS;
  }
  else if (strcmp (theValP->a, "1.2.840.10008.1.2.4.51") == 0)
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = JPEG_LOSSY;
  }
//  else if (strcmp (theValP->a, "1.2.840.10008.1.2.4.50") == 0)
//  {
//    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
//    gArrCompression  [inFileNb] = JPEG_LOSSY;
//  }
  else if (strcmp (theValP->a, "1.2.756.777.1.2.4.70") == 0) /* PAPYRUS defined transfert syntax */
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_IMPL;
    gArrCompression  [inFileNb] = JPEG_LOSSLESS;
  }
#ifdef MAYO_WAVE /* WARNING this is defined in DICOM as JPEG-LS lossless image compression */
		 /* whereas 1.2.840.10008.1.2.4.81 is JPEG-LS Lossy (near-Lossless) image compression */
  else if (strcmp (theValP->a, "1.2.840.10008.1.2.4.80") == 0) 
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = MAYO_WAVELET;
  }
#endif
  else if (strcmp (theValP->a, "1.2.840.10008.1.2.4.90") == 0) 
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = JPEG2000;
  }
   else if (strcmp (theValP->a, "1.2.840.10008.1.2.4.91") == 0) 
  {
    gArrTransfSyntax [inFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [inFileNb] = JPEG2000;
  }

  else 
  {
    theErr = Papy3GroupFree (&theGroup2P, TRUE); 
    RETURN (papSyntaxNotImplemented);
  }


    
  /* extract the SOP Class UID in order to know the modality of the file */
  theValP = Papy3GetElement (theGroup2P, papMediaStorageSOPClassUIDGr, &theNbVal, &theElemType);
  
  /* find the modality */
  found = FALSE;
  i = 0;
  
  if (theValP != NULL)
  {
    /* DICOMDIR defined SOP Class UID */
    if (gIsPapyFile [inFileNb] == DICOMDIR)
      if (strcmp (theValP->a, "1.2.840.10008.1.3.10") == 0)
      {
        /* free group 2 as we do not need it anymore */
        theErr = Papy3GroupFree (&theGroup2P, TRUE);
        RETURN (theErr);
      } /* if */
      else RETURN (papNotPapyrusFile);

    /* avoid a bug with the old version of PAPYRUS ( < 3.3) */
    theElength = strlen (theValP->a);
    if (theValP->a [theElength - 1] == '0'  && 
        strcmp (theValP->a, gArrUIDs [NM_IM]) != 0 ) theValP->a [theElength - 1] = '\0';
  
    while (!found && i < END_MODALITY)
    {
      if (strcmp (theValP->a, gArrUIDs [(int) i]) == 0) 
      {
        found = TRUE;
        
        /* set the modality of the file */
        gFileModality [inFileNb] = (int)i;
      }
      else i++;
    } /* while */
  } /* if ...there is a value for getting the modality in group 2 */
  
  /* if theValP NULL or not found or untrustable file (...) */
  /* look for the element 0x0008:0x0060 modality 	*/
   /*if ((theValP == NULL) || (!found) || gIsPapyFile [inFileNb] == DICOM10)*/
  if (!found)
  {
    i = 0;
    /* keep the position in the file */
    theErr = Papy3FTell (gPapyFile [inFileNb], &theFilePos);
    
    /* reset the file pointer to its previous position */
    theErr = Papy3FSeek (gPapyFile [inFileNb], SEEK_SET, 132L);

    /* goto group 8 and read it */
    if ((theErr = Papy3GotoGroupNb (inFileNb, 0x0008)) < 0)
      { Papy3GroupFree (&theGroup2P, TRUE); RETURN (theErr); } 
    if ((theErr = Papy3GroupRead (inFileNb, &theGroupTmpP)) < 0)
      { Papy3GroupFree (&theGroup2P, TRUE); RETURN (theErr); }
    
    /* extract the modality */
    theValP = Papy3GetElement (theGroupTmpP, papModalityGr, &theNbVal, &theElemType);
    if (theValP != NULL)
      ExtractModality (theValP, inFileNb);
    /* else this file will not live */
    else 
    {
      /* free the group 8 */
      theErr = Papy3GroupFree (&theGroupTmpP, TRUE);
      theErr = Papy3GroupFree (&theGroup2P, TRUE); 
      RETURN (papElemOfTypeOneNotFilled);
    
    }
    /* free the group 8 */
    theErr = Papy3GroupFree (&theGroupTmpP, TRUE);
    
    /* reset the file pointer to its previous position */
    theErr = Papy3FSeek (gPapyFile [inFileNb], SEEK_SET, theFilePos);
    
  } /* if ...theValP is NULL or unknown UID */
      
  /* free group 2 as we do not need it anymore */
  theErr = Papy3GroupFree (&theGroup2P, TRUE);  
  
  RETURN (theErr);
  
} /* endof ExtractFileMetaInformation3 */



/********************************************************************************/
/*									 	*/
/*	ExtractPapyDataSetInformation3 : Extracts the data sets relativ 	*/
/*	information i.e. the number of images, and the offsets to the data sets */
/*	and the pixel datas for a PAPYRUS 3 file.				*/
/*	return : standard error message.					*/
/*										*/
/********************************************************************************/

PapyShort
ExtractPapyDataSetInformation3 (PapyShort inFileNb)
{
  PapyShort	theErr, i;
  PapyUShort	theElemCreator, theElemNb;
  PapyULong	theNbVal, theSavedFilePos, theItemLength, theULong;
  int		theElemType;
  SElement	*theGroupP;
  UValue_T	*theValP;
  
  
  /* move the file pointer to group 41 */
  if ((theErr = Papy3GotoGroupNb (inFileNb, 0x0041)) < 0) RETURN (theErr);
  
  /* find the creator element number for the PAPYRUS 3.0 elements */
  if ((theElemCreator = Papy3FindOwnerRange (inFileNb, 0x0041, "PAPYRUS 3.0")) == 0)
    RETURN (papNotFound);
  
  
  /* look for the position of the pointer and the image sequence */
  
  /* save the current file pos */
  Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &theSavedFilePos);
  
  /* elem (0x0041, 0x??10) = pointer sequence */
  theElemNb  = theElemCreator << 8;
  theElemNb |= 0x0010;
  if ((theErr = Papy3GotoElemNb (inFileNb, 0x0041, theElemNb, &theULong)) < 0) RETURN (theErr);
  Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &gOffsetToPtrSeq [inFileNb]);
  
  /* elem (0x0041, 0x??50) = image sequence */
  theElemNb  = theElemCreator << 8;
  theElemNb |= 0x0050;
  if ((theErr = Papy3GotoElemNb (inFileNb, 0x0041, theElemNb, &theULong)) < 0) RETURN (theErr);
  Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &gOffsetToImageSeq [inFileNb]);
  
  /* reset the file pointer to the begining of group 41 */
  Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theSavedFilePos);
  
  
  
  /* read THE group 41 and stores it */
  if ((theErr = Papy3GroupRead (inFileNb, &gArrGroup41 [inFileNb])) < 0) RETURN (papReadGroup);
  
  /* extracts the number of images in the file */
  theValP = Papy3GetElement (gArrGroup41 [inFileNb], papNumberofimagesGr, &theNbVal, &theElemType);
  if( theValP) gArrNbImages [inFileNb] = theValP->us;
  else RETURN (papReadGroup);
  
  
  /* allocate room for the offsets to the data set and pixel data of the file */
  gRefImagePointer [inFileNb] = (PapyULong *) ecalloc3 ((PapyULong) gArrNbImages [inFileNb], 
    						     (PapyULong) sizeof (PapyULong));
  gRefPixelOffset  [inFileNb] = (PapyULong *) ecalloc3 ((PapyULong) gArrNbImages [inFileNb], 
    						     (PapyULong) sizeof (PapyULong));
  /* allocate room for the SOP instance UID of the images */
  gImageSOPinstUID [inFileNb] = (char **) ecalloc3 ((PapyULong) gArrNbImages [inFileNb], 
    						     (PapyULong) sizeof (char *));
  
  
  
  /* extraction of the offsets to the data set(s) and the image(s) */
  /* so points to the first element of the pointer sequence */
  if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL)
    Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) (gOffsetToPtrSeq [inFileNb] + 8L));
  else if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL)
    Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) (gOffsetToPtrSeq [inFileNb] + 12L));
  
  /* extract the offset to data set and the image and the UID for each image */
  for (i = 0; i < gArrNbImages [inFileNb]; i++)
  {
    /* extract the length of this item of the pointer sequence */
    theItemLength  = Papy3ExtractItemLength (inFileNb);
    if ((int) theItemLength < 0) RETURN ((int) theItemLength);
    Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &theULong);
    theItemLength += theULong;
    
    /* move the file pointer to the group 41 of the pointer sequence */
    if ((theErr = Papy3GotoGroupNb (inFileNb, 0x0041)) < 0) RETURN (theErr);
    
    /* read the group */
    if ((theErr = Papy3GroupRead (inFileNb, &theGroupP)) < 0) RETURN (theErr);
    
    /* extract the offset to the data set */
    theValP = Papy3GetElement (theGroupP, papImagePointerGr, &theNbVal, &theElemType);
    *(gRefImagePointer [inFileNb] + i) = theValP->ul;
    
    /* extract the offset to the pixel datas */
    theValP = Papy3GetElement (theGroupP, papPixelOffsetGr, &theNbVal, &theElemType);
    *(gRefPixelOffset [inFileNb] + i) = theValP->ul;
    
    /* extract the SOP instance UID of the image */
    theValP = Papy3GetElement (theGroupP, papReferencedImageSOPClassUIDGr, &theNbVal, &theElemType);
    if (theValP != NULL)
      *(gImageSOPinstUID [inFileNb] + i) = (char *) PapyStrDup (theValP->a);
    
    /* free the group */
    theErr = Papy3GroupFree (&theGroupP, TRUE);
    
    /* go to the end of this item of the pointer sequence */
    Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theItemLength);
    
  } /* for ...extraction of the offsets to data set and the images */

  
  RETURN (theErr);
  
} /* endof ExtractPapyDataSetInformation3 */



/********************************************************************************/
/*									 	*/
/*	ExtractDicomDataSetInformation3 : Extracts the data sets relativ 	*/
/*	information i.e. the offsets to the data sets and the pixel datas for 	*/
/*	a DICOM file.								*/
/*	return : standard error message.					*/
/*										*/
/********************************************************************************/

PapyShort
ExtractDicomDataSetInformation3 (PapyShort inFileNb)
{
  PapyShort	theErr, i;
  PapyULong	theULong;
  PapyULong	theOffsetDataSet, theOffsetImage;
  
  
  /* move the file pointer to group 0x7FE0 */
  if ((theErr = Papy3GotoGroupNb (inFileNb, 0x7FE0)) < 0) RETURN (theErr);
  
  
  /* look for the position of the image pixel element */
  
  /* elem (0x7FE0, 0x0010) = image pixel */
  if ((theErr = Papy3GotoElemNb (inFileNb, 0x7FE0, 0x0010, &theULong)) < 0) RETURN (theErr);
  
  /* get the position of the element */
  Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &theOffsetImage);
  
  /* add something depending on the transfert syntax */
  if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL || 
      gArrTransfSyntax [inFileNb] == BIG_ENDIAN_EXPL) theOffsetImage += 12L;
  else theOffsetImage += 8L;
  
  
  /* set the position of the unique data set */
  /* part 10 compliant DICOM file */
  if (gIsPapyFile [inFileNb] == DICOM10) theOffsetDataSet = 132L;
  /* non-part 10 DICOM file */
  else if (gIsPapyFile [inFileNb] == DICOM_NOT10) theOffsetDataSet = 0L;
      
  
  
  /* allocate room for the offsets to the data set and pixel data of the file */
  gRefImagePointer [inFileNb] = (PapyULong *) ecalloc3 ((PapyULong) gArrNbImages [inFileNb], 
    						     (PapyULong) sizeof (PapyULong));
  gRefPixelOffset  [inFileNb] = (PapyULong *) ecalloc3 ((PapyULong) gArrNbImages [inFileNb], 
    						     (PapyULong) sizeof (PapyULong));
  
  
  /* put the offset to data set and the image for each image */
  for (i = 0; i < gArrNbImages [inFileNb]; i++)
  {
    /* put the offset to the data set */
    *(gRefImagePointer [inFileNb] + i) = theOffsetDataSet;
    
    /* put the offset to the pixel datas */
    *(gRefPixelOffset [inFileNb] + i) = theOffsetImage;
    
  } /* for ...putting the offsets to data set and the images */

  
  return 0;
  
} /* endof ExtractDicomDataSetInformation3 */



/********************************************************************************/
/*									 	*/
/*	Papy3GetModule : Get the specified module from the specified data set.	*/
/*	Beware : this routine DO NOT extract the pixel data from the file for 	*/
/*	optimization reasons. To get the image, get the module, the call the	*/
/*	Papy3GetPixelData routine.						*/
/*	return : the read module or NULL.					*/
/*										*/
/********************************************************************************/

pModule * CALLINGCONV
Papy3GetModule (PapyShort inFileNb, PapyShort inImageNb, int inModuleID)
{
  int		i, j, theElemType, theEnumTag, found, theOddGroup;
  int		*theListOfGroupsP, *theFooP, theElem = FALSE;
  PapyShort	theErr;
  PapyUShort	theElemTag, theElemCreator, theTmpTag;
  PapyULong	theItemLength, theNbVal, theLoopVal;
  UValue_T	*theValP, *theTmpValP;
  SElement	*theGrP, *theTmpGrP, *theZouzouteP;
  pModule	*theModuleP, *theElemP;

  
  /* if it is a PAPYRUS 3 file */
  switch (gIsPapyFile [inFileNb])
  {
    case DICOMDIR :	/* DICOMDIR file */
    case DICOM10 :	/* DICOM file */
      /* it is a basic part 10 DICOM file so jump past the file preamble */
      if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, 132L) != 0) return NULL;
      break;

    case PAPYRUS3 :	/* PAPYRUS 3 file */
      /* a usefull test */
      if (inImageNb > gArrNbImages [inFileNb] || inModuleID > END_MODULE) return NULL;
    
      /* position the file pointer at the right position */
      switch (inModuleID)
      {
        case GeneralPatientSummary :
        case GeneralVisitSummary :
        case GeneralStudySummary :
        case GeneralSeriesSummary :
          /* go to the begining of the first group of the summaries */ 
          if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, 132L) != 0) return NULL;
          if ((theErr = Papy3GotoGroupNb (inFileNb, 0x0008)) < 0) return NULL;
          break;
  
        case ImageIdentification :
        case IconImage :
        case ImagePointer :
        case PixelOffset :
          /* it is one of the pointer sequence module, so go to the given ptr sequence */
          if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) gOffsetToPtrSeq [inFileNb] + 8L) != 0)
          return NULL;
      
          /* look for the given item of the ptr seq */
          for (i = 1; i < inImageNb; i++)
          {
            theItemLength = Papy3ExtractItemLength (inFileNb);
            if ((int) theItemLength < 0) return NULL;
            if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) theItemLength) != 0) 
              return NULL;
          } /* for */
      
          /* then points to the first element of the item */
          if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) 8L) != 0) 
            return NULL;
          break;
    
        case InternalImagePointerSequence :
          /* get the whole pointer sequence so points to the begining of the ptr seq */
          if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) gOffsetToPtrSeq [inFileNb]) != 0)
            return NULL;
          break;
      
        case ImageSequencePap :
          /* get the whole image sequence, so points to the begining of the image seq */
          if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) gOffsetToImageSeq [inFileNb]) != 0)
            return NULL;
          break;
    
        default :
          /* it is a module of the specified data set, so go to the begining of it */
          if ((theErr = Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) *(gRefImagePointer [inFileNb] + inImageNb - 1))) < 0)
            return NULL;
          break;
      
      } /* switch ...positioning the file pointer at the right place */

      break; 	/* PAPYRUS file */
      
    case DICOM_NOT10 :	/* non-part 10 DICOM file */
      /* it is a basic non-part 10 DICOM file so set the file pointer at the begining */
      if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, 0L) != 0) return NULL;
      break;
    
    default :
      /* do nothing */
      break;
  
  } /* switch ...file type */


  /* creation of the module */
  theModuleP = CreateModule3 (inModuleID);
  
  /* initialize the lists of groups contained in the module to empty */
  theListOfGroupsP  = (int *) ecalloc3 ((PapyULong) END_GROUP, (PapyULong) sizeof (int));
  
  theFooP = NULL;
  /* scan the module to find its group composition */
  LookForGroupsInModule3 (theModuleP, inModuleID, theFooP, theListOfGroupsP);

  /* loop on the groups */
  for (i = 0; i < END_GROUP; i++)
  {
    /* read only the needed groups */
    if (theListOfGroupsP [i] == 1)
    {
      /* look for the group */
      if ((theErr = Papy3GotoGroupNb (inFileNb, (PapyShort) (gArrGroup [i].number))) == 0)
      {
        /* test wether it is an odd group number or not */
        if (gArrGroup [i].number % 2 != 0)
        {
          theOddGroup = TRUE;
          
          /* look for the owner range of the PAPYRUS 3.0 elements */
  	      theElemCreator = Papy3FindOwnerRange (inFileNb, gArrGroup [i].number, "PAPYRUS 3.0");
          
        } /* if ...odd group number */
        else theOddGroup = FALSE;
        
        /* read the group */
        if ((theErr = Papy3GroupRead (inFileNb, &theGrP)) < 0) 
        {Papy3ModuleFree (&theModuleP, inModuleID, TRUE); efree3 ((void **) &theListOfGroupsP); return NULL;}
        
        theElemP = theModuleP;
        /* test each element of the module to see if it belongs to the group */
        for (j = 0; j < gArrModule [inModuleID]; j++, theElemP++)
        {
          /* does the element belongs to the group ? */
          if (theElemP->group == theGrP->group)
          {
            /* locate the enum place of the element given its tag */
            theTmpGrP = theGrP;
            found = FALSE;
            theEnumTag = 0;
            theElemTag = theElemP->element;
            /* if it is an odd group number */
            if (theOddGroup && theElemTag >= 0x0100)
            {
              /* convert the element range to the one extracted from the file */
              /* 0xaabb -> 0x00bb */
              theTmpTag   = theElemTag << 8;
              theTmpTag   = theTmpTag  >> 8;
              /* put the theElemP creator in the 2 most significant bytes... */
              /* 0x00cc -> 0xcc00 */
              theElemTag  = theElemCreator << 8;
              /* ...and the element tag in the 2 less significant bytes */
              /* 0xccbb */
              theElemTag |= theTmpTag;
            } /* if ...odd group number */
              
            while (!found && (theEnumTag <= (long) gArrGroup [i].size))
            {
              if (theTmpGrP->element == theElemTag) found = TRUE;
              else
              {
                theEnumTag++;
                theTmpGrP++;
              } /* else */
            } /* while */
            
            /* if it is the pixel data element do not read it */
            if (found && !(theElemP->group == 0x7FE0 && theElemTag == 0x0010))
            {

              /* extract the element */
              theValP = Papy3GetElement (theGrP, theEnumTag, &theNbVal, &theElemType);
            
              /* put the element in the module */
              if (theValP != NULL)
              {
				        /* test that it has found at least one element */
                if (!theElem) theElem = TRUE;

                /* loop on the values of the element */
                for (theLoopVal = 0L, theTmpValP = theValP; theLoopVal < theNbVal; theLoopVal++, theTmpValP++)
                {
                  /* depending on the VR of the element put it to the group */
                  switch (theElemType)
                  {
                    case SS :
                      Papy3PutElement (theModuleP, j, &(theTmpValP->ss)); 
                      break;
                    case USS :
                    case AT :
                      Papy3PutElement (theModuleP, j, &(theTmpValP->us)); 
                      break;
		                case OB :
                      Papy3PutImage (inFileNb, theModuleP, j, (PapyUShort *) theTmpValP->a, 0, 0, 8, (theGrP + theEnumTag)->length);
                      break;
                    case OW :
                      Papy3PutImage (inFileNb, theModuleP, j, theTmpValP->ow, 0, 0, 16, (theGrP + theEnumTag)->length);
                      break;
                    case SL :
                      Papy3PutElement (theModuleP, j, &(theTmpValP->sl)); 
                      break;
                    case UL :
                      Papy3PutElement (theModuleP, j, &(theTmpValP->ul)); 
                      break;
                    case FL :
                      Papy3PutElement (theModuleP, j, &(theTmpValP->fl)); 
                      break;
                    case FD :
                      Papy3PutElement (theModuleP, j, &(theTmpValP->fd)); 
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
                      Papy3PutElement (theModuleP, j, &(theTmpValP->a)); 
                      break;
                    case UN :
                      Papy3PutUnknown (theModuleP, j, theTmpValP->a, (theGrP + theEnumTag)->length);
                      break;
                    case SQ :            
                      Papy3PutElement (theModuleP, j, &(theTmpValP->sq)); 
                      break;
                  } /* switch */
                } /* for ...loop on the values of the element */
              } /* if ...the element exists */
            } /* if ...the element is not pixel data */
            else 	/* it is the pixel data element */
            {
              /* put the element length and number of value if any */
              theZouzouteP = theGrP + theEnumTag;
              theElemP->nb_val = theZouzouteP->nb_val;
              theElemP->length = theZouzouteP->length;
            } /* else ...pixel data element */
            
          } /* if ...the element belongs to this group */
        } /* for ...loop on the elements of the module */
        
        /* free the group */
        /* first free the unused SQ element from the group */
        theErr = Papy3FreeSQElement (&theGrP, theModuleP, inModuleID);
        theErr = Papy3GroupFree (&theGrP, FALSE);
        
      } /* if ...the group exists */
    } /* if ...group has to be read */
    
  } /* for ...reading of the needed groups */
  
  /* delete the lists of groups number of the module */
  efree3 ((void **) &theListOfGroupsP);
  
  /* if no element found we have to assume the module is empty ... */
  if (!theElem)
  {
    Papy3ModuleFree (&theModuleP, inModuleID, TRUE);
    return NULL;
  } /* if */
  else 
    return theModuleP; 
   
} /* endof Papy3GetModule */
