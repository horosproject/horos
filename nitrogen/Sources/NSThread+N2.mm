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


@implementation NSThread (N2)

NSString* const NSThreadUniqueIdKey = @"uniqueId";

-(NSString*)uniqueId {
	return [self.threadDictionary objectForKey:NSThreadUniqueIdKey];
}

-(void)setUniqueId:(NSString*)uniqueId {
	if ([uniqueId isEqual:self.uniqueId]) return;
	[self willChangeValueForKey:NSThreadUniqueIdKey];
	[self.threadDictionary setObject:uniqueId forKey:NSThreadUniqueIdKey];
	[self didChangeValueForKey:NSThreadUniqueIdKey];
}

NSString* const NSThreadSupportsCancelKey = @"supportsCancel";

-(BOOL)supportsCancel {
	NSNumber* supportsCancel = [self.threadDictionary objectForKey:NSThreadSupportsCancelKey];
	return supportsCancel? [supportsCancel boolValue] : NO;
}

-(void)setSupportsCancel:(BOOL)supportsCancel {
	if (supportsCancel == self.supportsCancel) return;
	[self willChangeValueForKey:NSThreadSupportsCancelKey];
	[self.threadDictionary setObject:[NSNumber numberWithBool:supportsCancel] forKey:NSThreadSupportsCancelKey];
	[self didChangeValueForKey:NSThreadSupportsCancelKey];
}

NSString* const NSThreadIsCancelledKey = @"isCancelled";

/*-(BOOL)isCancelled {
	NSNumber* isCancelled = [self.threadDictionary objectForKey:NSThreadSupportsCancelKey];
	return isCancelled? isCancelled.boolValue : NO;
}*/

-(void)setIsCancelled:(BOOL)isCancelled {
	if (isCancelled == self.isCancelled) return;
	if (!isCancelled) [NSException raise:NSGenericException format:@"a cancelled thread cannot be uncancelled"];
	[self willChangeValueForKey:NSThreadIsCancelledKey];
	[self cancel];
	[self didChangeValueForKey:NSThreadIsCancelledKey];
}

NSString* const NSThreadStatusKey = @"status";

-(NSString*)status
{
	NSString *s = nil;
	
	@synchronized (self.threadDictionary)
	{
		s = [[[self.threadDictionary objectForKey:NSThreadStatusKey] copy] autorelease];
	}
	
	return s;
}

-(void)setStatus:(NSString*)status
{
	if( [status isEqual:self.status]) return;
	
	[self willChangeValueForKey:NSThreadStatusKey];
	
	@synchronized (self.threadDictionary)
	{
		if( status == nil) [self.threadDictionary removeObjectForKey: NSThreadStatusKey];
		else [self.threadDictionary setObject: [[status copy] autorelease] forKey:NSThreadStatusKey];
	}
	
	[self didChangeValueForKey:NSThreadStatusKey];
}

NSString* const NSThreadSubthreadsArrayKey = @"subthreads";

-(NSMutableArray*)subthreadsArray {
	NSMutableArray* subthreadsArray = [self.threadDictionary objectForKey:NSThreadSubthreadsArrayKey];
	
	if (!subthreadsArray) {
		subthreadsArray = [NSMutableArray array];
		[self.threadDictionary setObject:subthreadsArray forKey:NSThreadSubthreadsArrayKey];
	}
	
	return subthreadsArray;
}

-(void)enterSubthreadWithRange:(CGFloat)rangeLoc:(CGFloat)rangeLen {
	[self.subthreadsArray addObject:[NSValue valueWithPoint:NSMakePoint(rangeLoc,rangeLen)]];
//	NSLog(@"entering level %d subthread", self.subthreadsArray.count);
	self.progress = 0;
}

-(void)exitSubthread {
//	NSLog(@"exiting level %d subthread", self.subthreadsArray.count);
	self.progress = 1;
	[self.subthreadsArray removeLastObject];
}

NSString* const NSThreadProgressKey = @"progress";
NSString* const NSThreadSubthreadsAwareProgressKey = @"subthreadsAwareProgress";

-(CGFloat)progress {
	NSNumber* progress = [self.threadDictionary objectForKey:NSThreadProgressKey];
	return progress? [progress floatValue] : -1;
}

-(void)setProgress:(CGFloat)progress {
	if (progress == self.progress) return;
	[self willChangeValueForKey:NSThreadProgressKey];
	[self.threadDictionary setObject:[NSNumber numberWithFloat:progress] forKey:NSThreadProgressKey];
//	[self performSelectorOnMainThread:NotifyInfoChangeSelector withObject:NSThreadProgressKey waitUntilDone:NO];
	[self didChangeValueForKey:NSThreadProgressKey];
	[self didChangeValueForKey:NSThreadSubthreadsAwareProgressKey];
}

-(CGFloat)subthreadsAwareProgress {
	CGFloat progress = self.progress;
	
	if (progress < 0)
		return progress;
	
	NSPoint range = NSMakePoint(0,1);
	for (NSValue* iv in self.subthreadsArray) {
		NSPoint ir = [iv pointValue];
		range = NSMakePoint(range.x+range.y*ir.x, range.y*ir.y);
	}
	
//	NSLog(@"progress %f means %f", progress, range.x+range.y*self.progress);
	
	return range.x+range.y*self.progress;
}

@end
