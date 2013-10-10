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

#import "DCMTKSeriesQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
#import "DCMTKImageQueryNode.h"
#import "DICOMToNSString.h"
#import "dicomFile.h"

#undef verify
#include "dcdeftag.h"

@implementation DCMTKSeriesQueryNode

@synthesize study;

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
				callingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				hostname:(NSString *)hostname 
				port:(int)port 
				transferSyntax:(int)transferSyntax
				compression: (float)compression
				extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKSeriesQueryNode alloc] initWithDataset:(DcmDataset *)dataset
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
		_studyInstanceUID = nil;
		const char *string = nil;
		NSStringEncoding encoding[ 10];
		
		for( int i = 0; i < 10; i++) encoding[ i] = 0;
		encoding[ 0] = NSISOLatin1StringEncoding;
		
        if (dataset) {
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
            
            if (dataset ->findAndGetString(DCM_SeriesInstanceUID, string).good() && string != nil) 
                _uid = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
                
            if (dataset ->findAndGetString(DCM_StudyInstanceUID, string).good() && string != nil) 
                _studyInstanceUID = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];	
            else
                _studyInstanceUID = [[extraParameters valueForKey: @"StudyInstanceUID"] retain];
            
            if (dataset ->findAndGetString(DCM_SeriesDescription, string).good() && string != nil) 
                _theDescription = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
                
            if (dataset ->findAndGetString(DCM_SeriesNumber, string).good() && string != nil) 
                _name = [[DicomFile stringWithBytes: (char*) string encodings: encoding] retain];
                
            if (dataset ->findAndGetString(DCM_ImageComments, string).good() && string != nil) 
                _comments = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
                
            if (dataset ->findAndGetString(DCM_SeriesDate, string).good() && string != nil)
            {
                NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
                _date = [[DCMCalendarDate dicomDate:dateString] retain];
                [dateString release];
            }
            
            if (dataset ->findAndGetString(DCM_SeriesTime, string).good() && string != nil)
            {
                NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
                _time = [[DCMCalendarDate dicomTime:dateString] retain];
                [dateString release];
            }
            
            if (dataset ->findAndGetString(DCM_Modality, string).good() && string != nil)	
                _modality = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
                
            if (dataset ->findAndGetString(DCM_NumberOfSeriesRelatedInstances, string).good() && string != nil)
            {
                NSString	*numberString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
                _numberImages = [[NSNumber numberWithInt: [numberString intValue]] retain];
                [numberString release];
            }
        }

	}
	return self;
}

- (void)dealloc
{
    self.study = nil;
	[_studyInstanceUID release];
	[super dealloc];
}

- (DcmDataset *)queryPrototype
{
	DcmDataset *dataset = new DcmDataset();
	dataset-> insertEmptyElement(DCM_InstanceCreationDate, OFTrue);
	dataset-> insertEmptyElement(DCM_InstanceCreationTime, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_SOPInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_InstanceNumber, OFTrue);
	dataset-> putAndInsertString(DCM_SeriesInstanceUID, [_uid UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_StudyInstanceUID, [_studyInstanceUID UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE", OFTrue);
	
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CFINDCommentsAndStatusSupport"])
        dataset-> insertEmptyElement(DCM_ImageComments, OFTrue);
    
	return dataset;
	
}

- (DcmDataset *)moveDataset{
	DcmDataset *dataset = new DcmDataset();
	dataset-> putAndInsertString(DCM_SeriesInstanceUID, [_uid UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_StudyInstanceUID, [_studyInstanceUID UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "SERIES", OFTrue);
	return dataset;
}

- (NSString*) studyInstanceUID
{
    if( _studyInstanceUID == nil)
        return @"";
    
    return _studyInstanceUID;
}

- (NSString*) seriesInstanceUID
{
    if( _uid == nil)
        return @"";
    
    return _uid;
}

- (void)addChild:(DcmDataset *)dataset
{
    @synchronized( _children)
    {
        if (!_children)
            _children = [[NSMutableArray alloc] init];
        
        if( dataset == nil)
            return;
	
        [_children addObject:[DCMTKImageQueryNode queryNodeWithDataset:dataset
                callingAET:_callingAET
                calledAET:_calledAET
                hostname:_hostname 
                port:_port 
                transferSyntax:_transferSyntax
                compression: _compression
                extraParameters:_extraParameters]];
    }
}

- (NSString*) type
{
    return @"Series";
}

- (BOOL) isFault // Match DicomSeries
{
    return NO;
}

- (NSNumber*) noFiles // Match DicomSeries
{
    return _numberImages;
}

- (NSString*) seriesDescription // Match DicomSeries
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_theDescription capitalizedString];
    
    return _theDescription;
}

- (NSNumber*) stateText
{
    return [NSNumber numberWithInt: [_interpretationStatusID intValue]];
}

- (NSDate*) dateOpened // Match DicomSeries
{
    return nil;
}

- (NSDate*) dateAdded // Match DicomSeries
{
    return nil;
}

- (NSString*) id // Match DicomSeries
{
    return nil;
}

- (NSString*) localstring // Match DicomSeries
{
    return nil;
}

- (NSString*) albumsNames // Match DicomSeries
{
    return nil;
}

- (NSString*) comment2 // Match DicomSeries
{
    return @"";
}

- (NSString*) comment3 // Match DicomSeries
{
    return @"";
}

- (NSString*) comment4 // Match DicomSeries
{
    return @"";
}

- (NSSet*) images // Match DicomSeries
{
    return nil;
}

- (DCMCalendarDate*) date // Match DicomSeries
{
    return [DCMCalendarDate dicomDateTimeWithDicomDate: _date dicomTime: _time];
}

- (NSNumber*) rawNoFiles // Match DicomSeries
{
    return _numberImages;
}

- (NSNumber*) numberOfImages // Match DicomSeries
{
    return _numberImages;
}
@end
