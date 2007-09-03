//
//  SendController.m
//  OsiriX
//
//  Created by Lance Pysher on 12/14/05.

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

/***************************************** Modifications *********************************************

Version 2.3
	20060109	LP	Don't need enviromemtal variable DICOMPATH with new DCMTK tools. The dicom dictionary is built in.

******************************************************************************************************/
	


#import "SendController.h"
#import "Wait.h"
#import <OsiriX/DCMNetServiceDelegate.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>
#import "NetworkSendDataHandler.h"
#import "PluginFilter.h"
#import "PluginManager.h"
#import "DCMTKStoreSCU.h"

static volatile int sendControllerObjects = 0;

@implementation SendController

+(int) sendControllerObjects
{
	return sendControllerObjects;
}

+ (void)sendFiles:(NSArray *)files
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMSENDALLOWED"] == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"DICOM Sending is not activated. Contact your PACS manager for more information about DICOM Send.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		return;
	}

	if( [files  count])
	{
		if( [[DCMNetServiceDelegate DICOMServersListSendOnly: YES QROnly: NO] count] > 0)
		{
			SendController *sendController = [[SendController alloc] initWithFiles:files];
			[NSApp beginSheet: [sendController window] modalForWindow:[NSApp mainWindow] modalDelegate:sendController didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
			[NSThread detachNewThreadSelector: @selector(releaseSelfWhenDone:) toTarget:sendController withObject: nil];
		}
		else
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No DICOM destinations available. See Preferences to add DICOM locations.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
	}
	else NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No files are selected...",nil),NSLocalizedString( @"OK",nil), nil, nil);
}

- (id)initWithFiles:(NSArray *)files{
	if (self = [super initWithWindowNibName:@"Send"])
	{
		NSLog( @"SendController initWithFiles");
		
		_abort = NO;
		_files = [files copy];
		int count = [_files  count];
		if(count == 1)
			[self setNumberFiles: [NSString stringWithFormat:NSLocalizedString(@"%d image", nil), count]];
		else if (count > 1)
			[self setNumberFiles: [NSString stringWithFormat:NSLocalizedString(@"%d images", nil), count]];
		
		
		_serverIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendServer"];	
		
		if( _serverIndex >= [[DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly: NO] count])
			_serverIndex = 0;
		
		_keyImageIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendWhat"];
		_offisTS = [[NSUserDefaults standardUserDefaults] integerForKey:@"syntaxListOffis"];
		
		_readyForRelease = NO;
		_lock = [[NSLock alloc] init];
		[_lock  lock];
		sendControllerObjects++;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSendMessage:) name:@"DCMSendStatus" object:nil];

	}
	return self;
}



- (void) windowDidLoad
{
	if 	([_files  count])
	{
		[serverList reloadData];
	
		int count = [[DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO] count];
		if (_serverIndex < count)
			[serverList selectItemAtIndex: _serverIndex];
			
//		[DICOMSendTool selectCellWithTag: _serverToolIndex];
		[keyImageMatrix selectCellWithTag: _keyImageIndex];
		
//		[syntaxListOsiriX selectItemWithTag: _osirixTS];
		[syntaxListOffis selectItemWithTag: _offisTS];
		
		[self selectServer: serverList];
	}

}

- (void)dealloc{
	NSLog(@"SendController Released");
	[_files release];
	[_server release];
	[_transferSyntaxString release];
	[_numberFiles release];
	[_lock lock];
	sendControllerObjects--;
	[_lock unlock];
	[_lock release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)releaseSelfWhenDone:(id)sender{
	[_lock lock];
	[_lock unlock];
	[self release];
}

- (NSString *)numberFiles{
	return _numberFiles;
}

- (void)setNumberFiles:(NSString *)numberFiles{
	[_numberFiles release];
	_numberFiles = [numberFiles retain];
}

- (id)server{
	return [self serverAtIndex:_serverIndex];
}


#pragma mark Accessors functions

- (id)serverAtIndex:(int)index
{
	NSArray			*serversArray		= [DCMNetServiceDelegate DICOMServersListSendOnly: YES QROnly:NO];
	
	if( index > -1 && index < [serversArray count]) return [serversArray objectAtIndex:index];
	
	return nil;
}

- (id)setServer:(id)server{
	[_server release];
	_server = [server retain];

}

- (IBAction)selectServer: (id)sender
{
	//NSLog(@"select server: %@", [sender description]);
	_serverIndex = [sender indexOfSelectedItem];
	
	[[NSUserDefaults standardUserDefaults] setInteger:_serverIndex forKey:@"lastSendServer"];
	
	if ([[self server] isKindOfClass:[NSDictionary class]])
	{
		int preferredTS = [[[self server] objectForKey:@"Transfer Syntax"] intValue];
				
		if (preferredTS ==  SendExplicitLittleEndian || 
			preferredTS == SendImplicitLittleEndian || 
			preferredTS == SendRLE ||
			preferredTS == SendJPEGLossless)
				[self  setOffisTS:preferredTS];
	
	}	
	
	[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[self server] objectForKey:@"Address"], [[self server] objectForKey:@"Port"]]];
}

