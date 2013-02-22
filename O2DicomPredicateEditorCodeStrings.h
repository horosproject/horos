//
//  O2DicomPredicateEditorCodeStrings.h
//  Predicator
//
//  Created by Alessandro Volz on 30.01.13.
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCMAttributeTag;

@interface O2DicomPredicateEditorCodeStrings : NSObject

+ (NSDictionary*)codeStringsForTag:(DCMAttributeTag*)tag;

@end

