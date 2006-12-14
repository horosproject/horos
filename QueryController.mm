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

#import "QueryController.h"
#import "WaitRendering.h"
#import "QueryFilter.h"
#import "AdvancedQuerySubview.h"
#import "DICOMLogger.h"
#import "ImageAndTextCell.h"
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import "QueryArrayController.h"
#import "NetworkMoveDataHandler.h"
#import "AdvancedQuerySubview.h"
#include "DCMTKVerifySCU.h"
#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import "DCMTKSeriesQueryNode.h"
#import "BrowserController.h"

static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *StudyDate = @"StudyDate";
static NSString *PatientBirthDate = @"PatientBirthDate";
static NSString *Modality = @"Modality";

@implementation QueryController

//******	OUTLINEVIEW

- (void)keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
	
	if( [[self window] firstResponder] == outlineView)
	{
		if(c == NSNewlineCharacter || c == NSEnterCharacter || c == NSCarriageReturnCharacter)
		{
			[self retrieveAndView: self];
		}
		else
		{
			[pressedKeys appendString: [event characters]];
			
			NSArray		*resultFilter = [[queryManager queries] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name LIKE[c] %@", [NSString stringWithFormat:@"%@*", pressedKeys]]];
			
			[pressedKeys performSelector:@selector(setString:) withObject:@"" afterDelay:0.5];
			
			if( [resultFilter count])
			{
				[outlineView selectRow: [outlineView rowForItem: [resultFilter objectAtIndex: 0]] byExtendingSelection: NO];
				[outlineView scrollRowToVisible: [outlineView selectedRow]];
			}
		}
	}	
}

