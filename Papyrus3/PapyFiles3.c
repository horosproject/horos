/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyFiles3.c                                                 */
/*	Function : contains all the file functions                              */
/*	Authors  : Matthieu Funk                                                */
/*             	   Christian Girard                                             */
/*             	   Jean-Francois Vurlod                                         */
/*             	   Marianne Logean                                              */
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
/*	           All Rights Reserved                                          */
/*                                                                              */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes ---------------------------------------*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <memory.h>

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif

#include "PapyPrivFunctionDef3.h"

#ifdef _WINDOWS
#include <io.h>
#endif



enum {kPAPY_READ, kPAPY_WRITE};		/* are we in read or write mode ? */


/********************************************************************************/
/*                                                                              */
/*	FindFreeFile3 : find a free file number in the array of files or        */
/*	increment the current number of open files                              */
/*	return : the number of the file, or standard error message              */
/*                                                                              */
/********************************************************************************/

PapyShort CALLINGCONV
FindFreeFile3 ()
{
  PapyShort i;
  
  for (i = 0; i < kMax_file_open; i++)
  {
    if (gPapyFile [i] == 0)
    {
      return i;

    } /* if */
  } /* for */  
  
  RETURN (papMaxOpenFile);

} /* endof FindFreeFile3 */


/********************************************************************************/
/*                                                                              */
/*	FileOpen3 : Given a filename open the file for reading                  */
/*	return : no error if OK standard error message otherwise                */
/*                                                                              */
/********************************************************************************/

PapyShort
FileOpen3 (char *inNameP, PAPY_FILE inVRefNum, PAPY_FILE *outFp, void* inFSSpec)
{
    PapyShort  theErr;

    
    if (inNameP == NULL || *inNameP == '\0') 
        RETURN (papFileName);

    if (inFSSpec)
    	theErr = Papy3FOpen (inNameP, 'r', inVRefNum, outFp, &inFSSpec);
    else
    	theErr = Papy3FOpen (inNameP, 'r', inVRefNum, outFp, NULL);
    if ((theErr) < 0)
       RETURN (papOpenFile);

    return papNoError;
    
} /* endof FileOpen3 */


/********************************************************************************/
/*                                                                              */
/*	Papy3FileOpen : Given a filename open it and check if it is a Papyrus   */
/*	file by looking for the DICM string at offset 129. It extracts the      */
/*	modality and the transfert syntax used for this file. It initializes    */
/*	the pointers to the data sets and the pixel datas.                      */
/*	return : a reference number to the opened file if successful            */
/*		       standard error message otherwise                         */
/*                                                                              */
/********************************************************************************/

PapyShort CALLINGCONV
Papy3FileOpen (char *inNameP, PAPY_FILE inVRefNum, int inToOpen, void* inFSSpec)
{
    PAPY_FILE		theFp;
    char		theFilename [256];
    unsigned char 	theBuff [15], theVersion [8];
    PapyLong		theFilePos;
    PapyULong		theReadSize, theNbVal;
    PapyShort		theFileNb, theErr;
    int			i, theElemType;
    enum EFile_Type	thePapyrusFile = PAPYRUS3;
    SElement		*theGroupP;
    UValue_T		*theValP;
    PapyShort           iResult;
    
    iResult = papNoError;

    if (inToOpen)
    {
      /* open the file */
      if ((theErr = FileOpen3 (inNameP, inVRefNum, &theFp, inFSSpec)) < 0)
      {
        iResult = papReadingOpenFile;
      }
    }
    else
      theFp = inVRefNum;
    
    if (iResult == papNoError)
    {
      /* set the file pointer at the begining */ 
        if ((theErr = (PapyShort) Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) 0L)) != 0)
        {
         iResult = papPositioning;
        }
        else
        {
        /* test if the "PAPYRUS 3.X" string is at the begining of the file */
        theReadSize = 15L;
		
        if ((theErr = (PapyShort) Papy3FRead (theFp, (PapyULong *) &theReadSize, 1L, theBuff)) < 0)
        {
          iResult = papReadFile;
        }
        else
        {
          /* compares the extracted string with the awaited string */
          theBuff [14] = '\0';
		
          /* if the PAPYRUS 3.0 string is not here it could be a basic DICOM file */
          if (strncmp ((char *) theBuff, "PAPYRUS 3.", 10) != 0) 
          {
            thePapyrusFile = DICOM10;
          }
    
          /* test the compatibility flag to ensure the file is readable by this   */
          /* version of the PAPYRUS toolkit */
          if (thePapyrusFile == PAPYRUS3)
          {
            if ((char) theBuff [13] > gPapyrusCompatibility [0])
            {
              iResult = papReadFile;
            } /* if ...incompatible version of the PAPYRUS file */
          }
		  
          if (iResult == papNoError)
          {
            /* find a free place for the file */
            theFileNb = FindFreeFile3 ();
            if (theFileNb < 0)
            {
              iResult = theFileNb;
            }
            else
            {
              gPapyFile [theFileNb]    = theFp; 
              gReadOrWrite [theFileNb] = kPAPY_READ;
			  gCachedGroupLength [theFileNb] = 0L;
			  gSeekPos [theFileNb] = 0;
			  gSeekPosApplied  [theFileNb] = 0;
			  
              /* set the papyrus version number */
              if (thePapyrusFile == PAPYRUS3)
              {
                for (i = 0; i < 4; i++)
                {
                  theVersion [i] = theBuff [i + 8];
                }
                theVersion [4] = '\0';
                /* convert the result to a float */
                gPapyrusFileVersion [theFileNb] = (float)atof ((char *) theVersion);
              } /* if ...it is a PAPYRUS file */
              else 
              {
                /* put the current value */
                gPapyrusFileVersion [theFileNb] = (float)atof ((char *) gPapyrusVersion);
              }
			  
              /* set the transfert syntax to the default one */
              gArrTransfSyntax [theFileNb] = LITTLE_ENDIAN_EXPL;    
			  
              /* go to the place where the "DICM" prefix should be (position 128) */ 
              if ((theErr = (PapyShort) Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) 128L)) != 0)
              {
                iResult = papPositioning;
				
              }
              else
              {
                theReadSize = 4L;
				
                if ((theErr = (PapyShort) Papy3FRead (theFp, (PapyULong *) &theReadSize, 1L, theBuff)) < 0)
                {
                  iResult = papReadFile;
                }
                else
                {
                  /* compares the extracted string with the awaited string */
                  theBuff [4] = '\0';
                  if (strcmp ((char *) theBuff, "DICM") != 0)
                  {
                    /* it could still be a non-part 10 DICOM file */
                    /* so try to get the modality element, if everything works fine */
                    /* assume it is the case */
					
                    /* reset the file pointer at the begining of the file */
                    theErr = Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) 0L);
					
                    /* set the transfert syntax to the most banal one */
                    gArrTransfSyntax [theFileNb] = LITTLE_ENDIAN_IMPL;
                    gArrCompression  [theFileNb] = NONE;
					
					// Antoine - 25 July 2008
					if ((theErr = ExtractFileMetaInformation3 (theFileNb)) < 0)
					{
						theErr = Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) 0L);
					}
					
                    /* goto group number 8 and if found read it */
                    if ((theErr = Papy3GotoGroupNb (theFileNb, 0x0008)) < 0)
                    {
						iResult = papNotPapyrusFile;
                    }
                    
					if( iResult == papNoError)
                    {
                      if ((theErr = Papy3GroupRead (theFileNb, &theGroupP)) < 0)
                      {
						iResult = papNotPapyrusFile;
                      }
                    } /* else ...group 0x0008 found */
					
                    if (iResult == papNoError)
                    {
                      /* try to extract the modality */

                      theValP = Papy3GetElement (theGroupP, papModalityGr, &theNbVal, &theElemType);
                      if (theValP != NULL)
                      {
                        ExtractModality (theValP, theFileNb);
                        thePapyrusFile = DICOM_NOT10; /* non-part 10 DICOM file */
                      }
                      else
                      {
                        thePapyrusFile = DICOM10; /* neither a DICOM file nor a PAPYRUS one */

                      } /* theValp NULL */
    
                      /* free the group 8 */
                      theErr = Papy3GroupFree (&theGroupP, TRUE);
    
                      /* reset the file pointer to its previous position */
                      theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, 0L);
      
                      /* neither a PAPYRUS nor a DICOM file */
                      if (thePapyrusFile == DICOM10)
                      {
                        iResult = papNotPapyrusFile;
                      } 

                    } /* if ...no error til yet ... */

                  } /* if ...could it be a non-part 10 DICOM file ? */
                  else  /* is it a DICOMDIR file? */
                  {

                    ExtractDicomdirFromPath (inNameP, theFilename);
                    if (theFilename [0] != '\0' &&
                        ((strncmp ((char*) theFilename, "dicomdir", 8) == 0) ||
                         (strncmp ((char*) theFilename, "Dicomdir", 8) == 0) ||
                         (strncmp ((char*) theFilename, "DICOMDIR", 8) == 0)))
                    {/* it is a DICOMDIR file: find now if group 0004 exist */

                      /* set the file pointer at the begining of the Directory Information */
                      theErr = Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) 132L);

                      /* goto group number 4  */
                      if ((theErr = Papy3GotoGroupNb (theFileNb, 0x0004)) >= 0)
                        thePapyrusFile = DICOMDIR; /* DICOMDIR file */
                      
                      /* reset the file pointer to its previous position */
                      theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, 132L);
                    }/* if DICOMDIR filename */

                  } /* else is it a DICOMDIR file? */

                  if (iResult == papNoError)
                  {
                    /* is it a PAPYRUS or a basic DICOM file ? */
                    /* 0 = DICOM part 10, 1 = PAPYRUS 3.X, 2 = non-part 10 DICOM, 3 = DICOMDIR */
                    gIsPapyFile [theFileNb] = thePapyrusFile;
    
                    gNbShadowOwner [theFileNb] = 0;
			              /* shadow_group that we allow to read */
                    (void) Papy3AddOwner (theFileNb, "PAPYRUS 3.0");
    
                    /* read group 2 (File Meta Information) to extract the basic informations */
                    /* regarding the way of reading the file */
                    if (gIsPapyFile [theFileNb] != DICOM_NOT10)
                    {
                      if ((theErr = ExtractFileMetaInformation3 (theFileNb)) < 0)
                      {
                        iResult = theErr;
						
						if (gShadowOwner [theFileNb] != NULL) 
							efree3 ((void **) &(gShadowOwner [theFileNb]));
                      }
					  
					  if( gArrTransfSyntax [theFileNb] == BIG_ENDIAN_EXPL) 
					  {
						//This is a sad reality..... OsiriX is not Big endian savvy for DICOM files............
						iResult = -1;
						printf("Transfer Syntax is BIG_ENDIAN_EXPL : unsupported by Papy Toolkit\r");
						}
					} /* if ...anything but a DICOM not 10 file */
    
                    if (iResult == papNoError)
                    {
                      if (gIsPapyFile [theFileNb] == DICOMDIR)
                      {
                        iResult = theFileNb;
                      }
                      else
                      {
                        /* extraction of the informations regarding groups 41 such as the number */
                        /* of images, the offsets to the data set and the pixel datas.           */
                        /* !!! This is only done for the PAPYRUS 3.X files !!!		     */
                        if (gIsPapyFile [theFileNb] == PAPYRUS3)
                        {
                          if ((theErr = ExtractPapyDataSetInformation3 (theFileNb)) < 0) 
                          {
                            iResult = theErr;
							
							if (gShadowOwner [theFileNb] != NULL) 
								efree3 ((void **) &(gShadowOwner [theFileNb]));
                          }
                        } /* if ...PAPYRUS file */
    
                        if (iResult == papNoError)
                        {
                          /* extract some information from group 28 */
                          /* first : keep the position in the file */
                          theErr = Papy3FTell (gPapyFile [theFileNb], &theFilePos);
  
                          /* then go to the data set */
                          if (gIsPapyFile [theFileNb] == DICOM10)
                            theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, 132L);
                          else if (gIsPapyFile [theFileNb] == DICOM_NOT10)
                            theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, 0L);
                          else if (gIsPapyFile [theFileNb] == PAPYRUS3)
                            theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, *gRefImagePointer [theFileNb]);
      
                          /* extract the informations from group28 from the file */
						  
                          if ((theErr = ExtractGroup28Information (theFileNb)) < 0)
                          {
								iResult = theErr;
								
								if (gShadowOwner [theFileNb] != NULL) 
									efree3 ((void **) &(gShadowOwner [theFileNb]));
                          }
						  
						  if (gIsPapyFile [theFileNb] == DICOM10)
                            theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, 132L);
                          else if (gIsPapyFile [theFileNb] == DICOM_NOT10)
                            theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, 0L);
							
                          /* extract data set information for the DICOM files */
						  
                          if ((gIsPapyFile [theFileNb] == DICOM10 || gIsPapyFile [theFileNb] == DICOM_NOT10) && (iResult == papNoError))
                          {
                            if ((theErr = ExtractDicomDataSetInformation3 (theFileNb)) < 0)
                            {
								iResult = theErr;

                            }
                          } /* if */
							
                          if (iResult == papNoError)
                          {
                            /* reset the file pointer to its previous position */
                            theErr = Papy3FSeek (gPapyFile [theFileNb], SEEK_SET, theFilePos);

                            iResult=theFileNb;
                          }
                        } /* if ...no error 'til yet... */
                      } /* else ... not a DICOMDIR file */
                    } /* if ...no error 'til yet... */
                  } /* if ...no error 'til yet... */
                } /* else ...no error reading the DICM string from the file */
              } /* else ...no error positioning the file pointer to the place where the DICM string is */
            } /* found a free file number for the file */

            /* if error */
            if (iResult < 0)
            {
              gPapyFile [theFileNb] = 0; 
            } /* if */

          } /* if ...no error 'til yet... */
        } /* else ...no error reading the file looking for the PAPYRUS 3.X str */
      } /* else ...no error setting the file pointer at the begining */

      /* if error */
      if (iResult < 0)
      {
        /* if file was open */
        if (inToOpen)
        {
          Papy3FClose (&theFp);
        } /* if */
      } /* if ...no error 'til yet... */

    } /* if ...no error 'til yet... */ 
    
	if( iResult > kMax_file_open)
		printf("Warning nbFile > kMax_file_open");
	
    return iResult;
    
} /* endof Papy3FileOpen */



