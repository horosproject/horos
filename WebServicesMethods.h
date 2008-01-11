//
//  WebServicesMethods.h
//  OsiriX
//
//  Created by joris on 12/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"
#import "DicomStudy.h"

@interface WebServicesMethods : NSObject {
	HTTPServer	*httpServ;
	NSString *webDirectory;
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSLock *sendLock;
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
+ (void)exportMovieToiPhone:(NSString *)inFile newFileName:(NSString *)outFile;

@end
