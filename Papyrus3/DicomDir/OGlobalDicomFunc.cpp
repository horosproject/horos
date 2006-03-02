// *************************************************************************** 
// *************************************************************************** 
//
//                      OGlobalDicomFunc
//
// ****************************************************************************
// ****************************************************************************
//
//  FILENAME	:	OGlobalDicomFunc.cpp
//
//  CLASSES	:	none
//  
//  DESCRIPTION	:	Utility routines for DICOM type conversion.
//
//  HISTORY     :       24-02-99	CHG creation
//
//  Copyright 1999 by UIN/HCUG, All rights reserved.
// ****************************************************************************
// ****************************************************************************

// *****************************************************************************
// ***          INCLUDES
// *****************************************************************************
   
#include <string.h>


// *****************************************************************************
// ***          DicomDateToDate
// *****************************************************************************

void DicomDateToDate (char *inChar, char *outChar)
// converts the date introduced in DICOM files in something more displayable
{
  strcpy (outChar, inChar);
  if (outChar [4] != '.') 	// new style
  {
    outChar [4] = '.';
    outChar [5] = inChar [4];
    outChar [6] = inChar [5];
    outChar [7] = '.';
    outChar [8] = inChar [6];
    outChar [9] = inChar [7];
    outChar [10] = '\0';
  } // if ...new style
  
} // endofmethod DicomDateToDate


// *****************************************************************************
// ***          DicomTimeToTime
// *****************************************************************************

void DicomTimeToTime (char *inChar, char *outChar)
// converts the date introduced in DICOM files in something more displayable
{
  strcpy (outChar, inChar);
  if (outChar [2] != ':')	// new style time
  {
    outChar [2] = ':';
    outChar [3] = inChar [2];
    outChar [4] = inChar [3];
    outChar [5] = ':';
    outChar [6] = inChar [4];
    outChar [7] = inChar [5];
    outChar [8] = '\0';
  } // if ...new style time
  
} // endofmethod DicomTimeToTime


// *****************************************************************************
// ***          DicomNameToName
// *****************************************************************************

void DicomNameToName (char *inChar, char *outChar)
// converts the date introduced in DICOM files in something more displayable
{
  long	lengthOfString, i;
  
  lengthOfString = (long) strlen (inChar);
  for (i = 0; i < lengthOfString; i++)
    if (inChar [i] == '^') outChar [i] = ' ';
    else outChar [i] = inChar [i];
  outChar [lengthOfString] = '\0';
  
} // endofmethod DicomNameToName
