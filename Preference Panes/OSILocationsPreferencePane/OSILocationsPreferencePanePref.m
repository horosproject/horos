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
* Version 2.3
*	20051215	LP	Added Transfer Syntax Option for Servers 
*****************************************************************************************************/

#import "OSILocationsPreferencePanePref.h"
#include "SimplePing.h"

/************ Transfer Syntaxes *******************
	@"Explicit Little Endian"
	@"JPEG 2000 Lossless"
	@"JPEG 2000 Lossy 10:1"
	@"JPEG 2000 Lossy 20:1"
	@"JPEG 2000 Lossy 50:1"
	@"JPEG Lossless"
	@"JPEG High Quality (9)"	
	@"JPEG Medium High Quality (8)"	
	@"JPEG Medium Quality (7)"
	@"Implicit"
	@"RLE"
*************************************************/

@implementation OSILocationsPreferencePanePref

- (void) checkUniqueAETitle
{
	int i, x;
	
	NSArray *serverList = [dicomNodes arrangedObjects];
	
	for( x = 0; x < [serverList count]; x++)
	{
		int value = [[[serverList objectAtIndex: x] valueForKey:@"Port"] intValue];
		if( value < 1) value = 1;
		if( value > 131072) value = 131072;
		[[serverList objectAtIndex: x] setValue: [NSNumber numberWithInt: value] forKey: @"Port"];		
		[[serverList objectAtIndex: x] setValue: [[serverList objectAtIndex: x] valueForKey:@"AETitle"] forKey:@"AETitle"];
		
		NSString *currentAETitle = [[serverList objectAtIndex: x] valueForKey: @"AETitle"];
		
		for( i = 0; i < [serverList count]; i++)
		{
			if( i != x)
			{
				if( [currentAETitle isEqualToString: [[serverList objectAtIndex: i] valueForKey: @"AETitle"]])
				{
					NSRunInformationalAlertPanel(NSLocalizedString(@"Same AETitle", 0L), [NSString stringWithFormat: NSLocalizedString(@"This AETitle is not unique: %@. AETitles should be unique, otherwise Q&R (C-Move SCP/SCU) can fail.", 0L), currentAETitle], NSLocalizedString(@"OK",nil), nil, nil);
					
					i = [serverList count];
					x = [serverList count];
				}
			}
		}
	}
}

- (int) echoAddress: (NSString*) address port:(int) port AET:(NSString*) aet
{
	NSTask* theTask = [[[NSTask alloc]init]autorelease];
	
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/echoscu"]];

	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/echoscu"]];

	NSArray *args = [NSArray arrayWithObjects: address, [NSString stringWithFormat:@"%d", port], @"-aet", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"-aec", aet, @"-to", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-ta", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-td", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-d", nil];
	
	NSLog( [args description]);
	
	[theTask setArguments:args];
	[theTask launch];
	[theTask waitUntilExit];
	
	return [theTask terminationStatus];
}

- (void) enableControls: (BOOL) val
{
	[characterSetPopup setEnabled: val];
	[addServerDICOM setEnabled: val];
	[addServerSharing setEnabled: val];
	[verifyPing setEnabled: val];
	[searchDICOMBonjourNodes setEnabled: val];
	[addLocalPath setEnabled: val];
	[loadNodes setEnabled: val];
	
	[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey:@"syncDICOMNodes"] forKey: @"syncDICOMNodes"];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.locations"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];

	stringEncoding = [[defaults stringForKey:@"STRINGENCODING"] retain];
	int tag = 0;
	 if( [stringEncoding isEqualToString: @"ISO_IR 192"])	//UTF8
		tag = 0;
	else if ( [stringEncoding isEqualToString: @"ISO_IR 100"])
		tag = 1;
	else if( [stringEncoding isEqualToString: @"ISO_IR 101"])
		tag =  2;
	else if( [stringEncoding isEqualToString: @"ISO_IR 109"])	
		tag =  3;
	else if( [stringEncoding isEqualToString: @"ISO_IR 110"])
		tag =  4;
	else if( [stringEncoding isEqualToString: @"ISO_IR 127"])	
		tag =  5 ;
	else if( [stringEncoding isEqualToString: @"ISO_IR 144"])		
		tag =  6;
	else if( [stringEncoding isEqualToString: @"ISO_IR 126"])	
		tag =  7;
	else if( [stringEncoding isEqualToString: @"ISO_IR 138"])		
		tag =  8 ;
	else if( [stringEncoding isEqualToString: @"GB18030"])	
		tag =  9;
	else if( [stringEncoding isEqualToString: @"ISO 2022 IR 149"])
		tag =  10;
	else if( [stringEncoding isEqualToString: @"ISO 2022 IR 13"])	
		tag =  11;
	else if( [stringEncoding isEqualToString: @"ISO_IR 13"])	
		tag =  12 ;
	else if( [stringEncoding isEqualToString: @"ISO 2022 IR 87"])	
		tag =  13 ;
	else if( [stringEncoding isEqualToString: @"ISO_IR 1166"])
		tag =  14 ;
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 100" forKey:@"STRINGENCODING"];
		tag = 1;
	}
			
	[characterSetPopup selectItemAtIndex:tag];
	
	[self checkUniqueAETitle];
	
	[self resetTest];
	
	int i;
	for( i = 0 ; i < [[dicomNodes arrangedObjects] count]; i++)
	{
		NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: i];
		if( [aServer valueForKey:@"Send"] == 0L)
			[aServer setValue:[NSNumber numberWithBool:YES] forKey:@"Send"];
	}
}

