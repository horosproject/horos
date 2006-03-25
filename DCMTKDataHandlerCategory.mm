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
				if (dcelem->getString(pn).good());
					predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithCString:pn  DICOMEncoding:charset]];
			}
			else if (key == DCM_PatientID){
				char *pid;
				if (dcelem->getString(pid).good());
					predicate = [NSPredicate predicateWithFormat:@"patientID like[cd] %@", [NSString stringWithCString:pid  DICOMEncoding:charset]];
			}
			else if (key == DCM_StudyInstanceUID ){
				char *suid;
				if (dcelem->getString(suid).good());
					predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [NSString stringWithCString:suid  DICOMEncoding:charset]];
			}
			else if (key == DCM_StudyID ) {
				char *sid;
				predicate = [NSPredicate predicateWithFormat:@"id == %@", [NSString stringWithCString:sid  DICOMEncoding:charset]];
			}
			else if (key ==  DCM_StudyDescription) {
				char *sd;
				predicate = [NSPredicate predicateWithFormat:@"studyName like[cd] %@", [NSString stringWithCString:sd  DICOMEncoding:charset]];
			}
			else if (key == DCM_InstitutionName) {
				char *inn;
				predicate = [NSPredicate predicateWithFormat:@"institutionName like[cd] %@", [NSString stringWithCString:inn  DICOMEncoding:charset]];
			}
			else if (key == DCM_ReferringPhysiciansName) {
				char *rpn;
				predicate = [NSPredicate predicateWithFormat:@"referringPhysician like[cd] %@", [NSString stringWithCString:rpn  DICOMEncoding:charset]];
			}
		}
	}
	

	

/*
//	while (key = [enumerator nextObject]){
		id value;
		//NSExpression *expression;
		NSPredicate *predicate;
		DCMAttribute *attr = [[object attributes] objectForKey:key];
		if ([searchType isEqualToString:@"STUDY"]) {

			else if ([[[attr attrTag] name] isEqualToString:@"PerformingPhysiciansName"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"performingPhysician like[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"StudyDate"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			

					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%f, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%f, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
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
			
			else if ([[[attr attrTag] name] isEqualToString:@"StudyTime"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime <= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime >= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
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
		else if ([searchType isEqualToString:@"SERIES"]) {
			//NSLog(@"Series search");
			if ([[[attr attrTag] name] isEqualToString:@"StudyInstanceUID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesInstanceUID"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", value];
			} 
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesDescription"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", value];
			}
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesNumber"]) {
				value = [attr value];
				predicate = [NSPredicate predicateWithFormat:@"id == %@", value];
			} 
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesDate"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					//id newValue = [DCMCalendarDate dicomDate:query];
					predicate = [NSPredicate predicateWithFormat:@"date < CAST(%f, \"NSDate\")", [self endOfDay:query]];

				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					DCMCalendarDate *query = [DCMCalendarDate dicomDate:queryString];			
					predicate = [NSPredicate predicateWithFormat:@"date  >= CAST(%f, \"NSDate\")",[self startOfDay:query]];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
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
			
			else if ([[[attr attrTag] name] isEqualToString:@"SeriesTime"]) {
				value = [attr value];
				if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasPrefix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[value queryString] stringByTrimmingCharactersInSet:set];	
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime <= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery] && [[(DCMCalendarDate *)value queryString] hasSuffix:@"-"]) {
					NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-"];
					NSString *queryString = [[[attr value] queryString] stringByTrimmingCharactersInSet:set];		
					NSNumber *query = [NSNumber numberWithInt:[queryString intValue]];			
					predicate = [NSPredicate predicateWithFormat:@"dicomTime >= %@",query];
				}
				else if ([(DCMCalendarDate *)value isQuery]){
					value = [attr value];
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
		else if ([searchType isEqualToString:@"IMAGE"]) {
		}

			
//	}
*/	
	NSLog(@"predicate: %@", [compoundPredicate description]);
	return compoundPredicate;
}

- ( DcmDataset *)studyDatasetForFetchedObject:(id)fetchedObject{
	return nil;
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
