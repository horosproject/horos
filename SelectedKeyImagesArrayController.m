//
//  SelectedKeyImagesArrayController.m
//  OsiriX
//
//  Created by Lance Pysher on 8/14/06.

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


#import "SelectedKeyImagesArrayController.h"
#import "DicomImage.h"
#import "browserController.h"


@implementation SelectedKeyImagesArrayController

- (void)awakeFromNib{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addKeyImages:) name:@"DragMatrixImageMoved" object:nil];
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}




- (void)addKeyImages:(NSNotification *)note{
	NSArray *keyImages = [[note userInfo] objectForKey:@"images"];
	NSEnumerator *enumerator = [keyImages objectEnumerator];
	id image;
	while (image = [enumerator nextObject]){
		if (![[self content] containsObject:image]) {
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
	
}


@end
