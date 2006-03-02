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




#import "SearchSubview.h"


@implementation SearchSubview

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[filterKeyPopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Study ID", nil), NSLocalizedString(@"Study Description", nil), NSLocalizedString(@"Referring Physician", nil),
		  NSLocalizedString(@"Performing Physician", nil), NSLocalizedString(@"Institution", nil), NSLocalizedString(@"Comments", nil),
		  NSLocalizedString(@"Study Status", nil), NSLocalizedString(@"Date Added", nil), nil]];
		
		[[dateRangePopup menu] addItem: [NSMenuItem separatorItem]];
		[dateRangePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"last hour", nil), NSLocalizedString(@"last 6 hours", nil), NSLocalizedString(@"last 12 hours", nil), nil]];
	}
	return self;
}


- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

@end
