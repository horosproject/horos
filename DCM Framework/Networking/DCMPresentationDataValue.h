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

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import <Cocoa/Cocoa.h>


@interface DCMPresentationDataValue : NSObject {

NSData *value;
NSMutableData *pdv;
unsigned int length;
unsigned char presentationContextID;
unsigned char messageControlHeader;

}
+ (id)pdvWithParameters:(NSDictionary *)params;
+ (id) pdvWithData:(NSData *)data offset:(int)offset  length:(int)aLength;
+ (id) pdvWithData:(NSData *)data;
+ (id)pdvWithBytes:(unsigned char*)bytes  
			length:(int)aLength  
			isCommand:(BOOL)isCommand 
			isLastFragment:(BOOL)isLastFragment  
			contextID:(unsigned char)contextID;
- (id)initWithBytes:(unsigned char*)bytes  
			length:(int)aLength  
			isCommand:(BOOL)isCommand 
			isLastFragment:(BOOL)isLastFragment  
			contextID:(unsigned char)contextID;
- (id)initWithParameters:(NSDictionary *)params;
- (id)initWithData:(NSData *)data offset:(int)offset  length:(int)aLength;
- (id)initWithData:(NSData *)data;
- (NSData *)pdv;
- (NSData *)value;
- (BOOL)isLastFragment;
- (BOOL) isCommand;
- (unsigned char)presentationContextID;
@end
