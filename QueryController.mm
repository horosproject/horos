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
#import "BrowserController.h"

static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *StudyDate = @"StudyDate";
static NSString *Modality = @"Modality";

@implementation QueryController

//******	OUTLINEVIEW

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

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [[tableColumn identifier] isEqualToString: @"name"])	// Is this study already available in our local database? If yes, display it in italic
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
		
			NSError						*error = 0L;
			NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
			NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
			NSPredicate					*predicate = [NSPredicate predicateWithFormat:  @"(studyInstanceUID == %@) AND (name == %@)", [item valueForKey:@"uid"], [item valueForKey:@"name"]];	//DCMTKQueryNode
			NSArray						*studyArray;
			
			[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
			[request setPredicate: predicate];
			
			[context lock];
			studyArray = [context executeFetchRequest:request error:&error];
			if( [studyArray count] > 0 && [[[studyArray objectAtIndex: 0] valueForKey: @"numberOfImages"] intValue] >= [[item valueForKey:@"numberImages"] intValue])
			{
				[(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised3.tif"]];
			}
			else [(ImageAndTextCell *)cell setImage: 0L];
			
			[context unlock];
		}
		else [(ImageAndTextCell *)cell setImage: 0L];
		
		[cell setFont: [NSFont boldSystemFontOfSize:13]];
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
	[queryManager sortArray: [outlineView sortDescriptors]];
	[outlineView reloadData];
}

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

		NSString *filterValue = [[searchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		[queryManager release];
		queryManager = nil;
		[outlineView reloadData];
		
		queryManager = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:netService];
		// add filters as needed
		
		if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
			//Specific Character Set
			[queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
		
		switch( [PatientModeMatrix selectedTag])
		{
			case 0:		currentQueryKey = PatientName;		break;
			case 1:		currentQueryKey = PatientID;		break;
		}
		
		if ([filterValue length] > 0) {			
			[queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
		}
		//
		if ([dateQueryFilter object]) [queryManager addFilter:[dateQueryFilter filteredValue] forDescription:@"StudyDate"];
		if ([modalityQueryFilter object]) [queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"ModalitiesinStudy"];
		
		if ([dateQueryFilter object] || [filterValue length] > 0)
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
				//	description = Modality;
				
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
	[searchField setStringValue:@""];
	[outlineView reloadData];
}

-(void) retrieve:(id)sender
{
	id object = [sender itemAtRow:[sender selectedRow]];	
	
	[NSThread detachNewThreadSelector:@selector(performRetrieve:) toTarget:self withObject:object];
}

- (void)performRetrieve:(id)object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[object retain];
	NetworkMoveDataHandler *moveDataHandler = [NetworkMoveDataHandler moveDataHandler];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[queryManager parameters]];
	NSLog(@"retrieve params: %@", [dictionary description]);
	if (dictionary != nil) {
		[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
		[object move:dictionary];
	}
	[object release];
	[pool release];
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
		NSString	*between = [NSString stringWithFormat:@"%@-%@", [[fromDate dateValue] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil], [[toDate dateValue] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];
		
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
			case 3:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*7];										break;
			case 4:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31];									break;
			
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
	
    NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
    NSMenuItem *item1, *item2, *item3;
    id searchCell = [searchField cell];
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
[fromDate setDateValue: [NSDate date]];
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
	id searchCell = [searchField cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];	
	
	[servers selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"lastQueryServer"]];
	 
    // OutlineView View
    
    [outlineView setDelegate: self];
	[outlineView setTarget: self];
	[outlineView setDoubleAction:@selector(retrieve:)];
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
	[buttonCell setAction:@selector(retrieve:)];
	[buttonCell setControlSize:NSMiniControlSize];
	[buttonCell setImage:[NSImage imageNamed:@"InArrow.tif"]];
//	[buttonCell setBordered:YES];
	[buttonCell setBezelStyle: NSRegularSquareBezelStyle];
	[tableColumn setDataCell:buttonCell];
	
	[fromDate setDateValue: [NSDate date]];
	[toDate setDateValue: [NSDate date]];
	
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
