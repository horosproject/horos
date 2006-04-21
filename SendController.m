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
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

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

#import "DCMTKStoreSCU.h"


extern NSMutableDictionary	*plugins, *pluginsDict;



@implementation SendController

+ (void)sendFiles:(NSArray *)files
{
	if 	([files  count])
	{
		SendController *sendController = [[SendController alloc] initWithFiles:files];
		[NSApp beginSheet: [sendController window] modalForWindow:[NSApp mainWindow] modalDelegate:sendController didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		[NSThread detachNewThreadSelector: @selector(releaseSelfWhenDone:) toTarget:sendController withObject: nil];
	}
	else NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No files are selected...",nil),NSLocalizedString( @"OK",nil), nil, nil);
}

- (id)initWithFiles:(NSArray *)files{
	if (self = [super initWithWindowNibName:@"Send"]){
		_files = [files copy];
		int count = [_files  count];
		if(count == 1)
			[self setNumberFiles: [NSString stringWithFormat:NSLocalizedString(@"%d image", nil), count]];
		else if (count > 1)
			[self setNumberFiles: [NSString stringWithFormat:NSLocalizedString(@"%d images", nil), count]];
		
		
		_serverIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendServer"];	
//		_serverToolIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSenderEngine"];
		_keyImageIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendWhat"];
//		_osirixTS = [[NSUserDefaults standardUserDefaults] integerForKey:@"syntaxListOsiriX"];
		_offisTS = [[NSUserDefaults standardUserDefaults] integerForKey:@"syntaxListOffis"];
		
		_readyForRelease = NO;
		_lock = [[NSLock alloc] init];
		[_lock  lock];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSendMessage:) name:@"DCMSendStatus" object:nil];

	}
	return self;
}



- (void) windowDidLoad
{
	if 	([_files  count])
	{
		[serverList reloadData];
	
		int count = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"] count] + [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] count];
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
	//NSLog(@"Release SendController");
	[_files release];
	[_server release];
	[_transferSyntaxString release];
	[_numberFiles release];
	[_lock release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)releaseSelfWhenDone:(id)sender{
	[_lock lock];
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
	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	//NSLog(@"server at INdex: %d", index);
	
	if( index > -1 && index < [serversArray count])
		return [serversArray objectAtIndex:index];
	else if( index > -1) 
		return [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:index - ([serversArray count])];
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
//		if (preferredTS < SendImplicitLittleEndian)
//				[self  setOsirixTS:preferredTS];
				
		if (preferredTS ==  SendExplicitLittleEndian || 
			preferredTS == SendImplicitLittleEndian || 
			preferredTS == SendRLE ||
			preferredTS == SendJPEGLossless)
				[self  setOffisTS:preferredTS];
	
	}	

	if ([[self server] isMemberOfClass: [NSNetService class]])
	{
		[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[self server] hostName], [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:[self server]]]]];
	}
	else
	{
		[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[self server] objectForKey:@"Address"], [[self server] objectForKey:@"Port"]]];
	}
}

//- (int)serverToolIndex{
//	return _serverToolIndex;
//}

//-(void)setServerToolIndex:(int)index{
//
//	_serverToolIndex = index;
//	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"lastSenderEngine"];
//}

- (int)keyImageIndex{
	return _keyImageIndex;
}

-(void)setKeyImageIndex:(int)index{
	_keyImageIndex = index;
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"lastSendWhat"];
}

//- (int) osirixTS{
//	return _osirixTS;
//}

//- (void) setOsirixTS:(int)index{
//	_osirixTS = index;
//	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"syntaxListOsiriX"];
//}


- (int) offisTS{
	return _offisTS;
}

- (void) setOffisTS:(int)index{
	_offisTS = index;
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"syntaxListOffis"];
}

