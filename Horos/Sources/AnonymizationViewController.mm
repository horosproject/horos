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

#import "AnonymizationViewController.h"
#import "AnonymizationTemplateNamePanelController.h"
#import "AnonymizationTagsView.h"
#import "DCMAttributeTag.h"
#import "N2Operators.h"
#import "Anonymization.h"
#import "N2AdaptiveBox.h"
#import "N2TextField.h"
#import "N2CustomTitledPopUpButtonCell.h"
#import "NSUserDefaultsController+N2.h"
#import "BrowserController.h"
#include <cmath>
#include <algorithm>

@interface AnonymizationViewController ()

@property(retain,readwrite) NSMutableArray* tags;
@property(readwrite) BOOL formatsAreOk;

@end


@implementation AnonymizationViewController

@synthesize annotationsBox;
@synthesize templatesPopup;
@synthesize tagsView;
@synthesize tags;
@synthesize formatsAreOk;

+(NSArray*)basicTags {
	return [NSArray arrayWithObjects:
			[DCMAttributeTag tagWithName:@"PatientsName"],
			[DCMAttributeTag tagWithName:@"PatientsSex"],
			[DCMAttributeTag tagWithName:@"PatientID"],
			[DCMAttributeTag tagWithName:@"PatientsWeight"],
			[DCMAttributeTag tagWithName:@"PatientsAge"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialSponsorName"],
//			[DCMAttributeTag tagWithName:@"PatientsBirthDate"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialProtocolID"],
//			[DCMAttributeTag tagWithName:@"InstitutionName"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialProtocolName"],
//			[DCMAttributeTag tagWithName:@"StudyID"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialSiteID"],
//			[DCMAttributeTag tagWithName:@"StudyDate"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialSiteName"],
//			[DCMAttributeTag tagWithName:@"StudyTime"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialSubjectReadingID"],
//			[DCMAttributeTag tagWithName:@"AcquisitionDatetime"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialSubjectID"],
//			[DCMAttributeTag tagWithName:@"SeriesDate"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialTimePointID"],
//			[DCMAttributeTag tagWithName:@"SeriesTime"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialTimePointDescription"],
//			[DCMAttributeTag tagWithName:@"InstanceCreationDate"],
//			[DCMAttributeTag tagWithName:@"ClinicalTrialCoordinatingCenterName"],
//			[DCMAttributeTag tagWithName:@"InstanceCreationTime"],
//			[DCMAttributeTag tagWithName:@"PerformingPhysiciansName"],
//			[DCMAttributeTag tagWithName:@"ReferringPhysiciansName"],
//			[DCMAttributeTag tagWithName:@"PhysiciansOfRecord"],
//			[DCMAttributeTag tagWithName:@"AccessionNumber"],
			NULL];
}

-(void)refreshTemplatesList {
	[templatesPopup removeAllItems];
	NSDictionary* templates = [[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:@"anonymizeTemplate"];
	for (NSString* name in [[templates allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)])
		[templatesPopup addItemWithTitle:name];
	[templatesPopup setEnabled:templates.count>0];
}

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values
{
	self = [super initWithNibName:@"AnonymizationView" bundle:NULL];
	[self view]; // load
	
	self.tags = [NSMutableArray array];
	
	// templates
	
	NSCell* tempCell = [templatesPopup.cell retain];
	templatesPopup.cell = [[[N2CustomTitledPopUpButtonCell alloc] init] autorelease];
	[templatesPopup.cell setControlSize:tempCell.controlSize];
	[templatesPopup.cell setFont:tempCell.font];
	[tempCell release];
	templatesPopup.autoenablesItems = NO;
	templatesPopup.target = self;
	templatesPopup.action = @selector(templatesPopupAction:);
	[self refreshTemplatesList];
	
	// tags
	
	NSMutableArray* dcmTagsToShow = [shownDcmTags mutableCopy];
	
	if (!dcmTagsToShow.count)
		[dcmTagsToShow addObjectsFromArray:[AnonymizationViewController basicTags]];
	
	for (DCMAttributeTag* tag in dcmTagsToShow)
		[self addTag:tag];
	
	[dcmTagsToShow release];
	
	[self setTagsValues:values];
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];
	
	return self;
}

-(void)adaptBoxToAnnotations {
	NSSize annotationsBoxPadding = ((NSView*)annotationsBox.contentView).frame.size - tagsView.frame.size;
	NSSize idealAnnotationsBoxSize = [self.tagsView idealSize];
	
	[annotationsBox adaptContainersToIdealSize:NSMakeSize(((NSView*)annotationsBox.contentView).frame.size.width, idealAnnotationsBoxSize.height+annotationsBoxPadding.height)];	
}

-(void)addTag:(DCMAttributeTag*)tag {
	
	if( tag == nil) return;
	
	if ([self.tags containsObject:tag])
		return;
	
	[self.tags addObject:tag];
	[self.tagsView addTag:tag];
	
	[[[self.tagsView checkBoxForObject:tag] cell] addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionInitial context:self.tagsView];
	[[self.tagsView textFieldForObject:tag] addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionInitial context:self.tagsView];
	[[self.tagsView textFieldForObject:tag] addObserver:self forKeyPath:@"formatIsOk" options:NSKeyValueObservingOptionInitial context:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeTextDidChangeNotification:) name:NSControlTextDidChangeNotification object:[self.tagsView textFieldForObject:tag]];
	
	[self adaptBoxToAnnotations];
}

