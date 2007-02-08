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

#include <netdb.h>

#import "BonjourBrowser.h"
#import "BrowserController.h"
#import "AppController.h"
#import "DicomFile.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

#define FILESSIZE 512*512*2

static long TIMEOUT	= 60;
#define USEZIP NO

extern NSString			*documentsDirectory();
extern NSThread			*mainThread;

volatile static BOOL threadIsRunning = NO;

@implementation BonjourBrowser

+ (void) waitForLock:(NSLock*) l
{
	while( [l tryLock] == NO)
	{
		if( [NSThread currentThread] == mainThread)
		{
			[[NSRunLoop currentRunLoop] runMode:@"OsiriXLoopMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
		}
	}
}

+ (NSString*) bonjour2local: (NSString*) str
{
	if( str == 0L) return 0L;
	
	NSMutableString	*destPath = [NSMutableString string];
	
	[destPath appendString:documentsDirectory()];
	[destPath appendString:@"/TEMP/"];
	[destPath appendString: [str lastPathComponent]];

	return destPath;
}

- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub{
	self = [super init];
	if (self != nil)
	{
		long i;
		
		lock = [[NSLock alloc] init];
		browser = [[NSNetServiceBrowser alloc] init];
		services = [[NSMutableArray array] retain];
		
		[self buildFixedIPList];
		
		interfaceOsiriX = bC;
		
		strcpy( messageToRemoteService, ".....");
		
		publisher = bPub;
		
		dbFileName = 0L;
		dicomFileNames = 0L;
		paths = 0L;
		path = 0L;
		filePathToLoad = 0L;
		FileModificationDate = 0L;
		
		localVersion = 0;
		BonjourDatabaseVersion = 0;
		
		resolved = YES;
		
		setValueObject = 0L;
		setValueValue = 0L;
		setValueKey = 0L;
		modelVersion = 0L;
		
		serviceBeingResolvedIndex = -1;
		[browser setDelegate:self];
		
		[browser searchForServicesOfType:@"_osirix._tcp." inDomain:@""];
		
		[browser scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: @"OsiriXLoopMode"];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
															  selector: @selector(updateFixedIPList:)
																  name: @"OsiriXServerArray has changed"
																object: nil];
	}
	return self;
}

- (void) dealloc
{
	[path release];
	[paths release];
	[dbFileName release];
	[dicomFileNames release];
	[modelVersion release];
	[FileModificationDate release];
	[filePathToLoad release];
	
	[super dealloc];
}

- (NSMutableArray*) services
{
	return services;
}

//- (BOOL) unzipToPath:(NSString*)_toPath
//{
//	NSFileManager              *localFm     = nil;
//	NSFileHandle               *nullHandle  = nil;
//	NSTask                     *unzipTask   = nil;
//	int                        result;
//
//	localFm     = [NSFileManager defaultManager];
//
//	nullHandle  = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
//	unzipTask   = [[NSTask alloc] init];
//	[unzipTask setLaunchPath:@"/usr/bin/unzip"];
//	[unzipTask setCurrentDirectoryPath: [[_toPath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
//	[unzipTask setArguments:[NSArray arrayWithObjects: _toPath, nil]];
//	[unzipTask setStandardOutput: nullHandle];
//	[unzipTask setStandardError: nullHandle];
//	[unzipTask launch];
//	if ([unzipTask isRunning]) [unzipTask waitUntilExit];
//	result      = [unzipTask terminationStatus];
//
//	[unzipTask release];
//
//	[localFm removeFileAtPath:_toPath handler:nil];
//
//	return YES;
//}

//- (void)connectionReceived:(NSNotification *)note
//{
//	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash (remplissage memoire) - Antoine
////    NSFileHandle		*incomingConnection = [[note userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
//	
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: [note object]];
//	
//	[[note object] readToEndOfFileInBackgroundAndNotify];
//	
//	NSLog( @"connectionReceived");
//	
//	[pool release];
//}

