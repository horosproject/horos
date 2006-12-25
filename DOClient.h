// DOClient.h

#import <Foundation/Foundation.h>

@interface DOClient:NSObject
{
         id serverObject;
}

- (void) connect;
- (void)log: (NSString*)string;

@end
