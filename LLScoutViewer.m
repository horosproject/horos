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

#import "LLScoutViewer.h"
#import "LLScoutView.h"
#import "LLScoutOrthogonalReslice.h"
#import "Notifications.h"

#import "LLMPRViewer.h"

@implementation LLScoutViewer

+ (BOOL)haveSamePixelSpacing:(NSArray*)pixA :(NSArray*)pixB;
{
	float pixSpacingAx = [[pixA objectAtIndex:0] pixelSpacingX];
	float pixSpacingAy = [[pixA objectAtIndex:0] pixelSpacingY];
	float pixSpacingBx = [[pixB objectAtIndex:0] pixelSpacingX];
	float pixSpacingBy = [[pixB objectAtIndex:0] pixelSpacingY];
	
	return ((pixSpacingAx == pixSpacingBx) && (pixSpacingAy == pixSpacingBy));
}

+ (BOOL)haveSameImagesCount:(NSArray*)pixA :(NSArray*)pixB;
{
	int imageCountA = [pixA count];
	int imageCountB = [pixB count];
	
	return (imageCountA == imageCountB);
}

+ (BOOL)haveSameImagesLocations:(NSArray*)pixA :(NSArray*)pixB;
{
	BOOL sameLocations = YES;
	int i;
	
	for(i=0; i<[pixA count] && sameLocations; i++)
	{
		sameLocations = sameLocations && ([[pixA objectAtIndex:i] sliceLocation] == [[pixB objectAtIndex:i] sliceLocation]);
		if (!sameLocations)
			NSLog(@"i:%d pixA:%f pixB:%f", i, [[pixA objectAtIndex:i] sliceLocation], [[pixB objectAtIndex:i] sliceLocation]);
	}
	
	return sameLocations;
}

+ (BOOL)verifyRequiredConditions:(NSArray*)pixA :(NSArray*)pixB;
{
	NSMutableString *alertMessage = [NSMutableString stringWithString: NSLocalizedString( @"The two series must have:", nil) ];
	
	BOOL samePixelSpacing, sameImagesCount, sameImagesLocations=NO;
	samePixelSpacing = [LLScoutViewer haveSamePixelSpacing:pixA :pixB];
	sameImagesCount = [LLScoutViewer haveSameImagesCount:pixA :pixB];
		
	if(!samePixelSpacing)
		[alertMessage appendString: NSLocalizedString( @"\n - the same pixels spacing", nil)];
	
	if(!sameImagesCount)
		[alertMessage appendString: NSLocalizedString( @"\n - the same number of images", nil)];
	else
	{
		sameImagesLocations = [LLScoutViewer haveSameImagesLocations:pixA :pixB];
		if(!sameImagesLocations)
			[alertMessage appendString:NSLocalizedString(  @"\n - the same location for each image", nil)];
	}
	
	BOOL error = !samePixelSpacing || !sameImagesCount || !sameImagesLocations;
	
	if(error)
		NSRunAlertPanel(NSLocalizedString(@"Error", nil),  alertMessage, NSLocalizedString(@"OK", nil), nil, nil);
	
	return !error;
}

