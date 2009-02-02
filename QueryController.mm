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
#import "AppController.h"
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

#import "PieChartImage.h"

static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *AccessionNumber = @"AccessionNumber";
static NSString *StudyDescription = @"StudyDescription";
static NSString *PatientBirthDate = @"PatientBirthDate";

static QueryController	*currentQueryController = nil;

static const char *GetPrivateIP()
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

+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer
{
	QueryArrayController *qm = nil;
	NSArray *array = nil;
	
	@try
	{
		NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 			
		NSString *theirAET = [aServer objectForKey:@"AETitle"];
		NSString *hostname = [aServer objectForKey:@"Address"];
		NSString *port = [aServer objectForKey:@"Port"];
		
		qm = [[[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:nil] autorelease];
		
		NSString *filterValue = [an stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([filterValue length] > 0)
		{
			[qm addFilter:filterValue forDescription:@"StudyInstanceUID"];
			[qm performQuery];
			array = [qm queries];
		}
		
		for( id a in array)
		{
			if( [a isMemberOfClass:[DCMTKStudyQueryNode class]] == NO)
				NSLog( @"warning : [item isMemberOfClass:[DCMTKStudyQueryNode class]] == NO");
		}
	}
	@catch (NSException * e)
	{
		NSLog( [e description]);
	}
	
	return array;
}

+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer
{
	QueryArrayController *qm = nil;
	int error = 0;
	
	@try
	{
		NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 			
		NSString *theirAET = [aServer objectForKey:@"AETitle"];
		NSString *hostname = [aServer objectForKey:@"Address"];
		NSString *port = [aServer objectForKey:@"Port"];

		qm = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:nil];
		
		NSString *filterValue = [an stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([filterValue length] > 0)
		{
			[qm addFilter:filterValue forDescription:@"AccessionNumber"];
			
			[qm performQuery];
			
			NSArray *array = [qm queries];
			
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary: [qm parameters]];
			NetworkMoveDataHandler *moveDataHandler = [NetworkMoveDataHandler moveDataHandler];
			[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
			
			for( DCMTKQueryNode	*object in array)
			{
				[dictionary setObject: [object valueForKey:@"calledAET"] forKey:@"calledAET"];
				[dictionary setObject: [object valueForKey:@"hostname"] forKey:@"hostname"];
				[dictionary setObject: [object valueForKey:@"port"] forKey:@"port"];
				[dictionary setObject: [object valueForKey:@"transferSyntax"] forKey:@"transferSyntax"];
				
				[object move: dictionary];
			}
			
			if( [array count] == 0) error = -3;
		}
	}
	@catch (NSException * e)
	{
		NSLog( [e description]);
		error = -2;
	}
	
	[qm release];
	
	return error;
}

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

	NSArray *args = [NSArray arrayWithObjects: address, [NSString stringWithFormat:@"%d", port], @"-aet", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"-aec", aet, @"-to", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-ta", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-td", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], nil];
	
	[theTask setArguments:args];
	[theTask launch];
	[theTask waitUntilExit];
	
	if( [theTask terminationStatus] == 0) return YES;
	else return NO;
}

- (IBAction) cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction) ok:sender
{
	[NSApp stopModal];
}

- (IBAction) switchAutoRetrieving: (id) sender
{
	NSLog( @"auto-retrieving switched");
	
	@synchronized( previousAutoRetrieve)
	{
		[previousAutoRetrieve removeAllObjects];
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"autoRetrieving"])
	{
//		BOOL doit = NO;
//		NSString *alertSuppress = @"auto retrieving warning";
//		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//		if ([defaults boolForKey: alertSuppress])
//		{
//			doit = YES;
//		}
//		else
//		{
//			NSAlert* alert = [NSAlert new];
//			[alert setMessageText: NSLocalizedString(@"Auto-Retrieving", nil)];
//			[alert setInformativeText: NSLocalizedString(@"Are you sure that you want to activate the Auto-Retrieving function : each study displayed in the Query & Retrieve list will be automatically retrieved to destination computer.\r\r(Only 10 studies is retrieved each time. Next 10 studies during next 'refresh'.)", nil)];
//			[alert setShowsSuppressionButton:YES ];
//			[alert addButtonWithTitle: NSLocalizedString(@"Yes", nil)];
//			[alert addButtonWithTitle: NSLocalizedString(@"Cancel", nil)];
//			
//			if ( [alert runModal] == NSAlertFirstButtonReturn) doit = YES;
//			
//			if ([[alert suppressionButton] state] == NSOnState)
//			{
//				[defaults setBool:YES forKey:alertSuppress];
//			}
//		}
		
		[NSApp beginSheet:	autoRetrieveWindow
			modalForWindow: self.window
			modalDelegate: nil
			didEndSelector: nil
			contextInfo: nil];
		
		int result = [NSApp runModalForWindow: autoRetrieveWindow];
		[autoRetrieveWindow orderOut: self];
		
		[NSApp endSheet: autoRetrieveWindow];
		
		if( result == NSRunStoppedResponse)
		{
			if( [autoQueryLock tryLock])
			{
				[self autoQueryThread];
				[autoQueryLock unlock];
			}
		}
		else [[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"autoRetrieving"];
	}
}

- (IBAction) endAddPreset:(id) sender
{
	if( [sender tag])
	{
		if( [[presetName stringValue] isEqualToString: @""])
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Add Preset", nil),  NSLocalizedString(@"Give a name !", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return;
		}
		
		NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
		
		if( savedPresets == nil) savedPresets = [NSDictionary dictionary];
		
		NSMutableDictionary *presets = [NSMutableDictionary dictionary];
		
		NSString *psName = [presetName stringValue];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"includeDICOMNodes"])
		{
			NSMutableArray *srcArray = [NSMutableArray array];
			for( id src in sourcesArray)
			{
				if( [[src valueForKey: @"activated"] boolValue] == YES)
					[srcArray addObject: [src valueForKey: @"AddressAndPort"]];
			}
			
			if( [srcArray count] == 0 && [sourcesTable selectedRow] >= 0)
				[srcArray addObject: [[sourcesArray objectAtIndex: [sourcesTable selectedRow]] valueForKey: @"AddressAndPort"]];
			
			[presets setValue: srcArray forKey: @"DICOMNodes"];
			
			psName = [psName stringByAppendingString: NSLocalizedString( @" & DICOM Nodes", nil)];
		}
		
		if( [savedPresets objectForKey: psName])
		{
			if (NSRunCriticalAlertPanel( NSLocalizedString(@"Add Preset", nil),  NSLocalizedString(@"A Preset with the same name already exists. Should I replace it with the current one?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) != NSAlertDefaultReturn) return;
		}
		
		[presets setValue: [searchFieldName stringValue] forKey: @"searchFieldName"];
		[presets setValue: [searchFieldID stringValue] forKey: @"searchFieldID"];
		[presets setValue: [searchFieldAN stringValue] forKey: @"searchFieldAN"];
		[presets setValue: [searchFieldStudyDescription stringValue] forKey: @"searchFieldStudyDescription"];
		
		[presets setValue: [NSNumber numberWithInt: [dateFilterMatrix selectedTag]] forKey: @"dateFilterMatrix"];
		
		NSMutableString *cellsString = [NSMutableString string];
		for( NSCell *cell in [modalityFilterMatrix cells])
		{
			if( [cell state] == NSOnState)
			{
				NSInteger row, col;
				
				[modalityFilterMatrix getRow: &row column: &col ofCell:cell];
				[cellsString appendString: [NSString stringWithFormat:@"%d %d ", row, col]];
			}
		}
		[presets setValue: cellsString forKey: @"modalityFilterMatrixString"];
		
		[presets setValue: [NSNumber numberWithInt: [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]]] forKey: @"PatientModeMatrix"];
		
		[presets setValue: [NSNumber numberWithDouble: [[fromDate dateValue] timeIntervalSinceReferenceDate]] forKey: @"fromDate"];
		[presets setValue: [NSNumber numberWithDouble: [[toDate dateValue] timeIntervalSinceReferenceDate]] forKey: @"toDate"];
		[presets setValue: [NSNumber numberWithDouble: [[searchBirth dateValue] timeIntervalSinceReferenceDate]] forKey: @"searchBirth"];
		
		NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary: savedPresets];
		[m setValue: presets forKey: psName];
		
		[[NSUserDefaults standardUserDefaults] setObject: m forKey:@"QRPresets"];
		
		[self buildPresetsMenu];
	}

	[presetWindow orderOut:sender];
    [NSApp endSheet:presetWindow returnCode:[sender tag]];
}

