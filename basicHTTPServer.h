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

#import "TCPServer.h"

@class basicHTTPConnection, HTTPServerRequest;
/** \brief HTTP server for RIS integration */

@interface basicHTTPServer : TCPServer {
@private
    Class connClass;
    NSURL *docRoot;
	
}

- (Class)connectionClass;
- (void)setConnectionClass:(Class)value;
// used to configure the subclass of basicHTTPConnection to create when  
// a new connection comes in; by default, this is basicHTTPConnection

- (NSURL *)documentRoot;
- (void)setDocumentRoot:(NSURL *)value;

@end



@interface basicHTTPServer (HTTPServerDelegateMethods)
- (void)HTTPServer:(basicHTTPServer *)serv didMakeNewConnection:(basicHTTPConnection *)conn;
// If the delegate implements this method, this is called  
// by an HTTPServer when a new connection comes in.  If the
// delegate wishes to refuse the connection, then it should
// invalidate the connection object from within this method.
@end


// This class represents each incoming client connection.
@interface basicHTTPConnection : NSObject {
@private
    id delegate;
    NSData *peerAddress;
    basicHTTPServer *server;
    NSMutableArray *requests;
    NSInputStream *istream;
    NSOutputStream *ostream;
    NSMutableData *ibuffer;
    NSMutableData *obuffer;
    BOOL isValid;
    BOOL firstResponseDone;
	NSTimer *closeTimer;
}

- (id)initWithPeerAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr forServer:(basicHTTPServer *)serv runloopMode: (NSString*) r;

- (id)delegate;
- (void)setDelegate:(id)value;

- (NSData *)peerAddress;

- (basicHTTPServer *)server;

- (HTTPServerRequest *)nextRequest;
// get the next request that needs to be responded to

- (BOOL)isValid;
- (void)invalidate;
// shut down the connection

- (void)performDefaultRequestHandling:(HTTPServerRequest *)sreq;
// perform the default handling action: GET and HEAD requests for files
// in the local file system (relative to the documentRoot of the server)

@end

@interface basicHTTPConnection (HTTPConnectionDelegateMethods)
- (void)HTTPConnection:(basicHTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess;
- (void)HTTPConnection:(basicHTTPConnection *)conn didSendResponse:(HTTPServerRequest *)mess;
// The "didReceiveRequest:" is the most interesting -- 
// tells the delegate when a new request comes in.
@end


// As NSURLRequest and NSURLResponse are not entirely suitable for use from 
// the point of view of an HTTP server, we use CFHTTPMessageRef to encapsulate
// requests and responses.  This class packages the (future) response with a
// request and other info for convenience.
@interface HTTPServerRequest : NSObject {
@private
    basicHTTPConnection *connection;
    CFHTTPMessageRef request;
    CFHTTPMessageRef response;
    NSInputStream *responseStream;
}

- (id)initWithRequest:(CFHTTPMessageRef)req connection:(basicHTTPConnection *)conn;

- (basicHTTPConnection *)connection;

- (CFHTTPMessageRef)request;

- (CFHTTPMessageRef)response;
- (void)setResponse:(CFHTTPMessageRef)value;
// The response may include a body.  As soon as the response is set, 
// the response may be written out to the network.

- (NSInputStream *)responseBodyStream;
- (void)setResponseBodyStream:(NSInputStream *)value;
// If there is to be a response body stream (when, say, a big
// file is to be returned, rather than reading the whole thing
// into memory), then it must be set on the request BEFORE the
// response [headers] itself.

@end