- (void)readAllTheData:(NSNotification *)note
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash (remplissage memoire) - Antoine
	BOOL				success = YES;
	NSData				*data = [[[note userInfo] objectForKey:NSFileHandleNotificationDataItem] retain];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: [note object]];
	[[note object] release];

	if( data)
	{
		if( [data bytes])
		{
			if ( strcmp( messageToRemoteService, "DATAB") == 0)
			{
				// we asked for a SQL file, let's write it on disc
				[dbFileName release];
				if( serviceBeingResolvedIndex < BonjourServices) dbFileName = [[self databaseFilePathForService:[[[self services] objectAtIndex:serviceBeingResolvedIndex] name]] retain];
				else dbFileName = [[self databaseFilePathForService:[[[self services] objectAtIndex:serviceBeingResolvedIndex] valueForKey:@"Description"]] retain];
				
				[[NSFileManager defaultManager] removeFileAtPath: dbFileName handler:0L];
				
				success = [data writeToFile: dbFileName atomically:YES];
				
			//	success = [[NSFileManager defaultManager] createFileAtPath: dbFileName contents:data attributes:nil];
			}
			else if ( strcmp( messageToRemoteService, "MFILE") == 0)
			{
				[FileModificationDate release];
				FileModificationDate = [[NSString alloc] initWithData:data encoding: NSUnicodeStringEncoding];
			}
			else if ( strcmp( messageToRemoteService, "RFILE") == 0)
			{
				NSLog(@"readAllTheData filePathToLoad : %@", filePathToLoad);
				BOOL isPages = [[filePathToLoad pathExtension] isEqualToString:@"pages"];
				NSString *zipFilePathToLoad;
				if(isPages)
				{
					NSLog(@"readAllTheData isPages");
					zipFilePathToLoad = [filePathToLoad stringByAppendingString:@".zip"];
					//[filePathToLoad release];
					//filePathToLoad = [zipFilePathToLoad retain];
				}
				NSLog(@"readAllTheData filePathToLoad : %@", filePathToLoad);
				NSLog(@"readAllTheData zipFilePathToLoad : %@", zipFilePathToLoad);

//					NSString *reportFileName = [filePathToLoad stringByDeletingPathExtension];
//					NSLog(@"reportFileName : %@", reportFileName);
//					// unzip the file
//					NSTask *unzipTask   = [[NSTask alloc] init];
//					[unzipTask setLaunchPath:@"/usr/bin/unzip"];
//					[unzipTask setCurrentDirectoryPath:[[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
//					[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", filePathToLoad, nil]]; // -o to override existing report w/ same name
//					[unzipTask launch];
//					if ([unzipTask isRunning]) [unzipTask waitUntilExit];
//					int result = [unzipTask terminationStatus];
//					[unzipTask release];
//					
//					NSLog(@"unzip result : %d", result);
//					if(result==0)
//					{
//						// remove the zip file!
//						filePathToLoad = reportFileName;
//					}

			
				//NSString *destPath = [BonjourBrowser bonjour2local: filePathToLoad];
				NSString *destPath = [BonjourBrowser bonjour2local: zipFilePathToLoad];
				[[NSFileManager defaultManager] removeFileAtPath: destPath handler:0L];
				
				long	pos = 0, size;
				NSData	*curData = 0L;
				
				// The File
				size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
				pos += 4;
				curData = [data subdataWithRange: NSMakeRange(pos, size)];
				pos += size;
				
				// Write the file
				success = [curData writeToFile:destPath atomically:YES];
				
				if(isPages)
				{
					NSLog(@"readAllTheData isPages 2");
					NSString *reportFileName = [destPath stringByDeletingPathExtension];
					NSLog(@"readAllTheData  reportFileName : %@", reportFileName);
					// unzip the file
					NSTask *unzipTask   = [[NSTask alloc] init];
					[unzipTask setLaunchPath:@"/usr/bin/unzip"];
					[unzipTask setCurrentDirectoryPath:[[destPath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
					[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", destPath, nil]]; // -o to override existing report w/ same name
					[unzipTask launch];
					while( [unzipTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
					int result = [unzipTask terminationStatus];
					[unzipTask release];
					
					NSLog(@"unzip result : %d", result);
					if(result==0)
					{
						//destPath = reportFileName;
						destPath = [BonjourBrowser bonjour2local:filePathToLoad];
						NSLog(@"destPath : %@", destPath);
						// remove the zip file!
						//filePathToLoad = reportFileName;
					}
				}
				
				// The modification date
				size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
				pos += 4;
				curData = [data subdataWithRange: NSMakeRange(pos, size)];
				pos += size;
				
				NSString	*str = [[NSString alloc] initWithData:curData encoding: NSUnicodeStringEncoding];
				
				// Change the modification & creation date
				NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:destPath traverseLink:YES];
				
				NSMutableDictionary *newfattrs = [NSMutableDictionary dictionaryWithDictionary: fattrs];
				[newfattrs setObject:[NSDate dateWithString:str] forKey:NSFileModificationDate];
				[newfattrs setObject:[NSDate dateWithString:str] forKey:NSFileCreationDate];
				[[NSFileManager defaultManager] changeFileAttributes:newfattrs atPath:destPath];
				
				[str release];
			}
			else if (strcmp( messageToRemoteService, "DICOM") == 0)
			{
				// we asked for a DICOM file(s), let's write it on disc
				
				long pos = 0, noOfFiles, size, i;
				
				noOfFiles = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
				pos += 4;
					
				for( i = 0 ; i < noOfFiles; i++)
				{
					size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
					pos += 4;
					
					NSData	*curData = [NSData dataWithBytesNoCopy:[data bytes] + pos length:size freeWhenDone:NO];		//[data subdataWithRange: NSMakeRange(pos, size)];
					pos += size;
					
					size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
					pos += 4;
					
					NSString *localPath = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,size)] bytes]];
					pos += size;
					
					if( [curData length])
					{
						if ([[NSFileManager defaultManager] fileExistsAtPath: localPath]) NSLog(@"strange...");
						
						[curData writeToFile: localPath atomically: YES];
						
//						[[NSFileManager defaultManager] removeFileAtPath: localPath handler:0L];
//						success = [[NSFileManager defaultManager] createFileAtPath: [localPath stringByAppendingString:@"RENAME"] contents:curData attributes:nil];
//						success = [[NSFileManager defaultManager] movePath:[localPath stringByAppendingString:@"RENAME"] toPath:localPath handler:0L];
					}
				}
			}
			else if (strcmp( messageToRemoteService, "VERSI") == 0)
			{
				// we asked for the last time modification date & time of the database
				
				BonjourDatabaseVersion = NSSwapBigDoubleToHost( *((NSSwappedDouble*) [data bytes]));
			}
			else if (strcmp( messageToRemoteService, "DBVER") == 0)
			{
				// we asked for the last time modification date & time of the database
				
				[modelVersion release];
				modelVersion = [[NSString alloc] initWithData:data encoding: NSASCIIStringEncoding];
			}
			else if (strcmp( messageToRemoteService, "PASWD") == 0)
			{
				long result = NSSwapBigIntToHost( *((int*) [data bytes]));
				
				if( result) wrongPassword = NO;
				else wrongPassword = YES;
			}
			else if (strcmp( messageToRemoteService, "ISPWD") == 0)
			{
				long result = NSSwapBigIntToHost( *((int*) [data bytes]));
				
				if( result) isPasswordProtected = YES;
				else isPasswordProtected = NO;
			}
			else if (strcmp( messageToRemoteService, "SETVA") == 0)
			{
				
			}

			if( success == NO)
			{
				NSLog(@"Bonjour transfer failed");
			}
		}
	}
	
	[data release];
	
	resolved = YES;
	
	[pool release];
}

