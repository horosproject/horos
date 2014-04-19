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




#import "SeriesView.h"
#import "DCMView.h"
#import "ViewerController.h"
#import "WindowLayoutManager.h"
#import "Notifications.h"

@implementation SeriesView

- (id)initWithFrame:(NSRect)frame {
	return [self initWithFrame:frame seriesRows:1  seriesColumns:1];

}

- (id)initWithFrame:(NSRect)frame seriesRows:(int)rows  seriesColumns:(int)columns
{
	self = [super initWithFrame:frame];
    if (self)
	{
        seriesRows = rows;
		seriesColumns = columns;
		tag = 0;
		
		imageColumns = [[WindowLayoutManager sharedWindowLayoutManager] imagesColumns];
		imageRows = [[WindowLayoutManager sharedWindowLayoutManager] imagesRows];
		
//		NSLog(@"ImageRows %d imageColumns: %d", imageRows, imageColumns);
	
		if (!imageRows)
			imageRows = 1;
		
		if (!imageColumns)
			imageColumns = 1;
		
		int matrixSize = imageRows * imageColumns;		
		imageViews = [[NSMutableArray array] retain];
		while (tag < matrixSize)
		{
			DCMView *dcmView = [[[DCMView alloc] initWithFrame:frame imageRows:imageRows imageColumns:imageColumns] autorelease];			
			[self addSubview:dcmView];
			[dcmView setTag:tag++];
		}
		[self setAutoresizingMask:NSViewMinXMargin];
		[self resizeSubviewsWithOldSize:[self bounds].size];
		[[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(updateImageTiling:)
               name:@"DCMImageTilingHasChanged"
			object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(defaultToolModified:)
               name:OsirixDefaultToolModifiedNotification
			object: nil];
			
        [[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(defaultRightToolModified:)
               name:OsirixDefaultRightToolModifiedNotification
			object: nil];
    }
    return self;
}


- (void)dealloc{
	NSLog(@"seriesView dealloc");
	[imageViews release];
	[dcmPixList release];
	[dcmFilesList release];
	[dcmRoiList release];
	[curRoiList release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSColor *backgroundColor = [NSColor blackColor];
	[backgroundColor setFill];	
	[NSBezierPath fillRect:rect];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize{
	
	NSRect superFrame = [[self superview] bounds];
    
    if( superFrame.size.width == 0 || superFrame.size.height == 0)
        return;
    
	float newWidth = superFrame.size.width / seriesColumns;
	float newHeight = superFrame.size.height / seriesRows;
	float newX = newWidth * (tag / seriesColumns);
	float newY = newHeight * (tag % seriesColumns);
	NSRect newFrame = NSMakeRect(newX, newY, newWidth, newHeight);
	[self setFrame:newFrame];
	[self setNeedsDisplay:YES];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize{
	[super resizeSubviewsWithOldSize:oldBoundsSize];
}

- (BOOL)isFlipped{
    return YES;
}

- (BOOL)autoresizesSubviews{
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return NO;
}

- (NSInteger)tag{
	return tag;
}

- (void)setTag:(NSInteger)theTag{
	tag = theTag;
}

- (DCMView *)firstView{
	return [imageViews objectAtIndex: 0];
}

- (NSMutableArray *)imageViews{
	return imageViews;
}

- (void)addSubview:(NSView *)aView{
	[super addSubview:aView];
	if ([aView isKindOfClass:[DCMView class]]) 
		[imageViews addObject:aView];

}

- (void) selectFirstTilingView
{
	[[self window] makeFirstResponder:[imageViews objectAtIndex:0]];
}

- (void)setImageViewMatrixForRows:(int)rows  columns:(int)columns
{
    [self setImageViewMatrixForRows: rows columns: columns rescale: YES];
}

- (void)setImageViewMatrixForRows:(int)rows  columns:(int)columns rescale: (BOOL) rescale
{
	NSDisableScreenUpdates();

	int currentSize = imageRows * imageColumns;
	int newSize = rows * columns;
	int i;
	
	[[[self window] windowController] setUpdateTilingViewsValue: YES];
	
	BOOL wasVisible = [[self window] isVisible];
	if( wasVisible) [[self window] orderOut: self];
	
	BOOL imageLevel = NO;
	if( rescale)
    {
        for( id imageObj in dcmFilesList)
        {
            float factor = (float) imageRows / (float) rows;
            
            float scale = [[imageObj valueForKey: @"scale"] floatValue];
            
            if( scale)
            {
                [imageObj setValue: [NSNumber numberWithFloat: scale * factor] forKey: @"scale"];
                imageLevel = YES;
            }
            
            float xOffset = [[imageObj valueForKey:@"xOffset"] floatValue];
            if( xOffset)
            {
                [imageObj setValue: [NSNumber numberWithFloat: xOffset * factor] forKey: @"xOffset"];
            }
            
            float yOffset = [[imageObj valueForKey:@"yOffset"] floatValue];
            if( yOffset)
            {
                [imageObj setValue: [NSNumber numberWithFloat: yOffset * factor] forKey: @"yOffset"];
            }
        }
    }
	
	// remove views
	if (newSize < currentSize)
	{
		[[self window] makeFirstResponder:[imageViews objectAtIndex:0]];
		for (i = currentSize - 1; i >= newSize ; i--)
		{
			DCMView *view = [imageViews lastObject];			
			[view removeFromSuperview];
			[view prepareToRelease];
			[imageViews removeLastObject];
		}
	}
	//add views
	else if (newSize > currentSize)
	{
        BOOL csis = [[imageViews lastObject] COPYSETTINGSINSERIES];
		for ( i = [imageViews count]; i < rows * columns; i++)
		{
			DCMView *dcmView = [[[DCMView alloc] initWithFrame:[self bounds]  imageRows:rows  imageColumns:columns] autorelease];
            [dcmView setCOPYSETTINGSINSERIESdirectly: csis];
			[self addSubview:dcmView];
			[dcmView setTag:i];	
			[dcmView setPixels: dcmPixList files:dcmFilesList rois:dcmRoiList firstImage:0 level:listType reset:YES];
		}	
	}
	
	for( DCMView *view in imageViews)
		[view setRows:rows columns:columns];
		
	[[self window] makeFirstResponder:[imageViews objectAtIndex:0]];
	[[[self window] windowController] setUpdateTilingViewsValue: NO];
	
	[self resizeSubviewsWithOldSize:[self bounds].size];
	[imageViews makeObjectsPerformSelector:@selector(setImageParamatersFromView:) withObject:[imageViews objectAtIndex:0]];
	
	if( rescale)
    {
        if( imageLevel == NO)
        {
            float factor = (float) imageRows / (float) rows;
            
            NSPoint origin = [[imageViews objectAtIndex: 0] origin];
            [[imageViews objectAtIndex: 0] setOriginX:origin.x*factor Y: origin.y*factor];
            [[imageViews objectAtIndex: 0] setScaleValue: [[imageViews objectAtIndex: 0] scaleValue] * factor];
        }
        else
        {
            for( id view in imageViews)
                [view updatePresentationStateFromSeriesOnlyImageLevel: NO]; // Apply the scale modifications
        }
    }
	
	imageRows = rows;
	imageColumns = columns;
	
	if( wasVisible) [[self window] makeKeyAndOrderFront: self];
	
	NSEnableScreenUpdates();
	
	[self setNeedsDisplay:YES];
}

- (void)updateImageTiling:(NSNotification *)note
{
	if ([[self window] isMainWindow])
	{
		int rows = [[[note userInfo] objectForKey:@"Rows"] intValue];
		int columns = [[[note userInfo] objectForKey:@"Columns"] intValue];
		[self setImageViewMatrixForRows:rows columns:columns];
	}
 }

 -(void) defaultToolModified: (NSNotification*) note{
	id sender = [note object];

	int ctag;

	if ([sender isKindOfClass:[NSMatrix class]])
	{
		NSButtonCell *theCell = [sender selectedCell];
		ctag = [theCell tag];
	}
	else if (!sender)
	{
		ctag = [[[note userInfo] valueForKey:@"toolIndex"] intValue];
	}
	else
	{
		ctag = [sender tag];
    }
	if( ctag >= 0)
    {
		for (DCMView *view in imageViews)
			[view setCurrentTool: ctag];
    }
}

 -(void) defaultRightToolModified: (NSNotification*) note{
	id sender = [note object];
	int ctag;

	if ([sender isKindOfClass:[NSMatrix class]])
	{
		NSButtonCell *theCell = [sender selectedCell];
		ctag = [theCell tag];
	}
	else
	{
		ctag = [sender tag];
    }
	
	if( ctag >= 0)
    {
		DCMView *view;
		for (view in imageViews)
        [view setRightTool: ctag];
    }
}

- (void) setPixels: (NSMutableArray*) pixels files: (NSArray*) files rois: (NSMutableArray*) rois firstImage: (short) firstImage level: (char) level reset: (BOOL) reset
{
	[dcmPixList release];
    dcmPixList = [pixels retain];
    
	[dcmFilesList release];
    dcmFilesList = [files retain];
	
	[dcmRoiList release];
    dcmRoiList = [rois retain];
    	
    listType = level;
	
	DCMView *view;
	int i = firstImage;
	for (view in imageViews)
	{
		if (i < [dcmPixList count])
			[view setPixels: pixels files:files rois:rois firstImage:i++ level:level reset:reset];
		else
			[view setPixels: pixels files:files rois:rois firstImage:-1 level:level reset:reset];
	}
 }

- (void) setDCM:(NSMutableArray*) c :(NSArray*)d :(NSMutableArray*)e :(short) firstImage :(char) type :(BOOL) reset
{
	[self setPixels: c files: d rois: e firstImage: firstImage level: type reset: reset];
}
 
 - (void) setBlendingFactor:(float) value{
	DCMView *view;
	for (view in imageViews)
		[view setBlendingFactor:value];
	
 }
- (void) setBlendingMode:(int) value{
	DCMView *view;
	for (view in imageViews)
		[view setBlendingMode:value];
}
- (void) setFlippedData:(BOOL) value
{
	DCMView *view;
	for (view in imageViews)
		[view setFlippedData:value];
}

-(void) ActivateBlending:(ViewerController*) bC blendingFactor:(float)blendingFactor{
	DCMView *view;
	for (view in imageViews)
	{
		if( bC)
			[view setBlending: [bC imageView]];			
		else
			[view setBlending: nil];
		
		[view setBlendingFactor: blendingFactor];
	}
}

- (int)imageRows{
	return imageRows;
}

- (int)imageColumns{
	return imageColumns;
}

@end
