/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#define FETCHNUMBER 100

#import "AsyncSocket.h"
#import "OsiriXSCPDataHandler.h"
#import "DicomFile.h"
#import "DicomFileDCMTKCategory.h"
#import "BrowserController.h"
#import "AppController.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DICOMToNSString.h"
#import "MutableArrayCategory.h"
#import "N2Debug.h"
#import "N2Connection.h"
#import "DicomDatabase.h"
#import "NSThread+N2.h"
#import "LogManager.h"
#import "MutableArrayCategory.h"
#import "DCMAbstractSyntaxUID.h"

#include "dctk.h"

char currentDestinationMoveAET[ 60] = "";

extern NSManagedObjectContext *staticContext;
extern BOOL forkedProcess;


@implementation OsiriXSCPDataHandler

@synthesize callingAET;

- (void)dealloc
{
    if( logDictionary)
    {
        if( moveArrayEnumerator < moveArray.count)
            [logDictionary setObject: @"Incomplete" forKey: @"logMessage"];
        [logDictionary setObject: [NSDate date] forKey: @"logEndTime"];
        [[LogManager currentLogManager] addLogLine: logDictionary];
    }
    
	[context release];
	context = nil;
    
	[moveArray release];
    moveArray = nil;
	
	[logDictionary release];
    logDictionary = nil;
	
	[findArray release];
	findArray = nil;
	
	[specificCharacterSet release];
	[findEnumerator release];
	
	[callingAET release];
	[findTemplate release];
	
	[super dealloc];
}

- (id)init
{
	if (self = [super init])
	{
        if( forkedProcess)
            context = [staticContext retain];
        else
            context = [[[DicomDatabase defaultDatabase] independentContext] retain];
        
	}
	return self;
}

+ (id)allocRequestDataHandler
{
#ifdef NONETWORKFUNCTIONS
    return nil;
#endif
    
	return [[OsiriXSCPDataHandler alloc] init];
}

-(NSTimeInterval) endOfDay:(NSCalendarDate *)day
{
	NSCalendarDate *start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: nil];
	NSCalendarDate *end = [start dateByAddingYears:0 months:0 days:0 hours:24 minutes:0 seconds:0];
	return [end timeIntervalSinceReferenceDate];
}

-(NSTimeInterval) startOfDay:(NSCalendarDate *)day
{
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: nil];
	return [start timeIntervalSinceReferenceDate];
}

- (NSPredicate*) predicateWithString: (NSString*) s forField: (NSString*) f any: (BOOL) any
{
	if( [s length] > 3)
	{
		for( int i = 1 ; i < [s length]-1; i++)
		{
			if( [s characterAtIndex: i] == '*') // contains a wildchar
			{
				if( any)
				{
					return [NSPredicate predicateWithFormat:@"ANY %K LIKE[cd] %@", f, s];
				}
				else
				{
					return [NSPredicate predicateWithFormat:@"%K LIKE[cd] %@", f, s];
				}
			}
		}
	}
	
	NSString *v = [s stringByReplacingOccurrencesOfString: @"*" withString:@""];
	NSPredicate *predicate = nil;
	
	if( any)
	{
		if( [v length] == 0)
			predicate = [NSPredicate predicateWithValue: YES];
		else if( [s characterAtIndex: 0] == '*' && [s characterAtIndex: [s length]-1] == '*')
			predicate = [NSPredicate predicateWithFormat:@"ANY %K CONTAINS[cd] %@", f, v];
		else if( [s characterAtIndex: 0] == '*')
			predicate = [NSPredicate predicateWithFormat:@"ANY %K ENDSWITH[cd] %@", f, v];
		else if( [s characterAtIndex: [s length]-1] == '*')
			predicate = [NSPredicate predicateWithFormat:@"ANY %K BEGINSWITH[cd] %@", f, v];
		else
			predicate = [NSPredicate predicateWithFormat:@"(ANY %K BEGINSWITH[cd] %@) AND (ANY %K ENDSWITH[cd] %@)", f, v, f, v];
	}
	else
	{
		if( [v length] == 0)
			predicate = [NSPredicate predicateWithValue: YES];
		else if( [s characterAtIndex: 0] == '*' && [s characterAtIndex: [s length]-1] == '*')
			predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", f, v];
		else if( [s characterAtIndex: 0] == '*')
			predicate = [NSPredicate predicateWithFormat:@"%K ENDSWITH[cd] %@", f, v];
		else if( [s characterAtIndex: [s length]-1] == '*')
			predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", f, v];
		else
			predicate = [NSPredicate predicateWithFormat:@"(%K BEGINSWITH[cd] %@) AND (%K ENDSWITH[cd] %@)", f, v, f, v];
	}
	
	return predicate;
}

- (NSPredicate*) predicateWithString: (NSString*) s forField: (NSString*) f
{
	return [self predicateWithString: s forField: f any: NO];
}