- (id)initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC;
{
	self = [super initWithWindowNibName:@"LLScoutView"];
	[[self window] setDelegate:self];
	[[self window] setShowsResizeIndicator:NO];
		
	// initialisations
	dcmPixList = [pix retain];
	dcmFileList = [files retain];

	[mprController initWithPixList: pix : files : vData : vC : bC: self];
	
	//[[mprController xReslicedView] adjustWLWW:400 :1200];
//	[[NSNotificationCenter defaultCenter] removeObserver:mprController name: OsirixChangeWLWWNotification object: nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:[mprController originalView] name: OsirixChangeWLWWNotification object: nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:[mprController xReslicedView] name: OsirixChangeWLWWNotification object: nil];
//	[[NSNotificationCenter defaultCenter] removeObserver:[mprController yReslicedView] name: OsirixChangeWLWWNotification object: nil];
	
	LLScoutOrthogonalReslice *reslicer = [[LLScoutOrthogonalReslice alloc] initWithOriginalDCMPixList: pix];
	[mprController setReslicer:reslicer];
	[reslicer release];
	[(LLScoutView*)[mprController xReslicedView] setIsFlipped: [[vC imageView] flippedData]];

	viewer = vC;
	blendingViewer = bC;

	[[NSNotificationCenter defaultCenter] removeObserver:self name: OsirixUpdateWLWWMenuNotification object: nil];	
	[[NSNotificationCenter defaultCenter] removeObserver:mprController name: OsirixUpdateWLWWMenuNotification object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver:[mprController originalView] name: OsirixUpdateWLWWMenuNotification object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver:[mprController xReslicedView] name: OsirixUpdateWLWWMenuNotification object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver:[mprController yReslicedView] name: OsirixUpdateWLWWMenuNotification object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:OsirixCloseViewerNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseMPRViewerNotification:) name:NSWindowWillCloseNotification object:nil];
	
	return self;
}

