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

#include "SimplePing.h"

static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *AccessionNumber = @"AccessionNumber";
static NSString *StudyDate = @"StudyDate";
static NSString *PatientBirthDate = @"PatientBirthDate";
static NSString *Modality = @"Modality";

static QueryController	*currentQueryController = 0L;

static char *GetPrivateIP()
{
	struct			hostent *h;
	char			hostname[100];
	gethostname(hostname, 99);
	if ((h=gethostbyname(hostname)) == NULL)
	{
        perror("Error: ");
        return "(Error locating Private IP Address)";
    }
	
    return (char*) inet_ntoa(*((struct in_addr *)h->h_addr));
}

@implementation QueryController

//******	OUTLINEVIEW

+ (QueryController*) currentQueryController
{
	return currentQueryController;
}

+ (BOOL) echo: (NSString*) address port:(int) port AET:(NSString*) aet
{
	NSTask* theTask = [[[NSTask alloc]init]autorelease];
	
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]];

	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]];

	NSArray *args = [NSArray arrayWithObjects: address, [NSString stringWithFormat:@"%d", port], @"-aet", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"-aec", aet, @"-to", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-ta", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-td", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-d", nil];
	
	NSLog( [args description]);
	
	[theTask setArguments:args];
	[theTask launch];
	[theTask waitUntilExit];
	
	if( [theTask terminationStatus] == 0) return YES;
	else return NO;
}


