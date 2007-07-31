//
//  OSICustomImageAnnotations.m
//  ImageAnnotations
//
//  Created by joris on 23/07/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "OSICustomImageAnnotations.h"


@implementation OSICustomImageAnnotations

- (id)init
{
	NSLog(@"OSICustomImageAnnotations init");
	
	self = [super init];
	if (self != nil)
	{
	}
	
	return self;
}

- (void)willSelect
{
	NSLog(@"OSICustomImageAnnotations willSelect");

	NSArray *modalities = [NSArray arrayWithObjects:NSLocalizedString(@"Default", nil), NSLocalizedString(@"CR", nil), NSLocalizedString(@"CT", nil), NSLocalizedString(@"DX", nil), NSLocalizedString(@"ES", nil), NSLocalizedString(@"MG", nil), NSLocalizedString(@"MR", nil), NSLocalizedString(@"NM", nil), NSLocalizedString(@"OT", nil),NSLocalizedString(@"PT", nil),NSLocalizedString(@"RF", nil),NSLocalizedString(@"SC", nil),NSLocalizedString(@"US", nil),NSLocalizedString(@"XA", nil), nil];
	
	[modalitiesPopUpButton removeAllItems];

	int i;
	for (i=0; i<[modalities count]; i++)
	{
		[modalitiesPopUpButton addItemWithTitle:[modalities objectAtIndex:i]];
	}
	
	layoutController = [[CIALayoutController alloc] initWithWindow:window];
	[sameAsDefaultButton setHidden:YES];
}

- (void)didSelect
{
	[layoutController setLayoutView:layoutView];
	[layoutController setPrefPane:self];
	[layoutController awakeFromNib];
}

- (void)didUnselect
{
	NSLog(@"OSICustomImageAnnotations didUnselect");
	if(layoutController)[layoutController release];
	layoutController = nil;
}

- (IBAction)addAnnotation:(id)sender;
{
	[layoutController addAnnotation:sender];
}

- (IBAction)removeAnnotation:(id)sender;
{
	[layoutController removeAnnotation:sender];
	[titleTextField setStringValue:@""];
}

- (IBAction)setTitle:(id)sender;
{
	[layoutController setTitle:sender];
}

- (IBAction)addFieldToken:(id)sender;
{
[layoutController addFieldToken:sender];

NSLog(@"makeFirstResponder");
//	NSArray *modes = [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil];
//	[[window firstResponder] setEnabled: NO];
	int m = [window makeFirstResponder: contentTokenField];
//	[contentTokenField display];
//	NSLog( @"%d", m);
	
//	[window performSelector:@selector(makeFirstResponder:)
//								 withObject:titleTextField
//								 afterDelay:0.1
//								 inModes:modes];

//	[window performSelector:@selector(makeFirstResponder:)
//								 withObject:contentTokenField
//								 afterDelay:0.1
//								 inModes:modes];

	
}

- (IBAction)validateTokenTextField:(id)sender;
{
	[layoutController validateTokenTextField:sender];
}

- (IBAction)saveAnnotationLayout:(id)sender;
{
	[layoutController saveAnnotationLayoutForModality:[[modalitiesPopUpButton selectedItem] title]];
}

- (IBAction)switchModality:(id)sender;
{
	[layoutController switchModality:sender];
	[addAnnotationButton setEnabled:[sameAsDefaultButton state]==NSOffState];
	[removeAnnotationButton setEnabled:[sameAsDefaultButton state]==NSOffState];
}

- (CIALayoutController*)layoutController; {return layoutController;}

- (NSTextField*)titleTextField; {return titleTextField;}
- (RWTokenField*)contentTokenField; {return contentTokenField;}
- (NSTokenField*)dicomNameTokenField; {return dicomNameTokenField;}
- (NSTextField*)dicomGroupTextField {return dicomGroupTextField;}
- (NSTextField*)dicomElementTextField; {return dicomElementTextField;}
- (NSTextField*)groupLabel; {return groupLabel;}
- (NSTextField*)elementLabel; {return elementLabel;}
- (NSTextField*)nameLabel; {return nameLabel;}
- (NSButton*)addCustomDICOMFieldButton; {return addCustomDICOMFieldButton;}
- (NSButton*)addDICOMFieldButton; {return addDICOMFieldButton;}
- (NSButton*)addDatabaseFieldButton; {return addDatabaseFieldButton;}
- (NSButton*)addSpecialFieldButton; {return addSpecialFieldButton;}
- (NSPopUpButton*)DICOMFieldsPopUpButton; {return DICOMFieldsPopUpButton;}
- (NSPopUpButton*)databaseFieldsPopUpButton; {return databaseFieldsPopUpButton;}
- (NSPopUpButton*)specialFieldsPopUpButton; {return specialFieldsPopUpButton;}
- (NSBox*)contentBox; {return contentBox;}
- (NSButton*)sameAsDefaultButton; {return sameAsDefaultButton;}

- (IBAction)setSameAsDefault:(id)sender;
{
	BOOL state = [sameAsDefaultButton state]==NSOnState;
	if(state) NSLog(@"NSOnState");
	else NSLog(@"NSOFFState");
	
	if(state)
	{
		//[layoutController removeAllAnnotations];
		[layoutController loadAnnotationLayoutForModality:@"Default"];
	}
	else
	{
		[layoutController loadAnnotationLayoutForModality:[[modalitiesPopUpButton selectedItem] title]];
	}
	[layoutView setEnabled:!state];
	[sameAsDefaultButton setState:state];
	[layoutView setNeedsDisplay:YES];
	
	[addAnnotationButton setEnabled:!state];
	[removeAnnotationButton setEnabled:!state];
}

@end
