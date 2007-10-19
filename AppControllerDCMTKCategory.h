//
//  AppControllerDCMTKCategory.h
//  OsiriX
//
//  Created by Lance Pysher on 4/2/06.

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
#import "AppController.h"


/** \brief  AppController category containing DCMTK call
*
* Certain C++ headers from DCMTK conflict with Objective C.
* Putting c++ calls in a category prevents build errors
 */

@interface AppController (AppControllerDCMTKCategory)

- (void)initDCMTK;  /**< Global registration of DCMTK toolkit*/
- (void)destroyDCMTK; /**< Degegister DCMTK*/

@end
