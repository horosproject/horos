/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "BonjourPublisher.h"
#import "BonjourBrowser.h"
#import "DCMPix.h"
#import "DCMTKStoreSCU.h"
#import "SendController.h"
#import "DicomStudy.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "NSUserDefaultsController+N2.h"

// imports required for socket initialization
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

// BY DEFAULT OSIRIX USES 8780 PORT

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static BonjourPublisher *currentPublisher = nil;

extern const char *GetPrivateIP();


@interface BonjourPublisher ()

@property(retain, readwrite) NSNetService* netService;

@end


@implementation BonjourPublisher

//@synthesize serviceName;
@synthesize netService;

+ (BonjourPublisher*) currentPublisher
{
	return currentPublisher;
}

- (id) initWithBrowserController: (BrowserController*) bC
{
	self = [super init];
	if (self != nil)
	{
		currentPublisher = self;
//		self.serviceName = [NSUserDefaultsController defaultServiceName];
		interfaceOsiriX = bC;
		
		fdForListening = 0;
		listeningSocket = nil;
		self.netService = nil;
		
		connectionLock = [[NSLock alloc] init];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingNameDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingPasswordFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingPasswordDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];		
	}
	return self;
}

- (void) dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingNameDefaultsKey];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingPasswordFlagDefaultsKey];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingPasswordDefaultsKey];

	[dicomSendLock release];
//	self.serviceName = NULL;
	[connectionLock release];
	
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
		keyPath = [keyPath substringFromIndex:7];
		if ([keyPath isEqual:OsirixBonjourSharingActiveFlagDefaultsKey]) {
			[self toggleSharing:[NSUserDefaultsController isBonjourSharingActive]];
			return;
		} else
		if ([keyPath isEqual:OsirixBonjourSharingNameDefaultsKey]) {
		//	[self ];
			return;
		} else
		if ([keyPath isEqual:OsirixBonjourSharingPasswordFlagDefaultsKey]) {
			return;
		} else
		if ([keyPath isEqual:OsirixBonjourSharingPasswordDefaultsKey]) {
			return;
		}
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (int) OsiriXDBCurrentPort
{
	return OsiriXDBCurrentPort;
}

- (void) toggleSharing:(BOOL) activated
{
    uint16_t chosenPort;
    if( !listeningSocket)
	{
        // Here, create the socket from traditional BSD socket calls, and then set up an NSFileHandle with
        //that to listen for incoming connections.
		
		if( fdForListening)
			close( fdForListening);
		fdForListening = 0;
	
        struct sockaddr_in serverAddress;
        socklen_t namelen = sizeof(serverAddress);
		
        // In order to use NSFileHandle's acceptConnectionInBackgroundAndNotify method, we need to create a
        // file descriptor that is itself a socket, bind that socket, and then set it up for listening. At this
        // point, it's ready to be handed off to acceptConnectionInBackgroundAndNotify.
        if((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0)
		{
//			int sock_buf_size = 10000;
//	
//			setsockopt( fdForListening, SOL_SOCKET, SO_SNDBUF, (char *)&sock_buf_size, sizeof(sock_buf_size) );
//			setsockopt( fdForListening, SOL_SOCKET, SO_RCVBUF, (char *)&sock_buf_size, sizeof(sock_buf_size) );

            memset(&serverAddress, 0, sizeof(serverAddress));
            serverAddress.sin_family = AF_INET;
            serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
            serverAddress.sin_port = htons(8780); //make it endian independent
			
            // Allow the kernel to choose a random port number by passing in 0 for the port.
            if (bind(fdForListening, (struct sockaddr *)&serverAddress, namelen) < 0)
			{
				NSLog(@"bind failed... select another port than 8780");
				
				serverAddress.sin_port = htons(0);
				if (bind(fdForListening, (struct sockaddr *)&serverAddress, namelen) < 0)
				{
					close (fdForListening);
					fdForListening = 0;
					return;
				}
            }
			
            // Find out what port number was chosen.
            if (getsockname(fdForListening, (struct sockaddr *)&serverAddress, &namelen) < 0)
			{
                close(fdForListening);
				fdForListening = 0;
                return;
            }
			
            chosenPort = ntohs(serverAddress.sin_port);
			
			if( chosenPort != 8780)
			{
				NSString *exampleAlertSuppress = @"Bonjour Port";
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				if ([defaults boolForKey:exampleAlertSuppress])
				{
				}
				else
				{
					NSAlert* alert = [[NSAlert new] autorelease];
					[alert setMessageText: NSLocalizedString(@"Bonjour Port", nil)];
					[alert setInformativeText : NSLocalizedString(@"Cannot use port 8780 for Bonjour sharing. It is already used, another port will be selected.", nil)];
					[alert setShowsSuppressionButton:YES];
					[alert runModal];
					if ([[alert suppressionButton] state] == NSOnState)
					{
						[defaults setBool:YES forKey:exampleAlertSuppress];
					}
				}
			}
			
			NSLog(@"Chosen port for DB sharing: %d", chosenPort);
			
			OsiriXDBCurrentPort = chosenPort;

			// Once we're here, we know bind must have returned, so we can start the listen
			if(listen(fdForListening, 1) == 0)
			{
				listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:fdForListening closeOnDealloc: NO];
				
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionReceived:) name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
				[listeningSocket acceptConnectionInBackgroundAndNotify];
			}
		}
    }

    if (!netService)
	{
        // lazily instantiate the NSNetService object that will advertise on our behalf.  Passing in "" for the domain causes the service
        // to be registered in the default registration domain, which will currently always be "local"
        netService = [[NSNetService alloc] initWithDomain:@"" type:@"_osirixdb._tcp." name:[NSUserDefaultsController bonjourSharingName] port:chosenPort];
        [netService setDelegate:self];
		
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] forKey: @"AETitle"];
		[params setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]  forKey: @"port"];
		
		if( [netService setTXTRecordData: [NSNetService dataFromTXTRecordDictionary: params]] == NO)
		{
			NSLog( @"ERROR - NSNetService setTXTRecordData FAILED");
		}
    }

    if (netService && listeningSocket)
	{
        if( activated)
            [netService publish];
		else
            [netService stop];
    }
	
	dbPublished = activated;
}

