/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "DicomStudy.h"

@interface DicomStudy (Report)

// report to pdf
+(void)transformReportAtPath:(NSString*)reportPath toPdfAtPath:(NSString*)outPdfPath;
-(void)saveReportAsPdfAtPath:(NSString*)path;
-(NSString*)saveReportAsPdfInTmp;

// pdf to dicom
+(void)transformPdfAtPath:(NSString*)pdfPath toDicomAtPath:(NSString*)outDicomPath usingSourceDicomAtPath:(NSString*)sourcePath;
-(void)transformPdfAtPath:(NSString*)pdfPath toDicomAtPath:(NSString*)outDicomPath;
-(void)saveReportAsDicomAtPath:(NSString*)path;
-(NSString*)saveReportAsDicomInTmp;

@end
