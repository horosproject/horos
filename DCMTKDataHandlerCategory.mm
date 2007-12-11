//
//  DCMTKDataHandlerCategory.mm
//  OsiriX
//
//  Created by Lance Pysher on 3/23/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMTKDataHandlerCategory.h"
#import "DICOMToNSString.h"
#include "dctk.h"

#import "browserController.h"


@implementation OsiriXSCPDataHandler (DCMTKDataHandlerCategory)

- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset{

	//NSPredicate *compoundPredicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
	NSPredicate *compoundPredicate = nil;
	const char *sType = NULL;
	const char *scs = NULL;
	//NSString *charset;	
	//should be STUDY, SERIES OR IMAGE
	NS_DURING 
	dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
	
	//NSLog(@"get Specific Character set");
	if (dataset->findAndGetString (DCM_SpecificCharacterSet, scs, OFFalse).good() && scs != NULL) {
		[specificCharacterSet release];
		specificCharacterSet = [[NSString stringWithCString:scs] retain];
		encoding = [NSString encodingForDICOMCharacterSet:specificCharacterSet];
	}
	else {
		[specificCharacterSet release];
		specificCharacterSet = [[NSString stringWithString:@"ISO_IR 100"] retain];
		encoding = NSISOLatin1StringEncoding;
	}
	
	if (strcmp(sType, "STUDY") == 0) 
		compoundPredicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
	else
		compoundPredicate = [NSPredicate predicateWithValue:YES];
		
	//NSLog(@"charset %@", specificCharacterSet);
		
	
	int elemCount = (int)(dataset->card());
    for (int elemIndex=0; elemIndex<elemCount; elemIndex++) {
		NSPredicate *predicate = nil;
		DcmElement* dcelem = dataset->getElement(elemIndex);
		DcmTagKey key = dcelem->getTag().getXTag();
		//printf("elemindex: %d key: %s\n",elemIndex, key.toString().c_str());
		if (strcmp(sType, "STUDY") == 0) {
			compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:
						[NSArray arrayWithObjects: compoundPredicate, nil]];
			if (key == DCM_PatientsName){
				char *pn;
				if (dcelem->getString(pn).good() && pn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", [NSString stringWithCString:pn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_PatientID){
				char *pid;
				if (dcelem->getString(pid).good() && pid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"patientID LIKE[cd] %@", [NSString stringWithCString:pid  DICOMEncoding:nil]];
			}
			else if (key == DCM_AccessionNumber){
				char *pid;
				if (dcelem->getString(pid).good() && pid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"accessionNumber LIKE[cd] %@", [NSString stringWithCString:pid  DICOMEncoding:nil]];
			}
			else if (key == DCM_StudyInstanceUID ){
				char *suid;
				if (dcelem->getString(suid).good() && suid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [NSString stringWithCString:suid  DICOMEncoding:nil]];
			}
			else if (key == DCM_StudyID ) {
				char *sid;
				if (dcelem->getString(sid).good() && sid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:sid  DICOMEncoding:nil]];
			}
			else if (key ==  DCM_StudyDescription) {
				char *sd;
				if (dcelem->getString(sd).good() && sd != NULL)
					predicate = [NSPredicate predicateWithFormat:@"studyName LIKE[cd] %@", [NSString stringWithCString:sd  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_InstitutionName) {
				char *inn;
				if (dcelem->getString(inn).good() && inn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"institutionName LIKE[cd] %@", [NSString stringWithCString:inn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_ReferringPhysiciansName) {
				char *rpn;
				if (dcelem->getString(rpn).good() && rpn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"referringPhysician LIKE[cd] %@", [NSString stringWithCString:rpn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_PerformingPhysiciansName) {
				char *ppn;
				if (dcelem->getString(ppn).good() && ppn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"performingPhysician LIKE[cd] %@", [NSString stringWithCString:ppn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_ModalitiesInStudy) {
				char *mis;
				if (dcelem->getString(mis).good() && mis != NULL)
					predicate = [NSPredicate predicateWithFormat:@"modality LIKE[cd] %@", [NSString stringWithCString:mis  DICOMEncoding:nil]];
			}
			
			else if (key == DCM_PatientsBirthDate) {
				//NSLog(@"BirthDate");
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good() && aDate != NULL) {
					NSString *dateString = [NSString stringWithCString:aDate DICOMEncoding:nil];
					value = [DCMCalendarDate dicomDate:dateString];
				}
				//NSLog(@"StudyDate decoded");
				if (!value) {
					predicate = nil;
				}
				else
				{
					predicate = [NSPredicate predicateWithFormat:@"(dateOfBirth >= CAST(%lf, \"NSDate\")) AND (dateOfBirth < CAST(%lf, \"NSDate\"))", [self startOfDay:value], [self endOfDay:value]];
				}
			}
			
			else if (key == DCM_StudyDate) {
				//NSLog(@"StudyDate");
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good() && aDate != NULL) {
					NSString *dateString = [NSString stringWithCString:aDate DICOMEncoding:nil];
					value = [DCMCalendarDate dicomDate:dateString];
				}
				//NSLog(@"StudyDate decoded");
				if (!value) {
					predicate = nil;
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			

					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%lf, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					//value = [attr value];
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						DCMCalendarDate *startDate = [DCMCalendarDate dicomDate:[values objectAtIndex:0]];
						DCMCalendarDate *endDate = [DCMCalendarDate dicomDate:[values objectAtIndex:1]];

						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\")", [self startOfDay:startDate]];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")",[self endOfDay:endDate]];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}
				else{
					predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\") AND date < CAST(%lf, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
				}
			}
			
			else if (key == DCM_StudyTime) {
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good() && aDate != NULL) {
					NSString *dateString = [NSString stringWithCString:aDate DICOMEncoding:nil];
					value = [DCMCalendarDate dicomTime:dateString];
				}
  
				if (!value) {
					predicate = nil;
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime <= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime >= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						NSNumber *startDate = [NSNumber numberWithInt:[[values objectAtIndex:0] intValue]];
						NSNumber *endDate = [NSNumber numberWithInt:[[values objectAtIndex:1] intValue]];

						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"dicomTime >= %@",startDate];
						
						//expression = [NSExpression expressionForConstantValue:(NSDate *)endDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"dicomTime <= %@",endDate];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}

				else{
					predicate = [NSPredicate predicateWithFormat:@"dicomTime == %@", [value dateAsNumber]];
				}
			}
			
			else
				predicate = nil;
		}
		else if (strcmp(sType, "SERIES") == 0) {
			if (key == DCM_StudyInstanceUID) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:nil]];
			}
			else if (key == DCM_SeriesInstanceUID) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL) {
					NSString *u = [NSString stringWithCString:string  DICOMEncoding:nil];
					NSArray *uids = [u componentsSeparatedByString:@"\\"];
					NSArray *predicateArray = [NSArray array];
					
					int x;
					for(x = 0; x < [uids count]; x++)
					{
						NSString *curString = [uids objectAtIndex: x];
						
						NSString *format = @"*%@*" ;
						if ([curString hasPrefix:@"*"] && [curString hasSuffix:@"*"])
							format = @"";
						else if ([curString hasPrefix:@"*"])
							format = @"%@*";
						else if ([curString hasSuffix:@"*"])
							format = @"*%@";
						
						NSString *suid = [NSString stringWithFormat:format, curString];
						
						predicateArray = [predicateArray arrayByAddingObject: [NSPredicate predicateWithFormat:@"seriesInstanceUID like %@", suid]];
					}
					
					predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
				}
			} 
			else if (key == DCM_SeriesDescription) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", [NSString stringWithCString:string  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_SeriesNumber) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:string  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_Modality) {
				char *mis;
				if (dcelem->getString(mis).good() && mis != NULL)
					predicate = [NSPredicate predicateWithFormat:@"study.modality LIKE[cd] %@", [NSString stringWithCString:mis  DICOMEncoding:nil]];
			}
			
			else if (key == DCM_SeriesDate) {
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good() && aDate != NULL) {
					NSString *dateString = [NSString stringWithCString:aDate DICOMEncoding:nil];
					value = [DCMCalendarDate dicomDate:dateString];
				}
  
				if (!value) {
					predicate = nil;
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					//id newValue = [DCMCalendarDate dicomDate:query];
					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%lf, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						DCMCalendarDate *startDate = [DCMCalendarDate dicomDate:[values objectAtIndex:0]];
						DCMCalendarDate *endDate = [DCMCalendarDate dicomDate:[values objectAtIndex:1]];

						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\")", [self startOfDay:startDate]];
						
						//expression = [NSExpression expressionForConstantValue:(NSDate *)endDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%lf, \"NSDate\")",[self endOfDay:endDate]];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}
				else{
					predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%lf, \"NSDate\") AND date < CAST(%lf, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
				}
			}
			else if (key == DCM_SeriesTime) {
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good() && aDate != NULL) {
					NSString *dateString = [NSString stringWithCString:aDate DICOMEncoding:nil];
					value = [DCMCalendarDate dicomTime:dateString];
				}
  
				if (!value) {
					predicate = nil;
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime <= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime >= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						NSNumber *startDate = [NSNumber numberWithInt:[[values objectAtIndex:0] intValue]];
						NSNumber *endDate = [NSNumber numberWithInt:[[values objectAtIndex:1] intValue]];

						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"dicomTime >= %@",startDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"dicomTime <= %@",endDate];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}

				else{
					predicate = [NSPredicate predicateWithFormat:@"dicomTime == %@", [value dateAsNumber]];
				}
			}
			else
				predicate = nil;
		}
		else if (strcmp(sType, "IMAGE") == 0) {
			
			if (key == DCM_StudyInstanceUID) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"series.study.studyInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:nil]];
			}
			else if (key == DCM_SeriesInstanceUID) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL) {
					NSString *u = [NSString stringWithCString:string  DICOMEncoding:nil];
					NSString *format = @"*%@*" ;
					if ([u hasPrefix:@"*"] && [u hasSuffix:@"*"])
						format = @"";
					else if ([u hasPrefix:@"*"])
						format = @"%@*";
					else if ([u hasSuffix:@"*"])
						format = @"*%@";
					NSString *suid = [NSString stringWithFormat:format, u];
					predicate = [NSPredicate predicateWithFormat:@"series.seriesInstanceUID like %@", suid];
				}
			} 
			else if (key == DCM_SOPInstanceUID) {
				NSLog(@"sop Instance");
				char *string;
//				if (dcelem->getString(string).good() && string != NULL)
//					predicate = [NSPredicate predicateWithFormat:@"sopInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:nil]];
					
				if (dcelem->getString(string).good() && string != NULL)
				{
					NSArray *uids = [[NSString stringWithCString:string  DICOMEncoding:nil] componentsSeparatedByString:@"\\"];
					NSArray *predicateArray = [NSArray array];
					
					int x;
					for(x = 0; x < [uids count]; x++)
					{
						predicateArray = [predicateArray arrayByAddingObject: [NSPredicate predicateWithFormat:@"sopInstanceUID == %@", [uids objectAtIndex: x]]];
					}
					
					predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
				}
			}
			else if (key == DCM_InstanceNumber) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"instanceNumber == %d", [[NSString stringWithCString:string  DICOMEncoding:nil] intValue]];
			}
			else if (key == DCM_NumberOfFrames) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"numberOfFrames == %d", [[NSString stringWithCString:string  DICOMEncoding:nil] intValue]];
			}
		}
		else
		{
			NSLog( @"OsiriX supports ONLY STUDY, SERIES, IMAGE levels ! Current level: %s", sType);
		}
		
		if (predicate)
			compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, compoundPredicate, nil]];
	}

	NSLog(@"predicate: %@", [compoundPredicate description]);
	
	NS_HANDLER
		NSLog(@"Exception getting predicate: %@ for dataset\n", [localException description]);
		dataset->print(COUT);
	NS_ENDHANDLER
	return compoundPredicate;
}
	

