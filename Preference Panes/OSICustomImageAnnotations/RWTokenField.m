//
//  RWTokenField.m
//  ImageAnnotations
//
//  Created by joris on 09/07/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "RWTokenField.h"


@interface NSTokenFieldCell (UndocumentedMethods)

- (void)_string:(id)fp8 tokenizeIndex:(int)fp12 inTextStorage:(id)fp16;

@end

@interface RWTokenFieldCell: NSTokenFieldCell
@end


//***************************************************************************

@implementation RWTokenFieldCell

+ (void) load
{
	[RWTokenFieldCell poseAsClass:[NSTokenFieldCell class]];
}

- (void)_string:(id)fp8 tokenizeIndex:(int)fp12 inTextStorage:(id)fp16
{
	[super _string:fp8 tokenizeIndex:fp12 inTextStorage:fp16];

	if(![[self controlView] respondsToSelector:@selector(tokenFieldCellDidTokenizeString)]) return;
	
	[[self controlView] performSelector:@selector(tokenFieldCellDidTokenizeString) withObject:self];
}

- (void) setObjectValue:(id<NSCopying>)object
{
	[super setObjectValue:object];
	
	if(![[self controlView] respondsToSelector:@selector(tokenFieldCellDidTokenizeString)]) return;
	
	[[self controlView] performSelector:@selector(tokenFieldCellDidTokenizeString) withObject:self];
}

@end

//***************************************************************************

@implementation RWTokenField

+ (void) load
{
	[RWTokenField poseAsClass:[NSTokenField class]];
}

- (void) tokenFieldCellDidTokenizeString:(NSTokenFieldCell*)tokenFieldCell
{
	NSDictionary* valueBindingInformation = [self infoForBinding:@"value"];
	if(valueBindingInformation != nil)
	{
		id valueBindingObject = [valueBindingInformation objectForKey:NSObservedObjectKey];
		NSString* valueBindingKeyPath = [valueBindingInformation objectForKey:NSObservedKeyPathKey];
		
		[valueBindingObject setValue:[self objectValue] forKeyPath:valueBindingKeyPath];
	}
	
	[self sendAction:[self action] to:[self target]];

	if([[self delegate] respondsToSelector:@selector(tokenFieldDidTokenizeString:)])
	{
		[[self delegate] performSelector:@selector(tokenFieldDidTokenizeString:) withObject:self];
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"concludeDragOperation");
	[super concludeDragOperation:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	NSLog(@"draggingEnded");
	[super draggingEnded:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"performDragOperation");
	return [super performDragOperation:sender];
}


@end