- (void) refresh: (id) sender
{
	[outlineView reloadData];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item{

	return (item == nil) ? [[queryManager queries] objectAtIndex:index] : [[(DCMTKQueryNode *)item children] objectAtIndex:index];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
	if (item == nil)
		return [[queryManager queries] count];
	else
	{
		if ( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES || [item isMemberOfClass:[DCMTKRootQueryNode class]] == YES)
			return YES;
		else 
			return NO;
	}
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( item)
	{
		if (![(DCMTKQueryNode *)item children])
		{
			[progressIndicator startAnimation:nil];
			[item queryWithValues:nil];
			[progressIndicator stopAnimation:nil];
		}
	}
	return  (item == nil) ? [[queryManager queries] count] : [[(DCMTKQueryNode *) item children] count];
}

- (NSArray*) localStudy:(id) item
{
	NSArray						*studyArray = 0L;
	
	if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
	{
		NSError						*error = 0L;
		NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
		NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
		NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", [item valueForKey:@"uid"]];
		
		
		[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[request setPredicate: predicate];
		
		[context lock];
		
		studyArray = [context executeFetchRequest:request error:&error];
		
		[context unlock];
	}
	
	return studyArray;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [[tableColumn identifier] isEqualToString: @"name"])	// Is this study already available in our local database? If yes, display it in italic
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
			NSArray						*studyArray;
			
			studyArray = [self localStudy: item];
			
			if( [studyArray count] > 0)
			{
				if( [[[studyArray objectAtIndex: 0] valueForKey: @"noFiles"] intValue] >= [[item valueForKey:@"numberImages"] intValue])
					[(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised3.tif"]];
				else
					[(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised2.tif"]];
			}
			else [(ImageAndTextCell *)cell setImage: 0L];
		}
//		else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)	Series parsing is not identical on OsiriX......... not limited to uid
//		{
//			NSError						*error = 0L;
//			NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
//			NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
//			NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]];
//			NSArray						*seriesArray;
//			
//			[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
//			[request setPredicate: predicate];
//			
//			[context lock];
//			seriesArray = [context executeFetchRequest:request error:&error];
//			
//			if( [seriesArray count] > 1) NSLog(@"[seriesArray count] > 2 !!");
//			
//			if( [seriesArray count] > 0) NSLog( @"%d / %d", [[[seriesArray objectAtIndex: 0] valueForKey: @"noFiles"] intValue], [[item valueForKey:@"numberImages"] intValue]);
//			if( [seriesArray count] > 0)
//			{
//				if( [[[seriesArray objectAtIndex: 0] valueForKey: @"noFiles"] intValue] >= [[item valueForKey:@"numberImages"] intValue])
//					[(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised3.tif"]];
//				else
//					[(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised2.tif"]];
//			}
//			else [(ImageAndTextCell *)cell setImage: 0L];
//			
//			[context unlock];
//		}
		else [(ImageAndTextCell *)cell setImage: 0L];
		
		[cell setFont: [NSFont boldSystemFontOfSize:13]];
		[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{

	if ( [[tableColumn identifier] isEqualToString: @"Button"] == NO && [tableColumn identifier] != 0L)
	{
		if( [[tableColumn identifier] isEqualToString: @"numberImages"])
		{
			return [NSNumber numberWithInt: [[item valueForKey: [tableColumn identifier]] intValue]];
		}
		else return [item valueForKey: [tableColumn identifier]];		
	}
	return nil;
}

- (void)outlineView:(NSOutlineView *)aOutlineView sortDescriptorsDidChange:(NSArray *)oldDescs
{
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	[queryManager sortArray: [outlineView sortDescriptors]];
	[outlineView reloadData];
	
	if( [[[[outlineView sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
	{
		[outlineView selectRow: 0 byExtendingSelection: NO];
	}
	else [outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: item]] byExtendingSelection: NO];
	
	[outlineView scrollRowToVisible: [outlineView selectedRow]];
}

- (void) queryPatientID:(NSString*) ID
{
	[PatientModeMatrix selectTabViewItemAtIndex: 1];	// PatientID search
	
	[dateFilterMatrix selectCellWithTag: 0];
	[self setDateQuery: dateFilterMatrix];
	
	[modalityFilterMatrix selectCellWithTag: 3];
	[self setModalityQuery: modalityFilterMatrix];
	
	[searchFieldID setStringValue: ID];
	
	[self query: self];
}

//- (IBAction) changeQueryFilter:(id) sender
//{
//	NSString *sdf = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
//	NSDateFormatter *dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
//	
//	switch( [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]])
//	{
//		case 0:		[searchField setFormatter: 0L];		break;
//		case 1:		[searchField setFormatter: 0L];		break;
//		case 2:		[searchField setFormatter: dateFomat];	break;
//	}
//}

-(void) query:(id)sender
{
	
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	NSNetService *netService = nil;
	id aServer;
	if ([servers indexOfSelectedItem] >= 0)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [servers indexOfSelectedItem] forKey:@"lastQueryServer"];
		
		aServer = [[self serversList]  objectAtIndex:[servers indexOfSelectedItem]];
		
		NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 
		if ([aServer isMemberOfClass:[NSNetService class]]){
			theirAET = [(NSNetService*)aServer name];
			hostname = [(NSNetService*)aServer hostName];
			port = [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]];
			netService = aServer;
		}
		else{
			theirAET = [aServer objectForKey:@"AETitle"];
			hostname = [aServer objectForKey:@"Address"];
			port = [aServer objectForKey:@"Port"];
		}
		
		[self setDateQuery: dateFilterMatrix];
		[self setModalityQuery: modalityFilterMatrix];
		
		//get rid of white space at end and append "*"
		
		[queryManager release];
		queryManager = nil;
		[outlineView reloadData];
		
		queryManager = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:netService];
		// add filters as needed
		
		if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
			//Specific Character Set
			[queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
		
		switch( [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]])
		{
			case 0:		currentQueryKey = PatientName;		break;
			case 1:		currentQueryKey = PatientID;		break;
			case 2:		currentQueryKey = PatientBirthDate;	break;
		}
		
		BOOL queryItem = NO;
		
		if( currentQueryKey == PatientName)
		{
			NSString *filterValue = [[searchFieldName stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			if ([filterValue length] > 0)
			{
				[queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
				queryItem = YES;
			}
		}
		else if( currentQueryKey == PatientBirthDate)
		{
			[queryManager addFilter: [[searchBirth dateValue] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] forDescription:currentQueryKey];
			queryItem = YES;
		}
		else if( currentQueryKey == PatientID)
		{
			NSString *filterValue = [[searchFieldID stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			if ([filterValue length] > 0)
			{
				[queryManager addFilter:filterValue forDescription:currentQueryKey];
				queryItem = YES;
			}
		}
		
		//
		if ([dateQueryFilter object]) [queryManager addFilter:[dateQueryFilter filteredValue] forDescription:@"StudyDate"];
		
		if ([modalityQueryFilter object]) [queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"ModalitiesinStudy"];
		
		if ([dateQueryFilter object] || queryItem)
		{
			[self performQuery: 0L];
		}		
		// if filter is empty and there is no date the query may be prolonged and fail. Ask first. Don't run if cancelled
		else if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil),  NSLocalizedString(@"No query parameters provided. The query may take a long time.", nil), NSLocalizedString(@"Continue", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
		{
			[self performQuery: 0L];
		}
		
	}
	else
		NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil), NSLocalizedString( @"Please select a remote source.", nil), NSLocalizedString(@"Continue", nil), nil, nil) ;
}

-(void) advancedQuery:(id)sender
{
	//only query if have destination
				
		//get values from window
	//NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
	NSEnumerator *enumerator = [advancedQuerySubviews objectEnumerator];
	AdvancedQuerySubview *view;
	NSNetService *netService = nil;
	if (queryFilters)
		[queryFilters removeAllObjects];
	else
		queryFilters = [[NSMutableArray array] retain];
		
	if ([sender tag] > 0)
	{
		if ([servers indexOfSelectedItem] >= 0)
		{
		//setup remote query
			NSString *theirAET;
			NSString *hostname;
			NSString *port;
			NSNetService *netService = nil;
			id aServer;
			/*
			if ([servers selectedRow] < [serversArray count] && [serversArray count] > 0)
				aServer =  [serversArray objectAtIndex:[servers selectedRow]];
			else 
				aServer = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:[servers selectedRow] - [serversArray count]];
			 */
			aServer = [[self serversList]  objectAtIndex:[servers indexOfSelectedItem]];
			NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 
			if ([aServer isMemberOfClass:[NSNetService class]]){
				theirAET = [(NSNetService*)aServer name];
				hostname = [(NSNetService*)aServer hostName];
				port = [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]];
				netService = aServer;
			}
			else{
				theirAET = [aServer objectForKey:@"AETitle"];
				hostname = [aServer objectForKey:@"Address"];
				port = [aServer objectForKey:@"Port"];
			}
			if (queryManager)
				[queryManager release];
			queryManager = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:netService];

			while (view = [enumerator nextObject]) {
				int searchType;
				id value;
				int day = 86400;
				NSString *key = [[view filterKeyPopup] titleOfSelectedItem];
				//NSLog(@"key %@", key);
				if ([key isEqualToString:NSLocalizedString(@"Modality", nil)]) {					
					searchType = searchExactMatch;
					switch ([[view searchTypePopup] indexOfSelectedItem]) {
						case osiCR: value = @"CR";
								break;
						case osiCT: value = @"CT";
								break;;
						case osiDX: value = @"DX";
								break;
						case osiES: value = @"ES";
								break;
						case osiMG: value = @"MG";
								break;
						case osiMR: value = @"MR";
								break;
						case osiNM: value = @"NM";
								break;
						case osiOT: value = @"OT";
								break;
						case osiPT: value = @"PT";
								break;
						case osiRF: value = @"RF";
								break;
						case osiSC: value = @"SC";
								break;
						case osiUS: value = @"US";
								break;
						case osiXA: value = @"XA";
								break;
						default: value = [[view valueField] stringValue];
					}
					//NSLog(@"modality %@", value);
				}				
				else if ([key isEqualToString:NSLocalizedString(@"Study Date", nil)]) {
					searchType = [[view searchTypePopup] indexOfSelectedItem] +  4;
					switch (searchType){
						case 4: value = [NSDate date]; 
								break;
						case 5:
								value = [NSDate dateWithTimeIntervalSinceNow: -day];
								break;
						case 8: //NSLog(@"within Date");
								value = [NSNumber numberWithInt:[[view dateRangePopup] indexOfSelectedItem] + 10];
								break;
						/*
						case 10:
						case 11:
						case 12:
						case 13:
						case 14:
						case 15:
						case 16:
						case 17: [NSDate date]; 
						
								break;
						*/
						default: value = [[view datePicker] objectValue];
							//value = [[view valueField] objectValue];
					}
				}
				else {
					searchType = [[view searchTypePopup] indexOfSelectedItem];
					value = [[view valueField] stringValue];
				}
				//NSLog(@"%@ %d %@", key, searchType, value);
				QueryFilter *filter = [QueryFilter queryFilterWithObject:value ofSearchType:searchType  forKey:key];
				[queryFilters addObject:filter];


					
				//NSLog(@"Filter value %@", [filter filteredValue]);
			}
			//add filters to query
			enumerator = [queryFilters objectEnumerator];
			QueryFilter *filter;
			while (filter = [enumerator nextObject]) {
				NSString *description = nil;
				if ([(NSString *)[filter key] isEqualToString:NSLocalizedString(@"Patient Name", nil)])
					description = PatientName;
				else if  ([(NSString *)[filter key] isEqualToString:NSLocalizedString(@"Patient ID", nil)])
					description = PatientID;
				else if  ([(NSString *)[filter key] isEqualToString:NSLocalizedString(@"Study Date", nil)])
					description = StudyDate;
				else if  ([(NSString *)[filter key] isEqualToString:NSLocalizedString(@"Modality", nil)])
					description = @"ModalitiesinStudy";
				
				if (description)
					[queryManager addFilter:[filter filteredValue] forDescription:description];
					// add extra query for Modality
			//	if ([description isEqualToString:Modality])
			//		[queryManager addFilter:[filter filteredValue] forDescription:@"ModalitiesinStudy"];
			}
			
		//Specific Character Set
		if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
			[queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];	
		
		//run query
		[self performQuery: 0L];
		[advancedQueryWindow close];	
		}
		else
			NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil), NSLocalizedString( @"Please select a remote source.", nil), NSLocalizedString(@"Continue", nil), nil, nil) ;
	}

	[advancedQueryWindow close];	
}


// This function calls many GUI function, it has to be called from the main thread
- (void)performQuery:(id)object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[progressIndicator startAnimation:nil];
	[queryManager performQuery];
	[progressIndicator stopAnimation:nil];
	[queryManager sortArray: [outlineView sortDescriptors]];
	[outlineView reloadData];
	[pool release];
}

- (void)clearQuery:(id)sender{
	[queryManager release];
	queryManager = nil;
	[progressIndicator stopAnimation:nil];
	[searchFieldName setStringValue:@""];
	[searchFieldID setStringValue:@""];
	[outlineView reloadData];
}

-(IBAction) copy:(id) sender
{
    NSPasteboard	*pb = [NSPasteboard generalPasteboard];
			
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	id   aFile = [outlineView itemAtRow:[outlineView selectedRow]];
	
	if( aFile)
		[pb setString: [aFile valueForKey:@"name"] forType:NSStringPboardType];
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	NSIndexSet		*selectedRowIndexes = [outlineView selectedRowIndexes];
	int				index;
	
	if( [selectedRowIndexes count])
	{
		for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
		{
		   if ([selectedRowIndexes containsIndex:index])
		   {
				if( onlyIfNotAvailable)
				{
					if( [[self localStudy: [outlineView itemAtRow:index]] count] == 0) [selectedItems addObject: [outlineView itemAtRow:index]];
					NSLog( @"Already here! We don't need to download it...");
				}
				else [selectedItems addObject: [outlineView itemAtRow:index]];
		   }
		}
		
		[NSThread detachNewThreadSelector:@selector(performRetrieve:) toTarget:self withObject: selectedItems];
	}
}

-(void) retrieve:(id)sender
{
	return [self retrieve: sender onlyIfNotAvailable: NO];
}

- (IBAction) retrieveAndView: (id) sender
{
	[self retrieve: self onlyIfNotAvailable: YES];
	[self view: self];
}

- (IBAction) retrieveAndViewClick: (id) sender
{
	if( [outlineView clickedRow] >= 0)
	{
		[self retrieveAndView: sender];
	}
}

- (void) retrieveClick:(id)sender
{
	if( [outlineView clickedRow] >= 0)
	{
		[self retrieve: sender];
	}
}

- (void) performRetrieve:(NSArray*) array
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[array retain];
	
	NetworkMoveDataHandler *moveDataHandler = [NetworkMoveDataHandler moveDataHandler];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[queryManager parameters]];
	
	NSLog(@"Retrieve START");
	
	int i;
	for( i = 0; i < [array count] ; i++)
	{
		if (dictionary != nil)
		{
			[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
			[[array objectAtIndex: i] move:dictionary];
		}
	}
	
	NSLog(@"Retrieve END");
	
	[array release];
	[pool release];
}

- (void) checkAndView:(id) item
{
	[[BrowserController currentBrowser] checkIncoming: self];
	
	NSError						*error = 0L;
	NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray						*studyArray, *seriesArray;
	BOOL						success = NO;
	
	if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
	{
		NSPredicate	*predicate = [NSPredicate predicateWithFormat:  @"(studyInstanceUID == %@)", [item valueForKey:@"uid"]];
		
		[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[request setPredicate: predicate];
		
		NSLog( [predicate description]);
		
		[context lock];
		studyArray = [context executeFetchRequest:request error:&error];
		if( [studyArray count] > 0)
		{
			NSManagedObject	*study = [studyArray objectAtIndex: 0];
			NSManagedObject	*series =  [[[BrowserController currentBrowser] childrenArray: study] objectAtIndex:0];
			
			[[BrowserController currentBrowser] openViewerFromImages: [NSArray arrayWithObject: [[BrowserController currentBrowser] childrenArray: series]] movie: nil viewer :nil keyImagesOnly:NO];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
				[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
			else
				[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
				
			success = YES;
		}
	}
	
	if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
	{
		NSPredicate	*predicate = [NSPredicate predicateWithFormat:  @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]];
		
		NSLog( [predicate description]);
		
		[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
		[request setPredicate: predicate];
		
		[context lock];
		seriesArray = [context executeFetchRequest:request error:&error];
		if( [seriesArray count] > 0)
		{
			NSLog( [seriesArray description]);
			
			NSManagedObject	*series = [seriesArray objectAtIndex: 0];
			
			[[BrowserController currentBrowser] openViewerFromImages: [NSArray arrayWithObject: [[BrowserController currentBrowser] childrenArray: series]] movie: nil viewer :nil keyImagesOnly:NO];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
				[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
			else
				[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
				
			success = YES;
		}
	}
	
	if( !success)
	{
		[[BrowserController currentBrowser] checkIncoming: self];
		
		if( checkAndViewTry-- > 0)
			[self performSelector:@selector( checkAndView:) withObject:item afterDelay:1.0];
		else success = YES;
	}
	
	if( success)
	{
		[item release];
	}
	
	[context unlock];
}

- (IBAction) view:(id) sender
{
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	checkAndViewTry = 20;
	if( item) [self checkAndView: [item retain]];
}

- (void)setModalityQuery:(id)sender
{
	[modalityQueryFilter release];
	
	if ( [[sender selectedCell] tag] != 3)
	{
		modalityQueryFilter = [[QueryFilter queryFilterWithObject:[[sender selectedCell] title] ofSearchType:searchExactMatch  forKey:@"ModalitiesinStudy"] retain];
	}
	else modalityQueryFilter = [[QueryFilter queryFilterWithObject: 0L ofSearchType:searchExactMatch  forKey:@"ModalitiesinStudy"] retain];
}


- (void)setDateQuery:(id)sender
{
	[dateQueryFilter release];
	
	if( [sender selectedTag] == 5)
	{
		NSDate	*later = [[fromDate dateValue] laterDate: [toDate dateValue]];
		NSDate	*earlier = [[fromDate dateValue] earlierDate: [toDate dateValue]];
		
		NSString	*between = [NSString stringWithFormat:@"%@-%@", [earlier descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil], [later descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];
		
		dateQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyDate"] retain];
	}
	else
	{		
		DCMCalendarDate *date;
		
		int searchType = searchAfter;
		
		switch ([sender selectedTag])
		{
			case 0:			date = nil;																								break;
			case 1:			date = [DCMCalendarDate date];											searchType = SearchToday;		break;
			case 2:			date = [DCMCalendarDate dateWithNaturalLanguageString:@"Yesterday"];	searchType = searchYesterday;	break;
			case 3:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*7 -1];										break;
			case 4:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31 -1];									break;
			
		}
		dateQueryFilter = [[QueryFilter queryFilterWithObject:date ofSearchType:searchType  forKey:@"StudyDate"] retain];
	}
}

//Action methods for managing advanced queries
- (void)openAdvancedQuery:(id)sender{
	[advancedQueryWindow makeKeyAndOrderFront:sender];
}

-(void) awakeFromNib
{
	[[self window] setFrameAutosaveName:@"QueryRetrieveWindow"];
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldID cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
								action:NULL
								keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
								action:NULL
								keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
								action:NULL
								keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldName cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
									action:NULL
									keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
									action:NULL
									keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
									action:NULL
									keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	
	NSString *sdf = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
	NSDateFormatter *dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
	[[[outlineView tableColumnWithIdentifier: @"birthdate"] dataCell] setFormatter: dateFomat];
}

- (void)addQuerySubview:(id)sender{
	//setup subview
	float subViewHeight = 50.0;
	
	AdvancedQuerySubview *subview = [[[AdvancedQuerySubview alloc] initWithFrame:NSMakeRect(0.0,0.0,507.0,subViewHeight)] autorelease];
	[filterBox addSubview:subview];	
	[advancedQuerySubviews  addObject:subview];
	[[subview addButton] setTarget:self];
	[[subview addButton] setAction:@selector(addQuerySubview:)];
	[[subview filterKeyPopup] setTarget:subview];
	[[subview filterKeyPopup] setAction:@selector(showSearchTypePopup:)];
	[[subview searchTypePopup] setTarget:subview];
	[[subview searchTypePopup] setAction:@selector(showValueField:)];
	[[subview removeButton] setTarget:self];
	[[subview removeButton] setAction:@selector(removeQuerySubview:)];
	[self drawQuerySubviews];
}	

- (void)removeQuerySubview:(id)sender{
	NSView *view = [sender superview];
	[advancedQuerySubviews removeObject:view];
	[view removeFromSuperview];
	[self drawQuerySubviews];
}

- (void)chooseFilter:(id)sender{
	[(AdvancedQuerySubview *)[sender superview] showSearchTypePopup:sender];
}
//******

-(id) init
{
    if ( self = [super initWithWindowNibName:@"Query"])
	{
		if( [[self serversList] count] == 0)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Query & Retrieve",nil),NSLocalizedString( @"No DICOM locations available. See Preferences to add DICOM locations.",nil),NSLocalizedString( @"OK",nil), nil, nil);
			return 0L;
		}
	
		result = 0L;
		queryFilters = 0L;
		advancedQuerySubviews = 0L;
		dateQueryFilter = 0L;
		modalityQueryFilter = 0L;
		currentQueryKey = 0L;
		echoSuccess = 0L;
		activeMoves = 0L;
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		queryFilters = [[NSMutableArray array] retain];
		advancedQuerySubviews = [[NSMutableArray array] retain];
		activeMoves = [[NSMutableDictionary dictionary] retain];
				
		[[self window] setDelegate:self];
	}
    
    return self;
}

- (void)dealloc
{
	NSLog( @"dealloc QueryController");
	[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys];
	[pressedKeys release];
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	[queryManager release];
	[queryFilters release];
	[dateQueryFilter release];
	[modalityQueryFilter release];
	[advancedQuerySubviews release];
	[activeMoves release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)windowDidLoad
{
	id searchCell = [searchFieldName cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];

	searchCell = [searchFieldID cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
	[servers selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"lastQueryServer"]];
	 
    // OutlineView View
    
    [outlineView setDelegate: self];
	[outlineView setTarget: self];
	[outlineView setDoubleAction:@selector(retrieveAndViewClick:)];
	ImageAndTextCell *cellName = [[[ImageAndTextCell alloc] init] autorelease];
	[[outlineView tableColumnWithIdentifier:@"name"] setDataCell:cellName];
	
	//set up Query Keys
	currentQueryKey = PatientName;
	
	dateQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch  forKey:@"StudyDate"] retain];
	modalityQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch  forKey:@"ModalitiesinStudy"] retain];

	[self addQuerySubview:nil];
		
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveMessage:) name:@"DICOMRetrieveStatus" object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveMessage:) name:@"DCMRetrieveStatus" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateServers:) name:@"ServerArray has changed" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateServers:) name:@"DCMNetServicesDidChange"  object:nil];

	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"Button"];
	NSButtonCell *buttonCell = [[[NSButtonCell alloc] init] autorelease];
	[buttonCell setTarget:self];
	[buttonCell setAction:@selector(retrieveClick:)];
	[buttonCell setControlSize:NSMiniControlSize];
	[buttonCell setImage:[NSImage imageNamed:@"InArrow.tif"]];
