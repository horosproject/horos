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


@interface N2Resizer : NSObject {
	NSView* _observed;
	NSView* _affected;
	BOOL _resizing;
}

@property(retain) NSView* observed;
@property(retain) NSView* affected;

-(id)initByObservingView:(NSView*)observed affecting:(NSView*)affected;

@end
