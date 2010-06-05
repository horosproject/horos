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

#import "Anonymization.h"
#import "DCMAttributeTag.h"
#import "AnonymizationViewController.h"
#import "AnonymizationSavePanelController.h"
#import "NSFileManager+N2.h"
#import "NSDictionary+N2.h"
#import "DCMObject.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "BrowserController.h"
#import "AppController.h"

@interface AnonymizationPanelRepresentation : NSObject {
	NSString* defaultsKey;
	id representedObject;
	id target;
	SEL action;
}

@property(retain) NSString* defaultsKey;
@property(retain) id representedObject;
@property(retain) id target;
@property SEL action;

@end
@implementation AnonymizationPanelRepresentation

@synthesize defaultsKey, representedObject, target, action;

-(void)dealloc {
	self.defaultsKey = NULL;
	self.representedObject = NULL;
	self.target = NULL;
	self.action = NULL;
	[super dealloc];
}

@end


@implementation Anonymization

+(DCMAttributeTag*)tagFromString:(NSString*)k {
	static NSDictionary* oldKeys = [[NSDictionary alloc] initWithObjectsAndKeys: 
									@"PatientsName", @"Patient's Name",
									@"PatientsSex", @"Patient's Sex",
									@"PatientID", @"Patient's ID",
									@"PatientsWeight", @"Patient's Weight",
									@"PatientsAge", @"Patient's Age",
									@"ClinicalTrialSponsorName", @"Trial Sponsor Name",
									@"PatientsBirthDate", @"Patient's Date of Birth",
									@"ClinicalTrialProtocolID", @"Trial Protocol ID",
									@"InstitutionName", @"Institution Name",
									@"ClinicalTrialProtocolName", @"Trial Protocol Name",
									@"StudyID", @"Study ID",
									@"ClinicalTrialSiteID", @"Trial Site ID",
									@"StudyDate", @"Study Date",
									@"ClinicalTrialSiteName", @"Trial Site Name",
									@"StudyTime", @"Study Time",
									@"ClinicalTrialSubjectReadingID", @"Trial Subject Reading ID",
									@"AcquisitionDatetime", @"Aquisition Date/Time",
									@"ClinicalTrialSubjectID", @"Trial Subject ID",
									@"SeriesDate", @"Series Date",
									@"ClinicalTrialTimePointID", @"Trial Time Point ID",
									@"SeriesTime", @"Series Time",
									@"ClinicalTrialTimePointDescription", @"Trial Time Point Description",
									@"InstanceCreationDate", @"Image Date",
									@"ClinicalTrialCoordinatingCenterName", @"Trial Coordinating Center Name",
									@"InstanceCreationTime", @"Image Time",
									@"PerformingPhysiciansName", @"Performing Physician",
									@"ReferringPhysiciansName", @"Referring Physician",
									@"PhysiciansofRecord", @"Physicians of Record",
									@"AccessionNumber", @"AccessionNumber",
									NULL];
	
	// older versions of OsiriX stored anonymization descriptors using the spaced keys and linked those with the DICOM tags through tags in the xib views and code.
	// here, through the oldKeys dictionary, we support these keys and directly translate them to standard dicom tag names.
	NSString* k2 = [oldKeys objectForKey:k];
	if (k2) k = k2;
	
	DCMAttributeTag* tag = [DCMAttributeTag tagWithName:k];
	if (!tag)
		tag = [DCMAttributeTag tagWithTagString:k];
	
	if (!tag)
		NSLog(@"Warning: unrecognized DICOM attribute tag %@", k);
	
	return tag;
}

+(NSArray*)tagsValuesArrayFromDictionary:(NSDictionary*)dic {
	NSMutableArray* out = [[NSMutableArray alloc] initWithCapacity:dic.count];
	
	for (NSString* k in dic) {
		id v = [dic objectForKey:k];
		
		DCMAttributeTag* tag = [self tagFromString:k];
		if (!tag)
			continue;
				
		if ([v isKindOfClass:[NSNull class]])
			v = NULL;
		
		[out addObject:[NSArray arrayWithObjects: tag, v, NULL]]; // if v is null then array contains only 1 object
	}
	
	return [out autorelease];
}

