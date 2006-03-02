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




#import <AppKit/AppKit.h>


@interface OpacityTransferView : NSView
{

	IBOutlet		NSTextField *position;
	
	NSMutableArray  *points;
	
	long			curIndex;
	
	unsigned char   red[256], green[256], blue[256];
}

-(NSMutableArray*) getPoints;
-(void) setCurrentCLUT :( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
- (IBAction) renderButton:(id) sender;

@end
