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




#import <AppKit/AppKit.h>

@interface SmartWindowController : NSWindowController {
	
	IBOutlet	NSTextField		*albumNameField;
	IBOutlet	NSBox			*filterBox;
	NSMutableArray				*subviews;
	NSMutableArray				*criteria;
	BOOL						madeCriteria;
	BOOL						firstTime;

}

- (IBAction)newAlbum:(id)sender;
- (void)removeSubview:(id)sender;
- (void)addSubview:(id)sender;
- (void)drawSubviews;

- (void)updateRemoveButtons;

- (void)createCriteria;
- (NSMutableArray *)criteria;
- (NSString *)albumTitle;
- (NSCalendarDate *)dateBeforeNow:(int)value;
- (BOOL)madeCriteria;

@end