- (int)keyImageIndex{
	return _keyImageIndex;
}

-(void)setKeyImageIndex:(int)index{
	_keyImageIndex = index;
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"lastSendWhat"];
}

- (int) offisTS{
	return _offisTS;
}

- (void) setOffisTS:(int)index{
	_offisTS = index;
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"syntaxListOffis"];
}

#pragma mark sheet functions

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
}

- (IBAction) endSelectServer:(id) sender
{
	NSLog(@"end select server");
	[[self window] orderOut:sender];
	[NSApp endSheet: [self window] returnCode:[sender tag]];
	NSArray *objectsToSend = _files;
	
	if( [sender tag])   //User clicks OK Button
    {		
		if (_keyImageIndex == 1)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isKeyImage == YES"];
			objectsToSend = [_files filteredArrayUsingPredicate:predicate];
		}
		
		if (_keyImageIndex == 2)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"modality LIKE[c] %@", [NSString stringWithFormat:@"*%@*", @"SC"]];
			objectsToSend = [objectsToSend filteredArrayUsingPredicate:predicate];
		}

		NSMutableArray	*files2Send = [objectsToSend valueForKey: @"completePath"];
		
		if( files2Send != 0L && [files2Send count] > 0)
		{
			if( !([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask && [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask))
			{
				// DONT REMOVE THESE LINES - THANX ANTOINE
				if( [[PluginManager plugins] valueForKey:@"ComPACS"] != 0)
				{
					long result = [[[PluginManager plugins] objectForKey:@"ComPACS"] prepareFilter: 0L];
					
					result = [[[PluginManager plugins] objectForKey:@"ComPACS"] filterImage: [NSString stringWithFormat:@"dicomSEND%@", [[objectsToSend objectAtIndex: 0] valueForKeyPath:@"series.study.patientUID"]]];
					if( result != 0)
					{
						NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"Smart card authentification is required for DICOM sending.",nil),NSLocalizedString( @"OK",nil), nil, nil);
						files2Send = 0L;
					}
				}
			}
			
			if( files2Send)
			{
				_waitSendWindow = [[Wait alloc] initWithString: NSLocalizedString(@"Sending files...",@"Sending files") :NO];
				[_waitSendWindow  setTarget:self];
				[_waitSendWindow showWindow:self];
				[[_waitSendWindow progress] setMaxValue:[files2Send count]];
				
				[_waitSendWindow setCancel:YES];
				[NSThread detachNewThreadSelector: @selector(sendDICOMFilesOffis:) toTarget:self withObject: objectsToSend];
			}
			else [_lock unlock];	// Will release the object
		}
		else [_lock unlock];	// Will release the object
	}
	else // Cancel
	{
		[_lock unlock];	// Will release the object
	}
}

#pragma mark Sending functions	

- (void) showErrorMessage:(NSException*) ne
{
	NSString	*message = [NSString stringWithFormat:@"%@\r\r%@\r%@", NSLocalizedString( @"DICOM StoreSCU operation failed.", nil), [ne name], [ne reason]];

	NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send Error",nil), message, NSLocalizedString( @"OK",nil), nil, nil);
}

- (void) executeSend :(NSArray*) samePatientArray
{
	BOOL	isFault = NO;
	
	if( _abort) return;
	
	int x;
	for( x = 0; x < [samePatientArray count] ; x++) if( [[samePatientArray objectAtIndex: x] isFault]) isFault = YES;
	
	NSArray	*files = [samePatientArray valueForKey: @"completePathResolved"];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"sendROIs"])
	{
		NSLog( @"add ROIs for DICOM sending");
		int i;
		NSMutableArray	*roiFiles = [NSMutableArray array];
		
		for( i = 0 ; i < [samePatientArray count] ; i++)
		{
			[roiFiles addObjectsFromArray: [[samePatientArray objectAtIndex: i] valueForKey: @"SRPaths"]];
		}
		
		files = [files arrayByAddingObjectsFromArray: roiFiles];
	}
	
	if( isFault) NSLog( @"Fault on objects: not available for sending");
	else
	{
		// Send the collected files from the same patient
		
		NSString *calledAET = [[self server] objectForKey:@"AETitle"];
		NSString *hostname = [[self server] objectForKey:@"Address"];
		NSString *destPort = [[self server] objectForKey:@"Port"];

		storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
				calledAET:calledAET 
				hostname:hostname 
				port:[destPort intValue] 
				filesToSend:files
				transferSyntax:_offisTS
				compression: 1.0
				extraParameters:nil];
		
		@try
		{
			[storeSCU run:self];
		}
		
		@catch( NSException *ne)
		{
			if( _waitSendWindow)
			{
				[self performSelectorOnMainThread:@selector(showErrorMessage:) withObject:ne waitUntilDone: NO];
			}
		}
		
		[storeSCU release];
		storeSCU = 0L;
	}
}

