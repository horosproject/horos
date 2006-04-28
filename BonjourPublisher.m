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

#import "BonjourPublisher.h"
#import "BonjourBrowser.h"
#import "xNSImage.h"
#import "DCMPix.h"

// imports required for socket initialization
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

#define USEZIP NO

// BY DEFAULT OSIRIX USES 8780 PORT

extern NSString * documentsDirectory();

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
        int namelen = sizeof(serverAddress);
		
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

- (void)connectionReceived:(NSNotification *)aNotification
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash (remplissage memoire) - Antoine
    
	[connectionLock lock];
	
	NSFileHandle		*incomingConnection = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
	NSData				*readData;
	NSMutableData		*data = [NSMutableData dataWithCapacity: 512*512*2*2];
	NSMutableData		*representationToSend = 0L;
	
	[[aNotification object] acceptConnectionInBackgroundAndNotify];
	
	if( incomingConnection)
	{
		// Waiting for incomming message (6 first bytes)
		while ( [data length] < 6 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
		
		if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DATAB" length: 6]])
		{
			//NSLog( @"[data bytes] = DATAB");
			
			// we send the database SQL file
			NSString *databasePath = [interfaceOsiriX localDatabasePath];
			representationToSend = [NSMutableData dataWithData: [[NSFileManager defaultManager] contentsAtPath:databasePath]];
			
		//	NSLog( [incomingConnection description]);
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"VERSI" length: 6]])
		{
			//NSLog( @"[data bytes] = VERSI");
			
			// we send the modification date of the SQL file
			NSString *databasePath = [interfaceOsiriX localDatabasePath];
			
			NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:databasePath traverseLink:YES];
			NSDate *moddate = [fattrs objectForKey:NSFileModificationDate];
			NSTimeInterval val = 0;
			if( moddate)
			{
				val = [moddate timeIntervalSinceReferenceDate];
			}
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
			
			long val = 0;
			
			if( pswd) val = 1;
			else val = 0;
			
			representationToSend = [NSMutableData dataWithBytes: &val length:sizeof(long)];
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"PASWD" length: 6]])
		{
			long pos = 6, stringSize;
			
			// We read 4 bytes that contain the string size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
			pos += 4;
			
			// We read the string
			while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			NSString *incomingPswd = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
			pos += stringSize;
			
			long val = 0;
			
			if( [incomingPswd isEqualToString: [interfaceOsiriX bonjourPassword]] || [interfaceOsiriX bonjourPassword] == 0L)
			{
				val = 1;
			}
			
			representationToSend = [NSMutableData dataWithBytes: &val length:sizeof(long)];
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"SENDD" length: 6]])
		{
			// We read 4 bytes that contain the file size
			while ( [data length] < 6 + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			
			long fileSize;
			[[data subdataWithRange: NSMakeRange(6, 4)] getBytes: &fileSize];
			fileSize = NSSwapBigLongToHost( fileSize);
			
			while ( [data length] < 6 + 4 + fileSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			
			NSString	*incomingFolder = [documentsDirectory() stringByAppendingPathComponent:@"/INCOMING"];
			NSString	*dstPath;
			
			long index = [NSDate timeIntervalSinceReferenceDate];
			
			do
			{
				dstPath = [NSString stringWithFormat:@"%@/%d", incomingFolder, index];
				index++;
			}
			while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
			
			[[data subdataWithRange: NSMakeRange(10,fileSize)] writeToFile:dstPath atomically: YES];
			
			representationToSend = 0L;
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"SETVA" length: 6]])
		{
			long pos = 6, size, noOfFiles = 0, stringSize, i;
			
			// We read 4 bytes that contain the string size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
			pos += 4;
			
			// We read the string
			while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			NSString *object = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
			pos += stringSize;
			
			// We read 4 bytes that contain the string size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
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
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
			pos += 4;
			
			// We read the string
			while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			NSString *key = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
			pos += stringSize;
			
			NSManagedObjectContext *context = [interfaceOsiriX managedObjectContext];
			[context lock];
			NSManagedObject	*item = [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: object]]];
			[context unlock];
			
			//NSLog(@"URL:%@", object);
			
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
						value = [NSString stringWithFormat: @"%@/REPORTS/%@", documentsDirectory(), [value lastPathComponent]];
					}
				}
				
				[item setValue: value forKeyPath: key];
			}
			
			[interfaceOsiriX refreshDatabase: 0L];
			[interfaceOsiriX saveDatabase: 0L];
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"MFILE" length: 6]])
		{
			long pos = 6, stringSize, size;
			
			// We read 4 bytes that contain the string size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
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
			long pos = 6, stringSize, size;
			
			// We read 4 bytes that contain the string size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
			pos += 4;
			
			// We read the string
			while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			NSString *path = [[NSString alloc] initWithData: [data subdataWithRange: NSMakeRange(pos,stringSize)] encoding: NSUnicodeStringEncoding];
			pos += stringSize;
			
			NSData	*content = [[NSFileManager defaultManager] contentsAtPath: path];
			
			// Send the file
			
			representationToSend = [NSMutableData data];
			
			stringSize = NSSwapHostLongToBig( [content length]);
			[representationToSend appendBytes:&stringSize length: 4];
			[representationToSend appendData: content];
			
			NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
			content = [[[fattrs objectForKey:NSFileModificationDate] description] dataUsingEncoding: NSUnicodeStringEncoding];
			stringSize = NSSwapHostLongToBig( [content length]);
			[representationToSend appendBytes:&stringSize length: 4];
			[representationToSend appendData: content];
			
			[path release];
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"WFILE" length: 6]])
		{
			long pos = 6, stringSize, dataSize, size;
			
			// We read 4 bytes that contain the string size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
			pos += 4;
			
			// We read the string
			while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			NSString *path = [[NSString alloc] initWithData: [data subdataWithRange: NSMakeRange(pos,stringSize)] encoding: NSUnicodeStringEncoding];
			pos += stringSize;
			
			// We read the data size
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &dataSize];	dataSize = NSSwapBigLongToHost( dataSize);
			pos += 4;
			
			// We read the data
			while ( [data length] < pos + dataSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			
			NSString	*localpath = [NSString stringWithFormat: @"%@/REPORTS/%@", documentsDirectory(), [path lastPathComponent]];
			
			[[NSFileManager defaultManager] removeFileAtPath: localpath handler:0L];
			[[data subdataWithRange: NSMakeRange(pos,dataSize)] writeToFile: localpath atomically:YES];
			pos += dataSize;
			
			[interfaceOsiriX refreshDatabase: 0L];
			
			[path release];
		}
		else if ([[data subdataWithRange: NSMakeRange(0,6)] isEqualToData: [NSData dataWithBytes:"DICOM" length: 6]])
		{
			NSMutableArray	*localPaths = [NSMutableArray arrayWithCapacity:0];
			NSMutableArray	*dstPaths = [NSMutableArray arrayWithCapacity:0];
			
			// We read now the path for the DICOM file(s)
			long pos = 6, size, noOfFiles = 0, stringSize, i;
			
			while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
			
			[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &noOfFiles];	noOfFiles = NSSwapBigLongToHost( noOfFiles);
			pos += 4;
			
			representationToSend = [NSMutableData dataWithCapacity: 0];
			
			for( i = 0; i < noOfFiles; i++)
			{
				// We read 4 bytes that contain the string size
				while ( [data length] < pos + 4 && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
				pos += 4;
				
				// We read the string
				while ( [data length] < pos + stringSize && (readData = [incomingConnection availableData]) && [readData length]) [data appendData: readData];
				NSString *path = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,stringSize)] bytes]];
				pos += stringSize;
				
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
				[[data subdataWithRange: NSMakeRange(pos, 4)] getBytes: &stringSize];	stringSize = NSSwapBigLongToHost( stringSize);
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
			
			long temp = NSSwapHostLongToBig( noOfFiles);
			[representationToSend appendBytes: &temp length: 4];	
			for( i = 0; i < noOfFiles; i++)
			//for( i = 0; i < [localPaths count]; i++)
			{
				NSString	*path = [localPaths objectAtIndex: i];
				
				if( [path cString] [ 0] != '/')
				{
					NSString	*extension = [path pathExtension];
					
					long val = [[path stringByDeletingPathExtension] intValue];
					NSString *dbLocation = [[BrowserController currentBrowser] currentDatabasePath];
					
					val /= 10000;
					val++;
					val *= 10000;

//					if (![extension caseInsensitiveCompare:@"tif"] || ![extension caseInsensitiveCompare:@"tiff"])
//						path = [[dbLocation stringByDeletingLastPathComponent] stringByAppendingFormat:@"/DATABASE/TIF/%@", path];
//					else
//					
						path = [[dbLocation stringByDeletingLastPathComponent] stringByAppendingFormat:@"/DATABASE/%d/%@", val, path];
				}
				
				if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO) NSLog( @"File doesn't exist at path: %@, length: %d", path);
				
				NSData	*content = [[NSFileManager defaultManager] contentsAtPath: path];
				
				size = NSSwapHostLongToBig( [content length]);
				[representationToSend appendBytes: &size length: 4];
				[representationToSend appendData: content];
				
				const char* string = [[dstPaths objectAtIndex: i] UTF8String];
				long stringSize = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
				
				[representationToSend appendBytes:&stringSize length: 4];
				[representationToSend appendBytes:string length: strlen( string)+1];
			}
		}
		
		[incomingConnection writeData:representationToSend];
		[incomingConnection closeFile];
	}
	
	[connectionLock unlock];
	
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
