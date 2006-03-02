/********************************************************************************/
/*				                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyFileSystemMac3.c                                         */
/*	Function : contain specific reading/writing fcts for all kind           */
/*                 of architecture                                              */
/*	Authors  : Christian Girard                                             */
/*             	   Marianne Logean                                              */
/*                 Dominique Blot                                               */
/*                                                                              */
/*	History  : 06.1995	version 3.1                                     */
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

/* ------------------------- includes ------------------------------------------*/

#include <Files.h>
#include <string.h>
#include <Script.h>

#ifndef PapyFileSystem3H
#include "PapyFileSystem3.h"
#endif


/********************************************************************************/
/*										*/
/*	Papy3FCreate : overwrites the standard create file function		*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FCreate (char *inFilenameP, PAPY_FILE inVolume, PAPY_FILE *inFp, void **inFSSpecP)
{
  int			theErr;
  FSSpec		*theFSSpecP;
  
  /* foo assignation to a foo var */
  inFp = inFp; 
  
  if ((inFSSpecP != NULL) && (*inFSSpecP != NULL))
     theFSSpecP = (FSSpec *) *inFSSpecP;
  else {
     /* create the FSSpec ptr */
     theFSSpecP = (FSSpec *) emalloc3 ((PapyULong) sizeof (FSSpec));
 
  if (inVolume >= 0)
    theFSSpecP->vRefNum = inVolume;
  else
    theFSSpecP->vRefNum = - LMGetSFSaveDisk ();
  theFSSpecP->parID = LMGetCurDirStore ();
  /* test the length of the filename (should not be greater than 64 on the Mac) */
  /* so if it is longer the filename is truncated */
  if (strlen (inFilenameP) > 64) inFilenameP [63] = '\0';
  strcpy ((char *) theFSSpecP->name, inFilenameP);
  c2pstr ((char *) theFSSpecP->name);
  } /* else */
   
  
  
  /* create the file */
  theErr = FSpCreate (theFSSpecP, 'OSIR', 'PAPY', smSystemScript);
  
  if ((inFSSpecP != NULL) && (*inFSSpecP == NULL))
     *inFSSpecP = theFSSpecP;
  else efree3 (&theFSSpecP);

  return theErr;

} /* endof Papy3FCreate */


/********************************************************************************/
/*										*/
/*	Papy3FOpen : overwrites the standard open file function			*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort
Papy3FOpen (char *inFilenameP, char inPermission, PAPY_FILE inVolumeNb, PAPY_FILE *outFp, 
	          void *inFSSpecP)
/* permission r : read, w : write, a : read/write (all) */
{
  PapyShort		theErr;
  FSSpec		*theFSSpecP;
  
  
  if (inFSSpecP == NULL)
  {
    /* create the FSSpec ptr */
    theFSSpecP = (FSSpec *) emalloc3 ((PapyULong) sizeof (FSSpec));

    /* in case of full pathname BLO, I suppose (!) that inFilenameP is a c-string */
    if (inVolumeNb == 0) 
    {
      c2pstr ((char *) inFilenameP);
      theErr = FSMakeFSSpec (0, 0, (unsigned char*) inFilenameP, theFSSpecP);
      p2cstr ((unsigned char *) inFilenameP);
    } /* if */
    else 
    {
      /* fill in the FSSpec structure */
      theFSSpecP->vRefNum = inVolumeNb;
      theFSSpecP->parID   = LMGetCurDirStore ();
      strcpy ((char *) theFSSpecP->name, inFilenameP);
      c2pstr ((char *) theFSSpecP->name);
    } /* else */
  } /* if */
  else theFSSpecP = (FSSpec *) *((void**) inFSSpecP);
  
  /* open the file */
  switch (inPermission) 
  {
    case 'r' : 
      theErr = (PapyShort) FSpOpenDF (theFSSpecP, fsRdPerm, outFp);
      break;
    case 'w' : 
      theErr = (PapyShort) FSpOpenDF (theFSSpecP, fsWrPerm, outFp); 
      break;
    case 'a' : 
    default  : 
      theErr = (PapyShort) FSpOpenDF (theFSSpecP, fsRdWrPerm, outFp);
  } /* switch */
  
  if (inFSSpecP == NULL) efree3 (&theFSSpecP);

  return theErr;

} /* endof Papy3FOpen */


