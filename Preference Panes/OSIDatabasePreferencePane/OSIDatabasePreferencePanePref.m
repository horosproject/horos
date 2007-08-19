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

/***************************************** Modifications *********************************************

Version 2.3
	20060116	LP	Added CombineProjectionSeries and splitMultiechoMR options
Version 2.4
	20060608	LP	Added DICOM SR option for reports
	
*****************************************************************************************************/

#import "OSIDatabasePreferencePanePref.h"
#import "PreferencePaneController.h"

@implementation OSIDatabasePreferencePanePref

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
	
	if( aView == _authView) return;

    if( [aView isKindOfClass: [NSControl class]])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }
	
	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
	
}

- (void) enableControls: (BOOL) val
{
	[self checkView: [self mainView] :val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) dealloc
{	
	NSLog(@"dealloc OSIDatabasePreferencePanePref");
	
	[super dealloc];
}

- (NSString*) pathResolved:(NSString*) inPath
{
	CFStringRef resolvedPath = nil;
	CFURLRef	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)inPath, kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != NULL) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, &targetIsFolder, &wasAliased) == noErr && wasAliased) {
				CFURLRef resolvedurl = CFURLCreateFromFSRef(NULL /*allocator*/, &fsRef);
				if (resolvedurl != NULL) {
					resolvedPath = CFURLCopyFileSystemPath(resolvedurl, kCFURLPOSIXPathStyle);
					CFRelease(resolvedurl);
				}
			}
		}
		CFRelease(url);
	}
	
	if( resolvedPath == 0L) return inPath;
	else return (NSString *)resolvedPath;
}

- (void) buildPluginsMenu
{
	NSString	*appSupport = @"Library/Application Support/OsiriX/Plugins";
	NSString	*appPath = [[NSBundle mainBundle] builtInPlugInsPath];
    NSString	*userPath = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
    NSString	*sysPath = [@"/" stringByAppendingPathComponent:appSupport];
	Class		filterClass;
	
	NSArray *paths = [NSArray arrayWithObjects:appPath, userPath, sysPath, nil];
	
	NSEnumerator *pathEnum = [paths objectEnumerator];
    NSString *path;
	
	int numberOfReportPlugins = 0;
	while ( path = [pathEnum nextObject] )
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		
		while ( name = [e nextObject] )
		{
			
			if ( [[name pathExtension] isEqualToString:@"plugin"] )
			{
				NSBundle *plugin = [NSBundle bundleWithPath:[self pathResolved:[path stringByAppendingPathComponent:name]]];
				
				if ( filterClass = [plugin principalClass])
				{
					if ([[[plugin infoDictionary] objectForKey:@"pluginType"] isEqualToString:@"Report"])
					{
						[reportsMode addItemWithTitle: [[plugin infoDictionary] objectForKey:@"CFBundleExecutable"]];
						[[reportsMode lastItem] setIndentationLevel:1];
						numberOfReportPlugins++;
					}
				}
			}
		}
	}
	
	if( numberOfReportPlugins <= 0)
	{
		[reportsMode removeItemAtIndex:[reportsMode indexOfItem:[reportsMode lastItem]]];
		[reportsMode removeItemAtIndex:[reportsMode indexOfItem:[reportsMode lastItem]]];
	}
	else
	{
		if(numberOfReportPlugins == 1)
			[[reportsMode itemAtIndex:5] setTitle:@"Plugin"];
		[reportsMode setAutoenablesItems:NO];
		[[reportsMode itemAtIndex:5] setEnabled:NO];
	}
}

