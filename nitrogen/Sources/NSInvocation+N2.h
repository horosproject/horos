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

@interface NSInvocation (N2)

+(NSInvocation*)invocationWithSelector:(SEL)sel target:(id)target;
+(NSInvocation*)invocationWithSelector:(SEL)sel target:(id)target argument:(id)arg;
-(void)setArgumentObject:(id)o atIndex:(NSUInteger)i;
-(id)returnValue;

@end