/********************************************************************************/
/*									 	*/
/*	Papy3FileCreate : given a filename check if this file does not exist and*/
/*	creates a new file. It has to put the file Meta Info as well as the	*/
/*	DICM prefix to identify the file. It has to initialize the variables	*/
/*	necessary to store the different offsets. It has to create the file	*/
/* 	structure in memory (list).						*/
/*	return : a reference number to the opened file if successful		*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3FileCreate (char *inNameP, PAPY_FILE inVRefNum, PapyUShort inNbImages, 
		 enum ETransf_Syntax inSyntax, enum EPap_Compression inCompression,
		 enum EModality inModality, int inToCreate, int inIsPapyrus, void* inFSSpec)
{
  PapyULong	theNumberOfBytes, theLengthOfFilename;
  int		i;
  PapyShort	theFileNb, theErr;
  PAPY_FILE	theFp;
  char	        theBuff [134];
  papObject	*theObjectP;
  Item	    	*theItemP;
  SElement	*theGr41P;
  /*void 	        *theFSSpecP;*/
    
/* -------- validity tests -------- */

  /* we have to have an image */
  if (inNbImages == 0) RETURN (papNbImagesIsZero);
    
  /* no valid filename specified */
  if (inToCreate && (inNameP == NULL || *inNameP == '\0')) RETURN (papFileName);
    
  /* Is the choosen syntax implemented ? */
  if (!((inSyntax == LITTLE_ENDIAN_IMPL && inCompression == NONE) ||
        (inSyntax == LITTLE_ENDIAN_EXPL && 
         (inCompression == NONE || inCompression == JPEG_LOSSLESS || inCompression == JPEG_LOSSY 
#ifdef MAYO_WAVE
          || inCompression == MAYO_WAVELET
#endif
     ))))
    RETURN (papSyntaxNotImplemented);
        
  /* Is the modality known in DICOM ? */
  if (inModality != CR_IM       && inModality != CT_IM     && inModality != MR_IM && 
      inModality != NM_IM       && inModality != US_IM     && inModality != US_MF_IM &&
      inModality != SEC_CAPT_IM && inModality != PX_IM     && inModality != DX_IM &&
      inModality != MG_IM       && inModality != IO_IM     && inModality != RF_IM &&
      inModality != PET_IM      && inModality != VLE_IM    && inModality != VLM_IM &&
      inModality != VLS_IM      && inModality != VLP_IM    && inModality != MFSBSC_IM &&
      inModality != MFGBSC_IM   && inModality != MFGWSC_IM && inModality != MFTCSC_IM) 
      RETURN (papUnknownModality);

/* -------- creating and opening the file -------- */
     
  /* look for a valid file number */
  theFileNb = FindFreeFile3 ();

  /* test wether it will be a PAPYRUS file or a set of DICOM files */
  if (inIsPapyrus == PAPYRUS3)	/* it is a PAPYRUS file, not a basic DICOM file */
    gIsPapyFile [theFileNb] = PAPYRUS3;
  else		/* it will be a set of DICOM files */
    gIsPapyFile [theFileNb] = DICOM10;

  gCachedGroupLength[theFileNb] = 0L;
  
  /* too many open files */
  if (theFileNb < 0) RETURN (theFileNb);
    
  if (inToCreate && gIsPapyFile [theFileNb] == PAPYRUS3)
  {
    /*if (inFSSpec)
    	theFSSpecP = &inFSSpec;
    else
    	theFSSpecP = NULL;*/
      
    if ((theErr = Papy3FCreate (inNameP, inVRefNum, &theFp, &inFSSpec)) != 0)
      RETURN (papFileAlreadyExist);
    
    if ((theErr = Papy3FOpen (inNameP, 'w', inVRefNum, &theFp, &inFSSpec)) != 0)
      RETURN (papFileCreationFailed);
      
    /*if (theFSSpecP != NULL) efree3 ((void **) &theFSSpecP);*/
  } /* if ...inToCreate */
  /* give it the file reference number */
  else theFp = inVRefNum;
  
  /* assign the file to the array of files */
  gPapyFile [theFileNb] = theFp;  


/* -------- file meta information -------- */

  /* if it is a PAPYRUS file */
  if (gIsPapyFile [theFileNb] == PAPYRUS3)
  {
    /* Put the DICOM File Meta Information in the file */
    /* first put a PAPYRUS 3.X string at the begining of the file */
    strcpy (theBuff, "PAPYRUS ");
    strcat (theBuff, gPapyrusVersion);
    strcat (theBuff, " ");
    /* set a different compatibility flag depending on the syntax used */
    if (inSyntax == LITTLE_ENDIAN_EXPL)
      strcat (theBuff, gPapyrusCompatibility);
    else strcat (theBuff, "1");
    /* then put 128 bytes set to 0 */
    for (i = 14; i < 128; i++) theBuff [i] = 0;
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
    
  } /* if ...PAPYRUS file */
    
  /* creation of the file meta information and initialization of the memory */
  /* representation of the file structure (list) */
  if ((theErr = CreateFileMetaInformation3 (theFileNb, inCompression, inSyntax, inModality)) < 0) RETURN (theErr);

/* -------- creation of the basic objects -------- */

  /* add a blank object for the Patient Summary to the file representation */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI 	    = papItem;
  theObjectP->item   	    = NULL;
  theObjectP->module 	    = NULL;
  theObjectP->group  	    = NULL;
  theObjectP->tmpFileLength = 0L;
  theItemP = InsertLastInList (&(gArrMemFile [theFileNb]), theObjectP);
    
  /* create a new papObject to store group 41 */
  theObjectP = (papObject *) emalloc3 ((PapyULong) sizeof (papObject));
  theObjectP->whoAmI 	    = papGroup;
  theObjectP->item   	    = NULL;
  theObjectP->module 	    = NULL;
  theObjectP->tmpFileLength = 0L;
    
  /* creation of the group 41 (Papyrus Data Element) */
  theGr41P = Papy3GroupCreate (Group41);
   
  /* store the group41 in the papObject */
  theObjectP->group = theGr41P;
  theObjectP->objID = Group41;
    
  /* insert the papObject at the end of the list representing the file */
  theItemP = InsertLastInList (&(gArrMemFile [theFileNb]), theObjectP);
    
  /* put the number of images in the group 41 */
  Papy3PutElement (theGr41P, papNumberofimagesGr, &inNbImages);
    
    
    
