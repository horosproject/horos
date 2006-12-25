//// DOServer.m

#import "DOServer.h"

@implementation Server

+ (NSConnection *)connectionToServerThreadForClient:(id <Client>)client
{
    NSPort *port1 = [NSPort port];
    NSPort *port2 = [NSPort port];
    
    NSConnection *connection = [NSConnection connectionWithReceivePort:port1
                                                              sendPort:port2];
    [connection setRootObject:client];
 
    // Ports switched here
    NSArray *portArray = [NSArray arrayWithObjects:port2, port1, nil];
 
    [NSThread detachNewThreadSelector:@selector(connectWithPorts:)
                             toTarget:[self class] 
                           withObject:portArray];
    return connection;
}


+ (void)connectWithPorts:(NSArray *)portArray
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    Server *instance = [[self alloc] init];

    NSConnection *connection =
        [[NSConnection alloc] initWithReceivePort:[portArray objectAtIndex:0]
                                         sendPort:[portArray objectAtIndex:1]];
    [connection setRootObject:instance];

    // Connect with the client
    [(id <Client>)[connection rootProxy] setServer:instance];

    // Run until termination
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    } while ([instance isRunning]);

    // If not invalidated, the ports leak and instance is never released
    [[connection receivePort] invalidate];
    [[connection sendPort] invalidate];

    [connection release];
    [instance release];
    [pool release];
}

- (void)terminate
{
    running = NO;
}

- (BOOL)isRunning
{
    return running;
}

@end