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
	
	// POST / PUT support
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;
	NSData *postBoundary;
	NSString *POSTfilename;
}

+ (void) emailNotifications;
+ (BOOL) sendNotificationsEmailsTo: (NSArray*) users aboutStudies: (NSArray*) filteredStudies predicate: (NSString*) predicate;
+ (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message forUser: (NSString*) user ip: (NSString*) ip;
+ (NSString*)decodeURLString:(NSString*)aString;
+ (NSString*)iPhoneCompatibleNumericalFormat:(NSString*)aString;
+ (NSString*)encodeURLString:(NSString*)aString;
- (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message;
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength;
- (NSArray*) addSpecificStudiesToArray: (NSArray*) array;
+ (NSArray*) addSpecificStudiesToArray: (NSArray*) array forUser: (NSManagedObject*) user predicate: (NSPredicate*) predicate;
@end
