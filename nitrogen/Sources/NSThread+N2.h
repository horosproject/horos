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

+(NSThread*)performBlockInBackground:(void(^)())block;

extern NSString* const NSThreadNameKey;

extern NSString* const NSThreadUniqueIdKey;
-(NSString*)uniqueId;
-(void)setUniqueId:(NSString*)uniqueId;

extern NSString* const NSThreadIsCancelledKey;
//-(BOOL)isCancelled;
-(void)setIsCancelled:(BOOL)isCancelled;

-(void)enterOperation;
-(void)enterOperationIgnoringLowerLevels;
-(void)enterOperationWithRange:(CGFloat)rangeLoc :(CGFloat)rangeLen;
-(void)exitOperation;
-(void)enterSubthreadWithRange:(CGFloat)rangeLoc :(CGFloat)rangeLen __deprecated;
-(void)exitSubthread __deprecated;

extern NSString* const NSThreadSupportsCancelKey;
-(BOOL)supportsCancel;
-(void)setSupportsCancel:(BOOL)supportsCancel;

extern NSString* const NSThreadSupportsBackgroundingKey;
-(BOOL)supportsBackgrounding;
-(void)setSupportsBackgrounding:(BOOL)supportsBackgrounding;

extern NSString* const NSThreadStatusKey;
-(NSString*)status;
-(void)setStatus:(NSString*)status;

extern NSString* const NSThreadProgressKey;
-(CGFloat)progress;
-(void)setProgress:(CGFloat)progress;

extern NSString* const NSThreadProgressDetailsKey;
-(NSString*)progressDetails;
-(void)setProgressDetails:(NSString*)progressDetails;

extern NSString* const NSThreadSubthreadsAwareProgressKey;
-(CGFloat)subthreadsAwareProgress;

@end

