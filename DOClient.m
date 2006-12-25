// DOClient.m

#import "DOClient.h"

@implementation DOClient

- (void) connect
{
   serverObject=[NSConnection rootProxyForConnectionWithRegisteredName:@"OsiriX_DistributedObjects_OsiriX" host: nil];
}

- (void)log: (NSString*)string
{
         [serverObject log: string];
}

@end