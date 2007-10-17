//
//  JPEGExif.h
//  OsiriX
//
//  Created by Antoine Rosset on 25.06.07.
//  Copyright 2007 OsiriX. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/** \brief add exif to JPEG */
@interface JPEGExif : NSObject {

}

+ (void) addExif:(NSURL*) url properties:(NSDictionary*) exifDict format: (NSString*) format;

@end
