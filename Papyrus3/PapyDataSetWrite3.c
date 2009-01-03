/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyDataSetWrite3.c                                          */
/*	Function : contains the functions that will manage the Data Sets and 	*/
/*		   the modules (writing).	                                */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes -----------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>


#ifdef Mac
#ifndef __LOWMEM__
#include <LowMem.h>
#endif
#ifndef __FILES__
#include <Files.h>
#endif
#include <Script.h>
#endif


#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif



/********************************************************************************/
/*									 	*/
/*	CreateFileMetaInformation3 : Creates the file meta information for the 	*/
/*	given file. It creates group2 and fill some elements.			*/
/*	return : noError if no problem						*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort
CreateFileMetaInformation3 (PapyShort inFileNb, enum EPap_Compression inCompression,
			    enum ETransf_Syntax inSyntax, enum EModality inModality)
{
  SElement	*theGr2P;
  papObject	*theObjectP;
  Item		*theItemP;
  PapyUShort	*theUsP;
  char		*theCharP, theChar [32];
  
  
  /* creation of the file meta information group */
  theGr2P = Papy3GroupCreate (Group2);
  
  /* provide the group structure with the needed information */
  /* set the last bit of the second byte in the file (after translation) to 1 */
  /* in order to identify the file meta information version (Version 2) */
  theUsP  = (PapyUShort *) emalloc3 ((PapyULong) sizeof (PapyUShort));
  *theUsP = 1;
  Papy3PutImage (inFileNb, theGr2P, papFileMetaInformationVersionGr, theUsP, 0, 0, 8, 2L);
  
  theCharP = (char*) &theChar[0];
  /* DICOMDIR defined SOP Class UID */
  if (gIsPapyFile [inFileNb] == DICOMDIR)
  {
    strcpy (theCharP, "1.2.840.10008.1.3.10");
    Papy3PutElement (theGr2P, papMediaStorageSOPClassUIDGr, &theCharP);
  }
  else
    /* media storage SOP class UID, i.e the UID of the imaging modality */
    Papy3PutElement (theGr2P, papMediaStorageSOPClassUIDGr, &(gArrUIDs [inModality]));
  
  /* the transfert syntax that will be used in the rest of the file */
  /* actually only the default DICOM syntax is supported, */
  /* i.e implicit VR little-endian with or without compression */  
  /* DISCUSS */
  if (inSyntax == LITTLE_ENDIAN_IMPL && inCompression == NONE)
    strcpy (theCharP, "1.2.840.10008.1.2");
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == NONE)
    strcpy (theCharP, "1.2.840.10008.1.2.1");
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == JPEG_LOSSLESS)
    strcpy (theCharP, "1.2.840.10008.1.2.4.70");
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == JPEG_LOSSY)
    strcpy (theCharP, "1.2.840.10008.1.2.4.51");
#ifdef MAYO_WAVE
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == MAYO_WAVELET)
    strcpy (theCharP, "1.2.840.10008.1.2.4.80"); 
    /* WARNING this is NOW defined in DICOM as JPEG-LS lossless image compression */
    /* whereas 1.2.840.10008.1.2.4.81 is JPEG-LS Lossy (near-Lossless) image compression */
    /* Warning: this SHOULD NOT BE a proprietary syntax transfer!!
     * the wavelet compression is still not standardized... 
     */
#endif /* MAYO_WAVE */
  else if (gIsPapyFile [inFileNb] == DICOMDIR)  /* DICOMDIR: LITTLE_ENDIAN_EXPL */
    strcpy (theCharP, "1.2.840.10008.1.2.1");
  Papy3PutElement (theGr2P, papTransferSyntaxUIDGr, &theCharP);
  
  /* we have to discuss what we will put here DISCUSS */
  strcpy (theCharP, "1.2.40.0.13.1.1.1");
  Papy3PutElement (theGr2P, papImplementationClassUIDGr, &theCharP);
  
  /* create an pObject and put the group 2 in it */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->group  = theGr2P;
  theObjectP->item   = NULL;
  theObjectP->module = NULL;
  theObjectP->record = NULL;
  theObjectP->tmpFileLength = 0L;
  theObjectP->whoAmI = papGroup;
  theObjectP->objID  = Group2;
  
  /* initialize the memory representation of the file by creating the first */
  /* cell that will contain the file meta information */
  theItemP = InsertFirstInList (&(gArrMemFile [inFileNb]), theObjectP);
    
  return papNoError;
  
} /* endof CreateFileMetaInformation3 */


/********************************************************************************/
/*									 	*/
/*	CreateDicomFileMetaInformation3 : Creates the file meta information for	*/
/*	the given file. It creates group2 and fill some elements. Then writes 	*/
/*	the group to the given file.						*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort
CreateDicomFileMetaInformation3 (PAPY_FILE inFp, PapyShort inFileNb, enum EPap_Compression inCompression,
			    	 enum ETransf_Syntax inSyntax, enum EModality inModality, 
			    	 PapyULong *OutMetaInfoSizeP)
{
  SElement	*theGr2P;
  PapyUShort	*theUsP;
  char		*theCharP, theChar [200];
  unsigned char	*theBuffP;
  PapyShort	theErr = 0;
  int		theGroupNb;
  PapyULong	theBufSize, thePos;
  
  
  /* creation of the file meta information group */
  theGr2P = Papy3GroupCreate (Group2);
  
  /* provide the group structure with the needed information */
  /* set the last bit of the second byte in the file (after translation) to 1 */
  /* in order to identify the file meta information version (Version 2) */
  theUsP  = (PapyUShort *) emalloc3 ((PapyULong) sizeof (PapyUShort));
  *theUsP = 1;
  Papy3PutImage (inFileNb, theGr2P, papFileMetaInformationVersionGr, theUsP, 0, 0, 8, 2L);
  
  /* media storage SOP class UID, i.e the UID of the imaging modality */
  Papy3PutElement (theGr2P, papMediaStorageSOPClassUIDGr, &(gArrUIDs [inModality]));
  
  /* the transfert syntax that will be used in the rest of the file */
  /* actually only the default DICOM syntax is supported, */
  /* i.e implicit VR little-endian with or without compression */  
  /* DISCUSS */
  theCharP = (char*) &theChar[0];
  if (inSyntax == LITTLE_ENDIAN_IMPL && inCompression == NONE)
    strcpy (theCharP, "1.2.840.10008.1.2");
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == NONE)
    strcpy (theCharP, "1.2.840.10008.1.2.1");
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == JPEG_LOSSLESS)
    strcpy (theCharP, "1.2.840.10008.1.2.4.70");
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == JPEG_LOSSY)
    strcpy (theCharP, "1.2.840.10008.1.2.4.51");
#ifdef MAYO_WAVE /* WARNING this is defined in DICOM as JPEG-LS lossless image compression */
		 /* whereas 1.2.840.10008.1.2.4.81 is JPEG-LS Lossy (near-Lossless) image compression */
  else if (inSyntax == LITTLE_ENDIAN_EXPL && inCompression == MAYO_WAVELET)
    strcpy (theCharP, "1.2.840.10008.1.2.4.80"); 
    /* Warning: this is a proprietary syntax transfer!!
     * the wavelet compression is still not standardized... 
     */
#endif /* MAYO_WAVE */
  Papy3PutElement (theGr2P, papTransferSyntaxUIDGr, &theCharP);
  
  /* SOP instance UID of this data set */
  /* convert an int into a string and add a number at the end to ensure uniqueness */
//  Papy3FPrint (theCharP, "64.572.218.916.%d", gCurrTmpFilename [inFileNb]);
  Papy3PutElement (theGr2P, papMediaStorageSOPInstanceUIDGr, &gPapSOPInstanceUID[inFileNb]);
  
  /* who is the creator of this wonderfull file ? */
  strcpy (theCharP, "OSIRIX MACOS");
  Papy3PutElement (theGr2P, papSourceApplicationEntityTitleGr, &theCharP);
  
  /* we have to discuss what we will put here DISCUSS */
  strcpy (theCharP, "1.2.40.0.13.1.1.1");
  Papy3PutElement (theGr2P, papImplementationClassUIDGr, &theCharP);
  
  /* now write the group to the file */
  if ((theGroupNb = Papy3ToEnumGroup (theGr2P->group)) < 0)
    RETURN (papGroupNumber);

  /* compute the size of the current group */
  ComputeGroupLength3 ((PapyShort) theGroupNb, theGr2P, NULL, inSyntax);
  theBufSize = theGr2P->value->ul + kLength_length;
    
  /* alloc the buffer that will contain the ready to write group */
  theBuffP = (unsigned char *) emalloc3 ((PapyULong) theBufSize);
    
  thePos = 0L;    
  /* put the elements of the group to the write buffer */
  if ((theErr = PutGroupInBuffer (inFileNb, 1, theGroupNb, theGr2P, theBuffP, &thePos, FALSE)) < 0) 
    RETURN (theErr);
    
  /* write the buffer to the temporary file */
  if ((theErr = WriteGroup3 (inFp, theBuffP, theBufSize)) < 0)
    RETURN (theErr);  
    
  /* frees the allocated buffer */
  efree3 ((void **) &theBuffP);
  
  /* compute the size of the file meta information */
  *OutMetaInfoSizeP = theBufSize + 132L;
    
  return theErr;
  
} /* endof CreateDicomFileMetaInformation3 */


/********************************************************************************/
/*									      	*/
/*	Papy3GetGroup2 : Returns a pointer to the group 2 to allow the user to	*/
/*	put the needed elements in it.						*/
/*	return : a pointer to the group 2					*/
/*										*/
/********************************************************************************/

SElement * CALLINGCONV
Papy3GetGroup2 (PapyShort inFileNb)
{
  return (gArrMemFile [inFileNb])->object->group;
} /* endof Papy3GetGroup2 */