- (void) willUnselect
{
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
}

- (void)dealloc{
	NSLog(@"dealloc OSILocationsPreferencePanePref");
	
	[stringEncoding release];
	[super dealloc];
}

- (IBAction) newServer:(id)sender
{
    NSMutableDictionary *aServer = [NSMutableDictionary dictionary];
    [aServer setObject:@"127.0.0.1" forKey:@"Address"];
    [aServer setObject:@"AETITLE" forKey:@"AETitle"];
    [aServer setObject:@"4096" forKey:@"Port"];
	[aServer setObject:[NSNumber numberWithBool:YES] forKey:@"QR"];
	[aServer setObject:[NSNumber numberWithBool:YES] forKey:@"Send"];
    [aServer setObject:@"Description" forKey:@"Description"];
	[aServer setObject:[NSNumber numberWithInt:0] forKey:@"Transfer Syntax"];
    
	[dicomNodes addObject:aServer];
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	
	[[dicomNodes tableView] scrollRowToVisible: [[dicomNodes tableView] selectedRow]];
	
	[self resetTest];
}

- (IBAction) osirixNewServer:(id)sender
{
    NSMutableDictionary *aServer = [NSMutableDictionary dictionary];
    [aServer setObject:@"osirix.hcuge.ch" forKey:@"Address"];
    [aServer setObject:@"OsiriX PACS Server" forKey:@"Description"];
    
    [osiriXServers addObject: aServer];
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	
	[[osiriXServers tableView] scrollRowToVisible: [[osiriXServers tableView] selectedRow]];
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
}

//****** TABLEVIEW

- (void) resetTest
{
	int i;
	
	for( i = 0 ; i < [[dicomNodes arrangedObjects] count]; i++)
	{
		NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: i];
		[aServer removeObjectForKey:@"test"];
	}
}

- (IBAction) OsiriXDBsaveAs:(id) sender;
{
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];

	[sPanel setRequiredFileType:@"plist"];
	
	if ([sPanel runModalForDirectory:0L file:NSLocalizedString(@"OsiriXDB.plist", nil)] == NSFileHandlingPanelOKButton)
	{
		[[osiriXServers arrangedObjects] writeToFile:[sPanel filename] atomically: YES];
	}
}

