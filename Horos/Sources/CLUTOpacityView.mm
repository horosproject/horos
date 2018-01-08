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

#import "CLUTOpacityView.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "Notifications.h"

@implementation CLUTOpacityView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		backgroundColor = [[NSColor blackColor] retain];
		histogramOpacity = 0.25;
		histogramColor = [[NSColor lightGrayColor] retain];
		pointsColor = [[NSColor blackColor] retain];
		pointsBorderColor = [[NSColor blackColor] retain];
		textLabelColor = [[NSColor whiteColor] retain];
		selectedPointColor = [[NSColor whiteColor] retain];
		curveColor = [[NSColor grayColor] retain];
		
		HUmin = -100000.0;
		HUmax = 100000.0;
		curves = [[NSMutableArray array] retain];
		pointColors = [[NSMutableArray array] retain];
		selectedPoint.y = -1.0;
		pointDiameter = 8;
		lineWidth = 3;
		pointBorder = 2;
		zoomFactor = 1.0;
		zoomFixedPoint = 0.0;
		vrViewLowResolution = NO;
		didResizeVRVIew = NO;
		mousePositionX = 0.0;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePointColor:) name:NSColorPanelColorDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(computeHistogram:) name:OsirixUpdateVolumeDataNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];
        
		[self createContextualMenu];
		undoManager = [[NSUndoManager alloc] init];
		
		[self updateView];
    }
    return self;
}

- (void)windowWillCloseNotification:(NSNotification*)notification;
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(setCLUTtoVRViewHighRes) object: nil];
    
	if( [notification object] == vrViewWindow)
		windowWillClose = YES;
}

