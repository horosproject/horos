/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit (DicomDir library)			*/
/*	File     : DicomDirFiles3.c						*/
/*	Function : contains all the file functions	               		*/
/********************************************************************************/

/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <memory.h>

#ifndef DicomdirH 
#include "DicomDir.h"
#endif


#ifdef _WINDOWS
#include <io.h>
#endif



enum {kPAPY_READ, kPAPY_WRITE};		/* are we in read or write mode ? */


/********************************************************************************/
/*									 	*/
/*	Papy3DicomDirCreate : given a filename check if this file does not	*/
/*	exist and creates a new file. It has to put the file Meta Info as well 	*/
/*	as the DICM prefix to identify the file. It has to initialize the 	*/
/*	variables necessary to store the different offsets. It has to create	*/
/* 	the file structure in memory (list).					*/
/*	return : a reference number to the opened file if successful		*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3DicomDirCreate (char *inNameP, int inNbFiles, PAPY_FILE inVRefNum, int inToCreate, void *MacFileSpec)
{
    PapyULong	theNumberOfBytes;
    int		i, thePapyrusFile = 0;
    PapyShort	theFileNb, theErr;
    PAPY_FILE	theFp;
    char	theBuff [134];
    void 	*theFSSpecP;
    char	theFilename [256];
    
    
/* -------- validity tests -------- */

    /* we have to have a file */
    if (inNbFiles == 0) RETURN (papNbImagesIsZero);

    /* no valid filename specified */
    if (inToCreate && (inNameP == NULL || *inNameP == '\0')) RETURN (papFileName);

    /* is it a DICOMDIR file? */
    ExtractDicomdirFromPath (inNameP, theFilename);
      if (theFilename [0] != '\0' &&
          ((strcmp ((char*) theFilename, "DICOMDIR.") == 0) ||
           (strcmp ((char*) theFilename, "dicomdir.") == 0) ||
           (strcmp ((char*) theFilename, "dicomdir" ) == 0) ||
           (strcmp ((char*) theFilename, "DICOMDIR" ) == 0)))
      thePapyrusFile = 3;

    if (thePapyrusFile != 3) RETURN (papFileName);
    
/* -------- creating and opening the file -------- */
     
    /* look for a valid file number */
    theFileNb = FindFreeFile3 ();
    /* 1 = PAPYRUS 3.X, 3 = DICOMDIR */
    gIsPapyFile [theFileNb] = (enum EFile_Type) thePapyrusFile;

    /* too many open files */
    if (theFileNb < 0) RETURN (theFileNb);
    
    if (inToCreate)
    {
      theFSSpecP = MacFileSpec;
      
      if ((theErr = Papy3FCreate (inNameP, inVRefNum, &theFp, &theFSSpecP)) != 0)
        RETURN (papFileAlreadyExist);
    
      if ((theErr = Papy3FOpen (inNameP, 'w', inVRefNum, &theFp, &theFSSpecP)) != 0)
        RETURN (papFileCreationFailed);
      
      if ((theFSSpecP != NULL) && (MacFileSpec == NULL)) efree3 ((void **) &theFSSpecP); //
      // BLOT ADD: if (theFSSpecP != NULL) efree3 ((void **) &theFSSpecP);
    } /* if ...inToCreate */
    else theFp = inVRefNum;
    
    /* assign the file to the array of files */
    gPapyFile [theFileNb] = theFp;

