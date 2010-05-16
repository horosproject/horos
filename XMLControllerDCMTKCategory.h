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
#import "XMLController.h"

/** \brief DCMTK calls for xml */

@interface XMLController (XMLControllerDCMTKCategory)

+ (int) modifyDicom:(NSArray*) params encoding: (NSStringEncoding) encoding;
- (void) prepareDictionaryArray;
- (int) getGroupAndElementForName:(NSString*) name group:(int*) gp element:(int*) el;

@end
