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



#import <Foundation/Foundation.h>

/** \brief Someting with network logging */
@interface DICOMLogger : NSObject {

}

- (id)initWithLog:(NSString *)info atPath:(NSString *)path;
- (void)addLog:(NSString *)info atPath:(NSString *)path;
+(DICOMLogger *)sharedLogger;
+(void)log:(NSString *)info atPath:(NSString *)path;

@end