- (void)cleanup;
{
	if(curves) [curves release];
	curves = [[NSMutableArray array] retain];
	if(pointColors) [pointColors release];
	pointColors = [[NSMutableArray array] retain];
	if( histogram)
	{
		free( histogram);
		histogram = nil;
	}
	didResizeVRVIew = NO;
	[self updateView];
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(setCLUTtoVRViewHighRes) object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[curves release];
	curves = nil; // IMPORTANT - used in setCLUTtoVRViewHighRes to detect if the object was destroy
	
	if(histogram) free(histogram);
	[pointColors release];
	[selectedPointColor release];
	[contextualMenu release];
	[undoManager release];

	[backgroundColor release];
	[histogramColor release];
	[pointsColor release];
	[pointsBorderColor release];
	[textLabelColor release];
	[selectedPointColor release];
	[curveColor release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Contextual menu

- (void)createContextualMenu;
{
	contextualMenu = [[NSMenu alloc] init];
	[contextualMenu addItemWithTitle:NSLocalizedString(@"New Curve", nil) action:@selector(newCurve:) keyEquivalent:@""];
	[contextualMenu addItemWithTitle:NSLocalizedString(@"Send to back", nil) action:@selector(sendToBack:) keyEquivalent:@""];
	[contextualMenu addItemWithTitle:NSLocalizedString(@"Remove All Curves", nil) action:@selector(removeAllCurves:) keyEquivalent:@""];
	[contextualMenu addItem:[NSMenuItem separatorItem]];
	[contextualMenu addItemWithTitle:NSLocalizedString(@"Save...", nil) action:@selector(chooseNameAndSave:) keyEquivalent:@""];
}

#pragma mark -
#pragma mark Histogram

- (void)setVolumePointer:(float*)ptr width:(int)width height:(int)height numberOfSlices:(int)n;
{
	volumePointer = ptr;
	voxelCount = width * height * n;
}

- (void)setHUmin:(float)min HUmax:(float)max;
{
	if( max - min < 1)
		max = min + 1;
	
	HUmin = min;
	HUmax = max;
}

- (void)callComputeHistogram
{
	protectionAgainstReentry = 0;
	[self computeHistogram];
}

- (void)computeHistogram;
{
    if( windowWillClose)
        return;
    
    vrViewWindow = [vrView window];
    
	vImage_Buffer buffer;
	buffer.data = volumePointer;
	buffer.height = 1;
	buffer.width = voxelCount;
	buffer.rowBytes = voxelCount * sizeof(float);
	
	histogramSize = (int)((HUmax-HUmin)/2);
	histogramSize++;
	if( histogramSize < 100)
		histogramSize = 100;
	
	if(histogram) free(histogram);
	
	histogram = (vImagePixelCount*) malloc(sizeof(vImagePixelCount) * ((histogramSize+100)*2L));
	if( histogram && buffer.data)
	{
		vImageHistogramCalculation_PlanarF( &buffer, histogram, histogramSize, HUmin, HUmax, kvImageDoNotTile);
		
		int i;
		vImagePixelCount min = histogram[0], max = 0;
		
		for(i=0; i<histogramSize; i++)
		{
			if(histogram[i]<min) min = histogram[i];
			if(histogram[i]>max) max = histogram[i];
		}

		float temp;
		for(i=0; i<histogramSize; i++)
		{
			temp = ((float)(histogram[i] - min) / (float)max)*10000.0;
			if (temp >= 1)
				histogram[i] = (vImagePixelCount)(log(temp)*1000);
			else
				histogram[i] = (vImagePixelCount)temp;
		}
	}
	
	if( protectionAgainstReentry++ > 20)
		return;
	
	[self simplifyHistogram];
}

- (void)simplifyHistogram;
{
	if(!histogram) return;
	if(histogramSize==0) return;
	
	vImagePixelCount sum = 0;
	for (int i=0 ; i<histogramSize; i++)
	{
		sum += histogram[i];
	}
	
	if(sum<=100) return;
	
	int maxBin = histogramSize-1;
	float binWidth = (HUmax - HUmin) / histogramSize;
	float newHUmax;

	for (int i=histogramSize-2; i>=0; i--)
	{
		if(histogram[i]<=10)
		{
			maxBin=i;
			newHUmax = HUmin+binWidth*i*1.5; // factor 1.5 is for tunning
		}
		else i=-1;
	}
	
	if(maxBin < histogramSize-2)
	{
		if(newHUmax >= HUmax) return;
		[self setHUmin:HUmin HUmax:newHUmax];
		[self computeHistogram];
	}
}

- (void)drawBinHistogramInRect:(NSRect)rect;
{
	int i, max = 0;
	for(i=2; i<histogramSize; i++)
	{
		if(histogram[i]>max) max = histogram[i];
	}
		
	float heightFactor = (max==0)? 1 : rect.size.height / max;
	
	NSRect *rects = (NSRect*) malloc(sizeof(NSRect) * histogramSize);
	float binWidth = rect.size.width / histogramSize;
	for(i=0; i<histogramSize; i++)
	{
		rects[i] = NSMakeRect(i * binWidth, 0, binWidth, histogram[i] * heightFactor);
	}
	
	[histogramColor set];
	NSRectFillList(rects, histogramSize);
	
	free( rects);
}

- (void)drawHistogramInRect:(NSRect)rect;
{
	NSAffineTransform *transform = [self transform];
	
	int i;
	vImagePixelCount max = 0;
	for(i=0; i<histogramSize; i++)
	{
		if(histogram[i]>max) max = histogram[i];
	}

	float heightFactor = (max==0)? 1.0 : 1.0 / max;
	float binWidth = (HUmax - HUmin) / histogramSize;

	NSBezierPath *line = [NSBezierPath bezierPath];

	[line moveToPoint:[transform transformPoint:NSMakePoint(HUmin, 0.0)]];
	for(i=0; i<histogramSize; i++)
	{
		NSPoint pt = NSMakePoint(HUmin + i * binWidth, histogram[i] * heightFactor);
		NSPoint ptInView = [transform transformPoint:pt];
		[line lineToPoint:ptInView];
		
		if(mousePositionX > pt.x-1 && mousePositionX < pt.x+1)
		{
			NSRect dotFrame = NSMakeRect(ptInView.x-3, ptInView.y-3, 6, 6);
			NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:dotFrame];
			NSColor *cDot = [histogramColor colorWithAlphaComponent:histogramOpacity*3.0];
			[cDot set];
			[dot fill];
		}
	}
	
	NSPoint pt = NSMakePoint(HUmax,0.0);
	pt = [transform transformPoint:pt];
	[line lineToPoint:pt];
		
	[line closePath];
	NSColor *c = [histogramColor colorWithAlphaComponent:histogramOpacity];
	[c set];
	[line fill];
	c = [histogramColor colorWithAlphaComponent:histogramOpacity*2.0];
	[c set];
	[line setLineWidth:1.0];
	[line stroke];
}

#pragma mark -
#pragma mark Curves

- (void)newCurve;
{
	NSMutableArray *theNewCurve = [NSMutableArray arrayWithCapacity:4];

	NSPoint pt1, pt2, pt3, pt4;
	
	pt1 = NSMakePoint(12, 0.0);
	pt2 = NSMakePoint(202, sqrt(0.027));
	pt3 = NSMakePoint(404, sqrt(0.133));
	pt4 = NSMakePoint(549, sqrt(0.682));

	float shift = 40.0;

	if(pt1.x<HUmin || pt4.x>HUmax)
	{
		float middle = (HUmin + HUmax)/2.0;
		float length = HUmax - HUmin;
		pt1.x = middle - 0.05*length;
		pt2.x = middle;
		pt3.x = middle + 0.05*length;
		pt4.x = middle + 0.1*length;
		shift = 0.01*length;
	}
	
	BOOL needsShift = NO;
	NSPoint c1, c2;
	for( int i = 0; i < [curves count]; i++)
	{
		c1 = [[[curves objectAtIndex:i] objectAtIndex:0] pointValue];
		c2 = [[[curves objectAtIndex:i] lastObject] pointValue];
		needsShift = (pt1.x>c1.x-shift && pt1.x<c1.x+shift) || (pt4.x>c2.x-shift && pt4.x<c2.x+shift);
		
		if(needsShift)
		{
			pt1.x += shift;
			pt2.x += shift;
			pt3.x += shift;
			pt4.x += shift;
			i=-1;
			needsShift = NO;
		}
	}
	
	[theNewCurve addObject:[NSValue valueWithPoint:pt1]];
	[theNewCurve addObject:[NSValue valueWithPoint:pt2]];
	[theNewCurve addObject:[NSValue valueWithPoint:pt3]];
	[theNewCurve addObject:[NSValue valueWithPoint:pt4]];
	
	NSMutableArray *theColors = [NSMutableArray arrayWithCapacity:4];
	[theColors addObject:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
	[theColors addObject:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
	[theColors addObject:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.0 alpha:1.0]];
	[theColors addObject:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
	
	[self addCurveAtindex:0 withPoints:theNewCurve colors:theColors];
	
	// select the new curve
	NSPoint controlPoint = [self controlPointForCurveAtIndex:0];
	selectedPoint = controlPoint;
	
	nothingChanged = NO;
	clutChanged = YES;
	vrViewLowResolution = NO;
	[self updateView];
}

//- (void)fillCurvesInRect:(NSRect)rect;
//{
//	int i, j;
//		
//	NSAffineTransform* transform = [self transform];
//	
//	for (i=[curves count]-1; i>=0; i--)
//	{
//		NSArray *aCurve = [curves objectAtIndex:i];
//
//		// GRADIENT FILL
//		NSRect smallRect;
//		NSPoint p0, p1;
//		NSColor *c, *c0, *c1;
//		for (j=0; j<[aCurve count]-1; j++)
//		{
//			p0 = [transform transformPoint:[[aCurve objectAtIndex:j] pointValue]];
//			p1 = [transform transformPoint:[[aCurve objectAtIndex:j+1] pointValue]];
//			c0 = [[pointColors objectAtIndex:i] objectAtIndex:j];
//			c1 = [[pointColors objectAtIndex:i] objectAtIndex:j+1];
//			int numberOfSmallRect = p1.x - p0.x + 1;
//			int n;
//			for(n=0; n<numberOfSmallRect; n++)
//			{
//				if(p0.y<p1.y)
//					smallRect = NSMakeRect(p0.x+n, 0, 2, ((numberOfSmallRect-n)*p0.y+n*p1.y)/numberOfSmallRect);
//				else
//					smallRect = NSMakeRect(p0.x+n-1, 0, 2, ((numberOfSmallRect-n)*p0.y+n*p1.y)/numberOfSmallRect);
//					
//				c = [c0 blendedColorWithFraction:(float)n/(float)numberOfSmallRect ofColor:c1];
//				[c set];
//				NSRectFill(smallRect);
//			}
//		}
//	}
//}

- (void)fillCurvesInRect:(NSRect)rect;
{	
	NSAffineTransform* transform = [self transform];
	
	for (int i=(long)[curves count]-1; i>=0; i--)
	{
		NSArray *aCurve = [curves objectAtIndex:i];

		CGFloat *locations = (CGFloat*)malloc(sizeof(CGFloat)*[aCurve count]); // for NSGradient
		
		NSBezierPath *line = [NSBezierPath bezierPath];
		NSPoint p0 = [[aCurve objectAtIndex:0] pointValue];
		[line moveToPoint:NSMakePoint(p0.x, 0.0)];
		
		float minX = [[aCurve objectAtIndex:0] pointValue].x;
		float maxX = [[aCurve lastObject] pointValue].x;
		float d = maxX - minX;
		
		// construct path & locations
		NSPoint pt;
		for (int j=0; j<[aCurve count]; j++)
		{
			pt = [[aCurve objectAtIndex:j] pointValue];
			locations[j] = (pt.x-minX) / d;
			[line lineToPoint:pt];
		}
		
		// close path
		NSPoint pt_closing = [[aCurve lastObject] pointValue];
		pt_closing.y = 0.0;
		[line lineToPoint:pt_closing];
		[line closePath];
		line = [transform transformBezierPath:line];
		
		// GRADIENT FILL
		NSGradient *gradient = [[NSGradient alloc] initWithColors:[pointColors objectAtIndex:i] atLocations:locations colorSpace:[NSColorSpace genericRGBColorSpace]];
		[gradient drawInBezierPath:line angle:0];
		[gradient release];
		
		free( locations);
	}
}

- (void)drawCurvesInRect:(NSRect)rect;
{
	int i, j;
		
	NSAffineTransform* transform = [self transform];
	
	for (i=(long)[curves count]-1; i>=0; i--)
	{
		NSArray *aCurve = [curves objectAtIndex:i];
	
		// CONTROL POINT SELECTED?
		NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
		BOOL controlPointSelected = NO;
		if([self isAnyPointSelected])
		{
			if((int) selectedPoint.x==(int) controlPoint.x && (float) selectedPoint.y==(float) controlPoint.y)
			{
				[selectedPointColor set];
				controlPointSelected = YES;
			}
		}
		
		// LINE
		NSBezierPath *line = [NSBezierPath bezierPath];
		[line moveToPoint:[[aCurve objectAtIndex:0] pointValue]];
		for (j=1; j<[aCurve count]; j++)
		{
			NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
			[line lineToPoint:pt];
		}
		line = [transform transformBezierPath:line];
		[curveColor set];
		if(controlPointSelected) [selectedPointColor set];
		[line setLineWidth:lineWidth];
		[line stroke];
				
		// CONTROL POINT (DRAW)
		NSRect frame = NSMakeRect(controlPoint.x-pointDiameter*0.5, controlPoint.y-pointDiameter*0.5, pointDiameter, pointDiameter);
		NSBezierPath *control = [NSBezierPath bezierPathWithRect:frame];
		[control setLineWidth:pointBorder];
		[pointsColor set];
		[control fill];
		[curveColor set];
		if(controlPointSelected) [selectedPointColor set];
		[control stroke];
		
		// DOTS
		NSPoint selectedPointForLabel = NSMakePoint(-1.0, -1.0);
		
		for (j=0; j<[aCurve count]; j++)
		{
			NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
			BOOL selected = NO;
			if([self isAnyPointSelected])
			{
				if((int) selectedPoint.x==(int) pt.x && (float) selectedPoint.y==(float) pt.y)
				{
					selected = YES;
				}
			}
			//border
			NSPoint pt1 = [transform transformPoint:pt];
			NSRect frame1 = NSMakeRect(pt1.x-pointDiameter*0.5-pointBorder, pt1.y-pointDiameter*0.5-pointBorder, pointDiameter+2*pointBorder, pointDiameter+2*pointBorder);
			NSBezierPath *dot1 = [NSBezierPath bezierPathWithOvalInRect:frame1];
			[pointsColor set];
			[dot1 stroke];
			[curveColor set];
			if(selected || controlPointSelected) [selectedPointColor set];
			[dot1 fill];
				
			//inside
			NSPoint pt2 = [transform transformPoint:pt];
			NSRect frame = NSMakeRect(pt2.x-pointDiameter*0.5, pt2.y-pointDiameter*0.5, pointDiameter, pointDiameter);
			NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:frame];

			[pointsColor set];
			[dot stroke];
            NSColor *c = [[pointColors objectAtIndex:i] objectAtIndex:j];
			[c set];
			[dot fill];
			
			if(selected) selectedPointForLabel = pt;
		}
		
		// LABEL FOR SELECTED POINT
		if(selectedPointForLabel.y>=0.0)[self drawPointLabelAtPosition:selectedPointForLabel];
		
		// LABEL FOR ALL POINTS
		if(controlPointSelected)
		{
			int maxYIndex = -1;
			int minYIndex = -1;
			float minY = 1.0;
			float maxY = 0.0;
			NSPoint currentPoint;
			for (j=0; j<[aCurve count]; j++)
			{
				currentPoint = [[aCurve objectAtIndex:j] pointValue];
				if(currentPoint.y<minY)
				{
					minY = currentPoint.y;
					minYIndex = j;
				}
				if(currentPoint.y>maxY)
				{
					maxY = currentPoint.y;
					maxYIndex = j;
				}
			}
			[self drawPointLabelAtPosition:[[aCurve objectAtIndex:0] pointValue]];
			[self drawPointLabelAtPosition:[[aCurve objectAtIndex:(long)[aCurve count]-1] pointValue]];
			if(minYIndex>0 && minY>0.0) [self drawPointLabelAtPosition:[[aCurve objectAtIndex:minYIndex] pointValue]];
			if(maxYIndex>0) [self drawPointLabelAtPosition:[[aCurve objectAtIndex:maxYIndex] pointValue]];
		}
	}
}

- (void)addCurveAtindex:(int)curveIndex withPoints:(NSArray*)pointsArray colors:(NSArray*)colorsArray;
{
	[[undoManager prepareWithInvocationTarget:self] deleteCurveAtIndex:curveIndex];
	[curves insertObject:pointsArray atIndex:curveIndex];
	[pointColors insertObject:colorsArray atIndex:curveIndex];
}

- (void)deleteCurveAtIndex:(int)curveIndex;
{
	nothingChanged = NO;
	clutChanged = YES;
	[[undoManager prepareWithInvocationTarget:self] addCurveAtindex:curveIndex withPoints:[NSMutableArray arrayWithArray:[curves objectAtIndex:curveIndex]] colors:[NSMutableArray arrayWithArray:[pointColors objectAtIndex:curveIndex]]];
	[curves removeObjectAtIndex:curveIndex];
	[pointColors removeObjectAtIndex:curveIndex];
}

- (void)moveCurveAtIndex:(int)i0 toIndex:(int)i1;
{
	[[undoManager prepareWithInvocationTarget:self] moveCurveAtIndex:i1 toIndex:i0];
	
	NSMutableArray *theCurve = [curves objectAtIndex:i0];
	NSMutableArray *theColors = [pointColors objectAtIndex:i0];
		
	if(i0>i1)
	{
		[curves insertObject:theCurve atIndex:i1];
		[pointColors insertObject:theColors atIndex:i1];
		[curves removeObjectAtIndex:i0+1];
		[pointColors removeObjectAtIndex:i0+1];
	}
	else
	{
		[curves insertObject:theCurve atIndex:i1+1];
		[pointColors insertObject:theColors atIndex:i1+1];
		[curves removeObjectAtIndex:i0];
		[pointColors removeObjectAtIndex:i0];
	}
}

- (void)sendToBackCurveAtIndex:(int)i;
{
	if(i != (long)[curves count]-1)
	{
		nothingChanged = NO;
		clutChanged = NO;
		[self moveCurveAtIndex:i toIndex:(long)[curves count]-1];
	}
}

- (void)sendToFrontCurveAtIndex:(int)i;
{
	if(i != 0)
	{
		nothingChanged = NO;
		clutChanged = NO;
		[self moveCurveAtIndex:i toIndex:0];
	}
}

- (int)selectedCurveIndex;
{
	return selectedCurveIndex;
}

- (void)selectCurveAtIndex:(int)i;
{
	if([curves count]==0) return;
	NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
	selectedCurveIndex = i;
	selectedPoint = controlPoint;
	[self setCLUTtoVRView:NO];
}

- (void)setColor:(NSColor*)color forCurveAtIndex:(int)curveIndex;
{
	nothingChanged = NO;
	clutChanged = YES;
	[[undoManager prepareWithInvocationTarget:self] setColors:[NSMutableArray arrayWithArray:[pointColors objectAtIndex:curveIndex]] forCurveAtIndex:curveIndex];
	
	for (NSUInteger i=0; i<[[curves objectAtIndex:curveIndex] count]; i++)
	{
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:i withObject:color];
	}
}

- (void)setColors:(NSArray*)colors forCurveAtIndex:(int)curveIndex;
{
	nothingChanged = NO;
	clutChanged = YES;
	[[undoManager prepareWithInvocationTarget:self] setColors:[NSMutableArray arrayWithArray:[pointColors objectAtIndex:curveIndex]] forCurveAtIndex:curveIndex];
	
	for (NSUInteger i=0; i<[[curves objectAtIndex:curveIndex] count]; i++)
	{
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:i withObject:[colors objectAtIndex:i]];
	}
}

