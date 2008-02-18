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
#import <OsiriX/DCMCMoveResponseDataHandler.h>

/** \brief No longer in use */
@interface NetworkMoveDataHandler : DCMCMoveResponseDataHandler {
	id logEntry;
}

+ (id)moveDataHandler;

@end
