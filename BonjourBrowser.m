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

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

#define FILESSIZE 512*512*2

static int TIMEOUT	= 30;
#define USEZIP NO

#define OSIRIXRUNMODE NSDefaultRunLoopMode
//@"OsiriXLoopMode"

extern NSString			*documentsDirectory();
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

+ (void) waitForLock:(NSLock*) l
{
	while( [l tryLock] == NO)
	{
		if( [NSThread currentThread] == mainThread)
		{
			[[NSRunLoop currentRunLoop] runMode: OSIRIXRUNMODE beforeDate:[NSDate dateWithTimeIntervalSinceNow: 0.002]];
		}
	}
}

- (void) waitTheLock
{
	[BonjourBrowser waitForLock: lock];
	[lock unlock];
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

+ (NSString*) uniqueLocalPath:(NSManagedObject*) image
{
	NSString	*uniqueFileName = [NSString stringWithFormat:@"%@-%@-%@-%d.%@", [image valueForKeyPath:@"series.study.patientUID"], [image valueForKey:@"sopInstanceUID"], [[image valueForKey:@"path"] lastPathComponent], [[image valueForKey:@"instanceNumber"] intValue], [image valueForKey:@"extension"]];
	
	NSString	*dicomFileName = [[documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"] stringByAppendingPathComponent: [DicomFile NSreplaceBadCharacter:uniqueFileName]];

	return dicomFileName;
}



- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub{
	self = [super init];
	if (self != nil)
	{
		int i;
		
		async = [[NSLock alloc] init];
		asyncWrite = [[NSLock alloc] init];
		lock = [[NSLock alloc] init];
		browser = [[NSNetServiceBrowser alloc] init];
		services = [[NSMutableArray array] retain];
		
		[self buildFixedIPList];
		[self buildLocalPathsList];
		[[BrowserController currentBrowser] loadDICOMFromiPod];
		[self arrangeServices];
		
		interfaceOsiriX = bC;
		
		strcpy( messageToRemoteService, ".....");
		
		publisher = bPub;
		
		tempDatabaseFile = [[self databaseFilePathForService: @"incomingDatabaseFile"] retain];
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
		
		[browser setDelegate:self];
		
		[browser searchForServicesOfType:@"_osirix._tcp." inDomain:@""];
		
		[browser scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: OSIRIXRUNMODE];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
															  selector: @selector(updateFixedList:)
																  name: @"OsiriXServerArray has changed"
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
	[lock release];
	[asyncWrite release];
	[async release];
	[browser release];
	[services release];
	
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
	
	if( data)
	{
		if( [data bytes])
		{
			if ( strcmp( messageToRemoteService, "DATAB") == 0)
			{
				// we asked for a SQL file, let's write it on disc
				[dbFileName release];
				
				NSDictionary	*dict = [[self services] objectAtIndex:serviceBeingResolvedIndex];
				
				if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) dbFileName = [[self databaseFilePathForService:[[dict valueForKey:@"service"] name]] retain];
				else dbFileName = [[self databaseFilePathForService:[dict valueForKey:@"Description"]] retain];
				
				[[NSFileManager defaultManager] removeFileAtPath: dbFileName handler:0L];
				[[NSFileManager defaultManager] movePath: tempDatabaseFile toPath: dbFileName handler: 0L];
				
//				success = [data writeToFile: dbFileName atomically:YES];
			}
			else if ( strcmp( messageToRemoteService, "GETDI") == 0)
			{
				[dicomListener release];
				dicomListener = 0L;
			
				dicomListener = [NSUnarchiver unarchiveObjectWithData: data];
				if( dicomListener == 0L) dicomListener = [NSDictionary dictionary];
				
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
				
				int	pos = 0, size;
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
					while( [unzipTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
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

			if( success == NO)
			{
				NSLog(@"Bonjour transfer failed");
			}
		}
	}
	
	return success;
}

- (void)readAllTheData:(NSNotification *)note
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];		// <- Keep this line, very important to avoid memory crash (remplissage memoire) - Antoine
	BOOL				success = YES;
	NSData				*data = [[[note userInfo] objectForKey:NSFileHandleNotificationDataItem] retain];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: [note object]];
	[[note object] release];
	currentConnection = 0L;

	if( data)
	{
		success = [self processTheData: data];
	}
	
	[data release];
	
	resolved = YES;
	
	[pool release];
}

- (void) asyncWrite: (NSString*) p
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	[async lock];
		int size = currentDataPos - lastAsyncPos;
	[async unlock];
	
	[asyncWrite lock];
	FILE *f = fopen ([p UTF8String], "wb");
	fseek( f, 0L, SEEK_END);
	
	fwrite( currentDataPtr + lastAsyncPos, size, 1, f);
	
	fclose( f);
	
	[asyncWrite unlock];
	
	lastAsyncPos = currentDataPos;
	
	[pool release];
}

- (void) incomingConnection:(NSNotification *)note
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	NSData		*incomingData = [[note userInfo] objectForKey: NSFileHandleNotificationDataItem];
	int length = [incomingData length];
	
	if( incomingData && length)
	{
		[[note object] readInBackgroundAndNotifyForModes: [NSArray arrayWithObject:OSIRIXRUNMODE]];
		
		[async lock];
		if( currentDataPtr == 0L)
		{
			currentDataPtr = malloc( BonjourDatabaseIndexFileSize);
			currentDataPos = 0L;
		}
		memcpy( currentDataPtr + currentDataPos, [incomingData bytes], length);
		currentDataPos += length;
		
		[async unlock];
		
		if ( strcmp( messageToRemoteService, "DATAB") == 0)
		{
			if( currentDataPos - lastAsyncPos > 1024L * 1024L * 10L)
				[NSThread detachNewThreadSelector: @selector( asyncWrite:) toTarget: self withObject: tempDatabaseFile];
		}
		
		[currentTimeOut release];
		currentTimeOut = [[NSDate dateWithTimeIntervalSinceNow: TIMEOUT] retain];
	}
	else
	{
		if ( strcmp( messageToRemoteService, "DATAB") == 0)
			[self asyncWrite: tempDatabaseFile];
		
		BOOL success = [self processTheData: [NSData dataWithBytesNoCopy: currentDataPtr  length: currentDataPos freeWhenDone: NO]];
		
		if( currentDataPtr)
		{
			free( currentDataPtr);
			currentDataPtr = 0L;
		}
		currentDataPos = 0L;
		
		resolved = YES;
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[note object]];
		
		[[note object] release];
		currentConnection = 0L;
	}
	
	[pool release];
}


