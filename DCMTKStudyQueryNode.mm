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


#import "DCMTKStudyQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
#import "DCMTKSeriesQueryNode.h"
#import "DCMTKImageQueryNode.h"
#import "DICOMToNSString.h"
#import "dicomFile.h"
#import "DicomStudy.h"

#undef verify
#include "dcdeftag.h"


@implementation DCMTKStudyQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
						callingAET:(NSString *)myAET  
						calledAET:(NSString *)theirAET  
						hostname:(NSString *)hostname 
						port:(int)port 
						transferSyntax:(int)transferSyntax
						compression: (float)compression
						extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKStudyQueryNode alloc] initWithDataset:(DcmDataset *)dataset
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
									extraParameters:(NSDictionary *)extraParameters{
	if (self = [super initWithDataset:(DcmDataset *)dataset
									callingAET:(NSString *)myAET  
									calledAET:(NSString *)theirAET  
									hostname:(NSString *)hostname 
									port:(int)port 
									transferSyntax:(int)transferSyntax
									compression: (float)compression
									extraParameters:(NSDictionary *)extraParameters]) {
		
		const char *string = nil;
		NSStringEncoding encoding[ 10];
		
		for( int i = 0; i < 10; i++) encoding[ i] = 0;
		encoding[ 0] = NSISOLatin1StringEncoding;
		
//		dataset ->print( COUT);
		
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
		
		if (dataset ->findAndGetString(DCM_StudyInstanceUID, string).good() && string != nil) 
			_uid = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			
		if (dataset ->findAndGetString(DCM_StudyDescription, string).good() && string != nil) 
			_theDescription = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
		
		if (dataset ->findAndGetString(DCM_PatientsName, string).good() && string != nil)
			_name = [[DicomFile stringWithBytes: (char*) string encodings: encoding] retain];
		
		if (dataset ->findAndGetString(DCM_PatientID, string).good() && string != nil)		
			_patientID = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
			
		if (dataset ->findAndGetString(DCM_AccessionNumber, string).good() && string != nil)		
			_accessionNumber = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
		
		if (dataset ->findAndGetString(DCM_StudyComments, string).good() && string != nil)		
			_comments = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
		
        if (dataset ->findAndGetString(DCM_InterpretationStatusID, string).good() && string != nil)
			_interpretationStatusID = [[DicomFile stringWithBytes: (char*) string encodings: encoding replaceBadCharacters: NO] retain];
        
		if (dataset ->findAndGetString(DCM_ReferringPhysiciansName, string).good() && string != nil)		
			_referringPhysician = [[DicomFile stringWithBytes: (char*) string encodings: encoding] retain];
		
        if (dataset ->findAndGetString(DCM_PerformingPhysiciansName, string).good() && string != nil)		
			_performingPhysician = [[DicomFile stringWithBytes: (char*) string encodings: encoding] retain];
        
		if (dataset ->findAndGetString(DCM_InstitutionName, string).good() && string != nil)		
			_institutionName = [[DicomFile stringWithBytes: (char*) string encodings: encoding] retain];
		
		if (dataset ->findAndGetString(DCM_PatientsBirthDate, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_birthdate = [[DCMCalendarDate dicomDate:dateString] retain];
			[dateString release];
		}

		if (dataset ->findAndGetString(DCM_StudyDate, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_date = [[DCMCalendarDate dicomDate:dateString] retain];
			[dateString release];
		}
		
		if (dataset ->findAndGetString(DCM_StudyTime, string).good() && string != nil) {
			NSString *dateString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_time = [[DCMCalendarDate dicomTime:dateString] retain];
			[dateString release];
		}
		

		if (dataset ->findAndGetString(DCM_ModalitiesInStudy, string).good() && string != nil)	{
			_modality = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
		}
		else
		{
			if (dataset ->findAndGetString(DCM_Modality, string).good() && string != nil)
			{
				_modality = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			}
			/*
			else {
				// look for modality at the Series level and get modalities from children
				//This has not been tested yet LWP
				[self queryWithValues:nil];
				NSMutableSet *modalitiesInStudy = [NSMutableSet set];
				NSEnumerator *enumerator = [_children  objectEnumerator];
				DCMTKSeriesQueryNode * child;
				while (child = [enumerator nextObject]) {
					if ([child modality])
						[modalitiesInStudy addObject:[child modality]];
				}
				_modality = [[[modalitiesInStudy allObjects] componentsJoinedByString:@"/"] retain];
			}
			*/
		}
		
		if (dataset ->findAndGetString(DCM_NumberOfStudyRelatedInstances, string).good() && string != nil)
		{
			NSString	*numberString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
			_numberImages = [[NSNumber numberWithInt: [numberString intValue]] retain];
			[numberString release];
		}
//		else if (dataset ->findAndGetString(DCM_ImageGroupLength, string).good() && string != nil)
//		{
//			NSString	*numberString = [[NSString alloc] initWithCString:string encoding:NSISOLatin1StringEncoding];
//			_numberImages = [[NSNumber numberWithInt: [numberString intValue]] retain];
//			[numberString release];
//		}
	}
	return self;
}

- (DcmDataset *)queryPrototype // When 'opening' a study -> SERIES level
{
	DcmDataset *dataset = new DcmDataset();
	dataset-> insertEmptyElement(DCM_SeriesDescription, OFTrue);
	dataset-> insertEmptyElement(DCM_SeriesDate, OFTrue);
	dataset-> insertEmptyElement(DCM_SeriesTime, OFTrue);
	dataset-> insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
	dataset-> insertEmptyElement(DCM_SeriesNumber, OFTrue);
	dataset-> insertEmptyElement(DCM_NumberOfSeriesRelatedInstances, OFTrue);
	dataset-> insertEmptyElement(DCM_Modality, OFTrue);
	dataset-> insertEmptyElement(DCM_ReferringPhysiciansName, OFTrue);
    dataset-> insertEmptyElement(DCM_PerformingPhysiciansName, OFTrue);
	dataset-> insertEmptyElement(DCM_InstitutionName, OFTrue);
	dataset-> putAndInsertString(DCM_StudyInstanceUID, [_uid UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "SERIES", OFTrue);
	
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CFINDBodyPartExaminedSupport"])
        dataset-> insertEmptyElement(DCM_BodyPartExamined, OFTrue);
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CFINDCommentsAndStatusSupport"])
    {
        dataset-> insertEmptyElement(DCM_StudyComments, OFTrue);
        dataset-> insertEmptyElement(DCM_InterpretationStatusID, OFTrue);
	}
    
	return dataset;
}

- (DcmDataset *)moveDataset
{
	DcmDataset *dataset = new DcmDataset();
	dataset-> putAndInsertString(DCM_StudyInstanceUID, [_uid UTF8String], OFTrue);
	dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "STUDY", OFTrue);
	return dataset;
}

- (DCMCalendarDate*) date // Match DicomStudy
{
    return [DCMCalendarDate dicomDateTimeWithDicomDate: _date dicomTime: _time];
}

- (NSString*) studyInstanceUID // Match DicomStudy
{
    if( _uid == nil)
        return @"";
    
    return _uid;
}

- (id) objectID // Match DicomStudy
{
    return self;
}

- (NSString*) studyName // Match DicomStudy
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_theDescription capitalizedString];
        
    return _theDescription;
}

