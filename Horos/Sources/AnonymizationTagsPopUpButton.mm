/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

#import "Anonymization.h"
#import "AnonymizationTagsPopUpButton.h"
#import "DCMTagDictionary.h"
#import "DCMAttributeTag.h"
#import "N2CustomTitledPopUpButtonCell.h"
#import "AnonymizationCustomTagPanelController.h"
#import "AnonymizationViewController.h"
#import "AnonymizationSavePanelController.h"
#import "DicomFile.h"
#import "DCMObject.h"
#import "DCMAttribute.h"
#import "N2Debug.h"

@implementation AnonymizationTagsPopUpButton

@synthesize selectedDCMAttributeTag;

NSInteger CompareDCMAttributeTagNames(id lsp, id rsp, void* context) {
	return [[lsp name] caseInsensitiveCompare: [rsp name]];
}

NSInteger CompareDCMAttributeTagStringValues(id lsp, id rsp, void* context) {
	return [[lsp stringValue] caseInsensitiveCompare:[rsp stringValue]];
}

+(NSMenu*)tagsMenu {
	return [self tagsMenuWithTarget:NULL action:NULL];
}

+ (NSArray*) tagsForFile: (NSString*) dicomFile
{
    if(dicomFile)
    {
        if([DicomFile isDICOMFile: dicomFile])
        {
            DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: dicomFile decodingPixelData:NO];
            
            NSArray *sortedKeys = [[[dcmObject attributes] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            NSMutableArray *tags = [NSMutableArray arrayWithCapacity: [sortedKeys count]];

            for( NSString *key in sortedKeys)
            {
                DCMAttribute *attr = [[dcmObject attributes] objectForKey: key];
                if( attr)
                    [tags addObject: attr];
            }
            
            return tags;
        }
    }
	return nil;
}

+(NSMenu*)tagsMenuWithTarget:(id)obj action:(SEL)action {
	NSMenu* tagsMenu = [[[NSMenu alloc] initWithTitle:@"DCM Annotation Tags"] autorelease];
	
	NSArray *tagsOfFile = [self tagsForFile: [Anonymization templateDicomFile]];
	if( tagsOfFile)
	{
		NSMenu* tagsOfTheDICOMFile = [[[NSMenu alloc] initWithTitle:@""] autorelease];
		NSMenuItem* tagsOfTheDICOMFileMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"File(s) tags", NULL) action:NULL keyEquivalent:@""] autorelease];
		[tagsOfTheDICOMFileMenuItem setSubmenu:tagsOfTheDICOMFile];
		[tagsMenu addItem:tagsOfTheDICOMFileMenuItem];
		for (DCMAttribute* tag in tagsOfFile)
		{
			@try
			{
				NSString* valDescription = @"";
				
				if( [tag valueLength] < 100)
				{
					for( id v in [tag values])
						valDescription = [valDescription stringByAppendingFormat:@" %@", [v description]];
				}
				
				NSString *description;
				
				if( [valDescription length])
					description = [NSString stringWithFormat:@"%@ - %@ -%@", [tag attrTag].stringValue, [tag attrTag].name, valDescription];
				else
					description = [NSString stringWithFormat:@"%@ - %@", [tag attrTag].stringValue, [tag attrTag].name];
				
				NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle: description action:action keyEquivalent:@""] autorelease];
				item.representedObject = [tag attrTag];
				item.target = obj;
				[tagsOfTheDICOMFile addItem:item];
			}
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e);
			}
		}
	}
	
	NSMutableArray* dcmTags = [NSMutableArray arrayWithCapacity:[[DCMTagDictionary sharedTagDictionary] count]];
	for (NSString* dcmTagsKey in [[DCMTagDictionary sharedTagDictionary] allKeys])
		[dcmTags addObject:[DCMAttributeTag tagWithTagString:dcmTagsKey]];
	
	NSMenu* tagsSortedByNameMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem* tagsSortedByNameMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sorted by Name", NULL) action:NULL keyEquivalent:@""] autorelease];
	[tagsSortedByNameMenuItem setSubmenu:tagsSortedByNameMenu];
	[tagsMenu addItem:tagsSortedByNameMenuItem];
	for (DCMAttributeTag* tag in [dcmTags sortedArrayUsingFunction:CompareDCMAttributeTagNames context:NULL]) {
		NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", tag.name, tag.stringValue] action:action keyEquivalent:@""] autorelease];
		item.representedObject = tag;
		item.target = obj;
		[tagsSortedByNameMenu addItem:item];
	}
	
	NSMenu* tagsSortedByStringValueMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem* tagsSortedByStringValueMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sorted by Value", NULL) action:NULL keyEquivalent:@""] autorelease];
	[tagsSortedByStringValueMenuItem setSubmenu:tagsSortedByStringValueMenu];
	[tagsMenu addItem:tagsSortedByStringValueMenuItem];
	for (DCMAttributeTag* tag in [dcmTags sortedArrayUsingFunction:CompareDCMAttributeTagStringValues context:NULL])
	{
		NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", tag.stringValue, tag.name] action:action keyEquivalent:@""] autorelease];
		item.representedObject = tag;
		item.target = obj;
		[tagsSortedByStringValueMenu addItem:item];
	}
	
	return tagsMenu;
}

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	self.cell = [[[N2CustomTitledPopUpButtonCell alloc] init] autorelease];
	self.autoenablesItems = NO;
	self.menu = [AnonymizationTagsPopUpButton tagsMenuWithTarget:self action:@selector(tagsMenuItemSelectedAction:)];
	
	NSMenuItem* extraItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Custom...", @"Title of menu item allowing the user to specify a custom anonymization dicom tag") action:@selector(customMenuItemAction:) keyEquivalent:@""] autorelease];
	extraItem.target = self;
	[self.menu addItem:extraItem];
	
	self.selectedDCMAttributeTag = NULL;
	
	return self;
}

