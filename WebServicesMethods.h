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
#import "HTTPServer.h"
#import "DicomStudy.h"

extern NSString* asciiString (NSString* name);

@interface WebServicesMethods : NSObject
{
	HTTPServer	*httpServ;
	NSString *webDirectory;
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSMutableDictionary *lockArray;
	NSLock *sendLock, *running;
	volatile BOOL shouldKeepRunning;
	NSString *ipAddressString;
	NSNetService *bonjourService;
}

- (BOOL) HTTPConnectionProtected:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess;

- (NSArray*)studiesForPredicate:(NSPredicate *)predicate;
- (NSArray*)seriesForPredicate:(NSPredicate *)predicate;
- (NSArray*)studiesForAlbum:(NSString *)albumName;

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies settings: (NSDictionary*) settings;
- (NSMutableString*)htmlStudy:(DicomStudy*)study parameters:(NSDictionary*)parameters settings: (NSDictionary*) settings;
- (NSTimeInterval) startOfDay:(NSCalendarDate *)day;
- (void)dicomSend:(id)sender;
- (void)dicomSendToDo:(NSDictionary*)todo;

+ (NSString*)encodeURLString:(NSString*)aString;
+ (NSString*)decodeURLString:(NSString*)aString;
+ (NSString *)encodeCharacterEntitiesIn:(NSString *)source;
+ (NSString *)decodeCharacterEntitiesIn:(NSString *)source;
+ (NSString*)iPhoneCompatibleNumericalFormat:(NSString*)aString;
- (void)exportMovieToiPhone:(NSString *)inFile newFileName:(NSString *)outFile;
- (CFHTTPMessageRef) prepareResponse: (NSData*) data fileURL: (NSString*) fileURL contentRange:(NSString*) contentRange totalLength:(int) totalLength mess:(HTTPServerRequest*) mess parameters:(NSMutableDictionary*) parameters;
@end