- (void) addPreset:(id) sender
{
	[NSApp beginSheet: presetWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) emptyPreset:(id) sender
{
	[searchFieldName setStringValue: @""];
	[searchFieldID setStringValue: @""];
	[searchFieldAN setStringValue: @""];
	[searchFieldStudyDescription setStringValue: @""];
	[dateFilterMatrix selectCellWithTag: 0];
	[modalityFilterMatrix deselectAllCells];
	[PatientModeMatrix selectTabViewItemAtIndex: 0];
}

- (void) applyPreset:(id) sender
{
	if([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
	{
		// Delete the Preset
		if (NSRunCriticalAlertPanel( NSLocalizedString(@"Delete Preset", nil),  NSLocalizedString(@"Are you sure you want to delete the selected Preset?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
		{
			NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
			
			NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary: savedPresets];
			[m removeObjectForKey: [sender title]];
			
			[[NSUserDefaults standardUserDefaults] setObject: m forKey:@"QRPresets"];
			
			[self buildPresetsMenu];
		}
	}
	else
	{
		NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
		
		if( [savedPresets objectForKey: [sender title]])
		{
			NSDictionary *presets = [savedPresets objectForKey: [sender title]];
			
			if( [presets valueForKey: @"DICOMNodes"])
			{
				NSArray *r = [presets valueForKey: @"DICOMNodes"];
				
				if( [r count])
				{
					[self willChangeValueForKey:@"sourcesArray"];
					
					for( id src in sourcesArray)
					{
						[src setValue: [NSNumber numberWithBool: NO] forKey: @"activated"];
					}
					
					if( [r count] == 1)
					{
						for( id src in sourcesArray)
						{
							if( [[src valueForKey: @"AddressAndPort"] isEqualToString: [r lastObject]])
							{
								[sourcesTable selectRow: [sourcesArray indexOfObject: src] byExtendingSelection: NO];
								[sourcesTable scrollRowToVisible: [sourcesArray indexOfObject: src]];
							}
						}
					}
					else
					{
						BOOL first = YES;
						
						for( id v in r)
						{
							for( id src in sourcesArray)
							{
								if( [[src valueForKey: @"AddressAndPort"] isEqualToString: v])
								{
									[src setValue: [NSNumber numberWithBool: YES] forKey: @"activated"];
									
									if( first)
									{
										first = NO;
										[sourcesTable selectRow: [sourcesArray indexOfObject: src] byExtendingSelection: NO];
										[sourcesTable scrollRowToVisible: [sourcesArray indexOfObject: src]];
									}
								}
							}
						}
					}
					
					[self didChangeValueForKey:@"sourcesArray"];
				}
			}
			
			if( [presets valueForKey: @"searchFieldName"])
				[searchFieldName setStringValue: [presets valueForKey: @"searchFieldName"]];
			
			if( [presets valueForKey: @"searchFieldID"])
				[searchFieldID setStringValue: [presets valueForKey: @"searchFieldID"]];
			
			if( [presets valueForKey: @"searchFieldAN"])
				[searchFieldAN setStringValue: [presets valueForKey: @"searchFieldAN"]];
			
			if( [presets valueForKey: @"searchFieldStudyDescription"])
				[searchFieldStudyDescription setStringValue: [presets valueForKey: @"searchFieldStudyDescription"]];
			
			[dateFilterMatrix selectCellWithTag: [[presets valueForKey: @"dateFilterMatrix"] intValue]];
			
			[modalityFilterMatrix deselectAllCells];
			
			if( [presets valueForKey: @"modalityFilterMatrixRow"] && [presets valueForKey: @"modalityFilterMatrixColumn"])
				[modalityFilterMatrix selectCellAtRow: [[presets valueForKey: @"modalityFilterMatrixRow"] intValue]  column:[[presets valueForKey: @"modalityFilterMatrixColumn"] intValue]];
			else
			{
				NSString *s = [presets valueForKey: @"modalityFilterMatrixString"];
				
				NSScanner *scan = [NSScanner scannerWithString: s];
				
				BOOL more;
				do
				{
					NSInteger row, col;
					
					more = [scan scanInteger: &row];
					more = [scan scanInteger: &col];
					
					if( more)
						[modalityFilterMatrix selectCellAtRow: row column: col];
					
				}while( more);
			}
			
			[PatientModeMatrix selectTabViewItemAtIndex: [[presets valueForKey: @"PatientModeMatrix"] intValue]];
			
			[fromDate setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[presets valueForKey: @"fromDate"] doubleValue]]];
			[toDate setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[presets valueForKey: @"toDate"] doubleValue]]];
			[searchBirth setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[presets valueForKey: @"searchBirth"] doubleValue]]];
			
			switch( [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]])
			{
				case 0:		[searchFieldName selectText: self];				break;
				case 1:		[searchFieldID selectText: self];				break;
				case 2:		[searchFieldAN selectText: self];				break;
				case 3:		[searchFieldName selectText: self];				break;
				case 4:		[searchFieldStudyDescription selectText: self];	break;
			}
		}
	}
}

- (void) buildPresetsMenu
{
	[presetsPopup removeAllItems];
	NSMenu *menu = [presetsPopup menu];
	
	[menu setAutoenablesItems: NO];
	
	[menu addItemWithTitle: @"" action:nil keyEquivalent: @""];
	
	NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
	
	[menu addItemWithTitle: NSLocalizedString( @"Empty Preset", nil) action:@selector( emptyPreset:) keyEquivalent:@""];
	[menu addItem: [NSMenuItem separatorItem]];
	
	if( [savedPresets count] == 0)
	{
		[[menu addItemWithTitle: NSLocalizedString( @"No Presets Saved", nil) action:nil keyEquivalent: @""] setEnabled: NO];
	}
	else
	{
		for( NSString *key in [[savedPresets allKeys] sortedArrayUsingSelector: @selector( compare:)])
		{
			[menu addItemWithTitle: key action:@selector( applyPreset:) keyEquivalent: @""];
		}
	}
	
	[menu addItem: [NSMenuItem separatorItem]];
	[menu addItemWithTitle: NSLocalizedString( @"Add current settings as a new Preset", nil) action:@selector( addPreset:) keyEquivalent:@""];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	BOOL valid = NO;
	
    if ([item action] == @selector( deleteSelection:))
	{
		[[BrowserController currentBrowser] showEntireDatabase];
	
		NSIndexSet* indices = [outlineView selectedRowIndexes];
		
		for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
		{
			if( [indices containsIndex: i])
			{
				NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i]];

				if( [studyArray count] > 0)
				{
					valid = YES;
				}
			}
		}
    }
	else valid = YES;
	
    return valid;
}

