//// DOServer.h

/* 

Creating a server thread
------------------------
Client call [Server connectionToServerThreadForClient:self] to create a
server thread and get back a connection to the thread. When the thread
is ready, it will call the client setServer: method. After the client
set the server, it can communicate with the server over DO.

Destroying a server thread
--------------------------
Client call [server terminate], then release the server as usual.

*/

@protocol Server

// Terminate the server thread
- (oneway void)terminate;

// Add other methods that servers must have

@end


@protocol Client

// Called from the server when its ready
- (void)setServer:(in id)server;

// Add other methods that clients must have

@end


@interface Server : NSObject <Server>
{
    BOOL running;
}

// Create new thread and get back a connection the thread
+ (NSConnection *)connectionToServerThreadForClient:(id <Client>)client;

// Private method used only by the Server class to connect to a new created thread
+ (void)connectWithPorts:(NSArray *)portArray;

- (BOOL)isRunning;

@end