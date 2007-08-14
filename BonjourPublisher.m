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

#import "BonjourPublisher.h"
#import "BonjourBrowser.h"
#import "DCMPix.h"
#import "DCMTKStoreSCU.h"

// imports required for socket initialization
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

#define USEZIP NO

// BY DEFAULT OSIRIX USES 8780 PORT

extern NSString * documentsDirectory();

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static char *GetPrivateIP()
{
	struct			hostent *h;
	char			hostname[100];
	gethostname(hostname, 99);
	if ((h=gethostbyname(hostname)) == NULL)
	{
        perror("Error: ");
        return "(Error locating Private IP Address)";
    }
	
    return (char*) inet_ntoa(*((struct in_addr *)h->h_addr));
}

@implementation BonjourPublisher

- (id) initWithBrowserController: (BrowserController*) bC
{
	self = [super init];
	if (self != nil)
	{
		serviceName = [[NSString stringWithString:@"OsiriX DataBase"] retain];
		interfaceOsiriX = bC;
		
		fdForListening = 0;
		listeningSocket = 0L;
		netService = 0L;
		
		connectionLock = [[NSLock alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[serviceName release];
	[connectionLock release];
	
	[super dealloc];
}

- (void)toggleSharing:(BOOL)boo
{
    uint16_t chosenPort;
    if(!listeningSocket) {

        // Here, create the socket from traditional BSD socket calls, and then set up an NSFileHandle with
        //that to listen for incoming connections.
		
			
		if(fdForListening) close(fdForListening);
		fdForListening= 0L;
	
        struct sockaddr_in serverAddress;
        socklen_t namelen = sizeof(serverAddress);
		
        // In order to use NSFileHandle's acceptConnectionInBackgroundAndNotify method, we need to create a
        // file descriptor that is itself a socket, bind that socket, and then set it up for listening. At this
        // point, it's ready to be handed off to acceptConnectionInBackgroundAndNotify.
        if((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
            memset(&serverAddress, 0, sizeof(serverAddress));
            serverAddress.sin_family = AF_INET;
            serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
            serverAddress.sin_port = htons(8780); //make it endian independent
			
            // Allow the kernel to choose a random port number by passing in 0 for the port.
            if (bind(fdForListening, (struct sockaddr *)&serverAddress, namelen) < 0)
			{
				NSLog(@"bind failed... select another port than 8780");
				
				NSRunCriticalAlertPanel(NSLocalizedString(@"Bonjour Port",nil), NSLocalizedString(@"Cannot use port 8780 for Bonjour sharing. It is already used.",nil),NSLocalizedString( @"OK",nil), nil, nil);
				
				serverAddress.sin_port = htons(0);
				if (bind(fdForListening, (struct sockaddr *)&serverAddress, namelen) < 0)
				{
					close (fdForListening);
					return;
				}
            }
			
            // Find out what port number was chosen.
            if (getsockname(fdForListening, (struct sockaddr *)&serverAddress, &namelen) < 0) {
                close(fdForListening);
                return;
            }
			
            chosenPort = ntohs(serverAddress.sin_port);

			NSLog(@"Chosen port: %d", chosenPort);		

			// Once we're here, we know bind must have returned, so we can start the listen
			if(listen(fdForListening, 1) == 0) {
				listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:fdForListening closeOnDealloc:NO];
			}
			else listeningSocket = 0L;
		}
    }

    if(!netService) {
        // lazily instantiate the NSNetService object that will advertise on our behalf.  Passing in "" for the domain causes the service
        // to be registered in the default registration domain, which will currently always be "local"
        netService = [[NSNetService alloc] initWithDomain:@"" type:@"_osirix._tcp." name:serviceName port:chosenPort];
        [netService setDelegate:self];
		
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] forKey: @"AETitle"];
		[params setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]  forKey: @"port"];
		
		if( [netService setTXTRecordData: [NSNetService dataFromTXTRecordDictionary: params]] == NO)
		{
			NSLog( @"ERROR - NSNetService setTXTRecordData FAILED");
		}
    }

    if(netService && listeningSocket) {
        if(boo) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionReceived:) name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
            [listeningSocket acceptConnectionInBackgroundAndNotify];
            [netService publish];
			
        } else {
			
            [netService stop];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
            // There is at present no way to get an NSFileHandle to -stop- listening for events, so we'll just have to tear it down and recreate it the next time we need it.
            [listeningSocket release];
            listeningSocket = nil;
        }
    }
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
	
	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc]	initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
																calledAET: [todo objectForKey:@"AETitle"] 
																hostname: [todo objectForKey:@"Address"] 
																port: [[todo objectForKey:@"Port"] intValue] 
																filesToSend: [todo valueForKey: @"Files"]
																transferSyntax: [[todo objectForKey:@"Transfer Syntax"] intValue] 
																compression: 1.0
																extraParameters: nil];
							
	@try
	{
		[storeSCU run:self];
	}
	
	@catch (NSException *ne)
	{
		NSLog( @"Bonjour DICOM Send FAILED");
		NSLog( [ne name]);
		NSLog( [ne reason]);
	}
	
	[storeSCU release];
	storeSCU = 0L;
	
	[pool release];
}

