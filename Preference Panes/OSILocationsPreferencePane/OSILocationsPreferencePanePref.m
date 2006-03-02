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

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	//setup GUI
	serverList = [[[defaults arrayForKey:@"SERVERS"] mutableCopy] retain];
	if (serverList) {
		[serverTable reloadData];
	}
	osirixServerList = [[[defaults arrayForKey:@"OSIRIXSERVERS"] mutableCopy] retain];
	if (osirixServerList) {
		[osirixServerTable reloadData];
	}
	stringEncoding = [[defaults stringForKey:@"STRINGENCODING"] retain];
	int tag = 0;
	if ( stringEncoding == @"ISO_IR 100")
		tag = 0;
	else if( stringEncoding == @"ISO_IR 101")
		tag =  1;
	else if( stringEncoding == @"ISO_IR 109")	
		tag =  2;
	else if( stringEncoding ==	@"ISO_IR 110")
		tag =  3;
	else if( stringEncoding ==@"ISO_IR 127")	
		tag =  4 ;
	else if( stringEncoding  == @"ISO_IR 144")		
		tag =  5;
	else if( stringEncoding == @"ISO_IR 126")	
		tag =  6;
	else if( stringEncoding == @"ISO_IR 138")		
		tag =  7 ;
	else if( stringEncoding == @"GB18030")	
		tag =  8 ;
	else if( stringEncoding  == @"ISO_IR 192")	
		tag =  9;
	else if( stringEncoding == @"ISO 2022 IR 149")
		tag =  10;
	else if( stringEncoding  == @"ISO 2022 IR 13")	
		tag =  11;
	else if( stringEncoding == @"ISO_IR 13"	)	
		tag =  12 ;
	else if( stringEncoding == @"ISO 2022 IR 87")	
		tag =  13 ;
	else if( stringEncoding == @"ISO_IR 1166")
		tag =  14 ;
			
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
    [aServer setObject:@"PACSARCH PACS Server" forKey:@"Description"];
	[aServer setObject:[NSNumber numberWithInt:0] forKey:@"Transfer Syntax"];
    
    [serverList addObject:aServer];
    
    [aServer release];
    
    [serverTable reloadData];
	
//Set to edit new entry
	[serverTable selectRow:[serverList count] - 1 byExtendingSelection:NO];
	[serverTable editColumn:0 row:[serverList count] - 1  withEvent:nil select:YES];
	
	[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerArray has changed" object:self];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:self];
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
	NSMutableDictionary *theRecord;	   

	if( [aTableView tag] == 0)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [serverList count]);
		
		theRecord = [[serverList objectAtIndex:rowIndex] mutableCopy];

		[theRecord setObject:anObject forKey:[aTableColumn identifier]];
		
		[serverList replaceObjectAtIndex:rowIndex withObject: theRecord];
		
		[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerArray has changed" object:self];
	}
	
	if( [aTableView tag] == 1)
	{
		NSParameterAssert(rowIndex >= 0 && rowIndex < [osirixServerList count]);
		
		theRecord = [[osirixServerList objectAtIndex:rowIndex] mutableCopy];
		
		[theRecord setObject:anObject forKey:[aTableColumn identifier]];
		
		[osirixServerList replaceObjectAtIndex:rowIndex withObject: theRecord];
		
		[[NSUserDefaults standardUserDefaults] setObject:osirixServerList forKey:@"OSIRIXSERVERS"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:self];
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
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerArray has changed" object:self];
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
//	NSLog(@"index: %d id %@", rowIndex, [aTableColumn identifier]);
	
	return YES;
}

- (void) deleteSelectedRow:(id)sender
{
	if( [sender tag] == 0)
	{
		[serverList removeObjectAtIndex:[serverTable selectedRow]];
		[[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"SERVERS"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerArray has changed" object:self];
		
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

- (IBAction) setStringEncoding:(id)sender{
	NSString *encoding;
	//int encoding = [[sender selectedItem] tag];

	switch ([[sender selectedItem] tag]){
		case 0: encoding = @"ISO_IR 100";
			break;
		case 1: encoding = @"ISO_IR 101";
			break;
		case 2: encoding = @"ISO_IR 109";
			break;
		case 3: encoding = @"ISO_IR 110";
			break;
		case 4: encoding = @"ISO_IR 127";
			break;
		case 5: encoding = @"ISO_IR 144";
			break;
		case 6: encoding = @"ISO_IR 126";
			break;
		case 7: encoding = @"ISO_IR 138";
			break;
		case 8: encoding = @"GB18030";
			break;
		case 9: encoding = @"ISO_IR 192";
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