/********************************************************************************/
/*									 	*/
/*	Papy3GetRecordType : Function only used when creating Dicomdir file	*/
/*	return : an enumerated value which identify the kind of record.		*/
/*										*/
/********************************************************************************/

int CALLINGCONV
Papy3GetRecordType (SElement *inGroup)
{
  int		theElemType;
  PapyULong	thePos;
  UValue_T	*theValP;
  char 		theDirType [257]; /* VR_CS_LENGTH = 256 */
  int		theRecordID = -1;

  
  /* Read the directory type  (0004,1430) */
  theValP = Papy3GetElement (inGroup, papDirectoryRecordTypeGr, &thePos, &theElemType);
  if (theValP != NULL) 
    strcpy (theDirType , theValP->a);
  
  switch (theDirType [0])
  {
    case 'P' :
      switch (theDirType [1])
      {
        case 'A' : 
          theRecordID = PatientR; 
          break;
        case 'R' : 
          theRecordID = PrintQueue; 
          break;
      }/* switch */
      break;
    case 'S' :
      switch (theDirType [4])
      {
        case 'Y' : 
          if (theDirType [5] == 'C') 
            theRecordID = StudyComponentR;
          else 
            theRecordID = StudyR;
          break;
        case 'E' : 
          theRecordID = SeriesR; 
          break;
      }/* switch ...theDirType [4] */
      break;
    case 'I' :
      switch (theDirType [1])
      {
        case 'M' :
          theRecordID = ImageR;
          break;
        case 'N' :
          theRecordID = Interpretation;
          break;
      }/* switch */
      break;
    case 'O' :	
      theRecordID = OverlayR;
      break;
    case 'M' :	
      theRecordID = ModalityLUTR;
      break;
    case 'V' :
      switch (theDirType [1])
      {
        case 'O' :
          theRecordID = VOILUTR;
          break;
        case 'I' :
          theRecordID = Visit;
          break;
      }/* switch */
      break;
    case 'C' :
      theRecordID = CurveR;
      break;
    case 'T' :
      theRecordID = Topic;
      break;
    case 'R' :
      theRecordID = Result;
      break;
    case 'F' :
      theRecordID = FilmSession;
      break;
    case 'B' :
      switch (theDirType [5])
      {
        case 'F' :
          theRecordID = BasicFilmBox;
          break;
        case 'I' :
          theRecordID = BasicImageBox;
          break;
      }/* switch */
      break;
  
  } /* switch ...theDirType [0] */
  
  return theRecordID;

} /* endof Papy3GetRecordType */


/********************************************************************************/
/*									      	*/
/*	Papy3CreateDataSet : Create a new data set item and add it to 		*/
/*	the list of Data Set of the given file.					*/
/*	return : a pointer to the created Data Set				*/
/*		 NULL otherwise							*/
/*										*/
/********************************************************************************/

Item * CALLINGCONV
Papy3CreateDataSet (PapyShort inFileNb)
{
  papObject	*theObjectP;
  Item		*theItemP, *theWrkP;
  SElement	*theGr41P;
  int		first = FALSE;
  
  
  /* if it is the first data set ... */
  if (gImageSequenceItem [inFileNb] == NULL) first = TRUE;
  
  /* creates an empty object that will point to the list of modules */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI 		= papItem;
  theObjectP->item   		= NULL;
  theObjectP->module 		= NULL;
  theObjectP->record 		= NULL;
  theObjectP->group 		= NULL;
  theObjectP->tmpFileLength 	= 0L;
  
  theItemP = InsertLastInList (&(gImageSequenceItem [inFileNb]), theObjectP);
  
  /* if it is the first data set, store the pointer to it in group 41 */
  if (first)
  {
    theWrkP  = gArrMemFile [inFileNb];
    theWrkP  = theWrkP->next->next;			/* locate group41 */
    theGr41P = theWrkP->object->group;
    Papy3PutElement (theGr41P, papImageSequenceGr, &(gImageSequenceItem [inFileNb]));
  } /* if */
    
  return theItemP;
  
} /* endof Papy3CreateDataSet */



/********************************************************************************/
/*									      	*/
/*	Papy3InsertItemToSequence : Create a new pObject that will point to the 	*/
/*	given Item (a group or a module or whatever you liked).	Then link the 	*/
/*	pObject to the given sequence.						*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3InsertItemToSequence (pModule *inModuleP, int inElemNb, enum EKind_Obj inItemType, 
			   void *inItem, int inItemId)
{
  pModule	*theElementP;
  papObject	*theObjectP;
  Item		*theNewItemP, *theObjectListP;
  int		first = FALSE;
  
  
  /* go to the element to add the item to */
  theElementP = inModuleP + inElemNb;
  
  /* if there were no value, add one */
  if (theElementP->nb_val == 0L) 
  {
    theElementP->nb_val = 1L;
    /* allocate room for the value to be inserted */
    theElementP->value = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
    /* and initializes it to NULL */
    theElementP->value->sq = NULL;
    
    /* creates the first part of the link */
    theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
    theObjectP->whoAmI 	      = papItem;
    theObjectP->item          = NULL;
    theObjectP->module 	      = NULL;
    theObjectP->record 	      = NULL;
    theObjectP->group         = NULL;
    theObjectP->tmpFileLength = 0L;
    /* and link it to the sequence */
    theObjectListP = InsertLastInList (&(theElementP->value->sq), theObjectP);
    
    first = TRUE;
    
  } /* if ...no value */
    
  /* get the pointer to the list of objects */
  theObjectListP = theElementP->value->sq->object->item;
  
  /* creates an empty object that will point to the item to insert */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI 	    = inItemType;
  theObjectP->objID  	    = inItemId;
  theObjectP->item   	    = NULL;
  theObjectP->module 	    = NULL;
  theObjectP->record 	    = NULL;
  theObjectP->group  	    = NULL;
  theObjectP->tmpFileLength = 0L;
  
  /* assign the item to the pObject */
  switch (inItemType)
  {
    case papItem   :
      theObjectP->item   = (Item *)     inItem;
      break;
    case papGroup  :
      theObjectP->group  = (SElement *) inItem;
      break;
    case papModule :
      theObjectP->module = (pModule *)   inItem;
      break;
    case papRecord :
      theObjectP->record = (Record *)   inItem;
      break;
    case papTmpFile:
    default :
      break;
  } /* switch */
  
  /* insert the pObject in the sequence */
  theNewItemP = InsertLastInList (&(theObjectListP), theObjectP);
  
  if (first)
    theElementP->value->sq->object->item = theNewItemP;
    
  return 0;
  
} /* endof Papy3InsertItemToSequence */



/********************************************************************************/
/*									 	*/
/*	CreateIcon3 : Create the icon pixel data for the Icon Image module of 	*/
/*	the module currently being closed.					*/
/* 	Each pixel of the icon is computed as a subsampling of the original 	*/
/* 	image.		 							*/
/*	return : a pointer to the pixel data of the icon.			*/
/*										*/
/********************************************************************************/

PapyUShort *
CreateIcon3 ()
{
  /* PapyUShort		gRefColumns; 		 width of original image */
  /* PapyUShort		gRefRows;		 height of original image */
  /* PapyUShort		gRefIsSigned;		 signed datas or no */
  /* PapyUShort		gRefBitsAllocated; 	 depth of original image (8 or 16 bits) */
  /* PapyUShort*	gRefPixelData;		 original pixmap, char* for 8 
                                                 bits images
						 or short* for 16 bits images */

  /* PapyUShort		gIconSize;		 width  of icon */
  /* PapyUShort		gIconSize;		 height of icon */

  PapyUShort		*theUSIconP;		/* destination pixmap (16 bits)*/
  PapyUChar		*theUCIconP;		/* ptr on the dest. pixmap (8 bits) */

  PapyULong		theLine, theRatio;
  PapyUShort		i, j;
  
  int 			theMin, theMax;


  /* if there were no WW or WL saved in the file then assume default values */
  if (gRefWW == -1 && gRefWW == gRefWL) 
  {
    gRefWW = (int) (gRefPixMax - gRefPixMin + 1);
    gRefWL = (gRefWW / 2) + (int) gRefPixMin;
  } /* if */
  
  /* avoids dividing by zero */
  if (gRefWW == 0) gRefWW = 1;
  
  /* allocate the memory for the icon */
  theUSIconP = (PapyUShort *) emalloc3 ((PapyULong) (gIconSize * gIconSize));
  theUCIconP = (PapyUChar *) theUSIconP;
    
  /* computes the ratios between the image and the icon */
  theRatio = (PapyULong) gRefColumns * (PapyULong) gRefRows / (PapyULong) gIconSize; 
  
  /* 8 bits image */
  if (gRefBitsAllocated == 8) 
  {
    PapyUChar	*thePixmapP;

    thePixmapP = (PapyUChar *) gRefPixelData;
    
    for (i = 0; i < gIconSize; i++)			/* lines */
    {
      theLine = (PapyULong) ((PapyULong)i * theRatio);
      theLine = (theLine / gRefColumns) * gRefColumns;		/* must be an integer number of lines */

      for (j = 0; j < gIconSize; j++, theUCIconP++)		/* columns */
        *theUCIconP = (PapyUChar) *(thePixmapP + (theLine + ((PapyULong) j * (PapyULong) gRefColumns / (PapyULong) gIconSize)));
      
    } /* for ...i */
	
  } /* if ...8 bits image */
  
  /* 12 or 16 bits image */
  else 
  {
    if (gRefIsSigned)
    {
      PapyShort	*thePixmapP;
      PapyShort	theValue;

      /* computes the min and max pixel values */
      theMin = gRefWL - (gRefWW / 2);
      theMax = theMin + gRefWW;

      thePixmapP = (PapyShort *) gRefPixelData;

      for (i = 0; i < gIconSize; i++)				/* lines */
      {
        theLine = (PapyULong) ((PapyULong) i * theRatio);
        theLine = (theLine / gRefColumns) * gRefColumns;	/* must be an integer number of lines */

        for (j = 0; j < gIconSize; j++, theUCIconP++)		/* columns */
        {
          /* first get the subsampled pixel value */
          theValue = (PapyShort) *(thePixmapP + (theLine + ((PapyULong) j * (PapyULong) gRefColumns / (PapyULong) gIconSize)));
          if (theValue < (PapyShort) theMin) theValue = (PapyShort) theMin;
          if (theValue > (PapyShort) theMax) theValue = (PapyShort) theMax;

          /* then convert it to an 8 bit value */
          *theUCIconP = (PapyUChar) (((PapyShort) theValue - theMin) * 255 / (PapyShort) gRefWW);
        } /* for ...j */

      } /* for ...i */

    } /* if ...signed values */
    else /* unsigned values */
    {
      PapyUShort		*thePixmapP;
      PapyUShort		theValue;

      /* computes the min and max pixel values */
      theMin = gRefWL - (gRefWW / 2);
      theMax = theMin + gRefWW; 
      if (theMin < 0) theMin = 0;
    
      thePixmapP = (PapyUShort *) gRefPixelData;
    
      for (i = 0; i < gIconSize; i++)			/* lines */
      {
        theLine = (PapyULong) ((PapyULong) i * theRatio);
        theLine = (theLine / gRefColumns) * gRefColumns;	/* must be an integer number of lines */

        for (j = 0; j < gIconSize; j++, theUCIconP++)	/* columns */
        {
          /* first get the subsampled pixel value */
          theValue = (PapyUShort) *(thePixmapP + (theLine + ((PapyULong) j * (PapyULong) gRefColumns / (PapyULong) gIconSize)));
        
          if (theValue < (PapyUShort) theMin) theValue = (PapyUShort) theMin;
          if (theValue > (PapyUShort) theMax) theValue = (PapyUShort) theMax;
        
          /* then convert it to an 8 bit value */
          *theUCIconP = (PapyUChar) (((PapyUShort) theValue - theMin) * 255 / (PapyUShort) gRefWW);
        } /* for ...j */
      
      } /* for ...i */

    } /* else ...unsigned values */ 
	
  } /* else ...12 or 16 bits image */
  
  /* free the original image as we do not need it any more */
  gRefPixelData = NULL;
  
  return theUSIconP;

} /* endof CreateIcon3 */