- (void)shiftCurveAtIndex:(int)curveIndex shift:(float)aShift
{
	[[undoManager prepareWithInvocationTarget:self] shiftCurveAtIndex:curveIndex shift:-aShift];
	NSMutableArray *theCurve = [curves objectAtIndex:curveIndex];
	NSPoint pt;
	
	for (NSUInteger i=0; i<[theCurve count]; i++)
	{
		pt = [[theCurve objectAtIndex:i] pointValue];
		pt.y += aShift;
		[theCurve replaceObjectAtIndex:i withObject:[NSValue valueWithPoint:pt]];
	}
}

- (void)setCurves:(NSMutableArray*)newCurves;
{
	if(curves) [curves release];
	curves = [newCurves retain];
}

- (void)setPointColors:(NSMutableArray*)newPointColors;
{
	if(pointColors) [pointColors release];
	pointColors = [newPointColors retain];
}

#pragma mark -
#pragma mark Coordinate to NSView Transform

- (NSAffineTransform*) transform;
{
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy: -HUmin*drawingRect.size.width/(HUmax-HUmin)*zoomFactor+drawingRect.origin.x yBy:0.0];
	[transform scaleXBy: drawingRect.size.width/(HUmax-HUmin)*zoomFactor yBy: drawingRect.size.height];
	
	NSAffineTransform* transform3 = [NSAffineTransform transform];
	[transform3 translateXBy: -zoomFixedPoint*(zoomFactor) yBy:0.0];
	[transform appendTransform: transform3];
	
	return transform;
}

#pragma mark -
#pragma mark Global draw method

- (void)drawRect:(NSRect)rect
{
	if( histogram == nil)
		[self callComputeHistogram];
	
	[backgroundColor set];
	NSRectFill(rect);
	
	sideBarRect.origin = rect.origin;
	sideBarRect.size.height = rect.size.height;
	sideBarRect.size.width = 30.0;
		
	rect.origin.x += sideBarRect.size.width;
	rect.size.width -= sideBarRect.size.width;
	
	drawingRect = rect;
	
	[self fillCurvesInRect:rect];
	[self drawHistogramInRect:rect];
	[self drawCurvesInRect:rect];
	
	[self drawSideBar:sideBarRect];
}

- (void)updateView;
{
	if( updateView) return;	// avoid re-entry
	updateView = YES;
	
	[self setNeedsDisplay:YES];
	
	if(clutChanged)[self setCLUTtoVRView];
	clutChanged = NO;
	
	updateView = NO;
}

#pragma mark -
#pragma mark Points

- (BOOL)selectPointAtPosition:(NSPoint)position;
{
	int i, j;
	for (i=0; i<[curves count]; i++)
	{
		NSArray *aCurve = [curves objectAtIndex:i];
		for (j=0; j<[aCurve count]; j++)
		{
			NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
			NSAffineTransform* transform = [self transform];
			NSPoint pt2 = [transform transformPoint:pt];
			if(position.x>=pt2.x-pointDiameter && position.y>=pt2.y-pointDiameter && position.x<=pt2.x+pointDiameter && position.y<=pt2.y+pointDiameter)
			{
				selectedPoint = [[aCurve objectAtIndex:j] pointValue];
				[[NSColorPanel sharedColorPanel] setColor:[[pointColors objectAtIndex:i] objectAtIndex:j]];
				[self sendToFrontCurveAtIndex:i];
				selectedCurveIndex = -1;
				clutChanged = NO;
				[self updateView];
				[self setCLUTtoVRView:NO];
				return YES;
			}
		}
	}
	[self setCLUTtoVRView:NO];
	return NO;
}

- (void)unselectPoints;
{
	selectedPoint.y = -1.0;
	clutChanged = NO;
	[self updateView];
}

- (BOOL)isAnyPointSelected;
{
	return (selectedPoint.y>=0.0);
}

- (void)changePointColor:(NSNotification *)notification;
{
	if([self isAnyPointSelected])
	{
		vrViewLowResolution = YES;
		
		int i, j;
		for (i=0; i<[curves count]; i++)
		{
			NSMutableArray *aCurve = [curves objectAtIndex:i];
			for (j=0; j<[aCurve count]; j++)
			{
				NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
				if((int) pt.x==(int) selectedPoint.x && (float) pt.y==(float) selectedPoint.y)
				{
					[self setColor:[[(NSColorPanel*)[notification object] color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace] forPointAtIndex:j inCurveAtIndex:i];
					[self updateView];
					return;
				}
			}
			NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
			if((int) controlPoint.x==(int) selectedPoint.x && (float) controlPoint.y==(float) selectedPoint.y)
			{
				[self setColor:[[(NSColorPanel*)[notification object] color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace] forCurveAtIndex:i];
				[self updateView];
				return;
			}
		}
	}
}

- (void)setColor:(NSColor*)color forPointAtIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex;
{
	NSColor *currentColor = [[[pointColors objectAtIndex:curveIndex] objectAtIndex:pointIndex] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	NSColor *newColor = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
			
	if([currentColor redComponent]!=[newColor redComponent] || [currentColor greenComponent]!=[newColor greenComponent] || [currentColor blueComponent]!=[newColor blueComponent])
	{
		clutChanged = YES;
		nothingChanged = NO;
		//vrViewLowResolution = NO;
		[[undoManager prepareWithInvocationTarget:self] setColor:[[pointColors objectAtIndex:curveIndex] objectAtIndex:pointIndex] forPointAtIndex:pointIndex inCurveAtIndex:curveIndex];
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:pointIndex withObject:color];
	}
}

- (NSPoint)legalizePoint:(NSPoint)point inCurve:(NSArray*)aCurve atIndex:(int)j;
{
	if(point.y<0.0) point.y = 0.0;
	if(point.y>=0.999) point.y = 0.999;
					
	if(j>0)
		if(point.x<=[[aCurve objectAtIndex:j-1] pointValue].x+10) point.x = [[aCurve objectAtIndex:j-1] pointValue].x+10;
	if(j<(long)[aCurve count]-1)
		if(point.x>=[[aCurve objectAtIndex:j+1] pointValue].x-10) point.x = [[aCurve objectAtIndex:j+1] pointValue].x-10;
			
	return point;
}

- (void)drawPointLabelAtPosition:(NSPoint)pt;
{
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:textLabelColor forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"value : %.0f\nalpha : %1.3f", @"don't translate the 'backslash n' before 'alpha', it is a new line symbol!"), pt.x, pt.y*pt.y] attributes:attrsDictionary] autorelease];
	NSAttributedString *labelValue = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"value : %.0f", nil), pt.x] attributes:attrsDictionary] autorelease];
	NSAttributedString *labelAlpha = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"alpha : %1.3f", nil), pt.y*pt.y] attributes:attrsDictionary] autorelease];
	
	NSAffineTransform* transform = [self transform];
	NSPoint pt1 = [transform transformPoint:pt];
	NSPoint labelPosition = NSMakePoint(pt1.x + pointDiameter, pt1.y + pointDiameter);
				