//	[buttonCell setBordered:YES];
	[buttonCell setBezelStyle: NSRegularSquareBezelStyle];
	[tableColumn setDataCell:buttonCell];
	
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	[toDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	
}

- (void)drawQuerySubviews{
	float subViewHeight = 50.0;
		//resize Autoresizing not working.  Need to manually seet window height and origin.
	int count = [advancedQuerySubviews  count];
	NSRect windowFrame = [advancedQueryWindow frame];
	NSRect boxFrame = [filterBox frame];
	float oldWindowHeight = windowFrame.size.height;
	float newWindowHeight = 138.0 + subViewHeight * count;
	float y = windowFrame.origin.y - (newWindowHeight - oldWindowHeight);
	//NSLog(@"count %d", count);
//[filterBox setFrame:NSMakeRect(boxFrame.origin.x, boxFrame.origin.y, boxFrame.size.width, subViewHeight * count)];
	NSEnumerator *enumerator = [advancedQuerySubviews reverseObjectEnumerator];
	id view;
	int i = 0;
	while (view = [enumerator nextObject]) {
		NSRect viewFrame = [view frame];
		[view setFrame:NSMakeRect(viewFrame.origin.x, subViewHeight * i++, viewFrame.size.width, viewFrame.size.height)];
		
	}
	[advancedQueryWindow setFrame:NSMakeRect(windowFrame.origin.x, y, windowFrame.size.width, newWindowHeight) display:YES];
	[self updateRemoveButtons];
	//[advancedQueryWindow setFrame:NSMakeRect(windowFrame.origin.x, windowFrame.origin.y - subViewHeight, windowFrame.size.width, 138 + subViewHeight * count) display:YES];
}

