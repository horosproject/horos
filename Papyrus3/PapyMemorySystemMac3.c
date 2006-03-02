/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyMemorySystemMac3.c                                       */
/*	Function : contains machine specific calls to the different file systems*/
/*	Authors  : Antoine ROSSET                                               */
/*                                                                              */
/*	History  : 02.1998	version 3.1                                     */
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

#ifndef PapyMemorySystemMac3H
#include "PapyMemorySystemMac3.h"
#endif

typedef struct SPapyMemStruct
{
  Ptr 		mFileP;
  long		mFilePos, mFileSize;
  PAPY_FILE	mvRefNum;
  HIOParam  	mPtrParm;
} SPapyMemStruct;

static SPapyMemStruct	thePapMemStruct [200];	/* Maximum of 200 files open */
static short		theListSize = 0;



/********************************************************************************/
/*										*/
/*	Papy3LoadFileMem 							*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort Papy3LoadFileMem (PAPY_FILE inVRefNum)
{
  OSErr		theErr;
  
  
  theErr = (PapyShort) GetEOF (inVRefNum, &thePapMemStruct [theListSize].mFileSize);
  
  /* thePapMemStruct [theListSize].mFileP = NewPtr (thePapMemStruct [theListSize].mFileSize);*/
  thePapMemStruct [theListSize].mFileP = (char *) emalloc3 ((PapyULong) thePapMemStruct [theListSize].mFileSize);
  if (thePapMemStruct [theListSize].mFileP == 0L) return -1;
  
  thePapMemStruct [theListSize].mPtrParm.ioRefNum   = (short) inVRefNum;
  thePapMemStruct [theListSize].mPtrParm.ioBuffer   = (Ptr)   thePapMemStruct [theListSize].mFileP;
  thePapMemStruct [theListSize].mPtrParm.ioReqCount = (long)  thePapMemStruct [theListSize].mFileSize;
  thePapMemStruct [theListSize].mPtrParm.ioPosMode  = fsFromStart;
  
  theErr = (PapyShort) PBRead ((ParmBlkPtr) &thePapMemStruct [theListSize].mPtrParm, TRUE);	/* Read in ASYNC ! */
  
  thePapMemStruct [theListSize].mFilePos = 0L;
  
  thePapMemStruct [theListSize].mvRefNum = inVRefNum;
  
  theListSize++;

 return noErr;
 
} /* endof Papy3LoadFileMem */


/********************************************************************************/
/*										*/
/*	Papy3SetMemPtr	 							*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

void Papy3SetMemPtr (PAPY_FILE inVRefNum, long inPos, long inSize, Ptr inPtr)
{
  short	i;
	
	
  for (i = 0; i < theListSize; i++)
  {
    if (thePapMemStruct [i].mvRefNum == inVRefNum)
    {
      if (inPtr == NULL)
      {
        thePapMemStruct [i].mFilePos  = 0L;
        thePapMemStruct [i].mFileSize = 0L;
        thePapMemStruct [i].mFileP    = 0L;
        thePapMemStruct [i].mvRefNum  = 0L;
      } /* if */
      else
      {
        thePapMemStruct [i].mFilePos  = inPos;
        thePapMemStruct [i].mFileSize = inSize;
        thePapMemStruct [i].mFileP    = inPtr;
      } /* else */
      
      return;
    } /* if ...inVRefNum */
  } /* for */
  
  DebugStr("\pNot found");
  
  return;
  
} /* endof Papy3SetMemPtr */


/********************************************************************************/
/*										*/
/*	Papy3GetMemPtr	 							*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

Ptr Papy3GetMemPtr (PAPY_FILE inVRefNum, long *ioPosP, long *ioSizeP, long *ActCount)
{
  short	i;
  
  for (i = 0; i < theListSize; i++)
  {
    if (thePapMemStruct [i].mvRefNum == inVRefNum)
    {
      if (ioPosP) *ioPosP     = thePapMemStruct [i].mFilePos;
      if (ioSizeP) *ioSizeP   = thePapMemStruct [i].mFileSize;
      if (ActCount) *ActCount = thePapMemStruct [i].mPtrParm.ioActCount;
      return thePapMemStruct [i].mFileP;
    } /* if */
  } /* for */
  
  return 0L;
  
} /* endof Papy3GetMemPtr */


/********************************************************************************/
/*										*/
/*	Papy3FLoadMem 								*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort Papy3FLoadMem (PAPY_FILE inVRefNum)
{
  PapyShort	theErr;
   
  
  if (Papy3GetMemPtr (inVRefNum, 0L, 0L, 0L)) Debugger();
  
  theErr = Papy3LoadFileMem (inVRefNum);
  if (theErr) DebugStr ("\pPapy3LoadFileMem Err");
  
  return theErr;
  
} /* endof Papy3FLoadMem */


