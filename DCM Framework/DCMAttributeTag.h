//
//  DCMAttributeTag.h
//  DCM Framework
//
//  Created by Lance Pysher on Thu Jun 03 2004.

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


@interface DCMAttributeTag : NSObject {

	int  _group;
	int _element;
	NSString *_name;
	NSString *_vr;
	NSString *_stringValue;
	

}
@property(readonly) int group;
@property(readonly) int element;
@property(readonly) NSString *stringValue;
@property(readonly) BOOL isPrivate;
@property(readonly) long longValue;
@property(readonly) NSString *vr;
@property(readonly) NSString *name;
@property(readonly) NSString *description;

+ (id)tagWithGroup:(int)group element:(int)element;
+ (id)tagWithTag:(DCMAttributeTag *)tag;
+ (id)tagWithTagString:(NSString *)tagString;
+ (id)tagWithName:(NSString *)name;
- (id)initWithGroup:(int)group element:(int)element;
- (id)initWithTag:(DCMAttributeTag *)tag;
- (id)initWithTagString:(NSString *)tagString;
- (id)initWithName:(NSString *)name;

- (NSComparisonResult)compare:(DCMAttributeTag *)tag;
- (BOOL)isEquaToTag:(DCMAttributeTag *)tag;

@end