- (void) sendDICOMFilesOffis:(NSArray *) objectsToSend
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

	NSString *calledAET = [[self server] objectForKey:@"AETitle"];
	NSString *hostname = [[self server] objectForKey:@"Address"];
	NSString *destPort = [[self server] objectForKey:@"Port"];
	
	NSLog(@"Server destination: %@", [[self server] description]);	
			
	int					i;
	NSString			*previousPatientUID = 0L;
	NSMutableArray		*samePatientArray = [NSMutableArray arrayWithCapacity: [objectsToSend count]];
	
	NSSortDescriptor	*sort = [[[NSSortDescriptor alloc] initWithKey:@"series.study.patientUID" ascending:YES] autorelease];
	NSArray				*sortDescriptors = [NSArray arrayWithObject: sort];
	
	objectsToSend = [objectsToSend sortedArrayUsingDescriptors: sortDescriptors];
	
	for( i = 0; i < [objectsToSend count] ; i++)
	{
		if( [previousPatientUID isEqualToString: [[objectsToSend objectAtIndex: i] valueForKeyPath:@"series.study.patientUID"]])
		{
			[samePatientArray addObject: [objectsToSend objectAtIndex: i]];
		}
		else
		{
			if( [samePatientArray count]) [self executeSend: samePatientArray];
			
			// Reset
			[samePatientArray removeAllObjects];
			[samePatientArray addObject: [objectsToSend objectAtIndex: i]];
			
			previousPatientUID = [[objectsToSend objectAtIndex: i] valueForKeyPath:@"series.study.patientUID"];
		}
	}
	
	if( [samePatientArray count]) [self executeSend: samePatientArray];
	
	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	[info setObject:[NSNumber numberWithInt:[objectsToSend count]] forKey:@"SendTotal"];
	[info setObject:[NSNumber numberWithInt:[objectsToSend count]] forKey:@"NumberSent"];
	[info setObject:[NSNumber numberWithBool:YES] forKey:@"Sent"];
	[info setObject:calledAET forKey:@"CalledAET"];
	
	[self performSelectorOnMainThread:@selector(closeSendPanel:) withObject:nil waitUntilDone:YES];	
	
	//need to unlock to allow release of self after send complete
	[_lock unlock];
	
	[pool release];
	
}

- (void)closeSendPanel:(id)sender{
	[_waitSendWindow close];			
	[_waitSendWindow release];			
	_waitSendWindow = 0L;	
}


- (void) setSendMessageThread:(NSDictionary*) info
{
	if( _waitSendWindow)
	{
		[_waitSendWindow incrementBy:1];
		[[[_waitSendWindow window] contentView] setNeedsDisplay:YES];
	}
}

- (void)setSendMessage:(NSNotification *)note
{
	if( [note object] == storeSCU)
		[self performSelectorOnMainThread:@selector(setSendMessageThread:) withObject:[note userInfo] waitUntilDone:YES]; // <- GUI operations are permitted ONLY on the main thread
}

#pragma mark serversArray functions

- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	NSArray			*serversArray		= [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
	
	if ([aComboBox isEqual:serverList])
	{	
		return [serversArray count];
	}
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	NSArray			*serversArray		= [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
	
	if ([aComboBox isEqual:serverList])
	{
		if( index > -1 && index < [serversArray count])
		{
			id theRecord = [serversArray objectAtIndex: index];			
			return [NSString stringWithFormat:@"%@ - %@",[theRecord objectForKey:@"AETitle"],[theRecord objectForKey:@"Description"]];
		}
	}
	return nil;
}



- (void)listenForAbort:(id)handler{
	[[_waitSendWindow window] orderOut:self];
	[storeSCU abort];
}

- (void)abort
{
	[self listenForAbort:nil];
	_abort = YES;
}


@end
