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
#import "N2Debug.h"
//#import "NSException+N2.h"

@interface N2BlockThread : NSThread {
    void (^_block)();
}

-(id)initWithBlock:(void(^)())block;

@end

@implementation NSThread (N2)

+(NSThread*)performBlockInBackground:(void(^)())block {
    N2BlockThread* bt = [[[N2BlockThread alloc] initWithBlock:block] autorelease];
    [bt start];
    return bt;
}

-(NSComparisonResult)compare:(id)obj {
	//NSException *e = [NSException exceptionWithName: @"NSThread compare" reason: @"compare:" userInfo: nil];	
	//[e printStackTrace];
	return NSOrderedSame;
}

NSString* const NSThreadNameKey = @"name";

#pragma mark Id

NSString* const NSThreadUniqueIdKey = @"uniqueId";

-(NSString*)uniqueId {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
    NSString* uniqueId = nil;
	
	@synchronized (self) {
		uniqueId = [[[self.threadDictionary objectForKey:NSThreadUniqueIdKey] copy] autorelease];
	}
	
	return uniqueId;
}

-(void)setUniqueId:(NSString*)uniqueId {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;

	if ([uniqueId isEqualToString:self.uniqueId])
		return;
	
	@synchronized (self) {
		[self willChangeValueForKey:NSThreadUniqueIdKey];
		[self.threadDictionary setObject:uniqueId forKey:NSThreadUniqueIdKey];
		[self didChangeValueForKey:NSThreadUniqueIdKey];
	}
}

NSString* const NSThreadIsCancelledKey = @"isCancelled";

-(void)setIsCancelled:(BOOL)isCancelled {
	if (self.isFinished)
		return;
	if (self.isCancelled)
		return;
	
	if (isCancelled == self.isCancelled) return;
	
	@synchronized (self) {
		[self willChangeValueForKey:NSThreadIsCancelledKey];
		[self cancel];
		[self didChangeValueForKey:NSThreadIsCancelledKey];
	}
}

#pragma mark Stack

static NSString* const NSThreadStackArrayKey = @"NSThreadStackArrayKey";

-(NSMutableArray*)stackArray {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
	
    if (self.isFinished)
        return nil;
    
	NSMutableArray* a = nil;
	
	@synchronized (self) {
		a = [self.threadDictionary objectForKey:NSThreadStackArrayKey];
		if (!a) {
			a = [NSMutableArray array];
			[self.threadDictionary setObject:a forKey:NSThreadStackArrayKey];
			if ([self.threadDictionary objectForKey:NSThreadStackArrayKey])
                [self enterOperation];
		}
	}
	
	return a;
}

static NSString* const NSThreadSubRangeKey = @"subRange";

-(NSMutableDictionary*)currentOperationDictionary {
    
    @synchronized (self) {
        return [[[self.stackArray lastObject] retain] autorelease];
    }
}

static NSString* const SuperThreadProgressKey = @"SuperThreadProgress";
static NSString* const SuperThreadNameKey = @"SuperThreadName";

-(void)enterOperation {
	@synchronized (self) {
        NSNumber* n = [NSNumber numberWithFloat:self.progress];
		[self.stackArray addObject:[NSMutableDictionary dictionary]];
        [self.currentOperationDictionary setObject:n forKey:SuperThreadProgressKey];
        if (self.name) [self.currentOperationDictionary setObject:self.name forKey:SuperThreadNameKey];
		self.progress = -1;
	}
}

-(void)enterOperationIgnoringLowerLevels {
	@synchronized (self) {
		[self enterOperation];
		[self.currentOperationDictionary setObject:[NSNull null] forKey:NSThreadSubRangeKey];
        self.progress = -1;
    }
}

-(void)enterOperationWithRange:(CGFloat)rangeLoc :(CGFloat)rangeLen
{
	@synchronized (self) {
		[self enterOperation];
		[self.currentOperationDictionary setObject:[NSValue valueWithPoint:NSMakePoint(rangeLoc,rangeLen)] forKey:NSThreadSubRangeKey];
		//	NSLog(@"entering level %d subthread", self.subthreadsArray.count);
		self.progress = 0;
	}
}

-(void)exitOperation {
	@synchronized (self) {
		if (self.stackArray.count > 1) {
            [self willChangeValueForKey:NSThreadStatusKey];
			NSNumber* temp = [[[self.currentOperationDictionary objectForKey:SuperThreadProgressKey] retain] autorelease];
			NSString* name = [[[self.currentOperationDictionary objectForKey:SuperThreadNameKey] retain] autorelease];
            
            [self.stackArray removeLastObject];
            [self didChangeValueForKey:NSThreadStatusKey];
            
            self.name = name;
            if (temp) self.progress = temp.floatValue;
            else self.progress = 1;
        }
		self.progress = 1;
	}
}

-(void)enterSubthreadWithRange:(CGFloat)rangeLoc :(CGFloat)rangeLen { // __deprecated
	@synchronized (self) {
		[self enterOperationWithRange:rangeLoc:rangeLen];
	}
}

-(void)exitSubthread { // __deprecated
	[self exitOperation];
}

#pragma mark Properties

NSString* const NSThreadSupportsCancelKey = @"supportsCancel";

-(BOOL)supportsCancel {
	if (self.isFinished)
		return NO;
	if (self.isCancelled)
		return NO;
	
	@synchronized (self) {
		return [[self.currentOperationDictionary objectForKey:NSThreadSupportsCancelKey] boolValue];
	}
	
	return NO;
}

