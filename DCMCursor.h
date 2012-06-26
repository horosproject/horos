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

/** \brief  Cursors */
@interface NSCursor(DCMCursor) 

+(NSCursor*)zoomCursor;
+(NSCursor*)rotateCursor;
+(NSCursor*)stackCursor;
+(NSCursor*)contrastCursor;
+(NSCursor*)rotate3DCursor;
+(NSCursor*)rotate3DCameraCursor;
+(NSCursor*)bonesRemovalCursor;
+(NSCursor*)crossCursor;
+(NSCursor*)rotateAxisCursor;

@end
