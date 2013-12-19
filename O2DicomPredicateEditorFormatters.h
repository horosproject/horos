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
#import <Foundation/Foundation.h>

@interface O2DicomPredicateEditorAgeStringFormatter : NSFormatter

@end


@interface O2DicomPredicateEditorMultiplicityFormatter : NSFormatter {
    NSFormatter* _monoFormatter;
}

@property(retain) NSFormatter* monoFormatter;

@end