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
#import "HTTPConnection.h"
#import "WebPortalUser.h"

@class WebPortalSession, WebPortalResponse;

@interface WebPortalConnection : HTTPConnection
{
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSLock *sendLock, *running;
	WebPortalUser* currentUser;
	NSMutableDictionary *urlParameters; // GET and POST params
	
	// POST / PUT support
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;
	NSData *postBoundary;
	NSString *POSTfilename;

	WebPortalSession* session;
}

@property(retain) WebPortalSession* session;
@property(retain) WebPortalUser* currentUser;

+ (void) emailNotifications;
+ (BOOL) sendNotificationsEmailsTo: (NSArray*) users aboutStudies: (NSArray*) filteredStudies predicate: (NSString*) predicate message: (NSString*) message replyTo: (NSString*) replyto customText: (NSString*) customText;
+ (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message forUser: (NSString*) user ip: (NSString*) ip;
//+ (NSString*)decodeURLString:(NSString*)aString;
+ (NSString*)iPhoneCompatibleNumericalFormat:(NSString*)aString;
+ (NSString*)unbreakableStringWithString:(NSString*)aString;
//+ (NSString*)encodeURLString:(NSString*)aString;
- (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message;
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength;
- (NSArray*) addSpecificStudiesToArray: (NSArray*) array;
+ (NSArray*) addSpecificStudiesToArray: (NSArray*) array forUser: (NSManagedObject*) user predicate: (NSPredicate*) predicate;
//- (NSMutableString*) setBlock: (NSString*) b visible: (BOOL) v forString: (NSMutableString*) s;
- (NSArray*)studiesForPredicate:(NSPredicate *)predicate sortBy: (NSString*) sortValue;
- (NSArray*)studiesForAlbum:(NSString *)albumName sortBy: (NSString*) sortValue;

#pragma mark JSON
- (NSString*)jsonAlbumList;
- (NSString*)jsonStudyListForStudies:(NSArray*)studies;
- (NSString*)jsonSeriesListForSeries:(NSArray*)series;
- (NSString*)jsonImageListForImages:(NSArray*)images;

#pragma mark Weasis
-(NSString*)weasisJnlpWithParamsString:(NSString*)parameters;
-(NSString*)weasisXmlWithParams:(NSDictionary*)parameters;

#pragma mark Administration HTML
-(void)generate:(WebPortalResponse*)response adminIndex:(NSDictionary*)parameters;
-(void)generate:(WebPortalResponse*)response adminUser:(NSDictionary*)parameters;

@end