//- (NSData *)dataByZippingLocalPath:(NSString *)_path
//{
//  NSFileHandle  *nullHandle  = nil;
//  NSFileHandle  *zipHandle   = nil;
//  NSPipe        *zipPipe     = nil;
//  NSTask        *zipTask     = nil;
//  NSData        *result      = nil;
//  NSString      *compression = nil;
//
//  int _level = 6;
//
//  // man zip writes, 6 is the default value
//  compression = [NSString stringWithFormat: @"-%d", (_level < 0 || _level > 9) ? 6 : _level];
//
//  zipPipe    = [NSPipe pipe];
//  zipHandle  = [zipPipe fileHandleForReading];
//  nullHandle = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
//  zipTask    = [[NSTask alloc] init];
//  [zipTask setLaunchPath:@"/usr/bin/zip"];
//  [zipTask setCurrentDirectoryPath: [_path stringByDeletingLastPathComponent]];
//  [zipTask setArguments: [NSArray arrayWithObjects:@"-qr", compression, @"-", [_path lastPathComponent], nil]];
//  [zipTask setStandardOutput:zipPipe];
//  [zipTask setStandardError:nullHandle];
//  [zipTask launch];
//
//  result     = [zipHandle readDataToEndOfFile];
//
//  [zipTask release];
//  return result;
//}

- (void) sendDICOMFilesToOsiriXNode:(NSDictionary*) todo
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if( dicomSendLock == nil) dicomSendLock = [[NSLock alloc] init];
	[dicomSendLock lock];
	
	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc]	initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
																calledAET: [todo objectForKey:@"AETitle"] 
																hostname: [todo objectForKey:@"Address"] 
																port: [[todo objectForKey:@"Port"] intValue] 
																filesToSend: [todo valueForKey: @"Files"]
																transferSyntax: [[todo objectForKey:@"TransferSyntax"] intValue] 
																compression: 1.0
																extraParameters: nil];
							
	@try
	{
		[storeSCU run:self];
	}
	
	@catch (NSException *ne)
	{
		NSLog( @"Bonjour DICOM Send FAILED");
		NSLog( @"%@", [ne name]);
		NSLog( @"%@", [ne reason]);
	}
	
	[storeSCU release];
	storeSCU = nil;
	
	[dicomSendLock unlock];
	
	[pool release];
}

