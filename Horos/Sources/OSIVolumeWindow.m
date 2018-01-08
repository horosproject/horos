/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "OSIVolumeWindow.h"
#import "OSIVolumeWindow+Private.h"
#import "OSIROIManager.h"
#import "OSIROIManager+Private.h"
#import "pluginSDKAdditions.h"
#import "Notifications.h"
#import "OSIFloatVolumeData.h"
#import "DCMView.h"

NSString* const OSIVolumeWindowDidCloseNotification = @"OSIVolumeWindowDidCloseNotification";

NSString* const OSIVolumeWindowWillChangeDataNotification = @"OSIVolumeWindowWillChangeDataNotification";
NSString* const OSIVolumeWindowDidChangeDataNotification = @"OSIVolumeWindowDidChangeDataNotification";

@interface OSIVolumeWindow ()
- (void)_viewerControllerDidLoadImagesNotification:(NSNotification *)notification;
- (void)_viewerControllerWillFreeVolumeDataNotification:(NSNotification *)notification;
- (void)_viewerControllerDidAllocateVolumeDataNotification:(NSNotification *)notification;
@end

@implementation OSIVolumeWindow

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"dataLoaded"]) {
		return NO;
	}
	
	return [super automaticallyNotifiesObserversForKey:key];
}


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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[_viewerController release];
	_viewerController = nil;
	_ROIManager.delegate = nil;
	[_ROIManager release];
	_ROIManager = nil;
    [_OSIROIs release];
    _OSIROIs = nil;
    [_generatedFloatVolumeDatas release];
    _generatedFloatVolumeDatas = nil;
    [_generatedFloatVolumeDataToInvalidate release];
    _generatedFloatVolumeDataToInvalidate = nil;
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

- (BOOL)isDataLoaded
{
    return _dataLoaded;
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
    NSString *dimensionAndIndexKey;
    NSArray *pixList;
    NSData *volumeData;
    OSIFloatVolumeData *floatVolumeData;
    
    assert([dimensions count] == 1);
    assert([indexes count] == 1);
    
    assert([[dimensions objectAtIndex:0] isEqualToString:@"movieIndex"]);
    assert([[indexes objectAtIndex:0] isKindOfClass:[NSNumber class]]);
    
    dimensionAndIndexKey = [NSString stringWithFormat:@"movieIndex_%@", [indexes objectAtIndex:0]]; // THIS is totally bogus once we handle more than one dimension
    
    floatVolumeData = [_generatedFloatVolumeDatas objectForKey:dimensionAndIndexKey];
    if (floatVolumeData) {
        if ([floatVolumeData isDataValid]) {
            return floatVolumeData;
        } else {
            [_generatedFloatVolumeDatas removeObjectForKey:dimensionAndIndexKey];
        }
    }
    
    pixList = [_viewerController pixList:[[indexes objectAtIndex:0] integerValue]];
    volumeData = [_viewerController volumeData:[[indexes objectAtIndex:0] integerValue]];
    
    assert(pixList);
    assert(volumeData);
    
    [_viewerController computeInterval];
    floatVolumeData = [[[OSIFloatVolumeData alloc] initWithWithPixList:pixList volume:volumeData] autorelease];
    
    [_generatedFloatVolumeDatas setObject:floatVolumeData forKey:dimensionAndIndexKey];
    [_generatedFloatVolumeDataToInvalidate setObject:floatVolumeData forKey:[NSNumber numberWithInteger:(NSInteger)volumeData]];
    
    return floatVolumeData;
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
        assert(0);
		return nil;
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

- (void)_viewerControllerDidLoadImagesNotification:(NSNotification *)notification
{
    ViewerController *viewerController = [notification object];
    
    assert([viewerController isKindOfClass:[ViewerController class]]);
    if ([viewerController isKindOfClass:[ViewerController class]] == NO) {
        NSLog(@"_viewerControllerDidLoadImagesNotification: recieved an object that is not ViewerController");
        return;
    }
    
    assert(viewerController == _viewerController);
    if (viewerController != _viewerController) {
        NSLog(@"_viewerControllerDidLoadImagesNotification: recieved the wrong viewerController");
        return;
    }
    
    [self willChangeValueForKey:@"dataLoaded"];
    _dataLoaded = YES;
    [self didChangeValueForKey:@"dataLoaded"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixViewerControllerDidLoadImagesNotification object:_viewerController];
}

- (void)_viewerControllerWillFreeVolumeDataNotification:(NSNotification *)notification
{
    assert([NSThread isMainThread]);
    NSData *volumeData;
    OSIFloatVolumeData *floatVolumeData;
    
    volumeData = [[notification userInfo] objectForKey:@"volumeData"];
    assert(volumeData);
    
    floatVolumeData = [_generatedFloatVolumeDataToInvalidate objectForKey:[NSNumber numberWithInteger:(NSInteger)volumeData]];
    if (floatVolumeData) {
        [floatVolumeData invalidateData];
        [_generatedFloatVolumeDataToInvalidate removeObjectForKey:[NSNumber numberWithInteger:(NSInteger)volumeData]];
    }
}

- (void)_viewerControllerDidAllocateVolumeDataNotification:(NSNotification *)notification
{
    // Do something here
}


@end

@implementation OSIVolumeWindow (Private)

- (id)initWithViewerController:(ViewerController *)viewerController
{
	if ( (self = [super init]) ) {
		_viewerController = [viewerController retain];
        _OSIROIs = [[NSMutableArray alloc] init];
        _generatedFloatVolumeDatas = [[NSMutableDictionary alloc] init];
        _generatedFloatVolumeDataToInvalidate = [[NSMutableDictionary alloc] init];
    
        _dataLoaded = [_viewerController isEverythingLoaded];
        if (_dataLoaded == NO) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_viewerControllerDidLoadImagesNotification:) name:OsirixViewerControllerDidLoadImagesNotification object:_viewerController];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_viewerControllerWillFreeVolumeDataNotification:) name:OsirixViewerControllerWillFreeVolumeDataNotification object:_viewerController];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_viewerControllerDidAllocateVolumeDataNotification:) name:OsirixViewerControllerDidAllocateVolumeDataNotification object:_viewerController];

        _ROIManager = [[OSIROIManager alloc] initWithVolumeWindow:self];
		_ROIManager.delegate = self;
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

- (void)viewerControllerWillChangeData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OSIVolumeWindowWillChangeDataNotification object:self];
}

- (void)viewerControllerDidChangeData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OSIVolumeWindowDidChangeDataNotification object:self];
}


- (void)drawInDCMView:(DCMView *)dcmView
{
    [_ROIManager drawInDCMView:dcmView];
}

- (void)setNeedsDisplay
{
    [[_viewerController imageView] setNeedsDisplay:YES];
    for (DCMView *dcmView in [_viewerController imageViews]) {
        [dcmView setNeedsDisplay:YES];
    }
}


@end
