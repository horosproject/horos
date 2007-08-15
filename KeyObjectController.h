//
//  KeyObjectController.h
//  OsiriX
//
//  Created by Lance Pysher on 6/13/06.
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

#import <Cocoa/Cocoa.h>


@interface KeyObjectController : NSWindowController {
	int _title;
	NSString *_keyDescription;
	id _study;
	NSString *_seriesUID;
}

- (id)initWithStudy:(id)study;
- (int)intTitle;
- (void)setIntTitle:(int)title;
- (NSString *) keyDescription;
- (void)setKeyDescription:(NSString *)keyDescription;

- (IBAction)closeWindow:(id)sender;

@end