- (void) subConnectionReceived:(NSFileHandle *)incomingConnection
{
	NSAutoreleasePool	*mPool = [[NSAutoreleasePool alloc] init];

	BOOL saveDB = NO;
	BOOL refreshDB = NO;

	[incomingConnection retain];
	
	[[interfaceOsiriX managedObjectContext] lock];
	
	if( dbPublished)
	{
		@try
		{
			NSData				*readData;
			NSMutableData		*data = [NSMutableData dataWithCapacity: 512*512*2*2];
			NSMutableData		*representationToSend = nil;
			
			if( incomingConnection)
			{
				// Waiting for incomming message (6 first bytes)
				while ( [data length] < 6 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				
				if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DATAB" length: 6]])
				{
					[interfaceOsiriX saveDatabase: nil];
					
					// we send the database SQL file
					NSString *databasePath = [interfaceOsiriX localDatabasePath];
					
					#if __LP64__
						representationToSend = [NSMutableData dataWithContentsOfMappedFile: databasePath];
						[incomingConnection writeData:representationToSend];
					#else
						NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: databasePath traverseLink: YES];
						long long fileSize = [[fattrs objectForKey:NSFileSize] longLongValue];
					
						fileSize /= 1024;	// Kb
						fileSize /= 1024;	// Mb
						
						#define DATA_READ_SIZE 200L
						
						if( fileSize > DATA_READ_SIZE)
						{
							NSFileHandle *dbFileHandle = [NSFileHandle fileHandleForReadingAtPath: databasePath];
							NSLog( @"split DB file reading");
							int length = 0;
							do
							{
								NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];
								
								NSData *chunk = [dbFileHandle readDataOfLength: DATA_READ_SIZE * 1024L*1024L];
								[incomingConnection writeData: chunk];
								length = [chunk length];
								
								[arp release];
							}
							while( length > 0);
						}
						else
						{
							representationToSend = [NSMutableData dataWithContentsOfMappedFile: databasePath];
							[incomingConnection writeData:representationToSend];
						}
					#endif
					
					struct sockaddr serverAddress;
					socklen_t namelen = sizeof(serverAddress);
					
					if (getsockname( [incomingConnection fileDescriptor], (struct sockaddr *)&serverAddress, &namelen) >= 0)
					{
						char client_ip_address[20];
						sprintf(client_ip_address, "%-d.%-d.%-d.%-d", ((int) serverAddress.sa_data[2]) & 0xff, ((int) serverAddress.sa_data[3]) & 0xff, ((int) serverAddress.sa_data[4]) & 0xff, ((int) serverAddress.sa_data[5]) & 0xff);
						NSLog( @"Bonjour Connection Received from: %s", client_ip_address);
					}
				}
				else
				{
					if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DBSIZ" length: 6]])
					{
						[interfaceOsiriX saveDatabase: nil];
						NSString *databasePath = [interfaceOsiriX localDatabasePath];
						
						NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: databasePath traverseLink: YES];
						
						int size, fileSize = [[fattrs objectForKey:NSFileSize] longLongValue];
						
						representationToSend = [NSMutableData data];
						
						NSLog( @"DB fileSize = %d", fileSize);
						
						size = NSSwapHostIntToBig( fileSize);
						[representationToSend appendBytes: &size length: 4];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"GETDI" length: 6]])
					{
						NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"AETitle", [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"], @"Port", [NSString stringWithFormat: @"%d", [DCMTKStoreSCU sendSyntaxForListenerSyntax: [[NSUserDefaults standardUserDefaults] integerForKey: @"preferredSyntaxForIncoming"]]], @"TransferSyntax", nil];
						
						representationToSend = [NSMutableData dataWithData: [NSArchiver archivedDataWithRootObject: dictionary]];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"VERSI" length: 6]])
					{
						//NSLog( @"[data bytes] = VERSI");
						
		//				// we send the modification date of the SQL file
		//				NSString *databasePath = [interfaceOsiriX localDatabasePath];
		//				
		//				NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:databasePath traverseLink:YES];
		//				NSDate *moddate = [fattrs objectForKey:NSFileModificationDate];
		//				NSTimeInterval val = 0;
		//				if( moddate)
		//				{
		//					val = [moddate timeIntervalSinceReferenceDate];
		//				}
						
						NSTimeInterval val = [interfaceOsiriX databaseLastModification];
						
						NSSwappedDouble swappedValue = NSSwapHostDoubleToBig( val);
						
						if( sizeof( swappedValue.v) != 8) NSLog(@"********** warning sizeof( swappedValue) != 8");
						
						representationToSend = [NSMutableData dataWithBytes: &swappedValue.v length:sizeof(NSTimeInterval)];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DBVER" length: 6]])
					{
						NSString	*versString = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
						
						representationToSend = [NSMutableData dataWithData: [versString dataUsingEncoding: NSASCIIStringEncoding]];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"ISPWD" length: 6]])
					{
						// is this database protected by a password
						NSString* pswd = [NSUserDefaultsController bonjourSharingPassword];
						
						int val = 0;
						
						if (pswd) val = NSSwapHostIntToBig(1);
						else val = 0;
						
						representationToSend = [NSMutableData dataWithBytes: &val length:sizeof(int)];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"PASWD" length: 6]])
					{
						int pos = 6, stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *incomingPswd = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						int val = 0;
						
						if (![NSUserDefaultsController bonjourSharingPassword] || [incomingPswd isEqualToString: [NSUserDefaultsController bonjourSharingPassword]])
						{
							val = NSSwapHostIntToBig(1);
						}
						
						representationToSend = [NSMutableData dataWithBytes: &val length:sizeof(int)];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,4)] isEqualToData: [NSData dataWithBytes:"SEND" length: 4]]) // SENDD & SENDG
					{
						int pos = 6, i;
						
						NSString *order = [NSString stringWithCString: [[data subdataWithRange: NSMakeRange(0,6)] bytes]];
						
						// We read 4 bytes that contain the no of file
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						int fileNo;
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &fileNo];
						fileNo = NSSwapBigIntToHost( fileNo);
						pos += 4;
						
						NSMutableArray *savedFiles = [NSMutableArray array];
						
						for( i = 0 ; i < fileNo; i++)
						{			
							// We read 4 bytes that contain the file size
							while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							
							int fileSize;
							[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &fileSize];
							fileSize = NSSwapBigIntToHost( fileSize);
							pos += 4;
							
							while ( [data length] < pos + fileSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							
							NSString *dstPath = [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"];
							[[data subdataWithRange: NSMakeRange(pos,fileSize)] writeToFile: dstPath atomically: YES];
							
							[savedFiles addObject: dstPath];
							
							pos += fileSize;
						}
						
						BOOL generatedByOsiriX = NO;
						if( [order isEqualToString: @"SENDD"]) generatedByOsiriX = NO;
						else if( [order isEqualToString: @"SENDG"]) generatedByOsiriX = YES;
						else
							NSLog( @"******* unknown order: %@", order);
							
						NSArray *objects = [BrowserController addFiles: savedFiles
															toContext: [[BrowserController currentBrowser] localManagedObjectContext]
															toDatabase: [BrowserController currentBrowser]
															onlyDICOM: NO 
														notifyAddedFiles: YES
													parseExistingObject: YES
														dbFolder: [[BrowserController currentBrowser] documentsDirectory]
													generatedByOsiriX: generatedByOsiriX];
						
						representationToSend = nil;
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"NEWMS" length: 6]]) // New Messaging System
					{
						int pos = 6, stringSize;
						
						// We read 4 bytes that contain the data size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the data
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSDictionary *d = [NSPropertyListSerialization propertyListFromData: [data subdataWithRange: NSMakeRange(pos,stringSize)] mutabilityOption: NSPropertyListImmutable format: nil errorDescription: nil];
						pos += stringSize;
						
						if( d)
						{
							NSString *message = [d objectForKey:@"message"];
						}
						
						representationToSend = nil;
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"ADDAL" length: 6]])
					{
						int pos = 6, stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *object = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						if( [object writeToFile:@"/tmp/ADDAL" atomically: YES])
						{
							NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile: @"/tmp/ADDAL"];
							
							NSArray *studies = [d objectForKey:@"albumStudies"];
							NSString *albumUID = [d objectForKey:@"albumUID"];
							
							NSManagedObjectContext *context = [interfaceOsiriX defaultManagerObjectContext];
							[context lock];
							
							@try
							{
								NSManagedObject *albumObject = [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: albumUID]]];
								NSMutableSet	*studiesOfTheAlbum = [albumObject mutableSetValueForKey: @"studies"];
								
								for( NSString *uri in studies)
								{
									DicomStudy *alb = (DicomStudy*) [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: uri]]];
									[studiesOfTheAlbum addObject: alb];
									[alb archiveAnnotationsAsDICOMSR];
								}
								
								refreshDB = YES;
								saveDB = YES;
							}
							
							@catch (NSException * e)
							{
								NSLog(@"Exception in BonjourPublisher ADDAL: %@");
							}
							
							NSError *error = nil;
							[context save: &error];
							[context unlock];
						}
						
						representationToSend = nil;
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"REMAL" length: 6]])
					{
						int pos = 6, stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *object = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						if( [object writeToFile:@"/tmp/REMAL" atomically: YES])
						{
							NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile: @"/tmp/REMAL"];
							
							NSArray *studies = [d objectForKey:@"albumStudies"];
							NSString *albumUID = [d objectForKey:@"albumUID"];
							
							NSManagedObjectContext *context = [interfaceOsiriX defaultManagerObjectContext];
							[context lock];
							
							@try
							{
								NSManagedObject *albumObject = [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: albumUID]]];
								NSMutableSet	*studiesOfTheAlbum = [albumObject mutableSetValueForKey: @"studies"];
								
								for( NSString *uri in studies)
								{
									DicomStudy *alb = (DicomStudy*) [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: uri]]];
									[studiesOfTheAlbum removeObject: alb];
									[alb archiveAnnotationsAsDICOMSR];
								}
								
								refreshDB = YES;
								saveDB = YES;
							}
							
							@catch (NSException * e)
							{
								NSLog(@"Exception in BonjourPublisher REMAL: %@");
							}
							
							NSError *error = nil;
							[context save: &error];
							[context unlock];
						}
						
						representationToSend = nil;
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"SETVA" length: 6]])
					{
						int pos = 6, stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *object = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						NSString *value;
						if( stringSize == 0)
						{
							value = nil;
						}
						else
						{
							while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							value = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
							pos += stringSize;
						}
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *key = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						NSManagedObjectContext *context = [interfaceOsiriX defaultManagerObjectContext];
						[context lock];
						
						@try
						{					
							NSManagedObject	*item = [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: object]]];
							
							//NSLog(@"URL:%@", object);
							if( item)
							{
								if( [[item valueForKeyPath: key] isKindOfClass: [NSNumber class]]) [item setValue: [NSNumber numberWithInt: [value intValue]] forKeyPath: key];
								else
								{
									if( [key isEqualToString: @"reportURL"] == YES)
									{
										if( value == nil)
										{
											[[NSFileManager defaultManager] removeFileAtPath:[item valueForKeyPath: key] handler:nil];
										}
										else if( [[key pathComponents] count] == 1)
										{
											value = [[[interfaceOsiriX documentsDirectory] stringByAppendingPathComponent: @"/REPORTS/"] stringByAppendingPathComponent: [value lastPathComponent]];
										}
									}
									
									[item setValue: value forKeyPath: key];
								}
							}
						}
						
						@catch (NSException *e)
						{
							NSLog(@"***** BonjourPublisher Exception: %@", e);
						}
						
						NSError *error = nil;
						[context save: &error];
						[context unlock];
						
						refreshDB = YES;
						saveDB = YES;
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"MFILE" length: 6]])
					{
						int pos = 6, stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *path = [[[NSString alloc] initWithData: [data subdataWithRange: NSMakeRange(pos,stringSize)] encoding: NSUnicodeStringEncoding] autorelease];
						pos += stringSize;
						
						if( [path length])
						{
							if( [path characterAtIndex: 0] != '/')
								path = [[interfaceOsiriX fixedDocumentsDirectory] stringByAppendingPathComponent: path];
						}
						
						NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
						
						NSData	*content = [[[fattrs objectForKey:NSFileModificationDate] description] dataUsingEncoding: NSUnicodeStringEncoding];
						
						representationToSend = [NSMutableData dataWithData: content];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DCMSE" length: 6]])
					{
						NSMutableArray	*localPaths = [NSMutableArray array];
						
						int pos = 6, noOfFiles = 0, stringSize, i;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *AETitle = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *Address = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *Port = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						// We read 4 bytes that contain the string size
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
						pos += 4;
						// We read the string
						while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						NSString *TransferSyntax = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
						pos += stringSize;
						
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &noOfFiles];	noOfFiles = NSSwapBigIntToHost( noOfFiles);
						pos += 4;
						
						representationToSend = [NSMutableData dataWithCapacity: 0];
						
						for( i = 0; i < noOfFiles; i++)
						{
							// We read 4 bytes that contain the string size
							while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
							pos += 4;
							
							// We read the string
							while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							NSString *path = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
							pos += stringSize;
							
							if( [path UTF8String] [ 0] != '/')
							{
								
								int val = [[path stringByDeletingPathExtension] intValue];
								
								NSString *dbLocation = [interfaceOsiriX localDatabasePath];
								
								val /= [BrowserController DefaultFolderSizeForDB];
								val++;
								val *= [BrowserController DefaultFolderSizeForDB];
								
								path = [[dbLocation stringByDeletingLastPathComponent] stringByAppendingFormat:@"/DATABASE.noindex/%d/%@", val, path];
							}
							
							[localPaths addObject: path];
						}
						
						if( [Address isEqualToString: @"127.0.0.1"])
						{
							struct sockaddr serverAddress;
							socklen_t namelen = sizeof( serverAddress);
							
							if (getsockname( [incomingConnection fileDescriptor], (struct sockaddr *)&serverAddress, &namelen) >= 0)
							{
								char client_ip_address[ 64];
								sprintf( client_ip_address, "%-d.%-d.%-d.%-d", ((int) serverAddress.sa_data[2]) & 0xff, ((int) serverAddress.sa_data[3]) & 0xff, ((int) serverAddress.sa_data[4]) & 0xff, ((int) serverAddress.sa_data[5]) & 0xff);
								Address = [NSString stringWithCString: client_ip_address encoding: NSUTF8StringEncoding];
							}
						}
						
						NSDictionary *todo = [NSDictionary dictionaryWithObjectsAndKeys: Address, @"Address", TransferSyntax, @"TransferSyntax", Port, @"Port", AETitle, @"AETitle", localPaths, @"Files", nil];
						
						[NSThread detachNewThreadSelector:@selector( sendDICOMFilesToOsiriXNode:) toTarget:self withObject: todo];
					}
					else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DICOM" length: 6]])
					{
						NSMutableArray	*localPaths = [NSMutableArray array];
						NSMutableArray	*dstPaths = [NSMutableArray array];
						
						// We read now the path for the DICOM file(s)
						int pos = 6, size, noOfFiles = 0, stringSize, i;
						
						while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
						
						[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &noOfFiles];	noOfFiles = NSSwapBigIntToHost( noOfFiles);
						pos += 4;
						
						representationToSend = [NSMutableData dataWithCapacity: 512*512*2*(noOfFiles+1)];
						
						for( i = 0; i < noOfFiles; i++)
						{
							// We read 4 bytes that contain the string size
							while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
							pos += 4;
							
							// We read the string
							while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							NSString *path = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
							pos += stringSize;
							
							if( [path UTF8String] [ 0] != '/')
							{
								if( [[[path pathComponents] objectAtIndex: 0] isEqualToString:@"ROIs"])
								{
									//It's a ROI !
									NSString	*local = [[interfaceOsiriX localDatabasePath] stringByDeletingLastPathComponent];
									
									path = [[local stringByAppendingPathComponent:@"/ROIs/"] stringByAppendingPathComponent: [path lastPathComponent]];
								}
								else
								{
									
									int val = [[path stringByDeletingPathExtension] intValue];
									
									val /= [BrowserController DefaultFolderSizeForDB];
									val++;
									val *= [BrowserController DefaultFolderSizeForDB];
									
									NSString	*local = [[interfaceOsiriX localDatabasePath] stringByDeletingLastPathComponent];
									
									path = [[[local stringByAppendingPathComponent:@"/DATABASE.noindex/"] stringByAppendingPathComponent: [NSString stringWithFormat:@"%d", val]] stringByAppendingPathComponent: path];
								}
							}
							
							[localPaths addObject: path];
							
			//				if([[path pathExtension] isEqualToString:@"zip"])
			//				{
			//					// it is a ZIP
			//					NSLog(@"BONJOUR ZIP");
			//					NSString *xmlPath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
			//					NSLog(@"xmlPath : %@", xmlPath);
			//					if([[NSFileManager defaultManager] fileExistsAtPath:xmlPath])
			//					{
			//						// it has an XML descriptor with it
			//						NSLog(@"BONJOUR XML");
			//						[localPaths addObject:xmlPath];
			//					}
			//				}
						}
						
						for( i = 0; i < noOfFiles; i++)
						{
							// We read 4 bytes that contain the string size
							while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
							pos += 4;
							
							// We read the string
							while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
							NSString *path = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
							pos += stringSize;
							
							[dstPaths addObject: path];
							
			//				if([[path pathExtension] isEqualToString:@"zip"])
			//				{
			//					// it is a ZIP
			//					NSLog(@"BONJOUR ZIP");
			//					NSString *xmlPath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
			//					NSLog(@"xmlPath : %@", xmlPath);
			//					if([[NSFileManager defaultManager] fileExistsAtPath:xmlPath])
			//					{
			//						// it has an XML descriptor with it
			//						NSLog(@"BONJOUR XML");
			//						[dstPaths addObject:xmlPath];
			//					}
			//				}
						}
						
						int temp = NSSwapHostIntToBig( noOfFiles);
						[representationToSend appendBytes: &temp length: 4];	
						for( i = 0; i < noOfFiles; i++)
						{
							NSString	*path = [localPaths objectAtIndex: i];
							
	//						if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO)
	//							NSLog( @"Bonjour Publisher - File doesn't exist at path: %@", path);
							
							NSData	*content = [NSData dataWithContentsOfMappedFile: path];
							
							size = NSSwapHostIntToBig( [content length]);
							[representationToSend appendBytes: &size length: 4];
							[representationToSend appendData: content];
							
							const char* string = [[dstPaths objectAtIndex: i] UTF8String];
							int stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
							
							[representationToSend appendBytes:&stringSize length: 4];
							[representationToSend appendBytes:string length: strlen( string)+1];
							
							[incomingConnection writeData: representationToSend];
							[representationToSend setLength: 0];
						}
					}
					
					[incomingConnection writeData: representationToSend];
				}
			}
		}
		@catch( NSException *ne)
		{
			NSLog( @"Exception in ConnectionReceived - Communication Interrupted : %@", ne);
		}
	}
	
	[[interfaceOsiriX managedObjectContext] unlock];
	
	[incomingConnection closeFile];
	[incomingConnection release];
	
	if( refreshDB) [interfaceOsiriX performSelectorOnMainThread:@selector( refreshDatabase:) withObject:nil waitUntilDone: NO];		// This has to be performed on the main thread
	if( saveDB) [interfaceOsiriX performSelectorOnMainThread:@selector( saveDatabase:) withObject:nil waitUntilDone: NO];			// This has to be performed on the main thread
	
	[mPool release];
}

- (void) connectionReceived:(NSNotification *) aNotification
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash - Antoine
    
	[connectionLock lock];
	
	@try 
	{
		[[aNotification object] acceptConnectionInBackgroundAndNotify];
		[NSThread detachNewThreadSelector: @selector (subConnectionReceived:) toTarget: self withObject: [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem]];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[connectionLock unlock];
	
	[pool release];
}

// work as a delegate of the NSNetService
- (void)netServiceWillPublish:(NSNetService*)sender
{
//	[interfaceOsiriX bonjourWillPublish];
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict
{
	// we should send an error message
	// here ...
	
	NSLog(@"did not publish... why?");
    [netService release];
    netService = nil;
}

- (void) netServiceDidStop:(NSNetService *)sender
{
//	[bonjourServiceName setEnabled:YES];
	
	if ([NSUserDefaultsController isBonjourSharingActive])
	{
		NSLog(@"**** Bonjour did stop ! Restarting it!");
		[self toggleSharing:YES];
	}
}

@end
