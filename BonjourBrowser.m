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

#include <netdb.h>

#import "BonjourBrowser.h"
#import "BrowserController.h"
#import "AppController.h"
#import "DicomFile.h"
#import "DicomImage.h"
#include "SimplePing.h"
#import "DCMNetServiceDelegate.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

#define FILESSIZE 512*512*2

static BOOL bugFixedForDNSResolve = NO;
static int TIMEOUT	= 10;
static NSLock *resolveServiceThreadLock = nil;
#define USEZIP NO

#define OSIRIXRUNMODE @"OsiriXLoopMode"

extern NSThread			*mainThread;

volatile static BOOL threadIsRunning = NO;

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

@implementation BonjourBrowser

- (void) waitTheLock
{
	NSManagedObjectContext *c = [[BrowserController currentBrowser] managedObjectContext];
	
	[c lock];
	[c unlock];
}

+ (NSString*) bonjour2local: (NSString*) str
{
	if( str == nil) return nil;
	
	NSMutableString	*destPath = [NSMutableString string];
	
	[destPath appendString:[[BrowserController currentBrowser] documentsDirectory]];
	[destPath appendString:@"/TEMP/"];
	[destPath appendString: [str lastPathComponent]];

	return destPath;
}

+ (NSString*) uniqueLocalPath:(NSManagedObject*) image
{
	NSString	*uniqueFileName = nil;
	
	if( [[image valueForKey: @"numberOfFrames"] intValue] > 1)
		uniqueFileName = [NSString stringWithFormat:@"%@-%@-%@.%@", [image valueForKeyPath:@"series.study.patientUID"], [image valueForKey:@"sopInstanceUID"], [[[image valueForKey:@"path"] lastPathComponent] stringByDeletingPathExtension], [image valueForKey:@"extension"]];
	else
		uniqueFileName = [NSString stringWithFormat:@"%@-%@-%@-%d.%@", [image valueForKeyPath:@"series.study.patientUID"], [image valueForKey:@"sopInstanceUID"], [[[image valueForKey:@"path"] lastPathComponent] stringByDeletingPathExtension], [[image valueForKey:@"instanceNumber"] intValue], [image valueForKey:@"extension"]];
	
	NSString *dicomFileName = [[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"/TEMP.noindex/"] stringByAppendingPathComponent: [DicomFile NSreplaceBadCharacter:uniqueFileName]];

	return dicomFileName;
}

- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub
{
	self = [super init];
	if (self != nil)
	{
		OSErr err;       
		SInt32 osVersion;
		
		serviceBeingResolvedIndex = -1;
		
		err = Gestalt ( gestaltSystemVersion, &osVersion );       
		if ( err == noErr)       
		{
			if ( osVersion >= 0x1052UL ) bugFixedForDNSResolve = YES;
		}
		
		#if !__LP64__
			bugFixedForDNSResolve = YES;
		#endif
		
		resolveServiceThreadLock = [[NSLock alloc] init];
		async = [[NSLock alloc] init];
		asyncWrite = [[NSLock alloc] init];
		browser = [[NSNetServiceBrowser alloc] init];
		services = [[NSMutableArray array] retain];
		
		[self buildFixedIPList];
		[self buildLocalPathsList];
		[self buildDICOMDestinationsList];
//		[[BrowserController currentBrowser] loadDICOMFromiPod];
		[self arrangeServices];
		
		interfaceOsiriX = bC;
		
		strcpy( messageToRemoteService, ".....");
		
		publisher = bPub;
		
		tempDatabaseFile = [[self databaseFilePathForService: @"incomingDatabaseFile"] retain];
		dbFileName = nil;
		dicomFileNames = nil;
		paths = nil;
		path = nil;
		filePathToLoad = nil;
		FileModificationDate = nil;
		
		localVersion = 0;
		BonjourDatabaseVersion = 0;
		
		resolved = YES;
		
		setValueObject = nil;
		setValueValue = nil;
		setValueKey = nil;
		modelVersion = nil;
		
		[browser setDelegate:self];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DoNotSearchForBonjourServices"] == NO)
			[browser searchForServicesOfType:@"_osirixdbsharing._tcp." inDomain:@""];
		
//		[browser scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												selector: @selector( updateFixedList:)
												name: @"OsiriXServerArray has changed"
												object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												selector: @selector( updateFixedList:)
												name: @"DCMNetServicesDidChange"
												object: nil];
												
	}
	return self;
}

