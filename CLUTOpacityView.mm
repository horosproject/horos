//
//  CLUTOpacityView.m
//  OsiriX
//
//  Created by joris on 15/01/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "CLUTOpacityView.h"
#import "BrowserController.h"

@implementation CLUTOpacityView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		backgroundColor = [NSColor blackColor];
		histogramOpacity = 0.25;
		histogramColor = [NSColor lightGrayColor];
		pointsColor = [NSColor blackColor];
		pointsBorderColor = [NSColor blackColor];
		textLabelColor = [NSColor whiteColor];
		selectedPointColor = [NSColor whiteColor];
		curveColor = [NSColor grayColor];
		
		HUmin = -1000.0;
		HUmax = 1000.0;
		curves = [[NSMutableArray arrayWithCapacity:0] retain];
		pointColors = [[NSMutableArray arrayWithCapacity:0] retain];
		colorPanel = [NSColorPanel sharedColorPanel];
		selectedPoint.y = -1.0;
		pointDiameter = 8;
		lineWidth = 3;
		pointBorder = 2;
		zoomFactor = 1.0;
		zoomFixedPoint = 0.0;
		vrViewLowResolution = NO;
		didResizeVRVIew = NO;
		mousePositionX = 0.0;
		
		[self computeHistogram];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePointColor:) name:@"NSColorPanelColorDidChangeNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(computeHistogram:) name:@"updateVolumeData" object:nil];
		
		[self createContextualMenu];
		undoManager = [[NSUndoManager alloc] init];
		
		[self updateView];
    }
    return self;
}

