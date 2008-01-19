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

@interface WebServicesMethods : NSObject {
	HTTPServer	*httpServ;
	NSString *webDirectory;
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSMutableDictionary *lockArray;
	NSLock *sendLock;
	BOOL shouldKeepRunning;
}

- (NSArray*)studiesForPredicate:(NSPredicate *)predicate;
- (NSArray*)seriesForPredicate:(NSPredicate *)predicate;
- (NSArray*)studiesForAlbum:(NSString *)albumName;

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies;
- (NSMutableString*)htmlStudy:(DicomStudy*)study parameters:(NSDictionary*)parameters isiPhone:(BOOL)isiPhone;
- (NSTimeInterval) startOfDay:(NSCalendarDate *)day;
- (NSArray*)dicomNodes;
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