/* -------- initializations a la Papyrus 2 -------- */

  /* nb of images in this file */
  gArrNbImages [theFileNb] = inNbImages;
    
  /* stores the name of the file (will be used to create the tmp files */
  theLengthOfFilename = (PapyULong) strlen (inNameP);
  gPapFilename [theFileNb] = (char *) emalloc3 ((PapyULong) theLengthOfFilename + 1L);
  strcpy (gPapFilename [theFileNb], inNameP);
    
  /* allocates room for the icons only if Papyrus compressed file */
  if (inSyntax == LITTLE_ENDIAN_EXPL && (inCompression == JPEG_LOSSLESS || 
	  				 inCompression == JPEG_LOSSY 
#ifdef MAYO_WAVE
       					 || inCompression == MAYO_WAVELET
#endif
     ))
  {
    gArrIcons [theFileNb] = (PapyUChar **) ecalloc3 ((PapyULong) inNbImages, 
      						      (PapyULong) sizeof (PapyUChar *));
    /* initializes the icon pointers to NULL */
    for (i = 0; i < inNbImages; i++) 
      gArrIcons [theFileNb] [i] = NULL;
  } /* if ...compressed file */

  /* modality of the file */
  gFileModality [theFileNb] = inModality;
    
  /* set the transfert syntax and the compression used for the file */
  gArrTransfSyntax [theFileNb] = inSyntax;
  gArrCompression  [theFileNb] = inCompression;

  /*if (compression == JPEG_LOSSLESS)
	gArrCompression  [theFileNb] = JPEG_LOSSLESS;
  else
	gArrCompression  [theFileNb] = JPEG_LOSSY;*/
    
  /* allocate room for the offsets to the data set and pixel data of the file */
  gRefImagePointer [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) inNbImages, 
    						     	 (PapyULong) sizeof (PapyULong));
  gPosImagePointer [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) inNbImages,
    						     	 (PapyULong) sizeof (PapyULong));
  gRefPixelOffset  [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) inNbImages, 
    						     	 (PapyULong) sizeof (PapyULong));
  gPosPixelOffset  [theFileNb] = (PapyULong *) ecalloc3 ((PapyULong) inNbImages,
    						     	 (PapyULong) sizeof (PapyULong));
    
  /* the file is in write mode */
  gReadOrWrite [theFileNb] = kPAPY_WRITE;
    

  RETURN (theFileNb);
    
} /* endof Papy3FileCreate */



/********************************************************************************/
/*										*/
/*	write_pos3 : writes from the buffer to the file at the specified pos. 	*/
/*	This function is used when writting the backward references to the file	*/
/* 	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort
write_pos3 (PAPY_FILE inFp, PapyULong inPos, unsigned char **ioBuffP, PapyShort inLength)

/*PapyShort	inFp;					 the file pointer */
/*PapyULong	inPos;			       the position to write from */
/*unsigned char	**ioBuffP;				 the buffer to write from */
/*PapyShort	inLength;		       the length of the element to write */
{
  int		theErr;
  PapyULong   	theTmpULong;
    
    
  if (Papy3FSeek (inFp, (int) SEEK_SET, (PapyLong) inPos))
  {
    theErr = Papy3FClose (&inFp);
    efree3 ((void **) ioBuffP);
    RETURN (papPositioning)
  } /* if */
    
  theTmpULong = inLength;

  if (Papy3FWrite (inFp, (PapyULong *) &theTmpULong, 1L, *ioBuffP) < 0)
  {
    theErr = Papy3FClose (&inFp);
    efree3 ((void **) ioBuffP);
    RETURN (papWriteFile)
  } /* if */
        
  efree3 ((void **) ioBuffP);
    
  RETURN (papNoError);
    
} /* endof write_pos3 */
 

/********************************************************************************/
/*										*/
/*	Papy3FileClose : Free the memory used by this file and destroys the in 	*/
/*	memory structure representing the file.					*/
/* 	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3FileClose (PapyShort inFileNb, int inToClose)
{
  PapyShort	theErr;
  int		i;
  
  /* close the Papyrus file */
  if (inToClose)
    if (Papy3FClose (&(gPapyFile [inFileNb])) != 0) RETURN (papCLOSE_FILE);
  
  /* delete the in memory file representation */
  if ((theErr = DeleteList (inFileNb, &(gArrMemFile [inFileNb]), TRUE, TRUE, TRUE)) < 0)
    RETURN (theErr);
  
  /* deletes the pointer sequence */
  if ((theErr = DeleteList (inFileNb, &(gPtrSequenceItem [inFileNb]), TRUE, TRUE, TRUE)) < 0)
    RETURN (theErr);
  if ((theErr = DeleteList (inFileNb, &(gImageSequenceItem [inFileNb]), TRUE, TRUE, TRUE)) < 0)
    RETURN (theErr);
  
  if (gArrGroup41 [inFileNb] != NULL)
    theErr = Papy3GroupFree (&(gArrGroup41 [inFileNb]), TRUE); 

  /* frees the allocated memory for the file */
  if (gPapFilename [inFileNb] != NULL)
    efree3 ((void **) &(gPapFilename [inFileNb]));

  /* frees the allocated memory for the file */
  if (gShadowOwner [inFileNb] != NULL) 
    efree3 ((void **) &(gShadowOwner [inFileNb]));
    
  if (gArrIcons [inFileNb] != NULL)
    efree3 ((void **) &(gArrIcons [inFileNb]));

  if (gRefSOPClassUID [inFileNb] != NULL)
    efree3 ((void **) &(gRefSOPClassUID [inFileNb]));

  if (gRefImagePointer [inFileNb] != NULL)
    efree3 ((void **) &(gRefImagePointer [inFileNb]));

  if (gPosImagePointer [inFileNb] != NULL)
    efree3 ((void **) &(gPosImagePointer [inFileNb]));

  if (gRefPixelOffset [inFileNb] != NULL)
    efree3 ((void **) &(gRefPixelOffset [inFileNb]));

  if (gPosPixelOffset [inFileNb] != NULL)
    efree3 ((void **) &(gPosPixelOffset [inFileNb]));
   
  if (gImageSOPinstUID [inFileNb] != NULL) 
  {
    for (i = 0; i < gArrNbImages [inFileNb]; i++) 
    {
      if (*(gImageSOPinstUID [inFileNb] + i) != NULL) 
        efree3 ((void **) (gImageSOPinstUID [inFileNb] + i));
    } /* for */
    efree3 ((void **) &(gImageSOPinstUID [inFileNb]));
  } /* if */


  if( gx0028ImageFormat [inFileNb])
	efree3 ((void **) &(gx0028ImageFormat [inFileNb]));

  gx0028BitsAllocated [inFileNb] = 0;

  gPatientSummaryItem [inFileNb] = NULL;
  
  gPapyFile [inFileNb] = 0;

  if( gCachedGroupLength[ inFileNb] != 0L)
	free( gCachedGroupLength[ inFileNb]);
  gCachedGroupLength[ inFileNb] = 0L;

  if( gCachedFramesMap[ inFileNb] != 0L)
	free( gCachedFramesMap[ inFileNb]);
  gCachedFramesMap[ inFileNb] = 0L;
	
  /* reset the incremental number for the file to zero */
  gCurrTmpFilename [inFileNb] = 1;

  RETURN (theErr);
  
} /* endof Papy3FileClose */


/********************************************************************************/
/*										*/
/*	Papy3WriteAndCloseFile : writes the whole in memory structure of the	*/
/*	given file to the disk. It closes any unclosed data set and saves the 	*/
/* 	references to the data sets and the pixel data. Finally frees some 	*/
/*	memory that is no more needed.						*/
/* 	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3WriteAndCloseFile (PapyShort inFileNb, int inToClose)
{
  unsigned char	*theBuffP;
  PapyShort	theErr, i;
  PapyULong	theBufPos;
  Item		*theFileStructP, *theSeqP, *theDataSetP, *theWrkItemP;
  
  
  /* Do the following tasks only if we are writing a PAPYRUS file */
  if (gIsPapyFile [inFileNb] == PAPYRUS3)
  {
    /* write group 2 (File Meta Information) and free it */
    if ((theErr = Papy3GroupWrite (inFileNb, (gArrMemFile [inFileNb])->object->group, FALSE)) < 0)
      RETURN (theErr);
    
    /* convert the Patient summaries modules to groups */
    theFileStructP = gArrMemFile [inFileNb]->next;
    if ((theErr = ItemModulesToGroups3 (inFileNb, theFileStructP, TRUE)) < 0) 
      RETURN (theErr);
  
    /* write the groups of the patient summary to the Papyrus file */
    theWrkItemP = (Item *) theFileStructP->object->item;
    while (theWrkItemP != NULL)
    {
      /* if gr 41 do not write it as the only element will be in THE gr 41 */
      if (theWrkItemP->object->group->group != 0x0041) 
      {
        /* write the current group to the file and then frees the allocated memory */
	if ((theErr = Papy3GroupWrite (inFileNb, theWrkItemP->object->group, FALSE)) < 0)
	  RETURN (theErr);
      }
      /* get next element of the list */
      theWrkItemP = theWrkItemP->next;
    
    } /* while ...loop on the groups of the patient summary */    
  
  
    /* makes sure that all the data sets have been converted to temporary files */
    /* if not, converts them and frees the modules of the data set */
    theDataSetP = gImageSequenceItem [inFileNb];
    while (theDataSetP != NULL)
    {
      if (theDataSetP->object->whoAmI != papTmpFile)
        if ((theErr = Papy3CloseDataSet (inFileNb, theDataSetP, TRUE, TRUE)) < 0) 
          RETURN (theErr);
    
      /* get next data set of the list */
      theDataSetP = theDataSetP->next;
    } /* while ...makes sure all data sets have been converted to tmp files */
  
  
    /* convert the items modules of the pointer sequence to groups */
    theSeqP = gPtrSequenceItem [inFileNb];
    while (theSeqP != NULL)
    {
      if ((theErr = ItemModulesToGroups3 (inFileNb, theSeqP, TRUE)) < 0)
        RETURN (theErr);
      
      /* get the next item of the pointer sequence */
      theSeqP = theSeqP->next;
    } /* while ...loop on the items of the pointer sequence */
  
  
    /* points to group 41 in the in memory file structure */
    theFileStructP = theFileStructP->next;
    /* write the group 41 */
    if ((theErr = Papy3GroupWrite (inFileNb, theFileStructP->object->group, FALSE)) < 0)
      RETURN (theErr);
  
 
    /* writes the saved references to the file */
    /* loop on the images of the file */
    for (i = 0; i < gArrNbImages [inFileNb]; i++)
    {
      /* put the offset to the data set in the buffer */
      theBuffP  = (unsigned char *) emalloc3 ((PapyULong) sizeof (PapyULong));
      theBufPos = 0;
      Put4Bytes (*(gRefImagePointer [inFileNb] + i), theBuffP, &theBufPos);
      
      /* write the offset from the begining of the file until the data set */
      if ((theErr = write_pos3 (gPapyFile [inFileNb], *(gPosImagePointer [inFileNb] + i), &theBuffP, 4)) < 0)
	RETURN (theErr);
      
      efree3 ((void **) &theBuffP);
      
      /* put the offset to the pixel datas in the buffer */
      theBuffP  = (unsigned char *) emalloc3 ((PapyULong) sizeof (PapyULong));
      theBufPos = 0L;
      Put4Bytes (*(gRefPixelOffset [inFileNb] + i), theBuffP, &theBufPos);
     
      /* write the offset from the begining of the file until the data set */
      if ((theErr = write_pos3 (gPapyFile [inFileNb], *(gPosPixelOffset [inFileNb] + i), &theBuffP, 4)) < 0)
	RETURN (theErr);
      
      efree3 ((void **) &theBuffP);
    
    } /* for ...writing the references to the data sets and the pixel datas */
  
  } /* if ...PAPYRUS file */


  /* frees the allocated memory */
  /* if DICOM file, inFileNb has never existed */
  if (gIsPapyFile [inFileNb] == DICOM10)
    theErr = Papy3FileClose (inFileNb, FALSE);
  else
    theErr = Papy3FileClose (inFileNb, inToClose);

  RETURN (theErr);
  
} /* endof Papy3WriteAndCloseFile */



