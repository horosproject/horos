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




#import <AppKit/AppKit.h>

/** \brief Window Controller for surveys */
@interface Survey : NSWindowController {

	IBOutlet		NSMatrix		*who, *where, *what, *usage, *plugin;
	IBOutlet		NSTextField		*comments;
}

-(IBAction) done : (id) sender;
-(IBAction) dontShowAgain : (id) sender;

@end
