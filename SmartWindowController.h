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


/** \brief Window Controller for creating smart albums
*
* Window Controller for creating Smart albums
*/

#import <AppKit/AppKit.h>

@class O2DicomPredicateEditor;
@class DicomDatabase;

@interface SmartWindowController : NSWindowController {
    DicomDatabase* _database;
    NSString* _name;
    NSPredicate* _predicate;
    NSTextField* _nameField;
    O2DicomPredicateEditor* _editor;
    NSTextView* _sqlText;
    NSInteger _mode;
}

@property(retain) DicomDatabase* database;

@property(retain) NSString* name;
@property(retain,nonatomic) NSPredicate* predicate;
@property(assign) NSString* predicateFormat;

@property NSInteger mode;

@property(readonly) BOOL nameIsValid;
@property(readonly) BOOL predicateIsValid;

@property(readonly) BOOL modeIsPredicate;
@property(readonly) BOOL modeIsSQL;

@property(assign) IBOutlet NSTextField* nameField;
@property(assign) IBOutlet O2DicomPredicateEditor* editor;
@property(assign) IBOutlet NSTextView* sqlText;

- (id)initWithDatabase:(DicomDatabase*)db;

- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)helpAction:(id)sender;
- (IBAction)testAction:(id)sender;

@end