#pragma mark sheet functions

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
	//
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
			// DONT REMOVE THESE LINES - THANX ANTOINE
			if( [plugins valueForKey:@"ComPACS"] != 0)
			{
				long result = [[plugins objectForKey:@"ComPACS"] prepareFilter: 0L];
				
				result = [[plugins objectForKey:@"ComPACS"] filterImage: [NSString stringWithFormat:@"dicomSEND%@", [[objectsToSend objectAtIndex: 0] valueForKeyPath:@"series.study.patientUID"]]];
				if( result != 0)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"Smart card authentification is required for DICOM sending.",nil),NSLocalizedString( @"OK",nil), nil, nil);
					files2Send = 0L;
				}
			}
		}	
			
		if( files2Send != 0L && [files2Send count] > 0)
		{
			//NSLog( @"Will send %d files", [files2Send count]);
						
			_waitSendWindow = [[Wait alloc] initWithString: NSLocalizedString(@"Sending files...",@"Sending files") :NO];
			[_waitSendWindow  setTarget:self];
			[_waitSendWindow showWindow:self];
			[[_waitSendWindow progress] setMaxValue:[files2Send count]];
			
//			if(_serverToolIndex == 1)
//			{
//				[_waitSendWindow setCancel:YES];
//				[NSThread detachNewThreadSelector: @selector(sendDICOMFiles:) toTarget:self withObject: files2Send];
//			}
//			else
			{
				[_waitSendWindow setCancel:YES];
				//[[_waitSendWindow progress] setIndeterminate: YES];
				//[_waitSendWindow setElapsedString:@"working..."];
				[NSThread detachNewThreadSelector: @selector(sendDICOMFilesOffis:) toTarget:self withObject: files2Send];
			}
		}		
	}

}

#pragma mark Sending functions	

//- (void)sendDICOMFiles:(NSMutableArray *)files
//{
//	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
//	
//	NSLog( @"**** WE SHOULD NOT BE HERE");
//	
//	NSMutableArray		*filesToSend = [files retain];
//	//NSMutableArray		*tempFiles = [NSMutableArray array];
//	//convert Syntax
//	NSEnumerator *enumerator = [filesToSend objectEnumerator];
//	NSString *path;
//	DCMTransferSyntax *ts;
//	NSString *transferSyntax;
//	//get Transfer Syntax and compression in indicated
//	int compression = DCMLosslessQuality;
//	switch ([self osirixTS]) {
//		case SendExplicitLittleEndian: 
//			ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
//			transferSyntax = @"Explicit Little Endian";
//			break;
//		case SendJPEG2000Lossless:
//			ts = [DCMTransferSyntax JPEG2000LosslessTransferSyntax];
//			transferSyntax = @"JPEG 2000 Lossless";
//			break;
//		case SendJPEG2000Lossy10:
//			ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
//			compression = DCMHighQuality;
//			transferSyntax = @"JPEG 2000 Lossy";
//			break;
//		case SendJPEG2000Lossy20:
//			ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
//			compression = DCMMediumQuality;
//			transferSyntax = @"JPEG 2000 Lossy";
//			break;
//		case SendJPEG2000Lossy50:
//			ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
//			compression =  DCMLowQuality;
//			transferSyntax = @"JPEG 2000 Lossy";
//			break;
//		case SendJPEGLossless: 
//			ts = [DCMTransferSyntax JPEGLosslessTransferSyntax];
//			transferSyntax = @"JPEG Lossless";
//			break;
//		case SendJPEGLossy9:
//			ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
//			compression = DCMHighQuality;
//			transferSyntax = @"JPEG Lossy";
//			break;
//		case SendJPEGLossy8:
//			ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
//			compression =  DCMMediumQuality;
//			transferSyntax = @"JPEG Lossy";
//			break;			
//		case SendJPEGLossy7:
//			ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
//			compression =  DCMLowQuality;
//			transferSyntax = @"JPEG Lossy";
//			break;
//		case SendImplicitLittleEndian:
//			ts = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
//			transferSyntax = @"Implicit";
//	}
//
//	NSString *calledAET;
//	NSString *hostname;
//	NSString *destPort;
//	NSNetService *netService = nil;
//	NSArray *objects;
//	NSArray *keys;
//
//	//bonjour
//	if ([[self server] isMemberOfClass:[NSNetService class]]){
//		calledAET = [[self server] name];
//		hostname = [[self server] hostName];
//		destPort = [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:[self server]]];
//		netService = [self server];		
//		objects = [NSArray arrayWithObjects:filesToSend, 
//						[NSNumber numberWithInt:compression],
//						ts,
//						[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], 
//						calledAET, 
//						hostname, 
//						destPort,  
//						netService,
//						nil];
//		keys = [NSArray arrayWithObjects:@"filesToSend", 
//					@"compression", 
//					@"transferSyntax",
//					@"callingAET", 
//					@"calledAET", 
//					@"hostname", 
//					@"port", 
//					@"netService",
//					nil];
//	}
//	else{
//		calledAET = [[self server] objectForKey:@"AETitle"];
//		hostname = [[self server] objectForKey:@"Address"];
//		destPort = [[self server] objectForKey:@"Port"];
//		objects = [NSArray arrayWithObjects:filesToSend, 
//						[NSNumber numberWithInt:compression],
//						ts,
//						[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], 
//						calledAET, 
//						hostname, 
//						destPort, 
//						nil];
//		keys = [NSArray arrayWithObjects:@"filesToSend", 
//					@"compression", 
//					@"transferSyntax",
//					@"callingAET", 
//					@"calledAET", 
//					@"hostname", 
//					@"port", 
//					nil];
//	}
//	NetworkSendDataHandler *dataHandler = [[[NetworkSendDataHandler alloc] initWithDebugLevel:0] autorelease];
//	[dataHandler setCalledAET:calledAET];
//	
//	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjects:objects forKeys:keys];
//	[params setObject:dataHandler forKey:@"receivedDataHandler"];
//	
//	DCMStoreSCU *storeSCU = [DCMStoreSCU sendWithParameters:(NSDictionary *)params];
//	
//	/*
//	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
//			calledAET:calledAET 
//			hostname:hostname 
//			port:[destPort intValue] 
//			filesToSend:(NSArray *)filesToSend
//			transferSyntax:(NSString *)transferSyntax
//			compression: 1.0
//			extraParameters:nil];
//	[storeSCU run:self];
//*/
//	[filesToSend release];
//
//	NSMutableDictionary *info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:[filesToSend count]] forKey:@"SendTotal"];
//	[info setObject:[NSNumber numberWithInt:[filesToSend count]] forKey:@"NumberSent"];
//	[info setObject:[NSNumber numberWithBool:YES] forKey:@"Sent"];
//	[info setObject:calledAET forKey:@"CalledAET"];
//	
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMSendStatus" object:nil userInfo:info];
//	
//	[self performSelectorOnMainThread:@selector(closeSendPanel:) withObject:nil waitUntilDone:YES];	
//	
//	[pool release];
//	//need to unlock to allow release of self after send complete
//	[_lock unlock];
//	
//}

