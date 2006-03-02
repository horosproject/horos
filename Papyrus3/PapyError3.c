/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyError3.c                                                 */
/*	Function : error management                                             */
/*	Authors  : Jean-Francois Vurlod	                                        */
/*                 Christian Girard                                             */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 06.1993	version 2.0                                     */
/*                 06.1994	version 3.0                                     */
/*                 06.1995	version 3.1                                     */
/*                 02.1996	version 3.3                                     */
/*                 02.1999	version 3.6                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7   on CVS                            */
/*                 10.2001      version 3.71  MAJ Dicom par CHG                 */
/*                                                                              */
/* 	(C) 1990-2001 The University Hospital of Geneva                         */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/

#include <stdio.h>

#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#ifndef PapyError3H
#include "PapyError3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif

#ifndef PapyError3H
#include "PAPERR3.h"
#endif

#endif 				/* FILENAME83 defined */


#define 		kMax_Error_Level	10

static char		sERRMSG[]	= "Error detected in library Papyrus 3";
static int		sExitWhenError	= TRUE;
static int		sCrtErrLevel	= -1;
EPapyError3		gPapyErrNo	= papNoError;
EPapyError3		gFirstError	= papNoError;
int			gPapyErrLigne 	[kMax_Error_Level];
char			*gPapyErrFileP 	[kMax_Error_Level];



/* 	enumeration of the error messages	*/


char	*PapyErrorList [] =
    {
/*  0 */"No error",
/* -1 */"See the error # in the var gPapyErrNo",
/* -2 */"Not implemented",
/* -3 */"Standard C library error",
/* -4 */"Not enough memory",
/* -5 */"UID unknow",
/* -6 */"Read group failed",
/* -7 */"Write group failed",
/* -8 */"Overlay is not in the interval [0x6000,0x601E]",
/* -9 */"UINOverlay is not in the interval [0x6001,0x6FFF]",
/*-10 */"All element of type 1 must be filled",
/*-11 */"Missing a group 0x0008",
/*-12 */"Image file name not defined",
/*-13 */"The length of the string is not even",
/*-14 */"Internal problem in Value",
/*-15 */"Internal problem in Ascii",
/*-16 */"Internal problem in Def",
/*-17 */"You want to write too many images",
/*-18 */"Enum group",
/*-19 */"Array index is greater than the size of the array",
/*-20 */"Create a papyrus file with 0 image",
/*-21 */"The maximum number of open file as been reached",
/*-22 */"The file already exist",
/*-23 */"File creation failed",
/*-24 */"Opening file in read only mode failed",
/*-25 */"Reserved 25",
/*-26 */"Reserved 26",
/*-27 */"Reserved 27",
/*-28 */"Reserved 28",
/*-29 */"Not found",
/*-30 */"Open file",
/*-31 */"Close file",
/*-32 */"Reading data in the file failed",
/*-33 */"Write file",
/*-34 */"The filename is not correct",
/*-35 */"Positioning pointer in the file failed",
/*-36 */"Wrong element number",
/*-37 */"Wrong element size",
/*-38 */"Group error",
/*-39 */"Group number",
/*-40 */"Bad argument",
/*-41 */"Error in list",
/*-42 */"This transfert syntax is not implemented",
/*-43 */"This compression algorithm is not yet implemented ",
/*-44 */"Unknown imaging modality",
/*-45 */"Mandatory module missing",
/*-46 */"Not a Papyrus file",
/*-47 */"Deleting file failed",
/*-48 */"A wrong value has been found in the file",
/*-49 */"The version of this file is newer than the version of the PAPYRUS toolkit"
    };


static char *sPapyErrorDecoP = "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n";


/******************************************************************************/
/*									      */
/*	PapyPrintErrMsg3 : this function prints the error messages to the     */
/*	standard error device						      */
/*	return : /							      */
/*									      */
/******************************************************************************/

void PapyPrintErrMsg3 (char *inFileP, PapyShort inLine)
{
#ifndef DLL
    PapyShort	i, theMax, theNb = 0;

    fprintf (stderr, sPapyErrorDecoP);
    if (sCrtErrLevel >= 0)
    {
	fprintf (stderr, "%s\n", sERRMSG);
	fprintf (stderr, "File : %s\nLine : %d\n", inFileP, inLine);
	
	if (sCrtErrLevel >= kMax_Error_Level)
	{
	    fprintf (stderr, "... .. .\n");
	    theMax = kMax_Error_Level - 1;
	}
	else
	    theMax = sCrtErrLevel;

	for (i = theMax; i >= 0; i--)
	{
	    static char	StrEmpty [] = "";
	    theNb += 2;
            fprintf(stderr,"%*sFile : %s\n%*sLine : %d\n",
                        theNb, StrEmpty,
                        gPapyErrFileP [i],
                        theNb, StrEmpty,
                        gPapyErrLigne [i]);
	    
	} /* for */

	if ((gPapyErrNo > papLastErrorNb) && (gPapyErrNo <= 0))
	    fprintf (stderr, "\nError : %s\n", PapyErrorList [-gPapyErrNo]);
	else
	    fprintf (stderr, "\nError : %d\n", gPapyErrNo);
    } /* if ...sCrtErrLevel >= 0 */
    else
	fprintf (stderr, "No e%s\n", &sERRMSG [1]);
	
    fprintf (stderr, sPapyErrorDecoP);
#endif
    
} /* endof PapyPrintErrMsg3 */


/******************************************************************************/
/*									      */
/*	PAPY3PRINTERRMSG : this function interfaces the error messages for    */
/*	Papy3PrintErrMsg						      */
/*	return : /							      */
/*									      */
/******************************************************************************/

void CALLINGCONV
PAPY3PRINTERRMSG ()
{
#if qDebug
    PapyPrintErrMsg3 (__FILE__, __LINE__);
#endif
}


/******************************************************************************/
/*									      */
/*	Papy3CheckError : this function checks in which file and in which line */
/*	the given error has occurred					      */
/*	return : /							      */
/*									      */
/******************************************************************************/

void Papy3CheckError (int inCodeErr, char *inFileP, int inLine)
{
    if (inCodeErr > 0)
    {
	sCrtErrLevel = -1;
	return;
    }
    gPapyErrNo = (EPapyError3) inCodeErr;
    if (gPapyErrNo)
    {
	sCrtErrLevel++;
	if (sCrtErrLevel < kMax_Error_Level)
	{
	    if (!sCrtErrLevel) gFirstError = gPapyErrNo;
	    gPapyErrLigne [sCrtErrLevel] = inLine;
	    gPapyErrFileP [sCrtErrLevel] = inFileP;
	}
    }
    else
	sCrtErrLevel = -1;
	
} /* endof Papy3CheckError */
