// DOClient.h

#import <Foundation/Foundation.h>

@interface DOClient:NSObject
{
         id serverObject;
}

- (void) connect;
- (id)log: (id)string;
- (void)bye;
@end
