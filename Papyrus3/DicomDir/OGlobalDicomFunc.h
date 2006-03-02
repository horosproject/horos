#ifndef OGlobalDicomFuncH
#define OGlobalDicomFuncH
// *************************************************************************** 
// *************************************************************************** 
//
//                      OGlobalDicomFunc
//
// ****************************************************************************
// ****************************************************************************
//
//  FILENAME	:	OGlobalDicomFunc.h
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

// converts a DICOM stored date to a standard one
extern void DicomDateToDate (char *, char *);

// converts a DICOM stored time to a standard one
extern void DicomTimeToTime (char *, char *);

// converts a DICOM stored name to a standard one
extern void DicomNameToName (char *, char *);

#endif // ifndef OGlobalDicomFuncH