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

/* 7/14/05 Added bonjour DICOM servers to servers. LP */


#import "QueryController.h"
//#import "DICOMQueryStudyRoot.h"
//#import "PMAttributeTag.h"
//#import "PMAttribute.h"
//#import "PMDirectoryRecord.h"
//#import "PMAttributeList.h"
#import "WaitRendering.h"
#import "QueryFilter.h"
#import "AdvancedQuerySubview.h"
#import "DICOMLogger.h"
#import "ImageAndTextCell.h"
//#import <OsiriX/DCM.h"
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import "QueryArrayController.h"
#import "NetworkMoveDataHandler.h"
#import "AdvancedQuerySubview.h"
#include "DCMTKVerifySCU.h"
#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
//#import "DCMTKSeriesQueryNode.h"
//#import "DCMTKImageQueryNode.h"


//extern int mainFindSCU(int argc, char *argv[]);
static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *StudyDate = @"StudyDate";
static NSString *Modality = @"Modality";
static NSString *logPath = @"~/Library/Logs/osirix.log";

@implementation QueryController

//Table View servers

- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
	if ([aTableView isEqual:servers]){
		return [[self serversList] count];
	}
	else
		return [moveLog count];
		
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if ([aTableView isEqual:servers])
	{
		id server  = [[self serversList] objectAtIndex:rowIndex];	
		if ([server isMemberOfClass:[NSNetService class]])
			return [NSString stringWithFormat:@"%@ - Bonjour", [server name]];
		else
			return [NSString stringWithFormat:@"%@ - %@",[server objectForKey:@"AETitle"],[server objectForKey:@"Description"]];
	/*
		if( rowIndex > -1 && rowIndex < [serversArray count])
		{
			id theRecord = [serversArray objectAtIndex:rowIndex];			
			return [NSString stringWithFormat:@"%@ - %@",[theRecord objectForKey:@"AETitle"],[theRecord objectForKey:@"Description"]];
		}
		else if( rowIndex > -1) {
			id service = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:rowIndex - ([serversArray count])];
			return [NSString stringWithFormat:@"%@ - Bonjour", [service name]];
		}
	*/
	}
	else{
		if (![[aTableColumn identifier] isEqualToString:@"Status"])
			return [[moveLog objectAtIndex:rowIndex] valueForKey:[aTableColumn identifier]];
		return nil;
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
		return NO;
}

 


//******	OUTLINEVIEW

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
	//NSLog(@"number of Children for :%@", [item description]);
	if( item)
	{
		if (![(DCMTKQueryNode *)item children]) {
			[progressIndicator startAnimation:nil];
			//[item queryWithValues:nil parameters:[queryManager parameters]];
			//NSLog(@"Query Series: %@", [item description]);
			[item queryWithValues:nil];
			[progressIndicator stopAnimation:nil];
		}
	}
	return  (item == nil) ? [[queryManager queries] count] : [[(DCMTKQueryNode *) item children] count];
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