- (void) dealloc
{
	[dicomListener release];
	[path release];
	[paths release];
	[dbFileName release];
	[dicomFileNames release];
	[modelVersion release];
	[FileModificationDate release];
	[filePathToLoad release];
	[tempDatabaseFile release];
	[async release];
	[asyncWrite release];
	[browser release];
	[services release];
	[resolveServiceThreadLock release];
	
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

- (BOOL) processTheData:(NSData *) data
{
	BOOL				success = YES;
	
	if ( strcmp( messageToRemoteService, "DATAB") == 0)
			{
				// we asked for a SQL file, let's write it on disc
				[dbFileName release];
				
				NSDictionary	*dict = [[self services] objectAtIndex:serviceBeingResolvedIndex];
				
				if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) dbFileName = [[self databaseFilePathForService:[[dict valueForKey:@"service"] name]] retain];
				else dbFileName = [[self databaseFilePathForService:[dict valueForKey:@"Description"]] retain];
				
				[[NSFileManager defaultManager] removeFileAtPath: dbFileName handler:nil];
				[[NSFileManager defaultManager] movePath: tempDatabaseFile toPath: dbFileName handler: nil];
				
//				success = [data writeToFile: dbFileName atomically:YES];
			}
			
	if( data)
	{
		if( [data bytes])
		{
			if ( strcmp( messageToRemoteService, "GETDI") == 0)
			{
				[dicomListener release];
				dicomListener = nil;
			
				dicomListener = [NSUnarchiver unarchiveObjectWithData: data];
				if( dicomListener == nil) dicomListener = [NSDictionary dictionary];
				
				dicomListener = [dicomListener retain];
				
				NSLog( [dicomListener description]);
			}
			else if ( strcmp( messageToRemoteService, "MFILE") == 0)
			{
				[FileModificationDate release];
				FileModificationDate = [[NSString alloc] initWithData:data encoding: NSUnicodeStringEncoding];
			}
			else if ( strcmp( messageToRemoteService, "RFILE") == 0)
			{
				BOOL isPages = [[filePathToLoad pathExtension] isEqualToString:@"pages"];
				NSString *zipFilePathToLoad = nil;
				if(isPages)
				{
					zipFilePathToLoad = [filePathToLoad stringByAppendingString:@".zip"];
				}
				else zipFilePathToLoad = filePathToLoad;
				
			
				NSString *destPath = [BonjourBrowser bonjour2local: zipFilePathToLoad];
				[[NSFileManager defaultManager] removeFileAtPath: destPath handler:nil];
				
				int	pos = 0, size;
				NSData	*curData = nil;
				
				// The File
				size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
				pos += 4;
				curData = [data subdataWithRange: NSMakeRange(pos, size)];
				pos += size;
				
				// Write the file
				success = [curData writeToFile:destPath atomically:YES];
				
				if(isPages)
				{
					// unzip the file
					NSTask *unzipTask   = [[NSTask alloc] init];
					[unzipTask setLaunchPath:@"/usr/bin/unzip"];
					[unzipTask setCurrentDirectoryPath:[[destPath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
					[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", destPath, nil]]; // -o to override existing report w/ same name
					[unzipTask launch];
					while( [unzipTask isRunning]) [NSThread sleepForTimeInterval: 0.002];
					int result = [unzipTask terminationStatus];
					[unzipTask release];
					if(result==0)
					{
						destPath = [BonjourBrowser bonjour2local:filePathToLoad];
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
				
				int pos = 0, noOfFiles, size, i;
				
				noOfFiles = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
				pos += 4;
					
				for( i = 0 ; i < noOfFiles; i++)
				{
					size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
					pos += 4;
					
					NSData	*curData = [NSData dataWithBytesNoCopy:(void *) ([data bytes] + pos) length:size freeWhenDone:NO];		//[data subdataWithRange: NSMakeRange(pos, size)];
					pos += size;
					
					size = NSSwapBigIntToHost( *((int*)[[data subdataWithRange: NSMakeRange(pos, 4)] bytes]));
					pos += 4;
					
					NSString *localPath = [NSString stringWithUTF8String: [[data subdataWithRange: NSMakeRange(pos,size)] bytes]];
					pos += size;
					
					if( [curData length])
					{
						if ([[NSFileManager defaultManager] fileExistsAtPath: localPath]) NSLog(@"strange...");
						
						[curData writeToFile: localPath atomically: YES];
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
			else if (strcmp( messageToRemoteService, "DBSIZ") == 0)
			{
				// we asked for the file size of the DB index file
				
				BonjourDatabaseIndexFileSize = NSSwapBigIntToHost( *((int*) [data bytes]));
			}
			else if (strcmp( messageToRemoteService, "PASWD") == 0)
			{
				int result = NSSwapBigIntToHost( *((int*) [data bytes]));
				
				if( result) wrongPassword = NO;
				else wrongPassword = YES;
			}
			else if (strcmp( messageToRemoteService, "ISPWD") == 0)
			{
				int result = NSSwapBigIntToHost( *((int*) [data bytes]));
				
				if( result) isPasswordProtected = YES;
				else isPasswordProtected = NO;
			}
			else if (strcmp( messageToRemoteService, "SETVA") == 0)
			{
				
			}
			else if (strcmp( messageToRemoteService, "REMAL") == 0)
			{
				
			}
			else if (strcmp( messageToRemoteService, "ADDAL") == 0)
			{
				
			}

			if( success == NO)
			{
				NSLog(@"Bonjour transfer failed");
			}
		}
	}
	
	return success;
}

//- (void)readAllTheData:(NSNotification *)note
//{
//	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash (remplissage memoire) - Antoine
//	BOOL				success = YES;
//	NSData				*data = [[[note userInfo] objectForKey:NSFileHandleNotificationDataItem] retain];
//	
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: [note object]];
//	[[note object] release];
//	currentConnection = nil;
//
//	if( data)
//	{
//		success = [self processTheData: data];
//	}
//	
//	[data release];
//	
//	resolved = YES;
//	
//	[pool release];
//}

- (void) asyncWrite: (NSString*) p
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( currentDataPtr != nil)
	{
		[asyncWrite lock];
		
		[async lock];
			int size = currentDataPos - lastAsyncPos;
			int pos = lastAsyncPos;
			lastAsyncPos = currentDataPos;
		[async unlock];
		
		if( size > 0)
		{
			
			FILE *f = fopen ([p UTF8String], "ab");
			fwrite( currentDataPtr + pos, size, 1, f);
			fclose( f);
		}
		[asyncWrite unlock];
	}
	
	[pool release];
}

- (void) incomingConnectionProcess: (NSData*) incomingData
{
	int length = [incomingData length];
	
	if( incomingData && length)
	{
		[async lock];
		if( currentDataPtr == nil)
		{
			currentDataPtr = malloc( BonjourDatabaseIndexFileSize);
			currentDataPos = 0;
		}
		
		if( currentDataPtr)
		{
			if( currentDataPos + length > BonjourDatabaseIndexFileSize)
			{
				NSLog( @"error: currentDataPos + length > BonjourDatabaseIndexFileSize");
				[currentConnection closeFile];
				[currentConnection release];
				currentConnection = nil;
			}
			else
				memcpy( currentDataPtr + currentDataPos, [incomingData bytes], length);
			currentDataPos += length;
		}
		
		if( currentDataPos - lastAsyncPos > 1024L * 1024L * 10L)
			[NSThread detachNewThreadSelector: @selector( asyncWrite:) toTarget: self withObject: tempDatabaseFile];
		
		[async unlock];
		
		NSDate *oldCurrentTimeOut = currentTimeOut;
		currentTimeOut = [[NSDate dateWithTimeIntervalSinceNow: TIMEOUT] retain];
		[oldCurrentTimeOut release];
	}
	else
	{
		[self asyncWrite: tempDatabaseFile];
		
		[async lock];
		[asyncWrite lock];
		
		[self processTheData: nil];
		
		if( currentDataPtr)
		{
			free( currentDataPtr);
			currentDataPtr = nil;
		}
		currentDataPos = 0;
		
		resolved = YES;
		
		[currentConnection closeFile];
		[currentConnection release];
		currentConnection = nil;
		
		[asyncWrite unlock];
		[async unlock];
	}
}

//- (void) incomingConnection:(NSNotification *) note
//{
//	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
//	
//	NSData		*incomingData = [[note userInfo] objectForKey: NSFileHandleNotificationDataItem];
//	
//	[self incomingConnectionProcess: incomingData];
//	
//	if( [incomingData length]) [currentConnection readInBackgroundAndNotifyForModes: [NSArray arrayWithObject:OSIRIXRUNMODE]];
//	else [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:currentConnection];
//	
//	[pool release];
//}

- (BOOL) connectToService: (struct sockaddr_in*) socketAddress
{
	BOOL succeed = NO;
	
//	NSString *ip = [NSString stringWithFormat: @"%s",inet_ntoa (socketAddress->sin_addr)];
//	if( [publisher  OsiriXDBCurrentPort] == ntohs( socketAddress->sin_port))
//	{
//		for( NSString *p in [[NSHost currentHost] addresses])
//		{
//			if( [p isEqualToString: ip])
//			{
//				NSLog(@"it's us!");
//				return NO;
//			}
//		}
//	}
	
	int socketToRemoteServer = socket(AF_INET, SOCK_STREAM, 0);	//SOCK_STREAM, 0);
	
//	int sock_buf_size = 10000;
//
//	setsockopt( socketToRemoteServer, SOL_SOCKET, SO_SNDBUF, (char *)&sock_buf_size, sizeof(sock_buf_size) );
//	setsockopt( socketToRemoteServer, SOL_SOCKET, SO_RCVBUF, (char *)&sock_buf_size, sizeof(sock_buf_size) );
	
	if(socketToRemoteServer > 0)
	{
		// SEND DATA
	
		currentConnection = [[NSFileHandle alloc] initWithFileDescriptor:socketToRemoteServer closeOnDealloc:YES];
		if( currentConnection)
		{
			 if(connect(socketToRemoteServer, (struct sockaddr *)socketAddress, sizeof(*socketAddress)) == 0)
			 {
//				NSLog( @"socket connected: %d", socketToRemoteServer);
			 
				// transfering the type of data we need
				NSMutableData	*toTransfer = [NSMutableData dataWithCapacity:0];
				
				[toTransfer appendBytes:messageToRemoteService length: 6];

				if (strcmp( messageToRemoteService, "ADDAL") == 0)
				{
					const char* string;
					int stringSize;
					
					string = [[[NSDictionary dictionaryWithObjectsAndKeys: albumStudies, @"albumStudies", albumUID, @"albumUID", nil] description] UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
				}
				
				if (strcmp( messageToRemoteService, "REMAL") == 0)
				{
					const char* string;
					int stringSize;
					
					string = [[[NSDictionary dictionaryWithObjectsAndKeys: albumStudies, @"albumStudies", albumUID, @"albumUID", nil] description] UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
				}
				
				if (strcmp( messageToRemoteService, "SETVA") == 0)
				{
					const char* string;
					int stringSize;
					
					string = [setValueObject UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
					
					if( setValueValue == nil)
					{
						string = nil;
						stringSize = 0;
					}
					else if( [setValueValue isKindOfClass:[NSNumber class]])
					{
						string = [[setValueValue stringValue] UTF8String];
						stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					}
					else
					{
						string = [setValueValue UTF8String];
						stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					}
					
					[toTransfer appendBytes:&stringSize length: 4];
					if( stringSize)
						[toTransfer appendBytes:string length: strlen( string)+1];
					
					string = [setValueKey UTF8String];
					stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
				}
				
				if (strcmp( messageToRemoteService, "RFILE") == 0)
				{
					NSLog(@"ask for : %@", filePathToLoad);
					NSData	*filenameData = [filePathToLoad dataUsingEncoding: NSUnicodeStringEncoding];
					int stringSize = NSSwapHostIntToBig( [filenameData length]);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:[filenameData bytes] length: [filenameData length]];
				}
				
				if (strcmp( messageToRemoteService, "MFILE") == 0)
				{
					NSData	*filenameData = [filePathToLoad dataUsingEncoding: NSUnicodeStringEncoding];
					int stringSize = NSSwapHostIntToBig( [filenameData length]);	// +1 to include the last 0 !
					
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
						
						[[NSFileManager defaultManager] removeFileAtPath: [[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingPathComponent: zipFileName] handler: nil];
						
						// zip the directory into a single archive file
						NSTask *zipTask   = [[NSTask alloc] init];
						[zipTask setLaunchPath:@"/usr/bin/zip"];
						[zipTask setCurrentDirectoryPath:[[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
						[zipTask setArguments:[NSArray arrayWithObjects:@"-r" , zipFileName, [filePathToLoad lastPathComponent], nil]];
						[zipTask launch];
						while( [zipTask isRunning]) [NSThread sleepForTimeInterval: 0.002];
						int result = [zipTask terminationStatus];
						[zipTask release];
						
						if(result==0)
						{
							NSMutableString *path2 = (NSMutableString*)[[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingPathComponent: zipFileName];
							[filePathToLoad release];
							filePathToLoad = [path2 retain];
							NSLog(@"filePathToLoad : %@", filePathToLoad);
						}
					}
				
					NSData	*filenameData = [filePathToLoad dataUsingEncoding: NSUnicodeStringEncoding];
					int stringSize = NSSwapHostIntToBig( [filenameData length]);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:[filenameData bytes] length: [filenameData length]];
					
					NSData	*fileData = [NSData dataWithContentsOfFile: filePathToLoad];
					int dataSize = NSSwapHostIntToBig( [fileData length]);
					[toTransfer appendBytes:&dataSize length: 4];
					[toTransfer appendData: fileData];
					
					if( isPages)
						[[NSFileManager defaultManager] removeFileAtPath: filePathToLoad handler: nil];
				}
				
				if (strcmp( messageToRemoteService, "DICOM") == 0)
				{
					int i, temp, noOfFiles = [paths count];
					
					temp = NSSwapHostIntToBig( noOfFiles);
					[toTransfer appendBytes:&temp length: 4];
					for( i = 0; i < noOfFiles ; i++)
					{
						const char* string = [[paths objectAtIndex: i] UTF8String];
						int stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
						
						[toTransfer appendBytes:&stringSize length: 4];
						[toTransfer appendBytes:string length: strlen( string)+1];
					}
					
					for( i = 0; i < noOfFiles ; i++)
					{
						const char* string = [[dicomFileNames objectAtIndex: i] UTF8String];
						int stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
						
						[toTransfer appendBytes:&stringSize length: 4];
						[toTransfer appendBytes:string length: strlen( string)+1];
					}
				}
				
				if (strcmp( messageToRemoteService, "DCMSE") == 0)
				{
					int temp, noOfFiles = [paths count];
					
					const char* string;
					int stringSize;
					
					// DICOM DESTINATION: DICOM NODE : AETitle, IP Address, and Port
					
					string = [[dicomDestination valueForKey:@"AETitle"] UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
					
					string = [[dicomDestination valueForKey:@"Address"] UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
					
					string = [[dicomDestination valueForKey:@"Port"] UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
					
					string = [[dicomDestination valueForKey:@"Transfer Syntax"] UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:string length: strlen( string)+1];
					
					// Which Files
					
					temp = NSSwapHostIntToBig( noOfFiles);
					[toTransfer appendBytes:&temp length: 4];
					for( id loopItem1 in paths)
					{
						const char* string = [loopItem1 UTF8String];
						int stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
						
						[toTransfer appendBytes:&stringSize length: 4];
						[toTransfer appendBytes:string length: strlen( string)+1];
					}
				}
				
				if ((strcmp( messageToRemoteService, "SENDD") == 0))
				{
					int temp, noOfFiles = [paths count];
					
					temp = NSSwapHostIntToBig( noOfFiles);
					[toTransfer appendBytes:&temp length: 4];
					
					for( id loopItem in paths)
					{
						NSData	*file = [NSData dataWithContentsOfFile: loopItem];
						
						int fileSize = NSSwapHostIntToBig( [file length]);
						[toTransfer appendBytes:&fileSize length: 4];
						[toTransfer appendData:file];
					}
				}
				
				if ((strcmp( messageToRemoteService, "PASWD") == 0))
				{
					const char* passwordUTF = [password UTF8String];
					int stringSize = NSSwapHostIntToBig( strlen( passwordUTF)+1);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:passwordUTF length: strlen( passwordUTF)+1];
				}
				
				@try
				{
					[currentConnection writeData: toTransfer];
				}
				
				@catch ( NSException *e)
				{
					NSLog(@"connectToService [currentConnection writeData: toTransfer] exception: %@", e);
					[currentConnection closeFile];
					[currentConnection release];
					currentConnection = nil;
					resolved = NO;
					succeed = NO;
				}
				
				if( currentConnection)
				{
					// *************
					if ((strcmp( messageToRemoteService, "DATAB") == 0))
					{
						NSData *readData = nil;
						
						@try
						{
							while( connectToServerAborted == NO && (readData = [currentConnection availableData]) && [readData length])
							{
								[self incomingConnectionProcess: readData];
							}
							
							[self incomingConnectionProcess: readData];
						}
						@catch ( NSException *e)
						{
							NSLog(@"connectToService 'DATAB' exception: %@", e);
						}
					}
					else
					{
						NSData *readData = nil;
						NSMutableData *data = [NSMutableData dataWithCapacity: 512*512*2*20];
						
						@try
						{
							while( (readData = [currentConnection availableData]) && [readData length])
							{
								[data appendData: readData];
								
								NSDate *oldCurrentTimeOut = currentTimeOut;
								currentTimeOut = [[NSDate dateWithTimeIntervalSinceNow: TIMEOUT] retain];
								[oldCurrentTimeOut release];
								
	//							NSLog( @"%d", [readData length]);
							}
							
							[self processTheData: data];
							
							[currentConnection closeFile];
							[currentConnection release];
							currentConnection = nil;
							
							resolved = YES;
						}
						@catch ( NSException *e)
						{
							NSLog(@"connectToService exception: %@", e);
						}
					}
					
					succeed = YES;
				}
			}
			else
			{
//				[self performSelectorOnMainThread: @selector(showErrorMessage:) withObject: NSLocalizedString( @"Failed to connect to the distant computer. Is OsiriX running on it? OsiriX database sharing activated? Firewall on port 8780?", nil) waitUntilDone: NO];
				
				NSLog( @"Failed to connect to the distant computer: is there a firewall on port 8780?? is OsiriX running on this distant computer?? aborted??");
//				[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: currentConnection];
//				[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: currentConnection];
				[currentConnection release];
				currentConnection = nil;
			}
		}
		else
		{
			close(socketToRemoteServer);
			NSLog( @"NSFileHandle creation failed");
		}
	}
	else NSLog( @"socket creation failed");
	
	return succeed;
}


- (void)showErrorMessage: (NSString*) s
{	
	NSAlert* alert = [NSAlert new];
	[alert setMessageText: NSLocalizedString(@"Network Error",nil)];
	[alert setInformativeText: s];
	[alert runModal];
}

- (void) buildFixedIPList
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncOsiriXDB"])
	{
		NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncOsiriXDBURL"]];
		
		if( url)
		{
			NSArray	*r = [NSArray arrayWithContentsOfURL: url];
			if( r)
				[[NSUserDefaults standardUserDefaults] setObject: r forKey: @"OSIRIXSERVERS"];
		}
	}

	int			i;
	NSArray		*osirixServersArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"OSIRIXSERVERS"];
	
	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"fixedIP"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [osirixServersArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [osirixServersArray objectAtIndex: i]];
		[dict setValue:@"fixedIP" forKey:@"type"];
	
		[services addObject: dict];
	}
}

- (void) buildDICOMDestinationsList
{
	int			i;
	NSArray		*dbArray = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
	
	if( dbArray == nil) dbArray = [NSArray array];
	
	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"dicomDestination"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [dbArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [dbArray objectAtIndex: i]];
		
		[dict setValue:@"dicomDestination" forKey:@"type"];
		[services addObject: dict];
	}
}

- (void) buildLocalPathsList
{
	int			i;
	NSArray		*dbArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
	NSString	*defaultPath = documentsDirectoryFor( [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]);
	
	if( dbArray == nil) dbArray = [NSArray array];
	
	for( i = 0; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"localPath"])
		{
			[services removeObjectAtIndex: i];
			i--;
		}
	}
	
	for( i = 0; i < [dbArray count]; i++)
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [dbArray objectAtIndex: i]];
		
		if( [[dict valueForKey:@"Path"] isEqualToString: defaultPath] == NO && [[[dict valueForKey:@"Path"] stringByAppendingPathComponent:@"OsiriX Data"] isEqualToString: defaultPath] == NO)
		{
			[dict setValue:@"localPath" forKey:@"type"];
			[services addObject: dict];
		}
	}
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) updateFixedList: (NSNotification*) note
{
	int i = [[BrowserController currentBrowser] currentBonjourService];
	
	NSDictionary	*selectedDict = nil;
	
	if( i >= 0) selectedDict = [[services objectAtIndex: i] retain];
	
	[self buildFixedIPList];
	[self buildLocalPathsList];
	[[BrowserController currentBrowser] loadDICOMFromiPod];
	[self buildDICOMDestinationsList];
	[self arrangeServices];
	
	[interfaceOsiriX displayBonjourServices];
	
	if( selectedDict)
	{
		NSInteger index = [services indexOfObject: selectedDict];
		
		if( index == NSNotFound)
			[[BrowserController currentBrowser] resetToLocalDatabase];
		else
			[[BrowserController currentBrowser] setCurrentBonjourService: index];
		
		[selectedDict release];
	}
	
	[interfaceOsiriX displayBonjourServices];
}

- (void) arrangeServices
{
	// Order them, first the localPath, fixedIP, and then bonjour
	
	NSMutableArray	*result = [NSMutableArray array];
	int i;
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"localPath"])
			[result addObject: [services objectAtIndex: i]];
	}
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"fixedIP"])
			[result addObject: [services objectAtIndex: i]];
	}
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"bonjour"])
			[result addObject: [services objectAtIndex: i]];
	}
	
	for( i = 0 ; i < [services count]; i++)
	{
		if( [[[services objectAtIndex: i] valueForKey:@"type"] isEqualToString:@"dicomDestination"])
			[result addObject: [services objectAtIndex: i]];
	}

	[services removeAllObjects];
	[services addObjectsFromArray: result];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (BOOL) connectToAdress: (NSString*) address port: (int) port
{
	struct sockaddr_in service;
	const char	*host_name = [address UTF8String];
	
	bzero((char *) &service, sizeof(service));
	service.sin_family = AF_INET;
	
	if( host_name == nil) return NO;
	
	if (isalpha(host_name[0]))
	{
		struct hostent *hp;
		
		hp = gethostbyname( host_name);
		if( hp) bcopy(hp->h_addr, (char *) &service.sin_addr, hp->h_length);
		else service.sin_addr.s_addr = inet_addr( host_name);
	}
	else service.sin_addr.s_addr = inet_addr( host_name);
	
	service.sin_port = htons( port);
	
	return [self connectToService: &service];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
	if( bugFixedForDNSResolve)
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

						break;
					case AF_INET6:
						// OsiriX server doesn't support IPv6
						return;
				}
			}
			
			for( NSDictionary *serviceDict in services)
			{
				if( [serviceDict objectForKey:@"service"] == sender)
				{
					NSLog( @"netServiceDidResolveAddress: %@:%@", ipAddressString, portString);
					
					[serviceDict setValue: ipAddressString forKey:@"Address"];
					[serviceDict setValue: portString forKey:@"OsiriXPort"];
				}
			}
		}
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
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: aNetService, @"service", @"bonjour", @"type", nil];
		
		[services addObject:dict];
		
		// Resolve the address and port for this NSNetService
		
		if( bugFixedForDNSResolve)
		{
			[aNetService setDelegate:self];
			[aNetService resolveWithTimeout: 5];
		}
	}
	
	// update interface
    if(!moreComing)
	{
		if( bugFixedForDNSResolve == NO)
		{
			NSTask *theTask = [[NSTask alloc] init];
			
			[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/dnsresolve" handler:nil];
			[theTask setArguments: [NSArray arrayWithObjects: @"DNSResolve", @"/tmp/dnsresolve", nil]];
			[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/32-bit shell.app/Contents/MacOS/32-bit shell"]];
			[theTask launch];
			[theTask waitUntilExit];
			[theTask release];
			
			NSMutableArray *newServices = [NSMutableArray arrayWithContentsOfFile: @"/tmp/dnsresolve"];
			
			for (NSDictionary *newDict in newServices)
			{
				for( NSMutableDictionary *s in services)
				{
					if( [[newDict valueForKey:@"Name"] isEqualToString: [[s objectForKey:@"service"] name]])
					{	
						[s setValue: [newDict valueForKey:@"Address"] forKey:@"Address"];
						[s setValue: [newDict valueForKey:@"OsiriXPort"] forKey:@"OsiriXPort"];
					}
				}
			}
		}
		
		[self arrangeServices];
		[interfaceOsiriX displayBonjourServices];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing 
{
    // This case is slightly more complicated. We need to find the object in the list and remove it.
    NSEnumerator * enumerator = [services objectEnumerator];
    NSNetService * currentNetService;
	
    while(currentNetService = [enumerator nextObject])
	{
        if( [[currentNetService valueForKey: @"service"] isEqual: aNetService])
		{
			// deleting the associate SQL temporary file
			if ([[NSFileManager defaultManager] fileExistsAtPath: [self databaseFilePathForService:[aNetService name]] ])
			{
				[[NSFileManager defaultManager] removeFileAtPath: [self databaseFilePathForService:[[currentNetService valueForKey: @"service"] name]] handler:self];
			}
			if( [interfaceOsiriX currentBonjourService] > 0)
			{
				if( [[services objectAtIndex: [interfaceOsiriX currentBonjourService]] valueForKey: @"service"] == aNetService)
				{
					[interfaceOsiriX resetToLocalDatabase];
				}
			}
			
			// deleting service from list
			NSInteger index = [services indexOfObject: currentNetService];
			if( index != NSNotFound)
			{
				NSLog( @"didRemove retainCout: %d", [currentNetService retainCount]);
				[services removeObjectAtIndex: index];
			}
            break;
        }
    }
	
    if(!moreComing)
	{
		[self arrangeServices];
		[interfaceOsiriX displayBonjourServices];
	}
}

- (BOOL) resolveServiceWithIndex:(int)index msg: (char*) msg
{
	BOOL succeed = NO;
	
	serviceBeingResolvedIndex = index;
	strcpy( messageToRemoteService, msg);
	resolved = YES;
	
	NSDictionary	*dict = nil;
	
	if( index >= 0) dict = [services objectAtIndex:index];
	
    if(-1 == index)
	{
	
    }
	else if( [[dict valueForKey:@"type"] isEqualToString:@"fixedIP"])
	{
		resolved = NO;
		succeed = [self connectToAdress: [dict valueForKey:@"Address"]  port: 8780];
	}
	else if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"])
	{   
		if( [dict valueForKey:@"Address"] && [dict valueForKey:@"OsiriXPort"])
		{
			resolved = NO;
			succeed = [self connectToAdress: [dict valueForKey:@"Address"]  port: [[dict valueForKey:@"OsiriXPort"] intValue]];
		}
		else
		{
			if( bugFixedForDNSResolve == NO)
				NSRunCriticalAlertPanel( NSLocalizedString( @"Bonjour Error", nil), NSLocalizedString( @"There is a bug in MacOS 10.5 for 64-bit application. Bonjour addresses cannot be resolved. Try to add this OsiriX workstation as a fixed node in Locations-Preferences.", nil), NSLocalizedString(@"OK", nil), 0, 0);
			else
				NSRunCriticalAlertPanel( NSLocalizedString( @"Bonjour Error", nil), NSLocalizedString( @"This address wasn't resolved. Try to add this OsiriX workstation as a fixed node in Locations-Preferences.", nil), NSLocalizedString(@"OK", nil), 0, 0);
			
			resolved = NO;
			succeed = NO;
		}
    }
	else
	{
		NSLog( @"ERROR index: %d : %@", index, dict);
	}
	
	return succeed;
}

- (void) resolveServiceThread:(NSDictionary*) object
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	[resolveServiceThreadLock lock];
	
	resolved = NO;
	
	@try
	{
		[self resolveServiceWithIndex: [[object valueForKey:@"index"] intValue] msg: (char*) [[object valueForKey:@"msg"] UTF8String]];
	}
	
	@catch (NSException * e)
	{
		NSLog(@"resolveServiceThread exception: %@", e);
	}
	
	[resolveServiceThreadLock unlock];
	
	[pool release];
	
	threadIsRunning = NO;
}

- (void) setWaitDialog: (WaitRendering*) w
{
	waitWindow = w;
}

- (void) abort:(id) sender
{
	connectToServerAborted = YES;
}

- (BOOL) connectToServer:(int) index message:(NSString*) message
{
	WaitRendering	*w = nil;
	
	connectToServerAborted = NO;
	
	w = waitWindow;

	NSDictionary	*dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: index], @"index", message, @"msg", nil];
	
	long previousPercentage = 0;
	
	NSDate *oldCurrentTimeOut = currentTimeOut;
	currentTimeOut = [[NSDate dateWithTimeIntervalSinceNow: TIMEOUT] retain];
	[oldCurrentTimeOut release];
	
	threadIsRunning = YES;
	[NSThread detachNewThreadSelector:@selector(resolveServiceThread:) toTarget:self withObject: dict];
	while( threadIsRunning == YES  && connectToServerAborted == NO && [currentTimeOut timeIntervalSinceNow] >= 0)
	{
		[NSThread sleepForTimeInterval: 0.01];
		
		if( w)
		{
			if( [w run] == NO) connectToServerAborted = YES;
			
			if( BonjourDatabaseIndexFileSize)
			{
				float fcurrentPercentage = (float) currentDataPos / (float) BonjourDatabaseIndexFileSize;
				
				int currentPercentage = fcurrentPercentage * 100;
				
				currentPercentage /= 4;
				currentPercentage *= 4;
				
				if( currentPercentage != previousPercentage)
				{
					previousPercentage = currentPercentage;
					[w setString: [NSString stringWithFormat:@"Downloading DB Index File (%d %%)", (int) currentPercentage]];
				}
			}
		}
	}
	
	if( w)
	{
		[w setString: @"Connecting..."];
	}
	
	if( connectToServerAborted)
	{
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: currentConnection];
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: currentConnection];

		[currentConnection closeFile];

		while( threadIsRunning == YES)
			[NSThread sleepForTimeInterval: 0.002];
		
		[currentConnection release];
		currentConnection = nil;
		
		resolved = NO;
		
		return NO;
	}
	
	return resolved;
}