- (void) subConnectionReceived:(NSFileHandle *)incomingConnection
{
	NSAutoreleasePool	*mPool = [[NSAutoreleasePool alloc] init];

	BOOL				saveDB = NO;
	BOOL				refreshDB = NO;

	[incomingConnection retain];
	
	@try
	{
		NSData				*readData;
		NSMutableData		*data = [NSMutableData dataWithCapacity: 512*512*2*2];
		NSMutableData		*representationToSend = 0L;
		
		
		if( incomingConnection)
		{
			// Waiting for incomming message (6 first bytes)
			while ( [data length] < 6 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			
			if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DATAB" length: 6]])
			{
				[interfaceOsiriX saveDatabase: 0L];
				
				// we send the database SQL file
				NSString *databasePath = [interfaceOsiriX localDatabasePath];
				
				representationToSend = [NSMutableData dataWithData: [[NSFileManager defaultManager] contentsAtPath:databasePath]];
				
				struct sockaddr serverAddress;
				socklen_t namelen = sizeof(serverAddress);
				
				if (getsockname( [incomingConnection fileDescriptor], (struct sockaddr *)&serverAddress, &namelen) >= 0)
				{
					char client_ip_address[20];
					sprintf(client_ip_address, "%-d.%-d.%-d.%-d", ((int) serverAddress.sa_data[2]) & 0xff, ((int) serverAddress.sa_data[3]) & 0xff, ((int) serverAddress.sa_data[4]) & 0xff, ((int) serverAddress.sa_data[5]) & 0xff);
					NSLog( @"Bonjour Connection Received from: %s", client_ip_address);
				}
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"GETDI" length: 6]])
			{
				NSString *address = [NSString stringWithCString:GetPrivateIP()];
				
				NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: address, @"Address", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"AETitle", [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"], @"Port", @"0", @"Transfer Syntax", 0L];
				
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
				
				representationToSend = [NSMutableData dataWithBytes: &val length:sizeof(NSTimeInterval)];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DBVER" length: 6]])
			{
				NSString	*versString = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
				
				representationToSend = [NSMutableData dataWithData: [versString dataUsingEncoding: NSASCIIStringEncoding]];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"ISPWD" length: 6]])
			{
				// is this database protected by a password
				NSString *pswd = [interfaceOsiriX bonjourPassword];
				
				int val = 0;
				
				if( pswd) val = NSSwapHostIntToBig(1);
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
				
				if( [incomingPswd isEqualToString: [interfaceOsiriX bonjourPassword]] || [interfaceOsiriX bonjourPassword] == 0L)
				{
					val = NSSwapHostIntToBig(1);
				}
				
				representationToSend = [NSMutableData dataWithBytes: &val length:sizeof(int)];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"SENDD" length: 6]])
			{
				int pos = 6, i;
				
				// We read 4 bytes that contain the no of file
				while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				int fileNo;
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &fileNo];
				fileNo = NSSwapBigIntToHost( fileNo);
				pos += 4;
				
				for( i = 0 ; i < fileNo; i++)
				{			
					// We read 4 bytes that contain the file size
					while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
					
					int fileSize;
					[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &fileSize];
					fileSize = NSSwapBigIntToHost( fileSize);
					pos += 4;
					
					while ( [data length] < pos + fileSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
					
					NSString	*incomingFolder = [documentsDirectory() stringByAppendingPathComponent:@"/INCOMING"];
					NSString	*dstPath;
					
					int index = [NSDate timeIntervalSinceReferenceDate];
					
					do
					{
						dstPath = [incomingFolder stringByAppendingPathComponent: [NSString stringWithFormat:@"%d", index]];
						index++;
					}
					while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
					
					[[data subdataWithRange: NSMakeRange(pos,fileSize)] writeToFile:dstPath atomically: YES];
					
					pos += fileSize;
				}
				
				representationToSend = 0L;
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"SETVA" length: 6]])
			{
				int pos = 6, size, noOfFiles = 0, stringSize, i;
				
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
				if( stringSize == 0L)
				{
					value = 0L;
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
				
				NSManagedObjectContext *context = [interfaceOsiriX managedObjectContext];
				[context retain];
				[context lock];
				NSManagedObject	*item = [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: object]]];
				[context unlock];
				[context release];
				
				//NSLog(@"URL:%@", object);
				if( item)
				{
					if( [[item valueForKeyPath: key] isKindOfClass: [NSNumber class]]) [item setValue: [NSNumber numberWithInt: [value intValue]] forKeyPath: key];
					else
					{
						if( [key isEqualToString: @"reportURL"] == YES)
						{
							if( value == 0L)
							{
								[[NSFileManager defaultManager] removeFileAtPath:[item valueForKeyPath: key] handler:0L];
							}
							else if( [[key pathComponents] count] == 1)
							{
								value = [[documentsDirectory() stringByAppendingPathComponent: @"/REPORTS/"] stringByAppendingPathComponent: [value lastPathComponent]];
							}
						}
						
						[item setValue: value forKeyPath: key];
					}
				}
				
				refreshDB = YES;
				saveDB = YES;
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"MFILE" length: 6]])
			{
				int pos = 6, stringSize, size;
				
				// We read 4 bytes that contain the string size
				while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
				pos += 4;
				
				// We read the string
				while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				NSString *path = [[NSString alloc] initWithData: [data subdataWithRange: NSMakeRange(pos,stringSize)] encoding: NSUnicodeStringEncoding];
				pos += stringSize;
				
				NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
				
				NSData	*content = [[[fattrs objectForKey:NSFileModificationDate] description] dataUsingEncoding: NSUnicodeStringEncoding];
				
				representationToSend = [NSMutableData dataWithData: content];
				
				[path release];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"RFILE" length: 6]])
			{
				NSLog(@"subConnectionReceived : RFILE");
				int pos = 6, stringSize, size;
				
				// We read 4 bytes that contain the string size
				while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
				pos += 4;
				
				// We read the string
				while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				NSMutableString *path = [[NSMutableString alloc] initWithData: [data subdataWithRange: NSMakeRange(pos,stringSize)] encoding: NSUnicodeStringEncoding];
				pos += stringSize;
				
				BOOL isDirectory = NO;
				NSString *zipFileName;
				[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
				if(isDirectory)
				{
					zipFileName = [NSString stringWithFormat:@"%@.zip", [path lastPathComponent]];
					// zip the directory into a single archive file
					NSTask *zipTask   = [[NSTask alloc] init];
					[zipTask setLaunchPath:@"/usr/bin/zip"];
					[zipTask setCurrentDirectoryPath:[[path stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
					[zipTask setArguments:[NSArray arrayWithObjects:@"-r" , zipFileName, [path lastPathComponent], nil]];
					[zipTask launch];
					while( [zipTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
					int result = [zipTask terminationStatus];
					[zipTask release];

					if(result==0)
					{
						NSMutableString *path2 = (NSMutableString*)[[path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", zipFileName];
						[path release];
						path = [path2 retain];
						NSLog(@"path : %@", path);
					}
				}

				NSData	*content = [[NSFileManager defaultManager] contentsAtPath: path];
				
				// Send the file
				
				representationToSend = [NSMutableData data];
				
				stringSize = NSSwapHostIntToBig( [content length]);
				[representationToSend appendBytes:&stringSize length: 4];
				[representationToSend appendData: content];
				
				NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
				content = [[[fattrs objectForKey:NSFileModificationDate] description] dataUsingEncoding: NSUnicodeStringEncoding];
				stringSize = NSSwapHostIntToBig( [content length]);
				[representationToSend appendBytes:&stringSize length: 4];
				[representationToSend appendData: content];
				
				if(isDirectory)
					[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
				[path release];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"WFILE" length: 6]])
			{
				NSLog(@"subConnectionReceived : WFILE");
				int pos = 6, stringSize, dataSize, size;
				
				// We read 4 bytes that contain the string size
				while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigIntToHost( stringSize);
				pos += 4;
				
				// We read the string
				while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				NSString *path = [[NSString alloc] initWithData: [data subdataWithRange: NSMakeRange(pos,stringSize)] encoding: NSUnicodeStringEncoding];
				pos += stringSize;
				
				// We read the data size
				while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &dataSize];	dataSize = NSSwapBigIntToHost( dataSize);
				pos += 4;
				
				// We read the data
				while ( [data length] < pos + dataSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				
				NSString	*localpath = [[documentsDirectory() stringByAppendingPathComponent: @"/REPORTS/"] stringByAppendingPathComponent: [path lastPathComponent]];
				
				[[NSFileManager defaultManager] removeFileAtPath: localpath handler:0L];
				[[data subdataWithRange: NSMakeRange(pos,dataSize)] writeToFile: localpath atomically:YES];
				pos += dataSize;
				
				BOOL isPages = [[localpath pathExtension] isEqualToString:@"zip"];
				if(isPages)
				{
					NSString *reportFileName = [localpath stringByDeletingPathExtension];
					NSLog(@"subConnectionReceived  reportFileName : %@", reportFileName);
					// unzip the file
					NSTask *unzipTask   = [[NSTask alloc] init];
					[unzipTask setLaunchPath:@"/usr/bin/unzip"];
					[unzipTask setCurrentDirectoryPath:[[localpath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
					[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", localpath, nil]]; // -o to override existing report w/ same name
					[unzipTask launch];
					while( [unzipTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
					int result = [unzipTask terminationStatus];
					[unzipTask release];
					
					NSLog(@"unzip result : %d", result);
					if(result==0)
					{
						// remove the zip file!
						//filePathToLoad = reportFileName;
					}
				}
				
				refreshDB = YES;

				if(isPages)
					[[NSFileManager defaultManager] removeFileAtPath:localpath handler:nil];

				[path release];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DCMSE" length: 6]])
			{
				NSMutableArray	*localPaths = [NSMutableArray arrayWithCapacity:0];
				
				int pos = 6, size, noOfFiles = 0, stringSize, i;
				
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
						NSString	*extension = [path pathExtension];
						
						int val = [[path stringByDeletingPathExtension] intValue];
						
						NSString *dbLocation = [interfaceOsiriX localDatabasePath];
						
						val /= 10000;
						val++;
						val *= 10000;
						
						path = [[dbLocation stringByDeletingLastPathComponent] stringByAppendingFormat:@"/DATABASE/%d/%@", val, path];
					}
					
					[localPaths addObject: path];
				}
				
				NSDictionary	*todo = [NSDictionary dictionaryWithObjectsAndKeys: Address, @"Address", TransferSyntax, @"Transfer Syntax", Port, @"Port", AETitle, @"AETitle", localPaths, @"Files", 0L];
				
				[NSThread detachNewThreadSelector:@selector( sendDICOMFilesToOsiriXNode:) toTarget:self withObject: todo];
			}
			else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DICOM" length: 6]])
			{
				NSMutableArray	*localPaths = [NSMutableArray arrayWithCapacity:0];
				NSMutableArray	*dstPaths = [NSMutableArray arrayWithCapacity:0];
				
				// We read now the path for the DICOM file(s)
				int pos = 6, size, noOfFiles = 0, stringSize, i;
				
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
						if( [[[path pathComponents] objectAtIndex: 0] isEqualToString:@"ROIs"])
						{
							//It's a ROI !
							NSString	*local = [[interfaceOsiriX localDatabasePath] stringByDeletingLastPathComponent];
							
							path = [[local stringByAppendingPathComponent:@"/ROIs/"] stringByAppendingPathComponent: [path lastPathComponent]];
						}
						else
						{
							NSString	*extension = [path pathExtension];
							
							int val = [[path stringByDeletingPathExtension] intValue];
							
							val /= 10000;
							val++;
							val *= 10000;
							
							NSString	*local = [[interfaceOsiriX localDatabasePath] stringByDeletingLastPathComponent];
							
							path = [[[local stringByAppendingPathComponent:@"/DATABASE/"] stringByAppendingPathComponent: [NSString stringWithFormat:@"%d", val]] stringByAppendingPathComponent: path];
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
					
					if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO) NSLog( @"Bonjour Publisher - File doesn't exist at path: %@", path);
					
					NSData	*content = [[NSFileManager defaultManager] contentsAtPath: path];
					
					size = NSSwapHostIntToBig( [content length]);
					[representationToSend appendBytes: &size length: 4];
					[representationToSend appendData: content];
					
					const char* string = [[dstPaths objectAtIndex: i] UTF8String];
					int stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[representationToSend appendBytes:&stringSize length: 4];
					[representationToSend appendBytes:string length: strlen( string)+1];
				}
			}
			
			[incomingConnection writeData:representationToSend];
			[incomingConnection closeFile];
		}
	}
	@catch( NSException *ne)
	{
		NSLog( @"catch in ConnectionReceived");
	}
	
	[incomingConnection release];
	[connectionLock unlock];
	
	if( refreshDB) [interfaceOsiriX performSelectorOnMainThread:@selector( refreshDatabase:) withObject:0L waitUntilDone: YES];		// This has to be performed on the main thread
	if( saveDB) [interfaceOsiriX performSelectorOnMainThread:@selector( saveDatabase:) withObject:0L waitUntilDone: YES];			// This has to be performed on the main thread
	
	[mPool release];
}

- (void) connectionReceived:(NSNotification *)aNotification
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash - Antoine
    
	[connectionLock lock];
	
	[[aNotification object] acceptConnectionInBackgroundAndNotify];
	[NSThread detachNewThreadSelector: @selector (subConnectionReceived:) toTarget: self withObject: [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem]];
	
	[pool release];
}

// work as a delegate of the NSNetService
- (void)netServiceWillPublish:(NSNetService *)sender
{
	[interfaceOsiriX bonjourWillPublish];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	// we should send an error message
	// here ...
	
	NSLog(@"did not publish... why?");
	
    [listeningSocket release];
    listeningSocket = nil;
    [netService release];
    netService = nil;
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	[interfaceOsiriX bonjourDidStop];
	
	[netService release];
	netService = 0L;

}

- (NSNetService*) netService
{
	return netService;
}

- (void)setServiceName:(NSString *) newName
{
	[serviceName release];
	serviceName = [newName retain];
}

- (NSString *) serviceName
{
	return serviceName;
}
@end
