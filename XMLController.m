/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#include "FVTiff.h"

#import "XMLController.h"
#import "dicomFile.h"
#import <OsiriX/DCMObject.h>

static NSString* 	XMLToolbarIdentifier					= @"XML Toolbar Identifier";
static NSString*	ExportToolbarItemIdentifier				= @"Export.icns";
static NSString*	ExportTextToolbarItemIdentifier			= @"ExportText";
static NSString*	ExpandAllItemsToolbarItemIdentifier		= @"add-large";
static NSString*	CollapseAllItemsToolbarItemIdentifier	= @"minus-large";
static NSString*	SearchToolbarItemIdentifier				= @"Search";

@implementation XMLController

-(void) exportXML:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

    [panel setCanSelectHiddenExtension:NO];
    [panel setRequiredFileType:@"xml"];
    
    if( [panel runModalForDirectory:0L file:[[self window]title]] == NSFileHandlingPanelOKButton)
    {
        //[xmlData writeToFile:[panel filename] atomically:NO];
		[[xmlDocument XMLString] writeToFile:[panel filename] atomically:NO];
		 
    }
}

-(void) exportText:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

    [panel setCanSelectHiddenExtension:NO];
    [panel setRequiredFileType:@"txt"];
    
    if( [panel runModalForDirectory:0L file:[[self window]title]] == NSFileHandlingPanelOKButton)
    {
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
		[[dcmObject description] writeToFile: [panel filename] atomically:NO];
    }
}


- (void) windowDidLoad
{
    [self setupToolbar];
}

-(id) init:(NSString*) sIn :(NSString*) name{
	if (self = [super initWithWindowNibName:@"XMLViewer"]){
		[[self window] setTitle:name];
		[[self window] setFrameAutosaveName:@"XMLWindow"];
		[[self window] setDelegate:self];
		
		srcFile = [sIn retain];
		if([DicomFile isDICOMFile:srcFile])
		{
			DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
			xmlDocument = [[dcmObject xmlDocument] retain];
		}
		else if([DicomFile isFVTiffFile:srcFile])
		{
/*			NSXMLElement *rootElement = [[NSXMLElement alloc] initWithName:@"FVTiffFile"];
			xmlDocument = [[NSXMLDocument alloc] initWithRootElement:rootElement];
			[rootElement release];*/
			xmlDocument = XML_from_FVTiff(srcFile);
		}
		else
		{
			NSXMLElement *rootElement = [[NSXMLElement alloc] initWithName:@"Unsupported Meta-Data"];
			xmlDocument = [[NSXMLDocument alloc] initWithRootElement:rootElement];
			[rootElement release];
		}
		[table reloadData];
		[table expandItem:[table itemAtRow:0] expandChildren:NO];
		
		[search setRecentsAutosaveName:@"xml meta data search"];
	}
	return self;
}

- (void) dealloc
{
	[srcFile release];
	
    [xmlDcmData release];
    
    [xmlData release];
	
	[xmlDocument release];
    
	[toolbar setDelegate: 0L];
	[toolbar release];
	
    [super dealloc];
}

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

- (void)windowWillClose:(NSNotification *)notification
{
	[self release];
}