+(NSDictionary*)tagsValuesDictionaryFromArray:(NSArray*)arr {
	NSMutableDictionary* out = [[NSMutableDictionary alloc] initWithCapacity:arr.count];
	
	for (NSArray* a in arr) {
		DCMAttributeTag* tag = [a objectAtIndex:0];
		id v = a.count>1? [a objectAtIndex:1] : @"";
	
		NSString* k = tag.name;
		if (!k) k = tag.stringValue;
		
		[out setObject:v forKey:k];
	}
	
	return [out autorelease];
}

+(NSArray*)tagsArrayFromStringsArray:(NSArray*)strings {
	NSMutableArray* out = [NSMutableArray arrayWithCapacity:strings.count];
	
	for (NSString* s in strings) {
		DCMAttributeTag* tag = [self tagFromString:s];
		if (tag) 
			[out addObject:tag];
	}
	
	return [[out copy] autorelease];
}

+(NSArray*)stringArrayFromTagsArray:(NSArray*)tags {
	NSMutableArray* out = [NSMutableArray arrayWithCapacity:tags.count];
	
	for (DCMAttributeTag* tag in tags)
		[out addObject:tag.stringValue];
	
	return [[out copy] autorelease];
}

+(BOOL)tagsValues:(NSArray*)a1 isEqualTo:(NSArray*)a2 {
	if (a1.count != a2.count)
		return NO;
	for (NSArray* a in a1) {
		DCMAttributeTag* atag = [a objectAtIndex:0];
		id aval = a.count>1? [a objectAtIndex:1] : @"";
		BOOL found = NO;
		for (NSArray* b in a2) {
			DCMAttributeTag* btag = [b objectAtIndex:0];
			id bval = b.count>1? [b objectAtIndex:1] : @"";
			if ([atag isEqual:btag]) {
				found = YES;
				if (!(aval == bval || [aval isEqual:bval]))
					return NO;
			}
		}
		if (!found)
			return NO;
	}
	
	return YES;
}

#pragma mark Panel

