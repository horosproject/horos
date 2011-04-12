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


#import "NSThread+N2.h"
//#import "NSException+N2.h"

@implementation NSThread (N2)

NSString* const NSThreadUniqueIdKey = @"uniqueId";

-(NSString*)uniqueId
{
	NSString *uniqueId = nil;
	
	if( self.isFinished)
		return nil;
	
	if( self.isCancelled)
		return nil;
	
	@synchronized (self.threadDictionary)
	{
		uniqueId = [self.threadDictionary objectForKey:NSThreadUniqueIdKey];
	}
	
	return uniqueId;
}

-(void)setUniqueId:(NSString*)uniqueId
{
	if( self.isFinished)
		return;
	
	if( self.isCancelled)
		return;
	
	if ([uniqueId isEqual:self.uniqueId])
		return;
	
	@synchronized (self.threadDictionary)
	{
		[self willChangeValueForKey:NSThreadUniqueIdKey];
		[self.threadDictionary setObject:uniqueId forKey:NSThreadUniqueIdKey];
		[self didChangeValueForKey:NSThreadUniqueIdKey];
	}
}

NSString* const NSThreadSupportsCancelKey = @"supportsCancel";

-(BOOL)supportsCancel
{
	if( self.isFinished)
		return NO;
	
	if( self.isCancelled)
		return NO;
	
	NSNumber* supportsCancel = nil;
	@synchronized (self.threadDictionary)
	{
		supportsCancel = [self.threadDictionary objectForKey:NSThreadSupportsCancelKey];
	}
	return supportsCancel? [supportsCancel boolValue] : NO;
}

-(void)setSupportsCancel:(BOOL)supportsCancel
{
	if( self.isFinished)
		return;
	
	if( self.isCancelled)
		return;
	
	if (supportsCancel == self.supportsCancel) return;
	
	@synchronized (self.threadDictionary)
	{
		[self willChangeValueForKey:NSThreadSupportsCancelKey];
		[self.threadDictionary setObject:[NSNumber numberWithBool:supportsCancel] forKey:NSThreadSupportsCancelKey];
		[self didChangeValueForKey:NSThreadSupportsCancelKey];
	}
}

NSString* const NSThreadIsCancelledKey = @"isCancelled";

-(void)setIsCancelled:(BOOL)isCancelled
{
	if( self.isFinished)
		return;
	
	if( self.isCancelled)
		return;
	
	if (isCancelled == self.isCancelled) return;
	
	@synchronized (self.threadDictionary)
	{
		[self willChangeValueForKey:NSThreadIsCancelledKey];
		[self cancel];
		[self didChangeValueForKey:NSThreadIsCancelledKey];
	}
}

NSString* const NSThreadStatusKey = @"status";

-(NSMutableArray*)statusArray {
	NSMutableArray* a = nil;
	
	@synchronized (self.threadDictionary) {
		a = [self.threadDictionary objectForKey:NSThreadStatusKey];
		if (!a) {
			a = [NSMutableArray array];
			[self.threadDictionary setObject:a forKey:NSThreadStatusKey];
		}
	}
	
	return a;
}

-(NSString*)status
{
	if( self.isFinished)
		return nil;
	if( self.isCancelled)
		return nil;
	
	NSString *s = nil;
	
	@synchronized (self.threadDictionary)
	{
		if (self.statusArray.count)
			s = [[self.statusArray.lastObject copy] autorelease];
	}
	
	return s;
}

-(void)setStatus:(NSString*)status
{
	if( self.isFinished)
		return;
	if( self.isCancelled)
		return;
	
	if( [status isEqual:self.status]) return;
	
	[self willChangeValueForKey:NSThreadStatusKey];
	
	@synchronized (self.threadDictionary)
	{
		if (self.statusArray.count) {
			if (status == nil) status = @"";
			[self.statusArray replaceObjectAtIndex:self.statusArray.count-1 withObject:[[status copy] autorelease]];
		} else [self pushStatus:status];
	}
	
	[self didChangeValueForKey:NSThreadStatusKey];
}

-(void)pushStatus:(NSString*)status {
	if( self.isFinished)
		return;
	if( self.isCancelled)
		return;
	
	@synchronized (self.threadDictionary)
	{
		if (!status) status = @"";
		[self.statusArray addObject:[[status copy] autorelease]];
	}
}

-(void)popStatus {
	if( self.isFinished)
		return;
	if( self.isCancelled)
		return;

	@synchronized (self.threadDictionary)
	{
		if (self.statusArray.count)
			[self.statusArray removeLastObject];
	}
}

NSString* const NSThreadSubthreadsArrayKey = @"subthreads";

-(NSMutableArray*)subthreadsArray
{
	NSMutableArray* subthreadsArray = nil;
	
	if( self.isFinished)
		return nil;
	
	if( self.isCancelled)
		return nil;
	
	@synchronized (self.threadDictionary)
	{
		subthreadsArray = [self.threadDictionary objectForKey:NSThreadSubthreadsArrayKey];
	
		if (!subthreadsArray)
		{
			subthreadsArray = [NSMutableArray array];
			[self.threadDictionary setObject:subthreadsArray forKey:NSThreadSubthreadsArrayKey];
		}
	}
	
	return subthreadsArray;
}

-(void)enterSubthreadWithRange:(CGFloat)rangeLoc:(CGFloat)rangeLen
{
	[self.subthreadsArray addObject:[NSValue valueWithPoint:NSMakePoint(rangeLoc,rangeLen)]];
//	NSLog(@"entering level %d subthread", self.subthreadsArray.count);
	self.progress = 0;
}

-(void)exitSubthread
{
	self.progress = 1;
	[self.subthreadsArray removeLastObject];
}

NSString* const NSThreadProgressKey = @"progress";
NSString* const NSThreadSubthreadsAwareProgressKey = @"subthreadsAwareProgress";

-(CGFloat)progress
{
	if( self.isFinished)
		return -1;
	
	if( self.isCancelled)
		return -1;
	
	NSNumber* progress = nil;
	@synchronized (self.threadDictionary)
	{
		progress = [self.threadDictionary objectForKey:NSThreadProgressKey];
	}
	return progress? [progress floatValue] : -1;
}

-(void)setProgress:(CGFloat)progress
{
	if( self.isFinished)
		return;
	
	if( self.isCancelled)
		return;
	
	if (progress == self.progress) return;

	@synchronized (self.threadDictionary)
	{
		[self willChangeValueForKey:NSThreadProgressKey];
		[self.threadDictionary setObject:[NSNumber numberWithFloat:progress] forKey:NSThreadProgressKey];
		//	[self performSelectorOnMainThread:NotifyInfoChangeSelector withObject:NSThreadProgressKey waitUntilDone:NO];
		[self didChangeValueForKey:NSThreadProgressKey];
		[self didChangeValueForKey:NSThreadSubthreadsAwareProgressKey];
	}
}

- (NSComparisonResult)compare:(id) obj
{
	//NSException *e = [NSException exceptionWithName: @"NSThread compare" reason: @"compare:" userInfo: nil];	
	//[e printStackTrace];
	
	return NSOrderedSame;
}

-(CGFloat)subthreadsAwareProgress
{
	CGFloat progress = self.progress;
	
	if (progress < 0)
		return progress;
	
	NSPoint range = NSMakePoint(0,1);
	for (NSValue* iv in self.subthreadsArray)
	{
		NSPoint ir = [iv pointValue];
		range = NSMakePoint(range.x+range.y*ir.x, range.y*ir.y);
	}
	
	return range.x+range.y*self.progress;
}

@end