//	NSRect rect = [self bounds];
NSRect rect = drawingRect;
	NSRect labelBounds = [label boundingRectWithSize:rect.size options:NSStringDrawingUsesDeviceMetrics];
	NSRect labelValueBounds = [labelValue boundingRectWithSize:rect.size options:NSStringDrawingUsesDeviceMetrics];
	NSRect labelAlphaBounds = [labelAlpha boundingRectWithSize:rect.size options:NSStringDrawingUsesDeviceMetrics];
	labelBounds.size.height *= 3.0; // because of the \n, we have 2 lines!
	labelBounds.size.height += 1.0;
	labelBounds.size.width = labelValueBounds.size.width;
	if(labelValueBounds.size.width < labelAlphaBounds.size.width) labelBounds.size.width = labelAlphaBounds.size.width;
	labelBounds.size.width += 4.0;

	if(labelPosition.y+labelBounds.size.height >= rect.size.height)
	{
		labelPosition.y = rect.size.height - labelBounds.size.height;
	}
	
	if(labelPosition.x+labelBounds.size.width >= rect.size.width)
	{
		labelPosition.x = rect.size.width - labelBounds.size.width;
	}
	
	NSBezierPath *labelRect = [NSBezierPath bezierPathWithRect:NSMakeRect(labelPosition.x-2.0,labelPosition.y,labelBounds.size.width,labelBounds.size.height)];
	[[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
	[labelRect fill];
	[label drawAtPoint:labelPosition];
}

- (void)addPoint:(NSPoint)point atIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex withColor:(NSColor*)color;
{
	[[undoManager prepareWithInvocationTarget:self] removePointAtIndex:pointIndex inCurveAtIndex:curveIndex];
	
	[[curves objectAtIndex:curveIndex] insertObject:[NSValue valueWithPoint:point] atIndex:pointIndex];
	[[pointColors objectAtIndex:curveIndex] insertObject:color atIndex:pointIndex];
}

- (void)removePointAtIndex:(int)ip inCurveAtIndex:(int)ic;
{
	NSMutableArray *theCurve = [curves objectAtIndex:ic];
	if([theCurve count]<=3)
	{
		[self deleteCurveAtIndex:ic];
	}
	else if(ip==0 || ip==(long)[theCurve count]-1) return;
	else
	{
		[[undoManager prepareWithInvocationTarget:self] addPoint:[[theCurve objectAtIndex:ip] pointValue] atIndex:ip inCurveAtIndex:ic withColor:[[pointColors objectAtIndex:ic] objectAtIndex:ip]];
		[theCurve removeObjectAtIndex:ip];
		[[pointColors objectAtIndex:ic] removeObjectAtIndex:ip];
	}
	[self unselectPoints];
	[self updateView];
}

- (void)replacePointAtIndex:(int)ip inCurveAtIndex:(int)ic withPoint:(NSPoint)point;
{
	[[undoManager prepareWithInvocationTarget:self] replacePointAtIndex:ip inCurveAtIndex:ic withPoint:[[[curves objectAtIndex:ic] objectAtIndex:ip] pointValue]];
	[[curves objectAtIndex:ic] replaceObjectAtIndex:ip withObject:[NSValue valueWithPoint:point]];
}

#pragma mark -
#pragma mark Control Point

- (NSPoint)controlPointForCurveAtIndex:(int)i;
{
	NSPoint controlPoint;
	NSArray *aCurve = [curves objectAtIndex:i];
	NSAffineTransform *transform = [self transform];
	
	if([aCurve count]%2==1)
	{
		controlPoint.x = [[aCurve objectAtIndex:((long)[aCurve count]-1)/2] pointValue].x;
		controlPoint.y = [[aCurve objectAtIndex:((long)[aCurve count]-1)/2] pointValue].y/2.0;
	}
	else
	{
		controlPoint.x = ([[aCurve objectAtIndex:[aCurve count]/2-1] pointValue].x + [[aCurve objectAtIndex:[aCurve count]/2] pointValue].x)/2.0;
		controlPoint.y = ([[aCurve objectAtIndex:[aCurve count]/2-1] pointValue].y + [[aCurve objectAtIndex:[aCurve count]/2] pointValue].y)/4.0;
	}
	
	controlPoint.x = ([[aCurve lastObject] pointValue].x + [[aCurve objectAtIndex:0] pointValue].x)/2.0;
	
	controlPoint = [transform transformPoint:controlPoint];
	return controlPoint;
}

- (BOOL)selectControlPointAtPosition:(NSPoint)position;
{
	NSPoint controlPoint;
	
	for ( NSUInteger i=0; i<[curves count]; i++)
	{
		controlPoint = [self controlPointForCurveAtIndex:i];
		if(position.x>=controlPoint.x-pointDiameter && position.y>=controlPoint.y-pointDiameter && position.x<=controlPoint.x+pointDiameter && position.y<=controlPoint.y+pointDiameter)
		{
			selectedPoint = controlPoint;
			[self sendToFrontCurveAtIndex:i];
			selectedCurveIndex = 0;
			[self setCLUTtoVRView:NO];
			//[self updateView];
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Lines selection

- (BOOL)clickOnLineAtPosition:(NSPoint)position;
{
	int i, j;
	NSPoint pt0, pt1, p0, p1;
	float a, b; // line between p0 & p1 : y = a x + b
	NSAffineTransform* transform = [self transform];
	NSMutableArray *aCurve, *colors;
	
	BOOL addPoint = NO;
	
	for (i=0; i<[curves count] && !addPoint; i++)
	{
		aCurve = [curves objectAtIndex:i];
		colors = [pointColors objectAtIndex:i];
		for (j=1; j<[aCurve count] && !addPoint; j++)
		{
			pt0 = [[aCurve objectAtIndex:j-1] pointValue];
			pt1 = [[aCurve objectAtIndex:j] pointValue];
			p0 = [transform transformPoint:pt0];
			p1 = [transform transformPoint:pt1];

			if(position.x>p0.x && position.x<p1.x)
			{
				if((position.y>=p0.y && position.y<=p1.y) || (position.y<=p0.y && position.y>=p1.y) || (p0.y==p1.y && position.y>=p0.y-10.0 && position.y<=p0.y+10.0))
				{
					a = (p1.y-p0.y)/(p1.x-p0.x);
					b = p0.y - a*p0.x;
					if(position.y>=a*position.x+b-10.0 && position.y<=a*position.x+b+10.0)
					{
						addPoint = YES;
					}
				}
			}
			else if(position.x==p0.x && position.x==p1.x)
			{
				addPoint = YES;
			}
		}
	}
	
	if(addPoint)
	{
		nothingChanged = NO;
		clutChanged = YES;
		[transform invert];
		NSPoint newPoint = [transform transformPoint:position];
		selectedPoint.x = newPoint.x;
		selectedPoint.y = newPoint.y;
		float blendingFactor = (newPoint.x - [[aCurve objectAtIndex:j-2] pointValue].x) / ([[aCurve objectAtIndex:j-1] pointValue].x - [[aCurve objectAtIndex:j-2] pointValue].x);
		[self addPoint:newPoint atIndex:j-1 inCurveAtIndex:i-1 withColor:[[colors objectAtIndex:j-2] blendedColorWithFraction:blendingFactor ofColor:[colors objectAtIndex:j-1]]];
		[self sendToFrontCurveAtIndex:i-1];
		selectedCurveIndex = 0;
		[self updateView];
	}
	
	return addPoint;
}

#pragma mark -
#pragma mark Mouse

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint mousePositionInWindow = [theEvent locationInWindow];
	NSPoint mousePositionInView = [self convertPoint:mousePositionInWindow fromView:nil];
	
	mouseDraggingStartPoint = mousePositionInView;
	
	nothingChanged = YES;
	clutChanged = NO;
	[undoManager beginUndoGrouping];
	
	vrViewLowResolution = NO;

	[super mouseDown:theEvent];

//	if([self clickInMenuButtonAtPosition:mousePositionInView])
//	{	
//		[NSMenu popUpContextMenu:contextualMenu withEvent:theEvent forView:self];
//		return;
//	}

	if([self clickInAddCurveButtonAtPosition:mousePositionInView] || [self clickInRemoveSelectedCurveButtonAtPosition:mousePositionInView] || [self clickInSaveButtonAtPosition:mousePositionInView] || [self clickInCloseButtonAtPosition:mousePositionInView])
	{
		[self setNeedsDisplay:YES];
		return;
	}
	
	if(![self selectPointAtPosition:mousePositionInView])
	{
		[self unselectPoints];
		if(![self selectControlPointAtPosition:mousePositionInView])
		{
			if(![self clickOnLineAtPosition:mousePositionInView])
			{
				NSAffineTransform* transformView2Coordinate = [self transform];
				[transformView2Coordinate invert];
			//	zoomFixedPoint = [transformView2Coordinate transformPoint:mousePositionInView].x;
			}
		}
		else if([theEvent clickCount] == 2)
		{
			nothingChanged = YES;
			clutChanged = NO;
			[[NSColorPanel sharedColorPanel] orderFront:self];
		}
	}
	else if([theEvent clickCount] == 2)
	{
		nothingChanged = YES;
		clutChanged = NO;
		[[NSColorPanel sharedColorPanel] orderFront:self];
	}
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	if(isRemoveSelectedCurveButtonHighlighted)
	{
		[self delete:self];
//		if([self selectedCurveIndex]>=0)
//			[self deleteCurveAtIndex:[self selectedCurveIndex]];
		isRemoveSelectedCurveButtonHighlighted = NO;
		nothingChanged = NO;
		[self setNeedsDisplay:YES];
	}
	
	[undoManager endUndoGrouping];
		
	if(isAddCurveButtonHighlighted)
	{
		[self newCurve];
		isAddCurveButtonHighlighted = NO;
		[self setNeedsDisplay:YES];
	}
	
	if(isSaveButtonHighlighted)
	{
		[self chooseNameAndSave:nil];
	}
	
	if(isCloseButtonHighlighted)
	{
		isCloseButtonHighlighted = NO;
		[[[vrView controller] clutOpacityDrawer] close];
	}
	
	if([theEvent clickCount] == 2 || nothingChanged)
	{
		[undoManager undoNestedGroup];
	}
	
	BOOL wasInLowResolution = vrViewLowResolution;
	vrViewLowResolution = NO;
	
	if(clutChanged || wasInLowResolution) [self setCLUTtoVRView];
	
	[super mouseUp:theEvent];
}

-(NSMenu*) menuForEvent:(NSEvent *)theEvent
{
	return contextualMenu;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[NSMenu popUpContextMenu:contextualMenu withEvent:theEvent forView:self];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[super mouseDragged:theEvent];
	
	[[NSCursor arrowCursor] set];
	
	NSPoint mousePositionInWindow = [theEvent locationInWindow];
	NSPoint mousePositionInView = [self convertPoint:mousePositionInWindow fromView:nil];

	if([self clickInAddCurveButtonAtPosition:mouseDraggingStartPoint])
	{
		[self clickInAddCurveButtonAtPosition:mousePositionInView];
		[self setNeedsDisplay:YES];
		return;
	}
	
	if([self clickInRemoveSelectedCurveButtonAtPosition:mouseDraggingStartPoint])
	{
		[self clickInRemoveSelectedCurveButtonAtPosition:mousePositionInView];
		[self setNeedsDisplay:YES];
		return;
	}

	if([self clickInSaveButtonAtPosition:mouseDraggingStartPoint])
	{
		[self clickInSaveButtonAtPosition:mousePositionInView];
		[self setNeedsDisplay:YES];
		return;
	}
	
	if([self clickInCloseButtonAtPosition:mouseDraggingStartPoint])
	{
		[self clickInCloseButtonAtPosition:mousePositionInView];
		[self setNeedsDisplay:YES];
		return;
	}
	
	if([self clickInSideBarAtPosition:mouseDraggingStartPoint])
	{
		return;
	}	
	
	if([self isAnyPointSelected])
	{
		vrViewLowResolution = YES;
	
		nothingChanged = NO;
		clutChanged = YES;
		NSAffineTransform* transformCoordinate2View = [self transform];
		NSAffineTransform* transformView2Coordinate = [self transform];
		[transformView2Coordinate invert];
		NSPoint firstPoint, lastPoint;
		
		NSPoint mouseLocation = [transformView2Coordinate transformPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
		mousePositionX = mouseLocation.x;
			
		int i, j;
		for (i=0; i<[curves count]; i++)
		{
			NSMutableArray *aCurve = [curves objectAtIndex:i];
			
			if(!([theEvent modifierFlags] & NSAlternateKeyMask))
			{
				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					if((int) pt.x==(int) selectedPoint.x && (float) pt.y==(float) selectedPoint.y)
					{
						NSPoint newPoint = [transformView2Coordinate transformPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
						newPoint = [self legalizePoint:newPoint inCurve:aCurve atIndex:j];
						[self replacePointAtIndex:j inCurveAtIndex:i withPoint:newPoint];
						selectedPoint.x = newPoint.x;
						selectedPoint.y = newPoint.y;
						[self updateView];
					}
				}
			}
			else
			{	
				firstPoint = [[aCurve objectAtIndex:0] pointValue];
				lastPoint = [[aCurve lastObject] pointValue];
				BOOL firstPointSelected = ((int) firstPoint.x==(int) selectedPoint.x && (float) firstPoint.y==(float) selectedPoint.y);
				BOOL lastPointSelected = ((int) lastPoint.x==(int) selectedPoint.x && (float) lastPoint.y==(float) selectedPoint.y);
				firstPoint = [transformCoordinate2View transformPoint:firstPoint];
				lastPoint = [transformCoordinate2View transformPoint:lastPoint];
				if( firstPointSelected || lastPointSelected)
				{
					float shiftX = [theEvent deltaX];
					float d = lastPoint.x - firstPoint.x;
					for (j=0; j<[aCurve count]; j++)
					{
						NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
						pt = [transformCoordinate2View transformPoint:pt];
						NSPoint shiftedPoint;
						float alpha = 1.0;
						if(firstPointSelected)
							alpha = fabs(pt.x - lastPoint.x) / d;
						else
							alpha = fabs(pt.x - firstPoint.x) / d;
						shiftedPoint = NSMakePoint(pt.x + alpha * shiftX, pt.y);
						shiftedPoint = [transformView2Coordinate transformPoint:shiftedPoint];
						[self replacePointAtIndex:j inCurveAtIndex:i withPoint:shiftedPoint];
					}
					for (j=0; j<[aCurve count]; j++)
					{
						NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
						pt = [self legalizePoint:pt inCurve:aCurve atIndex:j];
						[self replacePointAtIndex:j inCurveAtIndex:i withPoint:pt];
					}
					if(firstPointSelected)
						selectedPoint = [[aCurve objectAtIndex:0] pointValue];
					else
						selectedPoint = [[aCurve lastObject] pointValue];

					[self updateView];
				}
			}
			
			NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
			if( (int) controlPoint.x == (int) selectedPoint.x && (float) controlPoint.y == (float) selectedPoint.y)
			{			
//				NSPoint newPointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//				NSPoint newPoint = [transformView2Coordinate transformPoint:newPointInView];
								
				float shiftX = [theEvent deltaX];
				float shiftY = [theEvent deltaY];

				firstPoint = [transformCoordinate2View transformPoint:[[aCurve objectAtIndex:0] pointValue]];
				lastPoint = [transformCoordinate2View transformPoint:[[aCurve lastObject] pointValue]];
				float d = lastPoint.x - firstPoint.x;
				float middlePointX = firstPoint.x + d / 2.0;

				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					pt = [transformCoordinate2View transformPoint:pt];
					NSPoint shiftedPoint;
					if([theEvent modifierFlags] & NSAlternateKeyMask)
					{
						shiftY = 0;
						
						float alpha = 1.0;
						if(j>0 && j<(long)[aCurve count]-1)
							alpha = 2.0*fabs(middlePointX - pt.x) / d;
						if(pt.x<=controlPoint.x)
							shiftedPoint = NSMakePoint(pt.x - alpha * shiftX, pt.y-shiftY);
						else
							shiftedPoint = NSMakePoint(pt.x + alpha * shiftX, pt.y-shiftY);
						if(shiftedPoint.x > controlPoint.x+10.0 || shiftedPoint.x < controlPoint.x-10.0 || pt.x == controlPoint.x || (pt.x < controlPoint.x+10.0 && shiftedPoint.x > controlPoint.x+10.0) || (pt.x > controlPoint.x-10.0 && shiftedPoint.x < controlPoint.x-10.0))
						{
							shiftedPoint = [transformView2Coordinate transformPoint:shiftedPoint];
							[self replacePointAtIndex:j inCurveAtIndex:i withPoint:shiftedPoint];
							controlPoint = [self controlPointForCurveAtIndex:i];
						}
					}
					else
					{
						shiftedPoint = NSMakePoint(pt.x+shiftX, pt.y-shiftY);
						if(j==0) shiftedPoint = NSMakePoint(pt.x+shiftX, pt.y);
						shiftedPoint = [transformView2Coordinate transformPoint:shiftedPoint];
						[self replacePointAtIndex:j inCurveAtIndex:i withPoint:shiftedPoint];
						controlPoint = [self controlPointForCurveAtIndex:i];
					}
				}
				
				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					pt = [self legalizePoint:pt inCurve:aCurve atIndex:j];
					[self replacePointAtIndex:j inCurveAtIndex:i withPoint:pt];
				}
				controlPoint = [self controlPointForCurveAtIndex:i];
				selectedPoint.x = controlPoint.x;
				selectedPoint.y = controlPoint.y;
				[self updateView];
				return;
			}
		}
	}
	else
	{
		if(fabs([theEvent deltaX])>fabs([theEvent deltaY]))
		{
			zoomFixedPoint -= [theEvent deltaX] / zoomFactor;
		}
//		else
//		{
//			float inc = -[theEvent deltaY] / 30.;
//			
//			if( zoomFactor +inc < 1.0) inc = 1.0 - zoomFactor;
//			if( zoomFactor +inc > 5.0) inc = 5.0 - zoomFactor;
//			
//			zoomFactor += inc;
//			zoomFixedPoint += (inc * [self bounds].size.width / (zoomFactor*2)) / 2.0 ;	// 
//			
//			[self setCursorLabelWithText:[NSString stringWithFormat:NSLocalizedString(@"zoom x %.1f", nil), zoomFactor]];
//		}
		[self updateView];
	}
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	if( ![[self window] isVisible])
		return;
	
	[super mouseMoved:theEvent];

	if( ![[self window] isMainWindow]) return;
	
	NSPoint mousePositionInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if( !NSPointInRect([NSEvent mouseLocation], [[self window] frame]))
	{
		[[NSCursor arrowCursor] set];
		mousePositionX = - 9999.0;
		[self updateView];
		return;
	}
	else if ([self clickInSideBarAtPosition:mousePositionInView])
	{
		NSString *mouseLabel;
		if([self clickInAddCurveButtonAtPosition:mousePositionInView])
		{
			mouseLabel = NSLocalizedString(@"Add", @"");
		}
		else if([self clickInRemoveSelectedCurveButtonAtPosition:mousePositionInView])
		{
			mouseLabel = NSLocalizedString(@"Remove", @"");
		}
		else if([self clickInSaveButtonAtPosition:mousePositionInView])
		{
			mouseLabel = NSLocalizedString(@"Save", @"");
		}
		else if([self clickInCloseButtonAtPosition:mousePositionInView])
		{
			mouseLabel = NSLocalizedString(@"Close", @"");
		}
		else mouseLabel = @"";
		
		[self setCursorLabelWithText:mouseLabel];
		mousePositionX = - 9999.0;
		[self updateView];
		return;
	}
	
	
	NSAffineTransform* transformView2Coordinate = [self transform];
	[transformView2Coordinate invert];
	NSPoint location = [transformView2Coordinate transformPoint:mousePositionInView];
	
	[self setCursorLabelWithText:[NSString stringWithFormat:@"x: %d", (int)location.x]];
	
	mousePositionX = location.x;
	[self updateView];
}

#pragma mark -
#pragma mark Keyboard

- (void)keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
	unichar c = [[theEvent characters] characterAtIndex:0];
	if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
	{
		if([self isAnyPointSelected])
		{
			[self delete:self];
			return;
		}
	}
	[super keyDown:theEvent];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

#pragma mark -
#pragma mark GUI

- (IBAction)computeHistogram:(id)sender;
{
	[self callComputeHistogram];
	[self updateView];
}

- (IBAction)setHistogramOpacity:(id)sender;
{
	histogramOpacity = [sender floatValue];
	[self updateView];
}

- (IBAction)newCurve:(id)sender;
{
	[self newCurve];
}

- (IBAction)setLineWidth:(id)sender;
{
	lineWidth = [sender floatValue];
	[self updateView];
}

- (IBAction)setPointDiameter:(id)sender;
{
	pointDiameter = [sender floatValue];
	[self updateView];
}

- (void)niceDisplay;
{
	NSRect screenFrame = [[[vrView window] screen] frame];
			
	NSRect newFrame = screenFrame;
	newFrame.size.height = 200;
	[[self window] setBackgroundColor:[NSColor blackColor]];
	
	NSRect vrFrame = [[vrView window] frame];
	vrFrame.size.height = vrFrame.size.height - newFrame.size.height +8;
	vrFrame.origin.y = vrFrame.origin.y + newFrame.size.height -8;
	if(!didResizeVRVIew)
	{
		[[vrView window] setFrame:vrFrame display:YES animate:NO];
		[vrView squareView:self];
		didResizeVRVIew = YES;
	}
	
	//[[self window] setAcceptsMouseMovedEvents:YES];

	if([curves count]==0)
	{
		[self newCurve];
	}
}

- (IBAction)niceDisplay:(id)sender;
{
	[self niceDisplay];
}

- (IBAction)sendToBack:(id)sender;
{
	NSUInteger i, j;
	int curveIndex = -1;

	for (i=0; i<[curves count] && curveIndex<0; i++)
	{
		NSArray *aCurve = [curves objectAtIndex:i];
		for (j=0; j<[aCurve count] && curveIndex<0; j++)
		{
			NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
			if((int) selectedPoint.x==(int) pt.x && (float) selectedPoint.y==(float) pt.y)
				curveIndex = i;
		}
	}

	if(curveIndex<0)
	{
		for (i=0; i<[curves count] && curveIndex<0; i++)
		{
			NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
			if((int) selectedPoint.x==(int) controlPoint.x && (float) selectedPoint.y==(float) controlPoint.y)
				curveIndex = i;
		}
	}

	if(curveIndex>=0)
	{
		[self sendToBackCurveAtIndex:curveIndex];
		[self updateView];
	}
}

- (IBAction)setZoomFator:(id)sender;
{
	zoomFactor = [sender floatValue];
	[self updateView];
}

- (IBAction)scroll:(id)sender;
{
//	zoomFixedPoint = [sender floatValue] / [sender maxValue] * [self bounds].size.width;
zoomFixedPoint = [sender floatValue] / [(NSSlider *)sender maxValue] * drawingRect.size.width;
	[self updateView];
}

- (IBAction)removeAllCurves:(id)sender;
{
	[curves removeAllObjects];
	[self updateView];
}

- (void)addCurveIfNeeded;
{
	if([curves count]==0)
	{
		[self newCurve];
	}
}

#pragma mark Custom GUI

- (void)drawSideBar:(NSRect)rect;
{
	[backgroundColor set];
	NSRectFill(rect);
	
	float leftMargin = 5.0;
	float topMargin = 5.0;
	float buttonsMargin = 5.0;
	float buttonSize = 15.0;
	
	closeButtonRect = NSMakeRect(rect.origin.x+leftMargin, rect.origin.y+rect.size.height-2.0*topMargin-buttonSize, buttonSize, buttonSize);
	addCurveButtonRect = NSMakeRect(closeButtonRect.origin.x, closeButtonRect.origin.y-closeButtonRect.size.height-buttonsMargin, buttonSize, buttonSize);
	removeSelectedCurveButtonRect = NSMakeRect(addCurveButtonRect.origin.x, addCurveButtonRect.origin.y-addCurveButtonRect.size.height-buttonsMargin, buttonSize, buttonSize);
	
	saveButtonRect = NSMakeRect(addCurveButtonRect.origin.x, 2.0*buttonsMargin, buttonSize, buttonSize);
	
	[self drawCloseButton:closeButtonRect];
	[self drawAddCurveButton:addCurveButtonRect];
	[self drawRemoveSelectedCurveButton:removeSelectedCurveButtonRect];
	[self drawSaveButton:saveButtonRect];
}

//- (void)drawMenuButton:(NSRect)rect;
//{
//	NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
//	[path setLineWidth:1.5];
//	[backgroundColor set];
//	[path fill];
//	[[NSColor whiteColor] set];
//	[path stroke];
//	
//	NSBezierPath *line = [NSBezierPath bezierPath];
//	[line setLineWidth:1.5];
//	NSPoint p1, p2;
//	float lineLength = 11;
//	p1 = NSMakePoint(rect.origin.x+2, rect.origin.y+4);
//	p2 = NSMakePoint(p1.x+lineLength, p1.y);
//	[line moveToPoint:p1];
//	[line lineToPoint:p2];
//	
//	p1 = NSMakePoint(p1.x, p1.y+4);
//	p2 = NSMakePoint(p1.x+lineLength, p1.y);
//	[line moveToPoint:p1];
//	[line lineToPoint:p2];
//	
//	p1 = NSMakePoint(p1.x, p1.y+4);
//	p2 = NSMakePoint(p1.x+lineLength, p1.y);
//	[line moveToPoint:p1];
//	[line lineToPoint:p2];
//	
//	[line stroke];
//}
- (void)drawCloseButton:(NSRect)rect;
{
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
	[path setLineWidth:1.5];
	if(isCloseButtonHighlighted)
		[[NSColor darkGrayColor] set];
	else
		[backgroundColor set];
	[path fill];
	[[NSColor whiteColor] set];
	[path stroke];
	
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line setLineWidth:2.0];
	NSPoint p1, p2;
	p1 = NSMakePoint(rect.origin.x+4, rect.origin.y+4);
	p2 = NSMakePoint(rect.origin.x + rect.size.width-4, rect.origin.y + rect.size.height-4);
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	
	p1 = NSMakePoint(rect.origin.x+4, rect.origin.y+ rect.size.height-4);
	p2 = NSMakePoint(rect.origin.x + rect.size.width-4, rect.origin.y+4);
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	
	[line stroke];
}

- (void)drawAddCurveButton:(NSRect)rect;
{
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
	[path setLineWidth:1.5];
	if(isAddCurveButtonHighlighted)
		[[NSColor darkGrayColor] set];
	else
		[backgroundColor set];
	[path fill];
	[[NSColor whiteColor] set];
	[path stroke];
	
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line setLineWidth:2.0];
	NSPoint p1, p2;
	float lineLength = 11;
	p1 = NSMakePoint(rect.origin.x+2, rect.origin.y+rect.size.height *0.5);
	p2 = NSMakePoint(p1.x+lineLength, p1.y);
	[line moveToPoint:p1];
	[line lineToPoint:p2];

	p1 = NSMakePoint(rect.origin.x+rect.size.width *0.5, rect.origin.y+2);
	p2 = NSMakePoint(p1.x, p1.y+lineLength);
	[line moveToPoint:p1];
	[line lineToPoint:p2];

	[line stroke];
}

