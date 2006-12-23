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

- (int) echoAddress: (NSString*) address port:(int) port AET:(NSString*) aet
{
	NSTask* theTask = [[[NSTask alloc]init]autorelease];
	
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/echoscu"]];

	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/echoscu"]];

	NSArray *args = [NSArray arrayWithObjects: address, [NSString stringWithFormat:@"%d", port], @"-aet", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"-aec", aet, @"-to", @"15", @"-ta", @"15", @"-td", @"15", @"-d", nil];
	
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

	
	//setup GUI
	serverList = [[[defaults arrayForKey:@"SERVERS"] mutableCopy] retain];
	
	int i;
	for( i = 0; i < [serverList count]; i++)
	{
		if( [[serverList objectAtIndex: i] valueForKey:@"QR"] == 0L)
		{
			NSMutableDictionary	*thisServer = [NSMutableDictionary dictionaryWithDictionary: [serverList objectAtIndex: i]];
			
			[thisServer setValue:[NSNumber numberWithBool:YES] forKey:@"QR"];
			
			[serverList replaceObjectAtIndex:i withObject:thisServer];
		}
	}
	[self resetTest];
	
	if (serverList) {
		[serverTable reloadData];
	}
	osirixServerList = [[[defaults arrayForKey:@"OSIRIXSERVERS"] mutableCopy] retain];
	if (osirixServerList) {
		[osirixServerTable reloadData];
	}
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
}

- (void)dealloc{
	NSLog(@"dealloc OSILocationsPreferencePanePref");
	
	[serverList release];
	[osirixServerList release];
	[stringEncoding release];
	[super dealloc];
}

- (IBAction) newServer:(id)sender
{
    NSMutableDictionary *aServer = [[NSMutableDictionary alloc] init];
    [aServer setObject:@"149.142.98.136" forKey:@"Address"];
    [aServer setObject:@"PACSARCH" forKey:@"AETitle"];
    [aServer setObject:@"4444" forKey:@"Port"];
	[aServer setObject:[NSNumber numberWithBool:YES] forKey:@"QR"];
    [aServer setObject:@"PACSARCH PACS Server" forKey:@"Description"];
	[aServer setObject:[NSNumber numberWithInt:9] forKey:@"Transfer Syntax"];
    
    [serverList addObject:aServer];
    
    [aServer release];
    
    [serverTable reloadData];
	
//Set to edit new entry
	[serverTable selectRow:[serverList count] - 1 byExtendingSelection:NO];
	[serverTable editColumn:0 row:[serverList count] - 1  withEvent:nil select:YES];
	
	[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	
	[self resetTest];
}

- (IBAction) osirixNewServer:(id)sender
{
    NSMutableDictionary *aServer = [[NSMutableDictionary alloc] init];
    [aServer setObject:@"osirix.hcuge.ch" forKey:@"Address"];
    [aServer setObject:@"OsiriX PACS Server" forKey:@"Description"];
    
    [osirixServerList addObject:aServer];
    
    [aServer release];
    
    [osirixServerTable reloadData];
	
//Set to edit new entry
	[osirixServerTable selectRow:[osirixServerList count] - 1 byExtendingSelection:NO];
	[osirixServerTable editColumn:0 row:[osirixServerList count] - 1  withEvent:nil select:YES];
	
	[[NSUserDefaults standardUserDefaults] setObject:osirixServerList forKey:@"OSIRIXSERVERS"];
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
}

//****** TABLEVIEW

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( [aTableView tag] == 0)	return [serverList count];
	if( [aTableView tag] == 1)	return [osirixServerList count];
	
	return 0;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if( [tableView tag] == 0)
	{
		[serverList sortUsingDescriptors: [serverTable sortDescriptors]];
		[serverTable reloadData];
	}
	
	if( [tableView tag] == 1)
	{
		[osirixServerList sortUsingDescriptors: [osirixServerTable sortDescriptors]];
		[osirixServerTable reloadData];
	}
}
- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState)
	{ 
		NSMutableDictionary *theRecord;	   

		if( [aTableView tag] == 0)
		{
			NSParameterAssert(rowIndex >= 0 && rowIndex < [serverList count]);
			
			theRecord = [[serverList objectAtIndex:rowIndex] mutableCopy];
			
			if( [[aTableColumn identifier] isEqualToString:@"AETitle"])
			{
				NSString	*aet = anObject;
	
				if( [aet length] >= 16) aet = [aet substringToIndex: 16];
	
				[theRecord setObject:aet forKey:[aTableColumn identifier]];
			}
			else [theRecord setObject:anObject forKey:[aTableColumn identifier]];
			
			[serverList replaceObjectAtIndex:rowIndex withObject: theRecord];
			
			[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
		}
		
		if( [aTableView tag] == 1)
		{
			NSParameterAssert(rowIndex >= 0 && rowIndex < [osirixServerList count]);
			
			theRecord = [[osirixServerList objectAtIndex:rowIndex] mutableCopy];
			
			[theRecord setObject:anObject forKey:[aTableColumn identifier]];
			
			[osirixServerList replaceObjectAtIndex:rowIndex withObject: theRecord];
			
			[[NSUserDefaults standardUserDefaults] setObject:osirixServerList forKey:@"OSIRIXSERVERS"];
		}
		
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	}
}

