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


@interface NSXMLNode (N2)

+(id)elementWithName:(NSString*)name text:(NSString*)text;
+(id)elementWithName:(NSString*)name unsignedInt:(NSUInteger)value;
+(id)elementWithName:(NSString*)name bool:(BOOL)value;
-(NSXMLNode*)childNamed:(NSString*)childName;

@end