- (void)cleanup;
{
	if(curves) [curves release];
	curves = [[NSMutableArray arrayWithCapacity:0] retain];
	if(pointColors) [pointColors release];
	pointColors = [[NSMutableArray arrayWithCapacity:0] retain];
	[self computeHistogram];
	didResizeVRVIew = NO;
	[self updateView];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if(histogram) free(histogram);
	[curves release];
	[pointColors release];
	[selectedPointColor release];
	[contextualMenu release];
	[undoManager release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
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
	HUmin = min;
	HUmax = max;
}

- (void)computeHistogram;
{
	vImage_Buffer buffer;
	buffer.data = volumePointer;
	buffer.height = 1;
	buffer.width = voxelCount;
	buffer.rowBytes = voxelCount * sizeof(float);
	
	histogramSize = (int)((HUmax-HUmin)/2);
	if(histogram) free(histogram);
	histogram = (vImagePixelCount*) malloc(sizeof(vImagePixelCount) * histogramSize);
	vImageHistogramCalculation_PlanarF(&buffer, histogram, histogramSize, HUmin, HUmax, kvImageDoNotTile);
	
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
NSLog(@"max : %u", max);
NSLog(@"max : %qu", max);
	float heightFactor = (max==0)? 1.0 : 1.0 / max;
	NSLog(@"heightFactor : %f", heightFactor);
	float binWidth = (HUmax - HUmin) / histogramSize;

	NSBezierPath *line = [NSBezierPath bezierPath];

	[line moveToPoint:[transform transformPoint:NSMakePoint(HUmin, 0.0)]];
	for(i=0; i<histogramSize; i++)
	{
		NSPoint pt = NSMakePoint(HUmin + i * binWidth, histogram[i] * heightFactor);
		//NSLog(@"pt : %f, %f", pt.x, pt.y);
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

	BOOL needsShift = NO;
	NSPoint c1, c2;
	int i;
	for (i=0; i<[curves count]; i++)
	{
		c1 = [[[curves objectAtIndex:i] objectAtIndex:0] pointValue];
		c2 = [[[curves objectAtIndex:i] lastObject] pointValue];
		needsShift = (pt1.x>c1.x-40 && pt1.x<c1.x+40) || (pt2.x>c2.x-40 && pt2.x<c2.x+40);
		
		if(needsShift)
		{
			pt1.x += 40;
			pt2.x += 40;
			pt3.x += 40;
			pt4.x += 40;
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
	[self updateView];
}

- (void)fillCurvesInRect:(NSRect)rect;
{
	int i, j;
		
	NSAffineTransform* transform = [self transform];
	
	for (i=[curves count]-1; i>=0; i--)
	{
		NSArray *aCurve = [curves objectAtIndex:i];

		// GRADIENT FILL
		NSRect smallRect;
		NSPoint p0, p1;
		NSColor *c, *c0, *c1;
		for (j=0; j<[aCurve count]-1; j++)
		{
			p0 = [transform transformPoint:[[aCurve objectAtIndex:j] pointValue]];
			p1 = [transform transformPoint:[[aCurve objectAtIndex:j+1] pointValue]];
			c0 = [[pointColors objectAtIndex:i] objectAtIndex:j];
			c1 = [[pointColors objectAtIndex:i] objectAtIndex:j+1];
			int numberOfSmallRect = p1.x - p0.x + 1;
			int n;
			for(n=0; n<numberOfSmallRect; n++)
			{
				if(p0.y<p1.y)
					smallRect = NSMakeRect(p0.x+n, 0, 2, ((numberOfSmallRect-n)*p0.y+n*p1.y)/numberOfSmallRect);
				else
					smallRect = NSMakeRect(p0.x+n-1, 0, 2, ((numberOfSmallRect-n)*p0.y+n*p1.y)/numberOfSmallRect);
					
				c = [c0 blendedColorWithFraction:(float)n/(float)numberOfSmallRect ofColor:c1];
				[c set];
				NSRectFill(smallRect);
			}
		}
	}
}

- (void)drawCurvesInRect:(NSRect)rect;
{
	int i, j;
		
	NSAffineTransform* transform = [self transform];
	
	for (i=[curves count]-1; i>=0; i--)
	{
		NSArray *aCurve = [curves objectAtIndex:i];
	
		// CONTROL POINT SELECTED?
		NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
		BOOL controlPointSelected = NO;
		if([self isAnyPointSelected])
		{
			if(selectedPoint.x==controlPoint.x && selectedPoint.y==controlPoint.y)
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
				if(selectedPoint.x==pt.x && selectedPoint.y==pt.y)
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
			[[[pointColors objectAtIndex:i] objectAtIndex:j] set];
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
			[self drawPointLabelAtPosition:[[aCurve objectAtIndex:[aCurve count]-1] pointValue]];
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
	if(i != [curves count]-1)
	{
		nothingChanged = NO;
		[self moveCurveAtIndex:i toIndex:[curves count]-1];
	}
}

- (void)sendToFrontCurveAtIndex:(int)i;
{
	if(i != 0)
	{
		nothingChanged = NO;
		[self moveCurveAtIndex:i toIndex:0];
	}
}

- (int)selectedCurveIndex;
{
	int i, j;
	int curveIndex = -1;
	for (i=0; i<[curves count] && curveIndex<0; i++)
	{
		NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
		if(selectedPoint.x==controlPoint.x && selectedPoint.y==controlPoint.y)
			curveIndex = i;
	}
	return curveIndex;
}

- (void)selectCurveAtIndex:(int)i;
{
	NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
	selectedPoint = controlPoint;
}

- (void)setColor:(NSColor*)color forCurveAtIndex:(int)curveIndex;
{
	nothingChanged = NO;
	[[undoManager prepareWithInvocationTarget:self] setColors:[NSMutableArray arrayWithArray:[pointColors objectAtIndex:curveIndex]] forCurveAtIndex:curveIndex];
	int i;
	for (i=0; i<[[curves objectAtIndex:curveIndex] count]; i++)
	{
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:i withObject:color];
	}
}

- (void)setColors:(NSArray*)colors forCurveAtIndex:(int)curveIndex;
{
	nothingChanged = NO;
	[[undoManager prepareWithInvocationTarget:self] setColors:[NSMutableArray arrayWithArray:[pointColors objectAtIndex:curveIndex]] forCurveAtIndex:curveIndex];
	int i;
	for (i=0; i<[[curves objectAtIndex:curveIndex] count]; i++)
	{
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:i withObject:[colors objectAtIndex:i]];
	}
}

- (void)shiftCurveAtIndex:(int)curveIndex shift:(float)aShift
{
	[[undoManager prepareWithInvocationTarget:self] shiftCurveAtIndex:curveIndex shift:-aShift];
	NSMutableArray *theCurve = [curves objectAtIndex:curveIndex];
	NSPoint pt;
	int i;
	for (i=0; i<[theCurve count]; i++)
	{
		pt = [[theCurve objectAtIndex:i] pointValue];
		pt.y += aShift;
		[theCurve replaceObjectAtIndex:i withObject:[NSValue valueWithPoint:pt]];
	}
}

#pragma mark -
#pragma mark Coordinate to NSView Transform

- (NSAffineTransform*)transform;
{
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:-HUmin*[self bounds].size.width/(HUmax-HUmin)*zoomFactor yBy:0.0];
	[transform scaleXBy:[self bounds].size.width/(HUmax-HUmin)*zoomFactor yBy:[self bounds].size.height];
	NSAffineTransform* transform2 = [NSAffineTransform transform];
	[transform2 translateXBy:-zoomFixedPoint*(zoomFactor-1.0) yBy:0.0];
	[transform appendTransform:transform2];
	return transform;
}

#pragma mark -
#pragma mark Global draw method

- (void)drawRect:(NSRect)rect
{
	[backgroundColor set];
	NSRectFill(rect);
	[self fillCurvesInRect:rect];
	[self drawHistogramInRect:rect];
	[self drawCurvesInRect:rect];
}

- (void)updateView;
{
	[self setNeedsDisplay:YES];
	if(!nothingChanged)[self setCLUTtoVRView];
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
				[colorPanel setColor:[[pointColors objectAtIndex:i] objectAtIndex:j]];
				[self sendToFrontCurveAtIndex:i];
				//[self updateView];
				return YES;
			}
		}
	}
	return NO;
}

