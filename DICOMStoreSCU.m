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



#import <Osirix/DCM.h>
#import "DICOMStoreSCU.h"
#import "PMDICOMStoreSCU.h"
#import "DICOMLogger.h"
#import "Wait.h"

NSString *tempPath = @"/tmp/OsiriXSend";
BOOL useExplicit;

@implementation DICOMStoreSCU

- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort files:(NSArray *)filenames transferSyntax:(DCMTransferSyntax*)ts quality:(int)q{
	if (self = [super init]){
		int debug = 0;
		if (DEBUG)
			debug = 2;
		callingAET = [myAET retain];
		calledAET = [theirAET retain];
		hostname = [host retain];
		port = [tcpPort intValue];
		files = [filenames retain];
		transferSyntax = [ts retain];
		quality =q;
		//NSLog(@"port %d", port);
		if (!transferSyntax)
			transferSyntax = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
		
		//make sure temp Folder exists
		
		NSFileManager *manager = [NSFileManager defaultManager];
		if (![manager fileExistsAtPath:tempPath]) {
			[manager createDirectoryAtPath:tempPath attributes:nil];
			if (DEBUG)
				NSLog(@"create Temp Folder");
		}
				
		NS_DURING
			Class StoreSCU = NSClassFromString(@"com.pixelmed.network.DICOMStoreSCU");
			storeSCU = [StoreSCU newWithSignature:@"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)", hostname, tcpPort, calledAET, callingAET, debug];
		NS_HANDLER
			NSLog(@"failed to create storeSCU");
			return nil;
		NS_ENDHANDLER
	}
	if (storeSCU)
		return self;
	else 
		return nil;
}


-(void)dealloc{
	[callingAET release];
	[calledAET release];
	[hostname release];
	[transferSyntax release];
	[storeSCU release];
	[files release];
}
	

-(BOOL)send:(NSString *)file{
	NSString *tempPath = @"/tmp/OsiriXSend";
	DCMTransferSyntax *ex = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString *newPath = [NSString stringWithFormat:@"%@/%@", tempPath, globallyUniqueString];
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
	if (DEBUG)
		NSLog(@"transfer Syntax: %@ ts: %@ quality:%d",transferSyntax, [transferSyntax description], quality);
	[dcmObject writeToFile:newPath withTransferSyntax:transferSyntax quality:quality atomically:YES];
	BOOL sent;
	NS_DURING
		//sent = [storeSCU sendFile:file :0];	
		sent = [storeSCU sendFile:newPath :0];
	NS_HANDLER
		NSLog(@"Send failed. Trying Explicit VR Little Endian Transfer Syntax");
		if (![transferSyntax isEqualToTransferSyntax:ex])	{	
			[transferSyntax release];
			transferSyntax = [ex retain];
			sent = [self send:file];
		}
	//	return NO;
	NS_ENDHANDLER
	[[NSFileManager defaultManager] removeFileAtPath:newPath handler:nil];
	return sent;
}

-(void)startSend:(id)sender{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSEnumerator *enumerator = [files objectEnumerator];
	NSString *file;
	int numberSent = 0;
	int count = [files count];
	int errorCount = 0;
	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	[info setObject:[NSNumber numberWithInt:count] forKey:@"SendTotal"];
	[info setObject:[NSNumber numberWithInt:0] forKey:@"NumberSent"];
	[info setObject:[NSNumber numberWithBool:NO] forKey:@"Sent"];
	[info setObject:calledAET forKey:@"CalledAET"];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

	while (file = [enumerator nextObject]) {
	
	
		if ([self send:file])
			[info setObject:[NSNumber numberWithInt:++numberSent] forKey:@"NumberSent"];
		else
			[info setObject:[NSNumber numberWithInt:++errorCount] forKey:@"ErrorCount"];

			[center postNotificationName:@"DICOMSendStatus" object:nil userInfo:info];
	}
	[info setObject:[NSNumber numberWithBool:YES] forKey:@"Sent"];
	[center postNotificationName:@"DICOMSendStatus" object:nil userInfo:info];
	
	NSString *log = [NSString stringWithFormat:@"Destination: %@\tTime: %@\tNumber Of Images: %d\tSent: %d\tError: %d", calledAET,  [[NSDate date] descriptionWithCalendarFormat:@"%Y %b %d %H:%M:%S" timeZone:nil locale:nil],count,numberSent,errorCount];
	NSString *path = @"~/Library/Logs/osirix.log";
	NSString *fullPath = [path stringByExpandingTildeInPath];
	
	[DICOMLogger log:log atPath:fullPath];
	
	[pool release];
	[sender storeSCPComplete:self];
}

@end
