//
//  O2DicomPredicateEditorFormatters.h
//  Predicator
//
//  Created by Alessandro Volz on 08.01.13.
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface O2DicomPredicateEditorAgeStringFormatter : NSFormatter

@end


@interface O2DicomPredicateEditorMultiplicityFormatter : NSFormatter {
    NSFormatter* _monoFormatter;
}

@property(retain) NSFormatter* monoFormatter;

@end