- (void)unselectPoints;
{
	selectedPoint.y = -1.0;
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
		int i, j;
		for (i=0; i<[curves count]; i++)
		{
			NSMutableArray *aCurve = [curves objectAtIndex:i];
			for (j=0; j<[aCurve count]; j++)
			{
				NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
				if(pt.x==selectedPoint.x && pt.y==selectedPoint.y)
				{
					[self setColor:[(NSColorPanel*)[notification object] color] forPointAtIndex:j inCurveAtIndex:i];
					[self updateView];
					return;
				}
			}
			NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
			if(controlPoint.x==selectedPoint.x && controlPoint.y==selectedPoint.y)
			{
				[self setColor:[(NSColorPanel*)[notification object] color] forCurveAtIndex:i];
				[self updateView];
				return;
			}
		}
	}
}

- (void)setColor:(NSColor*)color forPointAtIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex;
{
	nothingChanged = NO;
	[[undoManager prepareWithInvocationTarget:self] setColor:[[pointColors objectAtIndex:curveIndex] objectAtIndex:pointIndex] forPointAtIndex:pointIndex inCurveAtIndex:curveIndex];
	[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:pointIndex withObject:color];
}

- (NSPoint)legalizePoint:(NSPoint)point inCurve:(NSArray*)aCurve atIndex:(int)j;
{
	if(point.y<0.0) point.y = 0.0;
	if(point.y>=0.999) point.y = 0.999;
					
	if(j>0)
		if(point.x<=[[aCurve objectAtIndex:j-1] pointValue].x+10) point.x = [[aCurve objectAtIndex:j-1] pointValue].x+10;
	if(j<[aCurve count]-1)
		if(point.x>=[[aCurve objectAtIndex:j+1] pointValue].x-10) point.x = [[aCurve objectAtIndex:j+1] pointValue].x-10;
			
	return point;
}

