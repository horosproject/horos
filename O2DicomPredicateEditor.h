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


#import <Cocoa/Cocoa.h>

@class O2DicomPredicateEditorRowTemplate;

@interface O2DicomPredicateEditor : NSPredicateEditor {
@private
    BOOL _inited, _inValidateEditing, _dbMode, _backbinding, _setting;
    O2DicomPredicateEditorRowTemplate* _dpert;
}

@property(nonatomic) BOOL dbMode, inited;

- (BOOL)matchForPredicate:(NSPredicate*)p;
- (BOOL)reallyMatchForPredicate:(NSPredicate*)predicate;

@end