//socket.h
- (BOOL) connectToService: (struct sockaddr_in*) socketAddress
{

NSLog(@"connectToService");
	BOOL succeed = NO;
	
	int socketToRemoteServer = socket(AF_INET, SOCK_STREAM, 0);
	if(socketToRemoteServer > 0)
	{
		// SEND DATA
	
		NSFileHandle * sendConnection = [[NSFileHandle alloc] initWithFileDescriptor:socketToRemoteServer closeOnDealloc:YES];
		if(sendConnection)
		{
//			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionReceived:) name:NSFileHandleReadCompletionNotification object:sendConnection];
           
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAllTheData:) name:NSFileHandleReadToEndOfFileCompletionNotification object: sendConnection];
			
			 if(connect(socketToRemoteServer, (struct sockaddr *)socketAddress, sizeof(*socketAddress)) == 0)
			 {
				// transfering the type of data we need
				NSMutableData	*toTransfer = [NSMutableData dataWithCapacity:0];
				
				[toTransfer appendBytes:messageToRemoteService length: 6];
				
				if (strcmp( messageToRemoteService, "SETVA") == 0)
				{
					const char* string;
					long stringSize;
					
					string = [setValueObject UTF8String];
					stringSize  = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
					
					if( setValueValue == 0L)
					{
						string = 0L;
						stringSize = 0;
					}
					else if( [setValueValue isKindOfClass:[NSNumber class]])
					{
						string = [[setValueValue stringValue] UTF8String];
						stringSize = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
					}
					else
					{
						string = [setValueValue UTF8String];
						stringSize = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
					}
					
					[toTransfer appendBytes:&stringSize length: 4];
					if( stringSize)
						[toTransfer appendBytes:string length: strlen( string)+1];
					
					string = [setValueKey UTF8String];
					stringSize = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
				}
				
				if (strcmp( messageToRemoteService, "RFILE") == 0)
				{
					NSLog(@"ask for : %@", filePathToLoad);
					NSData	*filenameData = [filePathToLoad dataUsingEncoding: NSUnicodeStringEncoding];
					long stringSize = NSSwapHostLongToBig( [filenameData length]);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:[filenameData bytes] length: [filenameData length]];
				}
				
				if (strcmp( messageToRemoteService, "MFILE") == 0)
				{
					NSData	*filenameData = [filePathToLoad dataUsingEncoding: NSUnicodeStringEncoding];
					long stringSize = NSSwapHostLongToBig( [filenameData length]);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:[filenameData bytes] length: [filenameData length]];
				}
				
				if (strcmp( messageToRemoteService, "WFILE") == 0)
				{				
					NSLog(@"connectToService, WFILE");
					BOOL isPages = [[filePathToLoad pathExtension] isEqualToString:@"pages"];
					if(isPages)
					{
						NSLog(@"connectToService isPages");
						NSString *zipFileName = [NSString stringWithFormat:@"%@.zip", [filePathToLoad lastPathComponent]];
						// zip the directory into a single archive file
						NSTask *zipTask   = [[NSTask alloc] init];
						[zipTask setLaunchPath:@"/usr/bin/zip"];
						[zipTask setCurrentDirectoryPath:[[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
						[zipTask setArguments:[NSArray arrayWithObjects:@"-r" , zipFileName, [filePathToLoad lastPathComponent], nil]];
						[zipTask launch];
						while( [zipTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
						int result = [zipTask terminationStatus];
						[zipTask release];

						if(result==0)
						{
							NSMutableString *path2 = (NSMutableString*)[[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", zipFileName];
							[filePathToLoad release];
							filePathToLoad = [path2 retain];
							NSLog(@"filePathToLoad : %@", filePathToLoad);
						}
					}
				
					NSData	*filenameData = [filePathToLoad dataUsingEncoding: NSUnicodeStringEncoding];
					long stringSize = NSSwapHostLongToBig( [filenameData length]);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:[filenameData bytes] length: [filenameData length]];
					
					NSData	*fileData = [NSData dataWithContentsOfFile: filePathToLoad];
					long dataSize = NSSwapHostLongToBig( [fileData length]);
					[toTransfer appendBytes:&dataSize length: 4];
					[toTransfer appendData: fileData];
				}
				
				if (strcmp( messageToRemoteService, "DICOM") == 0)
				{
					long i, temp, noOfFiles = [paths count];
					
					temp = NSSwapHostLongToBig( noOfFiles);
					[toTransfer appendBytes:&temp length: 4];
					for( i = 0; i < noOfFiles ; i++)
					{
						const char* string = [[paths objectAtIndex: i] UTF8String];
						long stringSize = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
						
						[toTransfer appendBytes:&stringSize length: 4];
						[toTransfer appendBytes:string length: strlen( string)+1];
					}
					
					for( i = 0; i < noOfFiles ; i++)
					{
						const char* string = [[dicomFileNames objectAtIndex: i] UTF8String];
						long stringSize = NSSwapHostLongToBig( strlen( string)+1);	// +1 to include the last 0 !
						
						[toTransfer appendBytes:&stringSize length: 4];
						[toTransfer appendBytes:string length: strlen( string)+1];
					}
				}
				
				if ((strcmp( messageToRemoteService, "SENDD") == 0))
				{
					long i, temp, noOfFiles = [paths count];
					
					temp = NSSwapHostLongToBig( noOfFiles);
					[toTransfer appendBytes:&temp length: 4];
					
					for( i = 0; i < noOfFiles ; i++)
					{
						NSData	*file = [NSData dataWithContentsOfFile: [paths objectAtIndex: i]];
						
						long fileSize = NSSwapHostLongToBig( [file length]);
						[toTransfer appendBytes:&fileSize length: 4];
						[toTransfer appendData:file];
					}
				}
				
				if ((strcmp( messageToRemoteService, "PASWD") == 0))
				{
					const char* passwordUTF = [password UTF8String];
					long stringSize = NSSwapHostLongToBig( strlen( passwordUTF)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:passwordUTF length: strlen( passwordUTF)+1];
				}
				
				[sendConnection writeData: toTransfer];
				
//				[sendConnection readInBackgroundAndNotify];
				
//				[sendConnection readToEndOfFileInBackgroundAndNotify];

				[sendConnection readToEndOfFileInBackgroundAndNotifyForModes:[NSArray arrayWithObject:@"OsiriXLoopMode"]];
				
				succeed = YES;
			}
			else
			{
				[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: sendConnection];
				[sendConnection release];
			}
		}
		else
		{
			close(socketToRemoteServer);
		}
	}
	
	return succeed;
}

- (long) BonjourServices
{
	return BonjourServices;
}

- (void) buildFixedIPList
{
	long			i;
	NSArray			*osirixServersArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"OSIRIXSERVERS"];
	
	
	
	for( i = 0; i < [osirixServersArray count]; i++)
	{
		[services addObject: [osirixServersArray objectAtIndex: i]];
	}
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) updateFixedIPList: (NSNotification*) note
{
	[services removeObjectsInRange: NSMakeRange( BonjourServices, [services count] - BonjourServices)];
	[self buildFixedIPList];
	[interfaceOsiriX displayBonjourServices];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————


- (BOOL) fixedIP: (int) index
{
	struct sockaddr_in service;
	const char	*host_name = [[[services objectAtIndex: index] valueForKey:@"Address"] UTF8String];
	
	bzero((char *) &service, sizeof(service));
	service.sin_family = AF_INET;
	
	if (isalpha(host_name[0]))
	{
		struct hostent *hp;
		
		hp = gethostbyname( host_name);
		if( hp) bcopy(hp->h_addr, (char *) &service.sin_addr, hp->h_length);
		else service.sin_addr.s_addr = inet_addr( host_name);
	}
	else service.sin_addr.s_addr = inet_addr( host_name);
	
	service.sin_port = htons(8780);
	
	return [self connectToService: &service];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
   if ([[sender addresses] count] > 0)
   {
        NSData * address;
        struct sockaddr * socketAddress;
        NSString * ipAddressString = nil;
        NSString * portString = nil;
        char buffer[256];
        int index;

        // Iterate through addresses until we find an IPv4 address
        for (index = 0; index < [[sender addresses] count]; index++) {
            address = [[sender addresses] objectAtIndex:index];
            socketAddress = (struct sockaddr *)[address bytes];

            if (socketAddress->sa_family == AF_INET) break;
        }

        // Be sure to include <netinet/in.h> and <arpa/inet.h> or else you'll get compile errors.

        if (socketAddress) {
            switch(socketAddress->sa_family) {
                case AF_INET:
                    if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer))) {
                        ipAddressString = [NSString stringWithCString:buffer];
                        portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
                    }
                    
                    // Cancel the resolve now that we have an IPv4 address.
                    [sender stop];
                    [sender release];
                    serviceBeingResolved = nil;

                    break;
                case AF_INET6:
                    // OsiriX server doesn't support IPv6
                    return;
            }
        }
		
		[self connectToService: (struct sockaddr_in *) socketAddress];
	}
}

