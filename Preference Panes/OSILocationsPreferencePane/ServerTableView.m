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

#import "ServerTableView.h"
#import <OsiriXAPI/DNDArrayController.h>
#import "OSILocationsPreferencePanePref.h"

@implementation ServerTableView

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	if( !flag)
	{
		// link for external dragged URLs
		return NSDragOperationLink;
	}
	return [super draggingSourceOperationMaskForLocal:flag];
}
@end
