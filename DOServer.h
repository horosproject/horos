//// DOServer.h

@interface DOServer : NSObject
{
         NSConnection* serverConnection;
}
- (id)log: (id)string;
- (void)serve;
- (NSConnection*) createConnectionName:(NSString*)name;
- (void) bye;
@end
