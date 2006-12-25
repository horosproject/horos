// DOServer.h

#import "DOServer.h"

@implementation DOServer

- (void)log: (NSString*)string
{
	NSLog(string);
}

- (void)serve
{
	serverConnection = [self createConnectionName:@"OsiriX_DistributedObjects_OsiriX"];

	[[NSRunLoop currentRunLoop] run];
}

- (NSConnection*) createConnectionName:(NSString*)name
{
   NSConnection* newConnection=[[NSConnection alloc] init];
   if ([newConnection registerName:name])
     {
       [newConnection setRootObject:self];
     }
   else
     {
       [newConnection release];
       newConnection=nil;
     }
   return newConnection;
}

@end