- (NSPredicate *)predicateForDataset:(DcmDataset *)dataset compressedSOPInstancePredicate: (NSPredicate**) csopPredicate seriesLevelPredicate: (NSPredicate**) SLPredicate
{
	NSPredicate *compoundPredicate = nil;
	NSPredicate *seriesLevelPredicate = nil;
	const char *sType = NULL;
	const char *scs = NULL;
	
	@try
	{
		dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
		
		if (dataset->findAndGetString (DCM_SpecificCharacterSet, scs, OFFalse).good() && scs != NULL)
		{
			[specificCharacterSet release];
			
			NSArray	*c = nil;
			
			@try
			{
				c = [[NSString stringWithUTF8String:scs] componentsSeparatedByString:@"\\"];
			
				if( [c count] > 0)
					specificCharacterSet = [[c objectAtIndex: 0] retain];
				else
					specificCharacterSet = [[NSString alloc] initWithUTF8String:scs];
			}
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e);
			}
			
			encoding = [NSString encodingForDICOMCharacterSet: specificCharacterSet];
		}
		else
		{
			[specificCharacterSet release];
			specificCharacterSet = [[NSString alloc] initWithString:@"ISO_IR 100"];
			encoding = NSISOLatin1StringEncoding;
		}
		
		NSString *dcmstartTime = nil;
		NSString *dcmendTime = nil;
		NSString *dcmstartDate = nil;
		NSString *dcmendDate = nil;
		
		int elemCount = (int)(dataset->card());
		for (int elemIndex=0; elemIndex<elemCount; elemIndex++)
		{
			NSPredicate *predicate = nil;
			DcmElement* dcelem = dataset->getElement(elemIndex);
            DcmTag tag = dcelem->getTag();
			DcmTagKey key = dcelem->getTag().getXTag();
			
            if( key == DCM_SpecificCharacterSet)
                continue;
            
            if( key == DCM_QueryRetrieveLevel)
                continue;
            
            if( key == DCM_NumberOfStudyRelatedInstances)
                continue;
            
			if (strcmp(sType, "STUDY") == 0)
			{
				if (key == DCM_PatientsName)
				{
					char *pn;
					if (dcelem->getString(pn).good() && pn != NULL)
					{
						NSString *patientNameString = [NSString stringWithUTF8String:pn  DICOMEncoding:specificCharacterSet];
                        
                        predicate = [[BrowserController currentBrowser] patientsnamePredicate: patientNameString soundex: NO];
					}
				}
				else if (key == DCM_PatientID)
				{
					char *pid;
					if (dcelem->getString(pid).good() && pid != NULL)
						predicate = [self predicateWithString: [NSString stringWithUTF8String:pid  DICOMEncoding:nil] forField: @"patientID"];
				}
				else if (key == DCM_AccessionNumber)
				{
					char *pid;
					if (dcelem->getString(pid).good() && pid != NULL)
						predicate = [self predicateWithString: [NSString stringWithUTF8String:pid  DICOMEncoding:nil] forField: @"accessionNumber"];
				}
				else if (key == DCM_StudyInstanceUID)
				{
					char *suid;
					if (dcelem->getString(suid).good() && suid != NULL)
						predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [NSString stringWithUTF8String:suid  DICOMEncoding:nil]];
				}
				else if (key == DCM_StudyID)
				{
					char *sid;
					if (dcelem->getString(sid).good() && sid != NULL)
						predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithUTF8String:sid  DICOMEncoding:nil]];
				}
				else if (key ==  DCM_StudyDescription)
				{
					char *sd;
					if (dcelem->getString(sd).good() && sd != NULL)
						predicate = [self predicateWithString: [NSString stringWithUTF8String:sd  DICOMEncoding:specificCharacterSet] forField: @"studyName"];
				}
                else if (key ==  DCM_InterpretationStatusID)
				{
					char *sd;
					if (dcelem->getString(sd).good() && sd != NULL)
						predicate = [NSPredicate predicateWithFormat:@"stateText == %@", [NSString stringWithUTF8String:sd  DICOMEncoding:nil]];
				}
				else if (key ==  DCM_ImageComments || key ==  DCM_StudyComments)
				{
					char *sd;
					if (dcelem->getString(sd).good() && sd != NULL)
					{
						NSPredicate *p1 = [self predicateWithString: [NSString stringWithUTF8String:sd  DICOMEncoding:specificCharacterSet] forField: @"comment"];
						NSPredicate *p2 = [self predicateWithString: [NSString stringWithUTF8String:sd  DICOMEncoding:specificCharacterSet] forField: @"series.comment" any: YES];
						
						predicate = [NSCompoundPredicate orPredicateWithSubpredicates: [NSArray arrayWithObjects: p1, p2, nil]];
					}
				}
				else if (key == DCM_InstitutionName)
				{
					char *inn;
					if (dcelem->getString(inn).good() && inn != NULL)
						predicate = [self predicateWithString: [NSString stringWithUTF8String:inn  DICOMEncoding:specificCharacterSet] forField: @"institutionName"];
				}
				else if (key == DCM_ReferringPhysiciansName)
				{
					char *rpn;
					if (dcelem->getString(rpn).good() && rpn != NULL)
						predicate = [self predicateWithString: [NSString stringWithUTF8String:rpn  DICOMEncoding:specificCharacterSet] forField: @"referringPhysician"];
				}
				else if (key ==  DCM_PerformingPhysiciansName)
				{
					char *ppn;
					if (dcelem->getString(ppn).good() && ppn != NULL)
						predicate = [self predicateWithString: [NSString stringWithUTF8String:ppn  DICOMEncoding:specificCharacterSet] forField: @"performingPhysician"];
				}
				else if (key ==  DCM_ModalitiesInStudy)
				{
					char *mis;
					if (dcelem->getString(mis).good() && mis != NULL)
					{
                        NSArray *modalities = [[NSString stringWithUTF8String:mis DICOMEncoding:nil] componentsSeparatedByString:@"\\"];
                        
                        if( modalities.count <= 1)
                            predicate = [NSPredicate predicateWithFormat:@"(modality CONTAINS[cd] %@)", [modalities lastObject]];
						else
                            predicate = [NSPredicate predicateWithFormat:@"(ANY series.modality IN %@)", modalities];
					}
				}
				else if (key ==  DCM_Modality)
				{
					char *mis;
					if (dcelem->getString(mis).good() && mis != NULL)
					{
                        NSArray *modalities = [[NSString stringWithUTF8String:mis DICOMEncoding:nil] componentsSeparatedByString:@"\\"];
                        
                        if( modalities.count <= 1)
                            predicate = [NSPredicate predicateWithFormat:@"(modality CONTAINS[cd] %@)", [modalities lastObject]];
						else
                            predicate = [NSPredicate predicateWithFormat:@"(ANY series.modality IN %@)", modalities];
					}
				}
				else if (key == DCM_PatientsBirthDate)
				{
					char *aDate;
					DCMCalendarDate *value = nil;
					if (dcelem->getString(aDate).good() && aDate != NULL)
					{
						NSString *dateString = [NSString stringWithUTF8String:aDate DICOMEncoding:nil];
						value = [DCMCalendarDate dicomDate:dateString];
					}
					
					if (!value)
					{
						predicate = nil;
					}
					else
					{
						if( [value isQuery] && [[value queryString] hasPrefix:@"-"]) // Before
						{
							value = [DCMCalendarDate dicomDate: [[value queryString] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"-"]]];
							
							predicate = [NSPredicate predicateWithFormat:@"(dateOfBirth < CAST(%lf, \"NSDate\"))", [self endOfDay: value]];
						}
						else if( [value isQuery] && [[value queryString] hasSuffix:@"-"]) // After
						{
							value = [DCMCalendarDate dicomDate: [[value queryString] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"-"]]];
							
							predicate = [NSPredicate predicateWithFormat:@"(dateOfBirth >= CAST(%lf, \"NSDate\"))", [self startOfDay: value]];
						}
						else if( [value isQuery])
						{
							NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
							
							if( values.count == 2)
							{
								DCMCalendarDate *start = [DCMCalendarDate dicomDate: [values objectAtIndex: 0]];
								DCMCalendarDate *end = [DCMCalendarDate dicomDate: [values objectAtIndex: 1]];
								
								predicate = [NSPredicate predicateWithFormat:@"(dateOfBirth >= CAST(%lf, \"NSDate\")) AND (dateOfBirth < CAST(%lf, \"NSDate\"))", [self startOfDay: start], [self endOfDay: end]];
							}
							else
								predicate = nil;
						}
						else
							predicate = [NSPredicate predicateWithFormat:@"(dateOfBirth >= CAST(%lf, \"NSDate\")) AND (dateOfBirth < CAST(%lf, \"NSDate\"))", [self startOfDay: value], [self endOfDay: value]];
					}
				}
				
				else if (key == DCM_StudyDate)
				{
					char *aDate;
					DCMCalendarDate *value = nil;
					if (dcelem->getString(aDate).good() && aDate != NULL)
					{
						NSString *dateString = [NSString stringWithUTF8String:aDate DICOMEncoding:nil];
						value = [DCMCalendarDate dicomDate:dateString];
					}
					
					if (!value)
					{
						predicate = nil;
					}
					else if ([value isQuery] && [[value queryString] hasPrefix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];
						
						dcmendDate = queryString;

					}
					else if ([value isQuery] && [[value queryString] hasSuffix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];
						
						dcmstartDate = queryString;
					}
					else if ([value isQuery])
					{
						NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
						if ([values count] == 2)
						{
							dcmstartDate = [values objectAtIndex:0];
							dcmendDate = [values objectAtIndex:1];
						}
						else
							predicate = nil;
					}
					else
					{
						predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\") AND date < CAST(%lf, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
					}
				}
				else if (key == DCM_StudyTime)
				{
					char *aDate;
					DCMCalendarDate *value = nil;
					if (dcelem->getString(aDate).good() && aDate != NULL)
					{
						NSString *dateString = [NSString stringWithUTF8String:aDate DICOMEncoding:nil];
						value = [DCMCalendarDate dicomTime:dateString];
					}
	  
					if (!value)
					{
						predicate = nil;
					}
					else if ([value isQuery] && [[value queryString] hasPrefix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];
						
						dcmendTime = queryString;
					}
					else if ([value isQuery] && [[value queryString] hasSuffix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];
						
						dcmstartTime = queryString;
					}
					else if ([value isQuery])
					{
						NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
						if ([values count] == 2)
						{
							dcmstartTime = [values objectAtIndex:0];
							dcmendTime = [values objectAtIndex:1];
						}
						else
							predicate = nil;
					}
					else
					{
						predicate = [NSPredicate predicateWithFormat:@"dicomTime == %@", [value dateAsNumber]];
					}
				}
				else
                {
                    if( dcelem->getLength() > 0)
                        printf( "***** DICOM SCP - STUDY LEVEL: unknown key: %s\r", tag.getTagName());
                    
                    predicate = nil;
                }
			}
			else if (strcmp(sType, "SERIES") == 0)
			{
				if (key == DCM_StudyInstanceUID)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
						predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [NSString stringWithUTF8String:string  DICOMEncoding:nil]];
				}
				else if (key == DCM_SeriesInstanceUID)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
					{
						NSString *u = [NSString stringWithUTF8String:string  DICOMEncoding:nil];
						NSArray *uids = [u componentsSeparatedByString:@"\\"];
						NSArray *predicateArray = [NSArray array];
						
						int x;
						for(x = 0; x < [uids count]; x++)
						{
							NSString *curString = [uids objectAtIndex: x];
							
							predicateArray = [predicateArray arrayByAddingObject: [NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", curString]];
						}
						
						predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
					}
				} 
				else if (key == DCM_SeriesDescription)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
						predicate = [self predicateWithString:[NSString stringWithUTF8String:string  DICOMEncoding:specificCharacterSet] forField:@"name"];
				}
				else if (key == DCM_SeriesNumber)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
						predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithUTF8String:string  DICOMEncoding:specificCharacterSet]];
				}
				else if (key ==  DCM_Modality)
				{
					char *mis;
					if (dcelem->getString(mis).good() && mis != NULL)
						predicate = [NSPredicate predicateWithFormat:@"study.modality CONTAINS[cd] %@", [NSString stringWithUTF8String:mis  DICOMEncoding:nil]];
				}
				
				else if (key == DCM_SeriesDate)
				{
					char *aDate;
					DCMCalendarDate *value = nil;
					if (dcelem->getString(aDate).good() && aDate != NULL)
					{
						NSString *dateString = [NSString stringWithUTF8String:aDate DICOMEncoding:nil];
						value = [DCMCalendarDate dicomDate:dateString];
					}
	  
					if (!value)
					{
						predicate = nil;
					}
					else if ([value isQuery] && [[value queryString] hasPrefix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];
						
						dcmendDate = queryString;

					}
					else if ([value isQuery] && [[value queryString] hasSuffix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
						
						dcmstartDate = queryString;
					}
					else if ([value isQuery])
					{
						NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
						if ([values count] == 2)
						{
							dcmstartDate = [values objectAtIndex:0];
							dcmendDate = [values objectAtIndex:1];
						}
						else
							predicate = nil;
					}
					else
					{
						predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\") AND date < CAST(%lf, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
					}
				}
				else if (key == DCM_SeriesTime)
				{
					char *aDate;
					DCMCalendarDate *value = nil;
					if (dcelem->getString(aDate).good() && aDate != NULL)
					{
						NSString *dateString = [NSString stringWithUTF8String:aDate DICOMEncoding:nil];
						value = [DCMCalendarDate dicomTime:dateString];
					}
	  
					if (!value)
					{
						predicate = nil;
					}
					else if ([value isQuery] && [[value queryString] hasPrefix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
						dcmendTime = queryString;
					}
					else if ([value isQuery] && [[value queryString] hasSuffix:@"-"])
					{
						NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
						NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];
						dcmstartTime = queryString;
					}
					else if ([value isQuery])
					{
						NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
						if ([values count] == 2)
						{
							dcmstartTime = [values objectAtIndex:0];
							dcmendTime = [values objectAtIndex:1];
						}
						else
							predicate = nil;
					}

					else
					{
						predicate = [NSPredicate predicateWithFormat:@"dicomTime == %@", [value dateAsNumber]];
					}
				}
                else
                {
                    if( dcelem->getLength() > 0)
                        printf( "***** DICOM SCP - SERIES LEVEL: unknown key: %s\r", tag.getTagName());
                    
                    predicate = nil;
                }
			}
			else if (strcmp(sType, "IMAGE") == 0)
			{
				if (key == DCM_StudyInstanceUID)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
					{
						predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [NSString stringWithUTF8String:string  DICOMEncoding:nil]];
					
						if( seriesLevelPredicate == nil)
							seriesLevelPredicate = predicate;
						else
							seriesLevelPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, seriesLevelPredicate, nil]];
							
						*SLPredicate = seriesLevelPredicate;
						
						predicate = nil;
					}
				}
				else if (key == DCM_SeriesInstanceUID)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
					{
						predicate = [NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", [NSString stringWithUTF8String:string  DICOMEncoding:nil]];
						
						if( seriesLevelPredicate == nil)
							seriesLevelPredicate = predicate;
						else
							seriesLevelPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: seriesLevelPredicate, predicate, nil]];
						
						*SLPredicate = seriesLevelPredicate;
						
						predicate = nil;
					}
				} 
				else if (key == DCM_SOPInstanceUID)
				{
					char *string = nil;
					
					if (dcelem->getString(string).good() && string != NULL)
					{
						NSArray *uids = [[NSString stringWithUTF8String:string  DICOMEncoding:nil] componentsSeparatedByString:@"\\"];
						NSArray *predicateArray = [NSArray array];
						
						for(int x = 0; x < [uids count]; x++)
						{
							NSPredicate	*p = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: [uids objectAtIndex: x]]] customSelector: @selector(isEqualToSopInstanceUID:)];
							predicateArray = [predicateArray arrayByAddingObject: p];
						}
						
						predicate = [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"];
						*csopPredicate = [NSCompoundPredicate orPredicateWithSubpredicates: predicateArray];
					}
				}
				else if (key == DCM_InstanceNumber)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
						predicate = [NSPredicate predicateWithFormat:@"instanceNumber == %d", [[NSString stringWithUTF8String:string  DICOMEncoding:nil] intValue]];
				}
				else if (key == DCM_NumberOfFrames)
				{
					char *string;
					if (dcelem->getString(string).good() && string != NULL)
						predicate = [NSPredicate predicateWithFormat:@"numberOfFrames == %d", [[NSString stringWithUTF8String:string  DICOMEncoding:nil] intValue]];
				}
                else
                {
                    if( dcelem->getLength() > 0)
                        printf( "***** DICOM SCP - IMAGE LEVEL: unknown key: %s\r", tag.getTagName());
                    
                    predicate = nil;
                }
			}
			else
			{
				printf( "***** DICOM SCP supports ONLY STUDY, SERIES, IMAGE levels ! Current level: %s\r", sType);
			}
			
			if (predicate)
			{
				if( compoundPredicate == nil) compoundPredicate = predicate;
				else compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: compoundPredicate, predicate, nil]];
			}
		}
		
		{
			NSPredicate *predicate = nil;
			
			if (strcmp(sType, "STUDY") == 0) 
				predicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
			else if (strcmp(sType, "SERIES") == 0)
				predicate = [NSPredicate predicateWithFormat:@"study.hasDICOM == %d", YES];
			else if (strcmp(sType, "IMAGE") == 0)
				predicate = [NSPredicate predicateWithFormat:@"series.study.hasDICOM == %d", YES];
			
			if (predicate)
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: compoundPredicate, predicate, nil]];
		}
		
		{
			NSPredicate *predicate = nil;
			
			NSTimeInterval startDate = 0.f;
			NSTimeInterval endDate = 0.f;
			
			if( dcmstartDate)
			{
				if( dcmstartTime)
				{
					DCMCalendarDate *time = [DCMCalendarDate dicomTime: dcmstartTime];
					startDate = [[[DCMCalendarDate dicomDate: dcmstartDate] dateByAddingYears: 0 months: 0 days: 0 hours: [time hourOfDay] minutes: [time minuteOfHour] seconds: [time secondOfMinute]] timeIntervalSinceReferenceDate];
				}
				else startDate = [self startOfDay: [DCMCalendarDate dicomDate: dcmstartDate]];
			}
			
			if( dcmendDate)
			{
				if( dcmendTime)
				{
					DCMCalendarDate *time = [DCMCalendarDate dicomTime: dcmendTime];
					endDate = [[[DCMCalendarDate dicomDate: dcmendDate] dateByAddingYears: 0 months: 0 days: 0 hours: [time hourOfDay] minutes: [time minuteOfHour] seconds: [time secondOfMinute]] timeIntervalSinceReferenceDate];
				}
				else endDate = [self endOfDay: [DCMCalendarDate dicomDate: dcmendDate]];
			}
			
			if( startDate && endDate)
			{
				//need two predicates for range
				
				NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\")", startDate];
				NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")", endDate];
				predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
			}
			else if( startDate)
			{		
				predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%lf, \"NSDate\")", startDate];
			}
			else if( endDate)
			{
				predicate = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")", endDate];
			}
			
			if (predicate)
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, compoundPredicate, nil]];
		}
	}
	
	@catch ( NSException *e)
	{
		N2LogExceptionWithStackTrace(e);
		dataset->print(COUT);
	}
	
	return compoundPredicate;
}

