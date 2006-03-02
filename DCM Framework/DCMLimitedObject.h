//
//  DCMLimitedObject.h
//  OsiriX
//
//  Created by Lance Pysher on 9/15/05.

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
//


#import <Cocoa/Cocoa.h>
#import "DCMObject.h"

@interface DCMLimitedObject : DCMObject {

}
+ (id)objectWithData:(NSData *)data lastGroup:(unsigned short)lastGroup;
+ (id)objectWithContentsOfFile:(NSString *)file lastGroup:(unsigned short)lastGroup;
+ (id)objectWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup;

- (id)initWithData:(NSData *)data lastGroup:(unsigned short)lastGroup;
- (id)initWithContentsOfFile:(NSString *)file lastGroup:(unsigned short)lastGroup;
- (id)initWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup;
- (id)initWithDataContainer:(DCMDataContainer *)data lengthToRead:(long)lengthToRead byteOffset:(long  *)byteOffset characterSet:(DCMCharacterSet *)characterSet lastGroup:(unsigned short)lastGroup;

- (long)readDataSet:(DCMDataContainer *)dicomData toGroup:(unsigned short)lastGroup byteOffset:(long *)byteOffset;

@end
