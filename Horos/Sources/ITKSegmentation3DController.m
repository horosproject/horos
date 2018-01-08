/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


#import "ITKSegmentation3D.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "Notifications.h"

#import "ITKSegmentation3DController.h"

enum algorithmTypes { intervalSegmentationType, thresholdSegmentationType, neighborhoodSegmentationType, confidenceSegmentationType};

@implementation ITKSegmentation3DController

- (BOOL) dataVolumic
{
	return [viewer isDataVolumicIn4D: NO];
}

+(id) segmentationControllerForViewer:(ViewerController*) v
{
	NSArray *winList = [NSApp windows];
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString:@"ITKSegmentation"])
		{
			if( [[loopItem windowController] viewer] == v)
			{
				return [loopItem windowController];
			}
		}
	}
	
	return nil;
}

-(void) dealloc
{
	NSLog(@"ITKSegmentation3DController dealloc");
	[algorithms release];
	[parameters release];
	[defaultsParameters release];
	[urlHelp release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[viewer roiDeleteWithName: NSLocalizedString( @"Segmentation Preview", nil)];
	
	NSLog(@"windowWillClose");
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self autorelease];
}

- (NSPoint) startingPoint
{
	return startingPoint;
}

- (ViewerController*) viewer
{
	return viewer;
}

- (id) initWithViewer:(ViewerController*) v
{
	// Is it already available for this viewer??
	id seg = [ITKSegmentation3DController segmentationControllerForViewer: v];
	if( seg)
        return [seg retain];
	
	// Else create a new one !

	self = [super initWithWindowNibName:@"ITKSegmentation"];
	
	viewer = v;
	resultsViewer = nil;
	startingPoint = NSMakePoint(0, 0);
	
	algorithms = [NSArray arrayWithObjects:	NSLocalizedString( @"Threshold (interval)", nil),
											NSLocalizedString( @"Threshold (lower/upper bounds)", nil),
											NSLocalizedString( @"Neighborhood", nil),
											NSLocalizedString( @"Confidence", nil),
											nil];
	[algorithms retain];
	
	parameters = [NSArray arrayWithObjects:	[NSArray arrayWithObjects:NSLocalizedString( @"Interval", nil), nil],
											[NSArray arrayWithObjects:NSLocalizedString( @"Lower Threshold", nil), NSLocalizedString( @"Upper Threshold", nil), nil],
											[NSArray arrayWithObjects:NSLocalizedString( @"Lower Threshold", nil), NSLocalizedString( @"Upper Threshold", nil), NSLocalizedString( @"Radius (pix.)", nil), nil],
											[NSArray arrayWithObjects:NSLocalizedString( @"Multiplier", nil), NSLocalizedString( @"Num. of Iterations", nil), NSLocalizedString( @"Initial Radius (pix.)", nil), nil],
											nil];
	[parameters retain];
	
	defaultsParameters = [NSArray arrayWithObjects:	[NSArray arrayWithObjects:@"100", nil],
											[NSArray arrayWithObjects:@"", @"", nil],
											[NSArray arrayWithObjects:@"", @"", @"2", nil],
											[NSArray arrayWithObjects:@"2.5", @"5", @"2", nil],
											nil];
	[defaultsParameters retain];
	
	urlHelp = [NSArray arrayWithObjects:	@"http://www.itk.org/Doxygen16/html/classitk_1_1ConnectedThresholdImageFilter.html#_details",
											@"http://www.itk.org/Doxygen16/html/classitk_1_1ConnectedThresholdImageFilter.html#_details",
											@"http://www.itk.org/Doxygen16/html/classitk_1_1NeighborhoodConnectedImageFilter.html#_details",
											@"http://www.itk.org/Doxygen16/html/classitk_1_1ConfidenceConnectedImageFilter.html#_details",
											nil];
	[urlHelp retain];
	
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(mouseViewerDown:)
               name: OsirixMouseDownNotification
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];
	
	[nc addObserver: self
			selector: @selector(drawStartingPoint:)
               name: OsirixDrawObjectsNotification
             object: nil];
	
	return self;
}