//socket.h
- (BOOL) connectToService: (struct sockaddr_in*) socketAddress
{
	BOOL succeed = NO;
	
	int socketToRemoteServer = socket(AF_INET, SOCK_STREAM, 0);
	if(socketToRemoteServer > 0)
	{
		// SEND DATA
	
		currentConnection = [[NSFileHandle alloc] initWithFileDescriptor:socketToRemoteServer closeOnDealloc:YES];
		if( currentConnection)
		{			
			 if(connect(socketToRemoteServer, (struct sockaddr *)socketAddress, sizeof(*socketAddress)) == 0)
			 {
				// transfering the type of data we need
				NSMutableData	*toTransfer = [NSMutableData dataWithCapacity:0];
				
				[toTransfer appendBytes:messageToRemoteService length: 6];
				
				if (strcmp( messageToRemoteService, "SETVA") == 0)
				{
					const char* string;
					int stringSize;
					
					string = [setValueObject UTF8String];
					stringSize  = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
					
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
						// zip the directory into a single archive file
						NSTask *zipTask   = [[NSTask alloc] init];
						[zipTask setLaunchPath:@"/usr/bin/zip"];
						[zipTask setCurrentDirectoryPath:[[filePathToLoad stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
						[zipTask setArguments:[NSArray arrayWithObjects:@"-r" , zipFileName, [filePathToLoad lastPathComponent], nil]];
						[zipTask launch];
						while( [zipTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
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
					int stringSize = NSSwapHostIntToBig( [filenameData length]);	// +1 to include the last 0 !
					
					[toTransfer appendBytes:&stringSize length: 4];
					[toTransfer appendBytes:[filenameData bytes] length: [filenameData length]];
					
					NSData	*fileData = [NSData dataWithContentsOfFile: filePathToLoad];
					int dataSize = NSSwapHostIntToBig( [fileData length]);
					[toTransfer appendBytes:&dataSize length: 4];
					[toTransfer appendData: fileData];
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
					int i, temp, noOfFiles = [paths count];
					
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
					int i, temp, noOfFiles = [paths count];
					
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
				
				[currentConnection writeData: toTransfer];
				
				if ((strcmp( messageToRemoteService, "DATAB") == 0))
				{
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingConnection:) name:NSFileHandleReadCompletionNotification object:currentConnection];
					[currentConnection readInBackgroundAndNotifyForModes: [NSArray arrayWithObject:OSIRIXRUNMODE]];
				}
				else
				{
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAllTheData:) name:NSFileHandleReadToEndOfFileCompletionNotification object: currentConnection];
					[currentConnection readToEndOfFileInBackgroundAndNotifyForModes: [NSArray arrayWithObject:OSIRIXRUNMODE]];
				}
				
				succeed = YES;
			}
			else
			{
				NSLog( @"Failed to connect to the distant computer: is there a firewall on port 8780?? is OsiriX running on this distant computer?? aborted??");
				
				[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: currentConnection];
				[currentConnection release];
				currentConnection = 0L;
			}
		}
		else
		{
			close(socketToRemoteServer);
		}
	}
	
	return succeed;
}

- (void) buildFixedIPList
{
	int			i;
	NSArray			*osirixServersArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"OSIRIXSERVERS"];
	
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

- (void) buildLocalPathsList
{
	int			i;
	NSArray			*dbArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
	
	if( dbArray == 0L) dbArray = [NSArray array];
	
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
		[dict setValue:@"localPath" forKey:@"type"];
		
		[services addObject: dict];
	}
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) updateFixedList: (NSNotification*) note
{
	int i = [[BrowserController currentBrowser] currentBonjourService];
	
	NSDictionary	*selectedDict = 0L;
	
	if( i >= 0) selectedDict = [[services objectAtIndex: i] retain];
	
	[self buildFixedIPList];
	[self buildLocalPathsList];
	[[BrowserController currentBrowser] loadDICOMFromiPod];
	
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
	
	if( host_name == 0L) return NO;
	
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

// This object is the delegate of its NSNetServiceBrowser object.
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	// remove my own sharing service
	if( aNetService == [publisher netService] || [[aNetService name] isEqualToString: [publisher serviceName]] == YES)
	{
		
	}
	else
	{
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: aNetService, @"service", @"bonjour", @"type", 0L];
		
		[services addObject:dict];
		
		// Resolve the address and port for this NSNetService
		
		[aNetService setDelegate:self];
		[aNetService scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
		[aNetService resolveWithTimeout: 5];
	}
	
	// update interface
    if(!moreComing)
	{
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
				[services removeObjectAtIndex: index];
			
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
	
	NSDictionary	*dict = 0L;
	
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
			resolved = NO;
			succeed = NO;
		}
    }
	else NSLog( @"ERROR !");
	
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
		NSRunLoop		*run = [NSRunLoop currentRunLoop];
		
		[currentTimeOut release];
		currentTimeOut = [[NSDate dateWithTimeIntervalSinceNow: TIMEOUT] retain];
		
		while( resolved == NO && [currentTimeOut timeIntervalSinceNow] >= 0)
		{
			[run runMode:OSIRIXRUNMODE beforeDate: [NSDate distantFuture]];
		}
	}
	
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
	WaitRendering	*w = 0L;
	
	connectToServerAborted = NO;
	
	if( [message isEqualToString:@"DATAB"] || [message isEqualToString:@"DBVER"]) w = waitWindow;

	NSDictionary	*dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: index], @"index", message, @"msg", 0L];
	
	int previousPercentage = 0;
	
	threadIsRunning = YES;
	[NSThread detachNewThreadSelector:@selector(resolveServiceThread:) toTarget:self withObject: dict];
	while( threadIsRunning == YES  && connectToServerAborted == NO)
	{
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.01]];
		
		if( w)
		{
			if( [w run] == NO) connectToServerAborted = YES;
			
			if( BonjourDatabaseIndexFileSize)
			{
				int currentPercentage = [currentData length];
				
				currentPercentage = currentPercentage * 10 / BonjourDatabaseIndexFileSize;
				currentPercentage *= 10;
				if( currentPercentage != previousPercentage)
				{
					previousPercentage = currentPercentage;
					[w setString: [NSString stringWithFormat:@"Downloading DB Index File (%d %%)", currentPercentage]];
				}
			}
		}
	}
	
	if( connectToServerAborted)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object: currentConnection];
		[currentConnection closeFile];
		
		while( threadIsRunning == YES)
		{
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
		}
		
		[currentConnection release];
		currentConnection = 0L;
		
		resolved = NO;
		
		return NO;
	}
	
	return resolved;
}