- (const char*) encodeString: (NSString*) str image: (NSManagedObject*) image
{
	if( str == nil)
		return nil;
		
	const char *a = [str cStringUsingEncoding: encoding];
	
	if( a == nil)
	{
		NSLog( @"--- cannot encode %@ -> switch to UTF-8 (ISO_IR 192) encoding", str);
		
		[specificCharacterSet release];
		specificCharacterSet = [[NSString alloc] initWithString: @"ISO_IR 192"];
		encoding = [NSString encodingForDICOMCharacterSet: specificCharacterSet];
		
		a = [str cStringUsingEncoding:encoding];
		
		if( a == nil)
		{
			NSLog( @"--- cannot encode %@ -> switch to dcm file encoding", str);
			
			NSArray	*c = [DicomFile getEncodingArrayForFile: [image valueForKey:@"completePathResolved"]];
			
			if( c)
			{
				for( NSString *encodingString in c)
				{
					if( [str cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: encodingString]])
					{
						[specificCharacterSet release];
						specificCharacterSet = [[NSString alloc] initWithString: encodingString];
						encoding = [NSString encodingForDICOMCharacterSet: specificCharacterSet];
						
						a = [str cStringUsingEncoding:encoding];
						
						break;
					}
				}
			}
		}
	}
	
	if( a == nil)
		NSLog( @"***** encodeString FAILED for: %@", [image valueForKey:@"completePathResolved"]);
	
	return a;
}