#pragma mark-
#pragma mark Network functions

- (NSDictionary*) getDICOMDestinationInfo:(int) index
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[dicomListener release];
	dicomListener = nil;
	
	[self connectToServer: index message:@"GETDI"];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	if( dicomListener == nil)
		dicomListener = [[NSDictionary dictionary] retain];
	
	return dicomListener;
}

- (BOOL) isBonjourDatabaseUpToDate: (int) index
{
	if( [[[BrowserController currentBrowser] managedObjectContext] tryLock] == NO) return YES;
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	BOOL result;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[self connectToServer: index message:@"VERSI"];
	
	if( localVersion == BonjourDatabaseVersion) result = YES;
	else result = NO;
	
	if( result == NO)
	{
		NSLog( @"isBonjourDatabaseUpToDate == NO");
 		NSLog( @"date: %@ versus: %@", [[NSDate dateWithTimeIntervalSinceReferenceDate:localVersion] description], [[NSDate dateWithTimeIntervalSinceReferenceDate:BonjourDatabaseVersion] description]);
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return result;
}

- (void) removeStudies: (NSArray*) studies fromAlbum: (NSManagedObject*) album bonjourIndex:(int) index
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[albumStudies release];
	[albumUID release];
	
	albumStudies = [[NSMutableArray array] retain];
	for( NSManagedObject *s in studies)
		[albumStudies addObject: [[[s objectID] URIRepresentation] absoluteString]];
	
	albumUID = [[[[album objectID] URIRepresentation] absoluteString] retain];
	
	[self connectToServer: index message:@"REMAL"];
	
	[NSThread sleepForTimeInterval: 0.1];  // for rock stable opening/closing socket
	
	[self connectToServer: index message:@"VERSI"];
	localVersion = BonjourDatabaseVersion;
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
}