-(void)setSupportsCancel:(BOOL)supportsCancel {
	if (self.isFinished)
		return;
	if (self.isCancelled)
		return;
    
    if ([self isMainThread])
        return;
	
	if (supportsCancel == self.supportsCancel)
		return;
	
	@synchronized (self) {
		[self willChangeValueForKey:NSThreadSupportsCancelKey];
		[self.currentOperationDictionary setObject:[NSNumber numberWithBool:supportsCancel] forKey:NSThreadSupportsCancelKey];
		[self didChangeValueForKey:NSThreadSupportsCancelKey];
	}
}

NSString* const NSThreadSupportsBackgroundingKey = @"supportsBackgrounding";

-(BOOL)supportsBackgrounding {
	@synchronized (self) {
		return [[self.currentOperationDictionary objectForKey:NSThreadSupportsBackgroundingKey] boolValue];
	}
	
	return NO;
}

-(void)setSupportsBackgrounding:(BOOL)supportsBackgrounding {
    if ([self isMainThread])
        return;
	
	if (supportsBackgrounding == self.supportsBackgrounding)
		return;
	
	@synchronized (self) {
		[self willChangeValueForKey:NSThreadSupportsBackgroundingKey];
		[self.currentOperationDictionary setObject:[NSNumber numberWithBool:supportsBackgrounding] forKey:NSThreadSupportsBackgroundingKey];
		[self didChangeValueForKey:NSThreadSupportsBackgroundingKey];
	}
}


NSString* const NSThreadStatusKey = @"status";

-(NSString*)status {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
	@synchronized (self) {
		for (int i = (long)self.stackArray.count-1; i >= 0; --i) {
			NSDictionary* d = [self.stackArray objectAtIndex:i];
			NSString* status = [d objectForKey:NSThreadStatusKey];
			if (status)
				return [[status copy] autorelease];
		}
		
		return nil;
	}
	
	return nil;
}

-(void)setStatus:(NSString*)status {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
	@synchronized (self) {
		NSString* previousStatus = self.status;
		if (previousStatus == status || [status isEqualToString:previousStatus])
			return;
		
		[self willChangeValueForKey:NSThreadStatusKey];
		if (status)
			[self.currentOperationDictionary setObject:[[status copy] autorelease] forKey:NSThreadStatusKey];
		else [self.currentOperationDictionary removeObjectForKey:NSThreadStatusKey];
		[self didChangeValueForKey:NSThreadStatusKey];
	}
	
}

NSString* const NSThreadProgressKey = @"progress";
NSString* const NSThreadSubthreadsAwareProgressKey = @"subthreadsAwareProgress";

-(CGFloat)progress {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
	@synchronized (self) {
		NSNumber* progress = [self.threadDictionary objectForKey:NSThreadProgressKey];
		return progress? progress.floatValue : -1;
	}
	
	return -1;
}

-(void)setProgress:(CGFloat)progress {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
	@synchronized (self) {
        if (self.progress == progress)
            return;
        
		[self willChangeValueForKey:NSThreadProgressKey];
		[self willChangeValueForKey:NSThreadSubthreadsAwareProgressKey];
		[self.threadDictionary setObject:[NSNumber numberWithFloat:progress] forKey:NSThreadProgressKey];
		[self didChangeValueForKey:NSThreadProgressKey];
		[self didChangeValueForKey:NSThreadSubthreadsAwareProgressKey];
	}
}

-(CGFloat)subthreadsAwareProgress {
	@synchronized (self) {
		if (self.isFinished)
            return 1;
        CGFloat progress = self.progress;
		if (progress < 0)
			return progress;
		
		NSPoint range = NSMakePoint(0,1);
		for (NSDictionary* i in self.stackArray) {
			NSValue* iv = [i objectForKey:NSThreadSubRangeKey];
			if ([iv isKindOfClass:[NSValue class]]) {
				NSPoint ir = [iv pointValue];
				range = NSMakePoint(range.x+range.y*ir.x, range.y*ir.y);
			} else if ([iv isKindOfClass:[NSNull class]]) {
                range = NSMakePoint(0,1);
            }
		}
		
		return range.x+range.y*self.progress;
	}
	
	return -1;
}

NSString* const NSThreadProgressDetailsKey = @"progressDetails";

-(NSString*)progressDetails {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
	@synchronized (self) {
		for (int i = (long)self.stackArray.count-1; i >= 0; --i) {
			NSDictionary* d = [self.stackArray objectAtIndex:i];
			NSString* progressDetails = [d objectForKey:NSThreadProgressDetailsKey];
			if (progressDetails)
				return [[progressDetails copy] autorelease];
		}
		
		return nil;
	}
	
	return nil;
}

-(void)setProgressDetails:(NSString*)progressDetails {
//    if (self.isFinished)
//    	return nil;
//    if (self.isCancelled)
//    	return nil;
    
	@synchronized (self) {
		NSString* previousProgressDetails = self.status;
		if (previousProgressDetails == progressDetails || [progressDetails isEqualToString:previousProgressDetails])
			return;
		
		[self willChangeValueForKey:NSThreadProgressDetailsKey];
		if (progressDetails)
			[self.currentOperationDictionary setObject:[[progressDetails copy] autorelease] forKey:NSThreadProgressDetailsKey];
		else [self.currentOperationDictionary removeObjectForKey:NSThreadProgressDetailsKey];
		[self didChangeValueForKey:NSThreadProgressDetailsKey];
	}
	
}

@end

@implementation N2BlockThread

-(id)initWithBlock:(void(^)())block {
    if ((self = [super init])) {
        _block = [block copy];
    }
    
    return self;
}

-(void)main {
    @autoreleasepool {
        @try {
            _block();
            [_block release]; _block = nil;
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
    }
}

-(void)dealloc {
    [_block release]; _block = nil;
    [super dealloc];
}

@end

