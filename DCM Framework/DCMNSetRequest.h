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
#import "DCMCommandMessage.h"


@interface DCMNSetRequest : DCMCommandMessage {

}
+ (id)nSetRequestWithSopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID;
		
- (id)initWithSopClassUID:(NSString *)sopClassUID  
		sopInstanceUID:(NSString *)sopInstanceUID;

@end
