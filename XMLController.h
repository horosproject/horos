/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/



#import <Cocoa/Cocoa.h>
#import "OSIWindowController.h"

@class ViewerController;
@class DCMObject;

/** \brief Window Controller for XML parsing */

@interface XMLController : OSIWindowController <NSToolbarDelegate, NSWindowDelegate>
{
    IBOutlet NSOutlineView		*table;
	IBOutlet NSScrollView		*tableScrollView;
    IBOutlet NSSearchField		*search;
    IBOutlet NSView				*searchView, *dicomEditingView;
	
    NSMutableArray				*xmlDcmData, *tree;
    NSData						*xmlData;    
    NSToolbar					*toolbar;	
	NSString					*srcFile;
	NSXMLDocument				*xmlDocument;
    DCMObject                   *dcmDocument;
	DicomImage                  *imObj;
	NSMutableArray				*dictionaryArray;
	
	ViewerController			*viewer;
	
	BOOL						isDICOM, dontClose;
	BOOL						editingActivated;
	BOOL						allowSelectionChange;
	
	int							editingLevel;
	
	IBOutlet NSWindow			*addWindow;
	IBOutlet NSComboBox			*dicomFieldsCombo;
	IBOutlet NSTextField		*addGroup, *addElement, *addValue;
	
	IBOutlet NSWindow			*validatorWindow;
	IBOutlet NSTextView			*validatorText;
	
	BOOL						dontListenToIndexChange;
    NSMutableArray              *modificationsToApplyArray, *modifiedFields, *modifiedValues;
}

- (BOOL) modificationsToApply;

+ (XMLController*) windowForViewer: (ViewerController*) v;

- (void) changeImageObject:(DicomImage*) image;
- (id) initWithImage:(DicomImage*) image windowName:(NSString*) name viewer:(ViewerController*) v;
- (void) setupToolbar;

- (IBAction) addDICOMField:(id) sender;
- (IBAction) setTagName:(id) sender;
- (IBAction) setGroupElement: (id) sender;
- (IBAction) executeAdd:(id) sender;
- (IBAction) validatorWebSite:(id) sender;
- (IBAction) verify:(id) sender;
- (void) reload:(id) sender;
- (void) reloadFromDCMDocument;
- (BOOL) item: (id) item containsString: (NSString*) s;
- (void) expandAllItems: (id) sender;
- (void) deepExpandAllItems: (id) sender;
- (void) expandAll: (BOOL) deep;
- (void) collapseAllItems: (id) sender;
- (void) deepCollapseAllItems: (id) sender;
- (void) collapseAll: (BOOL) deep;
- (IBAction) setSearchString:(id) sender;

- (NSString*) stringsSeparatedForNode:(NSXMLNode*) node;
- (void) traverse: (NSXMLNode*) node string:(NSMutableString*) string;

@property(readonly) NSManagedObject *imObj;
@property(readonly) ViewerController *viewer;
@property(nonatomic) BOOL editingActivated;
@end