- (void) addStudies: (NSArray*) studies toAlbum: (NSManagedObject*) album bonjourIndex:(int) index
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[albumStudies release];
	[albumUID release];
	
	albumStudies = [[NSMutableArray array] retain];
	for( NSManagedObject *s in studies)
		[albumStudies addObject: [[[s objectID] URIRepresentation] absoluteString]];
	
	albumUID = [[[[album objectID] URIRepresentation] absoluteString] retain];
	
	[self connectToServer: index message:@"ADDAL"];
	
	[NSThread sleepForTimeInterval: 0.1];  // for rock stable opening/closing socket
	
	[self connectToServer: index message:@"VERSI"];
	localVersion = BonjourDatabaseVersion;
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
}

- (void) setBonjourDatabaseValue:(int) index item:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[setValueObject release];
	[setValueValue release];
	[setValueKey release];
	
	setValueObject = [[[[obj objectID] URIRepresentation] absoluteString] retain];
	setValueValue = [value retain];
	setValueKey = [key retain];
	
	[self connectToServer: index message:@"SETVA"];
	
	[NSThread sleepForTimeInterval: 0.1];  // for rock stable opening/closing socket
	
	[self connectToServer: index message:@"VERSI"];
	localVersion = BonjourDatabaseVersion;
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
}