// This object is the delegate of its NSNetServiceBrowser object.
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	// remove my own sharing service
	if( aNetService == [publisher netService] || [[aNetService name] isEqualToString: [publisher serviceName]] == YES)
	{
		
	}
	else
	{
		[services insertObject:aNetService atIndex:BonjourServices];
		BonjourServices ++;
	}
	
	// update interface
    if(!moreComing) [interfaceOsiriX displayBonjourServices];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    // This case is slightly more complicated. We need to find the object in the list and remove it.
    NSEnumerator * enumerator = [services objectEnumerator];
    NSNetService * currentNetService;
	
    while(currentNetService = [enumerator nextObject]) {
        if ([currentNetService isEqual:aNetService])
		{
			// deleting the associate SQL temporary file
			if ([[NSFileManager defaultManager] fileExistsAtPath: [self databaseFilePathForService:[aNetService name]] ])
			{
				[[NSFileManager defaultManager] removeFileAtPath: [self databaseFilePathForService:[currentNetService name]] handler:self];
			}
									
			if( [interfaceOsiriX currentBonjourService] == [services indexOfObject: aNetService])
			{
				[interfaceOsiriX resetToLocalDatabase];
			}

			// deleting service from list
            [services removeObject:currentNetService];

			BonjourServices --;
            break;
        }
    }

    if (serviceBeingResolved && [serviceBeingResolved isEqual:aNetService]) {
        [serviceBeingResolved stop];
        [serviceBeingResolved release];
        serviceBeingResolved = nil;
    }

    if(!moreComing)
	{
		[interfaceOsiriX displayBonjourServices];
	}
}
//
//- (void) stopService
//{
//	return;
//	
//	if (serviceBeingResolved)
//	{
//        [serviceBeingResolved stop];
//        [serviceBeingResolved release];
//        serviceBeingResolved = nil;
//    }
//}


