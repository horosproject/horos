//// DOClient.h

#import "DOServer.h" // for Client protocol

@interface Client : NSObject <Client>
{
    id <Server> server;
    NSConnection *serverConnection;
}
@end