#pragma mark-
#pragma mark Network functions

- (NSDictionary*) getDICOMDestinationInfo:(int) index
{
	[BonjourBrowser waitForLock: lock];
	
	[dicomListener release];
	dicomListener = 0L;
	
	[self connectToServer: index message:@"GETDI"];
	
	[lock unlock];
	
	if( dicomListener == 0L)
	{
		NSLog( @"empty");
		dicomListener = [[NSDictionary dictionary] retain];
	}
	
	return dicomListener;
}

- (BOOL) isBonjourDatabaseUpToDate: (int) index
{
	if( [lock tryLock] == NO) return YES;
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

	waitWindow = [[WaitRendering alloc] init: NSLocalizedString(@"Connecting to OsiriX database...", nil)];
	[waitWindow showWindow:self];
	[waitWindow setCancel: YES];
	[waitWindow setCancelDelegate: self];
	[waitWindow start];
	
	if( [self connectToServer: index message:@"DBVER"])
	{
		if( [modelVersion isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"]] == NO)
		{
			[lock unlock];
			[waitWindow end];
			[waitWindow release];
			waitWindow = 0L;
			
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
					[waitWindow end];
					[waitWindow release];
					waitWindow = 0L;
					
					NSRunAlertPanel( NSLocalizedString( @"Bonjour Database", 0L), NSLocalizedString( @"Wrong password.", 0L), nil, nil, nil);
					serviceBeingResolvedIndex = -1;
					
					return 0L;
				}
			}
			
			BonjourDatabaseIndexFileSize = 0;
			if( [self connectToServer: index message: @"DBSIZ"] == YES)
			{
				NSLog( @"BonjourDatabaseIndexFileSize = %d Kb", BonjourDatabaseIndexFileSize/1024);
				
				// For async writing
				[[NSFileManager defaultManager] removeFileAtPath: tempDatabaseFile handler: 0L];
				lastAsyncPos = 0L;
				[asyncWrite lock];
				[asyncWrite unlock];
				[async lock];
				[async unlock];
				
				if( [self connectToServer: index message: @"DATAB"] == YES)
				{
					[self connectToServer: index message: @"VERSI"];
					
					localVersion = BonjourDatabaseVersion;
				}
				else
				{
					[dbFileName release];
					dbFileName = 0L;
				}
			}
			else
			{
				[dbFileName release];
				dbFileName = 0L;
			}
		}
		else
		{
			[dbFileName release];
			dbFileName = 0L;
		}
	}
	else
	{
		[dbFileName release];
		dbFileName = 0L;
	}
	
	[waitWindow end];
	[waitWindow release];
	waitWindow = 0L;
	
	[lock unlock];
	
	return dbFileName;
}

