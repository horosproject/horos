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

#import "AnonymizationViewController.h"
#import "AnonymizationTemplateNamePanelController.h"
#import "AnonymizationTagsView.h"
#import "DCMAttributeTag.h"
#import "N2Operators.h"
#import "Anonymization.h"
#import "N2AdaptiveBox.h"
#import "N2CustomTitledPopUpButtonCell.h"
#include <cmath>
#include <algorithm>

@interface AnonymizationViewController ()

@property(retain,readwrite) NSMutableArray* tags;

@end


@implementation AnonymizationViewController

@synthesize annotationsBox;
@synthesize templatesPopup;
@synthesize tagsView;
@synthesize tags;

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

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values {
	self = [super initWithNibName:@"AnonymizationView" bundle:NULL];
	self.view; // load
	
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
	
	[self.view.window setMaxSize:NSMakeSize(CGFLOAT_MAX, self.view.window.frame.size.height)];
	[self.view.window setMinSize:NSMakeSize(600, self.view.window.frame.size.height)];
}

-(void)addTag:(DCMAttributeTag*)tag {
	if ([self.tags containsObject:tag])
		return;
	
	[self.tags addObject:tag];
	[self.tagsView addTag:tag];
	
	[[[self.tagsView checkBoxForTag:tag] cell] addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionInitial context:self.tagsView];
	[[self.tagsView textFieldForTag:tag] addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionInitial context:self.tagsView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeTextDidChangeNotification:) name:NSControlTextDidChangeNotification object:[self.tagsView textFieldForTag:tag]];
	
	[self adaptBoxToAnnotations];
}

-(void)removeTag:(DCMAttributeTag*)tag {
	if (![self.tags containsObject:tag])
		return;

	[[[self.tagsView checkBoxForTag:tag] cell] removeObserver:self forKeyPath:@"state"];
	[[self.tagsView textFieldForTag:tag] removeObserver:self forKeyPath:@"value"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:[self.tagsView textFieldForTag:tag]];

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
}

-(void)observeTextDidChangeNotification:(NSNotification*)notif {
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];
}

//-(void)observeViewFrameDidChange:(NSNotification*)notification {
//	[self.tagsView adaptCellSizeToViewSize];
//}

-(void)dealloc {
	NSLog(@"AnonymizationViewController dealloc");
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
	
	while (tags.count)
		[self removeTag:[tags objectAtIndex:tags.count-1]];	
	
	self.tags = NULL;
	[super dealloc];
}

-(NSArray*)tagsValues {
	NSMutableArray* out = [NSMutableArray array];
	
	for (DCMAttributeTag* tag in tags)
		if ([[self.tagsView checkBoxForTag:tag] state]) {
			NSTextField* tf = [self.tagsView textFieldForTag:tag];
			
			id value = tf.stringValue.length? tf.objectValue : NULL;
			//if (value)
			//	if () // TODO: objs
			
			[out addObject:[NSArray arrayWithObjects: tag, value, NULL]];
		}
	
	return [[out copy] autorelease];
}

NSInteger CompareArraysByNameOfDCMAttributeTagAtIndexZero(NSArray* arg1, NSArray* arg2, void* context) {
	return [[[arg1 objectAtIndex:0] name] caseInsensitiveCompare:[[arg2 objectAtIndex:0] name]];
}

-(void)setTagsValues:(NSArray*)tagsValues
{
	tagsValues = [tagsValues sortedArrayUsingFunction:CompareArraysByNameOfDCMAttributeTagAtIndexZero context:NULL];
	
	NSMutableArray* zeroTags = [self.tags mutableCopy];
	
	// this removes all previous tags
	if (tagsValues.count)
		while (self.tags.count)
			[self removeTag:[self.tags objectAtIndex:0]];
	
	for (NSArray* tagValue in tagsValues) {
		DCMAttributeTag* tag = [tagValue objectAtIndex:0];
		[self addTag:tag];
		id value = tagValue.count>1? [tagValue objectAtIndex:1] : NULL;
		NSButton* checkBox = [self.tagsView checkBoxForTag:tag];
		[checkBox setState: value? NSOnState : NSOffState];
		NSTextField* textField = [self.tagsView textFieldForTag:tag];
		
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
		[[self.tagsView checkBoxForTag:tag] setState:NSOffState];
		[[self.tagsView textFieldForTag:tag] setStringValue:@""];
	}
	
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:self.tagsView];

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
	if (![name isEqual:[self nameOfCurrentMatchingTemplate]])
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
