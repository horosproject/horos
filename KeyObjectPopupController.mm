//
//  KeyObjectPopupController.mm
//  OsiriX
//
//  Created by Lance Pysher on 7/16/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
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

- (id)initWithViewerController:(ViewerController *)controller popup:(NSPopUpButton *)popupButton{
	if (self = [super init]) {
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

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

- (NSArray *)reports{
	return _reports;
}

- (void)setReports:(NSArray *)reports{
	[_reports release];
	_reports = [reports retain];
}

- (NSMenu *)menu{
	return _menu;
}

- (void)setMenu:(NSMenu *)menu{
	[_menu release];
	_reports = [menu retain];
}

- (void)willPopUp:(NSNotification *)note{
	//update menu
	NSLog(@"will Popup");
	NSLog(@"[_menu numberOfItems]:  %d", [_menu numberOfItems]);
	// Remove old Report Type Menu Items
	if ([_menu numberOfItems] > 4) {
		int i = [_menu numberOfItems] - 1;
		while (i >= 4)
		{
			NSLog(@"menu itemAtIndex %d: %@", i, [[_menu itemAtIndex:i] title]);
			[_menu removeItemAtIndex:i--];
		}
	}
	id study = [[[_viewerController imageView] seriesObj] valueForKey:@"study"];
	[_reports release];
	_reports = [[study valueForKey:@"keyObjects"] retain];
	// Report Type Menu Items
	NSEnumerator *enumerator = [_reports objectEnumerator];
	id report;
	[_menu addItem:[NSMenuItem separatorItem]];
	while (report = [enumerator nextObject]) {
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:[report valueForKey:@"keyObjectType"] action:@selector(useKeyObjectNote:) keyEquivalent:@""] autorelease];
		[_menu addItem:	item];
		[item setTarget:self];	
	}
}

- (IBAction)useKeyObjectNote:(id)sender{
	NSInteger index = [_popupButton indexOfSelectedItem] - 8;
	[_popupButton selectItemAtIndex:[_viewerController displayOnlyKeyImages]];
	if (index > -1) {
		NSArray *references = [[_reports objectAtIndex:index] referencedObjects];
		NSManagedObjectModel *model = [[BrowserController currentBrowser] managedObjectModel];
		NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
		NSPredicate *predicate = [NSPredicate predicateWithValue:NO];
		NSError *error = 0L;
		NSArray *imagesArray = nil;
		NSEnumerator *enumerator = [references objectEnumerator];
		id reference;
		while (reference = [enumerator nextObject]){
			predicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, [NSPredicate predicateWithFormat:@"sopInstanceUID == %@", reference], nil]]; 
		}
		[dbRequest setPredicate:predicate];
		imagesArray = [[context executeFetchRequest:dbRequest error:&error] retain];
		[[BrowserController currentBrowser] openViewerFromImages:[NSArray arrayWithObject: imagesArray] movie:NO viewer :_viewerController keyImagesOnly:NO];
	}
	NSLog(@"Load key Object reference images: %d", index);
}


@end
