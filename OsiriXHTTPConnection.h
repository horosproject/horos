#import <Cocoa/Cocoa.h>
#import "HTTPConnection.h"

extern NSString* asciiString (NSString* name);

@interface OsiriXHTTPConnection : HTTPConnection
{
	NSString *webDirectory;
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSLock *sendLock, *running;
	NSString *ipAddressString;
}

+ (NSString*)decodeURLString:(NSString*)aString;
+ (NSString*)iPhoneCompatibleNumericalFormat:(NSString*)aString;
+ (NSString*)encodeURLString:(NSString*)aString;

@end