- (BOOL) retrieveDICOMFilesWithSTORESCU:(int) indexFrom to:(int) indexTo paths:(NSArray*) ip
{
	int i;
	
	//Do we have DICOM Node informations about the destination node?
	if( indexTo >= 0)	// indexTo == -1: this computer
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [services objectAtIndex: indexTo]];
		[dict addEntriesFromDictionary: [self getDICOMDestinationInfo: indexTo]];
		[services replaceObjectAtIndex:indexTo withObject: dict];
		
		if( [dict valueForKey: @"Port"] == 0L) return NO;
	}
	
	if( indexFrom >= 0)	// indexFrom == -1: this computer
	{
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: [services objectAtIndex: indexFrom]];
		[dict addEntriesFromDictionary: [self getDICOMDestinationInfo: indexFrom]];
		[services replaceObjectAtIndex:indexFrom withObject: dict];
		
		if( [dict valueForKey: @"Port"] == 0L) return NO;
	}
	
	[BonjourBrowser waitForLock: lock];
	
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
		
		dicomDestination = [NSDictionary dictionaryWithObjectsAndKeys: address, @"Address", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"AETitle", [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"], @"Port", @"0", @"Transfer Syntax", 0L];
		
		[dicomDestination retain];
	}
	
	[self connectToServer: indexFrom message:@"DCMSE"];
	
	[lock unlock];
	
	return YES;
}

