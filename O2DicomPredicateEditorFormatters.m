/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "O2DicomPredicateEditorFormatters.h"

@implementation O2DicomPredicateEditorAgeStringFormatter

- (NSString*)stringForObjectValue:(id)value {
    return value;
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error {
    NSScanner* s = [NSScanner scannerWithString:string];
    
    NSInteger num = 0;
    if (![s scanInteger:&num]) {
        if (error) *error = NSLocalizedString(@"This field must contain a numeric value.", nil);
        return NO;
    }
    
    if (num > 999 || num < 0) {
        if (error) *error = NSLocalizedString(@"The numeric value in this field must be between 0 and 999.", nil);
        return NO;
    }

    NSString* cfs = nil;
    [s scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&cfs];

    unichar t = 0;
    if (cfs.length > 0)
        switch ([[cfs uppercaseString] characterAtIndex:0]) {
            case 'Y':
            case 'M':
            case 'W':
            case 'D':
                t = [cfs characterAtIndex:0];
                break;
            default:
                *error = NSLocalizedString(@"The postfixed letter must be either Y, M, W or D.", ni);
                return NO;
        }

    if (!t)
        t = 'Y';
    
    *obj = [NSString stringWithFormat:@"%03d%c", (int)num, t];
    return YES;
}

@end


@implementation O2DicomPredicateEditorMultiplicityFormatter

@synthesize monoFormatter = _monoFormatter;

- (void)dealloc {
    self.monoFormatter = nil;
    [super dealloc];
}

- (NSString*)stringForObjectValue:(id)value {
    return value;
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error {
    NSArray* parts = [string componentsSeparatedByString:@"\\"];
    for (size_t i = 0; i < parts.count; ++i) {
        NSString* part = [parts objectAtIndex:i];
        id obj = nil;
        NSString* err = nil;
        if (![self.monoFormatter getObjectValue:&obj forString:part errorDescription:&err]) {
            *error = [NSString stringWithFormat:NSLocalizedString(@"On component %d: %@", nil), i+1, err];
            return NO;
        }
    }
    
    *obj = string;
    return YES;
    
        
    NSScanner* s = [NSScanner scannerWithString:string];
    
    NSInteger num = 0;
    if (![s scanInteger:&num]) {
        if (error) *error = NSLocalizedString(@"This field must contain a numeric value.", nil);
        return NO;
    }
    
    if (num > 999 || num < 0) {
        if (error) *error = NSLocalizedString(@"The numeric value in this field must be between 0 and 999.", nil);
        return NO;
    }
    
    NSString* cfs = nil;
    [s scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&cfs];
    
    unichar t = 0;
    if (cfs.length > 0)
        switch ([[cfs uppercaseString] characterAtIndex:0]) {
            case 'Y':
            case 'M':
            case 'W':
            case 'D':
                t = [cfs characterAtIndex:0];
                break;
            default:
                *error = NSLocalizedString(@"The postfixed letter must be either Y, M, W or D.", ni);
                return NO;
        }
    
    if (!t)
        t = 'Y';
    
    *obj = [NSString stringWithFormat:@"%03d%c", (int)num, t];
    return YES;
}


@end