/********************************************************************************/
/*										*/
/*	ReadGroup3 : reads the next group from the file and put it in a buffer.*/
/*	return : standard error message						*/
/*									 	*/
/********************************************************************************/

PapyShort
ReadGroup3 (PapyShort inFileNb, PapyUShort *outGroupNbP, unsigned char **outBuffP,
	     PapyULong *outBytesReadP, PapyULong *outGroupLengthP)

{
  PapyULong   	theStartPos, theCurrPos, theReadLength, theBufPos = 0L;
  PapyULong   	theGrLength, theElemLength, theFirstElemLength, theTempL, i;
  PapyUShort	theElemNb, theTemplGr2, theElemCreator, theElemNb2;
  int		theErr;
  PAPY_FILE	theFp;

    
  theFp = gPapyFile [inFileNb];
    
  theFirstElemLength = (PapyULong) kLength_length; /* 12 */
    
  /* allocate a buffer to read until group length */
  *outBuffP 	   = (unsigned char *) emalloc3 (theFirstElemLength);
  *outBytesReadP   = theFirstElemLength;
  *outGroupLengthP = 0L;
    
  /* read the file until the group length value */
  theTempL = theFirstElemLength;
  if ((theErr = (PapyShort) Papy3FRead (theFp, &theTempL, 1L, *outBuffP)) < 0)
  {
    efree3 ((void **) outBuffP);
    RETURN (papReadFile)
  } /* if */
  
  i = 0L;	/* position in the read buffer */
  *outGroupNbP	= Extract2Bytes (*outBuffP, &i);	/* group number */
  theElemNb   	= Extract2Bytes (*outBuffP, &i);	/* element number */
  
  /* check the transfert syntax */
  if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL || *outGroupNbP == 0x0002)
  {
    i += 2;	/* moves 2 bytes forward */
    theTemplGr2 = Extract2Bytes (*outBuffP, &i);
    theTempL    = (PapyULong) theTemplGr2;		/* element length */
  } /* if ...EXPLICIT VR */
  /* IMPLICIT VR */
  else theTempL = Extract4Bytes (*outBuffP, &i);	/* element length */
        
        
  /* length of the group element is present */
  /* or DICOMDIR, so compute it */
  if (theElemNb == 0) /* && *outGroupNbP != 0x0004)*/
    theGrLength = Extract4Bytes (*outBuffP, &i);
  /* group with no length set, so compute it */
  else
  {
    theErr = Papy3FSeek (theFp, (int) SEEK_CUR, - (long) theFirstElemLength);
    if (*outGroupNbP != 0x7FE0)
      theGrLength = ComputeUndefinedGroupLength3 (inFileNb, -1L);
    else
    {
      if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL) theGrLength = 12L;
      else theGrLength = 8L;
    } /* else ...group 0x7FE0 */
     
    /* tell Papy3GroupRead to fill the group length element */
    *outGroupLengthP   = theGrLength;
    *outBytesReadP     = 0L;	/* have not read the group length element */
    theFirstElemLength = 0L;
      
  } /* else ...undefined group length */
    
    
  /* different ways of reading depending on the group number */
  switch (*outGroupNbP)
  {
    case 0x0041 :
      /* if it is group 41, we will not read the pointer sequence and the */
      /* image sequence, because they are too big to be kept all the time */
          
      /* find the creator element number for the PAPYRUS 3.0 elements */
      if ((theElemCreator = Papy3FindOwnerRange (inFileNb, 0x0041, "PAPYRUS 3.0")) == 0)
        RETURN (papNotFound);
        
        
      /* save the start of copy area position (file) */
      theErr = Papy3FTell ((PAPY_FILE) theFp, (PapyLong *) &theStartPos);
        
      /* look for the pointer sequence (elem 0x1010) */
      theElemNb2  = theElemCreator << 8;
      theElemNb2 |= 0x0010;
      theErr = Papy3GotoElemNb (inFileNb, *outGroupNbP, theElemNb2, &theElemLength);
        
      /* make sure we have find the element */
      if (theErr == 0)
      {
        /* save the file offset to the pointer sequence */
        theErr = Papy3FTell ((PAPY_FILE) theFp, (PapyLong *) &theCurrPos);
        if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL)
	  theCurrPos += 8L;		/* +8 allows for jumping until begin of val */
	else if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL)
	  theCurrPos += 12L;		/* +12 allows for jumping until begin of val */
        
        /* realloc more place for the group buffer */
        theReadLength  = theCurrPos - theStartPos;
        theBufPos = theFirstElemLength;
        *outBytesReadP += theReadLength;
        *outBuffP = (unsigned char *) erealloc3 (*outBuffP, (PapyULong) (theFirstElemLength + theReadLength),
			(PapyULong) theFirstElemLength); /* OLB */
	
	/* read in the group buffer */
	theErr = Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) theStartPos);
    
    	if ((theErr = (PapyShort) Papy3FRead (theFp, &theReadLength, 1L, ((*outBuffP) + theBufPos))) < 0)
    	{
	  theErr = Papy3FClose (&theFp);
	  efree3 ((void **) outBuffP);
	  RETURN (papReadFile)
    	} /* if */
	theBufPos += theReadLength;
	
	  
	/* skip the pointer sequence */
	theErr = Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) theElemLength);
	
	/* save the current file position */
	theErr = Papy3FTell ((PAPY_FILE) theFp, (PapyLong *) &theStartPos);
      } /* if ...skip the pointer sequence */
	
	
	
      /* look for the image sequence (elem 0x1050) */
      theElemNb2  = theElemCreator << 8;
      theElemNb2 |= 0x0050;
      theErr = Papy3GotoElemNb (inFileNb, *outGroupNbP, theElemNb2, &theElemLength);
      
      /* if image sequence found */
      if (theErr == 0)
      {
        /* stores the position of the Image Sequence in the file */
        theErr = Papy3FTell ((PAPY_FILE) theFp, (PapyLong *) &theCurrPos);
        if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL)
	  theCurrPos += 8L;		/* +8 allows for jumping until begin of val */
	else if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL)
	  theCurrPos += 12L;		/* +12 allows for jumping until begin of val */
        
        theReadLength  = theCurrPos - theStartPos;
        *outBytesReadP += theReadLength;
        /* realloc more place for the group buffer */
        *outBuffP = (unsigned char *) erealloc3 (*outBuffP, (PapyULong) (theBufPos + theReadLength),
						 (PapyULong)theBufPos); /* OLB */
	
	/* read in the group buffer */
	theErr = Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) theStartPos);
    
    	if ((theErr = (PapyShort) Papy3FRead (theFp, &theReadLength, 1L, ((*outBuffP) + theBufPos))) < 0)
    	{
	  theErr = Papy3FClose (&theFp);
	  efree3 ((void **) outBuffP);
	  RETURN (papReadFile)
    	} /* if */
      } /* if ...image sequence */
	
      /* there was no image seq, we assume there was no pointer seq too => read whole group */
      else if (theErr == -29) 
      {
        *outBytesReadP += theGrLength;
        
        /* re-allocate room for the part of the group we will read */
        *outBuffP = (unsigned char *) erealloc3 (*outBuffP, (PapyULong) (theFirstElemLength + theGrLength),
						 (PapyULong) theFirstElemLength);        /* OLB */
        /* reads the group from the file */
    	if ((theErr = (PapyShort) Papy3FRead (theFp, &theGrLength, 1L, ((*outBuffP) + theFirstElemLength))) < 0)
    	{
	  theErr = Papy3FClose (&theFp);
	  efree3 ((void **) outBuffP);
	  RETURN (papReadFile)
    	} /* if */
	  
      } /* else ...element not found */
	
      break;
      
    case 0x7FE0 :
      /* allocates everything but the pixel data pointer to efficiently use mem */
      /* test the value representation */
      if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL)
        theGrLength = (4 * sizeof (PapyUShort)) + sizeof (PapyULong);	/* 12 */
      else
        theGrLength = (2 * sizeof (PapyUShort)) + sizeof (PapyULong);	/* 8 */

      if (theFirstElemLength != 0)
      {
        *outBuffP = (unsigned char *) erealloc3 (*outBuffP, (PapyULong) (theFirstElemLength + theGrLength),
		  			         (PapyULong) theFirstElemLength); /* OLB */
      } /* if ...theFirstElemLength <> 0 */
      else
      {
        efree3 ((void **) outBuffP);		/* frees the outbuf */
        *outBuffP = (unsigned char *) emalloc3 (theGrLength);
      } /* theFirstElemLength = 0 */
 
      *outBytesReadP += theGrLength;
       
      /* reads the group from the file until the pixel datas */
      if ((theErr = (PapyShort) Papy3FRead (theFp, &theGrLength, 1L, ((*outBuffP) + theFirstElemLength))) < 0)
      {
        theErr = Papy3FClose (&theFp);
        efree3 ((void **) outBuffP);
        RETURN (papReadFile)
      } /* if */
      break;
      
    default :
      *outBytesReadP += theGrLength;
        
      /* re-allocate room for the part of the group we will read */
      *outBuffP = (unsigned char *) erealloc3 (*outBuffP, (PapyULong) (theFirstElemLength + theGrLength),
		  			       (PapyULong) theFirstElemLength); /* OLB */
        
      /* reads the group from the file */
      if ((theErr = (PapyShort) Papy3FRead (theFp, &theGrLength, 1L, ((*outBuffP) + theFirstElemLength))) < 0)
      {
		efree3 ((void **) outBuffP);
		RETURN (papReadFile)
      } /* if */
      break;
        
  } /* switch ...group number */
      
    
  RETURN (papNoError);
    
} /* endof ReadGroup3 */