-(void) deleteSelection:(id) sender
{
	[[BrowserController currentBrowser] showEntireDatabase];
	
	NSIndexSet* indices = [outlineView selectedRowIndexes];
	BOOL extendingSelection = NO;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
	{
		if( [indices containsIndex: i])
		{
			NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i]];

			if( [studyArray count] > 0)
			{
				NSManagedObject	*series =  [[[BrowserController currentBrowser] childrenArray: [studyArray objectAtIndex: 0]] objectAtIndex:0];
				[[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO extendingSelection: extendingSelection];
				extendingSelection = YES;
			}
		} 
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	if( extendingSelection)
	{
		[[BrowserController currentBrowser] delItem: self];
	}
}

- (void)keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
	
	if( [[self window] firstResponder] == outlineView)
	{
		if( c == NSDeleteCharacter)
		{
			[self deleteSelection: self];
		}
		else if( c == ' ')
		{
			[self retrieve: self onlyIfNotAvailable: YES];
		}
		else if( c == NSNewlineCharacter || c == NSEnterCharacter || c == NSCarriageReturnCharacter)
		{
			[self retrieveAndView: self];
		}
		else
		{
			[pressedKeys appendString: [event characters]];
			
			NSLog(@"%@", pressedKeys);
			
			NSArray		*resultFilter = [resultArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", pressedKeys]];
			
			[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys selector:@selector(setString:) object:@""];
			[pressedKeys performSelector:@selector(setString:) withObject:@"" afterDelay:0.5];
			
			if( [resultFilter count])
			{
				[outlineView selectRow: [outlineView rowForItem: [resultFilter objectAtIndex: 0]] byExtendingSelection: NO];
				[outlineView scrollRowToVisible: [outlineView selectedRow]];
			}
			else NSBeep();
		}
	}
}

- (void) refresh: (id) sender
{	
	if( DatabaseIsEdited == NO)
	{
		[studyArrayInstanceUID release];
		studyArrayInstanceUID = nil;
		[outlineView reloadData];
	}
}

- (void) refreshAutoQR: (id) sender
{
	autoQueryRemainingSecs = 1;
	[self autoQueryTimerFunction: QueryTimer]; 
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{

	return (item == nil) ? [resultArray objectAtIndex:index] : [[(DCMTKQueryNode *)item children] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [[tableColumn identifier] isEqualToString:@"comment"])
	{
		DatabaseIsEdited = YES;
		return YES;
	}
	else
	{
		DatabaseIsEdited = NO;
		return NO;
	}
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

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
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

- (NSArray*) localSeries:(id) item
{
	NSArray *seriesArray = nil;
	NSManagedObject *study = [[self localStudy: [outlineView parentForItem: item]] lastObject];
	
	if( study == nil) return seriesArray;
	
	if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
	{
		NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
		
		[context lock];
		
		@try
		{
			seriesArray = [[[study valueForKey:@"series"] allObjects] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]]];
		}
		@catch (NSException * e)
		{
			NSLog( @"**** localSeries exception: %@", [e description]);
		}
		
		[context unlock];
	}
	else
		NSLog( @"Warning! Not a series class !");
	
	return seriesArray;
}

- (void) computeStudyArrayInstanceUID
{
	if( lastComputeStudyArrayInstanceUID == 0 || studyArrayInstanceUID == 0 || [NSDate timeIntervalSinceReferenceDate] - lastComputeStudyArrayInstanceUID > 1)
	{
		NSError						*error = nil;
		NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
		NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
		NSPredicate					*predicate = [NSPredicate predicateWithValue: YES];
		
		[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[request setPredicate: predicate];
		
		[context retain];
		[context lock];
		
		@try
		{
			[studyArrayInstanceUID release];
			[studyArrayCache release];
			
			studyArrayCache = [[context executeFetchRequest:request error:&error] retain];
			studyArrayInstanceUID = [[studyArrayCache valueForKey:@"studyInstanceUID"] retain];
		}
		@catch (NSException * e)
		{
			NSLog( @"**** computeStudyArrayInstanceUID exception: %@", [e description]);
		}
		
		[context unlock];
		[context release];
		
		NSLog( @"computeStudyArrayInstanceUID");
		
		lastComputeStudyArrayInstanceUID = [NSDate timeIntervalSinceReferenceDate];
	}
}

- (NSArray*) localStudy:(id) item
{
	if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
	{
		@try
		{
			if( studyArrayInstanceUID == nil) [self computeStudyArrayInstanceUID];
			
			NSUInteger index = [studyArrayInstanceUID indexOfObject:[item valueForKey: @"uid"]];
			
			if( index == NSNotFound) return [NSArray array];
			else return [NSArray arrayWithObject: [studyArrayCache objectAtIndex: index]];
		}
		@catch (NSException * e)
		{
			[studyArrayInstanceUID release];
			studyArrayInstanceUID = nil;
			return nil;
		}
	}
	else NSLog( @"Warning! Not a study class !");
	
	return nil;
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation;
{
	if( [[tableColumn identifier] isEqualToString: @"name"])
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
			NSArray *studyArray;
			
			studyArray = [self localStudy: item];
			
			if( [studyArray count] > 0)
			{
				float localFiles = [[[studyArray objectAtIndex: 0] valueForKey: @"noFiles"] floatValue];
				float totalFiles = [[item valueForKey:@"numberImages"] floatValue];
				float percentage = 0;
				
				if( totalFiles != 0.0)
					percentage = localFiles / totalFiles;
				if( percentage > 1.0) percentage = 1.0;
				
				return [NSString stringWithFormat:@"%@\n%d%% (%d/%d)", [cell title], (int)(percentage*100), (int)localFiles, (int)totalFiles];
			}
		}
		
		if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
		{
			NSArray *seriesArray;
			
			seriesArray = [self localSeries: item];
			
			if( [seriesArray count] > 0)
			{
				float localFiles = [[[seriesArray objectAtIndex: 0] valueForKey: @"noFiles"] floatValue];
				float totalFiles = [[item valueForKey:@"numberImages"] floatValue];
				float percentage = 0;
				
				if( totalFiles != 0.0)
					percentage = localFiles / totalFiles;
					
				if(percentage > 1.0) percentage = 1.0;
				
				return [NSString stringWithFormat:@"%@\n%d%% (%d/%d)", [cell title], (int)(percentage*100), (int)localFiles, (int)totalFiles];
			}
		}
	}
	return @"";
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	DCMTKStudyQueryNode *item = [[notification userInfo] valueForKey: @"NSObject"];
	
	if( [item children])
	{
		[item purgeChildren];
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [[tableColumn identifier] isEqualToString: @"name"])	// Is this study already available in our local database? If yes, display it in italic
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
			NSArray	*studyArray;
			
			studyArray = [self localStudy: item];
			
			if( [studyArray count] > 0)
			{
				float percentage = 0;
				
				if( [[item valueForKey:@"numberImages"] floatValue] != 0.0)
					percentage = [[[studyArray objectAtIndex: 0] valueForKey: @"noFiles"] floatValue] / [[item valueForKey:@"numberImages"] floatValue];
					
				if(percentage > 1.0) percentage = 1.0;

				[(ImageAndTextCell *)cell setImage:[NSImage pieChartImageWithPercentage:percentage]];
			}
			else [(ImageAndTextCell *)cell setImage: nil];
		}
		else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
		{
			NSArray	*seriesArray;
			
			seriesArray = [self localSeries: item];
			
			if( [seriesArray count] > 0)
			{
				float percentage = 0;
				
				if( [[item valueForKey:@"numberImages"] floatValue] != 0.0)
					percentage = [[[seriesArray objectAtIndex: 0] valueForKey: @"noFiles"] floatValue] / [[item valueForKey:@"numberImages"] floatValue];
					
				if(percentage > 1.0) percentage = 1.0;
				
				[(ImageAndTextCell *)cell setImage:[NSImage pieChartImageWithPercentage:percentage]];
			}
			else [(ImageAndTextCell *)cell setImage: nil];
		}
		else [(ImageAndTextCell *)cell setImage: nil];
		
		[cell setFont: [NSFont boldSystemFontOfSize:13]];
		[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
	}
	else if( [[tableColumn identifier] isEqualToString: @"numberImages"])
	{
		if( [item valueForKey:@"numberImages"]) [cell setIntegerValue: [[item valueForKey:@"numberImages"] intValue]];
		else [cell setStringValue:@"n/a"];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if( [[tableColumn identifier] isEqualToString: @"stateText"])
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
			NSArray *studyArray = [self localStudy: item];
			
			if( [studyArray count] > 0)
			{
				if( [[[studyArray objectAtIndex: 0] valueForKey:@"stateText"] intValue] == 0)
					return nil;
				else
					return [[studyArray objectAtIndex: 0] valueForKey: @"stateText"];
			}
		}
		else
		{
			NSArray *seriesArray = [self localSeries: item];
			if( [seriesArray count])
			{
				if( [[[seriesArray objectAtIndex: 0] valueForKey:@"stateText"] intValue] == 0)
					return nil;
				else
					return [[seriesArray objectAtIndex: 0] valueForKey: @"stateText"];
			}
		}
	}
	else if( [[tableColumn identifier] isEqualToString: @"comment"])
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
			NSArray *studyArray = [self localStudy: item];
			
			if( [studyArray count] > 0)
				return [[studyArray objectAtIndex: 0] valueForKey: @"comment"];
		}
		else
		{
			NSArray *seriesArray = [self localSeries: item];
			if( [seriesArray count])
				return [[seriesArray objectAtIndex: 0] valueForKey: @"comment"];
		}
	}
	else if ( [[tableColumn identifier] isEqualToString: @"Button"] == NO && [tableColumn identifier] != nil)
	{
		if( [[tableColumn identifier] isEqualToString: @"numberImages"])
		{
			return [NSNumber numberWithInt: [[item valueForKey: [tableColumn identifier]] intValue]];
		}
		else return [item valueForKey: [tableColumn identifier]];		
	}
	return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSArray *array;
	
	if( [[tableColumn identifier] isEqualToString: @"comment"] || [[tableColumn identifier] isEqualToString: @"stateText"])
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
			array = [self localStudy: item];
		else
			array = [self localSeries: item];
		
		if( [array count] > 0)
		{
			[[BrowserController currentBrowser] setDatabaseValue: object item: [array objectAtIndex: 0] forKey: [tableColumn identifier]];
		}
		else NSRunCriticalAlertPanel( NSLocalizedString(@"Study not available", nil), NSLocalizedString(@"The study is not available in the local Database, you cannot modify or set the comments/status fields.", nil), NSLocalizedString(@"OK", nil), nil, nil) ;
	}
	
	DatabaseIsEdited = NO;
}