- (BOOL) sendDICOMFile:(int) index paths:(NSArray*) ip
{
	
	for( id loopItem in ip)
	{
		if( [[NSFileManager defaultManager] fileExistsAtPath: loopItem] == NO) return NO;
	}
	
	[BonjourBrowser waitForLock: lock];
	
	[paths release];
	paths = [ip retain];
	
	[self connectToServer: index message:@"SENDD"];
	
	[lock unlock];
	
	return YES;
}

- (void) getDICOMROIFiles:(int) index roisPaths:(NSArray*) roisPaths
{
	[BonjourBrowser waitForLock: lock];
	
	[dicomFileNames release];
	dicomFileNames = [[NSMutableArray alloc] initWithCapacity: 0];
	
	[paths release];
	paths = [[NSMutableArray alloc] initWithCapacity: 0];
	
	// TRY TO LOAD MULTIPLE DICOM FILES AT SAME TIME -> better network performances
	
	NSString	*roistring = [NSString stringWithString:@"ROIs/"];
	
	for( id loopItem in roisPaths)
	{
		NSString	*local = [[documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"] stringByAppendingPathComponent: loopItem];
		 
		if( [[NSFileManager defaultManager] fileExistsAtPath: local] == NO)
		{
			[paths addObject: [roistring stringByAppendingPathComponent: loopItem]];
			[dicomFileNames addObject: [BonjourBrowser bonjour2local: loopItem]];
		}
	}
	
	if( [dicomFileNames count] > 0)
		[self connectToServer: index message:@"DICOM"];
	
	[lock unlock];
}

- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (int) noOfImages
{
	[BonjourBrowser waitForLock: lock];
	
	// Does this file already exist?
	NSString	*dicomFileName = [BonjourBrowser uniqueLocalPath: image];
	
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
	NSInteger			size = 0, i = [images indexOfObject: image];
	
	do
	{
		DicomImage	*curImage = [images objectAtIndex: i];
		
		dicomFileName = [BonjourBrowser uniqueLocalPath: curImage];
		
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