- (void)drawPointLabelAtPosition:(NSPoint)pt;
{
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:textLabelColor forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"value : %.0f\nalpha : %1.3f", pt.x, pt.y*pt.y] attributes:attrsDictionary] autorelease];
	NSAttributedString *labelValue = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"value : %.0f", pt.x] attributes:attrsDictionary] autorelease];
	NSAttributedString *labelAlpha = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"alpha : %1.3f", pt.y*pt.y] attributes:attrsDictionary] autorelease];
	
	NSAffineTransform* transform = [self transform];
	NSPoint pt1 = [transform transformPoint:pt];
	NSPoint labelPosition = NSMakePoint(pt1.x + pointDiameter, pt1.y + pointDiameter);
				
	NSRect rect = [self bounds];
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
	else if(ip==0 || ip==[theCurve count]-1) return;
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
		controlPoint.x = [[aCurve objectAtIndex:([aCurve count]-1)/2] pointValue].x;
		controlPoint.y = [[aCurve objectAtIndex:([aCurve count]-1)/2] pointValue].y/2.0;
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
	int i;
	NSPoint controlPoint;
	
	for (i=0; i<[curves count]; i++)
	{
		controlPoint = [self controlPointForCurveAtIndex:i];
		if(position.x>=controlPoint.x-pointDiameter && position.y>=controlPoint.y-pointDiameter && position.x<=controlPoint.x+pointDiameter && position.y<=controlPoint.y+pointDiameter)
		{
			selectedPoint = controlPoint;
			[self sendToFrontCurveAtIndex:i];
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
	NSPoint pt0, pt1, p0, p1, newPoint;
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
		[transform invert];
		NSPoint newPoint = [transform transformPoint:position];
		selectedPoint.x = newPoint.x;
		selectedPoint.y = newPoint.y;
		float blendingFactor = (newPoint.x - [[aCurve objectAtIndex:j-2] pointValue].x) / ([[aCurve objectAtIndex:j-1] pointValue].x - [[aCurve objectAtIndex:j-2] pointValue].x);
		[self addPoint:newPoint atIndex:j-1 inCurveAtIndex:i-1 withColor:[[colors objectAtIndex:j-2] blendedColorWithFraction:blendingFactor ofColor:[colors objectAtIndex:j-1]]];
		[self sendToFrontCurveAtIndex:i-1];
		[self updateView];
	}
	
	return addPoint;
}

