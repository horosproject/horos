//
//  DicomFileDCMTKCategory.mm
//  OsiriX
//
//  Created by Lance Pysher on 6/27/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DicomFileDCMTKCategory.h"
#import "Papyrus3/Papyrus3.h"

#undef verify

#include "osconfig.h"
#include "dcfilefo.h"
#include "dcdeftag.h"
#include "ofstd.h"

extern NSLock	*PapyrusLock;


@implementation DicomFile (DicomFileDCMTKCategory)

+ (BOOL) isDICOMFileDCMTK:(NSString *) file{
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([file UTF8String]);
	if (status.good())
		return YES;
	return NO;
}

-(short) getDicomFileDCMTK{
	int					itemType;
	long				cardiacTime = -1;
	short				x, theErr;
	PapyShort           fileNb, imageNb;
	PapyULong           nbVal;
	UValue_T            *val;
	SElement			*theGroupP;
	NSString			*converted = 0L;
	NSStringEncoding	encoding;//NSStringEncoding
	NSString *echoTime = nil;
	const char *string = NULL;
	
	DcmFileFormat fileformat;
	[PapyrusLock lock];
	OFCondition status = fileformat.loadFile([filePath UTF8String]);
	[PapyrusLock unlock];
	if (status.good()){
		NSString *characterSet = 0L;
		fileType = [[NSString stringWithString:@"DICOM"] retain];
		[dicomElements setObject:fileType forKey:@"fileType"];
		encoding = NSISOLatin1StringEncoding;
		DcmDataset *dataset = fileformat.getDataset();
		
		if ([self autoFillComments]  == YES ||[self checkForLAVIM] == YES)
		{
			if( [self autoFillComments])
			{
				NSString	*commentsField;
				int elementNumber = ([self commentsGroup] * 10,000) +  [self commentsElement];
				DcmTagKey key = DcmTagKey([self commentsGroup], [self commentsElement]);
				// * 10,000 + [self commentsElement];
				if (dataset->findAndGetString(key, string, OFFalse).good()){
					commentsField = [NSString stringWithCString:string];
					[dicomElements setObject:commentsField forKey:@"commentsAutoFill"];

				}
			}
			
			if([self checkForLAVIM] )
			{
				NSString	*album = 0L;
				dataset->findAndGetString(DCM_ImageComments, string, OFFalse); 
			}
		}
				
	}
	
	if (status.good())
		return YES;
	return NO;
}

@end