/********************************************************************************/
/*									 	*/
/*	CreatePointerSequence3 : Creates the pointer sequence for the given data*/
/*	set of the given file. It will fill the Image Identification pModule, 	*/
/*	the Icon Image pModule, the Image Pointer pModule and the Pixel Offset	*/
/*	pModule.									*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort
CreatePointerSequence3 (PapyShort inFileNb, Item *inDataSetP)
{
  PapyShort	thePosOfInsert, first;
  int		theCreateIconImage = TRUE;
  PapyULong	theULong;
  Item		*theWrkItemP, *theSeqItemP;
  papObject	*theObjectP;
  pModule	*theModuleP;
  PapyUShort	theUShort, *theIconP;
  char		*theCharP, theChar [16];
  
  
  /* -------- insert the item in the pointer sequence -------- */
  
  /* Look for the position of the data set in the list in order   */
  /* to know where to insert the new item in the pointer sequence */
  thePosOfInsert = 0;
  theWrkItemP = gImageSequenceItem [inFileNb];
  /* loop until data set found */
  while (theWrkItemP != inDataSetP)
  {
    thePosOfInsert++;
    theWrkItemP = theWrkItemP->next;
  } /* while */
  
  /* if it is the first item of the Pointer Sequence ... */
  if (gPtrSequenceItem [inFileNb] == NULL) first = TRUE;
  else first = FALSE;
  
  /* creates an empty object that will point to the list of modules */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI 	    = papItem;
  theObjectP->item   	    = NULL;
  theObjectP->module 	    = NULL;
  theObjectP->record 	    = NULL;
  theObjectP->group  	    = NULL;
  theObjectP->tmpFileLength = 0L;
  
  /* insert the item in the pointer sequence at the specified position */
  theSeqItemP = InsertInListAt ((Item **) &gPtrSequenceItem [inFileNb], theObjectP, thePosOfInsert);
  
  /* if it is the first item of the pointer sequence, store the pointer to it in group 41 */
  if (first)
  {
    theWrkItemP = gArrMemFile [inFileNb];
    theWrkItemP = theWrkItemP->next; 
    theWrkItemP = theWrkItemP->next;	/* locate group41 */
    Papy3PutElement (theWrkItemP->object->group, papPointerSequenceGr, &theSeqItemP);
  } /* if */
  
  
  /* -------- create the Image Identification module -------- */
  theModuleP = Papy3CreateModule (theSeqItemP, ImageIdentification);
  
  /* fill the elements of the Image Identification module */
  Papy3PutElement (theModuleP, papReferencedImageSOPClassUIDII, &gRefSOPClassUID [inFileNb]);
  Papy3PutElement (theModuleP, papReferencedImageSOPInstanceUID, &gRefSOPInstanceUID);
  Papy3PutElement (theModuleP, papImageNumberII, &gRefImageNb);
  
  efree3 ((void **) &gRefImageNb);
  efree3 ((void **) &gRefSOPInstanceUID);
  
  /* -------- create the Icon Image module -------- */
  /* in case of a Papyrus compressed image look if there is an icon to put */
  if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL && 
       (gArrCompression [inFileNb] == JPEG_LOSSLESS || gArrCompression [inFileNb] == JPEG_LOSSY
#ifdef MAYO_WAVE
	  || gArrCompression [inFileNb] == MAYO_WAVELET
#endif
          ) &&
      gArrIcons [inFileNb] [thePosOfInsert] == NULL) theCreateIconImage = FALSE;
  
  if (theCreateIconImage)
  {
    theModuleP = Papy3CreateModule (theSeqItemP, IconImage);
  
    /* fill the elements of the Icon Image module */
    theUShort = 1;
    Papy3PutElement (theModuleP, papSamplesperPixelII, &theUShort);
  
    theCharP = (char *) &theChar [0];
    strcpy (theCharP, "MONOCHROME2");	/* monochrome2 : 0 = black */
    Papy3PutElement (theModuleP, papPhotometricInterpretationII, &theCharP);
    Papy3PutElement (theModuleP, papRowsII,    &gIconSize);
    Papy3PutElement (theModuleP, papColumnsII, &gIconSize);
    theUShort = 8;		/* the icon should be coded on 8 bits */
    Papy3PutElement (theModuleP, papBitsAllocatedII, &theUShort);
    Papy3PutElement (theModuleP, papBitsStoredII,    &theUShort);
    theUShort--;		/* high bit should be one less than bits allocated */
    Papy3PutElement (theModuleP, papHighBitII, &theUShort);
    theUShort = 0;	      /* this means pixel representation = PapyUShort */
    Papy3PutElement (theModuleP, papPixelRepresentationII, &theUShort);
  
    /* take the icon image from the list */
    if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL && (gArrCompression [inFileNb] == JPEG_LOSSLESS
							   || gArrCompression [inFileNb] == JPEG_LOSSY 
#ifdef MAYO_WAVE
                					   || gArrCompression [inFileNb] == MAYO_WAVELET
#endif
       ))
    {
      theIconP = (PapyUShort *) (gArrIcons [inFileNb] [thePosOfInsert]);
      Papy3PutImage (inFileNb, theModuleP, papPixelDataII, theIconP, gIconSize, gIconSize, 8, 0L);
      efree3 ((void **) &(gArrIcons [inFileNb] [thePosOfInsert]));
    } /* if ...take the icon from the list */
    /* create the icon pixels from the image */
    else
    {
      theIconP = CreateIcon3 ();
      Papy3PutImage (inFileNb, theModuleP, papPixelDataII, theIconP, gIconSize, gIconSize, 8, 0L);
    } /* else ...compute the icon from the original image */
  
  } /* if ...creation of the icon image module */
  
  /* -------- create the Image Pointer module -------- */
  theModuleP = Papy3CreateModule (theSeqItemP, ImagePointer);

  /* the offset to the data set is zero relatively to the temp. file */
  theULong = 0L;		
  Papy3PutElement (theModuleP, papImagePointer, &theULong);
  
  /* -------- create the Pixel Offset module -------- */
  theModuleP = Papy3CreateModule (theSeqItemP, PixelOffset);

  /* the offset to the pixel data in the tmp file */
  Papy3PutElement (theModuleP, papPixelOffset, &theULong);
  
  return 0;
  
} /* endof CreatePointerSequence3 */ 



/********************************************************************************/
/*										*/
/*	Papy3LinkModuleToDS : Link the given module to the Data Set.		*/
/*										*/
/********************************************************************************/

void CALLINGCONV
Papy3LinkModuleToDS (Item *inDataSetP, pModule *inModuleP, int inModuleName)
{
  Item		*theItemP;
  papObject	*theObjectP;
  
    
  /* ------- link the created module to the list of modules of the data set ---- */
  
  /* creation of the pObject pointing to the module */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI = papModule;
  theObjectP->objID  = inModuleName;
  /* link the module to the object */
  theObjectP->module = inModuleP;
  theObjectP->record = NULL;
  theObjectP->item   = NULL;
  theObjectP->group  = NULL;
  theObjectP->file	 = NULL;
  theObjectP->tmpFileLength = 0L;

  /* insert the item at the end of the list of modules of the data set */
  theItemP = InsertLastInList ((Item **) &(inDataSetP->object->item), theObjectP);

} /* endof Papy3LinkModuleToDS */