-(void) CloseViewerNotification:(NSNotification*) note
{
	if( [note object] == resultsViewer) resultsViewer = nil;
	
	if( [note object] == viewer)
	{
		[[self window] close];
	}
}

- (void) drawStartingPoint:(NSNotification*) note
{
	if([note object] == [viewer imageView])
	{
		if( startingPoint.x != 0 && startingPoint.y != 0)
		{
			NSDictionary	*userInfo = [note userInfo];
			
			CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
            if( cgl_ctx == nil)
                return;
            
			glColor3f (0.0f, 1.0f, 0.5f);
			glLineWidth(2.0 * self.window.backingScaleFactor);
			glBegin(GL_LINES);
			
			float crossx, crossy, scaleValue = [[userInfo valueForKey:@"scaleValue"] floatValue];
			
			crossx = startingPoint.x - [[userInfo valueForKey:@"offsetx"] floatValue];
			crossy = startingPoint.y - [[userInfo valueForKey:@"offsety"] floatValue];
			
			glVertex2f( scaleValue * (crossx - 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx - 5), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 5), scaleValue*(crossy));
			
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-40));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+40));
			glEnd();
		}
	}
}

- (void) mouseViewerDown:(NSNotification*) note
{
	if([note object] == viewer)
	{
		int xpx, ypx, zpx; // coordinate in pixels
		float xmm, ymm, zmm; // coordinate in millimeters
		
		xpx = [[[note userInfo] objectForKey:@"X"] intValue];
		ypx = [[[note userInfo] objectForKey:@"Y"] intValue];
		zpx = [[viewer imageView] curImage];
		
		float location[3];
		[[[viewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location pixelCenter: YES];
		xmm = location[0];
		ymm = location[1];
		zmm = location[2];
		
		[startingPointPixelPosition setStringValue:[NSString stringWithFormat:NSLocalizedString(@"px:\t\tx:%d y:%d", nil), xpx, ypx]];
		[startingPointWorldPosition setStringValue:[NSString stringWithFormat:NSLocalizedString(@"mm:\t\tx:%2.2f y:%2.2f z:%2.2f", nil), xmm, ymm, zmm]];
		[startingPointValue setStringValue:[NSString stringWithFormat:NSLocalizedString(@"value:\t%2.2f", nil), [[[viewer imageView] curDCM] getPixelValueX: xpx Y:ypx]]];
		startingPoint = NSMakePoint(xpx, ypx);
		
		[self preview: viewer];
		
		[[note userInfo] setValue: [NSNumber numberWithBool: YES] forKey: @"stopMouseDown"];
	}
}

- (ViewerController*) duplicateCurrent2DViewerWindow
{
    return [viewer copyViewerWindow];
}

- (void) windowDidLoad
{
	[self fillAlgorithmPopup];
	[self changeAlgorithm:self];
}

-(IBAction) preview:(id) sender
{
	BOOL parametersProvided = YES;
	int p;
	
	float f = [[NSUserDefaults standardUserDefaults] floatForKey: @"growingRegionInterval"];
	int fd = f * 1000.;
	f = fd / 1000.;
	[[NSUserDefaults standardUserDefaults] setFloat: f forKey: @"growingRegionInterval"];
	
	NSString *name = NSLocalizedString( @"Segmentation Preview", nil);
	
	[viewer roiDeleteWithName: name];
	
	if( sender == viewer)
	{
		if( [[growingMode selectedCell] tag] != 1)
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"segmentationDirectlyGenerate"])
				name = [newName stringValue];
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"previewGrowingRegion"] == NO && [[NSUserDefaults standardUserDefaults] boolForKey: @"segmentationDirectlyGenerate"] == NO) return;
	
	for(p=0;p<[params numberOfRows]; p++)
	{
		parametersProvided = parametersProvided && (![[[params cellAtRow:p column:0] stringValue] isEqualToString:@""]);
	}
	
	if (!parametersProvided)
	{
		return;
	}
	
	if ( startingPoint.x == 0 && startingPoint.y == 0)
	{
		return;
	}

	long slice;
	int previousMovieIndex = [viewer curMovieIndex];
	
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"preview3DGrowingRegion"] == NO )
        slice = [[viewer imageView] curImage];
    else
        slice = -1;
	
	for( int i = 0; i < [viewer maxMovieIndex]; i++)
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"growingRegionPropagateIn4D"])
			[viewer setMovieIndex: i];
		
		if( i == [viewer curMovieIndex])
		{
			ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[viewer pixList] :[viewer volumePtr] :slice];
			if( itk)
			{
				// an array for the parameters
				int algo = [[algorithmPopup selectedItem] tag];
				int parametersCount = [[parameters objectAtIndex:algo] count];
				NSMutableArray *parametersArray = [NSMutableArray arrayWithCapacity:parametersCount];
				int i;
				for(i=0; i<parametersCount; i++)
				{
					[parametersArray addObject:[NSNumber numberWithFloat:[[params cellAtRow:i column:0] floatValue]]];
				}
				
				[itk regionGrowing3D	: viewer
										: nil
										: slice
										: startingPoint
										: algo //[[params cellAtIndex: 1] floatValue]
										: parametersArray //[[params cellAtIndex: 2] floatValue]
										: [[pixelsSet cellWithTag:0] state]==NSOnState
										: [[pixelsValue cellWithTag:0] floatValue]
										: [[pixelsSet cellWithTag:1] state]==NSOnState
										: [[pixelsValue cellWithTag:1] floatValue]
										: (ToolMode)[[NSUserDefaults standardUserDefaults] integerForKey: @"growingRegionROIType"]
										: ((long)[roiResolution maxValue] + 1) - [roiResolution intValue]
										: name
										: [[NSUserDefaults standardUserDefaults] boolForKey: @"mergeWithExistingROIs"]
										];
				
				[itk release];
			}
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"growingRegionPropagateIn4D"])
		[viewer setMovieIndex: previousMovieIndex];
}

