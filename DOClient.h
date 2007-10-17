// DOClient.h

#import <Foundation/Foundation.h>


/** \brief Distributed object client */
@interface DOClient:NSObject
{
         id serverObject;
}

- (void) connect;
- (id)log: (id)string;
- (void)bye;
@end