- (void)updateRemoveButtons{
	if ([advancedQuerySubviews count] == 1) {
		AdvancedQuerySubview *view = [advancedQuerySubviews objectAtIndex:0];
		[[view removeButton] setEnabled:NO];
	}
	else {
		NSEnumerator *enumerator = [advancedQuerySubviews  objectEnumerator];
		AdvancedQuerySubview *view;
		while (view = [enumerator nextObject])
				[[view removeButton] setEnabled:YES];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setInteger: [servers indexOfSelectedItem] forKey:@"lastQueryServer"];
}

- (void)updateServers:(NSNotification *)note{
	[servers reloadData];
}

- (BOOL)dicomEcho{
	BOOL status = YES;
	id echoSCU;
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	id aServer;
	NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
	NSMutableArray *objects;
	NSMutableArray *keys; 
	if ([servers indexOfSelectedItem] >= 0)
	{
		NSLog(@"Server at Index: %d", [servers indexOfSelectedItem]);
		aServer = [[self serversList]  objectAtIndex:[servers indexOfSelectedItem]];
	 
		//Bonjour
		if ([aServer isMemberOfClass:[NSNetService class]]){
			theirAET = [(NSNetService*)aServer name];
			hostname = [(NSNetService*)aServer hostName];
			port = [NSString stringWithFormat: @"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]];
			//port = @"4096";
		}
		else{
			theirAET = [aServer objectForKey:@"AETitle"];
			hostname = [aServer objectForKey:@"Address"];
			port = [aServer objectForKey:@"Port"];

		}
	}
	DCMTKVerifySCU *verifySCU = [[[DCMTKVerifySCU alloc] initWithCallingAET:myAET  
			calledAET:theirAET  
			hostname:hostname 
			port:[port intValue]
			transferSyntax:nil
			compression: nil
			extraParameters:nil] autorelease];
	return [verifySCU echo];
}

- (IBAction)verify:(id)sender{
	id				aServer;
	NSString		*message;
	WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Verifying...", nil)];
	[wait showWindow:self];
	NSString * status = [self dicomEcho] ? @"succeeded" : @"failed";
	[wait close];
	[wait release];

	if ( [servers indexOfSelectedItem] >= 0) {
		aServer = [[self serversList]  objectAtIndex:[servers indexOfSelectedItem]];
		if ([aServer isMemberOfClass:[NSNetService class]])
			message = [NSString stringWithFormat: @"Connection to %@ at %@:%@ %@", [aServer name], [aServer hostName], [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]] , status];
		else
			message = [NSString stringWithFormat: @"Connection to %@ at %@:%@ %@", [aServer objectForKey:@"AETitle"], [aServer objectForKey:@"Address"], [aServer objectForKey:@"Port"], status];
	}
	
	NSAlert *alert = [NSAlert alertWithMessageText:@"DICOM verification" defaultButton:nil  alternateButton:nil otherButton:nil informativeTextWithFormat:message];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert runModal];

}