/********************************************************************************/
/*										*/
/*	Papy3FClose : overwrites the standard close file function		*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FClose (PAPY_FILE *inFp)
{
  int		theErr;
  
  
  theErr = FSClose (*inFp);

  return theErr;

} /* endof Papy3FClose */


/********************************************************************************/
/*										*/
/*	Papy3FDelete : overwrites the standard delete file function		*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FDelete (char *inFilenameP, void *inIdentifierP)
{
  int		theErr;
  
  
  /* foo use of a foo var */
  inFilenameP = inFilenameP;
  
  theErr = FSpDelete ((const FSSpec *) inIdentifierP);

  return theErr;

} /* endof Papy3FDelete */


/********************************************************************************/
/*										*/
/*	Papy3FRead : overwrites the standard read from file function		*/
/*	return : error (0 if OK, negative value otherwise)			*/
/*										*/
/********************************************************************************/

PapyShort
Papy3FRead (PAPY_FILE inFp, PapyULong *ioBytesToReadP, PapyULong inNb, void *ioBufferP)
{
  HIOParam   	ptrParm;
  PapyShort     theErr;
  
  
  /* foo use of a foo var */
  inNb = inNb;
  
  ptrParm.ioRefNum   = (short) inFp;
  ptrParm.ioBuffer   = (Ptr) ioBufferP;
  ptrParm.ioReqCount = (long) *ioBytesToReadP;
  ptrParm.ioPosMode  = fsAtMark;
  theErr = (PapyShort) PBRead ((ParmBlkPtr) &ptrParm, FALSE);

  return theErr;

} /* endof Papy3FRead */


/********************************************************************************/
/*									 	*/
/*	Papy3FWrite : overwrite the standard write to file function		*/
/*	return : error (0 if OK, negative value otherwise)			*/
/*										*/
/********************************************************************************/

PapyShort
Papy3FWrite (PAPY_FILE inFp, PapyULong *ioBytesToWriteP, PapyULong inNb, void *outBufferP)
{
  HIOParam   	ptrParm;
  PapyShort	theErr;
  
  
  /* foo use of a foo var */
  inNb = inNb;
  
  ptrParm.ioRefNum   = (short) inFp;
  ptrParm.ioBuffer   = (Ptr) outBufferP;
  ptrParm.ioReqCount = (long) *ioBytesToWriteP;
  ptrParm.ioPosMode  = fsAtMark;
  theErr = (PapyShort) PBWrite ((ParmBlkPtr) &ptrParm, FALSE);

  return theErr;

} /* endof Papy3FWrite */


/********************************************************************************/
/*									 	*/
/*	Papy3FSeek : Papyrus own build file pointer positioning function.	*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FSeek (PAPY_FILE inFp, int inPosMode, PapyLong inOffset)
{
  int	theErr;
  short	macPosMode;
  
  switch (inPosMode)
  {
    case SEEK_SET :
      macPosMode = fsFromStart;
      break;
    case SEEK_CUR :
      macPosMode = fsFromMark;
      break;
    case SEEK_END :
      macPosMode = fsFromLEOF;
      break;
  }
  
  theErr = SetFPos (inFp, macPosMode, (long) inOffset);
  return theErr;

} /* endof Papy3FSeek */


/********************************************************************************/
/*									 	*/
/*	Papy3FTell : Papyrus function to get the current position of the file	*/
/*	pointer.								*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FTell (PAPY_FILE inFp, PapyLong *outFilePosP)
{
  int theErr;
  
  theErr = GetFPos (inFp, (long *) outFilePosP);
  return theErr;

} /* endof Papy3FTell */


/********************************************************************************/
/*									 	*/
/*	Papy3FPrint : Papyrus function to set a string				*/
/*										*/
/********************************************************************************/

void
Papy3FPrint (char *inStringP, char *inFormatP, int inValue)
{
  sprintf (inStringP, inFormatP, inValue);

} /* endof Papy3FPrint */
