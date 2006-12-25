//// DOServer.h

@interface DOServer:NSObject
{
         NSConnection* serverConnection;
}
- (void)log: (NSString*)string;
- (void)serve;
- (NSConnection*) createConnectionName:(NSString*)name;
@end
