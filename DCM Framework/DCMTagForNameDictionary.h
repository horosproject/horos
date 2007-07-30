//
//  DCMTagForNameDictionary.h
//  OsiriX
//
//  Created by Lance Pysher on Wed Jun 09 2004.

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


@interface DCMTagForNameDictionary : NSDictionary {

}

+(id)sharedTagForNameDictionary;

@end