/********************************************************************************/
/*										*/
/*	Papy3LinkGroupToDS : Link the given group to the Data Set.		*/
/*										*/
/********************************************************************************/

void CALLINGCONV
Papy3LinkGroupToDS (Item *inDataSetP, SElement *inGroupP, int inGroupName)
{
  Item		*theItemP;
  papObject	*theObjectP;
  

  /* ------- link the created group to the list of modules/groups of the data set ---- */
  
  /* creation of the pObject pointing to the group */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI 	    = papGroup;
  theObjectP->objID  	    = inGroupName;
  /* link the group to the object */
  theObjectP->group  	    = inGroupP;
  theObjectP->item   	    = NULL;
  theObjectP->module 	    = NULL;
  theObjectP->file   	    = NULL;
  theObjectP->tmpFileLength = 0L;

  /* insert the item at the end of the list of modules/groups of the data set */
  theItemP = InsertLastInList ((Item **) &(inDataSetP->object->item), theObjectP);

} /* endof Papy3LinkGroupToDS */



/********************************************************************************/
/*										*/
/*	Papy3CreateModule : Create a new module and add it to the list of 	*/
/*	modules of the Data Set.						*/
/*	return : a pointer to the created module				*/
/*		 NULL otherwise							*/
/*										*/
/********************************************************************************/

pModule * CALLINGCONV 
Papy3CreateModule (Item *inDataSetP, int inModuleName)
{
  pModule	*theModuleP;
  
  
  /* create the module a la Papy3GroupCreate */
  theModuleP = CreateModule3 (inModuleName);
  
  /* link the module to the list of the data set */
  Papy3LinkModuleToDS (inDataSetP, theModuleP, inModuleName);
    
  return theModuleP;

} /* endof Papy3CreateModule */



/********************************************************************************/
/*										*/
/*	Papy3FindModule : Finds the given module in the given data set of the  	*/
/*	given file (write).							*/
/*	return : A pointer to the module or NULL if the module does not exist.	*/
/*										*/
/********************************************************************************/

pModule * CALLINGCONV
Papy3FindModule (Item *inDataSetP, int inModuleID)
{
  Item	*theWrkItemP;
  int	found = FALSE;
  
  
  /* points to the first module of the list */
  theWrkItemP = inDataSetP;
  if (theWrkItemP == NULL) return NULL;
  
  /* loop on the modules until it finds the right one */
  while (!found && theWrkItemP->next != NULL)
  {
    if (theWrkItemP->object->objID == inModuleID) found = TRUE;
    else theWrkItemP = theWrkItemP->next;
  } /* while */
  
  if (found) return theWrkItemP->object->module;
  else return NULL;
  
} /* endof Papy3FindModule */



/********************************************************************************/
/*										*/
/*	CheckDataSetModules3 : check the given data set to see if all the needed*/
/*	modules have been filled.						*/
/*	return : standard error message.					*/
/*										*/
/********************************************************************************/

PapyShort
CheckDataSetModules3 (PapyShort inFileNb, Item *inDataSetP)
{
  PapyShort	i, theMaxLoop, found;
  Item		*theWrkItemP;
  Data_Set	*theWrkDSP;
  
  
  /* how many elements do we have to check ? */
  switch (gFileModality [inFileNb])
  {
    case CR_IM :
      theMaxLoop = gArrModuleNb [CR_IM];
      break;
    case CT_IM :
      theMaxLoop = gArrModuleNb [CT_IM];
      break;
    case MR_IM :
      theMaxLoop = gArrModuleNb [MR_IM];
      break;
    case NM_IM :
      theMaxLoop = gArrModuleNb [NM_IM];
      break;
    case US_IM :
      theMaxLoop = gArrModuleNb [US_IM];
      break;
    case US_MF_IM :  
      theMaxLoop = gArrModuleNb [US_MF_IM];
      break;
    case SEC_CAPT_IM :
      theMaxLoop = gArrModuleNb [SEC_CAPT_IM];
      break;
    case PX_IM :
    case DX_IM :
      theMaxLoop = gArrModuleNb [DX_IM];
      break;
    case MG_IM :
      theMaxLoop = gArrModuleNb [MG_IM];
      break;
    case IO_IM :
      theMaxLoop = gArrModuleNb [IO_IM];
      break;
    case RF_IM :
      theMaxLoop = gArrModuleNb [RF_IM];
      break;
    case PET_IM :
      theMaxLoop = gArrModuleNb [PET_IM];
      break;
    case VLE_IM :
      theMaxLoop = gArrModuleNb [VLE_IM];
      break;
    case VLM_IM :
      theMaxLoop = gArrModuleNb [VLM_IM];
      break;
    case VLS_IM :
      theMaxLoop = gArrModuleNb [VLS_IM];
      break;
    case VLP_IM :
      theMaxLoop = gArrModuleNb [VLP_IM];
      break;
    case MFSBSC_IM :
      theMaxLoop = gArrModuleNb [MFSBSC_IM];
      break;
    case MFGBSC_IM :
      theMaxLoop = gArrModuleNb [MFGBSC_IM];
      break;
    case MFGWSC_IM :
      theMaxLoop = gArrModuleNb [MFGWSC_IM];
      break;
    case MFTCSC_IM :
      theMaxLoop = gArrModuleNb [MFTCSC_IM];
      break;
  } /* switch */
  
  /* check the data set */
  theWrkDSP = gArrModalities [gFileModality [inFileNb]];
  for (i = 0; i < theMaxLoop; i++)
  {
    /* is the checked module mandatory ? */
    if (theWrkDSP->usage == M)
    {
      /* look if this module is in the data set */
      theWrkItemP = (Item *) inDataSetP->object->item;
      found = FALSE;
      while (theWrkItemP != NULL && !found)
      {
        if ((theWrkItemP->object != NULL) && 
            (theWrkItemP->object->objID  == theWrkDSP->moduleName) &&
            (theWrkItemP->object->whoAmI == papModule)) found = TRUE;
        theWrkItemP = theWrkItemP->next;
      } /* while */
      
      if (!found) RETURN (papMissingModule);
    
    } /* if ...we only check the mandatory modules */
    
    /* incrementation */
    theWrkDSP++;
  } /* for ...checking the data set */
  
  return 0;
  
} /* endof CheckDataSetModules3 */



/********************************************************************************/
/*										*/
/*	CreatePatientSummary3 : Creates the general patient summary module for 	*/
/*	the given file. It takes the datas out of the Patient and the Patient 	*/
/*	Study modules.								*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
CreatePatientSummary3 (PapyShort inFileNb)
{
  int		theElemType;
  Item		*theFirstDataSetP;
  pModule	*theFromModuleP, *thePatSumModuleP;
  UValue_T	*theValP;
  PapyULong	theNbVal;
  
  
  /* search the first data set */
  theFirstDataSetP = (Item *) gImageSequenceItem [inFileNb]->object->item;
  
  /* search for the Patient module */
  theFromModuleP = Papy3FindModule (theFirstDataSetP, Patient);
  if (theFromModuleP == NULL) RETURN (papMissingModule);
  
  /* create the general patient summary module and add it to the list of summaries */
  thePatSumModuleP = Papy3CreateModule (gPatientSummaryItem [inFileNb], GeneralPatientSummary);
  
  /* copy the elements from the Patient module to the Patient Summary module */
  theValP = Papy3GetElement (theFromModuleP, papPatientsNameP, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSumModuleP, papPatientsNameGPS, &(theValP->a));
  
  theValP = Papy3GetElement (theFromModuleP, papPatientIDP, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSumModuleP, papPatientsID, &(theValP->a));
  
  theValP = Papy3GetElement (theFromModuleP, papPatientsBirthDateP, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSumModuleP, papPatientsBirthDateGPS, &(theValP->a));
  
  theValP = Papy3GetElement (theFromModuleP, papPatientsSexP, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSumModuleP, papPatientsSexGPS, &(theValP->a));
  
  /* search for the Patient Study module */
  theFromModuleP = Papy3FindModule (theFirstDataSetP, PatientStudy);
  if (theFromModuleP == NULL) RETURN (papNoError);
  
  /* copy the elements from the Patient Study module to the Patient Summary module */
  theValP = Papy3GetElement (theFromModuleP, papPatientsSizePS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSumModuleP, papPatientsHeight, &(theValP->a));
  
  theValP = Papy3GetElement (theFromModuleP, papPatientsWeightPS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSumModuleP, papPatientsWeightGPS, &(theValP->a));
    
  return 0;
  
} /* endof CreatePatientSummary3 */



/********************************************************************************/
/*										*/
/*	CreateStudySummary3 : Creates the general study summary module for 	*/
/*	the given file. It takes the datas out of the General Study module.	*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
CreateStudySummary3 (PapyShort inFileNb)
{
  int		theElemType;
  Item		*theFirstDataSetP;
  pModule	*theFromModuleP, *thePatStudyModuleP;
  UValue_T	*theValP;
  PapyULong	theNbVal;
  
  
  /* search the first data set */
  theFirstDataSetP = (Item *) gImageSequenceItem [inFileNb]->object->item;
  
  /* search for the General Study module */
  theFromModuleP = Papy3FindModule (theFirstDataSetP, GeneralStudy);
  if (theFromModuleP == NULL) RETURN (papMissingModule);
  
  /* create the general study summary module and add it to the list of summaries */
  thePatStudyModuleP = Papy3CreateModule (gPatientSummaryItem [inFileNb], GeneralStudySummary);
  
  /* copy the elements to the General Patient Summary module */
  theValP = Papy3GetElement (theFromModuleP, papStudyDateGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatStudyModuleP, papStudyDateGSS, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papStudyTimeGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatStudyModuleP, papStudyTimeGSS, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papStudyInstanceUIDGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatStudyModuleP, papStudyUID, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papStudyIDGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatStudyModuleP, papStudyIDGSS, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papAccessionNumberGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatStudyModuleP, papAccessionnumberGSS, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papReferringPhysiciansNameGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatStudyModuleP, papReferringPhysiciansNameGSS, &(theValP->a));
  
  return 0;
  
} /* endof CreateStudySummary3 */