/********************************************************************************/
/*										*/
/*	WriteGroup3 : writes the next group					*/
/*	return : 0 if OK							*/
/*		 else standard error message					*/
/*										*/
/********************************************************************************/

PapyShort
WriteGroup3 (PAPY_FILE inFp, unsigned char *inBuffP, PapyULong ioBytesToWrite)

/*PapyShort	inFp;			     the file to write to */
/*unsigned char	*inBuffP;			     the buffer to write from */
/*PapyULong	ioBytesToWrite		     the number of bytes to write */
{
  int		theErr;


  if (Papy3FWrite (inFp, &ioBytesToWrite, 1L, inBuffP) < 0)
  {
    theErr = Papy3FClose (&inFp);
    RETURN (papWriteFile)
  } /* if */
     
  RETURN (papNoError);
    
} /* endof WriteGroup3 */


/********************************************************************************/
/*										*/
/*	Papy3GetNextGroupNb : get the number of the next group to be read  	*/
/*	return : the number of the next group if OK				*/
/*		 else READ_FILE error (-22) EOF reached				*/
/*									 	*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GetNextGroupNb (PapyShort inFileNb)
{
  PAPY_FILE		theFp;	     
  unsigned char		theBuff [2];
  PapyULong		i;
  PapyUShort		theGroupNb;
  int		    	theErr;
	
  
  theFp = gPapyFile [inFileNb];

  i = 2L;
  if ((theErr = (PapyShort) Papy3FRead (theFp, &i, 1L, (void *) theBuff)) < 0)
  {
    theErr = Papy3FClose (&theFp);
    RETURN (papReadFile)
  } /* if */
   
  i = 0L;
  theGroupNb = Extract2Bytes (theBuff, &i);
  
  /* resets the file pointer to its previous position */
  if (Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) -2L) != 0) RETURN (papPositioning);

  return theGroupNb;
    
} /* endof Papy3GetNextGroupNb */



/********************************************************************************/
/*										*/
/*	Papy3SkipNextGroup : skips the next group				*/
/*	return : 0 if OK							*/
/*		 else standard error message (-22 = READ ERROR = eof reached)	*/
/*		 or the size of the element is wrong (-27)			*/
/* 		 or we jumped over the eof (-25)			 	*/
/*										*/
/********************************************************************************/

struct cachedGroupStruct
{
	int group;
	int length;
};
typedef struct cachedGroupStruct cachedGroupStruct;

PapyShort CALLINGCONV
Papy3SkipNextGroup (PapyShort inFileNb)
{
	PAPY_FILE		theFp;
	unsigned char	theBuff [kLength_length];
	PapyULong		i;
	PapyULong		theGrLength, theTempL;
	PapyUShort	theTempS, theGrNb;
	int			theErr;
	
	theFp = gPapyFile[ inFileNb];
	
	cachedGroupStruct *cachedGroup = gCachedGroupLength[ inFileNb];
	
	if( cachedGroup == 0L)
	{
		gCachedGroupLength[ inFileNb] = cachedGroup = (cachedGroupStruct*) malloc( 1024L * sizeof( cachedGroupStruct));
		if( cachedGroup == 0L)
			printf("malloc failed Papy3SkipNextGroup\r");
		cachedGroup[0].length = 0;
		cachedGroup[0].group = 0;
	}
	
	i = kLength_length;
	if ((theErr = (PapyShort) Papy3FRead (theFp, &i, 1L, theBuff)) < 0)
	{
		theErr = Papy3FClose (&theFp);
		RETURN (papReadFile)
	} /* if */
	
	i = 0L;
	theGrNb  = Extract2Bytes (theBuff, &i);
	theTempS = Extract2Bytes (theBuff, &i);
	
	/* DICOMDIR separator  0xFFFE:0xE000 */
	if ((theGrNb == 0xFFFE) && (theTempS == 0xE000)) 
	{
		theErr = Papy3FSeek (theFp, (int) SEEK_CUR, -4L);
		RETURN (theErr)
	} /* if */
	
	/* Try to find the group length in the cache */
	int z = 0;
	while( cachedGroup[ z].length != 0 && cachedGroup[ z].group != 0)
	{
		if( cachedGroup[ z].group == theGrNb)
			break;
		z++;

		if( z >= 1000)
			break;
	}
	
	if( cachedGroup[ z].group == theGrNb)
	{
		if (Papy3FSeek (theFp, (int) SEEK_CUR, cachedGroup[ z].length - kLength_length) != 0)
			RETURN (papPositioning);
		RETURN( papNoError);
	}
	
	/* if the group length elem is here extract the group length from the buffer */
	if (theTempS == 0)
	{
		/* test the VR */
		if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL && theGrNb != 0x0002)
			theTempL = Extract4Bytes (theBuff, &i);
		else 
		{
			i += 2L;
			theTempL = (PapyULong) Extract2Bytes (theBuff, &i);
		} /* else */
		/* if (theTempL != 4L) RETURN (papElemSize); this is to let pass little endian impl gr2 files */
		theGrLength = Extract4Bytes (theBuff, &i);

		//	if( theGrLength <= 0)
		{
			theErr = Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) - kLength_length);
			theGrLength = ComputeUndefinedGroupLength3 (inFileNb, -1L);
		}
	} /* if ...extract group length from buffer */

	/* else the group length element not here compute it */
	else
	{
		 /* test the VR */
		if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL && theGrNb == 0x0002)
		{
			theErr = Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) - kLength_length);
			theGrLength = ComputeUndefinedGroupLength3 (inFileNb, -1L);
			if( theGrLength == 8)
				theGrLength = 28;
		}
		else
		{
			theErr = Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) - kLength_length);
			theGrLength = ComputeUndefinedGroupLength3 (inFileNb, -1L);
		}
	} /* else ...undefined group length */

	if( theGrLength <= 0)
	{
		printf("error theGrLength <= 0 : %d\r", theGrLength);
		RETURN ( -1);
	}
	/* sets the file pointer at the begining of the next group */
	if (Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) theGrLength) != 0)
		RETURN (papPositioning);
	
	cachedGroup[ z].group = theGrNb;
	cachedGroup[ z].length = theGrLength;
	
	cachedGroup[ z+1].group = 0;
	cachedGroup[ z+1].length = 0;
	
	RETURN (papNoError);
} /* endof Papy3SkipNextGroup */



/********************************************************************************/
/*										*/
/*	Papy3GotoGroupNb : goto the specified group nb				*/
/*	return : 0 if OK							*/
/*		 else standard error message (-22 = READ ERROR = eof reached)	*/
/* 		 or we jumped over the eof (-25)				*/
/*		 or the group was missing (-29)					*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GotoGroupNb (PapyShort inFileNb, PapyShort inGroupNb)

/*PapyShort	inFileNb;	       the file pointer to read from */
/*PapyShort	inGroupNb;	    the group we want to position to */
{
  PapyShort	theLastGroupNb, theCurrGroupNb, theStartGroupNb, theErr = 0;
  PapyLong	theStartPos;
    
    
  theErr = Papy3FTell ((PAPY_FILE) gPapyFile [inFileNb], (PapyLong *) &theStartPos);
   
  theLastGroupNb = 0x0000;		/* foo intial value */
  theCurrGroupNb = Papy3GetNextGroupNb (inFileNb);  
  if (theCurrGroupNb < 0)
    RETURN (theCurrGroupNb);
  theStartGroupNb = theCurrGroupNb;
    
  while (theCurrGroupNb < inGroupNb && 
    	 theCurrGroupNb > 0 &&
	 theCurrGroupNb >= theStartGroupNb &&
	 theCurrGroupNb != 0x7FE0)
  {
    theErr = Papy3SkipNextGroup (inFileNb);
    if (theErr < 0) 
    {
      Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theStartPos);
      RETURN (theErr);
    } /* if */
      
    theLastGroupNb = theCurrGroupNb;
    theCurrGroupNb = Papy3GetNextGroupNb (inFileNb);
    if (theCurrGroupNb < 0)
	{
	
	}
  } /* while */
    
  if (theCurrGroupNb != inGroupNb)
  {
    Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theStartPos);
    RETURN (papGroupNumber);
  } /* if ...group missing */
    
    
  RETURN (papNoError);
    
} /* endof Papy3GotoGroupNb */



/********************************************************************************/
/*										*/
/*	Papy3FindOwnerRange : Look for the range dynimcally attributed to DICOM	*/
/*	Private Data Elements given the owner name, the group number and the	*/
/* 	Papyrus file number.							*/
/*	To make sure the file pointer is set at the right position (begining of */
/*	the group to look at one should first call the Papy3GotoGroupNb 	*/
/*	function.								*/
/*	return : the element number of the creator element for this range	*/
/*		 else standard error message					*/
/*										*/
/********************************************************************************/

