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

#import <Cocoa/Cocoa.h>
#import "BrowserController.h"
#import "BonjourPublisher.h"
#import "WaitRendering.h"

@interface BonjourBrowser : NSObject
{
	NSLock				*lock, *async, *asyncWrite;
	
	int					lastAsyncPos;
	NSString			*tempDatabaseFile;
		
    NSNetServiceBrowser	*browser;
	NSMutableArray		*services;
    NSNetService		*serviceBeingResolved;
	int					serviceBeingResolvedIndex;
	BrowserController	*interfaceOsiriX;
	char				messageToRemoteService[ 256];
	
	BonjourPublisher	*publisher;
	
	NSMutableArray		*dicomFileNames, *paths;
	NSString			*dbFileName, *password;
	NSString			*path;
	BOOL				isPasswordProtected, wrongPassword;
	
	NSString			*setValueObject, *setValueKey;
	id					setValueValue;
	
	NSTimeInterval		localVersion, BonjourDatabaseVersion;
	int					BonjourDatabaseIndexFileSize;
	
	NSString			*modelVersion;
	NSString			*filePathToLoad;
	
	NSString			*FileModificationDate;
	
	NSDictionary		*dicomListener;
	
	NSDictionary		*dicomDestination;
	
	volatile BOOL		resolved, connectToServerAborted;
	
	WaitRendering		*waitWindow;
	
	NSFileHandle		*currentConnection;
	NSMutableData		*currentData;
	
	void				*currentDataPtr;
	int					currentDataPos;
	
	NSDate				*currentTimeOut;
	

}

+ (NSString*) bonjour2local: (NSString*) str;
+ (NSString*) uniqueLocalPath:(NSManagedObject*) image;
- (void) waitTheLock;
- (void) setWaitDialog: (WaitRendering*) w;

- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub;

- (BOOL) resolveServiceWithIndex:(int)index msg: (char*) msg;

- (NSMutableArray*) services;
- (NSString *) databaseFilePathForService:(NSString*) service;

- (void) getDICOMROIFiles:(int) index roisPaths:(NSArray*) roisPaths;
- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (int) noOfImages;
- (NSString*) getDatabaseFile:(int) index ;
- (void) setBonjourDatabaseValue:(int) index item:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;

- (BOOL) sendDICOMFile:(int) index paths:(NSArray*) ip;
- (BOOL) isBonjourDatabaseUpToDate: (int) index;

- (NSString*) getFile:(NSString*) pathFile index:(int) index;
- (BOOL) sendFile:(NSString*) pathFile index:(int) index;
- (BOOL) retrieveDICOMFilesWithSTORESCU:(int) indexFrom to:(int) indexTo paths:(NSArray*) ip;
- (NSDate*) getFileModification:(NSString*) pathFile index:(int) index;

- (void) buildFixedIPList;
- (void) buildLocalPathsList;
- (void) arrangeServices;

- (BOOL) connectToAdress: (NSString*) address port: (int) port;

- (NSDictionary*) getDICOMDestinationInfo:(int) index;
@end