- (void)studyDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset
{
	@try
	{
		NSManagedObject *image = [[[[fetchedObject valueForKey: @"series"] anyObject] valueForKey: @"images"] anyObject];
		
		for( NSString *keyString in [findTemplate allKeys])
		{
			NSArray *elementAndGroup = [keyString componentsSeparatedByString: @","];
			
            @try
            {
                if( [elementAndGroup count] != 2)
                {
                    NSLog( @"***** studyDatasetForFetchedObject ERROR");
                }
                else
                {
                    DcmTagKey key( [[elementAndGroup objectAtIndex: 1] intValue], [[elementAndGroup objectAtIndex: 0] intValue]);
                    
                    if( key == DCM_PatientsName && [fetchedObject valueForKey:@"name"])
                    {
                        dataset->putAndInsertString( DCM_PatientsName, [self encodeString: [fetchedObject primitiveValueForKey:@"name"] image: image]);
                    }
                    
                    else if( key == DCM_PatientID && [fetchedObject valueForKey:@"patientID"])
                    {
                        dataset->putAndInsertString(DCM_PatientID, [self encodeString: [fetchedObject valueForKey:@"patientID"] image: image]);
                    }
                    
                    else if( key == DCM_PatientsSex && [fetchedObject valueForKey:@"patientSex"])
                    {
                        dataset->putAndInsertString(DCM_PatientsSex, [self encodeString: [fetchedObject valueForKey:@"patientSex"] image: image]);
                    }
                    
                    else if( key == DCM_AccessionNumber && [fetchedObject valueForKey:@"accessionNumber"])
                    {
                        dataset->putAndInsertString(DCM_AccessionNumber, [self encodeString: [fetchedObject valueForKey:@"accessionNumber"] image: image]);
                    }
                    
                    else if( key == DCM_StudyDescription && [fetchedObject valueForKey:@"studyName"])
                    {
                        dataset->putAndInsertString( DCM_StudyDescription, [self encodeString: [fetchedObject valueForKey:@"studyName"] image: image]);
                    }
                    
                    else if( key == DCM_ImageComments && [fetchedObject valueForKey:@"comment"])
                    {
                        dataset->putAndInsertString( DCM_ImageComments, [self encodeString: [fetchedObject valueForKey:@"comment"] image: image]);
                    }
                    else if (key ==  DCM_InterpretationStatusID)
                    {
                        dataset->putAndInsertString( DCM_InterpretationStatusID, [self encodeString: [[fetchedObject valueForKey:@"stateText"] stringValue] image: image]);
                    }
                    else if( key == DCM_StudyComments && [fetchedObject valueForKey:@"comment"])
                    {
                        dataset->putAndInsertString( DCM_StudyComments, [self encodeString: [fetchedObject valueForKey:@"comment"] image: image]);
                    }
                    else if( key == DCM_PatientsBirthDate && [fetchedObject valueForKey:@"dateOfBirth"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"dateOfBirth"]];
                        dataset->putAndInsertString(DCM_PatientsBirthDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_StudyDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_StudyTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ContentDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_ContentDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ContentTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_ContentTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_SeriesDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_SeriesDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_SeriesTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_SeriesTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_AcquisitionDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_AcquisitionDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_AcquisitionTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_AcquisitionTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyInstanceUID && [fetchedObject valueForKey:@"studyInstanceUID"])
                    {
                        dataset->putAndInsertString(DCM_StudyInstanceUID, [[fetchedObject valueForKey:@"studyInstanceUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
                    }
                    else if( key == DCM_SOPClassUID && [fetchedObject valueForKeyPath:@"series.seriesSOPClassUID"])
                    {
                        dataset->putAndInsertString(DCM_SOPClassUID, [[[[fetchedObject valueForKeyPath:@"series.seriesSOPClassUID"] allObjects] componentsJoinedByString:@"\\"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyID && [fetchedObject valueForKey:@"id"])
                    {
                        dataset->putAndInsertString(DCM_StudyID, [[fetchedObject valueForKey:@"id"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
                    }
                    else if( key == DCM_ModalitiesInStudy && [fetchedObject valueForKey:@"modality"])
                    {
                        NSMutableArray *modalities = [NSMutableArray array];
                    
                        BOOL SC = NO, SR = NO;
                        
                        for( NSString *m in [[fetchedObject valueForKeyPath:@"series.modality"] allObjects])
                        {
                            if( [modalities containsObject: m] == NO)
                            {
                                if( [m isEqualToString:@"SR"]) SR = YES;
                                else if( [m isEqualToString:@"SC"]) SC = YES;
                                else [modalities addObject: m];
                            }
                        }
                        
                        if( SC) [modalities addObject: @"SC"];
                        if( SR) [modalities addObject: @"SR"];
                    
                        dataset->putAndInsertString(DCM_ModalitiesInStudy, [[modalities componentsJoinedByString:@"\\"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ReferringPhysiciansName && [fetchedObject valueForKey:@"referringPhysician"])
                    {
                        dataset->putAndInsertString(DCM_ReferringPhysiciansName, [self encodeString: [fetchedObject valueForKey:@"referringPhysician"] image: image]);
                    }
                    else if( key == DCM_PerformingPhysiciansName && [fetchedObject valueForKey:@"performingPhysician"])
                    {
                        dataset->putAndInsertString(DCM_PerformingPhysiciansName, [self encodeString: [fetchedObject valueForKey:@"performingPhysician"] image: image]);
                    }
                    else if( key == DCM_InstitutionName && [fetchedObject valueForKey:@"institutionName"])
                    {
                        dataset->putAndInsertString(DCM_InstitutionName, [self encodeString: [fetchedObject valueForKey:@"institutionName"] image: image]);
                    }
                    else if( key == DCM_NumberOfStudyRelatedInstances && [fetchedObject valueForKey:@"noFiles"])
                    {
                        int numberInstances = [[fetchedObject valueForKey:@"rawNoFiles"] intValue];
                        char value[10];
                        sprintf(value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfStudyRelatedInstances, value);
                    }
                    else if( key == DCM_NumberOfStudyRelatedSeries && [fetchedObject valueForKey:@"series"])
                    {
                        int numberInstances = [[fetchedObject valueForKey:@"series"] count];
                        char value[10];
                        sprintf(value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfStudyRelatedSeries, value);
                    }
                    else dataset->insertEmptyElement( key, OFTrue);
                }
            }
            @catch( NSException *e)
            {
                N2LogException( e);
                dataset->print(COUT);
            }
		}
		
		dataset->putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
		
		if( specificCharacterSet)
			dataset->putAndInsertString(DCM_SpecificCharacterSet, [specificCharacterSet UTF8String]);
	}
	
	@catch (NSException *e)
	{
		NSLog( @"studyDatasetForFetchedObject exception: %@", e);
	}
}

- (void)seriesDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset
{
	@try
	{
		NSManagedObject *image = [[fetchedObject valueForKey: @"images"] anyObject];
		
		for( NSString *keyString in [findTemplate allKeys])
		{
            @try
            {
                NSArray *elementAndGroup = [keyString componentsSeparatedByString: @","];
                
                if( [elementAndGroup count] != 2)
                {
                    NSLog( @"***** seriesDatasetForFetchedObject ERROR");
                }
                else
                {
                    DcmTagKey key( [[elementAndGroup objectAtIndex: 1] intValue], [[elementAndGroup objectAtIndex: 0] intValue]);
                    
                    if( key == DCM_SeriesDescription && [fetchedObject valueForKey:@"name"])
                    {
                        dataset->putAndInsertString(DCM_SeriesDescription, [self encodeString: [fetchedObject valueForKey:@"name"] image: image]);
                    }
                    
                    else if( key == DCM_SeriesDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_SeriesDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_SeriesTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_SeriesTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_AcquisitionDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_AcquisitionDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_AcquisitionTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_AcquisitionTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_Modality && [fetchedObject valueForKey:@"modality"])
                    {
                        dataset->putAndInsertString(DCM_Modality, [[fetchedObject valueForKey:@"modality"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_SeriesNumber && [fetchedObject valueForKey:@"id"])
                    {
                        dataset->putAndInsertString( DCM_SeriesNumber, [[[fetchedObject valueForKey:@"id"] stringValue] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_SeriesInstanceUID && [fetchedObject valueForKey:@"seriesDICOMUID"])
                    {
                        dataset->putAndInsertString(DCM_SeriesInstanceUID, [[fetchedObject valueForKey:@"seriesDICOMUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_NumberOfSeriesRelatedInstances && [fetchedObject valueForKey:@"noFiles"])
                    {
                        int numberInstances = [[fetchedObject valueForKey:@"rawNoFiles"] intValue];
                        char value[ 20];
                        sprintf( value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfSeriesRelatedInstances, value);
                    }
                    
                    // ******************** STUDY
                    
                    else if( key == DCM_PatientsName && [fetchedObject valueForKeyPath:@"study.name"])
                    {
                        dataset->putAndInsertString(DCM_PatientsName, [self encodeString: [fetchedObject valueForKeyPath:@"study.name"] image: image]);
                    }
                    
                    else if( key == DCM_PatientID && [fetchedObject valueForKeyPath:@"study.patientID"])
                    {
                        dataset->putAndInsertString(DCM_PatientID, [self encodeString: [fetchedObject valueForKeyPath:@"study.patientID"] image: image]);
                    }
                    
                    else if( key == DCM_PatientsSex && [fetchedObject valueForKeyPath:@"study.patientSex"])
                    {
                        dataset->putAndInsertString(DCM_PatientsSex, [self encodeString: [fetchedObject valueForKeyPath:@"study.patientSex"] image: image]);
                    }
                    
                    else if( key == DCM_AccessionNumber && [fetchedObject valueForKeyPath:@"study.accessionNumber"])
                    {
                        dataset->putAndInsertString(DCM_AccessionNumber, [self encodeString: [fetchedObject valueForKeyPath:@"study.accessionNumber"] image: image]);
                    }
                    
                    else if( key == DCM_StudyDescription && [fetchedObject valueForKeyPath:@"study.studyName"])
                    {
                        dataset->putAndInsertString( DCM_StudyDescription, [self encodeString: [fetchedObject valueForKeyPath:@"study.studyName"] image: image]);
                    }
                    
                    else if( key == DCM_ImageComments && [fetchedObject valueForKeyPath:@"comment"])
                    {
                        dataset->putAndInsertString( DCM_ImageComments, [self encodeString: [fetchedObject valueForKeyPath:@"comment"] image: image]);
                    }
                    
                    else if( key == DCM_InterpretationStatusID && [fetchedObject valueForKeyPath:@"study.stateText"])
                    {
                        dataset->putAndInsertString( DCM_InterpretationStatusID, [self encodeString: [[fetchedObject valueForKeyPath:@"study.stateText"] stringValue] image: image]);
                    }
                    else if( key == DCM_StudyComments && [fetchedObject valueForKeyPath:@"study.comment"])
                    {
                        dataset->putAndInsertString( DCM_StudyComments, [self encodeString: [fetchedObject valueForKeyPath:@"study.comment"] image: image]);
                    }
                    
                    else if( key == DCM_PatientsBirthDate && [fetchedObject valueForKeyPath:@"study.dateOfBirth"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKeyPath:@"study.dateOfBirth"]];
                        dataset->putAndInsertString(DCM_PatientsBirthDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyDate && [fetchedObject valueForKeyPath:@"study.date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKeyPath:@"study.date"]];
                        dataset->putAndInsertString(DCM_StudyDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyTime && [fetchedObject valueForKeyPath:@"study.date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKeyPath:@"study.date"]];
                        dataset->putAndInsertString(DCM_StudyTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyInstanceUID && [fetchedObject valueForKeyPath:@"study.studyInstanceUID"])
                    {
                        dataset->putAndInsertString(DCM_StudyInstanceUID, [[fetchedObject valueForKeyPath:@"study.studyInstanceUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
                    }
                    else if( key == DCM_SOPClassUID && [fetchedObject valueForKey:@"seriesSOPClassUID"])
                    {
                        dataset->putAndInsertString(DCM_SOPClassUID, [[fetchedObject valueForKey:@"seriesSOPClassUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyID && [fetchedObject valueForKeyPath:@"study.id"])
                    {
                        dataset->putAndInsertString(DCM_StudyID, [[fetchedObject valueForKeyPath:@"study.id"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
                    }
                    else if( key == DCM_ModalitiesInStudy && [fetchedObject valueForKeyPath:@"study.modality"])
                    {
                        NSMutableArray *modalities = [NSMutableArray array];
                    
                        BOOL SC = NO, SR = NO;
                        
                        NSManagedObject *study = [fetchedObject valueForKeyPath:@"study"];
                        
                        for( NSString *m in [[study valueForKeyPath:@"modality"] allObjects])
                        {
                            if( [modalities containsObject: m] == NO)
                            {
                                if( [m isEqualToString:@"SR"]) SR = YES;
                                else if( [m isEqualToString:@"SC"]) SC = YES;
                                else [modalities addObject: m];
                            }
                        }
                        
                        if( SC) [modalities addObject: @"SC"];
                        if( SR) [modalities addObject: @"SR"];
                    
                        dataset->putAndInsertString(DCM_ModalitiesInStudy, [[modalities componentsJoinedByString:@"\\"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ReferringPhysiciansName && [fetchedObject valueForKeyPath:@"study.referringPhysician"])
                    {
                        dataset->putAndInsertString(DCM_ReferringPhysiciansName, [self encodeString: [fetchedObject valueForKeyPath:@"study.referringPhysician"] image: image]);
                    }
                    else if( key == DCM_PerformingPhysiciansName && [fetchedObject valueForKeyPath:@"study.performingPhysician"])
                    {
                        dataset->putAndInsertString(DCM_PerformingPhysiciansName, [self encodeString: [fetchedObject valueForKeyPath:@"study.performingPhysician"] image: image]);
                    }
                    else if( key == DCM_InstitutionName && [fetchedObject valueForKeyPath:@"study.institutionName"])
                    {
                        dataset->putAndInsertString(DCM_InstitutionName, [self encodeString: [fetchedObject valueForKeyPath:@"study.institutionName"] image: image]);
                    }
                    else if( key == DCM_NumberOfStudyRelatedInstances && [fetchedObject valueForKeyPath:@"study.noFiles"])
                    {
                        int numberInstances = [[fetchedObject valueForKeyPath:@"study.rawNoFiles"] intValue];
                        char value[10];
                        sprintf(value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfStudyRelatedInstances, value);
                    }
                    else if( key == DCM_NumberOfStudyRelatedSeries)
                    {
                        NSManagedObject *study = [fetchedObject valueForKeyPath:@"study"];
                        
                        int numberInstances = [[study valueForKeyPath:@"series"] count];
                        char value[10];
                        sprintf(value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfStudyRelatedSeries, value);
                    }
                    
                    else dataset ->insertEmptyElement( key, OFTrue);
                }
            }
            @catch( NSException *e)
            {
                N2LogException( e);
                dataset->print(COUT);
            }
        }
    
		dataset->putAndInsertString(DCM_QueryRetrieveLevel, "SERIES");
		if( specificCharacterSet)
			dataset->putAndInsertString(DCM_SpecificCharacterSet, [specificCharacterSet UTF8String]);
	}
	@catch( NSException *e)
	{
		N2LogException( e);
		dataset->print(COUT);
	}
}

- (void)imageDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset
{
	@try
	{
		NSManagedObject *image = fetchedObject;
		
		for( NSString *keyString in [findTemplate allKeys])
		{
			NSArray *elementAndGroup = [keyString componentsSeparatedByString: @","];
			
            @try
            {
                if( [elementAndGroup count] != 2)
                {
                    NSLog( @"***** imageDatasetForFetchedObject ERROR");
                }
                else
                {
                    DcmTagKey key( [[elementAndGroup objectAtIndex: 1] intValue], [[elementAndGroup objectAtIndex: 0] intValue]);
                    
                    if( key == DCM_SliceLocation && [fetchedObject valueForKey: @"sliceLocation"])
                    {
                        dataset->putAndInsertString( key, [[[fetchedObject valueForKey:@"sliceLocation"] stringValue] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_SOPInstanceUID && [fetchedObject valueForKey: @"sopInstanceUID"])
                    {
                        dataset->putAndInsertString( key, [[fetchedObject valueForKey:@"sopInstanceUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_InstanceNumber && [fetchedObject valueForKey: @"instanceNumber"])
                    {
                        dataset->putAndInsertString( key, [[[fetchedObject valueForKey:@"instanceNumber"] stringValue] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_NumberOfFrames && [fetchedObject valueForKey: @"numberOfFrames"])
                    {
                        if( [DCMAbstractSyntaxUID isImageStorage: [fetchedObject valueForKeyPath: @"series.seriesSOPClassUID"]])
                            dataset->putAndInsertString( key, [[[fetchedObject valueForKey:@"numberOfFrames"] stringValue] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ContentDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_ContentDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ContentTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_ContentTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_AcquisitionDate && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_AcquisitionDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_AcquisitionTime && [fetchedObject valueForKey:@"date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
                        dataset->putAndInsertString(DCM_AcquisitionTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    // ******************** SERIES
                    
                    else if( key == DCM_ImageComments)
                    {
                        if( [(NSString*) [fetchedObject valueForKeyPath: @"series.comment"] length] > 0)
                        {
                            dataset->putAndInsertString( key, [self encodeString: [fetchedObject valueForKeyPath:@"series.comment"] image: image]);
                        }
                        else if( [(NSString*) [fetchedObject valueForKeyPath: @"series.study.comment"] length] > 0)
                        {
                            dataset->putAndInsertString( key, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.comment"] image: image]);
                        }
                        else dataset ->insertEmptyElement( key, OFTrue);
                    }
                    
                    else if( key == DCM_SeriesDescription && [fetchedObject valueForKeyPath: @"series.name"])
                    {
                        dataset->putAndInsertString(DCM_SeriesDescription, [self encodeString: [fetchedObject valueForKeyPath:@"series.name"] image: image]);
                    }
                    
                    else if( key == DCM_SeriesDate && [fetchedObject valueForKeyPath:@"series.date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKeyPath:@"series.date"]];
                        dataset->putAndInsertString(DCM_SeriesDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_SeriesTime && [fetchedObject valueForKeyPath:@"series.date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKeyPath:@"series.date"]];
                        dataset->putAndInsertString(DCM_SeriesTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_Modality && [fetchedObject valueForKeyPath:@"series.modality"])
                    {
                        dataset->putAndInsertString(DCM_Modality, [[fetchedObject valueForKeyPath:@"series.modality"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_SeriesNumber && [fetchedObject valueForKeyPath:@"series.id"])
                    {
                        dataset->putAndInsertString( DCM_SeriesNumber, [[[fetchedObject valueForKeyPath:@"series.id"] stringValue] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_SeriesInstanceUID && [fetchedObject valueForKeyPath:@"series.seriesDICOMUID"])
                    {
                        dataset->putAndInsertString(DCM_SeriesInstanceUID, [[fetchedObject valueForKeyPath:@"series.seriesDICOMUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    
                    else if( key == DCM_NumberOfSeriesRelatedInstances && [fetchedObject valueForKeyPath:@"series.noFiles"])
                    {
                        int numberInstances = [[fetchedObject valueForKeyPath:@"series.rawNoFiles"] intValue];
                        char value[ 20];
                        sprintf( value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfSeriesRelatedInstances, value);
                    }
                    
                    // ******************** STUDY
                    
                    else if( key == DCM_PatientsName && [fetchedObject valueForKeyPath:@"series.study.name"])
                    {
                        dataset->putAndInsertString(DCM_PatientsName, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.name"] image: image]);
                    }
                    
                    else if( key == DCM_PatientID && [fetchedObject valueForKeyPath:@"series.study.patientID"])
                    {
                        dataset->putAndInsertString(DCM_PatientID, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.patientID"] image: image]);
                    }
                    
                    else if( key == DCM_PatientsSex && [fetchedObject valueForKeyPath:@"series.study.patientSex"])
                    {
                        dataset->putAndInsertString(DCM_PatientsSex, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.patientSex"] image: image]);
                    }
                    
                    else if( key == DCM_AccessionNumber && [fetchedObject valueForKeyPath:@"series.study.accessionNumber"])
                    {
                        dataset->putAndInsertString(DCM_AccessionNumber, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.accessionNumber"] image: image]);
                    }
                    
                    else if( key == DCM_StudyDescription && [fetchedObject valueForKeyPath:@"series.study.studyName"])
                    {
                        dataset->putAndInsertString( DCM_StudyDescription, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.studyName"] image: image]);
                    }
                    
                    else if( key == DCM_InterpretationStatusID && [fetchedObject valueForKeyPath:@"series.study.stateText"])
                    {
                        dataset->putAndInsertString( DCM_InterpretationStatusID, [self encodeString: [[fetchedObject valueForKeyPath:@"series.study.stateText"] stringValue] image: image]);
                    }
                    else if( key == DCM_StudyComments && [fetchedObject valueForKeyPath:@"series.study.comment"])
                    {
                        dataset->putAndInsertString( DCM_ImageComments, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.comment"] image: image]);
                    }
                    else if( key == DCM_PatientsBirthDate && [fetchedObject valueForKeyPath:@"series.study.dateOfBirth"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKeyPath:@"series.study.dateOfBirth"]];
                        dataset->putAndInsertString(DCM_PatientsBirthDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyDate && [fetchedObject valueForKeyPath:@"series.study.date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKeyPath:@"series.study.date"]];
                        dataset->putAndInsertString(DCM_StudyDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyTime && [fetchedObject valueForKeyPath:@"series.study.date"])
                    {
                        DCMCalendarDate *dicomDate = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKeyPath:@"series.study.date"]];
                        dataset->putAndInsertString(DCM_StudyTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyInstanceUID && [fetchedObject valueForKeyPath:@"series.study.studyInstanceUID"])
                    {
                        dataset->putAndInsertString(DCM_StudyInstanceUID, [[fetchedObject valueForKeyPath:@"series.study.studyInstanceUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
                    }
                    else if( key == DCM_SOPClassUID && [fetchedObject valueForKeyPath:@"series.seriesSOPClassUID"])
                    {
                        dataset->putAndInsertString(DCM_SOPClassUID, [[fetchedObject valueForKeyPath:@"series.seriesSOPClassUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_StudyID && [fetchedObject valueForKeyPath:@"series.study.id"])
                    {
                        dataset->putAndInsertString(DCM_StudyID, [[fetchedObject valueForKeyPath:@"series.study.id"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
                    }
                    else if( key == DCM_ModalitiesInStudy && [fetchedObject valueForKeyPath:@"series.study.modality"])
                    {
                        NSMutableArray *modalities = [NSMutableArray array];
                    
                        BOOL SC = NO, SR = NO;
                        
                        NSManagedObject *study = [fetchedObject valueForKeyPath:@"series.study"];
                        
                        for( NSString *m in [[study valueForKeyPath:@"series.modality"] allObjects])
                        {
                            if( [modalities containsObject: m] == NO)
                            {
                                if( [m isEqualToString:@"SR"]) SR = YES;
                                else if( [m isEqualToString:@"SC"]) SC = YES;
                                else [modalities addObject: m];
                            }
                        }
                        
                        if( SC) [modalities addObject: @"SC"];
                        if( SR) [modalities addObject: @"SR"];
                    
                        dataset->putAndInsertString(DCM_ModalitiesInStudy, [[modalities componentsJoinedByString:@"\\"] cStringUsingEncoding:NSISOLatin1StringEncoding]);
                    }
                    else if( key == DCM_ReferringPhysiciansName && [fetchedObject valueForKeyPath:@"series.study.referringPhysician"])
                    {
                        dataset->putAndInsertString(DCM_ReferringPhysiciansName, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.referringPhysician"] image: image]);
                    }
                    else if( key == DCM_PerformingPhysiciansName && [fetchedObject valueForKeyPath:@"series.study.performingPhysician"])
                    {
                        dataset->putAndInsertString(DCM_PerformingPhysiciansName, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.performingPhysician"] image: image]);
                    }
                    else if( key == DCM_InstitutionName && [fetchedObject valueForKeyPath:@"series.study.institutionName"])
                    {
                        dataset->putAndInsertString(DCM_InstitutionName, [self encodeString: [fetchedObject valueForKeyPath:@"series.study.institutionName"] image: image]);
                    }
                    else if( key == DCM_NumberOfStudyRelatedInstances && [fetchedObject valueForKeyPath:@"series.study.noFiles"])
                    {
                        int numberInstances = [[fetchedObject valueForKeyPath:@"series.study.rawNoFiles"] intValue];
                        char value[10];
                        sprintf(value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfStudyRelatedInstances, value);
                    }
                    else if( key == DCM_NumberOfStudyRelatedSeries)
                    {
                        NSManagedObject *study = [fetchedObject valueForKeyPath:@"series.study"];
                        
                        int numberInstances = [[study valueForKeyPath:@"series"] count];
                        char value[10];
                        sprintf(value, "%d", numberInstances);
                        dataset->putAndInsertString(DCM_NumberOfStudyRelatedSeries, value);
                    }
                    
                    else
                        dataset ->insertEmptyElement( key, OFTrue);
                }
            }
            @catch( NSException *e)
            {
                N2LogException( e);
                dataset->print(COUT);
            }
		}
		dataset->putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
		if( specificCharacterSet)
			dataset->putAndInsertString(DCM_SpecificCharacterSet, [specificCharacterSet UTF8String]);
	}
	
	@catch( NSException *e)
	{
		NSLog( @"********* imageDatasetForFetchedObject exception: %@", e);
		dataset->print(COUT);
	}
}

- (OFCondition)prepareFindForDataSet: (DcmDataset *) dataset
{
    NSPredicate *compressedSOPInstancePredicate = nil, *seriesLevelPredicate = nil;
	NSPredicate *predicate = [self predicateForDataset: dataset compressedSOPInstancePredicate: &compressedSOPInstancePredicate seriesLevelPredicate: &seriesLevelPredicate];
    
	NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;
	NSError *error = nil;
	NSEntityDescription *entity;
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    
    OFCondition cond = EC_Normal;
    
    @try
    {
        const char *sType;
        dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
        
        [findTemplate release];
        findTemplate = [[NSMutableDictionary alloc] init];
        
        int elemCount = (int)(dataset->card());
        for (int elemIndex=0; elemIndex<elemCount; elemIndex++)
        {
            DcmElement* dcelem = dataset->getElement(elemIndex);
            DcmTagKey key = dcelem->getTag().getXTag();
            
            [findTemplate setObject: [NSNumber numberWithBool: YES] forKey: [NSString stringWithFormat: @"%d,%d", key.getElement(), key.getGroup()]];
        }
        
        if (strcmp(sType, "STUDY") == 0) 
            entity = [[model entitiesByName] objectForKey:@"Study"];
        else if (strcmp(sType, "SERIES") == 0) 
            entity = [[model entitiesByName] objectForKey:@"Series"];
        else if (strcmp(sType, "IMAGE") == 0) 
            entity = [[model entitiesByName] objectForKey:@"Image"];
        else 
            entity = nil;
        
        if (entity)
        {
            [request setEntity: entity];
            [request setPredicate: predicate];
                        
            error = nil;
            
            [findArray release];
            findArray = nil;
            
            NSArray *tempFindArray = [NSArray array];
            
            @try
            {
                if( seriesLevelPredicate) // First find at series level, then move to image level
                {
                    NSFetchRequest *seriesRequest = [[[NSFetchRequest alloc] init] autorelease];
                    
                    [seriesRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
                    [seriesRequest setPredicate: seriesLevelPredicate];
                    
                    NSArray *newObjects = nil;
                    NSArray *allSeries = [NSArray array];
                    
                    int total = [context countForFetchRequest: seriesRequest error: &error];
                    
                    [seriesRequest setFetchLimit: FETCHNUMBER];
                    do
                    {
                        newObjects = [context executeFetchRequest: seriesRequest error: &error];
                        allSeries = [allSeries arrayByAddingObjectsFromArray: newObjects];
                        
                        [seriesRequest setFetchOffset: [seriesRequest fetchOffset] + FETCHNUMBER];
                        
                        if( [NSThread currentThread].isCancelled)
                            break;
                        
                        if( total)
                            [[NSThread currentThread] setProgress: (float) tempFindArray.count / (float) total];
                    }
                    while( [newObjects count]);
                    
                    for( id series in allSeries)
                        tempFindArray = [tempFindArray arrayByAddingObjectsFromArray: [[series valueForKey: @"images"] allObjects]];
                    
                    tempFindArray = [tempFindArray filteredArrayUsingPredicate: predicate];
                }
                else
                {
                    NSArray *newObjects = nil;
                    
                    int total = [context countForFetchRequest: request error: &error];
                    
                    [request setFetchLimit: FETCHNUMBER];
                    do
                    {
                        newObjects = [context executeFetchRequest: request error: &error];
                        tempFindArray = [tempFindArray arrayByAddingObjectsFromArray: newObjects];
                        
                        [request setFetchOffset: [request fetchOffset] + FETCHNUMBER];
                        
                        if( [NSThread currentThread].isCancelled)
                            break;
                        
                        if( total)
                            [[NSThread currentThread] setProgress: (float) tempFindArray.count / (float) total];
                    }
                    while( [newObjects count]);
                }
                
                if( strcmp(sType, "IMAGE") == 0 && compressedSOPInstancePredicate)
                    tempFindArray = [tempFindArray filteredArrayUsingPredicate: compressedSOPInstancePredicate];
                
                if( strcmp(sType, "IMAGE") == 0)
                    tempFindArray = [tempFindArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"instanceNumber" ascending: YES] autorelease]]];
                
                if( strcmp(sType, "SERIES") == 0)
                  tempFindArray = [tempFindArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending: YES] autorelease]]];
                
                if (strcmp(sType, "STUDY") == 0 || strcmp(sType, "SERIES") == 0) // Only at series or study level
                {
                    if( [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"] > 0 && tempFindArray.count > [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"])
                    {
                        NSLog( @"----- C-Find maximumNumberOfCFindObjects reached: %d, %d", (int) tempFindArray.count, (int) [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"]);
                        tempFindArray = [tempFindArray subarrayWithRange: NSMakeRange( 0, [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfCFindObjects"])];
                    }
                }
                
                if( strcmp(sType, "IMAGE") == 0) //Only ONE DICOM "instance" : multiple frames are stored in multiple instance in OsiriX DB
                {
                    NSMutableArray *mutableTempFindArray = [NSMutableArray arrayWithArray: tempFindArray];
                    NSMutableArray *imagePaths = [NSMutableArray arrayWithArray: [tempFindArray valueForKey:@"completePath"]];
                    [imagePaths removeDuplicatedStringsInSyncWithThisArray: mutableTempFindArray];
                    
                    tempFindArray = mutableTempFindArray;
                }
                
                findArray = [[NSArray alloc] initWithArray: tempFindArray];
            }
            @catch (NSException * e)
            {
                NSLog( @"prepareFindForDataSet exception");
                NSLog( @"%@", [e description]);
            }
            
            if (error)
            {
                [findArray release];
                findArray = nil;
                cond = EC_IllegalParameter;
            }
            else
                cond = EC_Normal;
        }
        else
        {
            [findArray release];
            findArray = nil;
            
            cond = EC_IllegalParameter;
        }
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
    
	[findEnumerator release];
	findEnumerator = [[findArray objectEnumerator] retain];
    findEnumeratorIndex = 0;
	
	return cond;
}

- (void) updateLog:(NSArray*) mArray
{
	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO) return;
	if( [mArray count] == 0) return;
	
	[logDictionary removeAllObjects];
	
    if( logDictionary == nil)
        logDictionary = [NSMutableDictionary new];
    
    NSString *fromTo = nil;
	if (!currentDestinationMoveAET[0] || !strcmp(currentDestinationMoveAET, [callingAET UTF8String]))
		fromTo = [NSString stringWithFormat: @"%@", callingAET];
	else
        fromTo = [NSString stringWithFormat: @"%@ / %s", callingAET, currentDestinationMoveAET];
	
	
    NSManagedObject *object = [mArray objectAtIndex: 0];
    
    [logDictionary setObject: fromTo forKey: @"logCallingAET"];
    [logDictionary setObject: [NSDate date] forKey: @"logStartTime"];
    [logDictionary setObject: [NSDate date] forKey: @"logEndTime"];
    [logDictionary setObject: @"In Progress" forKey: @"logMessage"];
    [logDictionary setObject: [NSNumber numberWithInt: 0] forKey: @"logNumberReceived"];
    [logDictionary setObject: @"Move" forKey: @"logType"];
    [logDictionary setObject: @"UTF-8" forKey: @"logEncoding"];
    
    unsigned int random = (unsigned int)time(NULL);
    unsigned int random2 = rand();
    
    [logDictionary setObject: [NSString stringWithFormat: @"%d%d%@", random, random2, [logDictionary objectForKey: @"logPatientName"]] forKey: @"logUID"];
    
    if( [[object valueForKey:@"type"] isEqualToString: @"Series"])
    {
        [logDictionary setObject: [object valueForKeyPath:@"study.name"] forKey: @"logPatientName"];
        [logDictionary setObject: [object valueForKeyPath:@"study.studyName"] forKey: @"logStudyDescription"];
        [logDictionary setObject: [NSNumber numberWithInt: [[object valueForKey: @"rawNoFiles"] intValue]] forKey: @"logNumberTotal"];
    }
    else if( [[object valueForKey:@"type"] isEqualToString: @"Study"])
    {
        [logDictionary setObject: [object valueForKeyPath:@"name"] forKey: @"logPatientName"];
        [logDictionary setObject: [object valueForKeyPath:@"studyName"] forKey: @"logStudyDescription"];
        [logDictionary setObject: [NSNumber numberWithInt: [[object valueForKey: @"rawNoFiles"] intValue]] forKey: @"logNumberTotal"];
    }
    else if( [[object valueForKey:@"type"] isEqualToString: @"Image"])
    {
        [logDictionary setObject: [object valueForKeyPath:@"series.study.name"] forKey: @"logPatientName"];
        [logDictionary setObject: [object valueForKeyPath:@"series.study.studyName"] forKey: @"logStudyDescription"];
        [logDictionary setObject: [NSNumber numberWithInt: mArray.count] forKey: @"logNumberTotal"];
    }
    
    [[LogManager currentLogManager] addLogLine: logDictionary];
}

- (OFCondition)prepareMoveForDataSet:( DcmDataset *)dataset
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	OFCondition cond = EC_IllegalParameter;
	@try 
	{
        NSPredicate *compressedSOPInstancePredicate = nil, *seriesLevelPredicate = nil;
		NSPredicate *predicate = [self predicateForDataset:dataset compressedSOPInstancePredicate: &compressedSOPInstancePredicate seriesLevelPredicate: &seriesLevelPredicate];
        
		NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;
		NSError *error = nil;
		NSEntityDescription *entity;
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        
		const char *sType;
		dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
        
		if (strcmp(sType, "STUDY") == 0) 
			entity = [[model entitiesByName] objectForKey:@"Study"];
		else if (strcmp(sType, "SERIES") == 0) 
			entity = [[model entitiesByName] objectForKey:@"Series"];
		else if (strcmp(sType, "IMAGE") == 0) 
			entity = [[model entitiesByName] objectForKey:@"Image"];
		else 
			entity = nil;
		
		[request setEntity: entity];
		[request setPredicate: predicate];
		
		error = nil;
		
		NSArray *array = [NSArray array];
		
		@try
		{
			if( seriesLevelPredicate) // First find at series level, then move to image level
			{
				NSFetchRequest *seriesRequest = [[[NSFetchRequest alloc] init] autorelease];
				
				[seriesRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
				[seriesRequest setPredicate: seriesLevelPredicate];
				
                
                NSArray *newObjects = nil;
                NSArray *allSeries = [NSArray array];
                
                int total = [context countForFetchRequest: seriesRequest error: &error];
                
                [seriesRequest setFetchLimit: FETCHNUMBER];
                do
                {
                    newObjects = [context executeFetchRequest: seriesRequest error: &error];
                    allSeries = [allSeries arrayByAddingObjectsFromArray: newObjects];
                    
                    [seriesRequest setFetchOffset: [seriesRequest fetchOffset] + FETCHNUMBER];
                    
                    if( [NSThread currentThread].isCancelled)
                        break;
                    
                    if( total)
                        [[NSThread currentThread] setProgress: (float) allSeries.count / (float) total];
                }
                while( [newObjects count]);
				
				for( id series in allSeries)
					array = [array arrayByAddingObjectsFromArray: [[series valueForKey: @"images"] allObjects]];
				
				array = [array filteredArrayUsingPredicate: predicate];
			}
			else
            {
                NSArray *newObjects = nil;
                
                int total = [context countForFetchRequest: request error: &error];
                
                [request setFetchLimit: FETCHNUMBER];
                do
                {
                    newObjects = [context executeFetchRequest: request error: &error];
                    array = [array arrayByAddingObjectsFromArray: newObjects];
                    
                    [request setFetchOffset: [request fetchOffset] + FETCHNUMBER];
                    
                    if( [NSThread currentThread].isCancelled)
                        break;
                    
                    if( total)
                        [[NSThread currentThread] setProgress: (float) array.count / (float) total];
                }
                while( [newObjects count]);
			}
			
			if( strcmp(sType, "IMAGE") == 0 && compressedSOPInstancePredicate)
				array = [array filteredArrayUsingPredicate: compressedSOPInstancePredicate];
			
			if( [array count] == 0)
			{
				// not found !!!!
			}
			
			if (error)
			{
				[moveArray release];
                moveArray = nil;
				
				cond = EC_IllegalParameter;
			}
			else
			{
				NSEnumerator *enumerator = [array objectEnumerator];
				id moveEntity;
				
				[self updateLog: array];
				
				NSMutableSet *moveSet = [NSMutableSet set];
				while (moveEntity = [enumerator nextObject])
					[moveSet unionSet:[moveEntity valueForKey:@"pathsForForkedProcess"]];
				
                [moveArray release];
                moveArray = [[[moveSet allObjects] sortedArrayUsingSelector:@selector(compare:)] retain];
				
				cond = EC_Normal;
			}
		}
		@catch (NSException * e)
		{
			NSLog( @"prepareMoveForDataSet exception");
			NSLog( @"%@", [e description]);
			NSLog( @"%@", [predicate description]);
		}
        
        if( forkedProcess)
        {
            // TO AVOID DEADLOCK
            // See DcmQueryRetrieveSCP::unlockFile dcmqrsrv.mm
            BOOL fileExist = YES;
            char dir[ 1024];
            sprintf( dir, "%s-%d", "/tmp/lock_process", getpid());
            
            int inc = 0;
            do
            {
                int err = unlink( dir);
                if( err  == 0 || errno == ENOENT) fileExist = NO;
                
                usleep( 1000);
                inc++;
            }
            while( fileExist == YES && inc < 100000);
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	[pool release];
	
	return cond;
}

- (BOOL)findMatchFound
{
	if (findArray) return YES;
	return NO;
}

- (int)moveMatchFound
{
	return moveArray.count;
}

- (OFCondition) nextFindObject:(DcmDataset *)dataset isComplete:(BOOL *)isComplete
{
	id item;
	
	@try
	{
		if (item = [findEnumerator nextObject])
		{
			if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
			{
				 [self seriesDatasetForFetchedObject:item dataset:(DcmDataset *)dataset];
			}
			else if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
			{
				[self studyDatasetForFetchedObject:item dataset:(DcmDataset *)dataset];
			}
			else if ([[item valueForKey:@"type"] isEqualToString:@"Image"])
			{
				[self imageDatasetForFetchedObject:item dataset:(DcmDataset *)dataset];
			}
			*isComplete = NO;
		}
		else
		{
			*isComplete = YES;
		}
        
        if( findArray.count)
            [[NSThread currentThread] setProgress: (float) (findEnumeratorIndex++) / (float) findArray.count];
        
        if( [NSThread currentThread].isCancelled)
            *isComplete = YES;
	}
	
	@catch (NSException * e)
	{
		NSLog( @"******* nextFindObject exception : %@", e);
	}
	
	return EC_Normal;
}

- (OFCondition)nextMoveObject:(char *)imageFileName
{
	OFCondition ret = EC_Normal;
	
    if( [NSThread currentThread].isCancelled)
        return EC_IllegalParameter;
    
	if( moveArrayEnumerator >= moveArray.count)
		return EC_IllegalParameter;
	
    if( moveArray == nil)
        return EC_IllegalParameter;
    
    strcpy(imageFileName, [[moveArray objectAtIndex: moveArrayEnumerator] UTF8String]);
    
	moveArrayEnumerator++;
	
	if( logDictionary)
	{
        if( moveArrayEnumerator >= moveArray.count)
            [logDictionary setObject: @"Complete" forKey: @"logMessage"];
        
        [logDictionary setObject: [NSNumber numberWithInt: [[logDictionary objectForKey: @"logNumberReceived"] intValue] + 1] forKey: @"logNumberReceived"];
        [logDictionary setObject: [NSDate date] forKey: @"logEndTime"];
        
        [[LogManager currentLogManager] addLogLine: logDictionary];
	}
    
	if( moveArrayEnumerator >= moveArray.count)
	{
		[logDictionary release];
        logDictionary = nil;
	}

	return ret;
}

@end