/********************************************************************************/
/*										*/
/*	CreateSeriesSummary3 : Creates the general series summary module for the*/
/*	given file. It takes the datas out of the General series module and the */
/*	group 41.								*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
CreateSeriesSummary3 (PapyShort inFileNb)
{
  int		theElemType;
  Item		*theFirstDataSetP;
  pModule	*theFromModuleP, *thePatSeriesModuleP;
  UValue_T	*theValP;
  PapyULong	theNbVal;
  
  
  /* search the first data set */
  theFirstDataSetP = (Item *) gImageSequenceItem [inFileNb]->object->item;
  
  /* search for the General Series module */
  theFromModuleP = Papy3FindModule (theFirstDataSetP, GeneralSeries);
  if (theFromModuleP == NULL) RETURN (papMissingModule);
  
  /* create the general series summary module and add it to the list of summaries */
  thePatSeriesModuleP = Papy3CreateModule (gPatientSummaryItem [inFileNb], GeneralSeriesSummary);
  
  /* copy the elements to the General Series Summary module */
  theValP = Papy3GetElement (theFromModuleP, papModalityGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSeriesModuleP, papModalityGSS, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papSeriesInstanceUIDGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSeriesModuleP, papSeriesInstanceUIDGSS, &(theValP->a));

  theValP = Papy3GetElement (theFromModuleP, papSeriesNumberGS, &theNbVal, &theElemType);
  if (theValP != NULL)
    Papy3PutElement (thePatSeriesModuleP, papSeriesNumberGSS, &(theValP->a));
  
  /* !! dont take number of images from group 41 as it will remain there when written */
  
  return 0;
  
} /* endof CreateSeriesSummary3 */


/********************************************************************************/
/*										*/
/*	CreateSummaries3 : Creates the summaries modules for the given file.	*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
CreateSummaries3 (PapyShort inFileNb)
{
  PapyShort	theErr;
  
  
  /* make the link to the memory representation of the file */
  gPatientSummaryItem [inFileNb] = gArrMemFile [inFileNb]->next;
  
  /* creation of the summaries */
  if ((theErr = CreatePatientSummary3 (inFileNb)) < 0) RETURN (theErr);
  if ((theErr = CreateStudySummary3   (inFileNb)) < 0) RETURN (theErr);
  if ((theErr = CreateSeriesSummary3  (inFileNb)) < 0) RETURN (theErr);
  
  RETURN (0);
  
} /* endof CreateSummaries3 */



/********************************************************************************/
/*										*/
/*	LookForGroupsInModule3 : Scan a module for its list of groups. Compares	*/
/* 	the found groups with the list of existing groups (if any) and build 	*/
/*	the list of groups to create or read (list that is returned).		*/
/*										*/
/********************************************************************************/

void
LookForGroupsInModule3 (pModule *inModuleP, int inModuleID, 
		        int *inDSGroupsTotP, int *inGrToCreateP)
{
  int		*theTmpCrP, *theTmpTotP, i;
  int		theEnumGrNb;
  pModule	*theElemP;
  
  
  theElemP = inModuleP;
  theTmpCrP = inGrToCreateP;
  
  /* initialize the array of groups to create to empty */
  for (i = 0; i < END_GROUP; i++) theTmpCrP [i] = 0;
  
  /* test to see wether there is a list of existing groups or not */
  if (inDSGroupsTotP != NULL)
  {
    theTmpTotP = inDSGroupsTotP;
    for (i = 0; i < gArrModule [inModuleID]; i++)
    {
      theEnumGrNb = Papy3ToEnumGroup (theElemP->group);
    
      /* if this group is not already in the array put it in the to create list */
      if (*(theTmpTotP + theEnumGrNb) == 0) 
      {
        *(theTmpCrP  + theEnumGrNb) = 1;
        *(theTmpTotP + theEnumGrNb) = 1;
      } /* if */
    
      /* next element of the module */
      theElemP++;
    } /* for ...loop on the elements of the module */
  
  } /* if ...existing list of read groups */
  else /* no list just add the groups found to the list */
  {
    for (i = 0; i < gArrModule [inModuleID]; i++)
    {
      theEnumGrNb = Papy3ToEnumGroup (theElemP->group);
    
      /* put the group in the to read list */
      if (theTmpCrP [theEnumGrNb] == 0)
        theTmpCrP [theEnumGrNb] = 1;
    
      /* next element of the module */
      theElemP++;
    } /* for ...loop on the elements of the module */
  } /* else */
  
} /* endof LookForGroupsInModule3 */



/********************************************************************************/
/*										*/
/*	SequencesToGroups3 : Convert the list of items of the sequence to a list*/
/*	of a list of groups. If the toDel param is set to TRUE, deletes the 	*/
/*	modules in the list too.						*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
SequencesToGroups3 (PapyShort inFileNb, Item *inSequenceP, int inToDel)
{
  Item		*theWrkItemListP;
  PapyShort	theErr;
  

  /* loop on the items of the sequence */
  theWrkItemListP = inSequenceP;
  while (theWrkItemListP != NULL)
  {
    switch (theWrkItemListP->object->whoAmI)
    {
      case papModule:
        /* translate the content of the data set to a list of groups */
        if ((theErr = ItemModulesToGroups3 (inFileNb, theWrkItemListP, inToDel)) < 0)
          RETURN (theErr);
        break;

      case papRecord:
        /* translate the content of the data set to a list of groups */
        if ((theErr = ItemRecordsToGroups3 (inFileNb, theWrkItemListP, inToDel)) < 0)
        break;

      case papItem:
      /*  if (theWrkItemListP->object->item != NULL)
        {*/
          switch (theWrkItemListP->object->item->object->whoAmI)
          {
            case papRecord:
              /* translate the content of the data set to a list of groups */
              if ((theErr = ItemRecordsToGroups3 (inFileNb, theWrkItemListP, inToDel)) < 0)
              break;

            default :
              SequencesToGroups3 (inFileNb, theWrkItemListP->object->item, inToDel);
              break;
          } /* switch ...theWrkItemListP->object->item->object->whoAmI */
   /*     }*/
        break;
        
      default:
        break;
    } /* switch (theWrkItemListP->object->whoAmI) */

    /* get next item of the sequence */
    theWrkItemListP = theWrkItemListP->next;
    
  } /* while ...loop on the items of the sequence */

  return 0;
   
} /* endof SequencesToGroups3 */



/********************************************************************************/
/*										*/
/*	KeepReferences3 : Keep some references to elements that will be needed  */
/* 	by the modules of the pointer sequence.					*/
/*										*/
/********************************************************************************/

void
KeepReferences3 (PapyShort inFileNb, int inModuleID, int inElementID, UValue_T *inValP)
{
  
  
  switch (inModuleID)
  {
    case SOPCommon :
      if (inElementID == papSOPClassUID) 
        /* it is the same SOP class UID for the whole file */
        if (gRefSOPClassUID [inFileNb] == NULL)
          gRefSOPClassUID [inFileNb] = PapyStrDup (inValP->a);
          
      if (inElementID == papSOPInstanceUID)
        gRefSOPInstanceUID = PapyStrDup (inValP->a);
            
      break;
     case GeneralImage : /* papInstanceNumber was papImageNumberGI before */
       if (inElementID == papInstanceNumberGI) gRefImageNb = PapyStrDup (inValP->a);
       break;
     case ImagePixel :
       switch (inElementID)
       {
          case papRows :
            gRefRows = inValP->us;
            break;
          case papColumns :
            gRefColumns = inValP->us;
            break;
          case papBitsAllocatedIP :
            gRefBitsAllocated = inValP->us;
            break;
          case papBitsStoredIP :
            gRefBitsStored = inValP->us;
            break;
          case papHighBitIP :
            gRefHighBit = inValP->us;
            break;
          case papPixelRepresentationIP :
            gRefIsSigned = inValP->us;
            break;
          case papSmallestImagePixelValue :
            gRefPixMin = inValP->us;
            break;
          case papLargestImagePixelValue :
            gRefPixMax = inValP->us;
            break;
          case papPixelData :   
            gRefPixelData = inValP->ow;
            break;
        } /* switch ...elems of image pixel module */
        break;
     case VOILUT :
       switch (inElementID)
       {
         case papWindowWidth :
           gRefWW = atoi (inValP->a);
           break;
         case papWindowCenter :
           gRefWL = atoi (inValP->a);
           break;
       } /* switch ...elems of VOILUT module */
       break;
            
  } /* switch ...module ID */
  
} /* endof KeepReferences3 */


/********************************************************************************/
/*										*/
/*	Papy3CheckDirectoryInformation : 					*/
/*	return : 								*/
/*										*/
/********************************************************************************/

void 
Papy3CheckDirectoryInformation (pModule *inModuleP)
{
  PapyULong   theLongValue;
  PapyUShort  theShortValue;

  
  /* initialize */
  theLongValue  = 0L;
  theShortValue = 0;

  /* 0004:1200 */
  Papy3PutElement (inModuleP, papOffsetofTheFirstDirectoryRecord, &theLongValue);
  /* 0004:1202 */
  Papy3PutElement (inModuleP, papOffsetofTheLastDirectoryRecord, &theLongValue);
  /* 0004:1212 */
  Papy3PutElement (inModuleP, papFilesetConsistencyFlag, &theShortValue);
  /* 0004:1220 */
  /*Papy3PutElement (inModuleP, papDirectoryRecordSequence, &theLongValue);*/

} /* endof Papy3CheckDirectoryInformation */


