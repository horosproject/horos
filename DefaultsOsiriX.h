//
//  Defaults.h
//  OsiriX
//
//  Created by Antoine Rosset on 20.06.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DefaultsOsiriX : NSObject {

}

+ (BOOL) isHUG;
+ (BOOL) isLAVIM;
+ (NSMutableDictionary*) getDefaults;
+ (NSString*) hostName;

@end
