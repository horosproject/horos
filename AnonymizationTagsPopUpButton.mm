//
//  AnonymizationTagsPopUpButton.mm
//  OsiriX
//
//  Created by Alessandro Volz on 5/25/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "AnonymizationTagsPopUpButton.h"
#import "DCMTagDictionary.h"
#import "DCMAttributeTag.h"
#import "N2CustomTitledPopUpButtonCell.h"
#import "AnonymizationCustomTagPanelController.h"


@implementation AnonymizationTagsPopUpButton

@synthesize selectedTag;

NSInteger CompareDCMAttributeTagNames(DCMAttributeTag* lsp, DCMAttributeTag* rsp, void* context) {
	return [lsp.name caseInsensitiveCompare:rsp.name];
}

NSInteger CompareDCMAttributeTagStringValues(DCMAttributeTag* lsp, DCMAttributeTag* rsp, void* context) {
	return [lsp.stringValue caseInsensitiveCompare:rsp.stringValue];
}

+(NSMenu*)tagsMenu {
	return [self tagsMenuWithTarget:NULL action:NULL];
}

+(NSMenu*)tagsMenuWithTarget:(id)obj action:(SEL)action {
	NSMenu* tagsMenu = [[NSMenu alloc] initWithTitle:@"DCM Annotation Tags"];
	
	NSMutableArray* dcmTags = [NSMutableArray arrayWithCapacity:[[DCMTagDictionary sharedTagDictionary] count]];
	for (NSString* dcmTagsKey in [[DCMTagDictionary sharedTagDictionary] allKeys])
		[dcmTags addObject:[DCMAttributeTag tagWithTagString:dcmTagsKey]];
	
	NSMenu* tagsSortedByNameMenu = [[NSMenu alloc] initWithTitle:@""];
	NSMenuItem* tagsSortedByNameMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sorted by Name", NULL) action:NULL keyEquivalent:@""];
	[tagsSortedByNameMenuItem setSubmenu:tagsSortedByNameMenu];
	[tagsMenu addItem:tagsSortedByNameMenuItem];
	for (DCMAttributeTag* tag in [dcmTags sortedArrayUsingFunction:CompareDCMAttributeTagNames context:NULL]) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", tag.name, tag.stringValue] action:action keyEquivalent:@""];
		item.representedObject = tag;
		item.target = obj;
		[tagsSortedByNameMenu addItem:item];
		[item autorelease];
	}
	
	NSMenu* tagsSortedByStringValueMenu = [[NSMenu alloc] initWithTitle:@""];
	NSMenuItem* tagsSortedByStringValueMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sorted by Value", NULL) action:NULL keyEquivalent:@""];
	[tagsSortedByStringValueMenuItem setSubmenu:tagsSortedByStringValueMenu];
	[tagsMenu addItem:tagsSortedByStringValueMenuItem];
	for (DCMAttributeTag* tag in [dcmTags sortedArrayUsingFunction:CompareDCMAttributeTagStringValues context:NULL]) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", tag.stringValue, tag.name] action:action keyEquivalent:@""];
		item.representedObject = tag;
		item.target = obj;
		[tagsSortedByStringValueMenu addItem:item];
	}
	
	return [tagsMenu autorelease];
}

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	self.cell = [[[N2CustomTitledPopUpButtonCell alloc] init] autorelease];
	self.autoenablesItems = NO;
	self.menu = [AnonymizationTagsPopUpButton tagsMenuWithTarget:self action:@selector(tagsMenuItemSelectedAction:)];
	
	NSMenuItem* extraItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Custom...", @"Title of menu item allowing the user to specify a custom anonymization dicom tag") action:@selector(customMenuItemAction:) keyEquivalent:@""];
	extraItem.target = self;
	[self.menu addItem:extraItem];
	[extraItem release];
	
	self.selectedTag = NULL;
	
	return self;
}

-(void)customMenuItemAction:(id)sender {
	AnonymizationCustomTagPanelController* panelController = [[AnonymizationCustomTagPanelController alloc] init];
	[panelController setAttributeTag:self.selectedTag];
	[NSApp beginSheet:panelController.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(addCustomTagPanelDidEnd:returnCode:contextInfo:) contextInfo:panelController];
	[panelController.window orderFront:self];
}

-(void)addCustomTagPanelDidEnd:(NSPanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	AnonymizationCustomTagPanelController* panelController = (id)contextInfo;
	
	if (returnCode == NSRunStoppedResponse) {
		[self setSelectedTag:[panelController attributeTag]];
	}
	
	[panel close];
	[panelController release];
}

-(void)tagsMenuItemSelectedAction:(NSMenuItem*)menuItem {
	[self setSelectedTag:menuItem.representedObject];
}

-(void)setSelectedTag:(DCMAttributeTag*)tag {
	[selectedTag release];
	selectedTag = [tag retain];
	
	[self didChangeValueForKey:@"title"];

	for (NSMenuItem* item in self.itemArray) {
		item.state = NSOffState;
		if (item.hasSubmenu)
			for (NSMenuItem* subitem in item.submenu.itemArray)
				subitem.state = tag && [subitem.representedObject isEqual:tag];
	}
	
	[self.cell setDisplayedTitle: selectedTag? (selectedTag.name? [NSString stringWithFormat:@"%@ - %@", selectedTag.name, selectedTag.stringValue] : selectedTag.stringValue) : NSLocalizedString(@"Select a DICOM tag...", NULL) ];
	
	[self didChangeValueForKey:@"selectedTag"];
}

@end