- (NSArray*) sortArray
{
	NSArray *s = [outlineView sortDescriptors];
	
	if( [s count])
	{
		if( [[[s objectAtIndex: 0] key] isEqualToString:@"date"])
		{
			NSMutableArray *sortArray = [NSMutableArray arrayWithObject: [s objectAtIndex: 0]];
			
			[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"time" ascending: [[s objectAtIndex: 0] ascending]] autorelease]];
			
			if( [s count] > 1)
			{
				NSMutableArray *lastObjects = [NSMutableArray arrayWithArray: s];
				[lastObjects removeObjectAtIndex: 0];
				[sortArray addObjectsFromArray: lastObjects];
			}
			
			return sortArray;
		}
	}
	
	return s;
}

- (void)outlineView:(NSOutlineView *)aOutlineView sortDescriptorsDidChange:(NSArray *)oldDescs
{
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	[resultArray sortUsingDescriptors: [self sortArray]];
	[self refresh: self];
	
	NSArray *s = [outlineView sortDescriptors];
	
	if( [s count])
	{
		if( [[[s objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
		{
			[outlineView selectRow: 0 byExtendingSelection: NO];
		}
		else [outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: item]] byExtendingSelection: NO];
	}
	else [outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: item]] byExtendingSelection: NO];
	
	[outlineView scrollRowToVisible: [outlineView selectedRow]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet *index = [outlineView selectedRowIndexes];
	id item = [outlineView itemAtRow:[index firstIndex]];
	
	if( item)
	{
		[selectedResultSource setStringValue: [NSString stringWithFormat:@"%@  /  %@:%d", [item valueForKey:@"calledAET"], [item valueForKey:@"hostname"], [[item valueForKey:@"port"] intValue]]];
	}
	else [selectedResultSource setStringValue:@""];
}

- (IBAction) selectModality: (id) sender;
{
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	
	if( [event modifierFlags] & NSCommandKeyMask)
	{
		for( NSCell *c in [modalityFilterMatrix cells])
		{
			if( [sender selectedCell] != c)
				[c setState: NSOffState];
		}
	}
}

- (NSArray*) queryPatientID:(NSString*) ID
{
	NSInteger PatientModeMatrixSelected = [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]];
	NSInteger dateFilterMatrixSelected = [dateFilterMatrix selectedTag];
	NSMutableArray *selectedModalities = [NSMutableArray array];
	for( NSCell *c in [modalityFilterMatrix cells]) if( [c state] == NSOnState) [selectedModalities addObject: c];
	NSString *copySearchField = [NSString stringWithString: [searchFieldID stringValue]];
	
	[PatientModeMatrix selectTabViewItemAtIndex: 1];	// PatientID search
	
	[dateFilterMatrix selectCellWithTag: 0];
	[self setDateQuery: dateFilterMatrix];
	[modalityFilterMatrix deselectAllCells];
	[self setModalityQuery: modalityFilterMatrix];
	[searchFieldID setStringValue: ID];
	
	[self query: self];
	
	NSArray *result = [NSArray arrayWithArray: resultArray];
	
	[PatientModeMatrix selectTabViewItemAtIndex: PatientModeMatrixSelected];
	[dateFilterMatrix selectCellWithTag: dateFilterMatrixSelected];
	for( NSCell *c in selectedModalities) [modalityFilterMatrix selectCell: c];
	[searchFieldID setStringValue: copySearchField];
	
	return result;
}

- (void) querySelectedStudy: (id) sender
{
	id   item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	if( item && [item isMemberOfClass:[DCMTKStudyQueryNode class]])
	{
		[self queryPatientID: [item valueForKey:@"patientID"]];
	}
	else NSRunCriticalAlertPanel( NSLocalizedString(@"No Study Selected", nil), NSLocalizedString(@"Select a study to query all studies of this patient.", nil), NSLocalizedString(@"OK", nil), nil, nil) ;
}

- (BOOL) array: uidArray containsObject: (NSString*) uid
{
	BOOL result = NO;
	
	for( NSUInteger x = 0 ; x < [uidArray count]; x++)
	{
		if( [[uidArray objectAtIndex: x] isEqualToString: uid]) return YES;
	}
	
	return result;
}

