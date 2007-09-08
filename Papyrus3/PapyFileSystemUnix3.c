/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyFileSystemUnix3.c                                        */
/*	Function : contains machine specific calls to the different file systems*/
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
/*	         All Rights Reserved                                            */
/*                                                                              */
/********************************************************************************/

/* ------------------------- includes ------------------------------------------*/

#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>		/* open */


#ifndef _WINDOWS
#ifndef Mac
#ifdef hpux
#include <sys/unistd.h>
#else
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/stat.h>
#include <unistd.h>
#endif
#endif
#endif

#include "PapyTypeDef3.h"
#include "PapyEalloc3.h"

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#ifndef __PapyError3__
#include "PapyError3.h"
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
  int         err;
  PAPY_FILE   file;
  
  if ((file = fopen (inFilenameP, "rb")) != NULL)
  {
    (void) fclose (file);
    RETURN (papFileAlreadyExist);
  }

  if ((file = fopen (inFilenameP, "wb")) == NULL)
    RETURN (papFileCreationFailed);

  (void) fclose (file);
    
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
/* inPermission r : read, w : write, a : read/write (all) */
{
  PAPY_FILE    file;

  switch (inPermission) {
    case 'r' : if ((*outFp = fopen (inFilenameP, "rb")) == NULL) 
                 RETURN (papOpenFile);
               break;
    case 'w' : if ((*outFp = fopen (inFilenameP, "wb")) == NULL) 
                 RETURN (papOpenFile);               
               break;
    case 'a' : 
    default  : if ((*outFp = fopen (inFilenameP, "r+")) == NULL) 
                 RETURN (papOpenFile);
  }/* endsandwich */

  /*outFp = &file;*/

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
  fclose (*inFp);
  
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



/********************************************************************************/
/*										*/
/*	Papy3FRead : overwrites the standard read from file function		*/
/*	return : error (0 if OK, negative value otherwise)			*/
/*										*/
/********************************************************************************/

PapyShort
Papy3FRead (PAPY_FILE inFp, PapyULong *ioBytesToReadP, PapyULong inNb, void *ioBufferP)
{
  long  packets = 0;
  
  packets = (PapyShort)(fread ((char *) ioBufferP, (size_t) *ioBytesToReadP, inNb, inFp));
  if (packets != inNb)
  {
	if( feof(inFp) != 0)
	{
		if( packets == 0) return -1;
		else return 0;
	}
	else
	{
		return -1;
	}
   }
  else return 0;

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
  PapyShort  err = 0;
  
  err = (PapyShort)(fwrite ((char *) outBufferP, (int)*ioBytesToWriteP, inNb, inFp));

  return err;

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
  PapyLong startPos, fileLimit;
  long     err;

//  if (inOffset > 1000000L)			// THIS IS EXTREMELY SLOW....
//  {
//    startPos = (PapyLong) ftell (inFp);
//    /* get the end of file */
//    err = fseek (inFp, 0L, (int) SEEK_END);
//    fileLimit = (PapyLong) ftell (inFp);
//    if (inOffset > fileLimit) return -1;  
//    err = fseek (inFp, (long) startPos, (int) SEEK_SET);
//  }

//	startPos = (PapyLong) ftell (inFp);

  err = fseek (inFp, (long) inOffset, inPosMode);
  
  return err;

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
  int err = 0;
  
  *outFilePosP = (PapyLong) ftell (inFp);
  
  return err;

} /* endof Papy3FTell */


/********************************************************************************/
/*									 	*/
/*	Papy3FPrint : Papyrus function to set a string.				*/
/*										*/
/********************************************************************************/

void
Papy3FPrint (char *inStringP, char *inFormatP, int inValue)
{
  
  sprintf (inStringP, inFormatP, inValue);
        
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

  struct stat     *aStatStruct;
  struct dirent   *aDirent;
  DIR             *aDIR;
  
  aStatStruct =  (struct stat*)emalloc3(sizeof(struct stat));
  aDirent =      (struct dirent*)emalloc3(sizeof(struct dirent));
  aDIR=         (DIR*)emalloc3(sizeof(DIR));


  aDIR = opendir(dicomPath);

  /* read all the filenames of the directory. */	
  while((aDirent=readdir(aDIR))!=NULL)
  {
    if((strncmp(aDirent->d_name,".",1)!=0) && (strncmp(aDirent->d_name,"..",2)!=0))
      (*nbFiles)++;
  }
  closedir(aDIR);

  efree3 ((void **) &aStatStruct);
  efree3 ((void **) &aDirent);
  efree3 ((void **) &aDIR);
  
} /* endof Papy3DGetNbFiles */