-(void)removeTag:(DCMAttributeTag*)tag {
	if (![self.tags containsObject:tag])
		return;

	[[[self.tagsView checkBoxForObject:tag] cell] removeObserver:self forKeyPath:@"state"];
	[[self.tagsView textFieldForObject:tag] removeObserver:self forKeyPath:@"value"];
	[[self.tagsView textFieldForObject:tag] removeObserver:self forKeyPath:@"formatIsOk"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:[self.tagsView textFieldForObject:tag]];

	[self.tags removeObject:tag];
	[self.tagsView removeTag:tag];
	
	[self adaptBoxToAnnotations];
}

-(NSString*)nameOfCurrentMatchingTemplate {
	NSArray* currentTagsValues = [self tagsValues];
	
	NSString* matchName = NULL;
	NSDictionary* templates = [[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:@"anonymizeTemplate"];
	for (NSString* name in templates) {
		NSArray* named = [Anonymization tagsValuesArrayFromDictionary:[templates objectForKey:name]];
		if ([Anonymization tagsValues:currentTagsValues isEqualTo:named])
			matchName = name;
	}
	
	return matchName;
}

-(void)updateFormatsAreOk {
	BOOL ok = YES;
	for (DCMAttributeTag* tag in tags) {
		N2TextField* textField = [tagsView textFieldForObject:tag];
		if (!textField.formatIsOk)
			ok = NO;
	}
	[self setFormatsAreOk:ok];
}

-(void)setFormatsAreOk:(BOOL)flag {
	if (flag == formatsAreOk)
		return;
	formatsAreOk = flag;
	[self didChangeValueForKey:@"formatsAreOk"];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
//	NSLog(@"observeValueForKeyPath:%@ ofObject....", keyPath);
	if (context == self.tagsView) {
		NSString* matchName = [self nameOfCurrentMatchingTemplate];
		
		if (matchName)
			[templatesPopup selectItemWithTitle:matchName];
		else [templatesPopup.selectedItem setState:0];
		
		[templatesPopup.cell setDisplayedTitle: matchName? matchName : NSLocalizedString(@"Custom", NULL) ];
		[templatesPopup setNeedsDisplay:YES];
		
		[deleteTemplateButton setEnabled: matchName != NULL];
	}
	else if ([keyPath isEqualToString:@"formatIsOk"]) {
		[self updateFormatsAreOk];
	}
}

-(void)observeTextDidChangeNotification:(NSNotification*)notif {
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];
}

//-(void)observeViewFrameDidChange:(NSNotification*)notification {
//	[self.tagsView adaptCellSizeToViewSize];
//}

-(void)dealloc {
//	NSLog(@"AnonymizationViewController dealloc");
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
	
	while (tags.count)
		[self removeTag:[tags objectAtIndex:(long)tags.count-1]];	
	
	self.tags = NULL;
	[super dealloc];
}

-(NSArray*)tagsValues {
	NSMutableArray* out = [NSMutableArray array];
	
	for (DCMAttributeTag* tag in tags)
		if ([[self.tagsView checkBoxForObject:tag] state]) {
			NSTextField* tf = [self.tagsView textFieldForObject:tag];
			
			id value = tf.stringValue.length? tf.objectValue : NULL;
			//if (value)
			//	if () // TODO: objs
			
			[out addObject:[NSArray arrayWithObjects: tag, value, NULL]];
		}
	
	return [[out copy] autorelease];
}

NSInteger CompareArraysByNameOfDCMAttributeTagAtIndexZero(id arg1, id arg2, void* context) {
	return [[[arg1 objectAtIndex:0] name] caseInsensitiveCompare:[[arg2 objectAtIndex:0] name]];
}