#pragma mark -
#pragma mark Mouse

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	NSPoint mousePositionInWindow = [theEvent locationInWindow];
	NSPoint mousePositionInView = [self convertPoint:mousePositionInWindow fromView:nil];
	
	nothingChanged = YES;
	[undoManager beginUndoGrouping];
	
	vrViewLowResolution = YES;
	
	if(![self selectPointAtPosition:mousePositionInView])
	{
		[self unselectPoints];
		if(![self selectControlPointAtPosition:mousePositionInView])
		{
			if(![self clickOnLineAtPosition:mousePositionInView])
			{
				NSAffineTransform* transformView2Coordinate = [self transform];
				[transformView2Coordinate invert];
				zoomFixedPoint = [transformView2Coordinate transformPoint:mousePositionInView].x;
			}
		}
		else if([theEvent clickCount] == 2)
		{
			nothingChanged = YES;
			[colorPanel orderFront:self];
		}
	}
	else if([theEvent clickCount] == 2)
	{
		nothingChanged = YES;
		[colorPanel orderFront:self];
	}
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	[undoManager endUndoGrouping];
	
	if([theEvent clickCount] == 2 || nothingChanged)
	{
		[undoManager undoNestedGroup];
	}
	
	vrViewLowResolution = NO;
	if(!nothingChanged)[self setCLUTtoVRView];
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
	if([self isAnyPointSelected])
	{
		nothingChanged = NO;
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
					if(pt.x==selectedPoint.x && pt.y==selectedPoint.y)
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
				BOOL firstPointSelected = (firstPoint.x==selectedPoint.x && firstPoint.y==selectedPoint.y);
				BOOL lastPointSelected = (lastPoint.x==selectedPoint.x && lastPoint.y==selectedPoint.y);
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
							alpha = fabsf(pt.x - lastPoint.x) / d;
						else
							alpha = fabsf(pt.x - firstPoint.x) / d;
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
			if(controlPoint.x==selectedPoint.x && controlPoint.y==selectedPoint.y)
			{			
				NSPoint newPointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
				NSPoint newPoint = [transformView2Coordinate transformPoint:newPointInView];
								
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
						float alpha = 1.0;
						if(j>0 && j<[aCurve count]-1)
							alpha = 2.0*fabsf(middlePointX - pt.x) / d;
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
		if(fabsf([theEvent deltaX])>fabsf([theEvent deltaY]))
		{
			zoomFixedPoint -= [theEvent deltaX];
		}
		else
		{
			if([theEvent deltaY]<0.0) zoomFactor += 0.1;
			if([theEvent deltaY]>0.0) zoomFactor -= 0.1;
			if(zoomFactor<1.0) zoomFactor = 1.0;
			if(zoomFactor>5.0) zoomFactor = 5.0;
			[self setCursorLabelWithText:[NSString stringWithFormat:@"zoom x %.1f", zoomFactor]];
		}
		[self updateView];
	}
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	[super mouseMoved:theEvent];

	if(![[self window] isMainWindow]) return;
	if(![[self window] isKeyWindow]) return;

	//[[NSCursor arrowCursor] set];	
	
	NSPoint mousePositionInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if(!NSPointInRect(mousePositionInView, [self bounds]))
	{
		[[NSCursor arrowCursor] set];
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
	unichar c = [[theEvent characters] characterAtIndex:0];
	if(c==NSDeleteCharacter)
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
	[self computeHistogram];
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
	int i, j;
	int curveIndex = -1;

	for (i=0; i<[curves count] && curveIndex<0; i++)
	{
		NSArray *aCurve = [curves objectAtIndex:i];
		for (j=0; j<[aCurve count] && curveIndex<0; j++)
		{
			NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
			if(selectedPoint.x==pt.x && selectedPoint.y==pt.y)
				curveIndex = i;
		}
	}

	if(curveIndex<0)
	{
		for (i=0; i<[curves count] && curveIndex<0; i++)
		{
			NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
			if(selectedPoint.x==controlPoint.x && selectedPoint.y==controlPoint.y)
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
	zoomFixedPoint = [sender floatValue] / [sender maxValue] * [self bounds].size.width;
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

#pragma mark -
#pragma mark Copy / Paste

- (IBAction)copy:(id)sender;
{
	int curveIndex = [self selectedCurveIndex];
	
	if(curveIndex >= 0)
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
					if(selectedPoint.x==pt.x && selectedPoint.y==pt.y)
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
		
		int selectedCurveIndex = [self selectedCurveIndex];
		NSMutableArray *selectedCurve;
		if(selectedCurveIndex>=0)
			selectedCurve = [curves objectAtIndex:selectedCurveIndex];
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
					if(selectedPoint.x==pt.x && selectedPoint.y==pt.y)
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
	
	if(curveIndex >= 0)
	{
		[self deleteCurveAtIndex:curveIndex];
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
					if(selectedPoint.x==pt.x && selectedPoint.y==pt.y)
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
		[self updateView];
	}
}

- (IBAction)redo:(id)sender;
{
	if([undoManager canRedo])
	{
		[undoManager redo];
		[self updateView];
	}
}

#pragma mark -
#pragma mark Archiving

#define CLUTDATABASE @"/CLUTs/"

- (void)chooseNameAndSave:(id)sender;
{
	[NSApp beginSheet:chooseNameAndSaveWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
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
	[clut setObject:curves forKey:@"curves"];
	[clut setObject:pointColors forKey:@"colors"];
	[clut setObject:name forKey:@"name"];

	NSMutableString *path = [NSMutableString stringWithString: [[BrowserController currentBrowser] documentsDirectory]];
	[path appendString:CLUTDATABASE];
	
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	
	[path appendString:name];
	[NSArchiver archiveRootObject:clut toFile:path];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateCLUTMenu" object:name userInfo:0L];
}

- (void)loadFromFileWithName:(NSString*)name;
{
	NSMutableString *path = [NSMutableString stringWithString: [[BrowserController currentBrowser] documentsDirectory]];
	[path appendString:CLUTDATABASE];
	[path appendString:name];
	
	NSMutableDictionary *clut = [NSUnarchiver unarchiveObjectWithFile:path];
	curves = [clut objectForKey:@"curves"];
	[curves retain];
	pointColors = [clut objectForKey:@"colors"];
	[pointColors retain];
}

#pragma mark -
#pragma mark Connection to VRView

- (void)setCLUTtoVRView;
{
	[self setCLUTtoVRView:vrViewLowResolution];
}

- (void)setCLUTtoVRView:(BOOL)lowRes;
{
	if([curves count]>0)
	{
		NSMutableDictionary *clut = [NSMutableDictionary dictionaryWithCapacity:2];
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
		factor = fabsf(pt.x - middle) / half;
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
	vrViewLowResolution = YES;
	[self updateView];
}

#pragma mark -
#pragma mark Window

//- (void)windowWillClose:(NSNotification *)aNotification
//{
//	if(vrView)
//	{
//		if([[aNotification object] isEqualTo:[self window]])
//		{
////			[[vrView window] removeChildWindow:[self window]];
//	[[[[vrView window] drawers] objectAtIndex:0] close];
//			if([vrView controller])
//			{
//				[[vrView window] zoom:self];
//				[vrView squareView:self];
//				[[[vrView controller] OpacityPopup] setEnabled:YES];
//			}
//			didResizeVRVIew = NO;
//		}
//		else if([[aNotification object] isEqualTo:[vrView window]])
//		{
//			didResizeVRVIew = NO;
//		}
//	}
//}

//- (void)windowDidMove:(NSNotification *)aNotification
//{
//	if(vrView)
//	{
//		if([[aNotification object] isEqualTo:[vrView window]])
//		{
//			if(vrView && [[self window] isVisible]) [self niceDisplay];
//		}
//	}
//}
//
//- (void)windowDidResignMain:(NSNotification *)aNotification
//{
//	if(vrView)
//	{
//		if([[aNotification object] isEqualTo:[vrView window]])
//		{
//			if([[self window] isVisible])
//				[[self window] orderWindow:NSWindowBelow relativeTo:[[vrView window] windowNumber]];
//	//			[[self window] orderBack:self];
//				
//		}
//	}
//}
//
//- (void)windowDidBecomeMain:(NSNotification *)aNotification
//{
//	if(vrView)
//	{
//		if([[aNotification object] isEqualTo:[vrView window]])
//		{
//			if([[self window] isVisible])
//				[[self window] orderFront:self];
//				//[[self window] orderWindow:NSWindowBelow relativeTo:[[vrView window] windowNumber]];
//				//[[self window] orderFront:self];
//		}
////		else if([[aNotification object] isEqualTo:[self window]])
////		{
////			//[[vrView window] orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
////			[[vrView window] orderFront:self];
////		}
//	}
//}
//
//- (void)windowDidBecomeKey:(NSNotification *)aNotification
//{
//	if(vrView)
//	{
//		if([[aNotification object] isEqualTo:[self window]])
//		{
//			[[vrView window] orderFront:self];
//		}
//	}
//}

#pragma mark -
#pragma mark Cursor

- (void)setCursorLabelWithText:(NSString*)text;
{
	NSPoint hotSpot = [[NSCursor arrowCursor] hotSpot];
	NSImage *cursorImage = [[[NSCursor arrowCursor] image] copy];

	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:textLabelColor forKey:NSForegroundColorAttributeName];
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:text attributes:attrsDictionary] autorelease];
	NSRect labelBounds = [label boundingRectWithSize:[self bounds].size options:NSStringDrawingUsesDeviceMetrics];

	NSSize imageSize = [cursorImage size];
	float arrowWidth = imageSize.width;
	imageSize.width += labelBounds.size.width;
	[cursorImage setSize:imageSize];
	NSPoint labelPosition = NSMakePoint(arrowWidth-6, .0);
	
	// draw
	[cursorImage lockFocus];
	[[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
	//NSRectFill(NSMakeRect(labelPosition.x-2, labelPosition.y+1, labelBounds.size.width+4, labelBounds.size.height+4));
	NSRectFill(NSMakeRect(labelPosition.x-2, labelPosition.y+1, labelBounds.size.width+4, 13)); // nicer if the height stays the same when moving the mouse
	[label drawAtPoint:labelPosition];
	[cursorImage unlockFocus];
	NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:hotSpot];
	[cursor set];
	
	[cursorImage release];
	[cursor release];
}

@end
