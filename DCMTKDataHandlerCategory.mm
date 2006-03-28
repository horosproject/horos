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


@implementation OsiriXSCPDataHandler (DCMTKDataHandlerCategory)

- (NSPredicate *)predicateForDataset:( DcmDataset *)dataset{

	//NSPredicate *compoundPredicate = [NSPredicate predicateWithFormat:@"hasDICOM == %d", YES];
	NSPredicate *compoundPredicate = [NSPredicate predicateWithValue:YES];
	const char *sType;
	const char *scs;
	NSString *charset;	
	//should be STUDY, SERIES OR IMAGE
	dataset->findAndGetString (DCM_QueryRetrieveLevel, sType, OFFalse);
	if (dataset->findAndGetString (DCM_SpecificCharacterSet, scs, OFFalse).good()) {
		charset = [NSString stringWithCString:scs];
	}
	else
		charset = @"ISO_IR 100";
	//NSISOLatin1StringEncoding;
		
	
	int elemCount = (int)(dataset->card());
    for (int elemIndex=0; elemIndex<elemCount; elemIndex++) {
		NSPredicate *predicate = nil;
		DcmElement* dcelem = dataset->getElement(elemIndex);
		DcmTagKey key = dataset->getTag().getXTag();
		if (strcmp(sType, "STUDY")) {
			compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:
						[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"hasDICOM == %d", YES], 
						compoundPredicate, nil]];
			if (key == DCM_PatientsName){
				char *pn;
				if (dcelem->getString(pn).good())
					predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithCString:pn  DICOMEncoding:charset]];
			}
			else if (key == DCM_PatientID){
				char *pid;
				if (dcelem->getString(pid).good())
					predicate = [NSPredicate predicateWithFormat:@"patientID like[cd] %@", [NSString stringWithCString:pid  DICOMEncoding:charset]];
			}
			else if (key == DCM_StudyInstanceUID ){
				char *suid;
				if (dcelem->getString(suid).good())
					predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [NSString stringWithCString:suid  DICOMEncoding:charset]];
			}
			else if (key == DCM_StudyID ) {
				char *sid;
				if (dcelem->getString(sid).good())
					predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:sid  DICOMEncoding:charset]];
			}
			else if (key ==  DCM_StudyDescription) {
				char *sd;
				if (dcelem->getString(sd).good())
					predicate = [NSPredicate predicateWithFormat:@"studyName like[cd] %@", [NSString stringWithCString:sd  DICOMEncoding:charset]];
			}
			else if (key == DCM_InstitutionName) {
				char *inn;
				if (dcelem->getString(inn).good())
					predicate = [NSPredicate predicateWithFormat:@"institutionName like[cd] %@", [NSString stringWithCString:inn  DICOMEncoding:charset]];
			}
			else if (key == DCM_ReferringPhysiciansName) {
				char *rpn;
				if (dcelem->getString(rpn).good())
					predicate = [NSPredicate predicateWithFormat:@"referringPhysician like[cd] %@", [NSString stringWithCString:rpn  DICOMEncoding:charset]];
			}
			else if (key ==  DCM_PerformingPhysiciansName) {
				char *ppn;
				if (dcelem->getString(ppn).good())
					predicate = [NSPredicate predicateWithFormat:@"performingPhysician like[cd] %@", [NSString stringWithCString:ppn  DICOMEncoding:charset]];
			}
			else if (key == DCM_StudyDate) {
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good()) {
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
				if (dcelem->getString(aDate).good()) {
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
						//NSLog(@"startDate: %@", [startDate description]);
						//NSLog(@"endDate :%@", [endDate description]);
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
		else if (strcmp(sType, "SERIES")) {
			if (key == DCM_StudyInstanceUID) {
				char *string;
				if (dcelem->getString(string).good())
					predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:charset]];
			}
			else if (key == DCM_SeriesInstanceUID) {
				char *string;
				if (dcelem->getString(string).good())
					predicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [NSString stringWithCString:string  DICOMEncoding:charset]];
			} 
			else if (key == DCM_SeriesDescription) {
				char *string;
				if (dcelem->getString(string).good())
					predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithCString:string  DICOMEncoding:charset]];
			}
			else if (key == DCM_SeriesNumber) {
				char *string;
				if (dcelem->getString(string).good())
					predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:string  DICOMEncoding:charset]];
			}
			else if (key == DCM_SeriesDate) {
				char *aDate;
				DCMCalendarDate *value = nil;
				if (dcelem->getString(aDate).good()) {
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
				if (dcelem->getString(aDate).good()) {
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
			else if (strcmp(sType, "IMAGE")) {
		}
	}

	NSLog(@"predicate: %@", [compoundPredicate description]);
	return compoundPredicate;

		
}
	

- ( DcmDataset )studyDatasetForFetchedObject:(id)fetchedObject{
	DcmDataset dataset;
	NSStringEncoding encoding = [NSString defaultCStringEncoding];
	if ([fetchedObject valueForKey:@"name"])
		dataset.putAndInsertString(DCM_PatientsName, [[fetchedObject valueForKey:@"name"] cStringUsingEncoding:encoding]);
	else
		dataset.putAndInsertString(DCM_PatientsName, NULL);
		
	if ([fetchedObject valueForKey:@"patientID"])	
		dataset.putAndInsertString(DCM_PatientID, [[fetchedObject valueForKey:@"patientID"] cStringUsingEncoding:encoding]);
	else
		dataset.putAndInsertString(DCM_PatientID, NULL);
		
	if ([fetchedObject valueForKey:@"studyName"])	
		dataset.putAndInsertString( DCM_StudyDescription, [[fetchedObject valueForKey:@"studyName"] cStringUsingEncoding:encoding]);
	else
		dataset.putAndInsertString( DCM_StudyDescription, NULL);
		

	if ([fetchedObject valueForKey:@"date"]){
		DCMCalendarDate *dicomDate = [DCMCalendarDate dicomDateWithDate:[fetchedObject valueForKey:@"date"]];
		DCMCalendarDate *dicomTime = [DCMCalendarDate dicomTimeWithDate:[fetchedObject valueForKey:@"date"]];
		dataset.putAndInsertString(DCM_StudyDate, [[dicomDate dateString] cStringUsingEncoding:NSISOLatin1StringEncoding]);
		dataset.putAndInsertString(DCM_StudyTime, [[dicomDate timeString] cStringUsingEncoding:NSISOLatin1StringEncoding]);

	
	}
	
	else {
		dataset.putAndInsertString(DCM_StudyDate, NULL);
		dataset.putAndInsertString(DCM_StudyTime, NULL);
		
	}
	
	
			
	if ([fetchedObject valueForKey:@"studyInstanceUID"])
		dataset.putAndInsertString(DCM_StudyInstanceUID,  [[fetchedObject valueForKey:@"studyInstanceUID"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset.putAndInsertString(DCM_StudyInstanceUID, NULL);
	
	
	if ([fetchedObject valueForKey:@"id"])
		dataset.putAndInsertString(DCM_StudyID , [[fetchedObject valueForKey:@"id"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset.putAndInsertString(DCM_StudyID, NULL);
		
	if ([fetchedObject valueForKey:@"modality"])
		dataset.putAndInsertString(DCM_ModalitiesInStudy , [[fetchedObject valueForKey:@"modality"] cStringUsingEncoding:NSISOLatin1StringEncoding]) ;
	else
		dataset.putAndInsertString(DCM_ModalitiesInStudy , NULL);
	
		
	if ([fetchedObject valueForKey:@"referringPhysician"])
		dataset.putAndInsertString(DCM_ReferringPhysiciansName, [[fetchedObject valueForKey:@"referringPhysician"] cStringUsingEncoding:encoding]);
	else
		dataset.putAndInsertString(DCM_ReferringPhysiciansName, NULL);
		
	if ([fetchedObject valueForKey:@"performingPhysician"])
		dataset.putAndInsertString(DCM_PerformingPhysiciansName,  [[fetchedObject valueForKey:@"performingPhysician"] cStringUsingEncoding:encoding]);
	else
		dataset.putAndInsertString(DCM_PerformingPhysiciansName, NULL);
		
	if ([fetchedObject valueForKey:@"institutionName"])
		dataset.putAndInsertString(DCM_InstitutionName,  [[fetchedObject valueForKey:@"institutionName"]  cStringUsingEncoding:encoding]);
	else
		dataset.putAndInsertString(DCM_InstitutionName, NULL);
	
	
	dataset.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");

	return dataset;

}
- ( DcmDataset *)seriesDatasetForFetchedObject:(id)fetchedObject{
	return nil;
}
- ( DcmDataset *)imageDatasetForFetchedObject:(id)fetchedObject{
	return nil;
}
- ( NSArray *)foundEntities{
	return nil;
}

@end
