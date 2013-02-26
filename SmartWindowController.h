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
    NSString* _name;
    NSPredicate* _predicate;
    DicomDatabase* _database;
    NSTextField* _nameField;
    O2DicomPredicateEditor* _editor;
}

@property(retain) NSString* name;
@property(retain) NSPredicate* predicate;
@property(retain) DicomDatabase* database;

@property(readonly) BOOL nameIsValid;
@property(readonly) BOOL predicateIsValid;

@property(assign) IBOutlet NSTextField* nameField;
@property(assign) IBOutlet O2DicomPredicateEditor* editor;

- (id)initWithDatabase:(DicomDatabase*)db;

- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;

@end