- (void) sendDICOMFilesOffis:(NSMutableArray *)files
{
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	NSMutableArray		*filesToSend = [files retain];
	
	NSString *calledAET;
	NSString *hostname;
	NSString *destPort;
	NSString *transferSyntax;
	NSLog(@"Server destination: %@", [[self server] description]);	
	
	if ([[self server] isMemberOfClass: [NSNetService class]]){
		calledAET = [[self server] name];
		hostname = [[self server] hostName];
		destPort = [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:[self server]]];

	}
	else{
		calledAET = [[self server] objectForKey:@"AETitle"];
		hostname = [[self server] objectForKey:@"Address"];
		destPort = [[self server] objectForKey:@"Port"];
	}
	

	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
			calledAET:calledAET 
			hostname:hostname 
			port:[destPort intValue] 
			filesToSend:(NSArray *)filesToSend
			transferSyntax:_offisTS
			compression: 1.0
			extraParameters:nil];
	sendSCU = storeSCU;
	[storeSCU run:self];
	
	[filesToSend release];

	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	[info setObject:[NSNumber numberWithInt:[filesToSend count]] forKey:@"SendTotal"];
	[info setObject:[NSNumber numberWithInt:[filesToSend count]] forKey:@"NumberSent"];
	[info setObject:[NSNumber numberWithBool:YES] forKey:@"Sent"];
	[info setObject:calledAET forKey:@"CalledAET"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMSendStatus" object:nil userInfo:info];
	
	[self performSelectorOnMainThread:@selector(closeSendPanel:) withObject:nil waitUntilDone:YES];	
	
	[pool release];
	//need to unlock to allow release of self after send complete
	[_lock unlock];
	
}

- (void)closeSendPanel:(id)sender{
	[_waitSendWindow close];			
	[_waitSendWindow release];			
	_waitSendWindow = 0L;	
}

