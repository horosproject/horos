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

#import "OSIVolumeWindow.h"
#import "OSIVolumeWindow+Private.h"
#import "OSIROIManager.h"
#import "pluginSDKAdditions.h"

NSString* const OSIVolumeWindowDidCloseNotification = @"OSIVolumeWindowDidCloseNotification";

@implementation OSIVolumeWindow

// don't call this!
- (id)init
{
	assert(0);
	[self autorelease];
	self = nil;
	return self;
}

- (void)dealloc
{
	[_viewerController release];
	_viewerController = nil;
	_ROIManager.delegate = nil;
	[_ROIManager release];
	_ROIManager = nil;
    [_OSIROIs release];
    _OSIROIs = nil;
	[super dealloc];
}

- (ViewerController *)viewerController // if you really want to go into the depths of OsiriX, use at your own peril!
{
	return _viewerController;
}

- (BOOL)isOpen
{
	return (_viewerController ? YES : NO);
}

- (OSIROIManager *)ROIManager
{
	return _ROIManager;
}

- (NSString *)title
{
	return [[_viewerController window] title];
}

- (NSArray *)dimensions // dimensions other than the 3 natural dimensions
{
	if ([_viewerController maxMovieIndex] > 1) {
		return [NSArray arrayWithObject:@"movieIndex"];
	} else {
		return [NSArray array];
	}
}

- (NSUInteger)depthOfDimension:(NSString *)dimension
{
	if ([dimension isEqualToString:@"movieIndex"]) {
		return [_viewerController maxMovieIndex];
	} else {
		return 0;
	}
}

- (OSIFloatVolumeData *)floatVolumeDataForDimensions:(NSArray *)dimensions indexes:(NSArray *)indexes;
{
	return [_viewerController floatVolumeDataForMovieIndex:0];
}

- (OSIFloatVolumeData *)floatVolumeDataForDimensionsAndIndexes:(NSString *)firstDimenstion, ...
{
	NSMutableArray *dimensions;
	NSMutableArray *indexes;
	id dimension;
	id index;
	
	if (firstDimenstion) {
		dimensions = [NSMutableArray array];
		indexes = [NSMutableArray array];
		
		va_list args;
		va_start(args, firstDimenstion);
		dimension = firstDimenstion;
		index = va_arg(args, id);
		assert([dimension isKindOfClass:[NSString class]]);
		assert(index);
		assert([index isKindOfClass:[NSNumber class]]);
		
		[dimensions addObject:dimension];
		[indexes addObject:index];
		while ( (dimension = va_arg(args, id)) ) {
			index = va_arg(args, id);
			assert([dimension isKindOfClass:[NSString class]]);
			assert(index);
			assert([index isKindOfClass:[NSNumber class]]);
			
			[dimensions addObject:dimension];
			[indexes addObject:index];
		}
		va_end(args);
		
		return [self floatVolumeDataForDimensions:dimensions indexes:indexes];
	} else {
		return [_viewerController floatVolumeDataForMovieIndex:0];
	}
}

- (void)addOSIROI:(OSIROI *)roi
{
    NSMutableArray *rois;
    rois = [self mutableArrayValueForKey:@"OSIROIs"];
    [rois addObject:roi];
}

- (void)removeOSIROI:(OSIROI *)roi
{
    NSMutableArray *rois;
    rois = [self mutableArrayValueForKey:@"OSIROIs"];
    [rois removeObject:roi];
}

- (NSArray *)OSIROIs // observable
{
    return _OSIROIs;
}

@end

@implementation OSIVolumeWindow (Private)

- (id)initWithViewerController:(ViewerController *)viewerController
{
	if ( (self = [super init]) ) {
		_viewerController = [viewerController retain];
		_ROIManager = [[OSIROIManager alloc] initWithVolumeWindow:self];
		_ROIManager.delegate = self;
        _OSIROIs = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)viewerControllerDidClose
{
	[self willChangeValueForKey:@"open"];
	[_viewerController release];
	_viewerController = nil;
	[self didChangeValueForKey:@"open"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OSIVolumeWindowDidCloseNotification object:self];
}

@end