- (NSArray*) queryPatientIDwithoutGUI: (NSString*) patientID
{
	NSString			*theirAET;
	NSString			*hostname;
	NSString			*port;
	NSNetService		*netService = nil;
	id					aServer;
	int					selectedServer;
	BOOL				atLeastOneSource = NO, noChecked = YES, error = NO;
	NSArray				*copiedSources = [NSArray arrayWithArray: sourcesArray];
	
	noChecked = YES;
	for( NSUInteger i = 0; i < [copiedSources count]; i++)
	{
		if( [[[copiedSources objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
			noChecked = NO;
	}
	
	selectedServer = -1;
	if( noChecked)
		selectedServer = [sourcesTable selectedRow];
	
	atLeastOneSource = NO;
	BOOL firstResults = YES;
	
	NSString *filterValue = [patientID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSMutableArray *result = [NSMutableArray array];
	
	if ([filterValue length] > 0)
	{
		for( NSUInteger i = 0; i < [copiedSources count]; i++)
		{
			if( [[[copiedSources objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES || selectedServer == i)
			{
				aServer = [[copiedSources objectAtIndex:i] valueForKey:@"server"];
				
				NSString *myAET = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]; 			
				theirAET = [aServer objectForKey:@"AETitle"];
				hostname = [aServer objectForKey:@"Address"];
				port = [aServer objectForKey:@"Port"];
				
				int numberPacketsReceived = 0;
				if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || (SimplePing( [hostname UTF8String], 1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"], 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0))
				{
					QueryArrayController *qm = [[QueryArrayController alloc] initWithCallingAET:myAET calledAET:theirAET  hostName:hostname port:port netService:netService];
					
					[qm addFilter:filterValue forDescription: PatientID];
					
					[qm performQuery];
					
					[result addObjectsFromArray: [qm queries]];
					
					[qm release];
				}
			}
		}
	}
	
	return result;
}

-(BOOL) queryWithDisplayingErrors:(BOOL) showError
{
	NSString			*theirAET;
	NSString			*hostname;
	NSString			*port;
	NSNetService		*netService = nil;
	id					aServer;
	int					selectedServer;
	BOOL				atLeastOneSource = NO, noChecked = YES, error = NO;
	
	[autoQueryLock lock];
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];
	
	BOOL showErrorCopy = [[NSUserDefaults standardUserDefaults] boolForKey: @"showErrorsIfQueryFailed"];
	[[NSUserDefaults standardUserDefaults] setBool: showError forKey: @"showErrorsIfQueryFailed"];
	
	noChecked = YES;
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
			noChecked = NO;
	}
	
	selectedServer = -1;
	if( noChecked)
		selectedServer = [sourcesTable selectedRow];
	
	atLeastOneSource = NO;
	BOOL firstResults = YES;
	
	NSMutableArray *tempResultArray = [NSMutableArray array];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES || selectedServer == i)
		{
			aServer = [[sourcesArray objectAtIndex:i] valueForKey:@"server"];
			
			if( showError)
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
						case 4:		currentQueryKey = StudyDescription;	break;
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
					else if( currentQueryKey == StudyDescription)
					{
						NSString *filterValue = [searchFieldStudyDescription stringValue];
						
						if ([filterValue length] > 0)
						{
							[queryManager addFilter:filterValue forDescription:currentQueryKey];
							queryItem = YES;
						}
					}
					
					//
					if ([dateQueryFilter object])
					{
						[queryManager addFilter:[dateQueryFilter filteredValue] forDescription:@"StudyDate"];
						queryItem = YES;
					}
					
					if ([timeQueryFilter object])
					{
						[queryManager addFilter:[timeQueryFilter filteredValue] forDescription:@"StudyTime"];
						queryItem = YES;
					}
					
					if ([modalityQueryFilter object])
					{
						[queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"ModalitiesinStudy"];
						queryItem = YES;
					}
					
					if (queryItem)
					{						
						[self performQuery: nil];
					}
					// if filter is empty and there is no date the query may be prolonged and fail. Ask first. Don't run if cancelled
					else
					{
						BOOL doit = NO;
						
						if( showError)
						{
							if( atLeastOneSource == NO)
							{
								NSString *alertSuppress = @"No parameters query";
								NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
								if ([defaults boolForKey:alertSuppress])
								{
									doit = YES;
								}
								else
								{
									NSAlert* alert = [NSAlert new];
									[alert setMessageText: NSLocalizedString(@"Query", nil)];
									[alert setInformativeText: NSLocalizedString(@"No query parameters provided. The query may take a long time.", nil)];
									[alert setShowsSuppressionButton:YES ];
									[alert addButtonWithTitle: NSLocalizedString(@"Continue", nil)];
									[alert addButtonWithTitle: NSLocalizedString(@"Cancel", nil)];
									
									if ( [alert runModal] == NSAlertFirstButtonReturn) doit = YES;
									
									if ([[alert suppressionButton] state] == NSOnState)
									{
										[defaults setBool:YES forKey:alertSuppress];
									}
								}
							}
							else doit = YES;
						}
						else doit = YES;
						
						if( doit)
						{
							[self performQuery: nil];
						}
						else i = [sourcesArray count];
					}
					
					if( firstResults)
					{
						firstResults = NO;
						[tempResultArray removeAllObjects];
						[tempResultArray addObjectsFromArray: [queryManager queries]];
					}
					else
					{
						NSArray		*curResult = [queryManager queries];
						NSArray		*uidArray = [tempResultArray valueForKey: @"uid"];
						
						for( NSUInteger x = 0 ; x < [curResult count] ; x++)
						{
							if( [self array: uidArray containsObject: [[curResult objectAtIndex: x] valueForKey:@"uid"]] == NO)
							{
								[tempResultArray addObject: [curResult objectAtIndex: x]];
							}
						}
					}
				}
//				else
//				{
//					NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", theirAET, hostname, [port intValue]];
//				
//					response = [response stringByAppendingString:NSLocalizedString(@"Connection failed to this DICOM node (c-echo failed)", nil)];
//					
//					NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), response, NSLocalizedString(@"Continue", nil), nil, nil) ;
//				}
			}
			else
			{
				if( showError)
				{
					NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", theirAET, hostname, [port intValue]];
				
					response = [response stringByAppendingString:NSLocalizedString(@"Connection failed to this DICOM node (ping failed)", nil)];
				
					NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), response, NSLocalizedString(@"Continue", nil), nil, nil) ;
					
					error = YES;
				}
			}
			atLeastOneSource = YES;
		}
	}
	
	if( [tempResultArray count])
		[tempResultArray sortUsingDescriptors: [self sortArray]];
	
	[autoQueryLock unlock];
	
	[self performSelectorOnMainThread:@selector( refreshList: ) withObject: tempResultArray waitUntilDone: YES];
	
	if( atLeastOneSource == NO)
	{
		if( showError)
			NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil), NSLocalizedString( @"Please select a DICOM node (check box).", nil), NSLocalizedString(@"Continue", nil), nil, nil) ;
	}
	
	[[NSUserDefaults standardUserDefaults] setBool: showErrorCopy forKey: @"showErrorsIfQueryFailed"];
	
	return error;
}

- (void) refreshList: (NSArray*) l
{
	[l retain];
	
	[resultArray removeAllObjects];
	[resultArray addObjectsFromArray: l];
	[self refresh: self];
	
	[l release];
}

- (void) displayQueryResults
{
	[sourcesTable selectRow: [sourcesTable selectedRow] byExtendingSelection: NO];
	
	if( [resultArray count] <= 1) [numberOfStudies setStringValue: [NSString stringWithFormat:@"%d study found", [resultArray count]]];
	else [numberOfStudies setStringValue: [NSString stringWithFormat:@"%d studies found", [resultArray count]]];
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
	
	[self autoQueryTimer: self];
	
	[self queryWithDisplayingErrors: YES];
	
	[self displayQueryResults];
	
	if ([sender isKindOfClass:[NSSearchField class]])
		[sender selectText: self];
}

// This function calls many GUI function, it has to be called from the main thread
- (void) performQuery:(id)object
{
	checkAndViewTry = -1;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[progressIndicator startAnimation:nil];
	[queryManager performQuery];
	[progressIndicator stopAnimation:nil];
	[resultArray sortUsingDescriptors: [self sortArray]];
	[self refresh: self];
	[pool release];
	
	queryPerformed = YES;
}