-(IBAction) compute:(id) sender
{
	BOOL parametersProvided = YES;
	int p;
	
	for(p=0;p<[params numberOfRows]; p++)
	{
		parametersProvided = parametersProvided && (![[[params cellAtRow:p column:0] stringValue] isEqualToString:@""]);
	}
	
	if (!parametersProvided)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segmentation Error", nil), NSLocalizedString(@"Please provide a value for each parameter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	if ( startingPoint.x == 0 && startingPoint.y == 0)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segmentation Error", nil), NSLocalizedString(@"Select a starting point by clicking in the image.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	[viewer roiDeleteWithName: NSLocalizedString( @"Segmentation Preview", nil)];
	
    [viewer addToUndoQueue: @"roi"];
    
	long slice;
	int previousMovieIndex = [viewer curMovieIndex];
	
	if( [[growingMode selectedCell] tag] == 1)
	{
		slice = -1;
	}
	else slice = [[viewer imageView] curImage];

	for( int i = 0; i < [viewer maxMovieIndex]; i++)
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"growingRegionPropagateIn4D"])
			[viewer setMovieIndex: i];
		
		if( i == [viewer curMovieIndex])
		{
			ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[viewer pixList] :[viewer volumePtr] :slice];
			if( itk)
			{
				ViewerController	*v = nil;
				
				if( [[outputResult selectedCell] tag] == 1)
				{
					if( resultsViewer == nil)
					{
						long currentImageIndex = [[viewer imageView] curImage];
						resultsViewer = [self duplicateCurrent2DViewerWindow];
						[[viewer imageView] setIndex:currentImageIndex];
						
						if( [[pixelsSet cellWithTag:1] state] == NSOnState)	// FILL THE IMAGE WITH THE VALUE
						{
							long	i, x;
							float	*dstImage, value = [[pixelsValue cellWithTag:1] floatValue];
							
							for( i = 0; i < [[resultsViewer pixList] count]; i++)
							{
								DCMPix	*curPix = [[resultsViewer pixList] objectAtIndex: i];
								dstImage = [curPix fImage];
								long tot = [curPix pwidth] * [curPix pheight];
								
								for( x = 0; x < tot; x++) 
								{
									*dstImage++ = value;
								}
							}
						}
					}
					
					v = resultsViewer;
				}
				
				// an array for the parameters
				int algo = [[algorithmPopup selectedItem] tag];
				int parametersCount = [[parameters objectAtIndex:algo] count];
				NSMutableArray *parametersArray = [NSMutableArray arrayWithCapacity:parametersCount] ;
				int i;
				for(i=0; i<parametersCount; i++)
				{
					[parametersArray addObject:[NSNumber numberWithFloat:[[params cellAtRow:i column:0] floatValue]]];
				}
				
				[itk regionGrowing3D	: viewer
										: v
										: slice
										: startingPoint
										: algo //[[params cellAtIndex: 1] floatValue]
										: parametersArray //[[params cellAtIndex: 2] floatValue]
										: [[pixelsSet cellWithTag:0] state]==NSOnState
										: [[pixelsValue cellWithTag:0] floatValue]
										: [[pixelsSet cellWithTag:1] state]==NSOnState
										: [[pixelsValue cellWithTag:1] floatValue]
										: (ToolMode)[[NSUserDefaults standardUserDefaults] integerForKey: @"growingRegionROIType"]
										: ((long)[roiResolution maxValue] + 1) - [roiResolution intValue]
										: [newName stringValue]
										: [[NSUserDefaults standardUserDefaults] boolForKey: @"mergeWithExistingROIs"]
										];
						
				if( v)
				{
					float wl, ww;
					
					[v needsDisplayUpdate];
					[[viewer imageView] getWLWW:&wl :&ww];
					[[v imageView] setWLWW:wl :ww];
				}
				
				[itk release];
			}
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"growingRegionPropagateIn4D"])
		[viewer setMovieIndex: previousMovieIndex];
    
    [[viewer window] makeKeyAndOrderFront: self]; //For easier undo/redo on ViewerController
}