- (void)drawRemoveSelectedCurveButton:(NSRect)rect;
{
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
	[path setLineWidth:1.5];
	if(isRemoveSelectedCurveButtonHighlighted)
		[[NSColor darkGrayColor] set];
	else
		[backgroundColor set];
	[path fill];
	[[NSColor whiteColor] set];
	[path stroke];
	
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line setLineWidth:2.0];
	NSPoint p1, p2;
	float lineLength = 11;
	p1 = NSMakePoint(rect.origin.x+2, rect.origin.y+rect.size.height *0.5);
	p2 = NSMakePoint(p1.x+lineLength, p1.y);
	[line moveToPoint:p1];
	[line lineToPoint:p2];

	[line stroke];
}

- (void)drawSaveButton:(NSRect)rect;
{
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
	[path setLineWidth:1.5];
	if(isSaveButtonHighlighted)
		[[NSColor darkGrayColor] set];
	else
		[backgroundColor set];
	[path fill];
	[[NSColor whiteColor] set];
	[path stroke];
	
	NSPoint center = NSMakePoint(rect.origin.x+rect.size.width*0.5, rect.origin.y+rect.size.height*0.5);
	NSRect dotFrame = NSMakeRect(center.x-3, center.y-3, 6, 6);
	NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:dotFrame];
	[dot fill];
}

