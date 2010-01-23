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

#import <Cocoa/Cocoa.h>
#import "BrowserController.h"
#import "BonjourPublisher.h"
#import "WaitRendering.h"

/** \brief  Searches and retrieves Bonjour shared databases */

@interface BonjourBrowser : NSObject
{
	NSRecursiveLock		*async, *asyncWrite;
	
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
	
	NSMutableArray		*albumStudies;
	NSString			*albumUID;
	
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
	
	void				*currentDataPtr;
	int					currentDataPos;
	
	NSDate				*currentTimeOut;
	
	// *********************** New system
	
	NSDictionary		*messageToSend;
}

+ (NSString*) bonjour2local: (NSString*) str;
+ (NSString*) uniqueLocalPath:(NSManagedObject*) image;
+ (BonjourBrowser*) currentBrowser;

- (void) waitTheLock;
- (void) setWaitDialog: (WaitRendering*) w;

- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub;

- (BOOL) resolveServiceWithIndex:(int)index msg: (char*) msg;

- (NSMutableArray*) services;
- (NSString *) databaseFilePathForService:(NSString*) service;

- (void) removeStudies: (NSArray*) studies fromAlbum: (NSManagedObject*) album bonjourIndex:(int) index;
- (void) addStudies: (NSArray*) studies toAlbum: (NSManagedObject*) album bonjourIndex:(int) index;

- (void) getDICOMROIFiles:(int) index roisPaths:(NSArray*) roisPaths;
- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (int) noOfImages;
- (NSString*) getDatabaseFile:(int) index ;
- (NSString*) getDatabaseFile:(int) index showWaitingWindow: (BOOL) showWaitingWindow;
- (void) setBonjourDatabaseValue:(int) index item:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;

- (BOOL) sendDICOMFile:(int) index paths:(NSArray*) ip;
- (BOOL) isBonjourDatabaseUpToDate: (int) index;

- (NSString*) getFile:(NSString*) pathFile index:(int) index;
- (BOOL) sendFile:(NSString*) pathFile index:(int) index;
- (BOOL) retrieveDICOMFilesWithSTORESCU:(int) indexFrom to:(int) indexTo paths:(NSArray*) ip;
- (NSDate*) getFileModification:(NSString*) pathFile index:(int) index;

- (void) deleteRoisObject: (NSManagedObject*) o paths: (NSArray*) p;

- (void) buildFixedIPList;
- (void) buildLocalPathsList;
- (void) buildDICOMDestinationsList;
- (void) arrangeServices;

- (BOOL) connectToAdress: (NSString*) address port: (int) port;

- (void) incomingConnectionProcess: (NSData*) data;

- (NSDictionary*) getDICOMDestinationInfo:(int) index;
@end
