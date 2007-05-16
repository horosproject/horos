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

#import <Cocoa/Cocoa.h>
#import "BrowserController.h"
#import "BonjourPublisher.h"

@interface BonjourBrowser : NSObject
{
	NSLock				*lock;
    NSNetServiceBrowser	*browser;
	NSMutableArray		*services;
	NSMutableArray		*servicesDICOMListener;
    NSNetService		*serviceBeingResolved;
	int					serviceBeingResolvedIndex, BonjourServices;
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
	
	NSString			*modelVersion;
	NSString			*filePathToLoad;
	
	NSString			*FileModificationDate;
	
	NSDictionary		*dicomListener;
	
	NSDictionary		*dicomDestination;
	
	volatile BOOL		resolved;
}

+ (NSString*) bonjour2local: (NSString*) str;
+ (NSString*) uniqueLocalPath:(NSManagedObject*) image;

- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub;

- (BOOL) resolveServiceWithIndex:(int)index msg: (char*) msg;

- (NSMutableArray*) services;
- (NSDictionary*) servicesDICOMListenerForIndex: (int) i;
- (NSString *) databaseFilePathForService:(NSString*) service;


- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (int) noOfImages;
- (NSString*) getDatabaseFile:(int) index ;
- (void) setBonjourDatabaseValue:(int) index item:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;

- (BOOL) sendDICOMFile:(int) index paths:(NSArray*) ip;
- (BOOL) isBonjourDatabaseUpToDate: (int) index;

- (NSString*) getFile:(NSString*) pathFile index:(int) index;
- (BOOL) sendFile:(NSString*) pathFile index:(int) index;
- (BOOL) retrieveDICOMFilesWithSTORESCU:(int) indexFrom to:(int) indexTo paths:(NSArray*) ip;
- (NSDate*) getFileModification:(NSString*) pathFile index:(int) index;

- (int) BonjourServices;
- (void) buildFixedIPList;
- (void) buildLocalPathsList;

- (NSDictionary*) getDICOMDestinationInfo:(int) index;
@end