- (NSString*) stringIDForStudy:(id) item
{
	return [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@", [item valueForKey:@"name"], [item valueForKey:@"patientID"], [item valueForKey:@"accessionNumber"], [item valueForKey:@"date"], [item valueForKey:@"time"], [item valueForKey:@"uid"]];
}

- (void) addStudyIfNotAvailable: (id) item toArray:(NSMutableArray*) selectedItems
{
	NSArray *studyArray = [self localStudy: item];
	
	int localFiles = 0;
	int totalFiles = [[item valueForKey:@"numberImages"] intValue];
	
	if( [studyArray count])
		localFiles = [[[studyArray objectAtIndex: 0] valueForKey: @"noFiles"] intValue];
	
	if( localFiles < totalFiles)
	{
		NSString *stringID = [self stringIDForStudy: item];
		
		@synchronized( previousAutoRetrieve)
		{
			NSNumber *previousNumberOfFiles = [previousAutoRetrieve objectForKey: stringID];
			
			// We only want to re-retrieve the study if they are new files compared to last time... we are maybe currently in the middle of a retrieve...
			
			if( [previousNumberOfFiles intValue] != totalFiles)
			{
				[selectedItems addObject: item];
				[previousAutoRetrieve setValue: [NSNumber numberWithInt: totalFiles] forKey: stringID];
			}
		}
	}
}

- (void) autoRetrieveThread: (NSArray*) list
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[autoQueryLock lock];
	
	// Start to retrieve the first 10 studies...
	
	NSMutableArray *selectedItems = [NSMutableArray array];
	
	for( id item in list)
	{
		[self addStudyIfNotAvailable: item toArray: selectedItems];
		if( [selectedItems count] >= 10) break;
	}
	
	if( [selectedItems count])
	{
		if( [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfPreviousStudyToRetrieve"])
		{
			NSMutableArray *previousStudies = [NSMutableArray array];
			for( id item in selectedItems)
			{
				NSArray *studiesOfThisPatient = [self queryPatientIDwithoutGUI: [item valueForKey:@"patientID"]];
				
				// Sort the resut by date & time
				NSMutableArray *sortArray = [NSMutableArray array];
				[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"date" ascending: NO] autorelease]];
				[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"time" ascending: NO] autorelease]];
				studiesOfThisPatient = [studiesOfThisPatient sortedArrayUsingDescriptors: sortArray];
				
				int numberOfStudiesAssociated = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfPreviousStudyToRetrieve"];
				
				for( id study in studiesOfThisPatient)
				{
					// We dont want current study
					if( [[study valueForKey:@"uid"] isEqualToString: [item valueForKey:@"uid"]] == NO)
					{
						BOOL found = YES;
						
						if( numberOfStudiesAssociated > 0)
						{
							if( [[NSUserDefaults standardUserDefaults] boolForKey:@"retrieveSameModality"])
							{
								if( [item valueForKey:@"modality"] && [study valueForKey:@"modality"])
								{
									if( [[study valueForKey:@"modality"] rangeOfString: [item valueForKey:@"modality"]].location == NSNotFound) found = NO;						
								}
								else found = NO;
							}
							
							if( [[NSUserDefaults standardUserDefaults] boolForKey:@"retrieveSameDescription"])
							{
								if( [item valueForKey:@"theDescription"] && [study valueForKey:@"theDescription"])
								{
									if( [[study valueForKey:@"theDescription"] rangeOfString: [item valueForKey:@"theDescription"]].location == NSNotFound) found = NO;
								}
								else found = NO;
							}
							
							if( found)
							{
								[self addStudyIfNotAvailable: study toArray: previousStudies];
								numberOfStudiesAssociated--;
							}
						}
					}
				}
			}
			
			[selectedItems addObjectsFromArray: previousStudies];
			
			for( id item in selectedItems)
				[item setShowErrorMessage: NO];
		}
		
		[NSThread detachNewThreadSelector:@selector( performRetrieve:) toTarget:self withObject: selectedItems];
		
		NSLog( @"-------");
		NSLog( @"Will auto-retrieve these items:");
		for( id item in selectedItems)
		{
			NSLog( @"%@ %@ %@ %@", [item valueForKey:@"name"], [item valueForKey:@"patientID"], [item valueForKey:@"accessionNumber"], [item valueForKey:@"date"]);
		}
		NSLog( @"-------");
		
		NSString *desc = [NSString stringWithFormat: NSLocalizedString( @"Will auto-retrieve %d studies", nil), [selectedItems count]];
		
		[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: desc name: @"newfiles"];
	}
	else
	{
		NSLog( @"--- autoRetrieving is up to date! Nothing to retrieve ---");
	}
	
	[autoQueryLock unlock];
	
	[pool release];
}

- (void) displayAndRetrieveQueryResults
{
	[self displayQueryResults];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"autoRetrieving"])
	{
		[NSThread detachNewThreadSelector:@selector( autoRetrieveThread:) toTarget:self withObject: [NSArray arrayWithArray: resultArray]];
	}
}

- (void) autoQueryThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( [self queryWithDisplayingErrors: NO] == 0)
		[self performSelectorOnMainThread: @selector( displayAndRetrieveQueryResults) withObject:0 waitUntilDone: NO];
	else
	{
		[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: @"Failed..." name: @"newfiles"];
	}
	
	[pool release];
}

- (void) autoQueryTimerFunction:(NSTimer*) t
{
	if( queryPerformed)
	{
		if( DatabaseIsEdited == NO)
		{
			if( --autoQueryRemainingSecs <= 0)
			{
				if( [autoQueryLock tryLock])
				{
					[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Query", nil) description: NSLocalizedString( @"Refreshing...", nil) name: @"newfiles"];
					
					[NSThread detachNewThreadSelector: @selector( autoQueryThread) toTarget: self withObject: nil];
					
					autoQueryRemainingSecs = 60*[[NSUserDefaults standardUserDefaults] integerForKey: @"autoRefreshQueryResults"]; 
					
					[autoQueryLock unlock];
				}
				else autoQueryRemainingSecs = 0;
			}
		}
		
		[autoQueryCounter setStringValue: [NSString stringWithFormat: @"%2.2d:%2.2d", (int) (autoQueryRemainingSecs/60), (int) (autoQueryRemainingSecs%60)]];
	}
}

- (IBAction) autoQueryTimer:(id) sender
{
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"autoRefreshQueryResults"])
	{
		[QueryTimer invalidate];
		[QueryTimer release];
		
		autoQueryRemainingSecs = 60*[[NSUserDefaults standardUserDefaults] integerForKey: @"autoRefreshQueryResults"];
		[autoQueryCounter setStringValue: [NSString stringWithFormat: @"%2.2d:%2.2d", (int) (autoQueryRemainingSecs/60), (int) (autoQueryRemainingSecs%60)]];
		
		QueryTimer = [[NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector( autoQueryTimerFunction:) userInfo:nil repeats:YES] retain];
	}
	else
	{
		[autoQueryCounter setStringValue: @""];
		
		[QueryTimer invalidate];
		[QueryTimer release];
		QueryTimer = nil;
	}
}

- (void)clearQuery:(id)sender
{
	[queryManager release];
	queryManager = nil;
	[progressIndicator stopAnimation:nil];
	[searchFieldName setStringValue:@""];
	[searchFieldID setStringValue:@""];
	[searchFieldAN setStringValue:@""];
	[searchFieldStudyDescription setStringValue:@""];
	[self refresh: self];
}

