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
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMTKDataHandlerCategory.h"
#import "DICOMToNSString.h"
#include "dctk.h"

#import "browserController.h"

extern BrowserController *browserWindow;


@implementation OsiriXSCPDataHandler (DCMTKDataHandlerCategory)

- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset{

	//NSPredicate *compoundPredicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
	NSPredicate *compoundPredicate;
	const char *sType;
	const char *scs;
	//NSString *charset;	
	//should be STUDY, SERIES OR IMAGE
	dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
	
	if (dataset->findAndGetString (DCM_SpecificCharacterSet, scs, OFFalse).good()) {
		specificCharacterSet = [[NSString stringWithCString:scs] retain];
		encoding = [NSString encodingForDICOMCharacterSet:specificCharacterSet];
	}
	else {
		specificCharacterSet = [@"ISO_IR 100" retain];
		encoding = NSISOLatin1StringEncoding;
	}
	
	if (strcmp(sType, "STUDY") == 0) 
		compoundPredicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
	else
		compoundPredicate = [NSPredicate predicateWithValue:YES];
		
	NSLog(@"charset %@", specificCharacterSet);
		
	
	int elemCount = (int)(dataset->card());
    for (int elemIndex=0; elemIndex<elemCount; elemIndex++) {
		NSPredicate *predicate = nil;
		DcmElement* dcelem = dataset->getElement(elemIndex);
		DcmTagKey key = dcelem->getTag().getXTag();
		printf("elemindex: %d key: %s\n",elemIndex, key.toString().c_str());
		if (strcmp(sType, "STUDY") == 0) {
			compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:
						[NSArray arrayWithObjects: compoundPredicate, nil]];
			if (key == DCM_PatientsName){
				char *pn;
				if (dcelem->getString(pn).good() && pn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithCString:pn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_PatientID){
				char *pid;
				if (dcelem->getString(pid).good() && pid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"patientID like[cd] %@", [NSString stringWithCString:pid  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_StudyInstanceUID ){
				char *suid;
				if (dcelem->getString(suid).good() && suid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [NSString stringWithCString:suid  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_StudyID ) {
				char *sid;
				if (dcelem->getString(sid).good() && sid != NULL)
					predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:sid  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_StudyDescription) {
				char *sd;
				if (dcelem->getString(sd).good() && sd != NULL)
					predicate = [NSPredicate predicateWithFormat:@"studyName like[cd] %@", [NSString stringWithCString:sd  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_InstitutionName) {
				char *inn;
				if (dcelem->getString(inn).good() && inn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"institutionName like[cd] %@", [NSString stringWithCString:inn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_ReferringPhysiciansName) {
				char *rpn;
				if (dcelem->getString(rpn).good() && rpn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"referringPhysician like[cd] %@", [NSString stringWithCString:rpn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_PerformingPhysiciansName) {
				char *ppn;
				if (dcelem->getString(ppn).good() && ppn != NULL)
					predicate = [NSPredicate predicateWithFormat:@"performingPhysician like[cd] %@", [NSString stringWithCString:ppn  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_ModalitiesInStudy) {
				char *mis;
				if (dcelem->getString(mis).good() && mis != NULL)
					predicate = [NSPredicate predicateWithFormat:@"modality like[cd] %@", [NSString stringWithCString:mis  DICOMEncoding:nil]];
			}
			
			else if (key == DCM_StudyDate) {
				NSLog(@"StudyDate");
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good() && aDate != NULL) {
					NSString *dateString = [NSString stringWithCString:aDate DICOMEncoding:nil];
					value = [DCMCalendarDate dicomDate:dateString];
				}
				NSLog(@"StudyDate decoded");
				if (!value) {
					predicate = nil;
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			

					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%f, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%f, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					//value = [attr value];
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						DCMCalendarDate *startDate = [DCMCalendarDate dicomDate:[values objectAtIndex:0]];
						DCMCalendarDate *endDate = [DCMCalendarDate dicomDate:[values objectAtIndex:1]];
						//NSLog(@"startDate: %@", [startDate description]);
						//NSLog(@"endDate :%@", [endDate description]);
						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%f, \"NSDate\")", [self startOfDay:startDate]];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%f, \"NSDate\")",[self endOfDay:endDate]];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}
				else{
					predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%f, \"NSDate\") AND date < CAST(%f, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
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
				
			if (predicate)
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, compoundPredicate, nil]];
		}
		else if (strcmp(sType, "SERIES") == 0) {
			if (key == DCM_StudyInstanceUID) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_SeriesInstanceUID) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:specificCharacterSet]];
			} 
			else if (key == DCM_SeriesDescription) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithCString:string  DICOMEncoding:specificCharacterSet]];
			}
			else if (key == DCM_SeriesNumber) {
				char *string;
				if (dcelem->getString(string).good() && string != NULL)
					predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:string  DICOMEncoding:specificCharacterSet]];
			}
			else if (key ==  DCM_Modality) {
				char *mis;
				if (dcelem->getString(mis).good() && mis != NULL)
					predicate = [NSPredicate predicateWithFormat:@"study.modality like[cd] %@", [NSString stringWithCString:mis  DICOMEncoding:nil]];
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
					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%f, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%f, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					NSArray *values = [[value queryString] componentsSeparatedByString:@"-"];
					if ([values count] == 2){
						DCMCalendarDate *startDate = [DCMCalendarDate dicomDate:[values objectAtIndex:0]];
						DCMCalendarDate *endDate = [DCMCalendarDate dicomDate:[values objectAtIndex:1]];
						//NSLog(@"startDate: %@", [startDate description]);
						//NSLog(@"endDate :%@", [endDate description]);
						//need two predicates for range
						NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"date >= CAST(%f, \"NSDate\")", [self startOfDay:startDate]];
						
						//expression = [NSExpression expressionForConstantValue:(NSDate *)endDate];
						NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date < CAST(%f, \"NSDate\")",[self endOfDay:endDate]];
						
						predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate1, predicate2, nil]];
					}
					else
						predicate = nil;
				}
				else{
					predicate = [NSPredicate predicateWithFormat:@"date >= CAST(%f, \"NSDate\") AND date < CAST(%f, \"NSDate\")",[self startOfDay:value],[self endOfDay:value]];
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
				
			if (predicate)
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects: predicate, compoundPredicate, nil]];
		}
			else if (strcmp(sType, "IMAGE") == 0) {
		}
	}

	NSLog(@"predicate: %@", [compoundPredicate description]);
	return compoundPredicate;

		
}
	

