//// Client.m

@implementation Client

- (void)setServer:(id)anObject
{
    [anObject retain];
    [anObject setProtocolForProxy:@protocol(Server)];
    [server release];
    server = (id <Server>)anObject;

    // You may start to communicate with the server now
}

@end