//Actions
-(void) query:(id)sender
{
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	NSNetService *netService = nil;
	id aServer;
	if ([servers selectedRow] >= 0) {
		/*
		if ([servers selectedRow] < [serversArray count]  && [serversArray count] > 0)
			aServer =  [serversArray objectAtIndex:[servers selectedRow]];
		else 
			aServer = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:[servers selectedRow] - [serversArray count]];
		*/
		aServer = [[self serversList]  objectAtIndex:[servers selectedRow]];
		NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 
		if ([aServer isMemberOfClass:[NSNetService class]]){
			theirAET = [aServer name];
			hostname = [aServer hostName];
			port = [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]];
			netService = aServer;
		}
		else{
			theirAET = [aServer objectForKey:@"AETitle"];
			hostname = [aServer objectForKey:@"Address"];
			port = [aServer objectForKey:@"Port"];
		}
	//get rid of white space at end and append "*"

		NSString *filterValue = [[searchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (queryManager)
			[queryManager release];
		queryManager = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:netService];
	// add filters as needed
		
		if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
			//Specific Character Set
			[queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
	
		if ([filterValue length] > 0) {			
			[queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
		}
		//need to change string to format YYYYMMDD
		DCMCalendarDate *startingDate = [dateQueryFilter object];
		//NSLog(@"query start date: %@", [startingDate description]);
		if (startingDate) {
			NSMutableString *dateString = [NSMutableString stringWithString: [startingDate descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];			
			[queryManager addFilter:dateString forDescription:@"StudyDate"];
		}
		
		if (startingDate || [filterValue length] > 0)
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

-(void) advancedQuery:(id)sender{
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
		
	if ([sender tag] > 0) {
		if ([servers selectedRow] >= 0) {
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
			 aServer = [[self serversList]  objectAtIndex:[servers selectedRow]];
			NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 
			if ([aServer isMemberOfClass:[NSNetService class]]){
				theirAET = [aServer name];
				hostname = [aServer hostName];
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

-(void) retrieve:(id)sender{
	id object = [sender itemAtRow:[sender selectedRow]];
    [NSThread detachNewThreadSelector:@selector(performRetrieve:) toTarget:self withObject:object];
}

- (void)performRetrieve:(id)object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NetworkMoveDataHandler *moveDataHandler = [NetworkMoveDataHandler moveDataHandler];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[queryManager parameters]];
	NSLog(@"retrieve params: %@", [dictionary description]);
	if (dictionary != nil) {
		[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
		[object move:dictionary];
	}
	[pool release];
}

- (void)setCurrentQueryKey:(id)sender{
	if ([sender tag] == 0)
		currentQueryKey = PatientName;
		
	else if ([sender tag] == 1)
		currentQueryKey = PatientID;
		
	[queryKeyField setStringValue:[sender title]];
}

- (void)setDateQuery:(id)sender{
	[dateQueryFilter release];
	DCMCalendarDate *date;
	if ([sender tag] == 0)
		date = [DCMCalendarDate date];
	else if ([sender tag] == 1)
		date = [DCMCalendarDate dateWithNaturalLanguageString:@"Yesterday"];
	else 
		date = nil;
		
	dateQueryFilter = [[QueryFilter queryFilterWithObject:date ofSearchType:searchExactMatch  forKey:@"StudyDate"] retain];	
	[queryDateField setStringValue:[sender title]];
}

//Action methods for managing advanced queries
- (void)openAdvancedQuery:(id)sender{
	[advancedQueryWindow makeKeyAndOrderFront:sender];
}

-(void) awakeFromNib
{
	[[self window] setFrameAutosaveName:@"QueryRetrieveWindow"];
	
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
		currentQueryKey = 0L;
		logString = 0L;
		echoSuccess = 0L;
		activeMoves = 0L;
		moveLog = 0L;
		currentEchoRow = 0L;
		echoImage = 0L;
		
		queryFilters = [[NSMutableArray array] retain];
		advancedQuerySubviews = [[NSMutableArray array] retain];
		activeMoves = [[NSMutableDictionary dictionary] retain];
		moveLog = [[NSMutableArray array] retain];
		
		logString = [NSString stringWithContentsOfFile:[logPath stringByExpandingTildeInPath]];
		if (!logString)
		{
			logString = @"";
		}
		[logString retain];

	}
    
    return self;
}

- (void)dealloc{
	[logString release];
	[queryManager release];
	[queryFilters release];
	[dateQueryFilter release];
	[advancedQuerySubviews release];
	[activeMoves release];
	[moveLog release];
	[echoImage release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)windowDidLoad
{
	//create prototype Menu for SearchField
	NSMenu *prototype = [[NSMenu alloc] initWithTitle:@"Search Menu"];
	NSMenuItem *itemName, *itemID, *itemToday, *itemYesterday, *itemAnyDate, *itemAdvanced;
    id searchCell = [searchField cell];
	
	itemName = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Patient Name", nil) action: @selector(setCurrentQueryKey:) keyEquivalent:@""];
	[itemName setTag:0];
    [prototype addItem:itemName];
	
	itemID = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Patient ID", nil) action: @selector(setCurrentQueryKey:) keyEquivalent:@""];
    [prototype addItem:itemID];
	[itemID setTag:1];
	
	[prototype addItem:[NSMenuItem separatorItem]];
	
	itemToday = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Today", nil) action: @selector(setDateQuery:) keyEquivalent:@""];
    [prototype addItem:itemToday];
	[itemToday setTag:0];
	
	itemYesterday = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Yesterday", nil) action: @selector(setDateQuery:) keyEquivalent:@""];
	[itemYesterday setTag:1];
    [prototype addItem:itemYesterday];
	
	itemAnyDate = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Any Date", nil) action: @selector(setDateQuery:) keyEquivalent:@""];
	[itemAnyDate setTag:2];
    [prototype addItem:itemAnyDate];
	
	[prototype addItem:[NSMenuItem separatorItem]];
	
	itemAdvanced = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Advanced Search", nil) action: @selector(openAdvancedQuery:) keyEquivalent:@""];
    [prototype addItem:itemAdvanced];
	
	[searchCell setSearchMenuTemplate:prototype];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell]  setAction:@selector(clearQuery:)];	

	//[searchCell setCancelButtonCell:nil];
	
	[itemToday release];
	[itemYesterday release];
	[itemAdvanced release];
	[prototype release];	
	[itemName release];
	[itemID release];
	// Finsihed submenu add
	

	//add data to servers tableView;
	//[servers setTarget:self];
	//[servers setAction:@selector(dicomEcho:)];
	ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
	[cell setEditable:NO];
	[[servers tableColumnWithIdentifier:@"Source"] setDataCell:cell];
    [servers reloadData];
	
    // OutlineView View
    
    [outlineView setDelegate: self];
	[outlineView setTarget: self];
	[outlineView setDoubleAction:@selector(retrieve:)];

	[statusField setStringValue:@" "];
	//set up Query Keys
	currentQueryKey = PatientName;
	[queryKeyField setStringValue:NSLocalizedString(@"Patient Name", nil)];
	dateQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch  forKey:@"StudyDate"] retain];
	[queryDateField setStringValue:NSLocalizedString(@"Any Date", nil)];

	[self addQuerySubview:nil];
	[logView setEditable:NO];
	[[logView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:logString] autorelease]];
	[logView scrollRangeToVisible:NSMakeRange([[logView string] length], 0)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveMessage:) name:@"DICOMRetrieveStatus" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveMessage:) name:@"DCMRetrieveStatus" object:nil];
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
	NSImageCell *imageCell = [[[NSImageCell alloc] init] autorelease];
	[statusTableColumn setDataCell:imageCell];
	
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
    [[self window] setDelegate:nil];
}
- (void)updateServers:(NSNotification *)note{
	[servers reloadData];
}

- (void)retrieveMessage:(NSNotification *)note{

	//updates status of retrieve
	
	NSDictionary *info = [note userInfo];
	NSDate *date = [info objectForKey:@"Time"];
	//NSLog(@"userInfo: %@", [info description]);
	if (date) {
		//if we already have the datahandler we have already added to active moves. need to replace objects
		if ([[activeMoves allKeys] containsObject:date]){
			NSMutableDictionary *dictionary = [activeMoves objectForKey:date];
			[dictionary setDictionary:info];
		}
		else
		{
			[activeMoves setObject:info forKey:date];
			[moveLog addObject:info];
			//should scroll to bottom  Not sure how to do it.
		}
		
	if ([[info objectForKey:@"RetrieveComplete"] boolValue])
		[activeMoves removeObjectForKey:date];
	}
		
	[logTable reloadData];
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
	if ([servers selectedRow] >= 0) {
		NSLog(@"Server at Index: %d", [servers selectedRow]);
		aServer = [[self serversList]  objectAtIndex:[servers selectedRow]];
	 
		//Bonjour
		if ([aServer isMemberOfClass:[NSNetService class]]){
			theirAET = [aServer name];
			hostname = [aServer hostName];
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
	//return runEcho([myAET UTF8String], [theirAET UTF8String], [hostname UTF8String], [port intValue], nil);
	
	
	/*
	BOOL status = YES;
	id echoSCU;
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	id aServer;
	NSData *address = nil;
	NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
	NSMutableArray *objects;
	NSMutableArray *keys; 
	if ([servers selectedRow] >= 0) {
		NSLog(@"Server at Index: %d", [servers selectedRow]);
		aServer = [[self serversList]  objectAtIndex:[servers selectedRow]];
	 
		//Bonjour
		if ([aServer isMemberOfClass:[NSNetService class]]){
			theirAET = [aServer name];
			objects = [NSMutableArray arrayWithObjects:myAET, theirAET, aServer, nil];
			keys = [NSMutableArray arrayWithObjects:@"callingAET", @"calledAET", @"netService", nil];
		}
		else{
			theirAET = [aServer objectForKey:@"AETitle"];
			hostname = [aServer objectForKey:@"Address"];
			port = [aServer objectForKey:@"Port"];
			objects = [NSMutableArray arrayWithObjects:myAET, theirAET, hostname, port, nil];
			keys = [NSMutableArray arrayWithObjects:@"callingAET", @"calledAET", @"hostname", @"port", nil];
		}
	}
	echoSuccess = YES;


		
	NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	
	//Parameters needed for initiation are:
	//@"hostname"					string
	//@"port"						NSNumber int
	//@"calledAET"				string
	//@"callingAET"				string
	
	return  [DCMVerificationSOPClassSCU echoSCUWithParams:params];
	*/

}

- (IBAction)verify:(id)sender{
	id				aServer;
	NSString		*message;
	WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Verifying...", nil)];
	[wait showWindow:self];
	NSString * status = [self dicomEcho] ? @"succeeded" : @"failed";
	[wait close];
	[wait release];

	if ( [servers selectedRow] >= 0) {
		aServer = [[self serversList]  objectAtIndex:[servers selectedRow]];
		if ([aServer isMemberOfClass:[NSNetService class]])
			message = [NSString stringWithFormat: @"Connection to %@ at %@:%@ %@", [aServer name], [aServer hostName], [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]] , status];
		else
			message = [NSString stringWithFormat: @"Connection to %@ at %@:%@ %@", [aServer objectForKey:@"AETitle"], [aServer objectForKey:@"Address"], [aServer objectForKey:@"Port"], status];
	}
	
	// standard servers
	/*
	if ( [servers selectedRow] >= 0 && ([servers selectedRow] < [serversArray count] && [serversArray count] > 0)) {
		aServer = [serversArray objectAtIndex:[servers selectedRow]];
		message = [NSString stringWithFormat: @"Connection to %@ at %@:%@ %@", [aServer objectForKey:@"AETitle"], [aServer objectForKey:@"Address"], [aServer objectForKey:@"Port"], status];
	}
	//bonjour servers
	else if ([servers selectedRow] > 0 ){
		aServer = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:[servers selectedRow]  - [serversArray count]];
		NSLog(@"bojour server: %@", [aServer description]);
		message = [NSString stringWithFormat: @"Connection to %@ at %@:%@ %@", [aServer name], [aServer hostName], [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:aServer]] , status];
	}	
	*/
	NSAlert *alert = [NSAlert alertWithMessageText:@"DICOM verification" defaultButton:nil  alternateButton:nil otherButton:nil informativeTextWithFormat:message];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert runModal];

}

- (IBAction)abort:(id)sender{
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


@end
