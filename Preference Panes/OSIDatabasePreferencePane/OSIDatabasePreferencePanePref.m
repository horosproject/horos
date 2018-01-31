/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "OSIDatabasePreferencePanePref.h"
#import "PluginManager.h"
#import "BrowserController.h"
#import "PreferencesWindowController+DCMTK.h"
#import "DCMAbstractSyntaxUID.h"
#import "BrowserControllerDCMTKCategory.h"
#import "DicomDatabase.h"
#import "DicomFile.h"
#import "WaitRendering.h"
#import "ICloudDriveDetector.h"

@implementation OSIDatabasePreferencePanePref

@synthesize currentCommentsAutoFill, currentCommentsField;
@synthesize newUsePatientIDForUID, newUsePatientBirthDateForUID, newUsePatientNameForUID;

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIDatabasePreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath: @"values.eraseEntireDBAtStartup" options: NSKeyValueObservingOptionNew context:nil];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath: @"values.dbFontSize" options: NSKeyValueObservingOptionNew context:nil];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath: @"values.horizontalHistory" options: NSKeyValueObservingOptionNew context:nil];
	}
	
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
		if ([keyPath isEqualToString:@"values.eraseEntireDBAtStartup" ])
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"eraseEntireDBAtStartup"])
            {
                NSRunCriticalAlertPanel( NSLocalizedString( @"Erase Entire Database", nil), NSLocalizedString( @"Warning! With this option, each time OsiriX is restarted, the entire database will be erased. All studies will be deleted. This cannot be undone.", nil), NSLocalizedString( @"OK", nil), nil, nil);
            }
        }
        
        if ([keyPath isEqualToString:@"values.horizontalHistory" ])
        {
            NSRunCriticalAlertPanel( NSLocalizedString( @"Restart", nil), NSLocalizedString( @"Restart Horos to apply this change.", nil), NSLocalizedString( @"OK", nil), nil, nil);
        }
        
        if ([keyPath isEqualToString:@"values.dbFontSize"])
        {
            [[BrowserController currentBrowser] setTableViewRowHeight];
            [[BrowserController currentBrowser] refreshMatrix: self];
            [[[BrowserController currentBrowser] window] display];
        }
    }
}

- (NSArray*) ListOfMediaSOPClassUID // Displayed in DB window
{
	NSMutableArray *l = [NSMutableArray array];
	
    [l addObject: NSLocalizedString( @"Displayed SOP Class UIDs", nil)];
    
	for( NSString *s in [[DCMAbstractSyntaxUID imageSyntaxes] sortedArrayUsingSelector: @selector(compare:)])
		[l addObject: [NSString stringWithFormat: @"%@ - %@", s, [BrowserController compressionString: s]]];
	
	return l;
}

- (NSArray*) ListOfMediaSOPClassUIDStored
{
	NSMutableArray *l = [NSMutableArray array];
	
    [l addObject: NSLocalizedString( @"Stored SOP Class UIDs", nil)];
    
	for( NSString *s in [[DCMAbstractSyntaxUID allSupportedSyntaxes] sortedArrayUsingSelector: @selector(compare:)])
		[l addObject: [NSString stringWithFormat: @"%@ - %@", s, [BrowserController compressionString: s]]];
	
	return l;
}


- (void) dealloc
{	
	NSLog(@"dealloc OSIDatabasePreferencePanePref");
	
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: @"values.eraseEntireDBAtStartup"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: @"values.dbFontSize"];
    
    [DICOMFieldsArray release];
    
    [_tlos release]; _tlos = nil;
	
	[super dealloc];
}

