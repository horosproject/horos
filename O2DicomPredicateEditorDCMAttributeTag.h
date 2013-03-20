//
//  O2DicomPredicateEditorDCMAttributeTag.h
//  Predicator
//
//  Created by Alessandro Volz on 30.01.13.
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import <OsiriX/DCMAttributeTag.h>


@interface O2DicomPredicateEditorDCMAttributeTag : DCMAttributeTag {
    NSString* _description;
    NSString* _cskey;
}

+ (id)tagWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description cskey:(NSString*)cskey;
+ (id)tagWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description;

- (NSString*)cskey;

@end