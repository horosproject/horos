//
//  O2DicomPredicateEditor.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 06.12.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

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

