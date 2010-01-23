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





#import <Foundation/Foundation.h>


@interface PMDICOMStoreSCU : NSObject {

}


//-(id)initWithCalledAET:(NSString *) callingAET:(NSString *)  hostName:(NSString *) port:(int);
-(BOOL)sendFile:(NSString *)fileName :(int)compressionLevel;
@end