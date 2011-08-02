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




#import "ROI.h"
#import "MyNSTextView.h"
#import "ViewerController.h"

/** \brief  Window Controller for ROI defaults */

@interface ROIDefaultsWindow : NSWindowController <NSComboBoxDataSource>
{
	NSArray			*roiNames;
	
}
/** Set Name and closes Window */
- (IBAction)setDefaultName:(id)sender;

/** Set default name to nil */
- (IBAction)unsetDefaultName:(id)sender;

/** Default initializer */
- (id)initWithController: (ViewerController*) c;

@end
