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




#import "ROI.h"
#import "MyNSTextView.h"
#import "ViewerController.h"


@interface ROIDefaultsWindow : NSWindowController {
//	IBOutlet NSComboBox		*name;
	NSMutableArray			*roiNames;
	
}

- (IBAction)setDefaultName:(id)sender;
- (IBAction)unsetDefaultName:(id)sender;

- (id)initWithController: (ViewerController*) c;

@end