/********************************************************************************/
/*										*/
/*	ItemModulesToGroups3 : Convert the list of modules of the Item to 	*/
/*	a list of groups. If the toDel param is set to TRUE, deletes the 	*/
/*	modules too.								*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
ItemModulesToGroups3 (PapyShort inFileNb, Item *ioDataSetP, int inToDel)
{
  int		*theDSGroupsTotP, *theGrToCreateP, *theTmpP;
  int		i, theEnumGr, theEnumTag, found, theElemType;
  UValue_T	*theValP, *theTmpValP;
  pModule	*theWrkModP;
  SElement	*theGroupP;
  papObject	*theObjectP;
  Item		*theWrkItemMP, *theGroupListP, *theWrkItemGP;
  PapyShort	theErr, theNbOfModuleElem;
  PapyUShort	theElemTag;
  PapyULong	theNbVal, theLoop;
  
  
  /* initialize the lists of groups contained in the data set to empty */
  theDSGroupsTotP = (int *) ecalloc3 ((PapyULong) END_GROUP, (PapyULong) sizeof (int));
  theGrToCreateP  = (int *) ecalloc3 ((PapyULong) END_GROUP, (PapyULong) sizeof (int));
  for (i = 0, theTmpP = theDSGroupsTotP; i < END_GROUP; i++, theTmpP++) *theTmpP = 0;
  
  /* perform some pointer initialization */
  theWrkItemMP = (Item *) ioDataSetP->object->item;	/* points on the first module */
  theGroupListP = NULL;					/* make sure it is blank */
  
  /* loop on the modules of the data set */
  while (theWrkItemMP != NULL)
  {
    /* if it is a module */
    if (theWrkItemMP->object->whoAmI == papModule)
    {
      /* Fill Directory Information module */
      if (theWrkItemMP->object->objID == DirectoryInformation)
          Papy3CheckDirectoryInformation (theWrkItemMP->object->module);

      /* find the groups to create from the description of the module */
      LookForGroupsInModule3 (theWrkItemMP->object->module, theWrkItemMP->object->objID,
      			      theDSGroupsTotP, theGrToCreateP);
    
      /* creation of the needed groups */
      for (i = 0; i < END_GROUP; i++)
      {
        /* do we have to add the group to the list of groups of the data set */
        if (*(theGrToCreateP + i) == 1)
        {
          /* creation of the group */
          theGroupP = Papy3GroupCreate (i);
        
          /* creation of the object to point to the group */
          theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
          theObjectP->whoAmI        = papGroup;
          theObjectP->objID         = i;
          theObjectP->group         = theGroupP;	/* link the group to the object */
  	      theObjectP->item          = NULL;
  	      theObjectP->module        = NULL;
  	      theObjectP->tmpFileLength = 0L;
        
          /* insert the object at its place in the list of groups of the data set */
          theWrkItemGP = InsertGroupInList ((Item **) &theGroupListP, theObjectP);
         
        } /* if ...add the group to the list of groups of the data set */
      } /* for ...loop on the array of groups */
    
      
      /* copy the elements of the module to the groups */
      theNbOfModuleElem = gArrModule [theWrkItemMP->object->objID];
      for (i = 0; i < theNbOfModuleElem; i++)
      {
        /* get the element from the module */
        theValP = Papy3GetElement (theWrkItemMP->object->module, i, &theNbVal, &theElemType);
      
        if (theValP != NULL)
        {
          /* Keep references to some elements to create the pointer sequence */
          KeepReferences3 (inFileNb, theWrkItemMP->object->objID, i, theValP);
        
          /* extract the group number to put the element to */
          theWrkModP = (pModule *) (theWrkItemMP->object->module + i);
          theEnumGr  = Papy3ToEnumGroup (theWrkModP->group);
          theElemTag = theWrkModP->element;

          /* locate the group to which to put the element in the group list */
          found = FALSE;
          theWrkItemGP = theGroupListP;
          while (!found && theWrkItemGP != NULL)
            if (theWrkItemGP->object->objID == theEnumGr) found = TRUE;
            else theWrkItemGP = theWrkItemGP->next;
      
          /* locate the enum place of the element given its tag */
          theGroupP = theWrkItemGP->object->group;
          found = FALSE;
          theEnumTag = 0;
          while (!found)
            if (theGroupP->element == theElemTag) found = TRUE;
            else
            {
              theEnumTag++;
              theGroupP++;
            } /* else */
          
          /* put the value(s) to the group */
          theTmpValP = theValP;
          for (theLoop = 0L; theLoop < theNbVal; theLoop++)
          {
          
            /* depending on the VR of the element put it to the group */
            switch (theWrkModP->vr)
            {
              case SS :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->ss)); 
                break;
              case USS :
              case AT :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->us)); 
                break;
              case OB :
                Papy3PutImage (inFileNb, theWrkItemGP->object->group, theEnumTag, 
            		       (PapyUShort *) theTmpValP->a, 0, 0, 8, theWrkModP->length);
                break;
              case OW :
                Papy3PutImage (inFileNb, theWrkItemGP->object->group, theEnumTag, theTmpValP->ow,
            		       0, 0, 16, theWrkModP->length);
                break;
              case SL :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->sl)); 
                break;
              case UL :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->ul)); 
                break;
              case FL :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->fl)); 
                break;
              case FD :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->fd)); 
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
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->a)); 
                break;
              case UN :
		            Papy3PutUnknown (theWrkItemGP->object->group, theEnumTag, theTmpValP->a, theWrkModP->length);
		            break;
              case SQ :
                /* convert the list of items of the sequence to a list of groups */
                if ((theErr = SequencesToGroups3 (inFileNb, theTmpValP->sq, inToDel)) < 0) RETURN (theErr);
            
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->sq)); 
                break;
            } /* switch */
            
            theTmpValP++;
          
          } /* for ...loop on the value(s) of an element */
      
        } /* if ...theValP != NULL */
 
      } /* for ...loop on the elements of the module */
      
  
    } /* if ...it is a module */
    
    
    /* if it is a group insert it at its place in the list */
    /* nota : this is done to allow for UIN Overlays to be in the data set */
    else if (theWrkItemMP->object->whoAmI == papGroup)
    {
      /* creation of the object to point to the group */
      theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
      theObjectP->whoAmI = papGroup;
      theObjectP->objID  = theWrkItemMP->object->objID;
      theObjectP->group  = theWrkItemMP->object->group;	/* link the group to the object */
      theObjectP->item   = NULL;
      theObjectP->module = NULL;
      theObjectP->tmpFileLength = 0L;
        
       
      /* insert the object at its place in the list of groups of the data set */
      theWrkItemGP = InsertGroupInList ((Item **) &theGroupListP, theObjectP);
    
    } /* else ...it is a group */
    
    /* examine next module (or group) */
    theWrkItemMP = theWrkItemMP->next;
    
  } /* while ...loop on the modules of the data set */
  

  /* delete the lists of groups number of the data set */
  efree3 ((void **) &theDSGroupsTotP);
  efree3 ((void **) &theGrToCreateP);
  
  /* deletes the list of modules and put the list of groups instead */
  /* deletes the groups but not the sequences */
  if ((theErr = DeleteList (inFileNb, (Papy_List **) &(ioDataSetP->object->item), inToDel, FALSE, FALSE)) < 0)
    RETURN (theErr);
  ioDataSetP->object->item = theGroupListP;

  return 0;
  
} /* endof ItemModulesToGroups3 */