-(IBAction) copy:(id) sender
{
    NSPasteboard	*pb = [NSPasteboard generalPasteboard];
			
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	id   aFile = [outlineView itemAtRow:[outlineView selectedRow]];
	
	if( aFile)
		[pb setString: [aFile valueForKey:@"name"] forType:NSStringPboardType];
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable forViewing: (BOOL) forViewing items:(NSArray*) items showGUI:(BOOL) showGUI
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	
	if([items count])
	{
		for( id item in items)
		{
			if( onlyIfNotAvailable)
			{
				int localNumber = 0;
				NSArray *array = 0L;
				
				if( [item isMemberOfClass: [DCMTKSeriesQueryNode class]])
					array = [self localSeries: item];
				else
					array = [self localStudy: item];
				
				if( [array count])
					localNumber = [[[array objectAtIndex: 0] valueForKey: @"noFiles"] intValue];
				
				if( localNumber < [[item valueForKey:@"numberImages"] intValue])
				{
					NSString *stringID = [self stringIDForStudy: item];
		
					@synchronized( previousAutoRetrieve)
					{
						NSNumber *previousNumberOfFiles = [previousAutoRetrieve objectForKey: stringID];
			
						// We only want to re-retrieve the study if they are new files compared to last time... we are maybe currently in the middle of a retrieve...
						
						if( [previousNumberOfFiles intValue] != [[item valueForKey:@"numberImages"] intValue])
						{
							[selectedItems addObject: item];
							[previousAutoRetrieve setValue: [NSNumber numberWithInt: [[item valueForKey:@"numberImages"] intValue]] forKey: stringID];
						}
						else NSLog( @"Already in transfer.... We don't need to download it...");
					}
				}
				else
					NSLog( @"Already here! We don't need to download it...");
			}
			else [selectedItems addObject: item];
		}
		
		if( [selectedItems count] > 0)
		{
			if( [sendToPopup indexOfSelectedItem] != 0 && forViewing == YES)
			{
				if( showGUI)
					NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Query & Retrieve",nil),NSLocalizedString( @"If you want to retrieve & view these images, change the destination to this computer ('retrieve to' menu).",nil),NSLocalizedString( @"OK",nil), nil, nil);
			}
			else
			{
				WaitRendering *wait = nil;
				
				if( showGUI)
				{
					wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting Retrieving...", nil)];
					[wait showWindow:self];
				}
				
				checkAndViewTry = -1;
				[NSThread detachNewThreadSelector:@selector( performRetrieve:) toTarget:self withObject: selectedItems];
				
				if( showGUI)
				{
					unsigned long finalTicks;
					Delay( 30, &finalTicks);
				
					[wait close];
					[wait release];
				}
			}
		}
	}
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable forViewing: (BOOL) forViewing
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	NSIndexSet		*selectedRowIndexes = [outlineView selectedRowIndexes];
	
	if( [selectedRowIndexes count])
	{
		for (NSUInteger index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
		{
		   if ([selectedRowIndexes containsIndex:index])
				[selectedItems addObject: [outlineView itemAtRow:index]];
		}
		
		[self retrieve: sender onlyIfNotAvailable: onlyIfNotAvailable forViewing: forViewing items: selectedItems showGUI: YES];
	}
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable
{
	return [self retrieve: sender onlyIfNotAvailable: onlyIfNotAvailable forViewing: NO];
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
	if( [[outlineView tableColumns] count] > [outlineView clickedColumn] && [outlineView clickedColumn] >= 0)
	{
		if( [[[[outlineView tableColumns] objectAtIndex: [outlineView clickedColumn]] identifier] isEqualToString: @"comment"])
			return;
	}
	   
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
	
	[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
	
	for( NSUInteger i = 0; i < [array count] ; i++)
	{
		DCMTKQueryNode	*object = [array objectAtIndex: i];
		
		[dictionary setObject:[object valueForKey:@"calledAET"] forKey:@"calledAET"];
		[dictionary setObject:[object valueForKey:@"hostname"] forKey:@"hostname"];
		[dictionary setObject:[object valueForKey:@"port"] forKey:@"port"];
		[dictionary setObject:[object valueForKey:@"transferSyntax"] forKey:@"transferSyntax"];

		NSDictionary	*dstDict = nil;
		
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
				
				@synchronized( previousAutoRetrieve)
				{
					[previousAutoRetrieve removeObjectForKey: [self stringIDForStudy: object]];
				}
			}
		}
	}
	
	for( id item in array)
		[item setShowErrorMessage: NO];
	
	NSLog(@"Retrieve END");
	
	[array release];
	
	[pool release];
}

- (void) checkAndView:(id) item
{
	if( [[self window] isVisible] == NO) return;
	if( checkAndViewTry < 0) return;
	
	[[BrowserController currentBrowser] checkIncoming: self];
	
	NSError						*error = nil;
	NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray						*studyArray, *seriesArray;
	BOOL						success = NO;
	
	[context lock];
	
	@try
	{
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
				
				if( [[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO] == NO)
				{
					[[BrowserController currentBrowser] showEntireDatabase];
					if( [[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO]) success = YES;
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
					[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
				else
					[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
					
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
				
	}
	@catch (NSException * e)
	{
		NSLog( @"**** checkAndView exception: %@", [e description]);
	}
	
	[context unlock];
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
	
	NSMutableString *m = [NSMutableString string];
	for( NSCell *cell in [sender cells])
	{
		if( [cell state] == NSOnState)
		{
			if( [m length]) [m appendString:@"\\"];
			[m appendString: [cell title]];
		}
	}
	
	if ( [m length])
		modalityQueryFilter = [[QueryFilter queryFilterWithObject:m ofSearchType:searchExactMatch  forKey:@"ModalitiesinStudy"] retain];
	else
		modalityQueryFilter = [[QueryFilter queryFilterWithObject: nil ofSearchType:searchExactMatch  forKey:@"ModalitiesinStudy"] retain];
}


- (void)setDateQuery:(id)sender
{
	[dateQueryFilter release];
	[timeQueryFilter release];
	timeQueryFilter = nil;
	
	if( [sender selectedTag] == 5)
	{
		[fromDate setEnabled: YES];
		[toDate setEnabled: YES];
		
		NSDate	*later = [[fromDate dateValue] laterDate: [toDate dateValue]];
		NSDate	*earlier = [[fromDate dateValue] earlierDate: [toDate dateValue]];
		
		NSString	*between = [NSString stringWithFormat:@"%@-%@", [earlier descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil], [later descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];
		
		dateQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyDate"] retain];
	}
	else
	{
		[fromDate setEnabled: NO];
		[toDate setEnabled: NO];
		
		DCMCalendarDate *date = nil;
		
		int searchType = searchAfter;
		
		switch( [sender selectedTag])
		{
			case 0:			date = nil;																								break;
			case 1:			date = [DCMCalendarDate date];											searchType = SearchToday;		break;
			case 2:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24 -1];	searchType = searchYesterday;	break;
			case 3:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*7 -1];									break;
			case 4:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31 -1];									break;
			
			case 10:	// AM & PM
			case 11:
				date = [DCMCalendarDate date];
				searchType = SearchToday;
				
				NSString	*between;
				
				if( [sender selectedTag] == 10)
					between = [NSString stringWithString:@"000000.000-120000.000"];
				else
					between = [NSString stringWithString:@"120000.000-235959.000"];
				
				timeQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyTime"] retain];
			break;				
		}
		dateQueryFilter = [[QueryFilter queryFilterWithObject:date ofSearchType:searchType  forKey:@"StudyDate"] retain];
	}
}

-(void) awakeFromNib
{
	[numberOfStudies setStringValue: @""];
	
	[[self window] setFrameAutosaveName:@"QueryRetrieveWindow"];
	
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier: @"stateText"];
	NSPopUpButtonCell *buttonCell = [[[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO] autorelease];
	[buttonCell setEditable: YES];
	[buttonCell setBordered: NO];
	[buttonCell addItemsWithTitles: [BrowserController statesArray]];
	[tableColumn setDataCell:buttonCell];
	
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
		id searchCell = [searchFieldStudyDescription cell];
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
	
	NSDateFormatter *dateFomat = [[[NSDateFormatter alloc]  init] autorelease];
	[dateFomat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat2"]];
	
	[[[outlineView tableColumnWithIdentifier: @"birthdate"] dataCell] setFormatter: dateFomat];
	
	[sourcesTable setDoubleAction: @selector( selectUniqueSource:)];
	
	[self refreshSources];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
		{
			[sourcesTable selectRow: i byExtendingSelection: NO];
			[sourcesTable scrollRowToVisible: i];
			break;
		}
	}
	
	[self buildPresetsMenu];
	
	[alreadyInDatabase setImage:[NSImage pieChartImageWithPercentage:1.0]];
	[partiallyInDatabase setImage:[NSImage pieChartImageWithPercentage:0.33]];
	
	[self autoQueryTimer: self];
}

//******

- (IBAction) selectUniqueSource:(id) sender
{
	[self willChangeValueForKey:@"sourcesArray"];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
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
	for( NSUInteger i = 0 ; i < [servers count]; i++)
	{
		if( [[savedServer objectForKey:@"AETitle"] isEqualToString: [[servers objectAtIndex:i] objectForKey:@"AETitle"]] && 
			[[savedServer objectForKey:@"AddressAndPort"] isEqualToString: [NSString stringWithFormat:@"%@:%@", [[servers objectAtIndex:i] valueForKey:@"Address"], [[servers objectAtIndex:i] valueForKey:@"Port"]]])
			{
				return [servers objectAtIndex:i];
			}
	}
	
	return nil;
}

- (void) refreshSources
{
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];
	
	NSMutableArray		*serversArray		= [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
	NSArray				*savedArray			= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SavedQueryArray"];
	
	[self willChangeValueForKey:@"sourcesArray"];
	 
	[sourcesArray removeAllObjects];
	
	for( NSUInteger i = 0; i < [savedArray count]; i++)
	{
		NSDictionary *server = [self findCorrespondingServer: [savedArray objectAtIndex:i] inServers: serversArray];
		
		if( server && ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
		{
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[[savedArray objectAtIndex: i] valueForKey:@"activated"], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
			
			[serversArray removeObject: server];
		}
	}
	
	for( NSUInteger i = 0; i < [serversArray count]; i++)
	{
		NSDictionary *server = [serversArray objectAtIndex: i];
		
		NSLog( [server description]);
		
		if( ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
		
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
	}
	
	[sourcesTable reloadData];
	
	[self didChangeValueForKey:@"sourcesArray"];
	
	// *********** Update Send To popup menu
	
	NSString	*previousItem = [[[sendToPopup selectedItem] title] retain];
	
	[sendToPopup removeAllItems];
	
	serversArray = [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
	
	NSString *ip = [NSString stringWithCString:GetPrivateIP()];
	[sendToPopup addItemWithTitle: [NSString stringWithFormat: NSLocalizedString( @"This Computer - %@/%@:%@", nil), [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], ip, [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]]];

	[[sendToPopup menu] addItem: [NSMenuItem separatorItem]];
	
	for( NSUInteger i = 0; i < [serversArray count]; i++)
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
		
		queryFilters = nil;
		dateQueryFilter = nil;
		timeQueryFilter = nil;
		modalityQueryFilter = nil;
		currentQueryKey = nil;
		echoSuccess = nil;
		activeMoves = nil;
		
//		partiallyInDatabase = [[NSImage imageNamed:@"QRpartiallyInDatabase.tif"] retain];
//		alreadyInDatabase = [[NSImage imageNamed:@"QRalreadyInDatabase.tif"] retain];
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		queryFilters = [[NSMutableArray array] retain];
		resultArray = [[NSMutableArray array] retain];
		activeMoves = [[NSMutableDictionary dictionary] retain];
		previousAutoRetrieve = [[NSMutableDictionary dictionary] retain];
		autoQueryLock = [[NSRecursiveLock alloc] init];
		performRetrievelock = [[NSRecursiveLock alloc] init];
//		displayLock = [[NSLock alloc] init];
		
		sourcesArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"SavedQueryArray"] mutableCopy];
		if( sourcesArray == nil) sourcesArray = [[NSMutableArray array] retain];
		
		[self refreshSources];
				
		[[self window] setDelegate:self];
		
		[self setDateQuery: dateFilterMatrix];
		
		currentQueryController = self;
	}
    
    return self;
}

- (void)dealloc
{
	[performRetrievelock lock];
	[performRetrievelock unlock];
	[autoQueryLock lock];
	[autoQueryLock unlock];
	
//	[displayLock lock];
//	[displayLock unlock];
//	[displayLock release];
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];

	NSLog( @"dealloc QueryController");
	[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys];
	[pressedKeys release];
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	[queryManager release];
	[queryFilters release];
	[dateQueryFilter release];
	[timeQueryFilter release];
	[modalityQueryFilter release];
	[activeMoves release];
	[previousAutoRetrieve release];
	[sourcesArray release];
	[resultArray release];
	[autoQueryLock release];
	[performRetrievelock release];
	[QueryTimer invalidate];
	[QueryTimer release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[studyArrayCache release];
	studyArrayCache = nil;
	[studyArrayInstanceUID release];
	studyArrayInstanceUID = nil;
	
	[super dealloc];
	
	currentQueryController = nil;
}

- (void)windowDidLoad
{
	id searchCell = [searchFieldName cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];

	searchCell = [searchFieldAN cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
	searchCell = [searchFieldStudyDescription cell];

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
	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Tools"] autorelease];
	NSMenuItem *item;
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Retrieve the images", nil) action: @selector( retrieve:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];

	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Retrieve and display the images", nil) action: @selector( retrieveAndView:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Query all studies of this patient", nil) action: @selector( querySelectedStudy:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete the local images", nil) action: @selector( deleteSelection:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	[outlineView setMenu: menu];
	
	//set up Query Keys
	currentQueryKey = PatientName;
	
	dateQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch  forKey:@"StudyDate"] retain];
	timeQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch  forKey:@"StudyTime"] retain];
	modalityQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch  forKey:@"ModalitiesinStudy"] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateServers:) name:@"DCMNetServicesDidChange"  object:nil];

	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"Button"];
	NSButtonCell *buttonCell = [[[NSButtonCell alloc] init] autorelease];
	[buttonCell setTarget:self];
	[buttonCell setAction:@selector(retrieveClick:)];
	[buttonCell setControlSize:NSMiniControlSize];
	[buttonCell setImage:[NSImage imageNamed:@"InArrow.tif"]];
	[buttonCell setBezelStyle: NSRoundRectBezelStyle]; // was NSRegularSquareBezelStyle
	[tableColumn setDataCell:buttonCell];
	
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	[toDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: @"SavedQueryArray"];
	
	[[self window] orderOut: self];
}

- (int) dicomEcho:(NSDictionary*) aServer
{
	int status = 0;
	
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	
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
	int				status, selectedRow = [sourcesTable selectedRow];
	
	[progressIndicator startAnimation:nil];
	
	[self willChangeValueForKey:@"sourcesArray"];
	
	for( NSUInteger i = 0 ; i < [sourcesArray count]; i++)
	{
		[sourcesTable selectRow: i byExtendingSelection: NO];
		[sourcesTable scrollRowToVisible: i];
		
		NSMutableDictionary *aServer = [sourcesArray objectAtIndex: i];
		
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
		
		case 2:		// Retrieve
			[self retrieve: sender];
		break;
		
		case 3:		// Verify
			[self verify: sender];
		break;
		
		case 1:		// Query Selected Patient
			[self querySelectedStudy: self];
		break;
	}
}
@end
