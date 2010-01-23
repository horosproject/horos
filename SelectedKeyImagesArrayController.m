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


#import "SelectedKeyImagesArrayController.h"
#import "DicomImage.h"
#import "browserController.h"
#import "Notifications.h"


@implementation SelectedKeyImagesArrayController

- (void)awakeFromNib{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addKeyImages:) name:OsirixDragMatrixImageMovedNotification object:nil];
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)addKeyImages:(NSNotification *)note{
	NSArray *keyImages = [[note userInfo] objectForKey:@"images"];
	id image;
	for (image in keyImages){
		if (![[self content] containsObject:image]){
			[self addObject:image];
			NSButtonCell *cell = [[[NSButtonCell alloc] initImageCell:[(DicomImage *)image thumbnail]] autorelease];
			[keyImageMatrix addColumnWithCells:[NSArray arrayWithObject:cell]];
			//export jpeg to reports folder for html export
			NSString *path = [[[BrowserController currentBrowser]  fixedDocumentsDirectory] stringByAppendingPathComponent:@"REPORTS"];
			NSFileManager *defaultManager = [NSFileManager defaultManager];
			BOOL isDir;
			//CHECK FOR REPORTS FOLDER
			if (!([defaultManager	fileExistsAtPath:path isDirectory:&isDir] && isDir))
				[defaultManager createDirectoryAtPath:path attributes:nil];
			//CHECK AND CREATE JPEGS SUBFOLDER
			path = [path stringByAppendingPathComponent:@"JPEGS"];
			if (!([defaultManager	fileExistsAtPath:path isDirectory:&isDir] && isDir))
				[defaultManager createDirectoryAtPath:path attributes:nil];
			//CREATE JPEG FOR HTML VIEWING
			NSString *imageUID = [NSString stringWithFormat:@"%@", [image valueForKey:@"sopInstanceUID"]];
			path = [path stringByAppendingPathComponent:imageUID];
			NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
			
			NSBitmapImageRep *rep = (NSBitmapImageRep *)[[image image]  bestRepresentationForDevice:nil] ;
			NSData *jpeg = [rep representationUsingType:NSJPEGFileType properties:dict];
			[jpeg writeToFile:path atomically :YES];
		}
	}
	[self updateMatrix];
}

- (void)remove:(id)sender
{
	[super remove:sender];
	[self updateMatrix];
}

- (void)select:(id)sender
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

	NSArray *cells = [keyImageMatrix selectedCells];
	NSCell *cell;
	for (cell in cells)
		[indexes addIndex:[cell tag]];

	[self setSelectionIndexes:(NSIndexSet *)indexes];
}

- (void)updateMatrix
{
	[super updateMatrix];
	[keyImageMatrix addColumn]; // we need one spot to be able to drag one more image
	[keyImageMatrix sizeToCells]; // take the size of the matrix with the extra column, thus the scrollbar will be well displayed
	[keyImageMatrix removeColumn:[keyImageMatrix numberOfColumns]-1]; // we don't actualy need one more button
}

@end