PapyUShort CALLINGCONV
Papy3FindOwnerRange (PapyShort inFileNb, PapyUShort inGroupNb, char *inOwnerStrP)
{
  PAPY_FILE	theFp;
  SShadowOwner	*theShOwP;
  char		*theStringP, *theP, theVr [3];
  unsigned char theBuff [256], *theBuffP;
  int		j, found = FALSE;
  PapyShort	theErr = 0;
  PapyUShort	theExtrGrNb, theExtrElemNb, tmpUShort;
  PapyULong	theElemLength, theStartPos, i, ii, theTmpULong, theULong;
  
  
  /* save the current file position */
  theFp = gPapyFile [inFileNb];
  Papy3FTell ((PAPY_FILE) theFp, (PapyLong *) &theStartPos);  
  
  theExtrGrNb = inGroupNb;
  /* search loop on the elements */
  while (!found && theExtrGrNb == inGroupNb && theErr >= 0)
  {
    theBuffP = (unsigned char *) &theBuff [0];
    i = 8L; 					/* grNb, theElemNb & theElemLength */
    if ((theErr = (PapyShort) Papy3FRead (theFp, &i, 1L, theBuffP)) < 0)
    {
      theErr = Papy3FClose (&theFp);
      RETURN (papReadFile)
    } /* if */
    
    /* extract the information from the read buffer */
    /* updates the current position in the read buffer */
    i = (PapyULong) 2L;  
    /* extract the group number according to the little-endian syntax */
	#if __BIG_ENDIAN__
    theExtrGrNb  = (PapyUShort) (*(theBuffP + 1));
    theExtrGrNb  = theExtrGrNb << 8;
    theExtrGrNb |= (PapyUShort) *theBuffP;
    #else
	theExtrGrNb  = *((PapyUShort*) theBuffP);
	#endif
	
    /* points to the right place in the buffer */
    theBuffP  = theBuff;
    theBuffP += i;
    /* updates the current position in the read buffer */
    i += 2L;
    /* extract the element number according to the little-endian syntax */
	#if __BIG_ENDIAN__
    theExtrElemNb  = (PapyUShort) (*(theBuffP + 1));
    theExtrElemNb  = theExtrElemNb << 8;
    theExtrElemNb |= (PapyUShort) *theBuffP;
    #else
	 theExtrElemNb  = *((PapyUShort*) theBuffP);
	#endif
	
	
    /* points to the right place in the buffer */
    theBuffP  = theBuff;
    theBuffP += i;
    
    /* check the syntax used for the file */
    if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL)
    {
      /* extract the element length according to the little-endian syntax */
	  #if __BIG_ENDIAN__
      theTmpULong   = (PapyULong) (*(theBuffP + 3));
      theTmpULong   = theTmpULong << 24;
      theULong	    = theTmpULong;
      theTmpULong   = (PapyULong) (*(theBuffP + 2));
      theTmpULong   = theTmpULong << 16;
      theULong	   |= theTmpULong;
      theTmpULong   = (PapyULong) (*(theBuffP + 1));
      theTmpULong   = theTmpULong << 8;
      theULong	   |= theTmpULong;
      theTmpULong   = (PapyULong) *theBuffP;
      theULong 	   |= theTmpULong;
      theElemLength    = theULong;
	  #else
	  theElemLength    = *((PapyULong*) theBuffP);
	  #endif
      /* updates the current position in the read buffer */
      i += 4L;
    } /* if ...implicit VR */
    else    /* explicit VR */
    {
      /* updates the current position in the read buffer */
      i += 2L;
      /* extract the Value Representation */
      theVr [0] = (char) *theBuffP;
      theVr [1] = (char) *(theBuffP + 1);
      theVr [2] = '\0';
      /* points to the right place in the buffer */
      theBuffP  = theBuff;
      theBuffP += i;
      
      /* test the VR */
      if (strcmp (theVr, "OB") == 0 ||
      	  strcmp (theVr, "OW") == 0 || 
          strcmp (theVr, "SQ") == 0 || 
          strcmp (theVr, "UN") == 0 || 
          strcmp (theVr, "UT") == 0)
      {
        /* read 4 more bytes to get the length of the element */
        theBuffP = (unsigned char *) &theBuff [0];
        i = 4L; 					/* elemLength */
        if ((theErr = (PapyShort) Papy3FRead (theFp, &i, 1L, theBuffP)) < 0)
        {
          theErr = Papy3FClose (&theFp);
	  RETURN (papReadFile)
        } /* if */
        
        /* extract the element length according to the little-endian syntax */
		#if __BIG_ENDIAN__
        theTmpULong	= (PapyULong) (*(theBuffP + 3));
        theTmpULong	= theTmpULong << 24;
        theULong	= theTmpULong;
        theTmpULong	= (PapyULong) (*(theBuffP + 2));
        theTmpULong	= theTmpULong << 16;
        theULong       |= theTmpULong;
        theTmpULong	= (PapyULong) (*(theBuffP + 1));
        theTmpULong	= theTmpULong << 8;
        theULong       |= theTmpULong;
        theTmpULong 	= (PapyULong) *theBuffP;
        theULong       |= theTmpULong;
        theElemLength	= theULong;
		#else
		theElemLength	= *((PapyULong*) theBuffP);
		#endif
      } /* if ...VR = OB, OW, SQ, UN or UT */
      else	/* other VRs */
      {
        /* updates the current position in the read buffer */
        i += 2L;
        /* extract the element number according to the little-endian syntax */
		#if __BIG_ENDIAN__
        tmpUShort  = (PapyUShort) (*(theBuffP + 1));
        tmpUShort  = tmpUShort << 8;
        tmpUShort |= (PapyUShort) *theBuffP;
        #else
		tmpUShort  = *((PapyUShort*) theBuffP);
		#endif
		
        theElemLength = (PapyULong) tmpUShort;
      } /* else ...other VRs */
    } /* else ...explicit VR */
    
    /* undefined length => VR = SQ */
    if (theElemLength == 0xFFFFFFFF)
    {
      if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL)
        Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) -8L);
      else
        Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) -12L);
      theElemLength = 0L;
      if ((theErr = ComputeUndefinedSequenceLength3 (inFileNb, &theElemLength)) < 0)
        return (PapyUShort) theErr;
    } /* if ...undefined element length */
    
    /* check if the element is a Creator of Private Data Element one */
    if (theExtrGrNb == inGroupNb && theExtrElemNb >= 0x0010 && theExtrElemNb <= 0x00FF)
    {
      theBuffP = (unsigned char *) &theBuff [0];
      if ((theErr = (PapyShort) Papy3FRead (theFp, &theElemLength, 1L, theBuffP)) < 0)
      {
	theErr = Papy3FClose (&theFp);
	RETURN (papReadFile)
      } /* if */
      
      /* extract the elements value */
      theStringP = (char *) emalloc3 ((PapyULong) (theElemLength + 1));
      theP       = theStringP;
      theBuffP   = theBuff;
      /* extract the element from the buffer */
      for (ii = 0L; ii < theElemLength; ii++, i++) 
      {
        *(theP++) = theBuffP [(int) ii];
      } /* for */
    
      theStringP [ii] = '\0';	/* string terminator */
      
      /* compares the extracted string with the one we are looking for */
      if (strncmp (theStringP, inOwnerStrP, strlen (inOwnerStrP)) == 0)
      {
        /* is Papyrus the owner of the element */
        j = 0;
        theShOwP = gShadowOwner [inFileNb];
        while (!found && j < gNbShadowOwner [inFileNb])
        {
          /* compares both creator strings */
          if (strncmp (theStringP, theShOwP->str_value, strlen (theShOwP->str_value)) == 0)
            found = TRUE;
        
          j++;
          theShOwP++;        
        } /* while ...looking if Papyrus is the owner of the element */
      } /* if ...theStringP comparison */
      
      efree3 ((void **) &theStringP);
      
    } /* if ...Creator of Private Data Element */
    else 	/* move the file pointer theElemLength farther */
      theErr = Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) theElemLength);
    
  } /* while ...extraction loop */
  
  /* reset the file pointer to its start position */
  Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) theStartPos);
  
  /* if the element is creator of a known element returns the range value */
  if (found) return theExtrElemNb;
  else return 0x0000;
  
} /* endof Papy3FindOwnerRange */



