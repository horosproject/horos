/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
    
        
//    NSScanner* s = [NSScanner scannerWithString:string];
//    
//    NSInteger num = 0;
//    if (![s scanInteger:&num]) {
//        if (error) *error = NSLocalizedString(@"This field must contain a numeric value.", nil);
//        return NO;
//    }
//    
//    if (num > 999 || num < 0) {
//        if (error) *error = NSLocalizedString(@"The numeric value in this field must be between 0 and 999.", nil);
//        return NO;
//    }
//    
//    NSString* cfs = nil;
//    [s scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&cfs];
//    
//    unichar t = 0;
//    if (cfs.length > 0)
//        switch ([[cfs uppercaseString] characterAtIndex:0]) {
//            case 'Y':
//            case 'M':
//            case 'W':
//            case 'D':
//                t = [cfs characterAtIndex:0];
//                break;
//            default:
//                *error = NSLocalizedString(@"The postfixed letter must be either Y, M, W or D.", ni);
//                return NO;
//        }
//    
//    if (!t)
//        t = 'Y';
//    
//    *obj = [NSString stringWithFormat:@"%03d%c", (int)num, t];
//    return YES;
}


@end












