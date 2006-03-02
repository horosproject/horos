/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import "PreferenceController.h"
#import "AppController.h"
#import "BrowserController.h"

#define DATAFILEPATH @"/Database.dat"

extern NSString * documentsDirectory();

extern NSMutableArray       *serversArray;
extern NSMutableDictionary  *hangingProtocols;
extern NSString             *AETitle, *AEPort, *AETransferSyntax, *DATABASELOCATIONURL, *QUERYCHARACTERSET;
extern long					STILLMOVIEMODE, AETimeOut, TRANSITIONTYPE, DATABASELOCATION, TEXTURELIMIT;
extern BOOL					DICOMFILEINDATABASE,TICKPLAY, DCMTKJPEG, STORESCP, CHECKUPDATES, COPYDATABASE, MOUNT, UNMOUNT, USEDICOMDIR, SAVEROIS, NOLOCALIZER, TRANSITIONEFFECT, ORIGINALSIZE, USESTORESCP;
extern BOOL					HIDEPATIENTNAME;
extern BOOL					DELETEFILELISTENER;
extern AppController		*appController;
extern short				copydatabaseMode;
extern BrowserController	*browserWindow;

//		BOOL				PreferencesWindowOpened = NO;
		BOOL				beforeHIDEPATIENTNAME;

@implementation PreferenceController

//****** TABLEVIEW

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if ([aTableView isEqual:tableView])
		return [serversArray count];
	else 
		return [[hangingProtocols objectForKey:modalityForHangingProtocols] count];

}

- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	if ([aTableView isEqual:tableView]) {
		id theRecord;	   
		NSParameterAssert(rowIndex >= 0 && rowIndex < [serversArray count]);
		theRecord = [serversArray objectAtIndex:rowIndex];
		[theRecord setObject:anObject forKey:[aTableColumn identifier]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerArray has changed" object:self];
		return;
	}
	else {
		NSArray *hangingProtocolArray = [hangingProtocols objectForKey:modalityForHangingProtocols];
		NSParameterAssert(rowIndex >= 0 && rowIndex < [hangingProtocolArray count]);
		id theRecord = [hangingProtocolArray objectAtIndex:rowIndex];
		[theRecord setObject:anObject forKey:[aTableColumn identifier]];
	}
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	id theRecord;
	if ([aTableView isEqual:tableView]) {
		NSParameterAssert(rowIndex >= 0 && rowIndex < [serversArray count]);
		theRecord = [serversArray objectAtIndex:rowIndex];
		
		if( [[aTableColumn identifier] isEqual:@"Port"] == YES)
		{
			long    value;
			
			value = [[theRecord objectForKey:[aTableColumn identifier]] intValue];
			
			if( value < 1) value = 1;
			if( value > 131072) value = 131072;
			
			[theRecord setObject:[[NSNumber numberWithLong:value] stringValue] forKey:[aTableColumn identifier]];
		}
		
		return [theRecord objectForKey:[aTableColumn identifier]];
	}
	else {
		NSArray *hangingProtocolArray = [hangingProtocols objectForKey:modalityForHangingProtocols];
		NSParameterAssert(rowIndex >= 0 && rowIndex < [hangingProtocolArray count]);
		id theRecord = [hangingProtocolArray objectAtIndex:rowIndex];
		/*
		if ([[aTableColumn identifier] isEqual:@"Rows"] || [[aTableColumn identifier] isEqual:@"Columns"]) 
			//return [[theRecord objectForKey:[aTableColumn identifier]] stringValue];
			return nil;
		NSLog(@"id %@, value %@", [aTableColumn identifier], [theRecord objectForKey:[aTableColumn identifier]]);
		*/
		return [theRecord objectForKey:[aTableColumn identifier]];
	}
		
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	NSLog(@"index: %d id %@", rowIndex, [aTableColumn identifier]);
	if ([aTableView isEqual:hangingProtocolTableView] && [[aTableColumn identifier] isEqualToString:@"Study Description"] && rowIndex == 0) 
			return NO;

	return YES;
}