- (BOOL)clickInSideBarAtPosition:(NSPoint)position;
{
	return NSPointInRect(position,sideBarRect);
}

//- (BOOL)clickInMenuButtonAtPosition:(NSPoint)position;
//{
//	return NSPointInRect(position,menuButtonRect);
//}

- (BOOL)clickInAddCurveButtonAtPosition:(NSPoint)position;
{
	if(NSPointInRect(position,addCurveButtonRect))
	{
		isAddCurveButtonHighlighted = YES;
		return YES;
	}
	else
	{
		isAddCurveButtonHighlighted = NO;
		return NO;
	}
}

- (BOOL)clickInRemoveSelectedCurveButtonAtPosition:(NSPoint)position;
{
	if(NSPointInRect(position, removeSelectedCurveButtonRect))
	{
		isRemoveSelectedCurveButtonHighlighted = YES;
		return YES;
	}
	else
	{
		isRemoveSelectedCurveButtonHighlighted = NO;
		return NO;
	}
}

- (BOOL)clickInCloseButtonAtPosition:(NSPoint)position
{
	if(NSPointInRect(position, closeButtonRect))
	{
		isCloseButtonHighlighted = YES;
		return YES;
	}
	else
	{
		isCloseButtonHighlighted = NO;
		return NO;
	}
}

- (BOOL)clickInSaveButtonAtPosition:(NSPoint)position;
{
	if(NSPointInRect(position, saveButtonRect))
	{
		isSaveButtonHighlighted = YES;
		return YES;
	}
	else
	{
		isSaveButtonHighlighted = NO;
		return NO;
	}
}

#pragma mark -
#pragma mark Copy / Paste

