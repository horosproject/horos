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

-(NSString*)status {
	return [self.threadDictionary objectForKey:NSThreadStatusKey];
}

-(void)setStatus:(NSString*)status {
	if ([status isEqual:self.status]) return;
	[self willChangeValueForKey:NSThreadStatusKey];
	[self.threadDictionary setObject:status forKey:NSThreadStatusKey];
//	[self performSelectorOnMainThread:NotifyInfoChangeSelector withObject:NSThreadStatusKey waitUntilDone:NO];
	[self didChangeValueForKey:NSThreadStatusKey];
}

NSString* const NSThreadProgressKey = @"progress";

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
}

@end