-(void) switchAction:(id) sender
{
	[AETitle release];
    [AEPort release];
    
    AETitle = [[[form cellAtIndex:0] stringValue] retain];
    AEPort = [[[form cellAtIndex:1] stringValue] retain];
//	AETimeOut = [[form cellAtIndex:2] intValue];
	
	STILLMOVIEMODE = [[stillMovieOptions selectedCell] tag];
	
	switch( [[TransferOptions selectedCell] tag])
	{
		case 0:		AETransferSyntax = [[NSString alloc] initWithString:@"+x="];		break;
		case 1:		AETransferSyntax = [[NSString alloc] initWithString:@"+xe"];		break;
		case 2:		AETransferSyntax = [[NSString alloc] initWithString:@"+xb"];		break;
		case 3:		AETransferSyntax = [[NSString alloc] initWithString:@"+xs"];		break;
		case 4:		AETransferSyntax = [[NSString alloc] initWithString:@"+xy"];		break;
		case 5:		AETransferSyntax = [[NSString alloc] initWithString:@"+xx"];		break;
		case 6:		AETransferSyntax = [[NSString alloc] initWithString:@"+xr"];		break;
		case 7:		AETransferSyntax = [[NSString alloc] initWithString:@"+xi"];		break;
	}
    
	TICKPLAY = [tickSoundOnOff state];
	DCMTKJPEG = [DcmTkJpegOnOff state];
    STORESCP = [ListenerOnOff state];
	HIDEPATIENTNAME = [PatientNameOnOff state];
	DELETEFILELISTENER = [[DeleteFileMode selectedCell] tag];
	if( beforeHIDEPATIENTNAME != HIDEPATIENTNAME)
	{
		beforeHIDEPATIENTNAME = HIDEPATIENTNAME;
		[browserWindow refreshNames];
	}
	
	CHECKUPDATES = [CheckUpdatesOnOff state];
	ORIGINALSIZE = [[SizeMatrix selectedCell] tag];
	TEXTURELIMIT = [[TextureMatrix selectedCell] tag];
	NOLOCALIZER = [LocalizerOnOff state];
	TRANSITIONEFFECT = [TransitionOnOff state];
	TRANSITIONTYPE = [[TransitionType selectedItem] tag];
	COPYDATABASE = [CopyDatabaseOnOff state];
	if( COPYDATABASE == NO) [CopyDatabaseMode setEnabled:NO];
	else [CopyDatabaseMode setEnabled:YES];
	copydatabaseMode = [[CopyDatabaseMode selectedCell] tag];
//	DICOMFILEINDATABASE = [[dicomInDatabase selectedCell] tag];
	USEDICOMDIR = [[DICOMDIRMode selectedCell] tag];
	
	MOUNT  = [MountOnOff state];
	UNMOUNT = [UnmountOnOff state];
	SAVEROIS = [CheckSaveLoadROI state];
	
	DATABASELOCATION = [[Location selectedCell] tag];
	
	[DATABASELOCATIONURL release];
	DATABASELOCATIONURL = [[LocationURL stringValue] retain];
}

-(void) newServer:(id)sender
{
    NSMutableDictionary *aServer = [[NSMutableDictionary alloc] init];
    [aServer setObject:@"149.142.98.136" forKey:@"Address"];
    [aServer setObject:@"PROCOM" forKey:@"AETitle"];
    [aServer setObject:@"4096" forKey:@"Port"];
    [aServer setObject:@"PROCOM PACS Server" forKey:@"Description"];
    
    [serversArray addObject:aServer];
    
    [aServer release];
    
    [tableView reloadData];
	
//Set to edit new entry
	[tableView selectRow:[serversArray count] - 1 byExtendingSelection:NO];
	[tableView editColumn:0 row:[serversArray count] - 1  withEvent:nil select:YES];
}

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter){
		if ([tableView isEqual:[[self window] firstResponder]]) {
			[serversArray removeObjectAtIndex:[tableView selectedRow]];
			[tableView reloadData];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerArray has changed" object:self];
		} 
		else if ([hangingProtocolTableView isEqual:[[self window] firstResponder]] && [hangingProtocolTableView selectedRow] > 0) {
			NSMutableArray *hangingProtocolArray = [hangingProtocols objectForKey:modalityForHangingProtocols];
			[hangingProtocolArray removeObjectAtIndex:[hangingProtocolTableView selectedRow]];
			[hangingProtocolTableView reloadData];
		}
			
    } else
    {
        [super keyDown:event];
    }
}

//******

-(id) init
{
    self = [super initWithWindowNibName:@"Preferences"];
    sharedAppController = [AppController sharedAppController];
	//hangingProtocols = [sharedAppController hangingProtocols];
	
//	PreferencesWindowOpened = YES;
	
    return self;
}

