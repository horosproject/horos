/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
//
=========================================================================*/



#import <Cocoa/Cocoa.h>
/** \brief OutlineView for BrowserController */
@interface MyOutlineView : NSOutlineView
{
	NSArray	*allColumns;
}

- (void)removeAllColumns;
- (NSTableColumn *)initialColumnWithIdentifier:(id)identifier;
- (BOOL)isColumnWithIdentifierVisible:(id)identifier;
- (void)setColumnWithIdentifier:(id)identifier visible:(BOOL)visible;
- (void)setInitialState;
- (void)restoreColumnState:(NSObject *)columnState;
- (NSObject < NSCoding > *)columnState;
- (NSArray*) allColumns;

@end