- (void) buildPluginsMenu
{
	int numberOfReportPlugins = 0;
	for( NSString *k in [[PluginManager reportPlugins] allKeys])
	{
		[reportsMode addItemWithTitle: k];
		[[reportsMode lastItem] setIndentationLevel:1];
		numberOfReportPlugins++;
	}
	
	if( numberOfReportPlugins <= 0)
	{
		[reportsMode removeItemAtIndex:[reportsMode indexOfItem:[reportsMode lastItem]]];
		[reportsMode removeItemAtIndex:[reportsMode indexOfItem:[reportsMode lastItem]]];
	}
	else
	{
		if(numberOfReportPlugins == 1)
			[[reportsMode itemAtIndex:4] setTitle:@"Plugin"];
		[reportsMode setAutoenablesItems:NO];
		[[reportsMode itemAtIndex:4] setEnabled:NO];
	}
}

-(void) willUnselect
{
    BOOL recompute = NO;
    
    if( self.newUsePatientBirthDateForUID == NO && self.newUsePatientNameForUID == NO && self.newUsePatientIDForUID == NO)
    {
        NSRunCriticalAlertPanel( NSLocalizedString( @"Patient UID", nil), NSLocalizedString( @"At least one parameter has to be selected to generate a valid Patient UID. Patient ID will be used.", nil), NSLocalizedString( @"OK", nil), nil, nil);
        
        self.newUsePatientIDForUID = YES;
    }
    
    if( self.newUsePatientBirthDateForUID != [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientBirthDateForUID"])
        recompute = YES;
    
    if( self.newUsePatientNameForUID != [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientNameForUID"])
        recompute = YES;
    
    if( self.newUsePatientIDForUID != [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientIDForUID"])
        recompute = YES;
    
    if( recompute)
    {
        [[NSUserDefaults standardUserDefaults] setBool: self.newUsePatientBirthDateForUID forKey: @"UsePatientBirthDateForUID"];
        [[NSUserDefaults standardUserDefaults] setBool: self.newUsePatientNameForUID forKey: @"UsePatientNameForUID"];
        [[NSUserDefaults standardUserDefaults] setBool: self.newUsePatientIDForUID forKey: @"UsePatientIDForUID"];
        
        WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString( @"Recomputing Patient UIDs...", nil)];
        [wait showWindow: self];
        [wait start];
        
        [DicomFile setDefaults];
        
        for( DicomDatabase *d in [DicomDatabase allDatabases])
        {
            [DicomDatabase recomputePatientUIDsInContext: d.managedObjectContext];
        }
        
        [[BrowserController currentBrowser] refreshDatabase: self];
        
        [wait end];
        [wait close];
        [wait autorelease];
    }
    
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) mainViewDidLoad
{


//	[[scrollView verticalScroller] setFloatValue: 0]; 
////	[[scrollView verticalScroller] setFloatValue:0.0 knobProportion:0.0]; //// now with bindings
//	[scrollView setVerticalScroller: [scrollView verticalScroller]];
	
//	[[scrollView contentView] scrollToPoint: NSMakePoint(600,600)];
	
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	//setup GUI
////	[copyDatabaseOnOffButton setState:[defaults boolForKey:@"COPYDATABASE"]]; //// now with bindings
	
//	[displayAllStudies setState:[defaults boolForKey:@"KeepStudiesOfSamePatientTogether"]];
	
	long locationValue = [defaults integerForKey:@"DEFAULT_DATABASELOCATION"];
	
	[locationMatrix selectCellWithTag:locationValue];
	[locationPathField setURL: [NSURL fileURLWithPath: [defaults stringForKey:@"DEFAULT_DATABASELOCATIONURL"]]];
	
//	[copyDatabaseModeMatrix setEnabled:[defaults boolForKey:@"COPYDATABASE"]];
////	[copyDatabaseModeMatrix selectCellWithTag:[defaults integerForKey:@"COPYDATABASEMODE"]];
//	[localizerOnOffButton setState:[defaults boolForKey:@"NOLOCALIZER"]]; 
//	[multipleScreensMatrix selectCellWithTag:[defaults integerForKey:@"MULTIPLESCREENSDATABASE"]];
	[seriesOrderMatrix selectCellWithTag:[defaults integerForKey:@"SERIESORDER"]];
	
	
	// COMMENTS
	self.currentCommentsAutoFill = 0;
    
    if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"commentFieldForAutoFill"] isEqualToString: @"comment"]) self.currentCommentsField = 1;
    if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"commentFieldForAutoFill"] isEqualToString: @"comment2"]) self.currentCommentsField = 2;
    if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"commentFieldForAutoFill"] isEqualToString: @"comment3"]) self.currentCommentsField = 3;
    if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"commentFieldForAutoFill"] isEqualToString: @"comment4"]) self.currentCommentsField = 4;
	
	// REPORTS
	[self buildPluginsMenu];
	if([[defaults stringForKey:@"REPORTSMODE"] intValue] == 3)
	{
		[reportsMode selectItemWithTitle:[defaults stringForKey:@"REPORTSPLUGIN"]];
	}
	else
	{
		[reportsMode selectItemWithTag:[[defaults stringForKey:@"REPORTSMODE"] intValue]];
	}
	
	// DATABASE AUTO-CLEANING
	
	[older setState:[defaults boolForKey:@"AUTOCLEANINGDATE"]];
	[deleteOriginal setState:[defaults boolForKey:@"AUTOCLEANINGDELETEORIGINAL"]];
	[[olderType cellWithTag:0] setState:[defaults boolForKey:@"AUTOCLEANINGDATEPRODUCED"]];
	[[olderType cellWithTag:1] setState:[defaults boolForKey:@"AUTOCLEANINGDATEOPENED"]];
	[[olderType cellWithTag:2] setState:[defaults boolForKey:@"AUTOCLEANINGCOMMENTS"]];
	
	[commentsDeleteText setStringValue: [defaults stringForKey:@"AUTOCLEANINGCOMMENTSTEXT"]];
	[commentsDeleteMatrix selectCellWithTag:[[defaults stringForKey:@"AUTOCLEANINGDONTCONTAIN"] intValue]];
	[olderThanProduced selectItemWithTag:[[defaults stringForKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"] intValue]];
	[olderThanOpened selectItemWithTag:[[defaults stringForKey:@"AUTOCLEANINGDATEOPENEDDAYS"] intValue]];
	
//	[freeSpace setState:[defaults boolForKey:@"AUTOCLEANINGSPACE"]];
//	[[freeSpaceType cellWithTag:0] setState:[defaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"]];
//	[[freeSpaceType cellWithTag:1] setState:[defaults boolForKey:@"AUTOCLEANINGSPACEOPENED"]];
//	[freeSpaceSize selectItemWithTag:[[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue]];
    
    
    self.newUsePatientBirthDateForUID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientBirthDateForUID"];
    self.newUsePatientNameForUID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientNameForUID"];
    self.newUsePatientIDForUID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientIDForUID"];
}

- (void)didSelect
{
	DICOMFieldsArray = [[[[[self mainView] window] windowController] prepareDICOMFieldsArrays] retain];
	
	NSMenu *DICOMFieldsMenu = [dicomFieldsMenu menu];
	[DICOMFieldsMenu setAutoenablesItems:NO];
	[dicomFieldsMenu removeAllItems];
	
	NSMenuItem *item;
	item = [[[NSMenuItem alloc] init] autorelease];
	[item setTitle:NSLocalizedString( @"DICOM Fields", nil)];
	[item setEnabled:NO];
	[DICOMFieldsMenu addItem:item];
	int i;
	for (i=0; i<[DICOMFieldsArray count]; i++)
	{
		item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[[DICOMFieldsArray objectAtIndex:i] title]];
		[item setRepresentedObject:[DICOMFieldsArray objectAtIndex:i]];
		[DICOMFieldsMenu addItem:item];
	}
	[dicomFieldsMenu setMenu:DICOMFieldsMenu];
}

- (IBAction) setReportMode:(id) sender
{
	// report mode int value
	// 0 : Microsoft Word
	// 1 : TextEdit
	// 2 : Pages
	// 3 : Plugin
	// 4 : DICOM SR
	// 5 : OO
	
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	int indexOfPluginsLabel = [reportsMode indexOfItemWithTitle:@"Plugins"];
	int indexOfPluginLabel = [reportsMode indexOfItemWithTitle:@"Plugin"];
	int indexOfLabel = (indexOfPluginsLabel>indexOfPluginLabel)?indexOfPluginsLabel:indexOfPluginLabel;
	
	indexOfLabel = (indexOfLabel<=0)? 10000 : indexOfLabel ;
	
	if([reportsMode indexOfSelectedItem] >= indexOfLabel) // in this case it is a plugin
	{
		[defaults setInteger:3 forKey:@"REPORTSMODE"];
		[defaults setObject:[[reportsMode selectedItem] title] forKey:@"REPORTSPLUGIN"];
	}
	else
	{
		[defaults setInteger:[[reportsMode selectedItem] tag] forKey:@"REPORTSMODE"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reportModeChanged" object:nil];
}

// - (IBAction) setDisplayAllStudiesAlbum:(id) sender
// {
//	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"KeepStudiesOfSamePatientTogether"];
// }

- (IBAction)regenerateAutoComments:(id) sender
{
	[[BrowserController currentBrowser] regenerateAutoComments: nil]; // nil == all studies
}

- (void) setCurrentCommentsField:(int) v
{
    currentCommentsField = v;
    
    if( currentCommentsField == 1) [[NSUserDefaults standardUserDefaults] setObject:@"comment" forKey:@"commentFieldForAutoFill"];
    if( currentCommentsField == 2) [[NSUserDefaults standardUserDefaults] setObject:@"comment2" forKey:@"commentFieldForAutoFill"];
    if( currentCommentsField == 3) [[NSUserDefaults standardUserDefaults] setObject:@"comment3" forKey:@"commentFieldForAutoFill"];
    if( currentCommentsField == 4) [[NSUserDefaults standardUserDefaults] setObject:@"comment4" forKey:@"commentFieldForAutoFill"];
}

- (void) setCurrentCommentsAutoFill:(int) v
{
    currentCommentsAutoFill = v;
    
    NSString *group, *element;
    if( currentCommentsAutoFill > 0)
    {
        group = [NSString stringWithFormat: @"COMMENTSGROUP%d", currentCommentsAutoFill+1];
        element = [NSString stringWithFormat: @"COMMENTSELEMENT%d", currentCommentsAutoFill+1];
    }
    else
    {
        group = [NSString stringWithFormat: @"COMMENTSGROUP"];
        element = [NSString stringWithFormat: @"COMMENTSELEMENT"];
    }
    
    if( [[[NSUserDefaults standardUserDefaults] stringForKey:group] intValue] > 0)
    {
        [commentsGroup setStringValue:[NSString stringWithFormat:@"0x%04X", [[[NSUserDefaults standardUserDefaults] stringForKey:group] intValue]]];
        [commentsElement setStringValue:[NSString stringWithFormat:@"0x%04X", [[[NSUserDefaults standardUserDefaults] stringForKey:element] intValue]]];
    }
    else
    {
        [commentsGroup setStringValue: @""];
        [commentsElement setStringValue: @""];
    }
}

- (IBAction) setAutoComments:(id) sender
{
	// COMMENTS

    NSString *group, *element;
    if( currentCommentsAutoFill > 0)
    {
        group = [NSString stringWithFormat: @"COMMENTSGROUP%d", currentCommentsAutoFill+1];
        element = [NSString stringWithFormat: @"COMMENTSELEMENT%d", currentCommentsAutoFill+1];
    }
    else
    {
        group = [NSString stringWithFormat: @"COMMENTSGROUP"];
        element = [NSString stringWithFormat: @"COMMENTSELEMENT"];
    }
    
	unsigned val;
	NSScanner *hexscanner;
	
	val = 0;
	hexscanner = [NSScanner scannerWithString: [commentsGroup stringValue]];
	[hexscanner scanHexInt: &val];
    
    if( val > 0)
    {
        [[NSUserDefaults standardUserDefaults] setInteger: val forKey: group];
        
        val = 0;
        hexscanner = [NSScanner scannerWithString: [commentsElement stringValue]];
        [hexscanner scanHexInt: &val];
        [[NSUserDefaults standardUserDefaults] setInteger: val forKey: element];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject: nil forKey: element];
        [[NSUserDefaults standardUserDefaults] setObject: nil forKey: group];
    }
    
    self.currentCommentsAutoFill = currentCommentsAutoFill;
}

- (IBAction) setDICOMFieldMenu: (id) sender;
{
	[commentsGroup setStringValue: [[[sender selectedItem] title] substringWithRange: NSMakeRange( 1, 6)]];
	[commentsElement setStringValue: [[[sender selectedItem] title] substringWithRange: NSMakeRange( 8, 6)]];
	
	[self setAutoComments: sender];
}

- (IBAction) databaseCleaning:(id)sender
{
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];

	if( [[olderType cellWithTag:0] state] == NSOffState && [[olderType cellWithTag:1] state] == NSOffState)
	{
		[older setState: NSOffState];
	}
	
	[defaults setBool:[older state] forKey:@"AUTOCLEANINGDATE"];
	[defaults setBool:[deleteOriginal state] forKey:@"AUTOCLEANINGDELETEORIGINAL"];
	
	[defaults setBool:[[olderType cellWithTag:0] state] forKey:@"AUTOCLEANINGDATEPRODUCED"];
	[defaults setBool:[[olderType cellWithTag:1] state] forKey:@"AUTOCLEANINGDATEOPENED"];
	[defaults setBool:[[olderType cellWithTag:2] state] forKey:@"AUTOCLEANINGCOMMENTS"];
	
	[defaults setInteger:[[commentsDeleteMatrix selectedCell] tag] forKey:@"AUTOCLEANINGDONTCONTAIN"];
	[defaults setObject:[commentsDeleteText stringValue] forKey:@"AUTOCLEANINGCOMMENTSTEXT"];
	
	[defaults setInteger:[[olderThanProduced selectedItem] tag] forKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"];
	[defaults setInteger:[[olderThanOpened selectedItem] tag] forKey:@"AUTOCLEANINGDATEOPENEDDAYS"];


//	[defaults setBool:[freeSpace state] forKey:@"AUTOCLEANINGSPACE"];
//	[defaults setBool:[[freeSpaceType cellWithTag:0] state] forKey:@"AUTOCLEANINGSPACEPRODUCED"];
//	[defaults setBool:[[freeSpaceType cellWithTag:1] state] forKey:@"AUTOCLEANINGSPACEOPENED"];
//	[defaults setInteger:[[freeSpaceSize selectedItem] tag] forKey:@"AUTOCLEANINGSPACESIZE"];
}

//- (IBAction)setMultipleScreens:(id)sender{
//	[[NSUserDefaults standardUserDefaults] setInteger:[(NSMatrix *)[sender selectedCell] tag] forKey:@"MULTIPLESCREENSDATABASE"];
//}

- (IBAction)setSeriesOrder:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:[(NSMatrix *)[sender selectedCell] tag] forKey:@"SERIESORDER"];
}


