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
	NSRunLoop			*myrunLoop;
	NSLock				*lock;
    NSNetServiceBrowser	*browser;
	NSMutableArray		*services;
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
	
	volatile BOOL		resolved;
}

+ (NSString*) bonjour2local: (NSString*) str;

- (id) initWithBrowserController: (BrowserController*) bC bonjourPublisher:(BonjourPublisher*) bPub;

- (void) resolveServiceWithIndex:(int)index msg: (char*) msg;

- (NSMutableArray*) services;
- (NSString *) databaseFilePathForService:(NSString*) service;


- (NSString*) getDICOMFile:(int) index forObject:(NSManagedObject*) image noOfImages: (long) noOfImages;
- (NSString*) getDatabaseFile:(int) index ;
- (void) setBonjourDatabaseValue:(int) index item:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;

- (BOOL) sendDICOMFile:(int) index path:(NSString*) ip;
- (BOOL) isBonjourDatabaseUpToDate: (int) index;

- (NSString*) getFile:(NSString*) pathFile index:(int) index;
- (BOOL) sendFile:(NSString*) pathFile index:(int) index;
- (NSDate*) getFileModification:(NSString*) pathFile index:(int) index;

- (long) BonjourServices;
- (void) buildFixedIPList;
@end
