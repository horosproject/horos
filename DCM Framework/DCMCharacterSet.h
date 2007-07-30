//
//  DCMCharacterSet.h
//  OsiriX
//
//  Created by Lance Pysher on Fri Jun 11 2004.

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


@interface DCMCharacterSet : NSObject {
	NSStringEncoding encoding;
	NSString *_characterSet;
}

- (id)initWithCode:(NSString *)characterSet;
- (id)initWithCharacterSet:(DCMCharacterSet *)characterSet;
- (NSStringEncoding)encoding;
- (NSString *)characterSet;

@end