+(id)showPanelClass:(Class)c forDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject  {
	NSArray* values = [Anonymization tagsValuesArrayFromDictionary:[[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:[NSString stringWithFormat:@"%@Values", defaultsKey]]];
	NSArray* tags = [self tagsArrayFromStringsArray:[[NSUserDefaultsController sharedUserDefaultsController] arrayForKey:defaultsKey]];
	
	AnonymizationPanelController* panelController = [[c alloc] initWithTags:tags values:values];
	AnonymizationPanelRepresentation* ro = [[[AnonymizationPanelRepresentation alloc] init] autorelease];
	ro.defaultsKey = defaultsKey;
	ro.representedObject = representedObject;
	ro.target = delegate;
	ro.action = sel;
	panelController.representedObject = ro;
	
	[NSApp beginSheet:panelController.window modalForWindow:window modalDelegate:self didEndSelector:@selector(panelDidEnd:returnCode:contextInfo:) contextInfo:panelController];
	[panelController.window orderFront:self];
	
	if (!delegate)
		[NSApp runModalForWindow:panelController.window];
	
	return panelController;
}

+(AnonymizationPanelController*)showPanelForDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject  {
	return [self showPanelClass:[AnonymizationPanelController class] forDefaultsKey:defaultsKey modalForWindow:window modalDelegate:delegate didEndSelector:sel representedObject:representedObject];
}

+(AnonymizationSavePanelController*)showSavePanelForDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject  {
	return [self showPanelClass:[AnonymizationSavePanelController class] forDefaultsKey:defaultsKey modalForWindow:window modalDelegate:delegate didEndSelector:sel representedObject:representedObject];
}

+(void)panelDidEnd:(NSPanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	AnonymizationPanelController* panelController = (id)contextInfo;
	AnonymizationPanelRepresentation* ro = panelController.representedObject;
	
	if (panelController.end) { // save config
		[[NSUserDefaults standardUserDefaults] setObject:[self stringArrayFromTagsArray:panelController.anonymizationViewController.tags] forKey:ro.defaultsKey];
		[[NSUserDefaults standardUserDefaults] setObject:[self tagsValuesDictionaryFromArray:panelController.anonymizationViewController.tagsValues] forKey:[NSString stringWithFormat:@"%@Values", ro.defaultsKey]];
	}
	
	[panel close];
	
	[ro retain];
	panelController.representedObject = ro.representedObject;
	if (ro.target)
		[ro.target performSelector:ro.action withObject:panelController];
	else if (panelController.end)
			[NSApp stopModal];
		else [NSApp abortModal];
	[ro release];
	
	[panelController release];
}

#pragma mark Anonymization

+(NSDictionary*)anonymizeFiles:(NSArray*)files toPath:(NSString*)dirPath withTags:(NSArray*)tags {
	NSMutableDictionary* filenameTranslation = [NSMutableDictionary dictionaryWithCapacity:files.count];
	
	NSString* tempDirPath = [dirPath stringByAppendingPathComponent:@".temp"];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:tempDirPath];
	
	NSInteger fileIndex = 0;
	for (NSString* filePath in files) {
		NSString* ext = [filePath pathExtension];
		if (!ext.length) ext = @"dcm";
		NSString* tempFileName = [NSString stringWithFormat:@"%d.%@", fileIndex, ext];
		NSString* tempFilePath = [tempDirPath stringByAppendingPathComponent:tempFileName];
		[DCMObject anonymizeContentsOfFile:filePath tags:tags writingToFile:tempFilePath];
		[filenameTranslation setObject:tempFilePath forKey:filePath];
		++fileIndex;
	}
	
	NSManagedObjectModel* managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"]]];
	NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	[persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:NULL URL:NULL options:NULL error:NULL];
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
	managedObjectContext.undoManager.levelsOfUndo = 1;	
	[managedObjectContext.undoManager disableUndoRegistration];
	
	NSArray* dicomImages = [BrowserController addFiles:[filenameTranslation allValues] toContext:managedObjectContext onlyDICOM:YES notifyAddedFiles:NO parseExistingObject:NO dbFolder:NULL];
		
	NSMutableArray* dicomSeries = [NSMutableArray array];
	for (DicomImage* image in dicomImages)
	{
		if (![dicomSeries containsObject:image.series])
			[dicomSeries addObject:image.series];
		
		NSString* tempFilePath = image.completePathResolved;
		NSString* ext = [tempFilePath pathExtension];
		
		NSString* fileDirPath = [dirPath stringByAppendingPathComponent:image.series.study.name];
		fileDirPath = [fileDirPath stringByAppendingPathComponent:image.series.study.studyName];
		fileDirPath = [fileDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@", image.series.name, image.series.id]];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:fileDirPath];
		
		NSString* filePath;
		NSInteger i = 0;
		do {
			++i;
			NSString* is = i ? [NSString stringWithFormat:@"-%4.4d", i] : @"";
			NSString* fileName = [NSString stringWithFormat:@"IM-%4.4d-%4.4d%@.%@", dicomSeries.count, image.instanceNumber, is, ext];
			filePath = [fileDirPath stringByAppendingPathComponent:fileName];
		} while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
		
		[[NSFileManager defaultManager] moveItemAtPath:tempFilePath toPath:filePath error:NULL];
		
		NSString* k = [filenameTranslation keyForObject:tempFilePath];
		if (k) [filenameTranslation setObject:filePath forKey:filenameTranslation];
		else NSLog(@"Warning: anonymization file naming error: unknown original for %@ which should have changed to %@", tempFilePath, filePath);
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:tempDirPath error:NULL];
	
	[managedObjectContext release];
	[persistentStoreCoordinator release];
	[managedObjectModel release];	
	
	return [[filenameTranslation copy] autorelease];
}


@end