- (void) mainViewDidLoad
{
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.database"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];


//	[[scrollView verticalScroller] setFloatValue: 0]; 
////	[[scrollView verticalScroller] setFloatValue:0.0 knobProportion:0.0];
//	[scrollView setVerticalScroller: [scrollView verticalScroller]];
	
//	[[scrollView contentView] scrollToPoint: NSMakePoint(600,600)];
	
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	//setup GUI
	[copyDatabaseOnOffButton setState:[defaults boolForKey:@"COPYDATABASE"]];
	
//	[displayAllStudies setState:[defaults boolForKey:@"KeepStudiesOfSamePatientTogether"]];
	
	long locationValue = [defaults integerForKey:@"DEFAULT_DATABASELOCATION"];
	
	[locationMatrix selectCellWithTag:locationValue];
	[locationURLField setStringValue:[defaults stringForKey:@"DEFAULT_DATABASELOCATIONURL"]];
	[locationPathField setURL: [NSURL URLWithString: [defaults stringForKey:@"DEFAULT_DATABASELOCATIONURL"]]];
	
//	[copyDatabaseModeMatrix setEnabled:[defaults boolForKey:@"COPYDATABASE"]];
	[copyDatabaseModeMatrix selectCellWithTag:[defaults integerForKey:@"COPYDATABASEMODE"]];
	[localizerOnOffButton setState:[defaults boolForKey:@"NOLOCALIZER"]];
//	[multipleScreensMatrix selectCellWithTag:[defaults integerForKey:@"MULTIPLESCREENSDATABASE"]];
	[seriesOrderMatrix selectCellWithTag:[defaults integerForKey:@"SERIESORDER"]];
	
	
	// COMMENTS
	
	[commentsAutoFill setState:[defaults boolForKey:@"COMMENTSAUTOFILL"]];
	[commentsGroup setStringValue:[NSString stringWithFormat:@"%04X", [[defaults stringForKey:@"COMMENTSGROUP"] intValue]]];
	[commentsElement setStringValue:[NSString stringWithFormat:@"%04X", [[defaults stringForKey:@"COMMENTSELEMENT"] intValue]]];
	
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
	
	[freeSpace setState:[defaults boolForKey:@"AUTOCLEANINGSPACE"]];
	[[freeSpaceType cellWithTag:0] setState:[defaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"]];
	[[freeSpaceType cellWithTag:1] setState:[defaults boolForKey:@"AUTOCLEANINGSPACEOPENED"]];
	[freeSpaceSize selectItemWithTag:[[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue]];
	
	NSDictionary *dict = [defaults objectForKey:@"COLUMNSDATABASE"];
	NSArray *titleArray = [[columnsDisplay cells] valueForKey:@"title"];
	
	NSEnumerator	*enumerator = [dict keyEnumerator];
	NSString		*key;
	
	while( key = [enumerator nextObject])
	{
		long index = [titleArray indexOfObject:key];
		
		if( index != NSNotFound)
		{
			long val = [[dict valueForKey: key] intValue];
			[[[columnsDisplay cells] objectAtIndex: index] setState: val];
		}
	}
	
	[[columnsDisplay cellWithTag:0] setState: ![defaults boolForKey:@"HIDEPATIENTNAME"]];
}

- (IBAction) setReportMode:(id) sender
{
	// report mode int value
	// 0 : Microsoft Word
	// 1 : TextEdit
	// 2 : Pages
	// 3 : Plugin
	// 4 : DICOM SR
	
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

- (IBAction) setAutoComments:(id) sender
{
	// COMMENTS
	
	[[NSUserDefaults standardUserDefaults] setBool: [commentsAutoFill state] forKey:@"COMMENTSAUTOFILL"];
	
	unsigned		val;
	NSScanner	*hexscanner;
	
	val = 0;
	hexscanner = [NSScanner scannerWithString:[commentsGroup stringValue]];
	[hexscanner scanHexInt:&val];
	[[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"COMMENTSGROUP"];
	
	val = 0;
	hexscanner = [NSScanner scannerWithString:[commentsElement stringValue]];
	[hexscanner scanHexInt:&val];
	[[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"COMMENTSELEMENT"];
	
	[commentsGroup setStringValue:[NSString stringWithFormat:@"%04X", [[[NSUserDefaults standardUserDefaults] stringForKey:@"COMMENTSGROUP"] intValue]]];
	[commentsElement setStringValue:[NSString stringWithFormat:@"%04X", [[[NSUserDefaults standardUserDefaults] stringForKey:@"COMMENTSELEMENT"] intValue]]];
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


	[defaults setBool:[freeSpace state] forKey:@"AUTOCLEANINGSPACE"];
	[defaults setBool:[[freeSpaceType cellWithTag:0] state] forKey:@"AUTOCLEANINGSPACEPRODUCED"];
	[defaults setBool:[[freeSpaceType cellWithTag:1] state] forKey:@"AUTOCLEANINGSPACEOPENED"];
	[defaults setInteger:[[freeSpaceSize selectedItem] tag] forKey:@"AUTOCLEANINGSPACESIZE"];
}

//- (IBAction)setMultipleScreens:(id)sender{
//	[[NSUserDefaults standardUserDefaults] setInteger:[(NSMatrix *)[sender selectedCell] tag] forKey:@"MULTIPLESCREENSDATABASE"];
//}

- (IBAction)setSeriesOrder:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:[(NSMatrix *)[sender selectedCell] tag] forKey:@"SERIESORDER"];
}

-(IBAction)setDisplayPatientName:(id)sender
{
	if( [[sender selectedCell] tag] == 0) [[NSUserDefaults standardUserDefaults] setBool:![[sender selectedCell] state] forKey:@"HIDEPATIENTNAME"];
	else
	{
		NSArray				*titleArray = [[columnsDisplay cells] valueForKey:@"title"];
		long				i;
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithCapacity: 0];
		
		for( i = 0; i < [titleArray count]; i++)
		{
			NSString*	key = [titleArray objectAtIndex: i];
			
			if( [key length] > 0)
				[dict setValue:[NSNumber numberWithInt:[[[columnsDisplay cells] objectAtIndex: i] state]] forKey: key];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"COLUMNSDATABASE"];
	}
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
				NSRunAlertPanel(@"OsiriX Database Location", @"This location is not valid. Select another location.", @"OK", nil, nil);
				
				[locationMatrix selectCellWithTag:0];
			}
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey:@"DEFAULT_DATABASELOCATION"];
	
	[[[[self mainView] window] windowController] reopenDatabase];
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
}

- (IBAction) resetDate:(id) sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey: NSShortTimeDateFormatString] forKey:@"DBDateFormat"];
}

