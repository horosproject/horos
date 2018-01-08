/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/




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
