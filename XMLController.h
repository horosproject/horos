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
	NSManagedObject				*imObj;
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

- (void) changeImageObject:(NSManagedObject*) image;
- (id) initWithImage:(NSManagedObject*) image windowName:(NSString*) name viewer:(ViewerController*) v;
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
