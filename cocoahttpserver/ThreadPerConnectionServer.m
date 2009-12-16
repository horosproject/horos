#import "ThreadPerConnectionServer.h"
#import "AsyncSocket.h"


@implementation ThreadPerConnectionServer

- (id)init
{
	if(self = [super init])
	{
		connectionClass = [TPCConnection self];
	}
	return self;
}

@end

@implementation TPCConnection

- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer
{
	if(self = [super initWithAsyncSocket:newSocket forServer:myServer])
	{
		continueRunLoop = YES;
		[NSThread detachNewThreadSelector:@selector(setupRunLoop) toTarget:self withObject:nil];
		
		// Note: The target of the thread is automatically retained, and released when the thread exits.
	}
	return self;
}

- (void)setupRunLoop
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	myRunLoop = [NSRunLoop currentRunLoop];
	
	[self performSelectorOnMainThread:@selector(switchRunLoop) withObject:nil waitUntilDone:YES];
	
	// Note: It is assumed the main listening socket is running on the main thread.
	// If this assumption is incorrect in your case, you'll need to call switchRunLoop on correct thread.
	
	while(continueRunLoop)
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		[myRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:30]];
		[innerPool release];
	}
	
//	NSLog(@"%p: RunLoop closing down", self);
	
	[pool release];
}

- (void)switchRunLoop
{
	// The moveToRunLoop method must be called on the socket's existing runloop/thread
	[asyncSocket moveToRunLoop:myRunLoop];
	
//	NSLog(@"%p: Run loop up", self);
}

/**
 * Called when the connection dies.
**/
- (void)die
{
	continueRunLoop = NO;
	[super die];
}

@end