- (void) resetTest
{
	int i;
	
	for( i = 0 ; i < [serverList count]; i++)
	{
		NSMutableDictionary *aServer = [[serverList objectAtIndex: i] mutableCopy];
		
		[aServer removeObjectForKey:@"test"];
		[serverList replaceObjectAtIndex: i withObject: aServer];
	}
	
	[serverTable reloadData];
}

- (IBAction) test:(id) sender
{
	int i;
	int status;
	
	for( i = 0 ; i < [serverList count]; i++)
	{
		NSMutableDictionary *aServer = [[serverList objectAtIndex: i] mutableCopy];
		
		int numberPacketsReceived = 0;
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || SimplePing( [[aServer objectForKey:@"Address"] UTF8String], 1, 5, 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0)
		{
			if( [self echoAddress:[aServer objectForKey:@"Address"] port:[[aServer objectForKey:@"Port"] intValue] AET:[aServer objectForKey:@"AETitle"]] == 0) status = 0;
			else status = -1;
		}
		else status = -2;
		
		[aServer setObject:[NSNumber numberWithInt: status] forKey:@"test"];
		[serverList replaceObjectAtIndex:i withObject: aServer];
	}
	
	[serverTable reloadData];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [aTableView tag] == 0)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [serverList count]);
		
		NSMutableDictionary *theRecord = [serverList objectAtIndex:rowIndex];
		
		if( [[aTableColumn identifier] isEqual:@"Address"] == YES)
		{
			switch( [[theRecord objectForKey:@"test"] intValue])
			{
				case -1:
					[aCell setTextColor: [NSColor orangeColor]];
				break;
				
				case -2:
					[aCell setTextColor: [NSColor redColor]];
				break;
				
				case 0:
					[aCell setTextColor: [NSColor blackColor]];
				break;
			}
		}
	}
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	NSMutableDictionary *theRecord;
	
	if( [aTableView tag] == 0)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [serverList count]);
		
		theRecord = [serverList objectAtIndex:rowIndex];
		
		if( [[aTableColumn identifier] isEqual:@"Port"] == YES)
		{
			long    value;
			BOOL	update = NO;
			
			value = [[theRecord objectForKey:[aTableColumn identifier]] intValue];
			
			if( value < 1) {	value = 1;	update = YES;}
			if( value > 131072) {	value = 131072;	update = YES;}
			
			if( update)
			{
				theRecord = [[serverList objectAtIndex:rowIndex] mutableCopy];
				[theRecord setObject:[[NSNumber numberWithLong:value] stringValue] forKey:[aTableColumn identifier]];
				[serverList replaceObjectAtIndex:rowIndex withObject: theRecord];
				
				[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
			}
		}
		
		return [theRecord objectForKey:[aTableColumn identifier]];
	}

	if( [aTableView tag] == 1)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [osirixServerList count]);
		
		theRecord = [osirixServerList objectAtIndex:rowIndex];
		
		return [theRecord objectForKey:[aTableColumn identifier]];
	}

	return 0L;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) return YES;
	else return NO;
}

- (void) deleteSelectedRow:(id)sender
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState)
	{
		if( NSRunInformationalAlertPanel(NSLocalizedString(@"Delete Server", 0L), NSLocalizedString(@"Are you sure you want to delete the selected server?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil) == NSAlertDefaultReturn)
		{
			if( [sender tag] == 0)
			{
				[serverList removeObjectAtIndex:[serverTable selectedRow]];
				[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
				
				[serverTable reloadData];
			}
			
			if( [sender tag] == 1)
			{
				[osirixServerList removeObjectAtIndex:[osirixServerTable selectedRow]];
				[[NSUserDefaults standardUserDefaults] setObject:osirixServerList forKey:@"OSIRIXSERVERS"];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:self];
				
				[osirixServerTable reloadData];
			}
		}
	}
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


@end