/* -------- file meta information -------- */

    /* Put the DICOM File Meta Information in the file */
    /* first put 128 bytes set to 0 */
    for (i = 0; i < 128; i++) theBuff [i] = 0;
    theNumberOfBytes = 128L;
    
    /* writes the bytes to the file */
    if (Papy3FWrite (theFp, (PapyULong *) &theNumberOfBytes, 1, theBuff) < 0)
    {
      theErr = Papy3FClose (&theFp);
      RETURN (papWriteFile)
    } /* if */
    
    /* then put the "DICM" string that will identify the file as a DICOM one */
    strcpy (theBuff, "DICM");
    theNumberOfBytes = (PapyULong) 4L;
    
    /* writes the bytes to the file */
    if (Papy3FWrite (theFp, (PapyULong *) &theNumberOfBytes, 1, theBuff) < 0)
    {
      theErr = Papy3FClose (&theFp);
      RETURN (papWriteFile)
    } /* if */
    
    /* creation of the file meta information and initialization of the memory */
    /* representation of the file structure (list) */
    if ((theErr = CreateFileMetaInformation3 (theFileNb, NONE, LITTLE_ENDIAN_EXPL, SEC_CAPT_IM)) < 0) RETURN (theErr);   
    
/* -------- initializations a la Papyrus 2 -------- */

    /* set the transfert syntax and the compression used for the file */
    gArrTransfSyntax [theFileNb] = LITTLE_ENDIAN_EXPL;
    gArrCompression  [theFileNb] = NONE;
    

    /* allocate room for the offsets to the records */
    gPosNextDirRecordOffset [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) END_RECORD, 
    						       		  (PapyULong) sizeof (PapyULong));
    gRefNextDirRecordOffset [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) END_RECORD,
    						       		  (PapyULong) sizeof (PapyULong));
    gPosLowerLevelDirRecordOffset [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) END_RECORD, 
    						       			(PapyULong) sizeof (PapyULong));
    gRefLowerLevelDirRecordOffset [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) END_RECORD,
    						       			(PapyULong) sizeof (PapyULong));
    /* and initialize  !! */
    for (i = 0; i < END_RECORD; i++)
    {
      *(gPosNextDirRecordOffset [theFileNb] + i)  = 0L;
      *(gRefNextDirRecordOffset [theFileNb] + i)  = 0L;
      *(gPosLowerLevelDirRecordOffset [theFileNb] + i)  = 0L;
      *(gRefLowerLevelDirRecordOffset [theFileNb] + i)  = 0L;
    }

    
    /* the file is in write mode */
    gReadOrWrite [theFileNb] = kPAPY_WRITE;
    

    RETURN (theFileNb);
    
} /* endof Papy3DicomDirCreate */


/********************************************************************************/
/*										*/
/*	Papy3WriteAndCloseDicomDir : writes the whole in memory structure of the*/
/*	given file to the disk. It closes any unclosed data set and saves the 	*/
/* 	references to the data sets and the pixel data. Finally frees some 	*/
/*	memory that is no more needed.						*/
/* 	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3WriteAndCloseDicomDir (PapyShort inFileNb, int inToClose)
{
  PapyShort	theErr;
  Item		*theFileStructP, *theWrkItemP;
  
  
  /* write group 2 (File Meta Information) and free it*/
  if ((theErr = Papy3GroupWrite (inFileNb, (gArrMemFile [inFileNb])->object->group, FALSE)) < 0)
    RETURN (theErr);

  /* convert all the modules and records to groups */
  theFileStructP = gArrMemFile [inFileNb]->next; 
  while (theFileStructP != NULL)
  {
    if ((theErr = ItemModulesToGroups3 (inFileNb, theFileStructP, TRUE)) < 0) 
      RETURN (theErr);
  
    /* write the groups to the Papyrus file */
    theWrkItemP = (Item *) theFileStructP->object->item;
    while (theWrkItemP != NULL)
    {
      /* write the current group to the file and then frees the allocated memory */
      if ((theErr = Papy3GroupWrite (inFileNb, theWrkItemP->object->group, FALSE)) < 0)
        RETURN (theErr);
    
      /* get next element of the list */
      theWrkItemP = theWrkItemP->next;
    
    } /* while ...loop on the groups */   

    /* get next element of the list */
    theFileStructP = theFileStructP->next;
  } /* while ...loop on the datasets */   
  
  
  /* frees the allocated memory */
  Papy3FileClose (inFileNb, inToClose);
    
  RETURN (theErr);
  
} /* endof Papy3WriteAndCloseDicomDir */