- (void)keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
	
	if( [[self window] firstResponder] == outlineView)
	{
		if( c == NSDeleteCharacter)
		{
			[[BrowserController currentBrowser] showEntireDatabase];
			
			NSIndexSet* indices = [outlineView selectedRowIndexes];
			int i;
			BOOL extendingSelection = NO;
			
			for( i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
			{
				if( [indices containsIndex: i])
				{
					NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i]];
		
					if( [studyArray count] > 0)
					{
						NSManagedObject	*series =  [[[BrowserController currentBrowser] childrenArray: [studyArray objectAtIndex: 0]] objectAtIndex:0];
						[[BrowserController currentBrowser] findAndSelectFile:0L image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO extendingSelection: extendingSelection];
						extendingSelection = YES;
					}
				} 
			}
			
			if( extendingSelection)
			{
				[[BrowserController currentBrowser] delItem: self];
			}
		}
		else if( c == NSNewlineCharacter || c == NSEnterCharacter || c == NSCarriageReturnCharacter)
		{
			[self retrieveAndView: self];
		}
		else
		{
			[pressedKeys appendString: [event characters]];
			
			NSArray		*resultFilter = [resultArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", [NSString stringWithFormat:@"%@*", pressedKeys]]];
			
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

	return (item == nil) ? [resultArray objectAtIndex:index] : [[(DCMTKQueryNode *)item children] objectAtIndex:index];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == nil)
		return [resultArray count];
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
	return  (item == nil) ? [resultArray count] : [[(DCMTKQueryNode *) item children] count];
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
		
		[context retain];
		[context lock];
		
		studyArray = [context executeFetchRequest:request error:&error];
		
		[context unlock];
		[context release];
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
					[(ImageAndTextCell *)cell setImage: Realised3];
				else
					[(ImageAndTextCell *)cell setImage: Realised2];
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
//			[context retain];
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
//			[context release];
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
	
	[resultArray sortUsingDescriptors: [outlineView sortDescriptors]];
	[outlineView reloadData];
	
	if( [[[[outlineView sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
	{
		[outlineView selectRow: 0 byExtendingSelection: NO];
	}
	else [outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: item]] byExtendingSelection: NO];
	
	[outlineView scrollRowToVisible: [outlineView selectedRow]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet			*index = [outlineView selectedRowIndexes];
	id					item = [outlineView itemAtRow:[index firstIndex]];
	
	if( item)
	{
		[selectedResultSource setStringValue: [NSString stringWithFormat:@"%@  /  %@:%d", [item valueForKey:@"calledAET"], [item valueForKey:@"hostname"], [[item valueForKey:@"port"] intValue]]];
	}
	else [selectedResultSource setStringValue:@""];
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

- (BOOL) array: uidArray containsObject: (NSString*) uid
{
	int x;
	BOOL result = NO;
	
	for( x = 0 ; x < [uidArray count]; x++)
	{
		if( [[uidArray objectAtIndex: x] isEqualToString: uid]) return YES;
	}
	
	return result;
}

-(void) query:(id)sender
{
	if ([sender isKindOfClass:[NSSearchField class]])
	{
		NSString	*chars = [[NSApp currentEvent] characters];
		
		if( [chars length])
		{
			if( [chars characterAtIndex:0] != 13 && [chars characterAtIndex:0] != 3) return;
		}
	}

	NSString			*theirAET;
	NSString			*hostname;
	NSString			*port;
	NSNetService		*netService = nil;
	id					aServer;
	int					i, selectedServer, selectedRow;
	BOOL				atLeastOneSource = NO, noChecked = YES;
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];
	
	[resultArray removeAllObjects];
	[outlineView reloadData];
	
	noChecked = YES;
	for( i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
		{
			noChecked = NO;
		}
	}
	
	selectedServer = -1;
	if( noChecked)
	{
		selectedServer = [sourcesTable selectedRow];
	}
	
	selectedRow = [sourcesTable selectedRow];
	
	atLeastOneSource = NO;
	for( i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES || selectedServer == i)
		{
			aServer = [[sourcesArray objectAtIndex:i] valueForKey:@"server"];
			
			[sourcesTable selectRow: i byExtendingSelection: NO];
			
			NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 			
			theirAET = [aServer objectForKey:@"AETitle"];
			hostname = [aServer objectForKey:@"Address"];
			port = [aServer objectForKey:@"Port"];
			
			int numberPacketsReceived = 0;
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || (SimplePing( [hostname UTF8String], 1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"], 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0))
			{
				//if( [QueryController echo: hostname port: [port intValue] AET:theirAET])
				{
					[self setDateQuery: dateFilterMatrix];
					[self setModalityQuery: modalityFilterMatrix];
					
					//get rid of white space at end and append "*"
					
					[queryManager release];
					queryManager = nil;
					
					queryManager = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:netService];
					// add filters as needed
					
					if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
						//Specific Character Set
						[queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
					
					switch( [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]])
					{
						case 0:		currentQueryKey = PatientName;		break;
						case 1:		currentQueryKey = PatientID;		break;
						case 2:		currentQueryKey = AccessionNumber;	break;
						case 3:		currentQueryKey = PatientBirthDate;	break;
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
					else if( currentQueryKey == AccessionNumber)
					{
						NSString *filterValue = [[searchFieldAN stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						
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
					else
					{
						BOOL doit = NO;
						
						if( atLeastOneSource == NO)
						{
							 if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil),  NSLocalizedString(@"No query parameters provided. The query may take a long time.", nil), NSLocalizedString(@"Continue", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn) doit = YES;
						}
						else doit = YES;
						
						if( doit) [self performQuery: 0L];
						else i = [sourcesArray count];
					}
					
					if( [resultArray count] == 0)
					{
						[resultArray addObjectsFromArray: [queryManager queries]];
					}
					else
					{
						int			x;
						NSArray		*curResult = [queryManager queries];
						NSArray		*uidArray = [resultArray valueForKey: @"uid"];
						
						for( x = 0 ; x < [curResult count] ; x++)
						{
							if( [self array: uidArray containsObject: [[curResult objectAtIndex: x] valueForKey:@"uid"]] == NO)
							{
								[resultArray addObject: [curResult objectAtIndex: x]];
							}
						}
					}
				}
//				else
//				{
//					NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", theirAET, hostname, [port intValue]];
//				
//					response = [response stringByAppendingString:NSLocalizedString(@"Connection failed to this DICOM node (c-echo failed)", 0L)];
//					
//					NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), response, NSLocalizedString(@"Continue", nil), nil, nil) ;
//				}
			}
			else
			{
				NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", theirAET, hostname, [port intValue]];
				
				response = [response stringByAppendingString:NSLocalizedString(@"Connection failed to this DICOM node (ping failed)", 0L)];
				
				NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), response, NSLocalizedString(@"Continue", nil), nil, nil) ;
			}
			atLeastOneSource = YES;
		}
	}
	
	[sourcesTable selectRow: selectedRow byExtendingSelection: NO];
	
	[resultArray sortUsingDescriptors: [outlineView sortDescriptors]];
	[outlineView reloadData];
	
	if( atLeastOneSource == NO)
		NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil), NSLocalizedString( @"Please select a DICOM node (check box).", nil), NSLocalizedString(@"Continue", nil), nil, nil) ;

	if ([sender isKindOfClass:[NSSearchField class]])
	{
		[sender selectText: self];
	}
	
	if( [resultArray count] <= 1) [numberOfStudies setStringValue: [NSString stringWithFormat:@"%d study found.", [resultArray count]]];
	else [numberOfStudies setStringValue: [NSString stringWithFormat:@"%d studies found.", [resultArray count]]];
}

// This function calls many GUI function, it has to be called from the main thread
- (void)performQuery:(id)object
{
	checkAndViewTry = -1;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[progressIndicator startAnimation:nil];
	[queryManager performQuery];
	[progressIndicator stopAnimation:nil];
	[resultArray sortUsingDescriptors: [outlineView sortDescriptors]];
	[outlineView reloadData];
	[pool release];
}

- (void)clearQuery:(id)sender{
	[queryManager release];
	queryManager = nil;
	[progressIndicator stopAnimation:nil];
	[searchFieldName setStringValue:@""];
	[searchFieldID setStringValue:@""];
	[searchFieldAN setStringValue:@""];
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

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable forViewing: (BOOL) forViewing
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
		
		if( [selectedItems count] > 0)
		{
			if( [sendToPopup indexOfSelectedItem] != 0 && forViewing == YES)
			{
				NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Query & Retrieve",nil),NSLocalizedString( @"If you want to retrieve & view these images, change the destination to this computer ('retrieve to' menu).",nil),NSLocalizedString( @"OK",nil), nil, nil);
			}
			else
			{
				WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting Retrieving...", nil)];
				[wait showWindow:self];
				
				checkAndViewTry = -1;
				[NSThread detachNewThreadSelector:@selector(performRetrieve:) toTarget:self withObject: selectedItems];
				
				Delay( 30, 0L);
				
				[wait close];
				[wait release];
			}
		}
	}
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable
{
	return [self retrieve: sender onlyIfNotAvailable: NO forViewing: NO];
}

-(void) retrieve:(id)sender
{
	return [self retrieve: sender onlyIfNotAvailable: NO];
}

- (IBAction) retrieveAndView: (id) sender
{
	[self retrieve: self onlyIfNotAvailable: YES forViewing: YES];
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
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary: [queryManager parameters]];
	
	NSLog( @"Retrieve START");
	NSLog( [dictionary description]);
	
	[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
	
	int i;
	for( i = 0; i < [array count] ; i++)
	{
		DCMTKQueryNode	*object = [array objectAtIndex: i];

		[dictionary setObject:[object valueForKey:@"calledAET"] forKey:@"calledAET"];
		[dictionary setObject:[object valueForKey:@"hostname"] forKey:@"hostname"];
		[dictionary setObject:[object valueForKey:@"port"] forKey:@"port"];
		[dictionary setObject:[object valueForKey:@"transferSyntax"] forKey:@"transferSyntax"];

		NSDictionary	*dstDict = 0L;
		
		if( [sendToPopup indexOfSelectedItem] != 0)
		{
			NSInteger index = [sendToPopup indexOfSelectedItem] -2;
			
			dstDict = [[DCMNetServiceDelegate DICOMServersList] objectAtIndex: index];
			
			[dictionary setObject: [dstDict valueForKey:@"AETitle"]  forKey: @"moveDestination"];
		}
		
		if( [[dstDict valueForKey:@"Port"] intValue]  == [[dictionary valueForKey:@"port"] intValue] &&
			[[dstDict valueForKey:@"Address"] isEqualToString: [dictionary valueForKey:@"hostname"]])
			{
				NSLog( @"move source == move destination -> Do Nothing");
			}
		else
		{
			int numberPacketsReceived = 0;
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || (SimplePing( [[dictionary valueForKey:@"hostname"] UTF8String], 1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"], 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0))
			{
				[object move:dictionary];
			}
		}
	}
	
	NSLog(@"Retrieve END");
	
	[array release];
	[pool release];
}

- (void) checkAndView:(id) item
{
	if( [[self window] isVisible] == NO) return;
	if( checkAndViewTry < 0) return;
	
	[[BrowserController currentBrowser] checkIncoming: self];
	
	NSError						*error = 0L;
	NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray						*studyArray, *seriesArray;
	BOOL						success = NO;

	[context retain];
	[context lock];

	if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
	{
		NSPredicate	*predicate = [NSPredicate predicateWithFormat:  @"(studyInstanceUID == %@)", [item valueForKey:@"uid"]];
		
		[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[request setPredicate: predicate];
		
		studyArray = [context executeFetchRequest:request error:&error];
		if( [studyArray count] > 0)
		{
			NSManagedObject	*study = [studyArray objectAtIndex: 0];
			NSManagedObject	*series =  [[[BrowserController currentBrowser] childrenArray: study] objectAtIndex:0];
			
			if( [[BrowserController currentBrowser] findAndSelectFile:0L image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO] == NO)
			{
				[[BrowserController currentBrowser] showEntireDatabase];
				if( [[BrowserController currentBrowser] findAndSelectFile:0L image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO]) success = YES;
			}
			else success = YES;
			
			if( success) [[BrowserController currentBrowser] databaseOpenStudy: study];
		}
	}
	
	if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
	{
		NSPredicate	*predicate = [NSPredicate predicateWithFormat:  @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]];
		
		NSLog( [predicate description]);
		
		[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
		[request setPredicate: predicate];
		
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
		
		if( checkAndViewTry-- > 0 && [sendToPopup indexOfSelectedItem] == 0)
			[self performSelector:@selector( checkAndView:) withObject:item afterDelay:1.0];
		else
			success = YES;
	}
	
	if( success)
	{
		[item release];
	}
	
	[context unlock];
	[context release];
}

- (IBAction) view:(id) sender
{
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	{
		checkAndViewTry = 20;
		if( item) [self checkAndView: [item retain]];
	}
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

-(void) awakeFromNib
{
	[numberOfStudies setStringValue: @""];
	
	[[self window] setFrameAutosaveName:@"QueryRetrieveWindow"];
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldAN cell];
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
	
	NSString *sdf = [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat"];
	NSDateFormatter *dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
	[[[outlineView tableColumnWithIdentifier: @"birthdate"] dataCell] setFormatter: dateFomat];
	
	[sourcesTable setDoubleAction: @selector( selectUniqueSource:)];
	
	[self refreshSources];
	
	int i;
	for( i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
		{
			[sourcesTable selectRow: i byExtendingSelection: NO];
			[sourcesTable scrollRowToVisible: i];
			break;
		}
	}
}

//******

- (IBAction) selectUniqueSource:(id) sender
{
	[self willChangeValueForKey:@"sourcesArray"];
	
	int i;
	for( i = 0; i < [sourcesArray count]; i++)
	{
		NSMutableDictionary		*source = [NSMutableDictionary dictionaryWithDictionary: [sourcesArray objectAtIndex: i]];
		
		if( [sender selectedRow] == i) [source setObject: [NSNumber numberWithBool:YES] forKey:@"activated"];
		else [source setObject: [NSNumber numberWithBool:NO] forKey:@"activated"];
		
		[sourcesArray	replaceObjectAtIndex: i withObject:source];
	}
	
	[self didChangeValueForKey:@"sourcesArray"];
}

- (NSDictionary*) findCorrespondingServer: (NSDictionary*) savedServer inServers : (NSArray*) servers
{
	int i;
	
	for( i = 0 ; i < [servers count]; i++)
	{
		if( [[savedServer objectForKey:@"AETitle"] isEqualToString: [[servers objectAtIndex:i] objectForKey:@"AETitle"]] && 
			[[savedServer objectForKey:@"AddressAndPort"] isEqualToString: [NSString stringWithFormat:@"%@:%@", [[servers objectAtIndex:i] valueForKey:@"Address"], [[servers objectAtIndex:i] valueForKey:@"Port"]]])
			{
				return [servers objectAtIndex:i];
			}
	}
	
	return 0L;
}

- (void) refreshSources
{
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];
	
	NSMutableArray		*serversArray		= [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
	NSArray				*savedArray			= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SavedQueryArray"];
	
	[self willChangeValueForKey:@"sourcesArray"];
	 
	[sourcesArray removeAllObjects];
	
	int i;
	for( i = 0; i < [savedArray count]; i++)
	{
		NSDictionary *server = [self findCorrespondingServer: [savedArray objectAtIndex:i] inServers: serversArray];
		
		if( server && ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == 0L ))
		{
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[[savedArray objectAtIndex: i] valueForKey:@"activated"], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", 0L]];
			
			[serversArray removeObject: server];
		}
	}
	
	for( i = 0; i < [serversArray count]; i++)
	{
		NSDictionary *server = [serversArray objectAtIndex: i];
		
		NSLog( [server description]);
		
		if( ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == 0L ))
		
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", 0L]];
	}
	
	[sourcesTable reloadData];
	
	[self didChangeValueForKey:@"sourcesArray"];
	
	// *********** Update Send To popup menu
	
	NSString	*previousItem = [[[sendToPopup selectedItem] title] retain];
	
	[sendToPopup removeAllItems];
	
	serversArray = [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
	
	NSString *ip = [NSString stringWithCString:GetPrivateIP()];
	[sendToPopup addItemWithTitle: [NSString stringWithFormat: NSLocalizedString( @"This Computer - %@/%@:%@", 0L), [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], ip, [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]]];

	[[sendToPopup menu] addItem: [NSMenuItem separatorItem]];
	
	for( i = 0; i < [serversArray count]; i++)
	{
		NSDictionary *server = [serversArray objectAtIndex: i];
		
		[sendToPopup addItemWithTitle: [NSString stringWithFormat:@"%@ - %@/%@:%@", [server valueForKey:@"Description"], [server valueForKey:@"AETitle"], [server valueForKey:@"Address"], [server valueForKey:@"Port"]]];
		
		if( [[[sendToPopup lastItem] title] isEqualToString: previousItem]) [sendToPopup selectItemWithTitle: previousItem];
	}
	
	[previousItem release];
}

-(id) init
{
    if ( self = [super initWithWindowNibName:@"Query"])
	{
		if( [[DCMNetServiceDelegate DICOMServersList] count] == 0)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Query & Retrieve",nil),NSLocalizedString( @"No DICOM locations available. See Preferences to add DICOM locations.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
		
		queryFilters = 0L;
		dateQueryFilter = 0L;
		modalityQueryFilter = 0L;
		currentQueryKey = 0L;
		echoSuccess = 0L;
		activeMoves = 0L;
		
		Realised2 = [[NSImage imageNamed:@"Realised2.tif"] retain];
		Realised3 = [[NSImage imageNamed:@"Realised3.tif"] retain];
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		queryFilters = [[NSMutableArray array] retain];
		resultArray = [[NSMutableArray array] retain];
		activeMoves = [[NSMutableDictionary dictionary] retain];
		
		sourcesArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"SavedQueryArray"] mutableCopy];
		if( sourcesArray == 0L) sourcesArray = [[NSMutableArray array] retain];
		
		[self refreshSources];
				
		[[self window] setDelegate:self];
		
		currentQueryController = self;
	}
    
    return self;
}

- (void)finalize {
	[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys];
	[super finalize];
}

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];

	NSLog( @"dealloc QueryController");
	[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys];
	[pressedKeys release];
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	[queryManager release];
	[queryFilters release];
	[dateQueryFilter release];
	[modalityQueryFilter release];
	[activeMoves release];
	[sourcesArray release];
	[resultArray release];
	[Realised2 release];
	[Realised3 release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
	
	currentQueryController = 0L;
}

- (void)windowDidLoad
{
	id searchCell = [searchFieldName cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];

	searchCell = [searchFieldAN cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];

	searchCell = [searchFieldID cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
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

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];
	
	[[self window] orderOut: self];
}

- (int) dicomEcho:(NSDictionary*) aServer
{
	int status = 0;
	
	id echoSCU;
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
	NSMutableArray *objects;
	NSMutableArray *keys; 
	
	theirAET = [aServer objectForKey:@"AETitle"];
	hostname = [aServer objectForKey:@"Address"];
	port = [aServer objectForKey:@"Port"];
	
	int numberPacketsReceived = 0;
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || (SimplePing( [hostname UTF8String], 1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"], 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0))
	{
		status = [QueryController echo: hostname port: [port intValue] AET: theirAET];
	}
	else status = -1;
	
	return status;
}

- (void)updateServers:(NSNotification *)note
{
	[self refreshSources];
}

- (IBAction)verify:(id)sender
{
	id				aServer;
	NSString		*message;	
	int				i;
	int				status, selectedRow = [sourcesTable selectedRow];
	
	[progressIndicator startAnimation:nil];
	
	[self willChangeValueForKey:@"sourcesArray"];
	
	for( i = 0 ; i < [sourcesArray count]; i++)
	{
		[sourcesTable selectRow: i byExtendingSelection: NO];
		[sourcesTable scrollRowToVisible: i];
		
		NSMutableDictionary *aServer = [sourcesArray objectAtIndex: i];
		
		int numberPacketsReceived = 0;
		
		switch( [self dicomEcho: [aServer objectForKey:@"server"]])
		{
			case 1:		status = 0;			break;
			case 0:		status = -1;		break;
			case -1:	status = -2;		break;
		}
		
		[aServer setObject:[NSNumber numberWithInt: status] forKey:@"test"];
	}
	
	[sourcesTable selectRow: selectedRow byExtendingSelection: NO];
	
	[self didChangeValueForKey:@"sourcesArray"];
	
	[progressIndicator stopAnimation:nil];
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

- (IBAction) pressButtons:(id) sender
{
	switch( [sender selectedSegment])
	{
		case 0:		// Query
			[self query: sender];
		break;
		
		case 1:		// Retrieve
			[self retrieve: sender];
		break;
		
		case 2:		// Verify
			[self verify: sender];
		break;
	}
}
@end