- (void)windowDidLoad
{
    NSLog(@"Nib file is loaded");
    
	previousPath = [documentsDirectory() retain];
	NSLog( previousPath);
	
	[Location selectCellWithTag: DATABASELOCATION];
	[LocationURL setStringValue:DATABASELOCATIONURL];
	[SizeMatrix selectCellWithTag: ORIGINALSIZE];
	[TextureMatrix selectCellWithTag: TEXTURELIMIT];
	
    [[form cellAtIndex:0] setStringValue:AETitle];
    [[form cellAtIndex:1] setStringValue:AEPort];
	[tickSoundOnOff setState:TICKPLAY];
	[DcmTkJpegOnOff setState:DCMTKJPEG];
    [ListenerOnOff setState:STORESCP];
	[PatientNameOnOff setState:HIDEPATIENTNAME];		beforeHIDEPATIENTNAME = HIDEPATIENTNAME;
	[DeleteFileMode selectCellWithTag: DELETEFILELISTENER];
	[CheckUpdatesOnOff setState:CHECKUPDATES];
	[LocalizerOnOff setState:NOLOCALIZER];
	[TransitionOnOff setState:TRANSITIONEFFECT];
	[TransitionType selectItemAtIndex:[TransitionType indexOfItemWithTag:TRANSITIONTYPE]];
	[CopyDatabaseOnOff setState:COPYDATABASE];
	[MountOnOff setState:MOUNT];
	[CheckSaveLoadROI setState:SAVEROIS];
	[UnmountOnOff setState:UNMOUNT];
	
	[CopyDatabaseMode selectCellWithTag: copydatabaseMode];
//	[dicomInDatabase selectCellWithTag:DICOMFILEINDATABASE];
	[DICOMDIRMode selectCellWithTag: USEDICOMDIR];
	
	[stillMovieOptions selectCellWithTag: STILLMOVIEMODE];
	NSLog(@"USESTORESCP %d" , USESTORESCP);
	[transferSyntaxBox setHidden:!(USESTORESCP)];
	[storageMatrix selectCellWithTag:USESTORESCP];

	if( [AETransferSyntax isEqualToString:@"+x="]) [TransferOptions selectCellWithTag:0];
	if( [AETransferSyntax isEqualToString:@"+xe"]) [TransferOptions selectCellWithTag:1];
	if( [AETransferSyntax isEqualToString:@"+xb"]) [TransferOptions selectCellWithTag:2];
	if( [AETransferSyntax isEqualToString:@"+xs"]) [TransferOptions selectCellWithTag:3];
	if( [AETransferSyntax isEqualToString:@"+xy"]) [TransferOptions selectCellWithTag:4];
	if( [AETransferSyntax isEqualToString:@"+xx"]) [TransferOptions selectCellWithTag:5];
	if( [AETransferSyntax isEqualToString:@"+xr"]) [TransferOptions selectCellWithTag:6];
	if( [AETransferSyntax isEqualToString:@"+xi"]) [TransferOptions selectCellWithTag:7];
	
    [tableView setDelegate: self];
	
	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setAllowsFloats:NO];
	[formatter setMinimum:[NSDecimalNumber one]];
	[formatter setMaximum:[NSDecimalNumber decimalNumberWithString:@"6.0"]];
	[formatter setFormat:@"#"];
	NSTableColumn *rowColumn = [hangingProtocolTableView tableColumnWithIdentifier:@"Rows"];
	id rowCell = [rowColumn dataCell];
	[rowCell setFormatter:formatter];
	NSTableColumn *columnColumn = [hangingProtocolTableView tableColumnWithIdentifier:@"ColumnS"];
	id columnCell = [columnColumn dataCell];
	[columnCell setFormatter:formatter];
	
	
	int index;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 100"]) index = 0;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 127"]) index = 1;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 101"]) index = 2;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 109"]) index = 3;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 110"]) index = 4;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 144"]) index = 5;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 126"]) index = 6;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 138"]) index = 7;
	if ([QUERYCHARACTERSET isEqualToString:@"GB18030"]) index = 8;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 192"]) index = 9;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO 2022 IR 149"]) index = 10;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO 2022 IR 13"]) index = 11;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO 2022 IR 87"]) index = 12;
	if ([QUERYCHARACTERSET isEqualToString:@"ISO_IR 166"]) index = 13;
	[(NSPopUpButton *)characterSetPopup selectItemAtIndex:index];
	[self switchAction:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[self window] setDelegate:nil];
    	
	[self switchAction:self];
	[appController savePrefs];
	[appController restartSTORESCP];
	
	[[self window] close];
	
	if( [previousPath isEqualToString: documentsDirectory()] == NO)
	{
		NSLog(@"New DATABASE path!");
		
		[browserWindow saveDatabase: [previousPath stringByAppendingString:DATAFILEPATH]];
		
		[browserWindow loadDatabase: [documentsDirectory() stringByAppendingString:DATAFILEPATH]];
		
		[browserWindow refreshDatabase];
	}
	
	[previousPath release];
	
