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


#import "OSIHangingPreferencePanePref.h"

@implementation OSIHangingPreferencePanePref

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	hangingProtocols = [[[defaults objectForKey:@"HANGINGPROTOCOLS"] mutableCopy] retain];
	//setup GUI
	
	modalityForHangingProtocols = [[NSString stringWithString:@"CR"] retain];
	[hangingProtocolTableView reloadData];
}

- (void)dealloc {
	[hangingProtocols release];
	
	NSLog(@"dealloc OSIHangingPreferencePanePref");

	[super dealloc];
}

//****** TABLEVIEW

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[hangingProtocols objectForKey:modalityForHangingProtocols] count];
}

- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{

	NSMutableArray *hangingProtocolArray = [[hangingProtocols objectForKey:modalityForHangingProtocols] mutableCopy];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [hangingProtocolArray count]);
	id theRecord = [[hangingProtocolArray objectAtIndex:rowIndex] mutableCopy];
	[theRecord setObject:anObject forKey:[aTableColumn identifier]];
	
	[hangingProtocolArray replaceObjectAtIndex:rowIndex withObject: theRecord];
	[hangingProtocols setObject:hangingProtocolArray forKey: modalityForHangingProtocols];
	
	[[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];

}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	NSArray *hangingProtocolArray = [hangingProtocols objectForKey:modalityForHangingProtocols];
	NSParameterAssert(rowIndex >= 0 && rowIndex < [hangingProtocolArray count]);
	id theRecord = [hangingProtocolArray objectAtIndex:rowIndex];
	return [theRecord objectForKey:[aTableColumn identifier]];

		
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	NSLog(@"index: %d id %@", rowIndex, [aTableColumn identifier]);
	if ([aTableView isEqual:hangingProtocolTableView] && [[aTableColumn identifier] isEqualToString:@"Study Description"] && rowIndex == 0) 
			return NO;

	return YES;
}

- (IBAction)setModalityForHangingProtocols:(id)sender
{	
	[modalityForHangingProtocols release];
	
	modalityForHangingProtocols = [[sender title] retain];
	[hangingProtocolTableView setHidden:NO];
	[newHangingProtocolButton setHidden:NO];
	[hangingProtocolTableView reloadData];
}

- (IBAction)newHangingProtocol:(id)sender{
	NSMutableDictionary *protocol = [NSMutableDictionary dictionary];
    [protocol setObject:@"Study Description" forKey:@"Study Description"];
    [protocol setObject:[NSNumber numberWithInt:1] forKey:@"Rows"];
    [protocol setObject:[NSNumber numberWithInt:2] forKey:@"Columns"];
	[protocol setObject:[NSNumber numberWithInt:1] forKey:@"Image Rows"];
	[protocol setObject:[NSNumber numberWithInt:1] forKey:@"Image Columns"];

	NSMutableArray *hangingProtocolArray = [[hangingProtocols objectForKey:modalityForHangingProtocols] mutableCopy];
    [hangingProtocolArray  addObject:protocol];
    [hangingProtocols setObject: hangingProtocolArray forKey: modalityForHangingProtocols];
	
    [[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];
    [hangingProtocolTableView reloadData];
	
//Set to edit new entry
	[hangingProtocolTableView  selectRow:[hangingProtocolArray count] - 1 byExtendingSelection:NO];
	[hangingProtocolTableView  editColumn:0 row:[hangingProtocolArray count] - 1  withEvent:nil select:YES];

}

- (void) deleteSelectedRow:(id)sender{
	NSMutableArray *hangingProtocolArray = [[hangingProtocols objectForKey:modalityForHangingProtocols] mutableCopy];
	[hangingProtocolArray removeObjectAtIndex:[hangingProtocolTableView selectedRow]];
	[hangingProtocols setObject: hangingProtocolArray forKey: modalityForHangingProtocols];
	[hangingProtocolTableView reloadData];
	[[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];
}


@end