/********************************************************************************/
/*										*/
/*	Papy3FOpenMem : overwrites the standard open file function		*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

PapyShort
Papy3FOpenMem (char *inFilenameP, char inPermission, PAPY_FILE inVolumeNb, PAPY_FILE *outFp, 
	       void *inFSSpecP)
/* permission r : read, w : write, a : read/write (all) */
{
  PapyShort		theErr;
  FSSpec		*theFSSpecP;
  
   
  if (inFSSpecP == NULL)
  {
    /* create the FSSpec ptr */
    theFSSpecP = (FSSpec *) emalloc3 ((PapyULong) sizeof (FSSpec));
 
    /* fill in the FSSpec structure */
    theFSSpecP->vRefNum = inVolumeNb;
    theFSSpecP->parID   = LMGetCurDirStore ();
    strcpy ((char *) theFSSpecP->name, inFilenameP);
    c2pstr ((char *) theFSSpecP->name);
  } /* if */
  else theFSSpecP = (FSSpec *) inFSSpecP;
  
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
  
  
  if (Papy3GetMemPtr (*outFp, 0L, 0L, 0L)) Debugger();
  
  theErr = Papy3LoadFileMem (*outFp);
  if (theErr) DebugStr ("\pPapy3LoadFileMem Err");
  
  if (inFSSpecP == NULL) efree3 (&theFSSpecP);
  
  return theErr;

} /* endof Papy3FOpenMem */


/********************************************************************************/
/*										*/
/*	Papy3FCloseMem : overwrites the standard close file function		*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FCloseMem (PAPY_FILE *ioFp)
{
  int		theErr;
  Ptr 		theFilePtr;
  long		theFilePos, theFileSize;
  
  
  theFilePtr = Papy3GetMemPtr (*ioFp, &theFilePos, &theFileSize, 0L);
  
  /*DisposePtr (theFilePtr);*/	
  efree3 ((void **) &theFilePtr);	
  theFilePtr = 0L;
  
  theErr = FSClose (*ioFp);

  Papy3SetMemPtr (*ioFp, theFilePos, theFileSize, theFilePtr);

  return theErr;

} /* endof Papy3FCloseMem */


/********************************************************************************/
/*										*/
/*	Papy3FReadMem : overwrites the standard read from file function		*/
/*	return : error (0 if OK, negative value otherwise)			*/
/*										*/
/********************************************************************************/

PapyShort Papy3FReadMem (PAPY_FILE inFp, PapyULong *inBytesToReadP, PapyULong inNb, 
    			 void **inBufferP, Boolean inNoMemTransfer)
{
  Ptr 		theFilePtr;
  long		theFilePos, theFileSize, theActCount;
  
  
  /* dummy instruction... */
  inNb = inNb;
  
  theFilePtr = Papy3GetMemPtr (inFp, &theFilePos, &theFileSize, &theActCount);
  
  /* Wait until the buffer is full to access this data */
  while (theFilePos + *inBytesToReadP > theActCount) Papy3GetMemPtr (inFp, 0L, 0L, &theActCount);
  
  if (inNoMemTransfer) 
    *inBufferP = theFilePtr + theFilePos;
  else 
    BlockMoveData (theFilePtr + theFilePos, *inBufferP, *inBytesToReadP);
  
  theFilePos += *inBytesToReadP;
  
  if (theFilePos > theFileSize) 
  { 
    Debugger();
    return EOF;
  } /* if */
  
  Papy3SetMemPtr (inFp, theFilePos, theFileSize, theFilePtr);
  
  return noErr;

} /* endof Papy3FReadMem */


/********************************************************************************/
/*									 	*/
/*	Papy3FSeekMem : Papyrus own build file pointer positioning function.	*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FSeekMem (PAPY_FILE inFp, int inPosMode, PapyLong inOffset)
{
  int		theErr = noErr;
  short		theMacPosMode;
  Ptr 		theFilePtr;
  long		theFilePos, theFileSize;
  
  
  theFilePtr = Papy3GetMemPtr (inFp, &theFilePos, &theFileSize, 0L);
  
  switch (inPosMode)
  {
    case SEEK_SET :
      theMacPosMode = fsFromStart;
      theFilePos    = inOffset;
      break;
    case SEEK_CUR :
      theMacPosMode = fsFromMark;
      theFilePos   += inOffset;
      break;
    case SEEK_END :
      theMacPosMode = fsFromLEOF;
      theFilePos    = theFileSize + inOffset;
      Debugger();
      break;
  } /* switch */
  
  Papy3SetMemPtr (inFp, theFilePos, theFileSize, theFilePtr);
  
  return theErr;

} /* endof Papy3FSeekMem */


/********************************************************************************/
/*									 	*/
/*	Papy3FTellMem : Papyrus function to get the current position of the file*/
/*	pointer.								*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FTellMem (PAPY_FILE inFp, PapyLong *outFilePosP)
{
  int 		theErr = noErr;
  Ptr 		theFilePtr;
  long		theFilePos, theFileSize;
  
  
  theFilePtr = Papy3GetMemPtr (inFp, &theFilePos, &theFileSize, 0L);
  
  *outFilePosP = theFilePos;
  
  return theErr;

} /* endof Papy3FTellMem */