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



/** \brief Window Controller for creating smart albums
*
* Window Controller for creating Smart albums
*/

#import <AppKit/AppKit.h>

@class O2DicomPredicateEditor;
@class DicomDatabase;
@class DicomAlbum;

@interface SmartWindowController : NSWindowController {
    DicomDatabase* _database;
    NSString* _name;
    DicomAlbum* _album;
    NSString* _predicateFormat;
    NSTextField* _nameField;
    O2DicomPredicateEditor* _editor;
    NSInteger _mode;
}

@property(retain) DicomDatabase* database;
@property(retain) DicomAlbum* album;

@property(retain) NSString* name;
@property(assign) NSPredicate* predicate;
@property(retain,nonatomic) NSString* predicateFormat;

@property NSInteger mode;

@property(readonly) BOOL nameIsValid;
@property(readonly) BOOL predicateFormatIsValid;

@property(readonly) BOOL modeIsPredicate;
@property(readonly) BOOL modeIsSQL;

@property(assign) IBOutlet NSTextField* nameField;
@property(assign) IBOutlet O2DicomPredicateEditor* editor;

- (id)initWithDatabase:(DicomDatabase*)db;

- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)helpAction:(id)sender;
- (IBAction)testAction:(id)sender;

@end
