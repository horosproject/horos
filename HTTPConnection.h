//
//  HTTPConnection.h
//  CocoaHTTPServer
//
//  Created by Jürgen Schweizer on 13.09.06.
//  Copyright 2006 Cultured Code.
//  License: Creative Commons Attribution 2.5 License
//           http://creativecommons.org/licenses/by/2.5/
//

#import <Cocoa/Cocoa.h>


@interface HTTPConnection : NSObject {
    NSFileHandle *fileHandle;
    id delegate;
    NSString *address;  // client IP address

    CFHTTPMessageRef message;
    BOOL isMessageComplete;
}

- (id)initWithFileHandle:(NSFileHandle *)fh delegate:(id)dl;
- (NSFileHandle *)fileHandle;

- (void)setAddress:(NSString *)value;
- (NSString *)address;

@end