- (IBAction) setSearchString:(id) sender
{
	
	[table reloadData];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return YES;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{

        if( item == nil)
        {
            return [xmlDocument childCount];
        }
        else
        {
            return [item childCount];
        }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if( [[item valueForKey:@"name"] isEqualToString:@"value"])
		return NO;
	else
	{
		if([item childCount] == 1 && [[[[item children] objectAtIndex:0] valueForKey:@"name"] isEqualToString:@"value"])
			return NO;
		else if([item childCount] == 1 && [[[item children] objectAtIndex:0] kind] == NSXMLTextKind)
			return NO;
		else if([item childCount] == 0L)
			return NO;
		else
			return YES;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
        if( item == 0L)
        {
            return [xmlDocument childAtIndex:index];
        }
        else
        {
			return [item childAtIndex:index];
        }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	BOOL found = NO;
	
	if( [[search stringValue] isEqualToString:@""] == NO)
	{
		NSRange range = [[item XMLString] rangeOfString: [search stringValue] options: NSCaseInsensitiveSearch];
		
		if( range.location != NSNotFound) found = YES;
		
		if( found)
		{
			[cell setTextColor: [NSColor blackColor]];
			[cell setFont:[NSFont boldSystemFontOfSize:12]];
		}
		else
		{
			[cell setTextColor: [NSColor grayColor]];
			[cell setFont:[NSFont systemFontOfSize:12]];
		}
	}
	else
	{
		[cell setTextColor: [NSColor blackColor]];
		[cell setFont:[NSFont systemFontOfSize:12]];
	}
	[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString    *identifier = [tableColumn identifier];
	if ([identifier isEqualToString:@"attributeTag"]){
		NSXMLNode *attr = nil;
		if ([item kind] == NSXMLElementKind)
			attr = [item attributeForName:@"attributeTag"];
		if (attr)
			return [attr stringValue];
		else
			return nil;
	}
	else if ([identifier isEqualToString:@"stringValue"] && [item childCount] > 1)
		return nil;
//	else if ([identifier isEqualToString:@"stringValue"] && ([[item valueForKey:@"name"] isEqualToString:@"DICOMObject"] || [[item valueForKey:@"name"] isEqualToString:@"FVTiff Meta-Data"]))
//		return nil;
	else
        return [item valueForKey:identifier];
	return nil;
}


// Delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return YES;
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: XMLToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
    
//    [window makeKeyAndOrderFront:nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
    if ([itemIdent isEqual: ExportToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Export XML",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export XML",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Export these XML Data in a XML File",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportXML:)];
    }
	else if ([itemIdent isEqual: SearchToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Search", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Search", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Search", nil)];
		
		[toolbarItem setView: searchView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([searchView frame]), NSHeight([searchView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([searchView frame]), NSHeight([searchView frame]))];
    }
	else if ([itemIdent isEqual: ExportTextToolbarItemIdentifier]) {       
		[toolbarItem setLabel: NSLocalizedString(@"Export Text", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export Text", 0L)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export these XML Data in a Text File", 0L)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportText:)];
    }
	else if ([itemIdent isEqual: ExpandAllItemsToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Expand All", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Expand All Items", 0L)];
		[toolbarItem setToolTip: NSLocalizedString(@"Expand All Items", 0L)];
		[toolbarItem setImage: [NSImage imageNamed: ExpandAllItemsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(deepExpandAllItems:)];
    }
	else if ([itemIdent isEqual: CollapseAllItemsToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Collapse All", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Collapse All Items", 0L)];
		[toolbarItem setToolTip: NSLocalizedString(@"Collapse All Items", 0L)];
		[toolbarItem setImage: [NSImage imageNamed: CollapseAllItemsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(deepCollapseAllItems:)];
    }
    else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar this kind of item is not supported 
	toolbarItem = nil;
    }
     return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	ExportToolbarItemIdentifier, 
										ExportTextToolbarItemIdentifier,
										ExpandAllItemsToolbarItemIdentifier,
										CollapseAllItemsToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										SearchToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarSeparatorItemIdentifier,
										ExportToolbarItemIdentifier,
										ExportTextToolbarItemIdentifier, 
										ExpandAllItemsToolbarItemIdentifier,
										CollapseAllItemsToolbarItemIdentifier,
										SearchToolbarItemIdentifier,
										nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	
	[addedItem retain];
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
	[removedItem release];
	
/*    if (removedItem==activeSearchItem) {
	[activeSearchItem autorelease];
	activeSearchItem = nil;    
    }*/
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = YES;
 //   if ([[toolbarItem itemIdentifier] isEqual: ImportToolbarItemIdentifier]) {
	// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
//	enable = YES;
 // }	
    return enable;
}

- (void) expandAllItems: (id) sender
{
	[self expandAll:NO];
}

- (void) deepExpandAllItems: (id) sender
{
	[self expandAll:YES];
}

- (void) expandAll: (BOOL) deep
{
	int i;
	for(i=0 ; i<[table numberOfRows] ; i++)
	{
		[table expandItem:[table itemAtRow:i] expandChildren:deep];
	}
}

- (void) collapseAllItems: (id) sender
{
	[self collapseAll:NO];
}

- (void) deepCollapseAllItems: (id) sender
{
	[self collapseAll:YES];
}

- (void) collapseAll: (BOOL) deep
{
	int i;
	for(i=1 ; i<[table numberOfRows]; i++) // starting from 1, so the DICOMObject is not collapsed
	{
		[table collapseItem:[table itemAtRow:i] collapseChildren:deep];
	}
}

@end
