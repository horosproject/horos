#import <Cocoa/Cocoa.h>
#import "HTTPConnection.h"


@interface OsiriXHTTPConnection : HTTPConnection
{
	NSString *webDirectory;
	NSMutableArray *selectedImages;
	NSMutableDictionary *selectedDICOMNode;
	NSLock *sendLock, *running;
	NSString *ipAddressString;
}

@end