- (IBAction)abort:(id)sender
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter postNotificationName:@"DCMAbortQueryNotification" object:nil];
	[defaultCenter postNotificationName:@"DCMAbortMoveNotification" object:nil];
	[defaultCenter postNotificationName:@"DCMAbortEchoNotification" object:nil];
}


- (IBAction)controlAction:(id)sender{
	if ([sender selectedSegment] == 0)
		[self verify:sender];
	else if ([sender selectedSegment] == 1)
		[self abort:sender];
}

- (NSArray *) serversList
{
	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	if ([serversArray count] > 0)
		return [serversArray arrayByAddingObjectsFromArray: [[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices]];
	else
		return [[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices];
}

#pragma mark serversArray functions

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if ([aComboBox isEqual:servers]) return [[self serversList] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];


	if ([aComboBox isEqual:servers]){
		if( index > -1 && index < [serversArray count])
		{
			id theRecord = [serversArray objectAtIndex: index];			
			return [NSString stringWithFormat:@"%@ - %@",[theRecord objectForKey:@"AETitle"],[theRecord objectForKey:@"Description"]];
		}
		else if( index > -1) {
			id service = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:index - ([serversArray count])];
			return [NSString stringWithFormat:NSLocalizedString(@"%@ - Bonjour", nil), [service name]];
		}
	}
	return nil;
}
@end