- (NSNumber*) expanded // Match DicomStudy
{
    return [NSNumber numberWithBool: NO];
}

- (NSString*) name  // Match DicomStudy
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_name capitalizedString];
    
    return _name;
//    return [DicomStudy scrambleString: _name];
}

- (NSDate*) dateOfBirth // Match DicomStudy
{
    return _birthdate;
}

- (NSString*) type // Match DicomStudy
{
    return @"Study";
}

- (NSString*) patientUID // Match DicomStudy
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: _name, @"patientName", _patientID, @"patientID", _birthdate, @"patientBirthDate", nil];
    
    return [DicomFile patientUID: dict];
}

- (BOOL) isFault // Match DicomStudy
{
    return NO;
}

- (NSString*) fileType // Match DicomStudy
{
    return @"DICOM";
}

- (NSString*) comment // Match DicomStudy
{
    return _comments;
}

- (NSString*) interpretationStatusID
{
    return _interpretationStatusID;
}

- (NSNumber*) stateText
{
    return [NSNumber numberWithInt: [_interpretationStatusID intValue]];
}

- (NSString*) reportURL // Match DicomStudy
{
    return nil;
}

- (NSDate*) dateAdded // Match DicomStudy
{
    return nil;
}

- (NSNumber*) rawNoFiles // Match DicomStudy
{
    return _numberImages;
}

- (NSNumber*) numberOfImages // Match DicomStudy
{
    return _numberImages;
}

- (NSNumber*) noSeries
{
    return nil;
}

- (NSArray*) imageSeries
{
    return nil;
}

- (NSNumber*) noFiles
{
    return _numberImages;
}

- (NSDate*) dateOpened // Match DicomStudy
{
    return nil;
}

- (NSString*) id // Match DicomStudy
{
    return nil;
}

- (NSString*) localstring // Match DicomStudy
{
    return nil;
}

- (NSString*) performingPhysician // Match DicomStudy
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_performingPhysician capitalizedString];
    
    return _performingPhysician;
}

- (NSString*) albumsNames // Match DicomStudy
{
    return nil;
}