//	PreferencesWindowOpened = NO;
	
	[self release];
}

-(IBAction) chooseURL:(id) sender
{
	NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
	long				result;
	
    [oPanel setCanChooseFiles:NO];
    [oPanel setCanChooseDirectories:YES];
	
	result = [oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"roi"]];
    
    if (result == NSOKButton) 
    {
		[LocationURL setStringValue: [oPanel directory]];
	}
}

- (IBAction)setModalityForHangingProtocols:(id)sender{
	[modalityForHangingProtocols release];
	if (![[sender title] isEqualToString:@"Modality"]) {		
		modalityForHangingProtocols = [[sender title] retain];
		[hangingProtocolTableView setHidden:NO];
		[newHangingProtocolButton setHidden:NO];
		NSMutableArray *hangingProtocolArray = [hangingProtocols objectForKey:modalityForHangingProtocols];
	}
	else {
		modalityForHangingProtocols = nil;
	//	[hangingProtocolTableView setHidden:YES];
	//	[newHangingProtocolButton setHidden:YES];
	}
	[hangingProtocolTableView reloadData];
}

- (IBAction)newHangingProtocol:(id)sender{
	NSMutableDictionary *protocol = [NSMutableDictionary dictionary];
    [protocol setObject:@"Study Description" forKey:@"Study Description"];
    [protocol setObject:[NSNumber numberWithInt:1] forKey:@"Rows"];
    [protocol setObject:[NSNumber numberWithInt:2] forKey:@"Columns"];
	[protocol setObject:[NSNumber numberWithInt:1] forKey:@"Image Rows"];
	[protocol setObject:[NSNumber numberWithInt:1] forKey:@"Image Columns"];

	NSMutableArray *hangingProtocolArray = [hangingProtocols objectForKey:modalityForHangingProtocols];
    [hangingProtocolArray  addObject:protocol];
    
    
    [hangingProtocolTableView reloadData];
	
//Set to edit new entry
	[hangingProtocolTableView  selectRow:[hangingProtocolArray count] - 1 byExtendingSelection:NO];
	[hangingProtocolTableView  editColumn:0 row:[hangingProtocolArray count] - 1  withEvent:nil select:YES];

}

- (IBAction)setQueryCharacterSet:(id)sender {
	switch ([sender indexOfSelectedItem]) {
		case 0: QUERYCHARACTERSET = @"ISO_IR 100";  //American English, default
			break;
		case 1: QUERYCHARACTERSET = @"ISO_IR 127";  //@"Arabic (ISO 8859-6)"
			break;
		case 2: QUERYCHARACTERSET = @"ISO_IR 101";  //NSISOLatin2StringEncoding
			break;
		case 3: QUERYCHARACTERSET = @"ISO_IR 109";  //@"Western (ISO Latin 3)"
			break;
		case 4: QUERYCHARACTERSET = @"ISO_IR 110";  //@"Central European (ISO Latin 4)"
			break;
		case 5: QUERYCHARACTERSET = @"ISO_IR 144";  //@"Cyrillic (ISO 8859-5)"
			break;
		case 6: QUERYCHARACTERSET = @"ISO_IR 126";  //@"Greek (ISO 8859-7)"
			break;
		case 7: QUERYCHARACTERSET = @"ISO_IR 138";  //@"Hebrew (ISO 8859-8)"
			break;
		case 8: QUERYCHARACTERSET = @"GB18030";  //@"Chinese (GB 18030)"
			break;
		case 9: QUERYCHARACTERSET = @"ISO_IR 192";  //NSUTF8StringEncoding
			break;
		case 10: QUERYCHARACTERSET = @"ISO 2022 IR 149";  //@"Korean (ISO 2022-KR)"
			break;
		case 11: QUERYCHARACTERSET = @"ISO 2022 IR 13";  //@"Japanese (Mac OS)"
			break;
		case 12: QUERYCHARACTERSET = @"ISO 2022 IR 87";  //@"Japanese 2 (Mac OS)"
			break;
		case 13: QUERYCHARACTERSET = @"ISO_IR 166";  //@"Thai (ISO 8859-11)"
			break;
		default: QUERYCHARACTERSET = @"ISO_IR 100";
	}
	NSLog(@"Character Set %@", QUERYCHARACTERSET);
}

- (IBAction)setStorageTool:(id)sender{
	USESTORESCP = [ sender selectedRow];
	[transferSyntaxBox setHidden:!(USESTORESCP)];
		
}
			

@end
