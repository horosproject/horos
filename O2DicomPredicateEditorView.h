/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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


#import <Cocoa/Cocoa.h>

@class DCMAttributeTag;
@class O2DicomPredicateEditorPopUpButton;
@class O2DicomPredicateEditorDatePicker;
@class O2DicomPredicateEditor;

@interface O2DicomPredicateEditorView : NSView <NSMenuDelegate, NSTextFieldDelegate> {
    BOOL _reviewing;
    NSInteger _tagsSortKey;
    NSMutableArray* _menuItems;
    // values
    DCMAttributeTag* _tag;
    NSInteger _operator;
    NSString* _stringValue;
    NSNumber* _numberValue;
    NSDate* _dateValue;
    NSInteger _within, _codeStringTag;
    // views
    O2DicomPredicateEditorPopUpButton* _tagsPopUp;
    O2DicomPredicateEditorPopUpButton* _operatorsPopUp;
    NSTextField* _stringValueTextField;
    NSTextField* _numberValueTextField;
    O2DicomPredicateEditorDatePicker* _datePicker;
    O2DicomPredicateEditorDatePicker* _timePicker;
    O2DicomPredicateEditorDatePicker* _dateTimePicker;
    O2DicomPredicateEditorPopUpButton* _withinPopUp;
    O2DicomPredicateEditorPopUpButton* _codeStringPopUp;
    NSTextField* _isLabel;
}

@property(retain,nonatomic, readonly) NSArray* tags;
@property NSInteger tagsSortKey;

@property(retain) DCMAttributeTag* tag;
@property NSInteger operator;
@property(retain,nonatomic) NSString* stringValue;
@property(retain) NSNumber* numberValue;
@property(retain) NSDate* dateValue;
@property NSInteger within, codeStringTag;

@property(assign) NSPredicate* predicate;

- (O2DicomPredicateEditor*)editor;

- (double)matchForPredicate:(NSPredicate*)predicate;

@end