- (BOOL) resolveServiceWithIndex:(int)index msg: (char*) msg
{
	BOOL succeed = NO;
	
	serviceBeingResolvedIndex = index;
	strcpy( messageToRemoteService, msg);
	resolved = YES;
	
    //  Make sure to cancel any previous resolves.
    if (serviceBeingResolved)
	{
        [serviceBeingResolved stop];
        [serviceBeingResolved release];
        serviceBeingResolved = nil;
    }

	
    if(-1 == index)
	{
    }
	else if( index >= BonjourServices)
	{
		resolved = NO;
		succeed = [self fixedIP: index];
	}
	else
	{        
        serviceBeingResolved = [services objectAtIndex:index];
        [serviceBeingResolved retain];
        [serviceBeingResolved setDelegate:self];
		
//		[serviceBeingResolved scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
		[serviceBeingResolved scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: @"OsiriXLoopMode"];
		
		resolved = NO;
		[serviceBeingResolved resolveWithTimeout: TIMEOUT];
		succeed = YES;
    }
	
	return succeed;
}

- (void) resolveServiceThread:(NSDictionary*) object
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	BOOL				succeed;
	
	resolved = NO;
	succeed = [self resolveServiceWithIndex: [[object valueForKey:@"index"] intValue] msg: (char*) [[object valueForKey:@"msg"] UTF8String]];
	
	if( succeed)
	{
		NSDate			*timeout = [NSDate dateWithTimeIntervalSinceNow: TIMEOUT];
		NSRunLoop		*run = [NSRunLoop currentRunLoop];
		
		while( resolved == NO && [timeout timeIntervalSinceNow] >= 0)
		{
			[run runMode:@"OsiriXLoopMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
		}
	}
	
	[pool release];
	
	threadIsRunning = NO;
}

