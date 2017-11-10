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

#import "KeyObjectPopupController.h"
#import "KeyObjectReport.h"
#import "browserController.h"
#import "DicomStudy.h"
#import "DicomImageDCMTKCategory.h"
#import "ViewerController.h"
#import "DCMView.h"

@implementation KeyObjectPopupController

- (id)initWithViewerController:(ViewerController *)controller popup:(NSPopUpButton *)popupButton
{
	if (self = [super init])
	{
		//don't retain Viewer. It retains us
		_popupButton = popupButton;
		_menu = [_popupButton menu];
		_viewerController = controller;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willPopUp:) name:NSPopUpButtonCellWillPopUpNotification object:[_popupButton cell]];
	}
	return self;
}

- (void)dealloc{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_reports release];
	[super dealloc];
}

- (NSArray *)reports
{
	return _reports;
}

- (void)setReports:(NSArray *)reports{
	[_reports release];
	_reports = [reports retain];
}

- (NSMenu *)menu
{
	return _menu;
}

- (void)setMenu:(NSMenu *)menu
{
	[_menu release];
	_reports = [menu retain];
}

- (void)willPopUp:(NSNotification *)note
{
	//update menu
	// Remove old Report Type Menu Items
	if ([_menu numberOfItems] > 4)
	{
		int i = [_menu numberOfItems] - 1;
		while (i >= 4)
		{
			[_menu removeItemAtIndex:i--];
		}
	}
	series = [[_viewerController imageView] seriesObj];
	id study = [[[_viewerController imageView] seriesObj] valueForKey:@"study"];
	[_reports release];
	_reports = [[study valueForKey:@"keyObjects"] retain];
	// Report Type Menu Items
	NSEnumerator *enumerator = [_reports objectEnumerator];
	id report;
	[_menu addItem:[NSMenuItem separatorItem]];
	while (report = [enumerator nextObject])
	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:[report valueForKey:@"keyObjectType"] action:@selector(useKeyObjectNote:) keyEquivalent:@""] autorelease];
		[_menu addItem:	item];
		[item setTarget:self];	
	}
}

- (IBAction)useKeyObjectNote:(id)sender
{
	NSInteger index = [_popupButton indexOfSelectedItem] - 5;
	[_popupButton selectItemAtIndex:[_viewerController displayOnlyKeyImages]];
	if (index > -1)
	{
		NSArray *imageInSeries = [[series valueForKey:@"images"] allObjects];
		NSArray *references = [[_reports objectAtIndex:index] referencedObjects];

		NSPredicate *predicate = [NSPredicate predicateWithValue:NO];
		NSArray *imagesArray = nil;
		NSEnumerator *enumerator = [references objectEnumerator];
		id reference;
		while (reference = [enumerator nextObject])
		{
			NSPredicate	*p = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: reference]] customSelector: @selector( isEqualToSopInstanceUID:)];
			
			predicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, p, nil]]; 
		}
		NSPredicate		*notNilPredicate = [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"];
		imageInSeries = [imageInSeries filteredArrayUsingPredicate: notNilPredicate];
		imagesArray = [[imageInSeries filteredArrayUsingPredicate: predicate] retain];
		[[BrowserController currentBrowser] openViewerFromImages:[NSArray arrayWithObject: imagesArray] movie:NO viewer :_viewerController keyImagesOnly:NO];
	}
	
}


@end
