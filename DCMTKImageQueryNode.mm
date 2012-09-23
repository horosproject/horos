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


#import "DCMTKImageQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
#import "DICOMToNSString.h"
#import "dicomFile.h"

#undef verify
#include "dcdeftag.h"


@implementation DCMTKImageQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKImageQueryNode alloc] initWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters] autorelease];
}

- (id)initWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters
{
	if (self = [super initWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters])
	{
		const char *string = nil;
		
		NSStringEncoding encoding[ 10];
		
		for( int i = 0; i < 10; i++) encoding[ i] = 0;
		encoding[ 0] = NSISOLatin1StringEncoding;
		
		if (dataset ->findAndGetString(DCM_SpecificCharacterSet, string).good() && string != nil)
		{
			_specificCharacterSet = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			
			NSArray	*c = [_specificCharacterSet componentsSeparatedByString:@"\\"];
			
			if( [c count] >= 10) NSLog( @"Encoding number >= 10 ???");
			
			if( [c count] < 10)
			{
				for( int i = 0; i < [c count]; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c objectAtIndex: i]];
				for( int i = [c count]; i < 10; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c lastObject]];
			}
		}
		
		if (dataset ->findAndGetString(DCM_SOPInstanceUID, string).good() && string != nil) 
			_uid = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			
		if (dataset ->findAndGetString(DCM_SeriesInstanceUID, string).good() && string != nil) 
			_seriesInstanceUID = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
		
		if (dataset ->findAndGetString(DCM_StudyInstanceUID, string).good() && string != nil) 
			_studyInstanceUID = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
		
		if (dataset ->findAndGetString(DCM_InstanceNumber, string).good() && string != nil) 
			_name = [[DicomFile stringWithBytes: (char*) string encodings: encoding] retain];
		
		if (dataset ->findAndGetString(DCM_InstanceCreationDate, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_date = [[DCMCalendarDate dicomDate:dateString] retain];
			[dateString release];
		}
		
		if (dataset ->findAndGetString(DCM_InstanceCreationTime, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_time = [[DCMCalendarDate dicomTime:dateString] retain];
			[dateString release];
		}
	}
	return self;
}

- (NSString*) seriesInstanceUID
{
	return _seriesInstanceUID;
}

- (NSString*) studyInstanceUID
{
	return _studyInstanceUID;
}

- (void) dealloc
{
	[_seriesInstanceUID release];
	[_studyInstanceUID release];
	
	[super dealloc];
}

- (DcmDataset *)moveDataset{
	DcmDataset *dataset = new DcmDataset();
	dataset-> putAndInsertString(DCM_SOPInstanceUID, [_uid UTF8String], OFTrue);
	//dataset-> putAndInsertString(DCM_StudyInstanceUID, [_studyInstanceUID UTF8String], OFTrue);
	//dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "SERIES", OFTrue);
	return dataset;
}

- (NSString*) type
{
    return @"Image";
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"DCMTKImageQueryNode: %@ %@ %@", _name, _date, _uid];
}

@end
