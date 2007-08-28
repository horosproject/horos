//
//  OSICustomImageAnnotations.m
//  ImageAnnotations
//
//  Created by joris on 23/07/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "OSICustomImageAnnotations.h"

NSComparisonResult  compareViewTags(id firstView, id secondView, void * context);
NSComparisonResult  compareViewTags(id firstView, id secondView, void * context)
{
   int firstTag;
   int secondTag;
   id v = context;
	
	if( [v boolValue])
	{
		secondTag = [firstView tag];
		firstTag = [secondView tag];
	}
	else
	{
		firstTag = [firstView tag];
		secondTag = [secondView tag];
	}

   if (firstTag == secondTag) {return NSOrderedSame;}
   else
   {
       if (firstTag < secondTag) {return NSOrderedAscending;}
       else {return NSOrderedDescending;}
   }
}

@implementation OSICustomImageAnnotations

- (void) lockView:(BOOL)locked
{
	[gray setHidden: !locked];
	[lock setHidden: !locked];
	
	[modalitiesPopUpButton setEnabled:!locked];
	[addAnnotationButton setEnabled:!locked];
	[removeAnnotationButton setEnabled:!locked];
	[sameAsDefaultButton setEnabled:!locked];
	[orientationWidgetButton setEnabled:!locked];
	
	[layoutView setEnabled:!locked];
	if(locked) [layoutView setDisabledText:@""];
	else [layoutView setDefaultDisabledText];
	
	[[self mainView] sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *))compareViewTags context: [NSNumber numberWithBool: !locked]];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    editable = YES;
	[self lockView: NO];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		editable = NO;
		[self lockView: YES];
	}
}

#pragma mark -

- (void) mainViewDidLoad
{
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.customImageAnnotations"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) editable = YES;
		else editable = NO;
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
		
		editable = YES;
	}
	[_authView updateStatus:self];
	
	if( editable)
	{
		[self lockView: NO];
	}
	else
	{
		[self lockView: YES];
	}
}

- (BOOL) editable
{
	return editable;
}

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
	
	if( editable)
	{
		[self lockView: NO];
	}
	else
	{
		[self lockView: YES];
	}
}

- (NSPreferencePaneUnselectReply)shouldUnselect;
{
	if(![layoutController checkAnnotations])
		return NSUnselectCancel;
	else
		return NSUnselectNow;
}

- (void)didUnselect
{
	NSLog(@"OSICustomImageAnnotations didUnselect");
	
	if(layoutController)
	{
		[layoutController saveAnnotationLayout];
		[layoutController release];
	}
	layoutController = nil;
}

- (IBAction)addAnnotation:(id)sender;
{

	
	[layoutController addAnnotation:sender];
	
	[addCustomDICOMFieldButton setEnabled:YES];
	[addDICOMFieldButton setEnabled:YES];
	[addDatabaseFieldButton setEnabled:YES];
	[addSpecialFieldButton setEnabled:YES];
}

- (IBAction)removeAnnotation:(id)sender;
{

	
	[layoutController removeAnnotation:sender];
	[titleTextField setStringValue:@""];
	
	[addCustomDICOMFieldButton setEnabled:NO];
	[addDICOMFieldButton setEnabled:NO];
	[addDatabaseFieldButton setEnabled:NO];
	[addSpecialFieldButton setEnabled:NO];
}

- (IBAction)setTitle:(id)sender;
{

	
	[layoutController setTitle:sender];
}

- (IBAction)addFieldToken:(id)sender;
{

	
	if(sender==addCustomDICOMFieldButton || sender==addDICOMFieldButton || sender==addDatabaseFieldButton || sender==addSpecialFieldButton)
	{
		NSWindow *win = [[self mainView] window];
		[win makeFirstResponder:contentTokenField];
	}
	[layoutController addFieldToken:sender];
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
	
	[addCustomDICOMFieldButton setEnabled:NO];
	[addDICOMFieldButton setEnabled:NO];
	[addDatabaseFieldButton setEnabled:NO];
	[addSpecialFieldButton setEnabled:NO];
}

- (CIALayoutController*)layoutController; {return layoutController;}

- (NSTextField*)titleTextField; {return titleTextField;}
- (NSTokenField*)contentTokenField; {return contentTokenField;}
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
- (NSPopUpButton*)modalitiesPopUpButton; {return modalitiesPopUpButton;}

- (IBAction)setSameAsDefault:(id)sender;
{

	
	BOOL state = [sameAsDefaultButton state]==NSOnState;

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
	
	[orientationWidgetButton setEnabled:!state];
}

- (NSButton*)orientationWidgetButton; {return orientationWidgetButton;}

- (IBAction)toggleOrientationWidget:(id)sender;
{

	
	BOOL state = [orientationWidgetButton state]==NSOnState;

	[layoutController setOrientationWidgetEnabled:state];
}

@end
