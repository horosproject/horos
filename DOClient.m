// DOClient.m

#import "DOClient.h"

@implementation DOClient

- (void) connect
{
   serverObject=[NSConnection rootProxyForConnectionWithRegisteredName:@"OsiriX_DistributedObjects_OsiriX" host: nil];
}

- (id)log: (id)string
{
	return [serverObject log: string];
}

- (void)bye
{
	[serverObject bye];
}

@end