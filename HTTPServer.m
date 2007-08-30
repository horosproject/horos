//
//  HTTPServer.m
//  Web2PDF Server
//
//  Created by Jürgen on 19.09.06.
//  Copyright 2006 Cultured Code.
//  License: Creative Commons Attribution 2.5 License
//           http://creativecommons.org/licenses/by/2.5/
//

#import "HTTPServer.h"
#import "HTTPConnection.h"
#import "AppController.h"
#import <sys/socket.h>   // for AF_INET, PF_INET, SOCK_STREAM, SOL_SOCKET, SO_REUSEADDR
#import <netinet/in.h>   // for IPPROTO_TCP, sockaddr_in
//#import <unistd.h>

@interface HTTPServer (PrivateMethods)
- (void)setCurrentRequest:(NSDictionary *)value;
- (void)processNextRequestIfNecessary;
@end

@implementation HTTPServer

- (id)initWithTCPPort:(unsigned)po delegate:(id)dl
{
    if( self = [super init] ) {
        port = po;
        delegate = [dl retain];
        connections = [[NSMutableArray alloc] init];
        requests = [[NSMutableArray alloc] init];
        [self setCurrentRequest:nil];
        
        NSAssert(delegate != nil, @"Please specify a delegate");
        NSAssert([delegate respondsToSelector:@selector(processURL:connection:)],
                  @"Delegate needs to implement 'processURL:connection:'");
        NSAssert([delegate respondsToSelector:@selector(stopProcessing)],
                 @"Delegate needs to implement 'stopProcessing'");

        /*socketPort = [[NSSocketPort alloc] initWithTCPPort:port];
          fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:[socketPort socket]
                                                     closeOnDealloc:YES];*/
        int fd = -1;
        CFSocketRef socket;
        socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
        if( socket ) {
            fd = CFSocketGetNative(socket);
            int yes = 1;
            setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
            
            struct sockaddr_in addr4;
            memset(&addr4, 0, sizeof(addr4));
            addr4.sin_len = sizeof(addr4);
            addr4.sin_family = AF_INET;
            addr4.sin_port = htons(port);
            addr4.sin_addr.s_addr = htonl(INADDR_ANY);
            NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
            if (kCFSocketSuccess != CFSocketSetAddress(socket, (CFDataRef)address4)) {
                NSLog(@"Could not bind to address");
            }
        } else {
            NSLog(@"No server socket");
        }
        
        fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd
                                                   closeOnDealloc:YES];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(newConnection:)
                   name:NSFileHandleConnectionAcceptedNotification
                 object:nil];
        
        [fileHandle acceptConnectionInBackgroundAndNotify];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileHandle release];
    [socketPort release];
    [currentRequest release];
    [requests release];
    [connections release];
    [delegate release];
    [super dealloc];
}


#pragma mark Managing connections

- (NSArray *)connections { return connections; }

- (void)newConnection:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *remoteFileHandle = [userInfo objectForKey:
                                            NSFileHandleNotificationFileHandleItem];
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if( errorNo ) {
        NSLog(@"NSFileHandle Error: %@", errorNo);
        return;
    }

    [fileHandle acceptConnectionInBackgroundAndNotify];

    if( remoteFileHandle ) {
        HTTPConnection *connection = [[HTTPConnection alloc] initWithFileHandle:remoteFileHandle delegate:self];
        if( connection ) {
            NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:[connections count]];
            [self willChange:NSKeyValueChangeInsertion
             valuesAtIndexes:insertedIndexes forKey:@"connections"];
            [connections addObject:connection];
            [self didChange:NSKeyValueChangeInsertion
             valuesAtIndexes:insertedIndexes forKey:@"connections"];
            [connection release];
        }
    }
}

- (void)closeConnection:(HTTPConnection *)connection;
{
    NSUInteger connectionIndex = [connections indexOfObjectIdenticalTo:connection];
    if( connectionIndex == NSNotFound ) return;

    // We remove all pending requests pertaining to connection
    NSMutableIndexSet *obsoleteRequests = [NSMutableIndexSet indexSet];
    BOOL stopProcessing = NO;
    int k;
    for( k = 0; k < [requests count]; k++) {
        NSDictionary *request = [requests objectAtIndex:k];
        if( [request objectForKey:@"connection"] == connection ) {
            if( request == [self currentRequest] ) stopProcessing = YES;
            [obsoleteRequests addIndex:k];
        }
    }
    
    NSIndexSet *connectionIndexSet = [NSIndexSet indexSetWithIndex:connectionIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:obsoleteRequests
              forKey:@"requests"];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:connectionIndexSet
              forKey:@"connections"];
    [requests removeObjectsAtIndexes:obsoleteRequests];
    [connections removeObjectsAtIndexes:connectionIndexSet];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:connectionIndexSet
             forKey:@"connections"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:obsoleteRequests
              forKey:@"requests"];
    
    if( stopProcessing ) {
        [delegate stopProcessing];
        [self setCurrentRequest:nil];
    }
    [self processNextRequestIfNecessary];
}