/********************************************************************************/
/*										*/
/*	Papy3GotoElemNb : goto the specified element of the current group.	*/
/*	return : the size of the element if OK					*/
/*		 else standard error message (-22 = READ ERROR = eof reached)	*/
/*		 or we did not find the element (-29)				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GotoElemNb (PapyShort inFileNb, PapyUShort inGroupNb, PapyUShort inElemNb, 
		 PapyULong *outElemLengthP)

/*PapyShort		inFileNb;		      the file pointer to read from */
/*PapyShort		inGroupNb;	   the group we want to position to */
/*PapyShort		inElemNb;		 the element we want to position to */
{
  PAPY_FILE	theFp;
  char		theVR [4];
  unsigned char	theBuff [10], *theCharP;
  PapyShort	theErr;
  PapyUShort	theTmpElemNb, theLastElemNb, theTmpGrNb, theTmpElemL;
  PapyULong	theStartPos, i, j, theTmpULong, theULong;
  int 		found = FALSE;

  
  /* save the current file position */
  theFp = gPapyFile [inFileNb];
  Papy3FTell ((PAPY_FILE) theFp, (PapyLong *) &theStartPos);  
        
  theTmpGrNb       = inGroupNb;
  theTmpElemNb     = 0;
  theLastElemNb    = 0;
  *outElemLengthP  = 0L;
        
  while (inGroupNb     == theTmpGrNb && !found &&
  	 theTmpElemNb  <  inElemNb && 
  	 theLastElemNb <= theTmpElemNb)
  {
    Papy3FSeek (theFp, (int) SEEK_CUR, (PapyLong) *outElemLengthP);
        
    i = 8L;
    theCharP = (unsigned char *) &theBuff [0];
    if ((theErr = (PapyShort) Papy3FRead (theFp, &i, 1L, theCharP)) < 0)
    {
      theErr = Papy3FClose (&theFp);
      RETURN (papReadFile)
    } /* if */
    
    theLastElemNb = theTmpElemNb;
    /* extract the information from the read buffer */
    /* updates the current position in the read buffer */
    i = (PapyULong) 2L;  
    /* extract the element according to the little-endian syntax */
	#if __BIG_ENDIAN__
    theTmpGrNb  = (PapyUShort) (*(theCharP + 1));
    theTmpGrNb  = theTmpGrNb << 8;
    theTmpGrNb |= (PapyUShort) *theCharP;
    #else
	theTmpGrNb  = *((PapyUShort*) theCharP);
	#endif
	
	
    /* points to the right place in the buffer */
    theCharP  = theBuff;
    theCharP += i;
    /* updates the current position in the read buffer */
    i += 2L;
    /* extract the element according to the little-endian syntax */
	#if __BIG_ENDIAN__
    theTmpElemNb  = (PapyUShort) (*(theCharP + 1));
    theTmpElemNb  = theTmpElemNb << 8;
    theTmpElemNb |= (PapyUShort) *theCharP;
    #else
	theTmpElemNb  = *((PapyUShort*) theCharP);
	#endif
	
    /* points to the right place in the buffer */
    theCharP  = theBuff;
    theCharP += i;
    
    /* if it is EXPLICIT VR */
    if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL || theTmpGrNb == 0x0002)
    {
      theVR [0] = (char) *theCharP;
      theVR [1] = (char) *(theCharP + 1);
      theVR [2] = '\0';
      theCharP += 2;	/* jump over the VR */
      
      /* updates the current position in the read buffer */
      i += 2L;
      
      if (strcmp (theVR, "OB") == 0 || 
      	  strcmp (theVR, "OW") == 0 || 
      	  strcmp (theVR, "SQ") == 0 ||
      	  strcmp (theVR, "UN") == 0 ||
      	  strcmp (theVR, "UT") == 0)
      {
        /* 2 bytes are set to blank so jump over them */
        i += 2L;
        theCharP +=2;
        
        /* read 4 more chars from the file */
        j = 4L;
        theCharP = (unsigned char *) &theBuff [0];
        if ((theErr = (PapyShort) Papy3FRead (theFp, &j, 1L, theCharP)) < 0)
        {
	  theErr = Papy3FClose (&theFp);
	  RETURN (papReadFile)
        } /* if */
      
        /* extract the element according to the little-endian implicit syntax */
		#if __BIG_ENDIAN__
        theTmpULong      = (PapyULong) (*(theCharP + 3));
        theTmpULong      = theTmpULong << 24;
        theULong	 = theTmpULong;
        theTmpULong      = (PapyULong) (*(theCharP + 2));
        theTmpULong      = theTmpULong << 16;
        theULong        |= theTmpULong;
        theTmpULong      = (PapyULong) (*(theCharP + 1));
        theTmpULong      = theTmpULong << 8;
        theULong        |= theTmpULong;
        theTmpULong      = (PapyULong) *theCharP;
        theULong        |= theTmpULong;
        *outElemLengthP  = theULong;
        #else
		*outElemLengthP  = *((PapyULong*) theCharP);
		#endif
		
        /* updates the number of bytes read */
        i += 4L;

      } /* if ...vr = OB, OW, SQ, UN or UT */
      else /* other VRs */
      {
        /* extract the element according to the little-endian explicit vr syntax */
		#if __BIG_ENDIAN__
        theTmpElemL  = (PapyUShort) (*(theCharP + 1));
        theTmpElemL  = theTmpElemL << 8;
        theTmpElemL |= (PapyUShort) *theCharP;
        #else
		theTmpElemL  = *((PapyUShort*) theCharP);
		#endif
		
        *outElemLengthP = (PapyULong) theTmpElemL;
        
        /* updates the number of bytes read */
        i += 2L;
        
      } /* else ...other VRs */
      
    } /* if ...Little-endian EXPLICIT VR */
    else /* Little-endian IMPLICIT VR */
    {
      /* extract the element according to the little-endian implicit syntax */
	  #if __BIG_ENDIAN__
      theTmpULong      = (PapyULong) (*(theCharP + 3));
      theTmpULong      = theTmpULong << 24;
      theULong	       = theTmpULong;
      theTmpULong      = (PapyULong) (*(theCharP + 2));
      theTmpULong      = theTmpULong << 16;
      theULong	      |= theTmpULong;
      theTmpULong      = (PapyULong) (*(theCharP + 1));
      theTmpULong      = theTmpULong << 8;
      theULong	      |= theTmpULong;
      theTmpULong      = (PapyULong) *theCharP;
      theULong 	      |= theTmpULong;
      *outElemLengthP  = theULong;
	  #else
	  *outElemLengthP  = *((PapyULong*) theCharP);
	  #endif
    
      /* updates the current position in the read buffer */
      i += 4L;
    } /* else ...little-endian IMPLICIT VR */
    
    /* have we got the element ? */
    if (inGroupNb == theTmpGrNb && inElemNb == theTmpElemNb) found = TRUE;
    
    /* undefined length => VR = SQ */
    if (*outElemLengthP == 0xFFFFFFFF && !(inGroupNb == 0x7FE0 && inElemNb == 0x0010))
    {
      Papy3FSeek (theFp, (int) SEEK_CUR,  -(PapyLong)i);
      *outElemLengthP = 0L;
      if ((theErr = ComputeUndefinedSequenceLength3 (inFileNb, outElemLengthP)) < 0)
        return theErr;
    } /* if ...undefined element length */
          
  } /* while ...looking for the pointer sequence */
  
  /* if element not reached reset the file pointer to its original position */
  if (!found)
  {
    Papy3FSeek (theFp, (int) SEEK_SET, (PapyLong) theStartPos);
    return (PapyShort) papNotFound;
  } /* if ...element not found */
  
  /* else go back to the begining of the element */
  else Papy3FSeek (theFp, (int) SEEK_CUR,-(PapyLong)i);
  
  return 0;
  
} /* endof Papy3GotoElemNb */



/********************************************************************************/
/*										*/
/*	Papy3ExtractItemLength : get the length of an item from the item	*/
/*	delimiter								*/
/*	return : the size of the item if OK					*/
/*		 else standard error message					*/
/*										*/
/********************************************************************************/

PapyULong CALLINGCONV
Papy3ExtractItemLength (PapyShort inFileNb)
{
  PAPY_FILE	theFp;
  PapyUShort	theUS;
  PapyULong	theItemLength, theBufPos, i;
  unsigned char	*theBuffP, theBuff [8];

  
  theFp = gPapyFile [inFileNb];
  theBuffP = (unsigned char *) &theBuff [0];
  
  /* read the file until the item length value */
  i = 8L;
  if (Papy3FRead (theFp, &i, 1L, theBuffP) < 0)
  {
    Papy3FClose (&theFp);
    RETURN (papReadFile)
  } /* if */

  /* extract the values from the buffer */
  theBufPos = 0L;
  theUS = Extract2Bytes (theBuffP, &theBufPos);
  if (theUS != 0xFFFE) return (PapyULong) papGroupNumber;
  theUS = Extract2Bytes (theBuffP, &theBufPos);
  if (theUS != 0xE000) return (PapyULong) papElemNumber;
  
  theItemLength = Extract4Bytes (theBuffP, &theBufPos);
  if (theItemLength <= 0) return (PapyULong) papElemSize;
  else 
    if (theItemLength == 0xFFFFFFFF) ComputeUndefinedItemLength3 (inFileNb, &theItemLength);
  
  return theItemLength;
  
} /* endof Papy3ExtractItemLength */

/********************************************************************************/
/*										*/
/*	ComputeUndefinedItemLength3 : compute the size of an item of undefined	*/
/*	length, starting from the current file position.			*/
/*										*/
/********************************************************************************/

PapyShort
ComputeUndefinedItemLength3 (PapyShort inFileNb, PapyULong *ioItemLengthP)
{
  PapyULong	theElemLength, theBufPos, theFileStartPos, i;
  PapyUShort	theGrNb, theElemNb;
  char		theVR [3];
  unsigned char	*theBuffP, theBuff [8];
  int		OK;
  

  /* initialisation */
  theGrNb         = 0;
  theElemNb       = 0;
  theElemLength   = 0L;
  OK 	          = FALSE;
  theVR [0]       = '\0';
  Papy3FTell ((PAPY_FILE) gPapyFile [inFileNb], (PapyLong *) &theFileStartPos);
  
  /* allocate the read buffer */
  theBuffP = (unsigned char *) &theBuff [0];
  
  /* look for the end of item delimiter */
  while (!OK)
  {
    /* read the file until the item length value */
    i = 8L;
    if (Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP) < 0)
    {
      Papy3FClose (&(gPapyFile [inFileNb]));
      RETURN (papReadFile)
    } /* if */

    *ioItemLengthP += 8L;
    
    /* get the group number, the element number and the element length of the */
    /* group */
    theBufPos = 0L;
    theGrNb       = Extract2Bytes (theBuffP, &theBufPos);
    theElemNb     = Extract2Bytes (theBuffP, &theBufPos);
    
    /* extract the element length depending on the syntax */
    if ((gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL && theGrNb != 0x0002) || 
    	(theGrNb == 0xFFFE && theElemNb == 0xE000) ||
    	(theGrNb == 0xFFFE && theElemNb == 0xE00D))
      theElemLength = Extract4Bytes (theBuffP, &theBufPos);
    else
    {
      /* extract the VR */
      theBuffP  += theBufPos;
      theVR [0]  = (char) *theBuffP;
      theVR [1]  = (char) *(theBuffP + 1);
      theVR [2]  = '\0';
      theBuffP   = (unsigned char *) &theBuff [0];
      theBufPos += 2;
      
      /* get the element length depending on the VR */
      if (	(theVR[0] == 'O' && theVR[1] == 'B') ||
			(theVR[0] == 'O' && theVR[1] == 'W') || 
			(theVR[0] == 'S' && theVR[1] == 'Q') || 
			(theVR[0] == 'U' && theVR[1] == 'N') || 
			(theVR[0] == 'U' && theVR[1] == 'T'))
      {

        /* read 4 more bytes */
        i = 4L;
        if (Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP) < 0)
        {
	  Papy3FClose (&(gPapyFile [inFileNb]));
	  RETURN (papReadFile)
        } /* if */
        *ioItemLengthP += 4L;
        theBufPos = 0L;
        theElemLength = Extract4Bytes (theBuffP, &theBufPos);
      }
      else
        theElemLength = (PapyULong) Extract2Bytes (theBuffP, &theBufPos); 
    } /* else ...EXPLICIT VR */
    
    /* is it the end of item delimiter ? */
    if (!(theGrNb == 0xFFFE && theElemNb == 0xE00D && theElemLength == 0L))
    {
      /* if the element <> outGroupLengthP => group of undefined size */
      if (theElemNb != 0x0000)
      {
        /* restore the previous file position */
        if ((theGrNb == 0x0002 || gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL) &&
            (strcmp (theVR, "SQ") == 0 || strcmp (theVR, "OB") == 0 || strcmp (theVR, "OW") == 0))
        {
          Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) -12L);
          *ioItemLengthP -= 12L;
        } /* if */
        else
        {
          Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) -8L);
          *ioItemLengthP -= 8L;
        } /* else */
        
        theElemLength = ComputeUndefinedGroupLength3 (inFileNb, -1L);
        if ((int) theElemLength < 0) RETURN ((PapyShort) theElemLength);
      } /* if ...has to compute the group length */
    
      /* add the size of the group to the item length */
      *ioItemLengthP += theElemLength;
    
      /* move the file pointer */
      Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) theElemLength);
    } /* if ...not end of item delimiter */
    /* we have reached the end of Item delimiter tag */
    else 
    {
      OK = TRUE;
      /* *ioItemLengthP -= 8L; */
    } /* else */
      
  } /* while ...look for the end of item delimiter */ 
  
  /* reset the file pointer to its previous position */
  Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theFileStartPos);
  
  return 0;
  
} /* endof ComputeUndefinedItemLength3 */



