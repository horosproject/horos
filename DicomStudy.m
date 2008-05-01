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

/***************************************** Modifications *********************************************

Version 2.3

	20051229	LP	Fixed bug in paths method. Now accesses completePath.
	20060101	DDP	Changed yearOld to return in the format 5 y or 23 d rather than 5 yo or 23 do,
					as this is more internationally generic.
				
	
****************************************************************************************************/

#import "DicomStudy.h"
#import "DicomSeries.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCM.h>

#ifdef OSIRIX_VIEWER
#import "DCMPix.h"
#import "VRController.h"
#import "browserController.h"
#import "BonjourBrowser.h"
#endif

@implementation DicomStudy

- (void) dealloc
{
	[dicomTime release];
	
	[super dealloc];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (BOOL) isHidden;
{
	return isHidden;
}

- (void) setHidden: (BOOL) h;
{
	isHidden = h;
}

- (NSString*) type
{
	return @"Study";
}

- (void) setReportURL: (NSString*) url
{
	#ifdef OSIRIX_VIEWER
	BrowserController	*cB = [BrowserController currentBrowser];
	
	if( url && [cB isCurrentDatabaseBonjour] == NO)
	{
		NSString *commonPath = [[cB fixedDocumentsDirectory] commonPrefixWithString: url options: NSLiteralSearch];
		
		if( [commonPath isEqualToString: [cB fixedDocumentsDirectory]])
		{
			url = [url substringFromIndex: [[cB fixedDocumentsDirectory] length]];
			
			if( [url characterAtIndex: 0] == '/') url = [url substringFromIndex: 1];
		}
	}
	#endif
	
	[self willChangeValueForKey: @"reportURL"];
	[self setPrimitiveValue: url forKey: @"reportURL"];
	[self didChangeValueForKey: @"reportURL"];
}

- (NSString*) reportURL
{
	NSString *url = [self primitiveValueForKey: @"reportURL"];
	
	#ifdef OSIRIX_VIEWER
	if( url && [url length])
	{
		BrowserController	*cB = [BrowserController currentBrowser];
		
		if( [cB isCurrentDatabaseBonjour] == NO)
		{
			if( [url characterAtIndex: 0] != '/')
				url = [[cB fixedDocumentsDirectory] stringByAppendingPathComponent: url];
			else
			{	// Should we convert it to a local path?
				NSString *commonPath = [[cB fixedDocumentsDirectory] commonPrefixWithString: url options: NSLiteralSearch];
				if( [commonPath isEqualToString: [cB fixedDocumentsDirectory]])
				{
					[self setReportURL: url];
					NSLog(@"report url converted to local path");
				}
			}
		}
	}
	#endif
	
	return url;
}

- (NSString *) localstring
{
	NSManagedObject	*obj = [[[[self valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
	
	BOOL local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	
	if( local) return @"L";
	else return @"";
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = 0L;
	
	[self willChangeValueForKey: @"date"];
	[self setPrimitiveValue: date forKey:@"date"];
	[self didChangeValueForKey: @"date"];
}

- (NSNumber*) dicomTime
{
	if( dicomTime) return dicomTime;
	
	dicomTime = [[[DCMCalendarDate dicomTimeWithDate:[self valueForKey: @"date"]] timeAsNumber] retain];
	
	return dicomTime;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSString*) yearOldAcquisition
{
	if( [self valueForKey: @"dateOfBirth"])
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[self valueForKey:@"dateOfBirth"] timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[self valueForKey:@"date"] timeIntervalSinceReferenceDate]];
		
		NSInteger years, months, days;
		
		[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
		
		if( years < 2)
		{
			if( years < 1)
			{
				if( months < 1) return [NSString stringWithFormat:@"%d d", days];
				else return [NSString stringWithFormat:@"%d m", months];
			}
			else return [NSString stringWithFormat:@"%d y %d m",years, months];
		}
		else return [NSString stringWithFormat:@"%d y", years];
	}
	else return @"";
}

- (NSNumber*) yearOldInDays
{
	if( [self valueForKey: @"dateOfBirth"])
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[self valueForKey:@"dateOfBirth"] timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate date];
		
		NSInteger days;
		
		days = [dateOfBirth timeIntervalSinceDate: momsBDay] / 86400.;
		
		return [NSNumber numberWithInt: days];
	}
	else return [NSNumber numberWithInt: 0];
}

- (NSString*) yearOld
{
	if( [self valueForKey: @"dateOfBirth"])
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[self valueForKey:@"dateOfBirth"] timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate date];
		
		NSInteger years, months, days;
		
		[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
		
		if( years < 2)
		{
			if( years < 1)
			{
				if( months < 1) return [NSString stringWithFormat:@"%d d", days];
				else return [NSString stringWithFormat:@"%d m", months];
			}
			else return [NSString stringWithFormat:@"%d y %d m",years, months];
		}
		else return [NSString stringWithFormat:@"%d y", years];
	}
	else return @"";
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSNumber *) noFiles
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] == 0)
	{
		NSSet	*series = [self valueForKey:@"series"];
		NSArray	*array = [series allObjects];
		
		long sum = 0, i;
		
		for( id loopItem in array)
		{
			if( [DCMAbstractSyntaxUID isStructuredReport: [loopItem valueForKey: @"seriesSOPClassUID"]] == NO)
				sum += [[loopItem valueForKey:@"noFiles"] intValue];
		}
		
		NSNumber	*no = [NSNumber numberWithInt:sum];
		
		[self willChangeValueForKey: @"numberOfImages"];
		[self setPrimitiveValue:no forKey:@"numberOfImages"];
		[self didChangeValueForKey: @"numberOfImages"];
		
		return no;
	}
	else return [self primitiveValueForKey:@"numberOfImages"];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSSet*) paths
{
//	NSLog(@"keyPath: %@", [[self valueForKeyPath:@"series.images.completePath"] description]);
	NSSet *sets = [self valueForKeyPath: @"series.images.completePath"];
	NSMutableSet *set = [NSMutableSet set];
//	NSEnumerator *enumerator = [[self primitiveValueForKey:@"series"] objectEnumerator];
	id subset;
	for (subset in sets)
		[set unionSet: subset];
	return set;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSSet*) keyImages
{
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [[self primitiveValueForKey: @"series"] objectEnumerator];
	
	id object;
	while (object = [enumerator nextObject])
		[set unionSet:[object keyImages]];
	return set;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ------------------------ Series subselections-----------------------------------ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ


- (NSArray *)imageSeries{
	NSArray *array = [self primitiveValueForKey: @"series"];
	
	NSMutableArray *newArray = [NSMutableArray array];
	id series;
	for (series in array){
		if ([DCMAbstractSyntaxUID isImageStorage:[series valueForKey:@"seriesSOPClassUID"]] || [DCMAbstractSyntaxUID isRadiotherapy:[series valueForKey:@"seriesSOPClassUID"]] || [series valueForKey:@"seriesSOPClassUID"] == nil)
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)reportSeries
{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	id series;
	for (series in array)
	{
		if ([DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]])
		{
			if( [[series valueForKey:@"id"] intValue] != 5002 || [[series valueForKey:@"name"] isEqualToString: @"OsiriX ROI SR"] == NO)		// We dont want the OsiriX ROIs SR
				[newArray addObject:series];
		}
	}
	return newArray;
}

- (NSArray *)structuredReports{
	NSArray *array = [self primitiveValueForKey:@"reportSeries"];
	NSMutableSet *set = [NSMutableSet set];
	id series;
	for (series in array)
		[set unionSet:[series primitiveValueForKey:@"images"]];
	return [set allObjects];
}

- (NSArray *)keyObjectSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	id series;
	for (series in array){
		if ([[DCMAbstractSyntaxUID keyObjectSelectionDocumentStorage] isEqualToString:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)keyObjects{
	NSArray *array = [self keyObjectSeries];
	NSMutableSet *set = [NSMutableSet set];
	id series;
	for (series in array)
		[set unionSet:[series primitiveValueForKey:@"images"]];
	return [set allObjects];
}

- (NSArray *)presentationStateSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	id series;
	for (series in array){
		if ([DCMAbstractSyntaxUID isPresentationState:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)waveFormSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	id series;
	for (series in array){
		if ([DCMAbstractSyntaxUID isWaveform:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

- (NSManagedObject *)roiSRSeries
{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	if ([array count] < 1)  return 0L;
	
	NSMutableArray *newArray = [NSMutableArray array];
	for( DicomSeries *series in array)
	{
		if( [[series valueForKey:@"id"] intValue] == 5002 && [[series valueForKey:@"name"] isEqualToString: @"OsiriX ROI SR"] == YES && [DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]] == YES)
			[newArray addObject:series];
	}
	
	if( [newArray count] > 1)
	{
		NSLog( @"****** multiple (%d) roiSRSeries?? Delete the extra series...", [newArray count]);
		int i;
		for( i = 1 ; i < [newArray count] ; i++)
			[[self managedObjectContext] deleteObject: [newArray objectAtIndex: i]]; 
	}
	
	if( [newArray count]) return [newArray objectAtIndex: 0];
	
	return 0L;
}

- (NSDictionary *)dictionary{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if ([self primitiveValueForKey:@"name"])
		[dict  setObject: [self primitiveValueForKey:@"name"] forKey: @"Patients Name"];
	if ([self primitiveValueForKey:@"patientID"])
		[dict  setObject: [self primitiveValueForKey:@"patientID"] forKey: @"Patient ID"];
	if ([self primitiveValueForKey:@"studyName"])
		[dict  setObject: [self primitiveValueForKey:@"studyName"] forKey: @"Study Description"];
	if ([self primitiveValueForKey:@"patientSex"] )
		[dict  setObject: [self primitiveValueForKey:@"patientSex"] forKey: @"Patients Sex"];
	if ([self primitiveValueForKey:@"dateOfBirth"] )
		[dict  setObject: [self primitiveValueForKey:@"dateOfBirth"] forKey: @"Patients DOB"];
	if ([self primitiveValueForKey:@"institutionName"])
		[dict  setObject: [self primitiveValueForKey:@"institutionName"] forKey: @"Institution"];
	if ([self primitiveValueForKey:@"accessionNumber"])
		[dict  setObject: [self primitiveValueForKey:@"accessionNumber"] forKey: @"Accession Number"];
	if ([self primitiveValueForKey:@"comment"])
		[dict  setObject: [self primitiveValueForKey:@"comment"] forKey: @"Comment"];
	if ([self primitiveValueForKey:@"modality"])
		[dict  setObject: [self primitiveValueForKey:@"modality"] forKey: @"Modality"];
	if ([self primitiveValueForKey:@"date"])
		[dict  setObject: [self primitiveValueForKey:@"date"] forKey: @"Study Date"];
	if ([self primitiveValueForKey:@"performingPhysician"] )
		[dict  setObject: [self primitiveValueForKey:@"performingPhysician"] forKey: @"Performing Physician"];
	if ([self primitiveValueForKey:@"referringPhysician"])
		[dict  setObject: [self primitiveValueForKey:@"referringPhysician"] forKey: @"Referring Physician"];
	if ([self primitiveValueForKey:@"id"])
		[dict  setObject: [self primitiveValueForKey:@"id"] forKey: @"Study ID"];
	if ([self primitiveValueForKey:@"studyInstanceUID"])
		[dict  setObject: [self primitiveValueForKey:@"studyInstanceUID"] forKey: @"Study Instance UID"];

	return dict;
}


- (NSComparisonResult)compareName:(DicomStudy*)study;
{
	return [[self valueForKey:@"name"] caseInsensitiveCompare:[study valueForKey:@"name"]];
}

@end