#pragma mark Managing requests

- (NSArray *)requests { return requests; }

- (void)newRequestWithURL:(NSURL *)url connection:(HTTPConnection *)connection
{
    //NSLog(@"requestWithURL:connection:");
    if( url == nil ) return;
    
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
        url, @"url",
        connection, @"connection",
        [NSCalendarDate date], @"date", nil];
    
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:[requests count]];
    [self willChange:NSKeyValueChangeInsertion
     valuesAtIndexes:insertedIndexes forKey:@"requests"];
    [requests addObject:request];
    [self didChange:NSKeyValueChangeInsertion
     valuesAtIndexes:insertedIndexes forKey:@"requests"];
    
    [self processNextRequestIfNecessary];
}

- (void)processNextRequestIfNecessary
{
    if( [self currentRequest] == nil && [requests count] > 0 ) {
        [self setCurrentRequest:[requests objectAtIndex:0]];
        [delegate processURL:[currentRequest objectForKey:@"url"]
                  connection:[currentRequest objectForKey:@"connection"]];
    }
}

- (void)setCurrentRequest:(NSDictionary *)value
{
    [currentRequest autorelease];
    currentRequest = [value retain];
}
- (NSDictionary *)currentRequest { return currentRequest; }


#pragma mark Sending replies

// The Content-Length header field will be automatically added
- (void)replyWithStatusCode:(int)code
                    headers:(NSDictionary *)headers
                       body:(NSData *)body
{
    CFHTTPMessageRef msg;
    msg = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
                                      code,
                                      NULL, // Use standard status description 
                                      kCFHTTPVersion1_1);

    NSEnumerator *keys = [headers keyEnumerator];
    NSString *key;
    while( key = [keys nextObject] ) {
        id value = [headers objectForKey:key];
        if( ![value isKindOfClass:[NSString class]] ) value = [value description];
        if( ![key isKindOfClass:[NSString class]] ) key = [key description];
        CFHTTPMessageSetHeaderFieldValue(msg, (CFStringRef)key, (CFStringRef)value);
    }

    if( body ) {
        NSString *length = [NSString stringWithFormat:@"%d", [body length]];
        CFHTTPMessageSetHeaderFieldValue(msg,
                                         (CFStringRef)@"Content-Length",
                                         (CFStringRef)length);
        CFHTTPMessageSetBody(msg, (CFDataRef)body);
    }
    
    CFDataRef msgData = CFHTTPMessageCopySerializedMessage(msg);
    @try {
        NSFileHandle *remoteFileHandle = [[[self currentRequest] objectForKey:@"connection"] fileHandle];
        [remoteFileHandle writeData:(NSData *)msgData];
    }
    @catch (NSException *exception) {
        NSLog(@"Error while sending response (%@): %@", [[self currentRequest] objectForKey:@"url"], [exception  reason]);
    }
    
    CFRelease(msgData);
    CFRelease(msg);
    
    // A reply indicates that the current request has been completed
    // (either successfully of by responding with an error message)
    // Hence we need to remove the current request:
    NSUInteger index = [requests indexOfObjectIdenticalTo:[self currentRequest]];
    if( index != NSNotFound ) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet
                  forKey:@"requests"];
        [requests removeObjectsAtIndexes:indexSet];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet
                 forKey:@"requests"];
    }
    [self setCurrentRequest:nil];
    [self processNextRequestIfNecessary];
}

- (void)replyWithData:(NSData *)data MIMEType:(NSString *)type
{
    NSDictionary *headers = [NSDictionary dictionaryWithObject:type forKey:@"Content-Type"];
    [self replyWithStatusCode:200 headers:headers body:data];  // 200 = 'OK'
}

- (void)replyWithStatusCode:(int)code message:(NSString *)message
{
    NSData *body = [message dataUsingEncoding:NSASCIIStringEncoding
                         allowLossyConversion:YES];
    [self replyWithStatusCode:code headers:nil body:body];
}

@end