/********************************************************************************/
/*										*/
/*	ComputeUndefinedSequenceLength3 : compute the size of a sequence of 	*/
/*	undefined length, starting from the current file position.		*/
/*										*/
/********************************************************************************/

PapyShort
ComputeUndefinedSequenceLength3 (PapyShort inFileNb, PapyULong *ioSeqLengthP)
{
  PapyULong	theElemLength, theBufPos, theFileStartPos, i;
  PapyUShort	theGrNb, theElemNb;
  char		theVR [3];
  unsigned char	*theBuffP, theBuff [8];
  int 		OK, theErr = 0;
  
  
  /* initialisation */
  theGrNb         = 0;
  theElemNb       = 0;
  theElemLength   = 0L;
  OK 	          = FALSE;
  Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &theFileStartPos);
  
  /* allocate the read buffer */
  theBuffP = (unsigned char *) &theBuff [0];
  
  /* look for the end of sequence delimiter */
  while (!OK)
  {
    /* read the file until the item length value */
    i = 8L;
    if (Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP) < 0)
    {
      Papy3FClose (&(gPapyFile [inFileNb]));
      RETURN (papReadFile)
    } /* if */
    
    *ioSeqLengthP += 8L;

    /* get the group number, the element number and the element length of the */
    /* item delimiter element */
    theBufPos 	  = 0L;
    theGrNb       = Extract2Bytes (theBuffP, &theBufPos);
    theElemNb     = Extract2Bytes (theBuffP, &theBufPos);
    
    /* extract the element length depending on the syntax */
    if ((gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL && theGrNb != 0x0002) || 
    	(theGrNb == 0xFFFE && theElemNb == 0xE000) ||
    	(theGrNb == 0xFFFE && theElemNb == 0xE00D) ||
    	(theGrNb == 0xFFFE && theElemNb == 0xE0DD))
      theElemLength = Extract4Bytes (theBuffP, &theBufPos);
    else
    {
      /* extract the VR */
      theBuffP  += theBufPos;
      theVR [0]  = (char) *theBuffP;
      theVR [1]  = (char) *(theBuffP + 1);
      theVR [2]  = '\0';
      theBuffP   = (unsigned char *) &theBuff [0];
      theBufPos += 2;
      
      /* get the element length depending on the VR */
      if (	(theVR[0] == 'O' && theVR[1] == 'B') ||
			(theVR[0] == 'O' && theVR[1] == 'W') || 
			(theVR[0] == 'S' && theVR[1] == 'Q') || 
			(theVR[0] == 'U' && theVR[1] == 'N') || 
			(theVR[0] == 'U' && theVR[1] == 'T'))
      {

        /* read 4 more bytes */
        i = 4L;
        if (Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP) < 0)
        {
			Papy3FClose (&(gPapyFile [inFileNb]));
			RETURN (papReadFile)
        } /* if */
        *ioSeqLengthP += 4L;
        theBufPos = 0L;
        theElemLength = Extract4Bytes (theBuffP, &theBufPos);
      }
      else
        theElemLength = (PapyULong) Extract2Bytes (theBuffP, &theBufPos); 
    } /* else ...EXPLICIT VR */
    
    /* is it the sequence delimiter ? */
    if (!((theGrNb == 0xFFFE) && (theElemNb == 0xE0DD) && (theElemLength == 0L)))
    {
      /* if the element has an undefined length (i.e. item of undefined length */
      if (theElemLength == 0xFFFFFFFF)
      {
        theElemLength = 0L;
        if ((theErr = (int) ComputeUndefinedItemLength3 (inFileNb, &theElemLength)) < 0)
          RETURN (theErr);
      } /* if */

      *ioSeqLengthP += theElemLength;
    
      /* move the file pointer */
      Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) theElemLength);
    } /* if ...not sequence delimiter */
    else OK = TRUE;
    
  } /* while ...looking for the end of the sequence */
  
  /* reset the file pointer to its previous position */
  Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theFileStartPos);
  
  return 0;
  
} /* endof ComputeUndefinedSequenceLength3 */



/********************************************************************************/
/*										*/
/*	ComputeUndefinedGroupLength3 : compute the size of a group of undefined	*/
/*	length, starting from the current file position.			*/
/*	return : the size of the group if OK					*/
/*		 else standard error message					*/
/*										*/
/********************************************************************************/

PapyULong
ComputeUndefinedGroupLength3 (PapyShort inFileNb, PapyLong inMaxSize)
{
  PapyULong	theGroupLength, theElemLength, theBufPos, theFileStartPos, i;
  PapyUShort	theGrNb, theCmpGrNb, theElemNb, theCmpElemNb;
  PapyShort	theErr;
  char		theVR [3];
  unsigned char	*theBuffP, theBuff [8];
  int		OK;
  
  
  /* initializations */
  if (inMaxSize == -1) inMaxSize = 1000000; /* arbitrary value */
  theGroupLength  = 0L;
  Papy3FTell (gPapyFile [inFileNb], (PapyLong *) &theFileStartPos);
  theBuffP = (unsigned char *) &theBuff [0];
  
  /* read the group number and the element number from the file */
  i = 4L;
  if ((theErr = (PapyShort) Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP)) < 0)
  {
    theErr = (PapyShort) Papy3FClose (&(gPapyFile [inFileNb]));
    RETURN (papReadFile)
  } /* if */

  /* get the group number and the element number */
  theBufPos 	= 0L;
  theGrNb       = Extract2Bytes (theBuffP, &theBufPos);
  theElemNb     = Extract2Bytes (theBuffP, &theBufPos);
  
  /* set some comparison variables */
  theCmpGrNb   	= theGrNb;
  theCmpElemNb 	= theElemNb;
  
  /* reset the file pointer to its previous position */
  Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theFileStartPos);

  /* loop on the elements of the group */
  OK = FALSE;
  while (!OK)
  {
    /* read the file until the element length value */
    i = 8L;
    if ((theErr = (PapyShort) Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP)) < 0)
    {
      theErr = (PapyShort) Papy3FClose (&(gPapyFile [inFileNb]));
	  printf("ComputeUndefinedGroupLength3\rError\r");
      return 0;
    } /* if */
    
    theGroupLength += 8L;

    /* get the group number, the element number and the element length */
    theBufPos = 0L;
    theGrNb       = Extract2Bytes (theBuffP, &theBufPos);
    theElemNb     = Extract2Bytes (theBuffP, &theBufPos);
    
    /* reset the VR ... */
    theVR [0] = 'A'; theVR [1] = 'A';

    /* extract the element length depending on the syntax */
    if ((gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_IMPL && theGrNb != 0x0002) ||
        (theGrNb == 0xFFFE && theElemNb == 0xE000) ||
        (theGrNb == 0xFFFE && theElemNb == 0xE00D))
       theElemLength = Extract4Bytes (theBuffP, &theBufPos);
    else
    {
      /* extract the VR */
      theBuffP  += theBufPos;
      theVR [0]  = (char) *theBuffP;
      theVR [1]  = (char) *(theBuffP + 1);
      theBuffP   = (unsigned char *) &theBuff [0];
      theBufPos += 2;
      
      /* get the element length depending on the VR */
      if (	(theVR[0] == 'O' && theVR[1] == 'B') ||
			(theVR[0] == 'O' && theVR[1] == 'W') || 
			(theVR[0] == 'S' && theVR[1] == 'Q') || 
			(theVR[0] == 'U' && theVR[1] == 'N') || 
			(theVR[0] == 'U' && theVR[1] == 'T'))
      {
        /* DICOMDIR : here is the record sequence*/
        if (theGrNb == 0x0004 && theElemNb == 0x1220)
        {
          i = 6L;
          /* read 6 more bytes: 2(elem) 4(value unuseful) */
          if (Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP) < 0)
          {
            Papy3FClose (&(gPapyFile [inFileNb]));
            RETURN (papReadFile)
          } /* if */
          theGroupLength -= 8L;
          theElemLength = 0L;
          OK = TRUE;
        } /* if ...elem = 0x0004, 0x1220 */
        else
        {
          /* read 4 more bytes */
          i = 4L;
          if (Papy3FRead (gPapyFile [inFileNb], &i, 1L, theBuffP) < 0)
          {
            Papy3FClose (&(gPapyFile [inFileNb]));
            RETURN (papReadFile)
          } /* if */
          theGroupLength += 4L;
          theBufPos       = 0L;
          theElemLength   = Extract4Bytes (theBuffP, &theBufPos);
        } /* else ...elem not 0x0004, 0x1220 */
      } /* if ...VR = OB, OW, SQ, Un or UT */
      else
        theElemLength = (PapyULong) Extract2Bytes (theBuffP, &theBufPos); 
    } /* else ...EXPLICIT VR */
    
    /* makes sure the element belongs to the group */
    if (theCmpGrNb == theGrNb && theCmpElemNb <= theElemNb && theGroupLength < (PapyULong) inMaxSize)
    {
      /* if the element has an undefined length (i.e. VR = SQ) */
      if (theElemLength == 0xFFFFFFFF)
      {
        theElemLength = 0L;
        if ((theErr = ComputeUndefinedSequenceLength3 (inFileNb, &theElemLength)) < 0)
          RETURN ((PapyULong) theErr);
      } /* if */
      
      /* add the size of the element to the group size */
      theGroupLength += theElemLength;
      
      /* move the file pointer */
      if ((theErr = Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_CUR, (PapyLong) theElemLength)) < 0)
        RETURN ((PapyULong) theErr);
    } /* if ...element in group */
    else
    {
		OK = TRUE;
		theGroupLength -= 8L;
		
       if (	(theVR[0] == 'O' && theVR[1] == 'B') ||
			(theVR[0] == 'O' && theVR[1] == 'W') || 
			(theVR[0] == 'S' && theVR[1] == 'Q') || 
			(theVR[0] == 'U' && theVR[1] == 'N') || 
			(theVR[0] == 'U' && theVR[1] == 'T'))
			 // ANTOINE: UN et UT RAJOUTE!
        theGroupLength -= 4L;
    } /* else ...end of group reached */
    
  } /* while ...loop on the elem of the group */
  
  /* reset the file position to the begining of the group */
  Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theFileStartPos);
  
  return theGroupLength;

} /* endof ComputeUndefinedGroupLength3 */