/********************************************************************************/
/*										*/
/*	ItemRecordsToGroups3 : Convert the list of records of the Item to 	*/
/*	a list of groups. If the toDel param is set to TRUE, deletes the 	*/
/*	record too.								*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
ItemRecordsToGroups3 (PapyShort inFileNb, Item *ioDataSetP, int inToDel)
{
  int		*theDSGroupsTotP, *theGrToCreateP, *theTmpP;
  int		i, j, theEnumGr, theEnumTag, found, theElemType;
  UValue_T	*theValP, *theTmpValP;
  SElement	*theWrkModP;
  SElement	*theGroupP;
  papObject	*theObjectP;
  Item		*theWrkItemMP, *theGroupListP, *theWrkItemGP;
  PapyShort	theErr, theNbOfRecordElem;
  PapyUShort	theElemTag;
  PapyULong	theNbVal, theLoop, theNbRecordGroups, theNbTotGroups;
		
  
  /* initialize the lists of groups contained in the data set to empty */
  theDSGroupsTotP = (int *) ecalloc3 ((PapyULong) END_GROUP, (PapyULong) sizeof (int));
  theGrToCreateP  = (int *) ecalloc3 ((PapyULong) END_GROUP, (PapyULong) sizeof (int));
  for (i = 0, theTmpP = theDSGroupsTotP; i < END_GROUP; i++, theTmpP++) *theTmpP = 0;
  
  /* perform some pointer initialization */
  theWrkItemMP  = (Item *) ioDataSetP->object->item;	/* points on the first record */
  theGroupListP = NULL;			/* make sure it is blank */

  /* count the number of groups for each records */
  theNbRecordGroups = 0L;
  theNbTotGroups    = 0L;

  /* loop on the records or groups of the data set */
  while (theWrkItemMP != NULL)
  {
    /* get item which contain the record
    /* if it is a record */
    if (theWrkItemMP->object->whoAmI == papRecord)
    {
      theNbRecordGroups = 0;
        
      /* find the groups to create from the description of the record */
      LookForGroupsInRecord3 (theWrkItemMP->object->record, theWrkItemMP->object->objID, theGrToCreateP);
      
      /* creation of the needed groups */
      for (i = 0; i < END_GROUP; i++)
      {
        /* do we have to add the group to the list of groups of the data set */
        if (*(theGrToCreateP + i) == 1)
        {	  
          /* creation of the group */
          theGroupP = Papy3GroupCreate (i);

          /* creation of the object to point to the group */
          theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
          theObjectP->whoAmI        = papGroup;
          theObjectP->objID         = i;
          theObjectP->group         = theGroupP;	/* link the group to the object */
          theObjectP->item          = NULL;
          theObjectP->record        = NULL;
          theObjectP->module        = NULL;
          theObjectP->tmpFileLength = 0L;
        
          /* insert the object at its place in the list of groups of the data set */
          theWrkItemGP = InsertLastInList ((Item **) &theGroupListP, theObjectP);
          
          /* only useful for records sequence */
          theNbRecordGroups++;

        } /* if ...add the group to the list of groups of the data set */
      } /* for ...loop on the array of groups */
      
      /* copy the elements of the record to the groups */
      theNbOfRecordElem = gArrRecord [theWrkItemMP->object->objID];
      for (i = 0; i < theNbOfRecordElem; i++)
      {
        /* get the element from the record */
        theValP = Papy3GetElement (theWrkItemMP->object->record, i, &theNbVal, &theElemType);
      
        if (theValP != NULL)
        {
          /* Keep references to some elements to create the pointer sequence */
          KeepReferences3 (inFileNb, theWrkItemMP->object->objID, i, theValP);
        
          /* extract the group number to put the element to */
          theWrkModP = (SElement *) (theWrkItemMP->object->record + i);
          theEnumGr  = Papy3ToEnumGroup (theWrkModP->group);
          theElemTag = theWrkModP->element;

          /* locate the group to which to put the element in the group list */
          found        = FALSE;
          theWrkItemGP = theGroupListP;
          
          /* found the just created groups */
          for (j = 0; j < (int) theNbTotGroups; j++) 
              theWrkItemGP = theWrkItemGP->next;
      
          while (!found && theWrkItemGP != NULL)
            if (theWrkItemGP->object->objID == theEnumGr) 
              found = TRUE;
            else 
              theWrkItemGP = theWrkItemGP->next;
      
          /* locate the enum place of the element given its tag */
          theGroupP  = theWrkItemGP->object->group;
          found      = FALSE;
          theEnumTag = 0;
          while (!found)
            if (theGroupP->element == theElemTag) 
              found = TRUE;
            else
            {
              theEnumTag++;
              theGroupP++;
            } /* else */
          
          /* put the value(s) to the group */
          theTmpValP = theValP;
          for (theLoop = 0L; theLoop < theNbVal; theLoop++)
          {
            /* depending on the VR of the element put it to the group */
            switch (theWrkModP->vr)
            {
              case SS :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->ss)); 
                break;
              case USS :
              case AT :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->us)); 
                break;
	            case OB :
                Papy3PutImage (inFileNb, theWrkItemGP->object->group, theEnumTag, 
            		       (PapyUShort *) theTmpValP->a, 0, 0, 8, theWrkModP->length);
                break;
              case OW :
                Papy3PutImage (inFileNb, theWrkItemGP->object->group, theEnumTag, theTmpValP->ow,
            		       0, 0, 16, theWrkModP->length);
                break;
              case SL :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->sl)); 
                break;
              case UL :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->ul)); 
                break;
              case FL :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->fl)); 
                break;
              case FD :
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->fd)); 
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
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->a)); 
                break;
              case SQ :
                /* convert the list of items of the sequence to a list of groups */
                if ((theErr = SequencesToGroups3 (inFileNb, theTmpValP->sq, inToDel)) < 0)
                  RETURN (theErr);
                Papy3PutElement (theWrkItemGP->object->group, theEnumTag, &(theTmpValP->sq));                	
                break;
            } /* switch */
            
            theTmpValP++;
          
          } /* for ...loop on the value(s) of an element */
      
        } /* if ...theValP != NULL */
 
      } /* for ...loop on the elements of the module */
      
  
    } /* if ...it is a record */
    
    
    /* if it is a group insert it at its place in the list */
    else    
      
    if (theWrkItemMP->object->whoAmI == papGroup)
    {
      /* creation of the object to point to the group */
      theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
      theObjectP->whoAmI 	= papGroup;
      theObjectP->objID  	= theWrkItemMP->object->objID;
      theObjectP->group  	= theWrkItemMP->object->group;/* link the group to the object */
      theObjectP->item   	= NULL;
      theObjectP->module 	= NULL;
      theObjectP->record 	= NULL;
      theObjectP->tmpFileLength = 0L;
        
       
      /* insert the object at its place in the list of groups of the data set */
      theWrkItemGP = InsertGroupInList ((Item **) &theGroupListP, theObjectP);
    
    } /* else ...it is a group */
    
    /* only useful for record sequence */
    theNbTotGroups += theNbRecordGroups;
    
    /* examine next record */
    theWrkItemMP = theWrkItemMP->next;
    
  } /* while ...loop on the modules of the data set */
  

  /* delete the lists of groups number of the data set */
  efree3 ((void **) &theDSGroupsTotP);
  efree3 ((void **) &theGrToCreateP);
  
  /* deletes the list of records and put the list of groups instead */
  /* deletes the groups but not the sequences */
  if ((theErr = DeleteList (inFileNb, (Papy_List **) &(ioDataSetP->object->item), inToDel, FALSE, FALSE)) < 0)
    RETURN (theErr);
  ioDataSetP->object->item = theGroupListP;
  
  return 0;
  
} /* endof ItemRecordsToGroups3 */



/********************************************************************************/
/*										*/
/*	CreateTmpFile3 : Creates and open a temporary file to store the groups	*/
/*	of a data set. 								*/
/*	return : a pointer to an object containing the tmp file, NULL otherwise	*/
/*										*/
/********************************************************************************/

PapyShort
CreateTmpFile3 (PapyShort inFileNb, PAPY_FILE *ioFpP, void **ioVoidP)
{
  char		*theFilenameP, theChar [256], theOtherStr [10];
  int		theLength;
  PapyShort	theErr;
  
  
  /* create the name of the temporary file */
  /* i.e. takes the name of the file and concatenate an incremental number */
  theFilenameP = (char *) &theChar [0];
  strcpy (theFilenameP, gPapFilename [inFileNb]);
  
  /* DICOM file case & first image of the data set*/
  if ((gIsPapyFile [inFileNb] == DICOM10 || gIsPapyFile [inFileNb] == DICOM_NOT10) &&
      gCurrTmpFilename [inFileNb] == 1)
  {
    /* try to open the file */
    theErr = Papy3FOpen (theFilenameP, 'w', (PAPY_FILE) 0, ioFpP, ioVoidP);
    switch (theErr)
    {
      case -49:	/* file was already open in write mode */
        /* in this case the file pointer is simply the original one ... */
        *ioFpP = gPapyFile [inFileNb];

      case 0:	/* was able to open the file in write mode */
        /* increment this to ensure uniqueness of temporary files */
        gCurrTmpFilename [inFileNb]++;
    
        /* remove the "0001.dcm" string from the filename if present */
        theLength = (int) strlen (theFilenameP);
        if (theFilenameP [theLength - 8] == '0' &&
    	    theFilenameP [theLength - 7] == '0' &&
    	    theFilenameP [theLength - 6] == '0' &&
    	    theFilenameP [theLength - 5] == '1' &&
    	    theFilenameP [theLength - 4] == '.' &&
    	    theFilenameP [theLength - 3] == 'd' &&
    	    theFilenameP [theLength - 2] == 'c' &&
    	    theFilenameP [theLength - 1] == 'm')
        {
          theFilenameP [theLength - 8] = '\0';
          strcpy (gPapFilename [inFileNb], theFilenameP);
        } /* if ...string ends by "0001.dcm" */
        
        /* makes sure the file pointer is set correctly */
        gPapyFile [inFileNb] = *ioFpP;
        
        /* then exits successfully the function */
        return 0;
        break;

      default:	/* file does not exist */
        break;
    } /* switch */
      
  } /* if ... DICOM file */
  
  /* append the incremental number to the filename */
  Papy3FPrint (theOtherStr, "%d", gCurrTmpFilename [inFileNb]);
  strcat (theOtherStr, ".dcm");
  strcat (theOtherStr, "\0");
  if (gCurrTmpFilename [inFileNb]      < 10)
    strcat (theFilenameP, "000");
  else if (gCurrTmpFilename [inFileNb] < 100)
    strcat (theFilenameP, "00");
  else if (gCurrTmpFilename [inFileNb] < 1000)
    strcat (theFilenameP, "0");
  strcat (theFilenameP, theOtherStr);
  
  /* increment the number to ensure uniqueness of tmp filenames */
  gCurrTmpFilename [inFileNb]++;
  
  /* creation of the temporary file */
  while (Papy3FCreate (theFilenameP, (PAPY_FILE) -1, ioFpP, ioVoidP) < 0 &&
  	 gCurrTmpFilename [inFileNb] < kMax_tmp_file) 
  {
    /* free the memory if some was allocated */
    /*if (*ioVoidP != NULL)
        efree3 ((void **) ioVoidP);*/
    
    /* re-create the name of the temporary file */
    Papy3FPrint (theOtherStr, "%d", gCurrTmpFilename [inFileNb]);
    strcat (theOtherStr, ".dcm");
    strcat (theOtherStr, "\0");
    strcpy (theFilenameP, gPapFilename [inFileNb]);
    if (gCurrTmpFilename [inFileNb]      < 10)
      strcat (theFilenameP, "000");
    else if (gCurrTmpFilename [inFileNb] < 100)
      strcat (theFilenameP, "00");
    else if (gCurrTmpFilename [inFileNb] < 1000)
      strcat (theFilenameP, "0");
    strcat (theFilenameP, theOtherStr);
      
    /* re-increment the number to ensure uniqueness of tmp filenames */
    gCurrTmpFilename [inFileNb]++;
    
  } /* while ...looking for a temp file to create */

  /* the file creation failed */
  if (gCurrTmpFilename [inFileNb] == kMax_tmp_file)
  {
    /*if (*ioVoidP != NULL)
        efree3 ((void **) ioVoidP); */
    RETURN (papFileCreationFailed);
  } /* if ...file creation failed */
   
  /* open the created tmp file */
  if (Papy3FOpen (theFilenameP, 'w', (PAPY_FILE) 0, ioFpP, ioVoidP) < 0)
  {
    /*if (*ioVoidP != NULL)
        efree3 ((void **) ioVoidP);*/
    RETURN (papFileCreationFailed);
  } /* if ...opening the file failed */
  
  /* this is to mark the DICOM file as being in use for the skeleton */
  if ((gIsPapyFile [inFileNb] == DICOM10 || gIsPapyFile [inFileNb] == DICOM_NOT10) &&
      gPapyFile [inFileNb] == 0)
    gPapyFile [inFileNb] = *ioFpP;
  
  return 0;

} /* endof CreateTmpFile3 */



