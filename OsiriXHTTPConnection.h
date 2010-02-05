#import <Cocoa/Cocoa.h>
#import "HTTPConnection.h"

extern NSString* asciiString (NSString* name);

@interface OsiriXHTTPConnection : HTTPConnection
{
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSLock *sendLock, *running;
	NSString *ipAddressString;
	NSManagedObject *currentUser;
	NSMutableDictionary *urlParameters;
	
	// POST / PUT support
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;
	NSData *postBoundary;
	NSString *POSTfilename;
}

+ (void) emailNotifications;
+ (BOOL) sendNotificationsEmailsTo: (NSArray*) users aboutStudies: (NSArray*) filteredStudies predicate: (NSString*) predicate message: (NSString*) message replyTo: (NSString*) replyto customText: (NSString*) customText;
+ (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message forUser: (NSString*) user ip: (NSString*) ip;
+ (NSString*)decodeURLString:(NSString*)aString;
+ (NSString*)iPhoneCompatibleNumericalFormat:(NSString*)aString;
+ (NSString*)unbreakableStringWithString:(NSString*)aString;
+ (NSString*)encodeURLString:(NSString*)aString;
- (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message;
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength;
- (NSArray*) addSpecificStudiesToArray: (NSArray*) array;
+ (NSArray*) addSpecificStudiesToArray: (NSArray*) array forUser: (NSManagedObject*) user predicate: (NSPredicate*) predicate;
- (NSMutableString*) setBlock: (NSString*) b visible: (BOOL) v forString: (NSMutableString*) s;
- (NSArray*)studiesForPredicate:(NSPredicate *)predicate sortBy: (NSString*) sortValue;
- (NSArray*)studiesForAlbum:(NSString *)albumName sortBy: (NSString*) sortValue;

#pragma mark JSON
- (NSString*)jsonAlbumList;
- (NSString*)jsonStudyListForStudies:(NSArray*)studies;
- (NSString*)jsonSeriesListForSeries:(NSArray*)series;
- (NSString*)jsonImageListForImages:(NSArray*)images;

@end