- (void) fillAlgorithmPopup
{
	int i;
	NSMenu *items = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	for (i=0; i<[algorithms count]; i++)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];				
		[item setTitle: [algorithms objectAtIndex: i]];
		[item setTag:i];
		[items addItem:item];
	}
	[algorithmPopup removeAllItems];
	[algorithmPopup setMenu:items];
	[algorithmPopup bind:@"selectedIndex" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionAlgorithm" options:nil];
}

- (IBAction) changeAlgorithm: (id) sender
{
	[self setNumberOfParameters: [[parameters objectAtIndex:[[algorithmPopup selectedItem] tag]] count]];

	int algorithmType = [[algorithmPopup selectedItem] tag];
	NSArray *titles= [parameters objectAtIndex:algorithmType];
	NSArray *defaultValues = [defaultsParameters objectAtIndex:algorithmType];
	NSFormCell *cell = nil;
	switch (algorithmType)
	{
		case intervalSegmentationType:	
				cell = [params cellAtRow:0 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:0]];
				[cell setStringValue:[defaultValues objectAtIndex:0]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionInterval" options:nil];	
				break;								
		case thresholdSegmentationType:
				cell = [params cellAtRow:0 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:0]];
				[cell setStringValue:[defaultValues objectAtIndex:0]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionLowerThreshold" options:nil];	
				
				cell = [params cellAtRow:1 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:1]];
				[cell setStringValue:[defaultValues objectAtIndex:1]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionUpperThreshold" options:nil];	
				break;	
				
		case neighborhoodSegmentationType:
		
				cell = [params cellAtRow:0 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:0]];
				[cell setStringValue:[defaultValues objectAtIndex:0]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionLowerThreshold" options:nil];	
				
				cell = [params cellAtRow:1 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:1]];
				[cell setStringValue:[defaultValues objectAtIndex:1]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionUpperThreshold" options:nil];
				
				cell = [params cellAtRow:2 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:2]];
				[cell setStringValue:[defaultValues objectAtIndex:2]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionRadius" options:nil];

				break;
		case confidenceSegmentationType:
		
				cell = [params cellAtRow:0 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:0]];
				[cell setStringValue:[defaultValues objectAtIndex:0]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionMultiplier" options:nil];	
				
				cell = [params cellAtRow:1 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:1]];
				[cell setStringValue:[defaultValues objectAtIndex:1]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionIterations" options:nil];
				
				cell = [params cellAtRow:2 column:0] ;
				[cell setTitleWidth:-1];
				[cell setTitle:[titles objectAtIndex:2]];
				[cell setStringValue:[defaultValues objectAtIndex:2]];
				[cell bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.growingRegionRadius" options:nil];
		break;
	}
	
	/*
	for(i=0; i<[[parameters objectAtIndex:[[algorithmPopup selectedItem] tag]] count]; i++)
	{
		[[params cellAtRow:i column:0] setTitleWidth:-1];
		[[params cellAtRow:i column:0] setTitle:[[parameters objectAtIndex:[[algorithmPopup selectedItem] tag]] objectAtIndex:i]];
		[[params cellAtRow:i column:0] setStringValue:[[defaultsParameters objectAtIndex:[[algorithmPopup selectedItem] tag]] objectAtIndex:i]];
	}
	*/
	[self preview: self];
}

- (void) setNumberOfParameters: (int) n
{
    params.translatesAutoresizingMaskIntoConstraints = YES;
    
	NSRect frameBefore = [params frame];
	// change the number of field in the matrix
	while (!([params numberOfRows]==0))
		[params removeRow:0];
	while (!([params numberOfRows]==n))
		[params addRow];
	// adjust the size of the matrix
	[params sizeToCells];
	NSRect frameAfter = [params frame];
	float deltaY = frameBefore.size.height - frameAfter.size.height;
	frameAfter.origin.y = frameBefore.origin.y + deltaY;
	[params setFrame:frameAfter];
//
    if( [[self.window.contentView constraints] count] == 0) //backward compatibility : prior auto-layout xib
    {
        NSDisableScreenUpdates();
        
    //	//adjust the size of the parameters box
        NSRect parametersBoxFrameBefore = [parametersBox frame];
        [parametersBox setContentViewMargins:NSMakeSize(4, 12)];
        [parametersBox sizeToFit];
        [parametersBox setFrame: NSMakeRect( parametersBoxFrameBefore.origin.x, [parametersBox frame].origin.y, parametersBoxFrameBefore.size.width, [parametersBox frame].size.height) ];
        
        // frames
        NSRect parametersBoxFrame = [parametersBox frame];
        NSRect resultsBoxFrame = [resultsBox frame];
        NSRect computeButtonFrame = [computeButton frame];
        
        //adjust the size & position of the window
        NSRect windowFrame = [[self window] frame];
        float newWindowHeight = parametersBoxFrame.size.height+resultsBoxFrame.size.height+computeButtonFrame.size.height+20+15;
        float deltaHeight = newWindowHeight-windowFrame.size.height;
        windowFrame.origin.y -= deltaHeight;
        windowFrame.size.height = newWindowHeight;
        [[self window] setFrame:windowFrame display:NO];
        
        //adjust the position of the parameters box
        parametersBoxFrame.origin.y = windowFrame.size.height - parametersBoxFrame.size.height - 20;
        [parametersBox setFrame:parametersBoxFrame];

        //adjust the position of the results box and the compute button
        resultsBoxFrame.origin.y = parametersBoxFrame.origin.y - resultsBoxFrame.size.height - 5;
        [resultsBox setFrame:resultsBoxFrame];
        computeButtonFrame.origin.y = resultsBoxFrame.origin.y - computeButtonFrame.size.height - 5;
        [computeButton setFrame:computeButtonFrame];
        
        [[self window] display];
        
        NSEnableScreenUpdates();
    }
}

- (IBAction) algorithmGetHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlHelp objectAtIndex:[[algorithmPopup selectedItem] tag]]]];
}
@end
