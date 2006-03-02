/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyFileSystemPC3.c                                          */
/*	Function : contain specific reading/writing fcts for all kind           */
/*                 of architecture                                              */
/*	Authors  : Christian Girard                                             */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 06.1995	version 3.1                                     */
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


/* ------------------------- includes ----------------------------------------*/

#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>              /* open */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifdef _WINDOWS
#include <windows.h>
#endif

#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyFileSystem3H
#include "PapyFileSystem3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PapyDef3.h"
#endif

#ifndef __PapyError3__
#include "PAPERR3.h"
#endif

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
  if ((*inFp = _open (inFilenameP, _O_RDONLY)) != -1)
  {
    (void) _close (*inFp);
    RETURN (papFileAlreadyExist);
  }
       
  if ((*inFp = _open (inFilenameP, _O_WRONLY | _O_CREAT | _O_BINARY, _S_IREAD | _S_IWRITE )) == -1)   
    RETURN (papFileCreationFailed);

  (void) _close (*inFp);

  return 0;

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
{
  long  pos;

  switch (inPermission)
  {
    case 'r' : 
      if ((*outFp = _open (inFilenameP, _O_RDONLY | _O_BINARY)) == -1) 
        RETURN (papOpenFile);
      break;
    case 'w' : 
    default  :
      if ((*outFp = _open (inFilenameP, _O_WRONLY | _O_CREAT | _O_BINARY, _S_IREAD | _S_IWRITE)) == -1) 
        RETURN (papOpenFile);
      break;
  }    
  
  pos = _lseek(*outFp, 0L, SEEK_SET);
  if (pos == -1L) 
    return -1;
      
  return 0;

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
  _close (*inFp);

  return 0;
  
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
  return (unlink ((char *) inFilenameP));

} /* endof Papy3FDelete */


/******************************************************************************/
/*									      */
/*	Papy3FRead : rewrite the standard fread function		      */
/*	return : the numbers of reading bytes				      */
/*									      */
/******************************************************************************/

PapyShort
Papy3FRead (PAPY_FILE inFp, PapyULong *ioBytesToReadP, PapyULong inNb, void *ioBufferP)
{
 unsigned int max_size = (unsigned int)*ioBytesToReadP * (unsigned int)inNb;
 int          bytesRead = -1;

 if (max_size > 0)
 {
   bytesRead = _read (inFp, (void *)ioBufferP, max_size);

   if (bytesRead <= 0) return -1;
 }

 return 0;

} /* endof Papy3FRead */


/******************************************************************************/
/*									      */
/*	Papy3FWrite : rewrite the standard fwrite function		      */
/*	return : the numbers of writing bytes				      */
/*									      */
/******************************************************************************/

PapyShort
Papy3FWrite (PAPY_FILE inFp, PapyULong *ioBytesToWriteP, PapyULong inNb, void *outBufferP)
{
 unsigned int max_size = (unsigned int)*ioBytesToWriteP * (unsigned int)inNb;
 int          bytesWrite = -1;
 
 bytesWrite = _write (inFp, (const void *)outBufferP, max_size);

 if (bytesWrite < 0)
   return -1;

 return 0;

} /* endof Papy3FWrite */


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
  int err = 0;
	
  *outFilePosP = (long) _tell(inFp);

  if( *outFilePosP < 0 )  
    return -1;

  return err;

} /* endof Papy3FTell */

/********************************************************************************/
/*									 	*/
/*	Papy3FSeek : Papyrus own build file pointer positioning function.	*/
/*	return : standard error message						*/
/*										*/
/********************************************************************************/

int
Papy3FSeek (PAPY_FILE inFp, int inPosMode, PapyLong inOffset)
{
  PapyLong	startPos, fileLimit;
  long			err;
  
  /*if (inOffset == 0L) return 0;*/

  if (inOffset > 100000L) 
  {
    Papy3FTell (inFp, (PapyLong *) &startPos);
 
    /* get the end of file */
    err = _lseek (inFp, 0L, SEEK_END);
	
    err = Papy3FTell (inFp, (PapyLong *) &fileLimit);
    if (inOffset > fileLimit) return -1;

    err = _lseek (inFp, (long) startPos, SEEK_SET);
  }

  if ((err = _lseek (inFp, (long) inOffset, inPosMode)) == -1L) 
    return -1;
  
  return 0;

} /* endof Papy3FSeek */



/********************************************************************************/
/*									 	*/
/*	Papy3FPrint : Papyrus function to set a string.				*/
/*										*/
/********************************************************************************/

void
Papy3FPrint (char *inStringP, char *inFormatP, int inValue)
{
  
  wsprintf (inStringP, inFormatP, inValue);
        
} /* endof Papy3FPrint */



/********************************************************************************/
/*									 	*/
/*	Papy3DGetNbFiles : Papyrus function to parse the directory and          */
/*                         return the number of files.				*/
/*										*/
/********************************************************************************/

int
Papy3DGetNbFiles (char *dicomPath, int *nbFiles)
{

  HANDLE          dp;
  WIN32_FIND_DATA wfd; 

  char buff [256];
  GetCurrentDirectory (256, buff);
  if (!SetCurrentDirectory (dicomPath))
  {
    fprintf (stderr, "opendir failed on %s\n", dicomPath);
    return (-1);
  } 

  /* read all the filenames of the directory. */
  dp = FindFirstFile ("*.*", &wfd);
  if (dp != INVALID_HANDLE_VALUE)
   do
    {
      if (!strcmp (wfd.cFileName, ".") || !strcmp (wfd.cFileName, ".."))
        continue;

      if (!( (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)==FILE_ATTRIBUTE_DIRECTORY ))
        (*nbFiles)++;

    } while (FindNextFile (dp, &wfd));
	
  if (dp != INVALID_HANDLE_VALUE)
    FindClose (dp);
        
  SetCurrentDirectory (buff);

} /* endof Papy3DGetNbFiles */