- (NSString*) comment2 // Match DicomStudy
{
    return @"";
}

- (NSString*) comment3 // Match DicomStudy
{
    return @"";
}

- (NSString*) comment4 // Match DicomStudy
{
    return @"";
}

- (NSNumber*) lockedStudy // Match DicomStudy
{
    return [NSNumber numberWithBool: NO];
}

- (NSString*) dictateURL // Match DicomStudy
{
    return nil;
}

- (NSString*) referringPhysician
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_referringPhysician capitalizedString];
    
    return _referringPhysician;
}

- (NSString*) institutionName // Match DicomStudy
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_institutionName capitalizedString];
    
    return _institutionName;
}

- (NSString*) modality // Match DicomStudy
{
    return [DicomStudy displayedModalitiesForSeries: [_modality componentsSeparatedByString: @"\\"]];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog( @"***** DCMTKStudyQueryNode valueForUndefinedKey : %@", key);
    
    return nil;
}

- (NSArray*)children // instead of sorting after every addChild, we sort when the array is requested
{
    @synchronized( _children)
    {
        if (_sortChildren)
        {
            _sortChildren = NO;
            [_children sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
        }
        
        return [super children];
    }
    
    return nil;
}

- (void)addChild:(DcmDataset *)dataset
{
	if( dataset == nil)
		return;
    
    @synchronized( _children)
    {
        if (!_children)
            _children = [[NSMutableArray alloc] init];
	}
    
	if( [_extraParameters valueForKey: @"StudyInstanceUID"] == nil && _uid != nil && _extraParameters != nil)
	{
		NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary: _extraParameters];
		
		[newDict setValue: _uid forKey: @"StudyInstanceUID"];
		[_extraParameters release];
		_extraParameters = [newDict retain];
	}
	
	const char *queryLevel = nil;
	
	if (dataset->findAndGetString(DCM_QueryRetrieveLevel, queryLevel).good()){}
	
	if( queryLevel == nil)
    {
        NSLog( @"**** queryLevel == nil");
        
        dataset->print( COUT);
        
		return;
	}
    
    @synchronized( _children)
    {
        if( strcmp( queryLevel, "IMAGE") == 0)
        {
            DCMTKImageQueryNode *newNode = [DCMTKImageQueryNode queryNodeWithDataset: dataset
                                                                          callingAET: _callingAET
                                                                           calledAET: _calledAET
                                                                            hostname: _hostname
                                                                                port: _port
                                                                      transferSyntax: _transferSyntax
                                                                         compression: _compression
                                                                     extraParameters: _extraParameters];
            BOOL alreadyHere = NO;
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QRRemoveDuplicateEntries"])
            {
                //Is it already here?
                for( DCMTKImageQueryNode* s in _children)
                {
                    if( [s.seriesInstanceUID isEqualToString: newNode.seriesInstanceUID] && [s.studyInstanceUID isEqualToString: newNode.studyInstanceUID] && [s.uid isEqualToString: newNode.uid] && [s.date isEqualToDate: newNode.date])
                        alreadyHere = YES;
                }
            }
            
            if( alreadyHere == NO)
                [_children addObject: newNode];
        }
        else if( strcmp( queryLevel, "SERIES") == 0)
        {
            DCMTKSeriesQueryNode *newNode = [DCMTKSeriesQueryNode queryNodeWithDataset: dataset
                                                                           callingAET: _callingAET
                                                                            calledAET: _calledAET
                                                                             hostname: _hostname
                                                                                 port: _port
                                                                       transferSyntax: _transferSyntax
                                                                          compression: _compression
                                                                      extraParameters: _extraParameters];
            
            newNode.study = self;
            
            BOOL alreadyHere = NO;
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QRRemoveDuplicateEntries"])
            {
                //Is it already here?
                for( DCMTKSeriesQueryNode* s in _children)
                {
                    if( [s.studyInstanceUID isEqualToString: newNode.studyInstanceUID] && [s.uid isEqualToString: newNode.uid])
                        alreadyHere = YES;
                }
            }
            
            if( alreadyHere == NO)
                [_children addObject: newNode];
        }
        else NSLog( @"******** unknown queryLevel *****");
        
        _sortChildren = YES; // instead of sorting after every addChild, we sort when the array is requested, so for N elements we only have 1 sort instead of N
    }
}

- (NSString*) XID
{
    NSMutableString *XID = [NSMutableString stringWithString: @"POD:"];
    
    [XID appendString: _hostname];
    [XID appendString: @":"];
    [XID appendFormat: @"%d", _port];
    [XID appendString: @":"];
    [XID appendString: @"STUDY"];
    [XID appendString: @":"];
    [XID appendString: self.studyInstanceUID];
    
    return XID;
}

@end