- (NSDate*) getFileModification:(NSString*) pathFile index:(int) index 
{
	NSDate			*modificationDate = nil;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: [BonjourBrowser bonjour2local: pathFile]])
	{
		NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:[BonjourBrowser bonjour2local: pathFile] traverseLink:YES];
		return [fattrs objectForKey:NSFileModificationDate];
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[filePathToLoad release];
	
	filePathToLoad = [pathFile retain];
	
	[self connectToServer: index message:@"MFILE"];
	
	if( resolved == YES)
	{
		modificationDate = [NSDate dateWithString: FileModificationDate];
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	return modificationDate;
}

- (NSString*) getFile:(NSString*) pathFile index:(int) index 
{
	NSString	*returnedFile = nil;
	
	// Does the file already exist?
	
	returnedFile = [BonjourBrowser bonjour2local: pathFile];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath:returnedFile]) return returnedFile;
	else returnedFile = nil;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[filePathToLoad release];
	filePathToLoad = [pathFile retain];
	
	[self connectToServer: index message:@"RFILE"];
	
	if( resolved == YES)
	{
		returnedFile = [BonjourBrowser bonjour2local: filePathToLoad];
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return returnedFile;
}

- (BOOL) sendFile:(NSString*) pathFile index:(int) index 
{
	BOOL succeed = NO;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[filePathToLoad release];
	
	filePathToLoad = [pathFile retain];
	
	[self connectToServer: index message:@"WFILE"];
	
	if( resolved == YES)
	{
		succeed = YES;
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return succeed;
}

- (NSString*) getDatabaseFile:(int) index
{
	return [self getDatabaseFile: index showWaitingWindow: NO];
}

- (NSString*) getDatabaseFile:(int) index showWaitingWindow: (BOOL) showWaitingWindow
{
	BOOL newConnection = NO;
	
	if( serviceBeingResolvedIndex != index)
		newConnection = YES;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[dbFileName release];
	dbFileName = nil;
	
	isPasswordProtected = NO;

	if( showWaitingWindow)
		waitWindow = [[WaitRendering alloc] init: NSLocalizedString(@"Connecting to OsiriX database...", nil)];
	else
		waitWindow = nil;

	BonjourDatabaseIndexFileSize = 0;
	currentDataPos = 0;

	[waitWindow showWindow:self];
	[waitWindow setCancel: YES];
	[waitWindow setCancelDelegate: self];
	[waitWindow start];
	
	if( [self connectToServer: index message:@"DBVER"])
	{
		[NSThread sleepForTimeInterval: 0.1]; // for rock stable opening/closing socket
		
		if( [modelVersion isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"]] == NO)
		{
			[[[BrowserController currentBrowser] managedObjectContext] unlock];
			[waitWindow end];
			[waitWindow release];
			waitWindow = nil;
			
			NSRunAlertPanel( NSLocalizedString( @"Bonjour Database", nil), NSLocalizedString( @"Database structure is not identical. Use the SAME version of OsiriX on clients and servers to correct the problem.", nil), nil, nil, nil);
			
			return nil;
		}
		
		if( newConnection)
		{
			[self connectToServer: index message:@"ISPWD"];
			
			[NSThread sleepForTimeInterval: 0.1];  // for rock stable opening/closing socket
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
				password = nil;
				
				password = [[interfaceOsiriX askPassword] retain];
				
				wrongPassword = YES;
				[self connectToServer: index message:@"PASWD"];
				[NSThread sleepForTimeInterval: 0.1]; // for rock stable opening/closing socket
				
				if( resolved == NO || wrongPassword == YES)
				{
					[[[BrowserController currentBrowser] managedObjectContext] unlock];
					[waitWindow end];
					[waitWindow release];
					waitWindow = nil;
					
					NSRunAlertPanel( NSLocalizedString( @"Bonjour Database", nil), NSLocalizedString( @"Wrong password.", nil), nil, nil, nil);
					serviceBeingResolvedIndex = -1;
					
					return nil;
				}
			}
			
			if( [self connectToServer: index message: @"DBSIZ"] == YES)
			{
				[NSThread sleepForTimeInterval: 0.1]; // for rock stable opening/closing socket
				
				if( BonjourDatabaseIndexFileSize)
				{
					NSLog( @"BonjourDatabaseIndexFileSize = %d Kb", BonjourDatabaseIndexFileSize/1024);
					
					if( currentDataPtr)
					{
						[async lock];
						free( currentDataPtr);
						currentDataPtr = nil;
						[async unlock];
					}
					
					// For async writing
					[[NSFileManager defaultManager] removeFileAtPath: tempDatabaseFile handler: nil];
					[[NSFileManager defaultManager] createFileAtPath: tempDatabaseFile contents:nil attributes:nil];
					lastAsyncPos = 0;
					[async lock];
					[async unlock];
					
					if( [self connectToServer: index message: @"DATAB"] == YES)
					{
						[NSThread sleepForTimeInterval: 0.1]; // for rock stable opening/closing socket
						
						[self connectToServer: index message: @"VERSI"];
						
						localVersion = BonjourDatabaseVersion;
					}
					else
					{
						[dbFileName release];
						dbFileName = nil;
					}
					
					if( currentDataPtr)
					{
						[async lock];
						free( currentDataPtr);
						currentDataPtr = nil;
						[async unlock];
					}
				}
				else
				{
					[dbFileName release];
					dbFileName = nil;
				}
			}
			else
			{
				[dbFileName release];
				dbFileName = nil;
			}
		}
		else
		{
			[dbFileName release];
			dbFileName = nil;
		}
	}
	else
	{
		[dbFileName release];
		dbFileName = nil;
	}
	
	NSString *returnedPath = dbFileName;
	
	if( [waitWindow aborted]) returnedPath = @"aborted";
	
	[waitWindow end];
	[waitWindow close];
	[waitWindow release];
	waitWindow = nil;
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return returnedPath;
}

- (BOOL) retrieveDICOMFilesWithSTORESCU:(int) indexFrom to:(int) indexTo paths:(NSArray*) ip
{
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"] == NO) return NO;
	
	//Do we have DICOM Node informations about the destination node?
	if( indexTo >= 0)	// indexTo == -1: this computer
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [services objectAtIndex: indexTo]];
		[dict addEntriesFromDictionary: [self getDICOMDestinationInfo: indexTo]];
		[services replaceObjectAtIndex:indexTo withObject: dict];
		
		if( [dict valueForKey: @"Port"] == nil) return NO;
	}
	
	if( indexFrom >= 0)	// indexFrom == -1: this computer
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [services objectAtIndex: indexFrom]];
		[dict addEntriesFromDictionary: [self getDICOMDestinationInfo: indexFrom]];
		[services replaceObjectAtIndex:indexFrom withObject: dict];
		
		if( [dict valueForKey: @"Port"] == nil) return NO;
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[paths release];
	paths = [ip retain];
	
	[dicomDestination release];
	if( indexTo >= 0)
	{
		dicomDestination = [[services objectAtIndex: indexTo] retain];
	}
	else // indexTo == -1: this computer
	{
		NSString *address = [NSString stringWithCString:GetPrivateIP()];
		
		dicomDestination = [NSDictionary dictionaryWithObjectsAndKeys: address, @"Address", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"AETitle", [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"], @"Port", @"0", @"Transfer Syntax", nil];
		
		[dicomDestination retain];
	}
	
	[self connectToServer: indexFrom message:@"DCMSE"];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return YES;
}

- (BOOL) sendDICOMFile:(int) index paths:(NSArray*) ip
{
	for( id loopItem in ip)
	{
		if( [[NSFileManager defaultManager] fileExistsAtPath: loopItem] == NO) return NO;
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[paths release];
	paths = [ip retain];
	
	BOOL success = [self connectToServer: index message:@"SENDD"];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return success;
}

- (void) getDICOMROIFiles:(int) index roisPaths:(NSArray*) roisPaths
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	[dicomFileNames release];
	dicomFileNames = [[NSMutableArray alloc] initWithCapacity: 0];
	
	[paths release];
	paths = [[NSMutableArray alloc] initWithCapacity: 0];
	
	// TRY TO LOAD MULTIPLE DICOM FILES AT SAME TIME -> better network performances
	
	NSString	*roistring = [NSString stringWithString:@"ROIs/"];
	
	for( id loopItem in roisPaths)
	{
		NSString	*local = [[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"/TEMP.noindex/"] stringByAppendingPathComponent: loopItem];
		 
		if( [[NSFileManager defaultManager] fileExistsAtPath: local] == NO)
		{
			[paths addObject: [roistring stringByAppendingPathComponent: loopItem]];
			[dicomFileNames addObject: [BonjourBrowser bonjour2local: loopItem]];
		}
	}
	
	if( [dicomFileNames count] > 0)
		[self connectToServer: index message:@"DICOM"];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
}

- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (int) noOfImages
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	// Does this file already exist?
	NSString	*dicomFileName = [BonjourBrowser uniqueLocalPath: image];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: dicomFileName])
	{
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
		return dicomFileName;
	}
	
	[dicomFileNames release];
	dicomFileNames = [[NSMutableArray alloc] initWithCapacity: 0];
	
	[paths release];
	paths = [[NSMutableArray alloc] initWithCapacity: 0];
	
	// TRY TO LOAD MULTIPLE DICOM FILES AT SAME TIME -> better network performances
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	NSSortDescriptor	*sort = [[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease];
	NSArray				*images = [[[[image valueForKey: @"series"] valueForKey:@"images"] allObjects] sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
	NSInteger			size = 0, i = [images indexOfObject: image];
	
	do
	{
		DicomImage	*curImage = [images objectAtIndex: i];
		
		dicomFileName = [BonjourBrowser uniqueLocalPath: curImage];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: dicomFileName] == NO)
		{
			[paths addObject: [curImage valueForKey:@"path"]];
			[dicomFileNames addObject: dicomFileName];
			
			size += [[curImage valueForKey:@"width"] intValue] * [[curImage valueForKey:@"height"] intValue] * 2 * [[curImage valueForKey:@"numberOfFrames"] intValue];
			
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
			
//			NSManagedObject	*roiSRSeries = [[curImage valueForKeyPath:@"series.study"] valueForKey:@"roiSRSeries"];
//			
//			NSArray	*rois = [curImage SRPaths];
//			
//			int x;
//			for( x = 0; x < [rois count] ; x++)
//			{
//				if( [[NSFileManager defaultManager] fileExistsAtPath: [rois objectAtIndex: x]])
//				{
//					[paths addObject: [rois objectAtIndex: x]];
//					[dicomFileNames addObject: [[dicomFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent: [[rois objectAtIndex: x] lastPathComponent]]];
//				}
//			}
		}
		i++;
		
	}while( size < FILESSIZE*noOfImages && i < [images count]);
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	[self connectToServer: index message:@"DICOM"];
	
	NSString	*returnString;
	
	if( [dicomFileNames count] == 0) returnString = nil;
	else if( [[NSFileManager defaultManager] fileExistsAtPath: [dicomFileNames objectAtIndex: 0]] == NO) returnString =  nil;
	else returnString = [NSString stringWithString: [dicomFileNames objectAtIndex: 0]];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return returnString;
}

- (NSString *) databaseFilePathForService:(NSString*) name
{
	NSMutableString *filePath = [NSMutableString stringWithCapacity:0];
	[filePath appendString:[[BrowserController currentBrowser] documentsDirectory]];
	[filePath appendString:@"/TEMP.noindex/"];
	[filePath appendString:[name stringByAppendingString:@".sql"]];
	return filePath;
}
@end
