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

#import <Cocoa/Cocoa.h>


@interface CIADICOMField : NSObject {
	int group, element;
	NSString *name;
}

- (id)initWithGroup:(int)g element:(int)e name:(NSString*)n;
- (int)group;
- (int)element;
- (NSString*)name;
- (NSString*)title;

@end