- (IBAction)copy:(id)sender;
{
	int curveIndex = [self selectedCurveIndex];
	
	if(curveIndex >= 0 && [curves count] > 0)
	{
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
		[dict setObject:[curves objectAtIndex:curveIndex] forKey:@"curve"];
		[dict setObject:[pointColors objectAtIndex:curveIndex] forKey:@"colors"];

		NSData* curveData = [NSArchiver archivedDataWithRootObject:dict];
		NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];

		[pasteboard declareTypes:[NSArray arrayWithObjects:@"osirixCLUTOpacityCurve", nil] owner:self];
		[pasteboard setData:curveData forType:@"osirixCLUTOpacityCurve"];
	}
	else
	{
		if(selectedPoint.y>=0.0)
		{
			int i, j;
			for (i=0; i<[curves count]; i++)
			{
				NSArray *aCurve = [curves objectAtIndex:i];
				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					if((int) selectedPoint.x==(int) pt.x && (float) selectedPoint.y==(float) pt.y)
					{
						NSData* colorData = [NSArchiver archivedDataWithRootObject:[[pointColors objectAtIndex:i] objectAtIndex:j]];
						NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];

						[pasteboard declareTypes:[NSArray arrayWithObjects:@"osirixCLUTOpacityPointColor", nil] owner:self];
						[pasteboard setData:colorData forType:@"osirixCLUTOpacityPointColor"];
						return;
					}
				}
			}
		}
	}
}

- (IBAction)paste:(id)sender;
{
	NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
	NSString* type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:@"osirixCLUTOpacityCurve", @"osirixCLUTOpacityPointColor", nil]];
	if([type isEqualToString:@"osirixCLUTOpacityCurve"])
	{
		NSData* curveData = [pasteboard dataForType:type];
		NSMutableDictionary *dict = [NSUnarchiver unarchiveObjectWithData:curveData];
		NSMutableArray *aCurve = [dict objectForKey:@"curve"];
		NSMutableArray *newColors = [dict objectForKey:@"colors"];
		
		int scx = [self selectedCurveIndex];
		NSMutableArray *selectedCurve;
		if(scx>=0)
			selectedCurve = [curves objectAtIndex:scx];
		else
			selectedCurve = aCurve;
		
		int i;
		float shift = 20;
		float delta = [[selectedCurve objectAtIndex:0] pointValue].x - [[aCurve objectAtIndex:0] pointValue].x + shift;

		NSMutableArray *aNewCurve = [NSMutableArray arrayWithCapacity:[aCurve count]];
		for (i=0; i<[aCurve count]; i++)
		{
			NSPoint pt = [[aCurve objectAtIndex:i] pointValue];
			pt.x += delta;
			[aNewCurve addObject:[NSValue valueWithPoint:pt]];
		}
		
		[self addCurveAtindex:0 withPoints:aNewCurve colors:newColors];
		[self selectCurveAtIndex:0];
		[self updateView];
	}
	else if([type isEqualToString:@"osirixCLUTOpacityPointColor"])
	{
		if(selectedPoint.y>=0.0)
		{
			int i, j;
			for (i=0; i<[curves count]; i++)
			{
				NSArray *aCurve = [curves objectAtIndex:i];
				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					if((int) selectedPoint.x==(int) pt.x && (float) selectedPoint.y==(float) pt.y)
					{
						NSData* colorData = [pasteboard dataForType:type];
						NSColor *color = [NSUnarchiver unarchiveObjectWithData:colorData];
						[self setColor:color forPointAtIndex:j inCurveAtIndex:i];
						[self updateView];
					}
				}
			}
		}
	}
}

- (IBAction)delete:(id)sender;
{
	int curveIndex = [self selectedCurveIndex];
	
	if(curveIndex >= 0 && [curves count] > 0)
	{
		[self deleteCurveAtIndex:curveIndex];
		vrViewLowResolution = NO;
		[self updateView];
	}
	else
	{
		if(selectedPoint.y>=0.0)
		{
			int i, j;
			for (i=0; i<[curves count]; i++)
			{
				NSArray *aCurve = [curves objectAtIndex:i];
				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					if((int) selectedPoint.x==(int) pt.x && (float) selectedPoint.y==(float) pt.y)
					{
						if([aCurve count]<=3)
						{
							[self deleteCurveAtIndex:i];
						}
						else
						{
							[self removePointAtIndex:j inCurveAtIndex:i];
						}
						[self updateView];
						return;
					}
				}
			}
		}
	}
}

- (IBAction)cut:(id)sender;
{
	[self copy:self];
	[self delete:self];
}

- (IBAction)undo:(id)sender;
{
	if([undoManager canUndo])
	{
		[undoManager undo];
		vrViewLowResolution = NO;
        clutChanged = YES;
		[self updateView];
	}
}

- (IBAction)redo:(id)sender;
{
	if([undoManager canRedo])
	{
		[undoManager redo];
		vrViewLowResolution = NO;
        clutChanged = YES;
		[self updateView];
	}
}

#pragma mark -
#pragma mark Saving (as plist)

- (void)chooseNameAndSave:(id)sender;
{
	if(isSaveButtonHighlighted)
	{
		isSaveButtonHighlighted = NO;
		[self setNeedsDisplay:YES];
	}
	[NSApp beginSheet:chooseNameAndSaveWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	[chooseNameAndSaveWindow orderFront:self];
}

- (IBAction)save:(id)sender;
{
	if([sender tag]==1)
	{
		if([[clutSavedName stringValue] length]>0)
		{
			[self saveWithName:[clutSavedName stringValue]];
			[chooseNameAndSaveWindow orderOut:self];
			[NSApp endSheet:chooseNameAndSaveWindow];
		}
	}
	else
	{
		[chooseNameAndSaveWindow orderOut:self];
		[NSApp endSheet:chooseNameAndSaveWindow];
	}	
}

- (void)saveWithName:(NSString*)name;
{
	NSMutableDictionary *clut = [NSMutableDictionary dictionaryWithCapacity:2];
	[clut setObject:[self convertCurvesForPlist] forKey:@"curves"];
	[clut setObject:[self convertPointColorsForPlist] forKey:@"colors"];
	
	NSString *path = [[[BrowserController currentBrowser] database] clutsDirPath];
	
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	path = [path stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"plist"]];
	[clut writeToFile:path atomically:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixUpdateCLUTMenuNotification object:name userInfo:nil];
	[[vrView controller] setCurCLUTMenu:name];
}

+ (NSDictionary*)presetFromFileWithName:(NSString*)name;
{
    NSString *CLUTsPath = [[[BrowserController currentBrowser] database] clutsDirPath];
    NSString *path = [CLUTsPath stringByAppendingPathComponent:name];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		if([[path pathExtension] isEqualToString:@""])
		{
			NSMutableDictionary *clut = [NSUnarchiver unarchiveObjectWithFile:path];
			return clut;
		}
		else
			return nil;
	}
	else
	{
		path = [path stringByAppendingPathExtension:@"plist"];
		if([[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			NSMutableDictionary *clutFromFile = [NSMutableDictionary dictionaryWithContentsOfFile:path];
			NSArray *curveArray = [CLUTOpacityView convertCurvesFromPlist:[clutFromFile objectForKey:@"curves"]];
			NSArray *colorArray = [CLUTOpacityView convertPointColorsFromPlist:[clutFromFile objectForKey:@"colors"]];
			NSMutableDictionary *clut = [NSMutableDictionary dictionary];
			if([curveArray count]>0 && [colorArray count]>0)
			{
				[clut setObject:curveArray forKey:@"curves"];
				[clut setObject:colorArray forKey:@"colors"];
				return clut;
			}
			else return nil;
		}
		else
		{
			// look in the resources bundle path
            path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:CLUTsPath.lastPathComponent];
            path = [path stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"plist"]];
			if([[NSFileManager defaultManager] fileExistsAtPath:path])
			{
				NSMutableDictionary *clutFromFile = [NSMutableDictionary dictionaryWithContentsOfFile:path];
				NSArray *curveArray = [CLUTOpacityView convertCurvesFromPlist:[clutFromFile objectForKey:@"curves"]];
				NSArray *colorArray = [CLUTOpacityView convertPointColorsFromPlist:[clutFromFile objectForKey:@"colors"]];
				NSMutableDictionary *clut = [NSMutableDictionary dictionary];
				if([curveArray count]>0 && [colorArray count]>0)
				{
					[clut setObject:curveArray forKey:@"curves"];
					[clut setObject:colorArray forKey:@"colors"];
					return clut;
				}
				else return nil;
			}
			else
				return nil;
		}
	}
}

- (void)loadFromFileWithName:(NSString*)name;
{
	NSDictionary* clut = [CLUTOpacityView presetFromFileWithName:name];
	if(clut)
	{
		curves = [clut objectForKey:@"curves"];
		[curves retain];
		pointColors = [clut objectForKey:@"colors"];
		[pointColors retain];
	}
}

#pragma mark conversion to plist-compatible types

- (NSArray*)convertPointColorsForPlist;
{
	NSMutableArray *convertedPointColors = [NSMutableArray array];
	int i, j;
	for (i=0; i<[pointColors count]; i++)
	{
		NSArray *colors = [pointColors objectAtIndex:i];
		NSMutableArray *newColors = [NSMutableArray array];
		for (j=0; j<[colors count]; j++)
		{
			NSColor *color = [colors objectAtIndex:j];
			[newColors addObject:[self convertColorToDict:color]];
		}
		[convertedPointColors addObject:newColors];
	}
	return convertedPointColors;
}

- (NSArray*)convertCurvesForPlist;
{
	NSMutableArray *convertedCurves = [NSMutableArray array];
	int i, j;
	for (i=0; i<[curves count]; i++)
	{
		NSArray *curve = [curves objectAtIndex:i];
		NSMutableArray *newCurves = [NSMutableArray array];
		for (j=0; j<[curve count]; j++)
		{
			NSPoint point = [[curve objectAtIndex:j] pointValue];
			[newCurves addObject:[self convertPointToDict:point]];
		}
		[convertedCurves addObject:newCurves];
	}
	return convertedCurves;
}