- (void)studyDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset{
	//DcmDataset dataset;
	//lets test responses as hardwired UTF8Strings
	//use utf8Encoding rather than encoding
		
	if ([fetchedObject valueForKey:@"name"])
		dataset ->putAndInsertString(DCM_PatientsName, [[fetchedObject valueForKey:@"name"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_PatientsName, NULL);
		
	if ([fetchedObject valueForKey:@"patientID"])	
		dataset ->putAndInsertString(DCM_PatientID, [[fetchedObject valueForKey:@"patientID"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_PatientID, NULL);
		
	if ([fetchedObject valueForKey:@"accessionNumber"])	
		dataset ->putAndInsertString(DCM_AccessionNumber, [[fetchedObject valueForKey:@"accessionNumber"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_AccessionNumber, NULL);
		
	if ([fetchedObject valueForKey:@"studyName"])	
		dataset ->putAndInsertString( DCM_StudyDescription, [[fetchedObject valueForKey:@"studyName"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString( DCM_StudyDescription, NULL);
		
	if ([fetchedObject valueForKey:@"dateOfBirth"]){
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"dateOfBirth"]];
		dataset ->putAndInsertString(DCM_PatientsBirthDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
	}
	else {
		dataset ->putAndInsertString(DCM_PatientsBirthDate, NULL);
	}
	
	if ([fetchedObject valueForKey:@"date"]){
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		dataset ->putAndInsertString(DCM_StudyDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
		dataset ->putAndInsertString(DCM_StudyTime, [[dicomTime timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);	
	}
	else {
		dataset ->putAndInsertString(DCM_StudyDate, NULL);
		dataset ->putAndInsertString(DCM_StudyTime, NULL);
	}
	
	
			
	if ([fetchedObject valueForKey:@"studyInstanceUID"])
		dataset ->putAndInsertString(DCM_StudyInstanceUID,  [[fetchedObject valueForKey:@"studyInstanceUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset ->putAndInsertString(DCM_StudyInstanceUID, NULL);
	
	
	if ([fetchedObject valueForKey:@"id"])
		dataset ->putAndInsertString(DCM_StudyID , [[fetchedObject valueForKey:@"id"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset ->putAndInsertString(DCM_StudyID, NULL);
		
	if ([fetchedObject valueForKey:@"modality"])
		dataset ->putAndInsertString(DCM_ModalitiesInStudy , [[fetchedObject valueForKey:@"modality"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset ->putAndInsertString(DCM_ModalitiesInStudy , NULL);
	
		
	if ([fetchedObject valueForKey:@"referringPhysician"])
		dataset ->putAndInsertString(DCM_ReferringPhysiciansName, [[fetchedObject valueForKey:@"referringPhysician"] cStringUsingEncoding:NSUTF8StringEncoding]);
	else
		dataset ->putAndInsertString(DCM_ReferringPhysiciansName, NULL);
		
	if ([fetchedObject valueForKey:@"performingPhysician"])
		dataset ->putAndInsertString(DCM_PerformingPhysiciansName,  [[fetchedObject valueForKey:@"performingPhysician"] cStringUsingEncoding:NSUTF8StringEncoding]);
	else
		dataset ->putAndInsertString(DCM_PerformingPhysiciansName, NULL);
		
	if ([fetchedObject valueForKey:@"institutionName"])
		dataset ->putAndInsertString(DCM_InstitutionName,  [[fetchedObject valueForKey:@"institutionName"]  cStringUsingEncoding:NSUTF8StringEncoding]);
	else
		dataset ->putAndInsertString(DCM_InstitutionName, NULL);
		
	//dataset ->putAndInsertString(DCM_SpecificCharacterSet,  "ISO_IR 192") ;
	dataset ->putAndInsertString(DCM_SpecificCharacterSet,  [specificCharacterSet cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
		
	if ([fetchedObject valueForKey:@"noFiles"]) {		
		int numberInstances = [[fetchedObject valueForKey:@"noFiles"] intValue];
		char value[10];
		sprintf(value, "%d", numberInstances);
		//NSLog(@"number files: %d", numberInstances);
		dataset ->putAndInsertString(DCM_NumberOfStudyRelatedInstances, value);
	}
		
	if ([fetchedObject valueForKey:@"series"]) {
		int numberInstances = [[fetchedObject valueForKey:@"series"] count];
		char value[10];
		sprintf(value, "%d", numberInstances);
		//NSLog(@"number series: %d", numberInstances);
		dataset ->putAndInsertString(DCM_NumberOfStudyRelatedSeries, value);
	}
		

	
	
	dataset ->putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");

	//return dataset;

}
- (void)seriesDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset{
	//DcmDataset dataset;
	NSLog(@"uid: %@",[fetchedObject valueForKey:@"dicomSeriesInstanceUID"]);
	if ([fetchedObject valueForKey:@"name"])	
		dataset ->putAndInsertString(DCM_SeriesDescription, [[fetchedObject valueForKey:@"name"]   cStringUsingEncoding:NSUTF8StringEncoding]);
	else
		dataset ->putAndInsertString(DCM_SeriesDescription, NULL);
		
	if ([fetchedObject valueForKey:@"date"]){

		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		dataset ->putAndInsertString(DCM_SeriesDate, [[dicomDate dateString]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
		dataset ->putAndInsertString(DCM_SeriesTime, [[dicomTime timeString]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	}
	else {
		dataset ->putAndInsertString(DCM_SeriesDate, NULL);
		dataset ->putAndInsertString(DCM_SeriesTime, NULL);
	}

	
	if ([fetchedObject valueForKey:@"modality"])
		dataset ->putAndInsertString(DCM_Modality, [[fetchedObject valueForKey:@"modality"]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset ->putAndInsertString(DCM_Modality, NULL);
		
	if ([fetchedObject valueForKey:@"id"]) {
		NSNumber *number = [fetchedObject valueForKey:@"id"];
		dataset ->putAndInsertString(DCM_SeriesNumber, [[number stringValue]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	}
	else
		dataset ->putAndInsertString(DCM_SeriesNumber, NULL);
			
	if ([fetchedObject valueForKey:@"dicomSeriesInstanceUID"])
		dataset ->putAndInsertString(DCM_SeriesInstanceUID, [[fetchedObject valueForKey:@"dicomSeriesInstanceUID"]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
		

	else
		dataset ->putAndInsertString(DCM_StudyInstanceUID, NULL);
	

	if ([fetchedObject valueForKey:@"noFiles"]) {
		int numberInstances = [[fetchedObject valueForKey:@"noFiles"] intValue];
		char value[10];
		sprintf(value, "%d", numberInstances);
		//NSLog(@"number series: %d", numberInstances);
		dataset ->putAndInsertString(DCM_NumberOfSeriesRelatedInstances, value);

	}
	
	dataset ->putAndInsertString(DCM_QueryRetrieveLevel, "SERIES");

	
	
	//return dataset;
}
- (void)imageDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset{

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NS_DURING
	if ([fetchedObject valueForKey:@"sopInstanceUID"])
		dataset ->putAndInsertString(DCM_SOPInstanceUID, [[fetchedObject valueForKey:@"sopInstanceUID"]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	if ([fetchedObject valueForKey:@"instanceNumber"]) {
		NSString *number = [[fetchedObject valueForKey:@"instanceNumber"] stringValue];
		dataset ->putAndInsertString(DCM_InstanceNumber, [number cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	}
	if ([fetchedObject valueForKey:@"numberOfFrames"]) {
		NSString *number = [[fetchedObject valueForKey:@"numberOfFrames"] stringValue];
		dataset ->putAndInsertString(DCM_NumberOfFrames, [number cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	}
	//UTF 8 Encoding
	//dataset ->putAndInsertString(DCM_SpecificCharacterSet,  "ISO_IR 192") ;
	dataset ->putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
	NS_HANDLER
	NS_ENDHANDLER
	[pool release];

}

- (OFCondition)prepareFindForDataSet:( DcmDataset *)dataset{
	NSManagedObjectModel *model = [[BrowserController currentBrowser] managedObjectModel];
	NSError *error = 0L;
	NSEntityDescription *entity;
	NSPredicate *predicate = [self predicateForDataset:dataset];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	const char *sType;
	dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
	OFCondition cond;
	
	if (strcmp(sType, "STUDY") == 0) 
		entity = [[model entitiesByName] objectForKey:@"Study"];
	else if (strcmp(sType, "SERIES") == 0) 
		entity = [[model entitiesByName] objectForKey:@"Series"];
	else if (strcmp(sType, "IMAGE") == 0) 
		entity = [[model entitiesByName] objectForKey:@"Image"];
	else 
		entity = nil;
	
	if (entity) {
		[request setEntity:entity];
		[request setPredicate:predicate];
					
		error = 0L;
		
		NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
		
		[context retain];
		[context lock];
		
		[findArray release];
		findArray = 0L;
		
		@try
		{
			findArray = [context executeFetchRequest:request error:&error];
		}
		@catch (NSException * e)
		{
			NSLog( @"prepareFindForDataSet exception");
			NSLog( [e description]);
		}
		
		[context unlock];
		[context release];
		
		if (error) {
			findArray = nil;
			cond = EC_IllegalParameter;
		}
		else {
			[findArray retain];
			cond = EC_Normal;
		}
	}
	else{
		findArray = nil;
		cond = EC_IllegalParameter;
	}
	
	[findEnumerator release];
	findEnumerator = [[findArray objectEnumerator] retain];
	
	return cond;
	 
}

- (void) updateLog:(NSArray*) mArray
{
	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO) return;
	
	for( NSManagedObject *object in mArray)
	{
		if( [[object valueForKey:@"type"] isEqualToString: @"Series"])
		{
			FILE * pFile;
			char dir[ 1024], newdir[1024];
			sprintf( dir, "%s/%s%d", [[BrowserController currentBrowser] cfixedDocumentsDirectory], "TEMP/move_log_", random());
			pFile = fopen (dir,"w+");
			if( pFile)
			{
				fprintf (pFile, "%s\r%s\r%s\r%d\r%s\r%s\r%d\r%d\r%s\r", [[object valueForKeyPath:@"study.name"] UTF8String], [[object valueForKeyPath:@"study.studyName"] UTF8String], [[self callingAET] UTF8String], time (NULL), "Complete", "unused", [[object valueForKey:@"noFiles"] intValue], time (NULL), "Move");
				fclose (pFile);
				strcpy( newdir, dir);
				strcat( newdir, ".log");
				rename( dir, newdir);
			}
		}
		
		if( [[object valueForKey:@"type"] isEqualToString: @"Study"])
		{
			FILE * pFile;
			char dir[ 1024], newdir[1024];
			sprintf( dir, "%s/%s%d", [[BrowserController currentBrowser] cfixedDocumentsDirectory], "TEMP/move_log_", random());
			pFile = fopen (dir,"w+");
			if( pFile)
			{
				fprintf (pFile, "%s\r%s\r%s\r%d\r%s\r%s\r%d\r%d\r%s\r", [[object valueForKey:@"name"] UTF8String], [[object valueForKey:@"studyName"] UTF8String], [[self callingAET] UTF8String], time (NULL), "Complete", "unused", [[object valueForKey:@"noFiles"] intValue], time (NULL), "Move");
				fclose (pFile);
				strcpy( newdir, dir);
				strcat( newdir, ".log");
				rename( dir, newdir);
			}
		}
	}
}

- (OFCondition)prepareMoveForDataSet:( DcmDataset *)dataset
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSManagedObjectModel *model = [[BrowserController currentBrowser] managedObjectModel];
	NSError *error = 0L;
	NSEntityDescription *entity;
	NSPredicate *predicate = [self predicateForDataset:dataset];
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
	
	[request setEntity:entity];
	[request setPredicate:predicate];
	
	error = 0L;
	
	NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context retain];
	[context lock];
	
	NSArray *array = 0L;
	
	OFCondition cond = EC_IllegalParameter;
	
	@try
	{
		array = [context executeFetchRequest:request error:&error];
		
		if (error)
		{
			[moveArray release];
			moveArray = [[NSArray array] retain];
			
			cond = EC_IllegalParameter;
		}
		else
		{
			NSEnumerator *enumerator = [array objectEnumerator];
			id moveEntity;
			//create set
			NSMutableSet *moveSet = [NSMutableSet set];
			while (moveEntity = [enumerator nextObject])
				[moveSet unionSet:[moveEntity valueForKey:@"paths"]];
			
			//array from set
			NSArray *tempMoveArray = [moveSet allObjects];
			
			/*
			create temp folder for Move paths. 
			Create symbolic links. 
			Will allow us to convert the sytax on copies if necessary
			*/
			
			//delete if necessary and create temp folder. Allows us to compress and deompress files. Wish we could do on the fly
	//		tempMoveFolder = [[NSString stringWithFormat:@"/tmp/DICOMMove_%@", [[NSDate date] descriptionWithCalendarFormat:@"%H%M%S%F"  timeZone:nil locale:nil]] retain]; 
	//		
	//		NSFileManager *fileManager = [NSFileManager defaultManager];
	//		if ([fileManager fileExistsAtPath:tempMoveFolder]) [fileManager removeFileAtPath:tempMoveFolder handler:nil];
	//		if ([fileManager createDirectoryAtPath:tempMoveFolder attributes:nil]) 
	//			NSLog(@"created temp Folder: %@", tempMoveFolder);
	//		
	//		//NSLog(@"Temp Move array: %@", [tempMoveArray description]);
	//		NSEnumerator *tempEnumerator = [tempMoveArray objectEnumerator];
	//		NSString *path;
	//		while (path = [tempEnumerator nextObject]) {
	//			NSString *lastPath = [path lastPathComponent];
	//			NSString *newPath = [tempMoveFolder stringByAppendingPathComponent:lastPath];
	//			[fileManager createSymbolicLinkAtPath:newPath pathContent:path];
	//			[paths addObject:newPath];
	//		}
			
			tempMoveArray = [tempMoveArray sortedArrayUsingSelector:@selector(compare:)];
			
			[moveArray release];
			moveArray = [tempMoveArray retain];
			NSLog( @"will move: %d dicom files", [moveArray count]);
			
			[self updateLog: array];
			
			cond = EC_Normal;
		}

	}
	@catch (NSException * e)
	{
		NSLog( @"prepareMoveForDataSet exception");
		NSLog( [e description]);
	}

	[context unlock];
	[context release];
	
	[moveEnumerator release];
	moveEnumerator = [[moveArray objectEnumerator] retain];
	
	[pool release];
	return cond;
}

- (BOOL)findMatchFound{
	if (findArray) return YES;
	return NO;
}
	
- (int)moveMatchFound{
	return [moveArray count];
}

- (OFCondition)nextFindObject:(DcmDataset *)dataset  isComplete:(BOOL *)isComplete{
	id item;
	if (item = [findEnumerator nextObject]) {
		if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) {
			 [self seriesDatasetForFetchedObject:item dataset:(DcmDataset *)dataset];
			
		}
		else if ([[item valueForKey:@"type"] isEqualToString:@"Study"]){
			[self studyDatasetForFetchedObject:item dataset:(DcmDataset *)dataset];
		}
		else if ([[item valueForKey:@"type"] isEqualToString:@"Image"]){
			[self imageDatasetForFetchedObject:item dataset:(DcmDataset *)dataset];
		}
		*isComplete = NO;
	}else
		*isComplete = YES;
	return EC_Normal;
}

- (OFCondition)nextMoveObject:(char *)imageFileName{
	NSString *path;
	//NSLog(@"nextMOveObject: %@", [moveEnumerator description]);
	if (path = [moveEnumerator nextObject])
	{
		//NSLog(@"move path: %@", path);
		strcpy(imageFileName, [path UTF8String]);
	}
	else
	{
		NSLog(@"No path");
		return EC_IllegalParameter;
	}
	return EC_Normal;
}

@end