-(void)dealloc
{
	NSLog(@"Scout Viewer dealloc");
//	if(mprViewerTop)[mprViewerTop release];
//	if(mprVieweMiddle)[mprVieweMiddle release];
//	if(mprViewerBottom)[mprViewerBottom release];

	[dcmPixList release];
	[dcmFileList release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
//	if(mprViewerTop)[[mprViewerTop window] close];
//	if(mprVieweMiddle)[[mprVieweMiddle window] close];
//	if(mprViewerBottom)[[mprViewerBottom window] close];

	[[self window] setAcceptsMouseMovedEvents: NO];
	
	NSWindow *w;
	if(mprViewerTop)
	{
		w = [mprViewerTop window];
		[mprViewerTop release];
		mprViewerTop = nil;
		[w close];
	}
	if(mprVieweMiddle)
	{
		w = [mprVieweMiddle window];
		[mprVieweMiddle release];
		mprVieweMiddle = nil;
		[w close];
	}
	if(mprViewerBottom)
	{
		w = [mprViewerBottom window];
		[mprViewerBottom release];
		mprViewerBottom = nil;
		[w close];
	}

	[self autorelease];
}

- (IBAction) showWindow:(id)sender
{
	NSRect screenRect = [[[self window] screen] frame];
	NSRect windowRect = [[self window] frame];
	windowRect.size.height = screenRect.size.height;
	windowRect.origin.x = 0;
	[[self window] setFrame:windowRect display:YES animate:NO];
	
	[super showWindow:sender];
	
	[mprController showViews:sender];
	[mprController setThickSlabMode:2];
	[mprController setThickSlab:[[[mprController originalDCMPixList] objectAtIndex:0] pheight]/8.0*([[[mprController originalDCMPixList] objectAtIndex:0] pixelSpacingY]/[[[mprController originalDCMPixList] objectAtIndex:0] sliceInterval])];
	[[mprController xReslicedView] setCurrentTool:tWL];
	[[mprController xReslicedView] scaleToFit];
	[mprController setWLWW:400 :1200];
	
	[[mprController originalView] setFusion:0 :1];
	[[mprController originalView] setThickSlabXY:0 :0];
	
	[self setTopLimit:(int)[dcmPixList count]*0.66 bottomLimit:(int)[dcmPixList count]*0.33];
}

- (BOOL)is2DViewer;
{
	return NO;
}

- (void)setTopLimit:(int)top bottomLimit:(int)bottom;
{
//	NSLog(@"setTopLimit:%d bottomLimit:%d", top, bottom);
	
	int newTopLimit, newBottomLimit;
	
//	if([self isStackUpsideDown])
//	{
//		newTopLimit = [dcmPixList count] - top;
//		newBottomLimit = [dcmPixList count] - bottom;
//	}
//	else
//	{
		newTopLimit = top;
		newBottomLimit = bottom;
//	}
	
	BOOL topChanged = newTopLimit != topLimit;
	BOOL bottomChanged = newBottomLimit != bottomLimit;
	
	if(topChanged)
	{
		topLimit = newTopLimit;
		[(LLScoutView*)[mprController xReslicedView] setTopLimit:topLimit];
		[[mprController xReslicedView] setNeedsDisplay:YES];
	}
	if(bottomChanged)
	{
		bottomLimit = newBottomLimit;
		[(LLScoutView*)[mprController xReslicedView] setBottomLimit:bottomLimit];
		[[mprController xReslicedView] setNeedsDisplay:YES];
	}
	
	NSWindow *w;
	if(mprViewerTop && topChanged)
	{
		w = [mprViewerTop window];
		[mprViewerTop release];
		mprViewerTop = nil;
		[w close];
	}
	if(mprVieweMiddle && (topChanged || bottomChanged))
	{
		w = [mprVieweMiddle window];
		[mprVieweMiddle release];
		mprVieweMiddle = nil;
		[w close];
	}
	if(mprViewerBottom && bottomChanged)
	{
		w = [mprViewerBottom window];
		[mprViewerBottom release];
		mprViewerBottom = nil;
		[w close];
	}
}

- (void)displayMPR:(int)index;
{
	NSRange pixRange;
	LLMPRViewer *llViewer;
	
//	NSLog(@"topLimit: %d, bottomLimit: %d",topLimit, bottomLimit);
//	NSLog(@"[[mprController originalDCMPixList] count]: %d",[[mprController originalDCMPixList] count]);
//	NSLog(@"[dcmPixList count]: %d",[dcmPixList count]);
//	NSLog(@"index: %d",index);

	if([self isStackUpsideDown])
		NSLog(@"isStackUpsideDown : YES");
	else
		NSLog(@"isStackUpsideDown : NO");

	if(index==0)
	{
		if([[viewer imageView] flippedData])
		{
			pixRange.location = topLimit;
			pixRange.length = [dcmPixList count] - topLimit;
		}
		else if([self isStackUpsideDown])
		{
//			pixRange.location = topLimit;
//			pixRange.length = [[mprController originalDCMPixList] count] - topLimit;
			pixRange.location = [dcmPixList count] - topLimit;
			pixRange.length = topLimit - bottomLimit;
		}
		else
		{
			pixRange.location = 0;
			pixRange.length = topLimit;
		}
		llViewer = mprViewerTop;
	}
	else if(index==1)
	{
		if([[viewer imageView] flippedData])
		{
			pixRange.location = bottomLimit;
			pixRange.length = topLimit - bottomLimit;
		}
		else if([self isStackUpsideDown])
		{
//			pixRange.location = bottomLimit;
//			pixRange.length = topLimit - bottomLimit;
			pixRange.location = [dcmPixList count] - bottomLimit; //topLimit;
			pixRange.length = bottomLimit; //[dcmPixList count] - topLimit;
		}
		else
		{
			pixRange.location = topLimit;
			pixRange.length = bottomLimit - topLimit;
		}
		llViewer = mprVieweMiddle;
	}
	else
	{
		if([[viewer imageView] flippedData])
		{
			pixRange.location = 0;
			pixRange.length = bottomLimit;
		}
		else if([self isStackUpsideDown])
		{
//			pixRange.location = 0;
//			pixRange.length = bottomLimit;
			pixRange.location = 0;
			pixRange.length = [dcmPixList count] - topLimit;
		}
		else
		{
			pixRange.location = bottomLimit;
			pixRange.length = [[mprController originalDCMPixList] count] - bottomLimit;
		}
		llViewer = mprViewerBottom;
	}

	NSArray *originalPix, *injectedPix, *originalFiles;
	//NSLog(@"pixRange.location: %d, pixRange.length: %d",pixRange.location, pixRange.length);
	originalPix = [dcmPixList subarrayWithRange:pixRange];
	injectedPix = [[blendingViewer pixList:0] subarrayWithRange:pixRange];
	originalFiles = [dcmFileList subarrayWithRange:pixRange];

	if(llViewer)
	{	
		NSWindow *w = [llViewer window];
		//[llViewer release];
 		//llViewer = nil;
		[w close];	
		llViewer = nil;
	}
	
	if(mprViewerTop)
	{	
		NSWindow *w = [mprViewerTop window];
		[w close];	
		mprViewerTop = nil;
	}
	if(mprVieweMiddle)
	{	
		NSWindow *w = [mprVieweMiddle window];
		[w close];	
		mprVieweMiddle = nil;
	}
	if(mprViewerBottom)
	{	
		NSWindow *w = [mprViewerBottom window];
		[w close];	
		mprViewerBottom = nil;
	}	
	
	if(index==0)
	{
		mprViewerTop = [[LLMPRViewer alloc] initWithPixList:originalPix :injectedPix :originalFiles :nil :viewer :blendingViewer :self];
		llViewer = mprViewerTop;
	}
	else if(index==1)
	{
		mprVieweMiddle = [[LLMPRViewer alloc] initWithPixList:originalPix :injectedPix :originalFiles :nil :viewer :blendingViewer :self];
		llViewer = mprVieweMiddle;
	}
	else
	{
		mprViewerBottom = [[LLMPRViewer alloc] initWithPixList:originalPix :injectedPix :originalFiles :nil :viewer :blendingViewer :self];
		llViewer = mprViewerBottom;
	}
	float wl, ww;
	[[mprController xReslicedView] getWLWW:&wl :&ww];

	//[llViewer retain];
	[llViewer setPixListRange:pixRange];
	[llViewer showWindow:self];
	[llViewer setWLWW:wl :ww];
}

- (void)toggleDisplayResliceAxes;{}
- (void)blendingPropagateOriginal:(OrthogonalMPRView*)sender;{}
- (void)blendingPropagateX:(OrthogonalMPRView*)sender;{}
- (void)blendingPropagateY:(OrthogonalMPRView*)sender;{}

- (void)CloseViewerNotification:(NSNotification*)note;
{
	ViewerController *v = [note object];
	
	if([v pixList] == [mprController originalDCMPixList])
	{
		[[self window] performClose: self];
		return;
	}
}

- (void)CloseMPRViewerNotification:(NSNotification*)note;
{
	//NSLog(@"CloseMPRViewerNotification");
	if(mprViewerTop)
	{
	//NSLog(@"mprViewerTop");
		if([[note object] isEqual:[mprViewerTop window]])
		{
		//NSLog(@"window");
			[mprViewerTop release];
			mprViewerTop = nil;
			return;
		}
	}
	if(mprVieweMiddle)
	{
	//NSLog(@"mprVieweMiddle");
		if([[note object] isEqual:[mprVieweMiddle window]])
		{
		//NSLog(@"window");
			[mprVieweMiddle release];
			mprVieweMiddle = nil;
			return;
		}
	}
	if(mprViewerBottom)
	{
	//NSLog(@"mprViewerBottom");
		if([[note object] isEqual:[mprViewerBottom window]])
		{
		//NSLog(@"window");
			[mprViewerBottom release];
			mprViewerBottom = nil;
			return;
		}
	}	
}

- (BOOL)isStackUpsideDown;
{
	if( [dcmPixList count] > 1)
	{
//		NSLog(@"- (BOOL)isStackUpsideDown;");
//		NSLog(@"[[dcmPixList objectAtIndex:0] sliceLocation] : %f", [[dcmPixList objectAtIndex:0] sliceLocation]);
//		NSLog(@"[[dcmPixList objectAtIndex:1] sliceLocation] : %f", [[dcmPixList objectAtIndex:1] sliceLocation]);
		
		//if(![[viewer imageView] flippedData])
			return ([[dcmPixList objectAtIndex:0] sliceLocation] - [[dcmPixList objectAtIndex:1] sliceLocation] < 0);
		//else
		//	return ([[dcmPixList objectAtIndex:0] sliceLocation] - [[dcmPixList objectAtIndex:1] sliceLocation] > 0);
	}
	else return NO;
}

@end