- (IBAction) refreshNodesOsiriXDB: (id) sender
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncOsiriXDB"])
	{
		NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncOsiriXDBURL"]];
		
		if( url)
		{
			NSArray	*r = [NSArray arrayWithContentsOfURL: url];
			
			if( r)
			{
				[osiriXServers removeObjects: [osiriXServers arrangedObjects]];
				[osiriXServers addObjects: r];
				
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
			}
			else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"Cannot download data from this URL.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"This URL is invalid. Check syntax.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (IBAction) OsiriXDBloadFrom:(id) sender;
{
	NSOpenPanel		*sPanel		= [NSOpenPanel openPanel];
	
	[self resetTest];
	
	[sPanel setRequiredFileType:@"plist"];
	
	if ([sPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"plist"]] == NSFileHandlingPanelOKButton)
	{
		NSArray	*r = [NSArray arrayWithContentsOfFile: [sPanel filename]];
		
		if( r)
		{
			if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load locations", 0L), NSLocalizedString(@"Should I add or replace this locations list to the current list?", 0L), NSLocalizedString(@"Add",nil), NSLocalizedString(@"Replace",nil), nil) == NSAlertDefaultReturn)
			{
				
			}
			else [osiriXServers removeObjects: [osiriXServers arrangedObjects]];
			
			[osiriXServers addObjects: r];
			
			int i, x;
			
			for( i = 0; i < [[osiriXServers arrangedObjects] count]; i++)
			{
				NSDictionary	*server = [[osiriXServers arrangedObjects] objectAtIndex: i];
				
				for( x = 0; x < [[osiriXServers arrangedObjects] count]; x++)
				{
					NSDictionary	*c = [[osiriXServers arrangedObjects] objectAtIndex: x];
					
					if( c != server)
					{
						if( [[server valueForKey:@"Address"] isEqualToString: [c valueForKey:@"Address"]] &&
							[[server valueForKey:@"Description"] isEqualToString: [c valueForKey:@"Description"]])
							{
								[osiriXServers removeObjectAtArrangedObjectIndex: i];
								i--;
								x = [[osiriXServers arrangedObjects] count];
							}
					}
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		}
	}
}


- (IBAction) saveAs:(id) sender;
{
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];

	[sPanel setRequiredFileType:@"plist"];
	
	[self resetTest];
	
	if ([sPanel runModalForDirectory:0L file:NSLocalizedString(@"DICOMNodes.plist", nil)] == NSFileHandlingPanelOKButton)
	{
		[[dicomNodes arrangedObjects] writeToFile:[sPanel filename] atomically: YES];
	}
}

- (IBAction) refreshNodesListURL: (id) sender
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncDICOMNodes"])
	{
		NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncDICOMNodesURL"]];
		
		if( url)
		{
			NSArray	*r = [NSArray arrayWithContentsOfURL: url];
			
			if( r)
			{
				[dicomNodes removeObjects: [dicomNodes arrangedObjects]];
				[dicomNodes addObjects: r];
				
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
			}
			else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"Cannot download data from this URL.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"This URL is invalid. Check syntax.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (IBAction) loadFrom:(id) sender;
{
	NSOpenPanel		*sPanel		= [NSOpenPanel openPanel];
	
	[self resetTest];
	
	[sPanel setRequiredFileType:@"plist"];
	
	if ([sPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"plist"]] == NSFileHandlingPanelOKButton)
	{
		NSArray	*r = [NSArray arrayWithContentsOfFile: [sPanel filename]];
		
		if( r)
		{
			if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load locations", 0L), NSLocalizedString(@"Should I add or replace this locations list to the current list?", 0L), NSLocalizedString(@"Add",nil), NSLocalizedString(@"Replace",nil), nil) == NSAlertDefaultReturn)
			{
				
			}
			else [dicomNodes removeObjects: [dicomNodes arrangedObjects]];
			
			[dicomNodes addObjects: r];
			
			int i, x;
			
			for( i = 0; i < [[dicomNodes arrangedObjects] count]; i++)
			{
				NSDictionary	*server = [[dicomNodes arrangedObjects] objectAtIndex: i];
				
				for( x = 0; x < [[dicomNodes arrangedObjects] count]; x++)
				{
					NSDictionary	*c = [[dicomNodes arrangedObjects] objectAtIndex: x];
					
					if( c != server)
					{
						if( [[server valueForKey:@"AETitle"] isEqualToString: [c valueForKey:@"AETitle"]] &&
							[[server valueForKey:@"Address"] isEqualToString: [c valueForKey:@"Address"]] &&
							[[server valueForKey:@"Port"] intValue] == [[c valueForKey:@"Port"] intValue])
							{
								[dicomNodes removeObjectAtArrangedObjectIndex: i];
								i--;
								x = [[dicomNodes arrangedObjects] count];
							}
					}
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		}
	}
	
	[self resetTest];
}

- (IBAction) test:(id) sender
{
	int i;
	int status;
	int selectedRow = [[dicomNodes tableView] selectedRow];
	
	[progress startAnimation: self];
	
	NSArray		*serverList = [dicomNodes arrangedObjects];
	
	for( i = 0 ; i < [serverList count]; i++)
	{
		NSMutableDictionary *aServer = [serverList objectAtIndex: i];
		
		[[dicomNodes tableView] selectRow: i byExtendingSelection: NO];
		[[dicomNodes tableView] display];
		
		int numberPacketsReceived = 0;
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || (SimplePing( [[aServer objectForKey:@"Address"] UTF8String], 1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"], 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0))
		{
			if( [self echoAddress:[aServer objectForKey:@"Address"] port:[[aServer objectForKey:@"Port"] intValue] AET:[aServer objectForKey:@"AETitle"]] == 0) status = 0;
			else status = -1;
		}
		else status = -2;
		
		[aServer setObject:[NSNumber numberWithInt: status] forKey:@"test"];
	}
	
	[progress stopAnimation: self];
	
	[[dicomNodes tableView] selectRow: selectedRow byExtendingSelection: NO];
	[[dicomNodes tableView] display];
}


- (IBAction) setStringEncoding:(id)sender{
	NSString *encoding;

	switch ([[sender selectedItem] tag]){
		case 0: encoding = @"ISO_IR 192";
			break;
		case 1: encoding = @"ISO_IR 100";
			break;
		case 2: encoding = @"ISO_IR 101";
			break;
		case 3: encoding = @"ISO_IR 109";
			break;
		case 4: encoding = @"ISO_IR 110";
			break;
		case 5: encoding = @"ISO_IR 127";
			break;
		case 6: encoding = @"ISO_IR 144";
			break;
		case 7: encoding = @"ISO_IR 126";
			break;
		case 8: encoding = @"ISO_IR 138";
			break;
		case 9: encoding = @"GB18030";
			break;
		
		case 10: encoding = @"ISO 2022 IR 149";
			break;
		case 11: encoding = @"ISO 2022 IR 13";
			break;
		case 12: encoding = @"ISO_IR 13";
			break;
		case 13: encoding = @"ISO 2022 IR 87";
			break;
		case 14: encoding = @"ISO_IR 1166";
			break;
		default: encoding = @"ISO_IR 100";
			break;
	}
	[[NSUserDefaults standardUserDefaults] setObject:encoding forKey:@"STRINGENCODING"];
	[stringEncoding release];
	stringEncoding = [encoding retain];
}

- (IBAction)setTransferSyntax:(id)sender{
	//NSLog (@"sender: %@", [sender description]);
}

- (IBAction) addPath:(id) sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];

    [oPanel setCanChooseFiles:YES];
    [oPanel setCanChooseDirectories:YES];

	if ([oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"sql"]] == NSFileHandlingPanelOKButton)
	{
		NSString	*location = [oPanel filename];
		
		if( [[location lastPathComponent] isEqualToString:@"OsiriX Data"])
		{
			location = [location stringByDeletingLastPathComponent];
		}

		if( [[location lastPathComponent] isEqualToString:@"DATABASE"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"OsiriX Data"])
		{
			location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
		}
		
		BOOL isDirectory;
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: location isDirectory: &isDirectory])
		{
			NSDictionary	*dict;
			
			if( isDirectory) dict = [NSDictionary dictionaryWithObjectsAndKeys: location, @"Path", [[location lastPathComponent] stringByAppendingString:@" DB"], @"Description", 0L];
				
			[localPaths addObject: dict];
			
			[[localPaths tableView] scrollRowToVisible: [[localPaths tableView] selectedRow]];
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		}
	}
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
}
@end