-(void)setTagsValues:(NSArray*)tagsValues
{
	tagsValues = [tagsValues sortedArrayUsingFunction:CompareArraysByNameOfDCMAttributeTagAtIndexZero context:NULL];
	
	NSMutableArray* zeroTags = [self.tags mutableCopy];
	
    NSDisableScreenUpdates();
    
	// this removes all previous tags
	if (tagsValues.count)
		while (self.tags.count)
			[self removeTag:[self.tags objectAtIndex:0]];
	
	for (NSArray* tagValue in tagsValues) {
		DCMAttributeTag* tag = [tagValue objectAtIndex:0];
		[self addTag:tag];
		id value = tagValue.count>1? [tagValue objectAtIndex:1] : NULL;
		NSButton* checkBox = [self.tagsView checkBoxForObject:tag];
		[checkBox setState: value? NSOnState : NSOffState];
		NSTextField* textField = [self.tagsView textFieldForObject:tag];
		
		if (!value || [value isKindOfClass:[NSString class]])
			[textField setStringValue: value? value : @""];
		else @try {
			[textField setObjectValue: value];
		} @catch (NSException* e) {
			NSLog(@"Warning: invalid value type %@ for DICOM tag %@", [value class], tag.name);
		}
		
		[zeroTags removeObject:tag];
	}
	
	for (DCMAttributeTag* tag in zeroTags) {
		[[self.tagsView checkBoxForObject:tag] setState:NSOffState];
		[[self.tagsView textFieldForObject:tag] setStringValue:@""];
	}
	
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];
    
    NSEnableScreenUpdates();
    
    /* UGLY HOTFIX / WORKAROUND UNTIL REVIEWING N2AdaptiveBox
     ------------------------------------------------------ */
    NSRect frame =  [[[BrowserController currentBrowser] window] frame];
    frame.size.width--;
    [[[BrowserController currentBrowser] window] setFrame:frame display:YES];
    frame.size.width++;
    [[[BrowserController currentBrowser] window] setFrame:frame display:YES];
    /* ---------------------------------------------------- */
    
	[zeroTags release];
}

-(void)saveTemplate:(NSArray*)templ withName:(NSString*)name {
	NSMutableDictionary* dic = [[[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:@"anonymizeTemplate"] mutableCopy];
	if (!dic) dic = [[NSMutableDictionary alloc] init];
	
	[dic setObject:[Anonymization tagsValuesDictionaryFromArray:templ] forKey:name];
	[[NSUserDefaults standardUserDefaults] setObject:dic forKey:@"anonymizeTemplate"];
	[dic release];
	
	[self refreshTemplatesList];
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];
	
}

-(void)templatesPopupAction:(NSPopUpButton*)sender {
	NSString* name = sender.selectedItem.title;
	NSDictionary* dic = [[[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:@"anonymizeTemplate"] objectForKey:name];
	NSArray* arr = [Anonymization tagsValuesArrayFromDictionary:dic];
	[self setTagsValues:arr];
	// backwards compatibility: prefs might contain NSStrings, which might not match with the corresponding objects, so if no match is found we autosave
	if (![name isEqualToString:[self nameOfCurrentMatchingTemplate]])
		[self saveTemplate:[self tagsValues] withName:name];
}

-(IBAction)saveTemplateAction:(id)sender {
	AnonymizationTemplateNamePanelController* panelController = [[AnonymizationTemplateNamePanelController alloc] initWithReplaceValues:[[[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:@"anonymizeTemplate"] allKeys]];
	[NSApp beginSheet:panelController.window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(saveTemplateNamePanelDidEnd:returnCode:contextInfo:) contextInfo:panelController];
	[panelController.window orderFront:self];
}

-(void)saveTemplateNamePanelDidEnd:(NSPanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	AnonymizationTemplateNamePanelController* panelController = (id)contextInfo;
	
	if (returnCode == NSRunStoppedResponse) {
		[self saveTemplate:[self tagsValues] withName:panelController.value];
	}
	
	[panel close];
	[panelController release];
}

-(IBAction)deleteTemplateAction:(id)sender {
	NSString* name = [templatesPopup.cell displayedTitle];
	NSMutableDictionary* dic = [[[NSUserDefaultsController sharedUserDefaultsController] dictionaryForKey:@"anonymizeTemplate"] mutableCopy];
	
	[dic removeObjectForKey:name];
	[[NSUserDefaults standardUserDefaults] setObject:dic forKey:@"anonymizeTemplate"];
	[dic release];
	
	[self refreshTemplatesList];
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];
}


@end