- (IBAction) resetDateOfBirth:(id) sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString] forKey:@"DBDateOfBirthFormat"];
}

- (IBAction)setLocationURL:(id)sender{
	//NSLog(@"setLocation URL");
		
	NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
	long				result;
	
    [oPanel setCanChooseFiles:NO];
    [oPanel setCanChooseDirectories:YES];
	
	result = [oPanel runModalForDirectory:0L file:nil types: 0L];
    
    if (result == NSOKButton)
	{
		NSString	*location = [oPanel directory];
		
		if( [[location lastPathComponent] isEqualToString:@"OsiriX Data"])
		{
			NSLog( [location lastPathComponent]);
			location = [location stringByDeletingLastPathComponent];
		}
		
		if( [[location lastPathComponent] isEqualToString:@"DATABASE"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"OsiriX Data"])
		{
			NSLog( [location lastPathComponent]);
			location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
		}
		
		[locationURLField setStringValue: location];
		[locationPathField setURL: [NSURL URLWithString: location]];
		[[NSUserDefaults standardUserDefaults] setObject:location forKey:@"DEFAULT_DATABASELOCATIONURL"];
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"DEFAULT_DATABASELOCATION"];
		[locationMatrix selectCellWithTag:1];
	}	
	else 
	{
		[locationURLField setStringValue: 0L];
		[locationPathField setURL: 0L];
		[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"DEFAULT_DATABASELOCATIONURL"];
		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"DEFAULT_DATABASELOCATION"];
		[locationMatrix selectCellWithTag:0];
	}
	
	[[[[self mainView] window] windowController] reopenDatabase];
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
}

- (IBAction) setCopyDatabaseMode:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey:@"COPYDATABASEMODE"];
}
- (IBAction)setCopyDatabaseOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"COPYDATABASE"];
//	[copyDatabaseModeMatrix setEnabled:[sender state]];
}
- (IBAction)setLocalizerOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"NOLOCALIZER"];

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