- (void)studyDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset{
	//DcmDataset dataset;
	
	if ([fetchedObject valueForKey:@"name"])
		dataset ->putAndInsertString(DCM_PatientsName, [[fetchedObject valueForKey:@"name"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_PatientsName, NULL);
		
	if ([fetchedObject valueForKey:@"patientID"])	
		dataset ->putAndInsertString(DCM_PatientID, [[fetchedObject valueForKey:@"patientID"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_PatientID, NULL);
		
	if ([fetchedObject valueForKey:@"studyName"])	
		dataset ->putAndInsertString( DCM_StudyDescription, [[fetchedObject valueForKey:@"studyName"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString( DCM_StudyDescription, NULL);
		

	if ([fetchedObject valueForKey:@"date"]){
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		dataset ->putAndInsertString(DCM_StudyDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
		dataset ->putAndInsertString(DCM_StudyTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);	
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
		dataset ->putAndInsertString(DCM_ReferringPhysiciansName, [[fetchedObject valueForKey:@"referringPhysician"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_ReferringPhysiciansName, NULL);
		
	if ([fetchedObject valueForKey:@"performingPhysician"])
		dataset ->putAndInsertString(DCM_PerformingPhysiciansName,  [[fetchedObject valueForKey:@"performingPhysician"] cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_PerformingPhysiciansName, NULL);
		
	if ([fetchedObject valueForKey:@"institutionName"])
		dataset ->putAndInsertString(DCM_InstitutionName,  [[fetchedObject valueForKey:@"institutionName"]  cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_InstitutionName, NULL);
		
	dataset ->putAndInsertString(DCM_SpecificCharacterSet,  [specificCharacterSet cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
		
	if ([fetchedObject valueForKey:@"noFiles"]) {		
		int numberInstances = [[fetchedObject valueForKey:@"noFiles"] intValue];
		char value[10];
		sprintf(value, "%d", numberInstances);
		NSLog(@"number files: %d", numberInstances);
		dataset ->putAndInsertString(DCM_NumberOfStudyRelatedInstances, value);
	}
		
	if ([fetchedObject valueForKey:@"series"]) {
		int numberInstances = [[fetchedObject valueForKey:@"series"] count];
		char value[10];
		sprintf(value, "%d", numberInstances);
		NSLog(@"number series: %d", numberInstances);
		dataset ->putAndInsertString(DCM_NumberOfStudyRelatedSeries, value);
	}
		

	
	
	dataset ->putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");

	//return dataset;

}
- (void)seriesDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset{
	//DcmDataset dataset;
	
	if ([fetchedObject valueForKey:@"name"])	
		dataset ->putAndInsertString(DCM_SeriesDescription, [[fetchedObject valueForKey:@"name"]   cStringUsingEncoding:encoding]);
	else
		dataset ->putAndInsertString(DCM_SeriesDescription, NULL);
		
	if ([fetchedObject valueForKey:@"date"]){

		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		dataset ->putAndInsertString(DCM_SeriesDate, [[dicomDate dateString]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
		dataset ->putAndInsertString(DCM_SeriesTime, [[dicomDate timeString]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
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
			
	if ([fetchedObject valueForKey:@"seriesInstanceUID"])
		dataset ->putAndInsertString(DCM_SeriesInstanceUID, [[fetchedObject valueForKey:@"seriesInstanceUID"]  cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	

	if ([fetchedObject valueForKey:@"noFiles"]) {
		int numberInstances = [[fetchedObject valueForKey:@"noFiles"] intValue];
		char value[10];
		sprintf(value, "%d", numberInstances);
		NSLog(@"number series: %d", numberInstances);
		dataset ->putAndInsertString(DCM_NumberOfSeriesRelatedInstances, value);

	}

	
	
	//return dataset;
}
- (void)imageDatasetForFetchedObject:(id)fetchedObject dataset:(DcmDataset *)dataset{

}

- (OFCondition)prepareFindForDataSet:( DcmDataset *)dataset{
	NSManagedObjectModel *model = [browserWindow managedObjectModel];
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
				
	findArray = [[browserWindow managedObjectContext] executeFetchRequest:request error:&error];
	
	OFCondition cond;
	
	if (error) {
		findArray = nil;
		cond = EC_IllegalParameter;
	}
	else {
		[findArray retain];
		cond = EC_Normal;
	}
		
	findEnumerator = [findArray objectEnumerator];
	
	return cond;
	 
}

- (OFCondition)prepareMoveForDataSet:( DcmDataset *)dataset{
		NSManagedObjectModel *model = [browserWindow managedObjectModel];
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
				
	NSArray *array = [[browserWindow managedObjectContext] executeFetchRequest:request error:&error];
	
	OFCondition cond;
	
	if (error) {
		moveArray = nil;
		cond = EC_IllegalParameter;
	}
	else {
		NSEnumerator *enumerator = [array objectEnumerator];
		id moveEntity;
		NSMutableSet *moveSet = [NSMutableSet set];
		while (moveEntity = [enumerator nextObject])
			[moveSet unionSet:[moveEntity valueForKey:@"paths"]];
		
		moveArray = [[moveSet allObjects] retain];
		
		cond = EC_Normal;
	}
		
	moveEnumerator = [moveArray objectEnumerator];
	
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
		*isComplete = NO;
	}else
		*isComplete = YES;
	return EC_Normal;
}

- (OFCondition)nextMoveObject:(char *)imageFileName{
	NSString *path;
	if (path = [moveEnumerator nextObject])
		imageFileName = (char *)[path cStringUsingEncoding:[NSString defaultCStringEncoding]];
	return EC_Normal;
}

@end
