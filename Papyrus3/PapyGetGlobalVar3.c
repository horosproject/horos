/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyGetGlobalVar3.c                                          */
/*	Function : functions that will get some important vars. This file has   */
/*	           been added to let the PCs compile DLL and still have access  */
/*	           to global variables.                                         */
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
/*	          All Rights Reserved                                           */
/*                                                                              */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif




/********************************************************************************/
/*										*/
/*	Papy3GetFile : gets the file pointer (machine) of the file given 	*/
/*	its Papyrus reference number.						*/
/*										*/
/********************************************************************************/

PAPY_FILE CALLINGCONV
Papy3GetFile (PapyShort inFileNb)
{
  return gPapyFile [inFileNb];
}


/********************************************************************************/
/*										*/
/*	Papy3GetCurrTmpFilename : gets the current name (iteration) allocated 	*/
/*	to the temp file.							*/
/*										*/
/********************************************************************************/

int CALLINGCONV
Papy3GetCurrTmpFilename (PapyShort inFileNb)
{
  return gCurrTmpFilename [inFileNb];
}


/********************************************************************************/
/*										*/
/*	Papy3GetNbImages : gets the number of images of the given file.		*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GetNbImages (PapyShort inFileNb)
{
  return gArrNbImages [inFileNb];
}


/********************************************************************************/
/*										*/
/*	Papy3GetTransfSyntax : gets the syntax used by the given file.		*/
/*										*/
/********************************************************************************/

enum ETransf_Syntax CALLINGCONV
Papy3GetTransfSyntax (PapyShort inFileNb)
{
  return gArrTransfSyntax [inFileNb];
}


/********************************************************************************/
/*										*/
/*	Papy3GetModality : gets the modality of the images of the given file.	*/
/*										*/
/********************************************************************************/

int CALLINGCONV
Papy3GetModality (PapyShort inFileNb)
{
  return gFileModality [inFileNb];
}


/********************************************************************************/
/*										*/
/*	Papy3GetNbElemInModule : gets the number of elements in the given module*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GetNbElemInModule (int moduleId)
{
  return gArrModule [moduleId];
}


/********************************************************************************/
/*										*/
/*	Papy3GetFileKind : gets the kind of file (0 = DICOM part 10 file, 	*/
/*	1 = PAPYRUS 3.X file, 2 = DICOM non-part 10 file			*/
/*										*/
/********************************************************************************/

int CALLINGCONV
Papy3GetFileKind (int inFileNb)
{
  return gIsPapyFile [inFileNb];
}


/********************************************************************************/
/*										*/
/*	Papy3GetToolkitVersion : gets the current version of the toolkit	*/
/*										*/
/********************************************************************************/

char* CALLINGCONV
Papy3GetToolkitVersion ()
{
  return gPapyrusVersion;
}


/********************************************************************************/
/*										*/
/*	Papy3GetCompression : gets the compression algorithm used for the file	*/
/*										*/
/********************************************************************************/

enum EPap_Compression CALLINGCONV
Papy3GetCompression (PapyShort inFileNb)
{
  return gArrCompression [inFileNb];
}