-(void)customMenuItemAction:(id)sender {
	AnonymizationCustomTagPanelController* panelController = [[AnonymizationCustomTagPanelController alloc] init];
	[panelController setAttributeTag:self.selectedDCMAttributeTag];
	[NSApp beginSheet:panelController.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(addCustomTagPanelDidEnd:returnCode:contextInfo:) contextInfo:panelController];
	[panelController.window orderFront:self];
}

-(void)addCustomTagPanelDidEnd:(NSPanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	AnonymizationCustomTagPanelController* panelController = (id)contextInfo;
	
	if (returnCode == NSRunStoppedResponse) {
		[self setSelectedDCMAttributeTag:[panelController attributeTag]];
	}
	
	[panel close];
	[panelController release];
}

-(void)tagsMenuItemSelectedAction:(NSMenuItem*)menuItem {
	[self setSelectedDCMAttributeTag:menuItem.representedObject];
}

-(void)setSelectedDCMAttributeTag:(DCMAttributeTag*)tag {
	[selectedDCMAttributeTag release];
	selectedDCMAttributeTag = [tag retain];
	
	[self didChangeValueForKey:@"title"];

	for (NSMenuItem* item in self.itemArray) {
		item.state = NSOffState;
		if (item.hasSubmenu)
			for (NSMenuItem* subitem in item.submenu.itemArray)
				subitem.state = tag && [subitem.representedObject isEqual:tag];
	}
	
	[self.cell setDisplayedTitle: selectedDCMAttributeTag? (selectedDCMAttributeTag.name? [NSString stringWithFormat:@"%@ - %@", selectedDCMAttributeTag.name, selectedDCMAttributeTag.stringValue] : selectedDCMAttributeTag.stringValue) : NSLocalizedString(@"Select a DICOM tag...", NULL) ];
	[self setNeedsDisplay:YES];
	
	[self didChangeValueForKey:@"selectedDCMAttributeTag"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AnonymizationSavePanelController *s = [[self window] windowController];
	AnonymizationViewController *v = [s anonymizationViewController];
	
	BOOL found = NO;
	int mg = [[menuItem representedObject] group], me = [[menuItem representedObject] element];
	for( DCMAttributeTag * t in [v tags])
	{
		if( t.group == mg && t.element == me)
		{
			found = YES;
			break;
		}
	}
	
	if( found)
		[menuItem setState: NSOnState];
	else
		[menuItem setState: NSOffState];
	
	return YES;
}

- (DCMAttributeTag *)selectedTag {
    return self.selectedDCMAttributeTag;
}

- (void)setSelectedTag:(DCMAttributeTag *)tag {
    [self setSelectedDCMAttributeTag:tag];
}

@end