- (IBAction)setLocation:(id)sender{
	
	if ([[sender selectedCell] tag] == 1)
	{
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"DEFAULT_DATABASELOCATIONURL"] isEqualToString:@""]) [self setLocationURL: self];
		
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"DEFAULT_DATABASELOCATIONURL"] isEqualToString:@""] == NO)
		{
			BOOL isDir;
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"DEFAULT_DATABASELOCATIONURL"] isDirectory:&isDir])
			{
				NSRunAlertPanel(@"Horos Database Location", @"This location is not valid. Select another location.", @"OK", nil, nil);
				
				[locationMatrix selectCellWithTag:0];
			}
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey:@"DEFAULT_DATABASELOCATION"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
	[[[[self mainView] window] windowController] reopenDatabase];
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
    
    // TODO - It may be appropriate to request user to restart Horos, or upon trying to set a new location warn on iCloud Sync Issue.
    // This should be done before setting the new path
    
    // Workaround (weak)
    // On Horos initialization this will make Horos to check if local database folder is being synchronized over iCloud
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"ICLOUD_DRIVE_SYNC_RISK_USER_IGNORED"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) resetDate:(id) sender
{
	NSDateFormatter	*dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateStyle: NSDateFormatterShortStyle];
	[dateFormat setTimeStyle: NSDateFormatterShortStyle];
	[[NSUserDefaults standardUserDefaults] setObject: [dateFormat dateFormat] forKey:@"DBDateFormat2"];
}