/********************************************************************************/
/*										*/
/*	WriteDicomHeader3 : Writes the DICOM header at the begining of the tmp	*/
/*	file (i.e. 128 bytes set to blank followed by the DICM string) as well 	*/
/* 	as the group 0x0002 which contains the file meta information 		*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort
WriteDicomHeader3 (PAPY_FILE inFp, PapyShort inFileNb, PapyULong *outMetaInfoSizeP)
{
  PapyShort	theErr = 0;
  PapyULong	theNumberOfBytes;
  char		theBuff [128];
  int		i;
  
  
  /* set 128 bytes to blank */
  for (i = 0; i < 128; i++) theBuff [i] = 0;
  theNumberOfBytes = 128L;
  
  /* write them to the file */
  if (Papy3FWrite (inFp, (PapyULong *) &theNumberOfBytes, 1, theBuff) < 0)
  {
    Papy3FClose (&inFp);
    RETURN (papWriteFile)
  } /* if */
  
  /* then put the DICM string that identifies the file as a DICOM one */
  strcpy (theBuff, "DICM");
  theNumberOfBytes = 4L;
  
  /* write the string to the file */
  if (Papy3FWrite (inFp, (PapyULong *) &theNumberOfBytes, 1, theBuff) < 0)
  {
    Papy3FClose (&inFp);
    RETURN (papWriteFile)
  } /* if */
  
  /* creation and writting of the file meta information (i.e. group 0x0002) */
  theErr = CreateDicomFileMetaInformation3 (inFp, inFileNb, gArrCompression [inFileNb], gArrTransfSyntax [inFileNb], 
  					    (enum EModality) gFileModality [inFileNb], outMetaInfoSizeP);

  return theErr;
  
} /* endof WriteDicomHeader3 */



/********************************************************************************/
/*										*/
/*	WriteTmpFile3 : Creates a temporary file to store the groups of a given	*/
/*	data set. It will save as well some relativ positions in the file.	*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort
WriteTmpFile3 (PapyShort inFileNb, Item *ioDataSetP, int inToDel)
{
  int		theGroupNb;
  PapyShort	theErr, theImNb;
  PAPY_FILE	theFp;
  PapyULong	theBufSize, theMetaInfoSize, thePos, theTmpUL;
  unsigned char *theBuffP;
  Item		*theWrkItemP;
  void		*theVoidP;
  
  
  theVoidP     	  = NULL;
  theMetaInfoSize = 0L;
  theFp	       	  = (PAPY_FILE) NULLFILE;

  /* create the temporary file that will contain the given data set */
  if ((theErr = CreateTmpFile3 (inFileNb, &theFp, &theVoidP)) < 0)
    RETURN (papFileCreationFailed);
  
  /* if the file is a DICOM one, then put the DICOM header to the temp file */
  /* in order to get a real DICOM file part 10 compliant */
  if (gIsPapyFile [inFileNb] == DICOM10)
    theErr = WriteDicomHeader3 (theFp, inFileNb, &theMetaInfoSize);
  
  /* find the place of the data set in the list of data sets */
  theImNb = 0;
  theWrkItemP = gImageSequenceItem [inFileNb];
  while (theWrkItemP != ioDataSetP && theWrkItemP != NULL)
  {
    theImNb++;
    theWrkItemP = theWrkItemP->next;
  } /* while ...loop on the data sets */

  /* initialisation */
  gCurrentOverlay    [inFileNb] = 0x6000;
  gCurrentUINOverlay [inFileNb] = 0x6001;
  
  /* take a pointer to the first group of the data set */
  theWrkItemP = (Item *) ioDataSetP->object->item;  
  
  /* loop on the groups of the data set */
  while (theWrkItemP != NULL)
  {
    if ((theGroupNb = Papy3ToEnumGroup (theWrkItemP->object->group->group)) < 0)
	RETURN (papGroupNumber);

    /* compute the size of the current group */
    ComputeGroupLength3 ((PapyShort) theGroupNb, theWrkItemP->object->group, NULL, 
			 gArrTransfSyntax [inFileNb]);
    theBufSize = theWrkItemP->object->group->value->ul + kLength_length;
    
    /* alloc the buffer that will contain the ready to write group */
    theBuffP = (unsigned char *) emalloc3 ((PapyULong) theBufSize);
    
    thePos = 0L;    
    /* put the elements of the group to the write buffer */
    if ((theErr = PutGroupInBuffer (inFileNb, theImNb, theGroupNb, theWrkItemP->object->group, 
    				    theBuffP, &thePos, FALSE)) < 0) RETURN (theErr);
    
    /* add the offsets to the data set to the offset to the group */
    if (theWrkItemP->object->group->group == 0x7FE0)
    {
      Papy3FTell (theFp, (PapyLong *) &theTmpUL);
      *(gRefPixelOffset  [inFileNb] + theImNb) += theTmpUL;
    } /* if */
    
    /* write the buffer to the temporary file */
    if ((theErr = WriteGroup3 (theFp, theBuffP, theBufSize)) < 0)
      RETURN (theErr);  
    
    /* frees the allocated buffer */
    efree3 ((void **) &theBuffP);
    
    /* get next item */
    theWrkItemP = theWrkItemP->next;
    
  } /* while ...loop on the groups of the data set */
  
  /* deletes the list of groups of the data set and put the tmp file instead */
  if ((theErr = DeleteList (inFileNb, (Papy_List **) &(ioDataSetP->object->item), inToDel, TRUE, TRUE)) < 0) 
    RETURN (theErr);
  
  ioDataSetP->object->whoAmI  = papTmpFile;
  ioDataSetP->object->objID   = gCurrTmpFilename [inFileNb] - 1;
  ioDataSetP->object->file    = theVoidP;
  
  /* stores the length of the tmp file */
  if (Papy3FSeek (theFp, (int) SEEK_END, (PapyLong) 0L) != 0)
    RETURN (papPositioning);
  Papy3FTell (theFp, (PapyLong *) &(ioDataSetP->object->tmpFileLength));

  
  /* close the temporary file */
  Papy3FClose (&theFp);
  
  return 0;

} /* endof WriteTmpFile3 */



/********************************************************************************/
/*										*/
/*	Papy3CloseDataSet : Close the given data set. If it is the first data 	*/
/*	set to be closed, it builds the summaries modules from the data set.It 	*/
/*	translates the modules into a group representation, frees the modules 	*/
/*	if the toDel param is set to TRUE. Then it saves the list of groups on 	*/
/*	a temporary file that is ready to be copied in the definitiv Papyrus 	*/
/*	file.									*/
/*	return : papNoError if no problem, standard error message otherwise.	*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3CloseDataSet (PapyShort inFileNb, Item *inDataSetP, int inToDel, int inPerformCheck)
{
  PapyShort	theErr;
  
  
  /* introduce some odd value to be tested */
  gRefPixMin =  0;
  gRefPixMax =  0;
  gRefWW     = -1;
  gRefWL     = -1;
  
  /* check if all the needed modules have been filled only if specified */
  if (inPerformCheck)
    if ((theErr = CheckDataSetModules3 (inFileNb, inDataSetP)) < 0) RETURN (theErr);

  /* perform the following task only if it is a PAPYRUS file */
  if (gIsPapyFile [inFileNb] == PAPYRUS3)
  {
    /* if it is the first data set to be saved, create the summaries modules */
    if (gPatientSummaryItem [inFileNb] == NULL) 
      if ((theErr = CreateSummaries3 (inFileNb)) < 0) RETURN (theErr);
  } /* if ...it is a PAPYRUS file */
  
  /* convert the module representation to the group representation */
  if ((theErr = ItemModulesToGroups3 (inFileNb, inDataSetP, inToDel)) < 0)
    RETURN (theErr);
  
  /* perform the following task only if it is a PAPYRUS file */
  if (gIsPapyFile [inFileNb] == PAPYRUS3)
  {  
    /* creation of the pointer sequence for this data set */
    theErr = CreatePointerSequence3 (inFileNb, inDataSetP);
  } /* if ...it is a PAPYRUS file */
  
  /* write the data set to a temporary file */
  if ((theErr = WriteTmpFile3 (inFileNb, inDataSetP, inToDel)) < 0) RETURN (theErr);  
  
  RETURN (theErr);
  
} /* endof Papy3CloseDataSet */