/*
- (void) sendDICOMFilesOffis:(NSMutableArray *)files
{
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	NSMutableArray		*filesToSend = [files retain];
	NSString			*path;
	NSTask              *theTask;
		
	

	{
	
		NSMutableArray *theArguments = [NSMutableArray array];
		NSPipe *thePipe = [NSPipe pipe];
		NSPipe *errorPipe = [NSPipe pipe];
		
		theTask = [[NSTask alloc] init];
		[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];	// DO NOT REMOVE !
		[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/storescu"]];
		
		
		
		if ([[self server] isMemberOfClass: [NSNetService class]]){
			[theArguments addObject: [[self server] hostName]];
			[theArguments addObject: [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:[self server]]]];
		}
		else{
			[theArguments addObject: [[self server] objectForKey:@"Address"]];
			[theArguments addObject: [[self server] objectForKey:@"Port"]];
		}		
		
		[theArguments addObjectsFromArray: filesToSend];
		
		[theArguments addObject: @"-aec"];
		if ([[self server] isMemberOfClass: [NSNetService class]])
			[theArguments addObject: [[self server] name]];
		else			
			[theArguments addObject: [[self server] objectForKey:@"AETitle"]];
		[theArguments addObject: @"-aet"];
		[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]];
		
		switch(_offisTS)
		{
			case SendImplicitLittleEndian:		[theArguments addObject:@"-xi"];	NSLog(@"-xi Implicit");				break;
			case SendExplicitLittleEndian:		[theArguments addObject:@"-xe"];	NSLog(@"-xe Explicit Little");		break;
			case SendExplicitBigEndian:			[theArguments addObject:@"-xb"];	NSLog(@"-xb Explicit Big");			break;
			case SendJPEGLossless:				[theArguments addObject:@"-xs"];	NSLog(@"-xs JPEG lossless");		break;
			case SendRLE:						[theArguments addObject:@"-xr"];	NSLog(@"-xr RLE");					break;
			case SendJPEG2000Lossless:			[theArguments addObject:@"-xv"];	NSLog(@"-xv JPEG 2000 lossless");	break;
		}
		
		[theTask setArguments:theArguments];
		
		[theTask setStandardOutput:thePipe];
		[theTask setStandardError:errorPipe];
		
		[_waitSendWindow setCancel:YES];
		// launch traceroute
		[theTask launch];
		while( [theTask isRunning] == YES && [_waitSendWindow aborted] == NO)
		{
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
		}
		
		if( [_waitSendWindow aborted] == NO)
		{
			NSData  *errData = [[errorPipe fileHandleForReading] availableData];
			NSData  *resData = [[thePipe fileHandleForReading] availableData];
			
			NSString    *errString = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
			NSString    *resString = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
			
			NSLog( errString);
			NSLog( resString);
			
			[errString release];
			[resString release];
		}

		
		[theTask interrupt];
		[theTask release];
		
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:[filesToSend count]] forKey:@"SendTotal"];
		[info setObject:[NSNumber numberWithInt:[filesToSend count]] forKey:@"NumberSent"];
		[info setObject:[NSNumber numberWithBool:YES] forKey:@"Sent"];
		if ([[self server] isMemberOfClass:[NSNetService class]])
			[info setObject:[[self server] name] forKey:@"CalledAET"]; 
		else
			[info setObject:[[self server] objectForKey:@"AETitle"] forKey:@"CalledAET"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMSendStatus" object:nil userInfo:info];
		
	}
	
	[filesToSend release];
	[pool release];
	
	[_lock unlock];
	
}
*/

- (void) setSendMessageThread:(NSDictionary*) info
{
	int count = [[info objectForKey:@"SendTotal"] intValue];
	int numberSent = [[info objectForKey:@"NumberSent"] intValue];

	if( _waitSendWindow)
	{
		[_waitSendWindow incrementBy:1];
		[[[_waitSendWindow window] contentView] setNeedsDisplay:YES];

		if( numberSent >= count-1)
		{
			[_waitSendWindow close];
			[_waitSendWindow release];
			_waitSendWindow = 0L;
		}
	}
}

- (void)setSendMessage:(NSNotification *)note
{
	[self performSelectorOnMainThread:@selector(setSendMessageThread:) withObject:[note userInfo] waitUntilDone:YES]; // <- GUI operations are permitted ONLY on the main thread
}

#pragma mark serversArray functions

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	
	if ([aComboBox isEqual:serverList])
	{
		//add BONJOUR DICOM also		
		int count = [serversArray count] + [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] count];		
		return count;
	}
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];


	if ([aComboBox isEqual:serverList]){
		if( index > -1 && index < [serversArray count])
		{
			id theRecord = [serversArray objectAtIndex: index];			
			return [NSString stringWithFormat:@"%@ - %@",[theRecord objectForKey:@"AETitle"],[theRecord objectForKey:@"Description"]];
		}
		else if( index > -1) {
			id service = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:index - ([serversArray count])];
			return [NSString stringWithFormat:NSLocalizedString(@"%@ - Bonjour", nil), [service name]];
		}
			
	}
	return nil;
}

//- (void)comboBoxSelectionDidChange:(NSNotification *)notification
//{
//	if ([[self server] isMemberOfClass: [NSNetService class]])
//	{
//		[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[self server] hostName], [NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:[self server]]]]];
//	}
//	else
//	{
//		[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[self server] objectForKey:@"Address"], [[self server] objectForKey:@"Port"]]];
//	}
//
//	
//}

- (void)listenForAbort:(id)handler{
	[sendSCU abort];
}

- (void)abort{
	[self listenForAbort:nil];
}


@end