- (NSDictionary*)convertColorToDict:(NSColor*)color;
{
	NSColor *safeColor = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithFloat:[safeColor redComponent]] forKey:@"red"];
	[dict setObject:[NSNumber numberWithFloat:[safeColor greenComponent]] forKey:@"green"];
	[dict setObject:[NSNumber numberWithFloat:[safeColor blueComponent]] forKey:@"blue"];
	return dict;
}

- (NSDictionary*)convertPointToDict:(NSPoint)point;
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithFloat:point.x] forKey:@"x"];
	[dict setObject:[NSNumber numberWithFloat:point.y] forKey:@"y"];
	return dict;
}

#pragma mark conversion from plist

+ (NSMutableArray*)convertPointColorsFromPlist:(NSArray*)plistPointColor;
{
	NSMutableArray *convertedPointColors = [NSMutableArray array];
	int i, j;
	for (i=0; i<[plistPointColor count]; i++)
	{
		NSArray *colors = [plistPointColor objectAtIndex:i];
		NSMutableArray *newColors = [NSMutableArray array];
		for (j=0; j<[colors count]; j++)
		{
			NSDictionary *colorDict = [colors objectAtIndex:j];
			NSColor *color = [NSColor colorWithCalibratedRed:[[colorDict objectForKey:@"red"] floatValue] green:[[colorDict objectForKey:@"green"] floatValue] blue:[[colorDict objectForKey:@"blue"] floatValue] alpha:1.0];
			[newColors addObject:color];
		}
		[convertedPointColors addObject:newColors];
	}
	return convertedPointColors;
}

+ (NSMutableArray*)convertCurvesFromPlist:(NSArray*)plistCurves;
{
	NSMutableArray *convertedCurves = [NSMutableArray array];
	int i, j;
	for (i=0; i<[plistCurves count]; i++)
	{
		NSArray *curve = [plistCurves objectAtIndex:i];
		NSMutableArray *newCurve = [NSMutableArray array];
		for (j=0; j<[curve count]; j++)
		{
			NSDictionary *pointDict = [curve objectAtIndex:j];
			NSPoint point = NSMakePoint([[pointDict objectForKey:@"x"] floatValue], [[pointDict objectForKey:@"y"] floatValue]);
			[newCurve addObject:[NSValue valueWithPoint:point]];
		}
		[convertedCurves addObject:newCurve];
	}
	return convertedCurves;
}

#pragma mark -
#pragma mark Connection to VRView

- (void)setCLUTtoVRView;
{
    if( windowWillClose)
        return;
    
	[self setCLUTtoVRView:vrViewLowResolution];
    
	if(clutChanged)
        [[vrView controller] setCurCLUTMenu:NSLocalizedString(@"16-bit CLUT", nil)];
}

- (void)setCLUTtoVRViewHighRes;
{
	if( curves)
		[self setCLUTtoVRView: NO];
}

- (void)setCLUTtoVRView:(BOOL)lowRes;
{
    if( windowWillClose)
        return;
    
	if( setCLUTtoVRView)
        return;	// avoid re-entry
    
	setCLUTtoVRView = YES;
	if([curves count]>0)
	{
		NSMutableDictionary *clut = [NSMutableDictionary dictionaryWithCapacity: 2];
		[clut setObject:curves forKey:@"curves"];
		[clut setObject:pointColors forKey:@"colors"];
		//[clut setObject:name forKey:@"name"];
		
		[vrView setAdvancedCLUT:clut lowResolution:lowRes];

		int curveIndex = [self selectedCurveIndex];
		if(curveIndex<0) curveIndex = 0;
		
		NSMutableArray *theCurve = [curves objectAtIndex:curveIndex];
		NSPoint firstPoint = [[theCurve objectAtIndex:0] pointValue];
		NSPoint lastPoint = [[theCurve lastObject] pointValue];
		float ww = (lastPoint.x - firstPoint.x);
		float wl = (lastPoint.x + firstPoint.x) / 2.0;
		
		float savedWl, savedWw;
		[vrView getWLWW: &savedWl :&savedWw];
		
		if( savedWl != wl || savedWw != ww)
			[vrView setWLWW: wl : ww];
	}
	setCLUTtoVRView = NO;
	
	if( lowRes)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(setCLUTtoVRViewHighRes) object: nil];
		[self performSelector: @selector(setCLUTtoVRViewHighRes) withObject:nil afterDelay: 0.5];
	}
	else [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(setCLUTtoVRViewHighRes) object: nil];
}

- (void)setWL:(float)wl ww:(float)ww;
{
	int curveIndex = [self selectedCurveIndex];
	if(curveIndex<0) curveIndex = 0;
	
	NSMutableArray *theCurve = [curves objectAtIndex:curveIndex];
	NSPoint firstPoint = [[theCurve objectAtIndex:0] pointValue];
	NSPoint lastPoint = [[theCurve lastObject] pointValue];
	float half = (lastPoint.x - firstPoint.x) / 2.0;
	float middle = firstPoint.x + half;
	
	// wl
	float shiftWL = wl - middle;
	
	//ww
	float shiftWW = firstPoint.x + shiftWL - (wl - 0.5 * ww);
	
	NSPoint pt;
	float factor = 1.0;
	int i;
	for (i=0; i<[theCurve count]; i++)
	{
		pt = [[theCurve objectAtIndex:i] pointValue];
		factor = fabs(pt.x - middle) / half;
		if(factor<0.0) factor = 0.0;
		pt.x += shiftWL;
		if(i<[theCurve count]/2.0) pt.x -= shiftWW * factor;
		else  pt.x += shiftWW * factor;
		pt = [self legalizePoint:pt inCurve:theCurve atIndex:i];
		[theCurve replaceObjectAtIndex:i withObject:[NSValue valueWithPoint:pt]];
	}

	for (i=0; i<[theCurve count]; i++)
	{
		pt = [[theCurve objectAtIndex:i] pointValue];
		pt = [self legalizePoint:pt inCurve:theCurve atIndex:i];
		[theCurve replaceObjectAtIndex:i withObject:[NSValue valueWithPoint:pt]];
	}
	nothingChanged = NO;
	clutChanged = YES;
		
	vrViewLowResolution = YES;
	[self updateView];
}

#pragma mark -
#pragma mark Cursor

- (void)setCursorLabelWithText:(NSString*)text;
{
	if([text isEqualToString:@""])
	{
		[[NSCursor arrowCursor] set];
		return;
	}
	
	NSPoint hotSpot = [[NSCursor arrowCursor] hotSpot];

	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:textLabelColor forKey:NSForegroundColorAttributeName];
	
	if( text == nil) text = @"";
	
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:text attributes:attrsDictionary] autorelease];
//	NSRect labelBounds = [label boundingRectWithSize:[self bounds].size options:NSStringDrawingUsesDeviceMetrics];
	NSRect labelBounds = [label boundingRectWithSize:drawingRect.size options:NSStringDrawingUsesDeviceMetrics];

	NSSize imageSize = [[[NSCursor arrowCursor] image] size];
	float arrowWidth = imageSize.width;
	imageSize.width += labelBounds.size.width;
	NSImage *cursorImage = [[NSImage alloc] initWithSize: imageSize];
	NSPoint labelPosition = NSMakePoint(arrowWidth-6, .0);
	
	// draw
	if( [cursorImage size].width > 0 && [cursorImage size].height > 0)
	{
		[cursorImage lockFocus];
		[[[NSCursor arrowCursor] image] drawAtPoint: NSMakePoint( 0, 0) fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];
		[[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
		//NSRectFill(NSMakeRect(labelPosition.x-2, labelPosition.y+1, labelBounds.size.width+4, labelBounds.size.height+4));
		NSRectFill(NSMakeRect(labelPosition.x-2, labelPosition.y+1, labelBounds.size.width+4, 13)); // nicer if the height stays the same when moving the mouse
		[label drawAtPoint:labelPosition];
		[cursorImage unlockFocus];
	}
	
	NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:hotSpot];
	[cursor set];
	
	[cursorImage release];
	[cursor release];
}


#pragma mark -
#pragma mark Overlapping curves

- (BOOL)doesCurve:(NSArray*)curveA overlapCurve:(NSArray*)curveB;
{
	NSPoint firstPointCurveA = [[curveA objectAtIndex:0] pointValue];
	NSPoint lastPointCurveA = [[curveA lastObject] pointValue];
	NSPoint firstPointCurveB = [[curveB objectAtIndex:0] pointValue];
	NSPoint lastPointCurveB = [[curveB lastObject] pointValue];
	
	BOOL b1 = (firstPointCurveA.x>=firstPointCurveB.x) && (firstPointCurveA.x<=lastPointCurveB.x);
	BOOL b2 = (lastPointCurveA.x>=firstPointCurveB.x) && (lastPointCurveA.x<=lastPointCurveB.x);
	BOOL b3 = (firstPointCurveB.x>=firstPointCurveA.x) && (firstPointCurveB.x<=lastPointCurveA.x);
	BOOL b4 = (lastPointCurveB.x>=firstPointCurveA.x) && (lastPointCurveB.x<=lastPointCurveA.x);
	
	return b1 || b2 || b3 || b4;
}

- (NSArray*)resolveOverlappingCurves;
{
	NSMutableArray *resolvedCurves = [NSMutableArray array];
	
	int i, j, k, l;
	for (i=0; i<[curves count]; i++)
	{
		for (j=i+1; j<[curves count]; j++)
		{
			NSArray *curveI = [curves objectAtIndex:i];
			NSArray *curveJ = [curves objectAtIndex:j];
			if([self doesCurve:curveI overlapCurve:curveJ])
			{
				k=0;
				l=0;
				while(k<[curveI count] && l<[curveJ count])
				{
					
				}
			}
		}
	}
	
	return resolvedCurves;
}

@end