- (BOOL) connectToServer:(long) index message:(NSString*) message
{
	NSDictionary	*dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: index], @"index", message, @"msg", 0L];
	
	threadIsRunning = YES;
	[NSThread detachNewThreadSelector:@selector(resolveServiceThread:) toTarget:self withObject: dict];
	while( threadIsRunning == YES)
	{
		if( [NSThread currentThread] == mainThread) [[NSRunLoop currentRunLoop] runMode:@"OsiriXLoopMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
		else [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
	}
	
//	[self performSelectorOnMainThread:@selector(resolveServiceThread:) withObject:dict waitUntilDone: YES];
	
//	[self resolveServiceThread: dict];
	
//	[self performSelectorOnMainThread:@selector(resolveServiceThread:) withObject:dict waitUntilDone:YES modes: [NSArray arrayWithObject:@"OsiriXLoopMode"]];

//	[self resolveServiceThread: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: index], @"index", message, @"msg", 0L]];
	
	
	return resolved;
}

#pragma mark-
#pragma mark Network functions

- (BOOL) isBonjourDatabaseUpToDate: (int) index
{
	if( [lock tryLock] == NO) return;
	[lock unlock];
	
	BOOL result;
	
	[BonjourBrowser waitForLock: lock];
	
	[self connectToServer: index message:@"VERSI"];
	
	if( localVersion == BonjourDatabaseVersion) result = YES;
	else result = NO;
	
	if( result == NO)
	{
		NSLog( @"isBonjourDatabaseUpToDate : NO");
//		NSLog( @"date: %@ versus: %@", [[NSDate dateWithTimeIntervalSince1970:localVersion] description], [[NSDate dateWithTimeIntervalSince1970:BonjourDatabaseVersion] description]);
	}
	
	[lock unlock];
	
	return result;
}

- (void) setBonjourDatabaseValue:(int) index item:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key
{
	[BonjourBrowser waitForLock: lock];
	
	[setValueObject release];
	[setValueValue release];
	[setValueKey release];
	
	setValueObject = [[[[obj objectID] URIRepresentation] absoluteString] retain];
	setValueValue = [value retain];
	setValueKey = [key retain];
	
	[self connectToServer: index message:@"SETVA"];
	
	[self connectToServer: index message:@"VERSI"];
	localVersion = BonjourDatabaseVersion;
	
	[lock unlock];
}

- (NSDate*) getFileModification:(NSString*) pathFile index:(int) index 
{
	NSMutableString	*returnedFile = 0L;
	NSDate			*modificationDate = 0L;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: [BonjourBrowser bonjour2local: pathFile]])
	{
		NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:[BonjourBrowser bonjour2local: pathFile] traverseLink:YES];
		return [fattrs objectForKey:NSFileModificationDate];
	}
	
	[BonjourBrowser waitForLock: lock];
	
	[filePathToLoad release];
	
	filePathToLoad = [pathFile retain];
	
	[self connectToServer: index message:@"MFILE"];
	
	if( resolved == YES)
	{
		modificationDate = [NSDate dateWithString: FileModificationDate];
	}
	
	[lock unlock];
	return modificationDate;
}

