//
//  O2DicomPredicateEditorDCMAttributeTag.m
//  Predicator
//
//  Created by Alessandro Volz on 30.01.13.
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import "O2DicomPredicateEditorDCMAttributeTag.h"


@implementation O2DicomPredicateEditorDCMAttributeTag

+ (id)tagWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description cskey:(NSString*)cskey {
    return [[self alloc] initWithGroup:group element:element vr:vr name:name description:description cskey:cskey];
}

+ (id)tagWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description {
    return [[self alloc] initWithGroup:group element:element vr:vr name:name description:description cskey:nil];
}

- (id)initWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description cskey:(NSString*)cskey {
    if (self = [super init]) {
        _group = group;
        _element = element;
        _vr = [vr retain];
        _name = [name retain];
        _description = [description retain];
        _cskey = [cskey retain];
    }
    
    return self;
}

- (void)dealloc {
    [_description release];
    [_cskey release];
    [super dealloc];
}

- (NSString*)description {
    if (_description)
        return _description;
    return [super description];
}

- (NSString*)cskey {
    return _cskey;
}

@end