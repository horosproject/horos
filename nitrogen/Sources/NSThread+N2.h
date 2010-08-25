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


@interface NSThread (N2)

extern NSString* const NSThreadUniqueIdKey;
-(NSString*)uniqueId;
-(void)setUniqueId:(NSString*)uniqueId;

extern NSString* const NSThreadSupportsCancelKey;
-(BOOL)supportsCancel;
-(void)setSupportsCancel:(BOOL)supportsCancel;

extern NSString* const NSThreadIsCancelledKey;
//-(BOOL)isCancelled;
-(void)setIsCancelled:(BOOL)isCancelled;

extern NSString* const NSThreadStatusKey;
-(NSString*)status;
-(void)setStatus:(NSString*)status;

extern NSString* const NSThreadProgressKey;
-(CGFloat)progress;
-(void)setProgress:(CGFloat)progress;

-(void)enterSubthreadWithRange:(CGFloat)rangeLoc:(CGFloat)rangeLen;
-(void)exitSubthread;

extern NSString* const NSThreadSubthreadsAwareProgressKey;
-(CGFloat)subthreadsAwareProgress;
@end