- (NSString*) getFile:(NSString*) pathFile index:(int) index 
{
	NSString	*returnedFile = 0L;
	
	// Does the file already exist?
	
	returnedFile = [BonjourBrowser bonjour2local: pathFile];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath:returnedFile]) return returnedFile;
	else returnedFile = 0L;
	
	//
	
	[BonjourBrowser waitForLock: lock];
	
	[filePathToLoad release];
	filePathToLoad = [pathFile retain];
	
	[self connectToServer: index message:@"RFILE"];
	
	if( resolved == YES)
	{
		returnedFile = [BonjourBrowser bonjour2local: filePathToLoad];
	}
	
	[lock unlock];
	
	return returnedFile;
}

- (BOOL) sendFile:(NSString*) pathFile index:(int) index 
{
	BOOL succeed = NO;
	
	[BonjourBrowser waitForLock: lock];
	
	[filePathToLoad release];
	
	filePathToLoad = [pathFile retain];
	
	[self connectToServer: index message:@"WFILE"];
	
	if( resolved == YES)
	{
		succeed = YES;
	}
	
	[lock unlock];
	
	return succeed;
}

- (NSString*) getDatabaseFile:(int) index
{
	BOOL newConnection = NO;
	
	if( serviceBeingResolvedIndex != index) newConnection = YES;
	
	[BonjourBrowser waitForLock: lock];
	
	[dbFileName release];
	dbFileName = 0L;
	
	isPasswordProtected = NO;
	
	if( [self connectToServer: index message:@"DBVER"])
	{
		if( [modelVersion isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"]] == NO)
		{
			[lock unlock];
			NSRunAlertPanel( NSLocalizedString( @"Bonjour Database", 0L), NSLocalizedString( @"Database structure is not identical. Use the SAME version of OsiriX on clients and servers to correct the problem.", 0L), nil, nil, nil);
			
			return 0L;
		}
		
		if( newConnection)
		{
			[self connectToServer: index message:@"ISPWD"];
		}
		else
		{
			resolved = YES;
		}
		
		if( resolved == YES)
		{
			if( isPasswordProtected)
			{
				[password release];
				password = 0L;
				
				password = [[interfaceOsiriX askPassword] retain];
				
				wrongPassword = YES;
				[self connectToServer: index message:@"PASWD"];
				
				if( resolved == NO || wrongPassword == YES)
				{
					[lock unlock];
					
					NSRunAlertPanel( NSLocalizedString( @"Bonjour Database", 0L), NSLocalizedString( @"Wrong password.", 0L), nil, nil, nil);
					serviceBeingResolvedIndex = -1;
					return 0L;
				}
			}
			
			if( [self connectToServer: index message: @"DATAB"] == YES)
			{
				[self connectToServer: index message: @"VERSI"];
				
				localVersion = BonjourDatabaseVersion;
			}
		}
	}
	
	[lock unlock];
	
	return dbFileName;
}

- (BOOL) sendDICOMFile:(int) index paths:(NSArray*) ip
{
	long i;
	
	for( i = 0 ; i < [ip count]; i++)
	{
		if( [[NSFileManager defaultManager] fileExistsAtPath: [ip objectAtIndex: i]] == NO) return NO;
	}
	
	[BonjourBrowser waitForLock: lock];
	
	[paths release];
	paths = [ip retain];
	
	[self connectToServer: index message:@"SENDD"];
	
	[lock unlock];
	
	return YES;
}

- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (long) noOfImages
{
	[BonjourBrowser waitForLock: lock];
	
	// Does this file already exist?
	NSString	*uniqueFileName = [NSString stringWithFormat:@"%@-%@-%@-%d.%@", [image valueForKeyPath:@"series.study.patientUID"], [image valueForKey:@"sopInstanceUID"], [[image valueForKey:@"path"] lastPathComponent], [[image valueForKey:@"instanceNumber"] intValue], [image valueForKey:@"extension"]];
	NSString	*dicomFileName = [[documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"] stringByAppendingPathComponent: [DicomFile NSreplaceBadCharacter:uniqueFileName]];
	if( [[NSFileManager defaultManager] fileExistsAtPath: dicomFileName])
	{
		[lock unlock];
		return dicomFileName;
	}
	
	[dicomFileNames release];
	dicomFileNames = [[NSMutableArray alloc] initWithCapacity: 0];
	
	[paths release];
	paths = [[NSMutableArray alloc] initWithCapacity: 0];
	
	// TRY TO LOAD MULTIPLE DICOM FILES AT SAME TIME -> better network performances
	
	NSSortDescriptor	*sort = [[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease];
	NSArray				*images = [[[[image valueForKey: @"series"] valueForKey:@"images"] allObjects] sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
	long				size = 0, i = [images indexOfObject: image];
	
	NSLog( @"Bonjour noOfImages: %d", noOfImages);
	
	do
	{
		NSManagedObject	*curImage = [images objectAtIndex: i];
		
		NSString	*uniqueFileName = [NSString stringWithFormat:@"%@-%@-%@-%d.%@", [curImage valueForKeyPath:@"series.study.patientUID"], [curImage valueForKey:@"sopInstanceUID"], [[curImage valueForKey:@"path"] lastPathComponent], [[curImage valueForKey:@"instanceNumber"] intValue], [image valueForKey:@"extension"]];
		
		dicomFileName = [[documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"] stringByAppendingPathComponent: [DicomFile NSreplaceBadCharacter:uniqueFileName]];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: dicomFileName] == NO)
		{
			[paths addObject: [curImage valueForKey:@"path"]];
			[dicomFileNames addObject: dicomFileName];
			
			size += [[curImage valueForKeyPath:@"width"] intValue] * [[curImage valueForKeyPath:@"height"] intValue] * 2 * [[curImage valueForKeyPath:@"numberOfFrames"] intValue];
			
			if([[[curImage valueForKey:@"path"] pathExtension] isEqualToString:@"zip"])
			{
				// it is a ZIP
				NSLog(@"BONJOUR ZIP");
				NSString *xmlPath = [[[curImage valueForKey:@"path"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
				if(![[NSFileManager defaultManager] fileExistsAtPath:xmlPath])
				{
					// it has an XML descriptor with it
					NSLog(@"BONJOUR XML");
					[paths addObject:xmlPath];
					[dicomFileNames addObject: [[dicomFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"]];
				}
			}
		}
		i++;
		
	}while( size < FILESSIZE*noOfImages && i < [images count]);
	
	NSLog( @"File packed for transfer: %d", [dicomFileNames count]);
	
	[self connectToServer: index message:@"DICOM"];
	
	NSString	*returnString;
	
	if( [dicomFileNames count] == 0) returnString = 0L;
	else if( [[NSFileManager defaultManager] fileExistsAtPath: [dicomFileNames objectAtIndex: 0]] == NO) returnString =  0L;
	else returnString = [NSString stringWithString: [dicomFileNames objectAtIndex: 0]];
	
	[lock unlock];
	
	return returnString;
}

- (NSString *) databaseFilePathForService:(NSString*) name
{
	NSMutableString *filePath = [NSMutableString stringWithCapacity:0];
	[filePath appendString:documentsDirectory()];
	[filePath appendString:@"/TEMP/"];
	[filePath appendString:[name stringByAppendingString:@".sql"]];
	return filePath;
}
@end