- (IBAction) resetDateOfBirth:(id) sender
{
	NSDateFormatter	*dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateStyle: NSDateFormatterShortStyle];
	[[NSUserDefaults standardUserDefaults] setObject: [dateFormat dateFormat] forKey:@"DBDateOfBirthFormat2"];
}

- (IBAction)setLocationURL:(id)sender{
	//NSLog(@"setLocation URL");
		
	NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setCanChooseFiles:NO];
    [oPanel setCanChooseDirectories:YES];
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSString	*location = oPanel.URL.path;
            
            if( [[location lastPathComponent] isEqualToString:@"Horos Data"])
            {
                NSLog( @"%@", [location lastPathComponent]);
                location = [location stringByDeletingLastPathComponent];
            }
            
            if( [[location lastPathComponent] isEqualToString:@"DATABASE"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"Horos Data"])
            {
                NSLog( @"%@", [location lastPathComponent]);
                location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
            }
            
            [locationPathField setURL: [NSURL fileURLWithPath: location]];
            [[NSUserDefaults standardUserDefaults] setObject:location forKey:@"DEFAULT_DATABASELOCATIONURL"];
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"DEFAULT_DATABASELOCATION"];
            [locationMatrix selectCellWithTag:1];
        }
        else
        {
            [locationPathField setURL: 0L];
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"DEFAULT_DATABASELOCATIONURL"];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"DEFAULT_DATABASELOCATION"];
            [locationMatrix selectCellWithTag:0];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[[[self mainView] window] windowController] reopenDatabase];
        
        [[[self mainView] window] makeKeyAndOrderFront: self];
       
        // TODO - It may be appropriate to request user to restart Horos, or upon trying to set a new location warn on iCloud Sync Issue.
        // This should be done before setting the new path
        
        // Workaround (weak)
        // On Horos initialization this will make Horos to check if local database folder is being synchronized over iCloud
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"ICLOUD_DRIVE_SYNC_RISK_USER_IGNORED"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    
}

- (BOOL)useSeriesDescription{
	return  [[NSUserDefaults standardUserDefaults] boolForKey:@"useSeriesDescription"];
}

- (void)setUseSeriesDescription:(BOOL)value{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:@"useSeriesDescription"];
}

- (BOOL)splitMultiEchoMR{
	return  [[NSUserDefaults standardUserDefaults] boolForKey:@"splitMultiEchoMR"];
}

- (void)setSplitMultiEchoMR:(BOOL)value{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:@"splitMultiEchoMR"];
}
//		
//- (BOOL)combineProjectionSeries{
//	return [[NSUserDefaults standardUserDefaults] boolForKey:@"combineProjectionSeries"];
//}
//
//- (void)setCombineProjectionSeries:(BOOL)value{
//	[[NSUserDefaults standardUserDefaults] setBool:value forKey:@"combineProjectionSeries"];
//}

@end
