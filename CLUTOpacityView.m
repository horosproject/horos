//
//  CLUTOpacityView.m
//  OsiriX
//
//  Created by joris on 15/01/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "CLUTOpacityView.h"


@implementation CLUTOpacityView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		backgroundColor = [NSColor blackColor];
		histogramOpacity = 0.5;
		histogramColor = [NSColor lightGrayColor];
		pointsColor = [NSColor blackColor];
		pointsBorderColor = [NSColor blackColor];
		selectedPointColor = [NSColor greenColor];
		curveColor = [NSColor whiteColor];
		
		HUmin = -1000.0;
		HUmax = 1000.0;
		curves = [[NSMutableArray arrayWithCapacity:0] retain];
		pointColors = [[NSMutableArray arrayWithCapacity:0] retain];
		colorPanel = [NSColorPanel sharedColorPanel];
		selectedPoint.y = -1.0;
		pointDiameter = 10;
		lineWidth = 2;
		//[self newCurve];
		[self computeHistogram];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePointColor:) name:@"NSColorPanelColorDidChangeNotification" object:nil];
		[self createContextualMenu];
		undoManager = [[NSUndoManager alloc] init];
		[self niceDisplay];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if(histogram) free(histogram);
	[curves release];
	[pointColors release];
	[contextualMenu release];
	[undoManager release];
	[super dealloc];
}

- (void)createContextualMenu;
{
	contextualMenu = [[NSMenu alloc] init];
	[contextualMenu addItemWithTitle:NSLocalizedString(@"New Curve", nil) action:@selector(newCurve:) keyEquivalent:@""];
	[contextualMenu addItemWithTitle:NSLocalizedString(@"Send to back", nil) action:@selector(sendToBack:) keyEquivalent:@""];
}

#pragma mark -
#pragma mark Histogram

- (void)setVolumePointer:(float*)ptr width:(int)width height:(int)height numberOfSlices:(int)n;
{
	volumePointer = ptr;
	voxelCount = width * height * n;
//	imgWidth = width;
//	imgHeight = height;
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
	
	//histogramSize = 1000;
	histogramSize = (HUmax-HUmin)/2;
	if(histogram) free(histogram);
	histogram = (vImagePixelCount*) malloc(sizeof(vImagePixelCount) * histogramSize);
	vImageHistogramCalculation_PlanarF(&buffer, histogram, histogramSize, HUmin, HUmax, kvImageDoNotTile);
	
	int i, min = -1, max = 0;
	for(i=0; i<histogramSize; i++)
	{
		if(histogram[i]<min || min<0) min = histogram[i];
		if(histogram[i]>max) max = histogram[i];
	}

	float temp;
	for(i=0; i<histogramSize; i++)
	{
		temp = ((float)(histogram[i] - min) / (float)max)*10000;
		if (temp > 0)
			histogram[i] = log(temp)*1000;
		else
			histogram[i] = temp;
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
}

- (void)drawHistogramInRect:(NSRect)rect;
{
	int i, max = 0;
	for(i=2; i<histogramSize; i++)
	{
		if(histogram[i]>max) max = histogram[i];
	}
		
	float heightFactor = (max==0)? 1 : rect.size.height / max;
	float binWidth = rect.size.width / histogramSize;

	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:NSMakePoint(0.0, 0.0)];
	for(i=0; i<histogramSize; i++)
	{
		NSPoint pt = NSMakePoint(i * binWidth, histogram[i] * heightFactor);
		[line lineToPoint:pt];
	}
	
	NSPoint pt = NSMakePoint(i * binWidth,0);
	[line lineToPoint:pt];
		
	[line closePath];
	NSColor *c = [[histogramColor colorWithAlphaComponent:histogramOpacity] retain];
	[c set];
	[line fill];
}

#pragma mark -
#pragma mark Curves

- (void)newCurve;
{
	NSMutableArray *theNewCurve = [NSMutableArray arrayWithCapacity:4];

	NSPoint pt1, pt2, pt3, pt4;
	float d, middle, x1, x2;
	d = 0.05 * (HUmax-HUmin); // 10% of total graph width
	middle = HUmin + (HUmax-HUmin) * 0.5;
	x1 = middle - d;
	x2 = middle + d;
	
	pt1 = NSMakePoint(x1, 0.0);
	pt2 = NSMakePoint(x1, 0.5);
	pt3 = NSMakePoint(x2, 0.5);
	pt4 = NSMakePoint(x2, 0.0);
	
	[theNewCurve addObject:[NSValue valueWithPoint:pt1]];
	[theNewCurve addObject:[NSValue valueWithPoint:pt2]];
	[theNewCurve addObject:[NSValue valueWithPoint:pt3]];
	[theNewCurve addObject:[NSValue valueWithPoint:pt4]];
	
	[curves insertObject:theNewCurve atIndex:0];
	
	NSMutableArray *theColors = [NSMutableArray arrayWithCapacity:4];
	[theColors addObject:[NSColor yellowColor]];
	[theColors addObject:[NSColor yellowColor]];
	[theColors addObject:[NSColor redColor]];
	[theColors addObject:[NSColor redColor]];
	[pointColors insertObject:theColors atIndex:0];
	
	// select the new curve
	NSPoint controlPoint = [self controlPointForCurveAtIndex:0];
	selectedPoint = controlPoint;
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
				smallRect = NSMakeRect(p0.x+n, 0, 2, ((numberOfSmallRect-n)*p0.y+n*p1.y)/numberOfSmallRect);
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
		//[line closePath];
		line = [transform transformBezierPath:line];
		[curveColor set];
		if(controlPointSelected) [selectedPointColor set];
		[line setLineWidth:lineWidth];
		[line stroke];
		
		//[[curveColor colorWithAlphaComponent:0.2] set];
		//[line fill];
		
		// CONTROL POINT (DRAW)
		NSRect frame = NSMakeRect(controlPoint.x-pointDiameter*0.5, controlPoint.y-pointDiameter*0.5, pointDiameter, pointDiameter);
		NSBezierPath *control = [NSBezierPath bezierPathWithRect:frame];
		[control setLineWidth:lineWidth];
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
			NSRect frame1 = NSMakeRect(pt1.x-pointDiameter*0.5-lineWidth, pt1.y-pointDiameter*0.5-lineWidth, pointDiameter+2*lineWidth, pointDiameter+2*lineWidth);
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
			//if(selected)
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
	[curves insertObject:pointsArray atIndex:curveIndex];
	[pointColors insertObject:colorsArray atIndex:curveIndex];
}

- (void)deleteCurveAtIndex:(int)i;
{
	[curves removeObjectAtIndex:i];
	[pointColors removeObjectAtIndex:i];
}

- (void)sendToBackCurveAtIndex:(int)i;
{
	NSMutableArray *theCurve = [curves objectAtIndex:i];
	[curves addObject:theCurve];
	[curves removeObjectAtIndex:i];
	
	NSMutableArray *theColors = [pointColors objectAtIndex:i];
	[pointColors addObject:theColors];
	[pointColors removeObjectAtIndex:i];
}

- (void)sendToFrontCurveAtIndex:(int)i;
{
	NSMutableArray *theCurve = [curves objectAtIndex:i];
	[curves insertObject:theCurve atIndex:0];
	[curves removeObjectAtIndex:i+1];
	
	NSMutableArray *theColors = [pointColors objectAtIndex:i];
	[pointColors insertObject:theColors atIndex:0];
	[pointColors removeObjectAtIndex:i+1];
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
	int i;
	for (i=0; i<[[curves objectAtIndex:curveIndex] count]; i++)
	{
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:i withObject:color];
	}
}

- (void)setColors:(NSArray*)colors forCurveAtIndex:(int)curveIndex;
{
	int i;
	for (i=0; i<[[curves objectAtIndex:curveIndex] count]; i++)
	{
		[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:i withObject:[colors objectAtIndex:i]];
	}
}

#pragma mark -
#pragma mark Coordinate to NSView Transform

- (NSAffineTransform*)transform;
{
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:-HUmin*[self bounds].size.width/(HUmax-HUmin) yBy:0.0];
	[transform scaleXBy:[self bounds].size.width/(HUmax-HUmin) yBy:[self bounds].size.height];
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
}

#pragma mark -
#pragma mark Points selection

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
			pt = [transform transformPoint:pt];
			if(position.x>=pt.x-pointDiameter && position.y>=pt.y-pointDiameter && position.x<=pt.x+pointDiameter && position.y<=pt.y+pointDiameter)
			{
				selectedPoint = [[aCurve objectAtIndex:j] pointValue];
				[colorPanel setColor:[[pointColors objectAtIndex:i] objectAtIndex:j]];
				[self sendToFrontCurveAtIndex:i];
				[self updateView];
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
					[[undoManager prepareWithInvocationTarget:self] setColor:[[pointColors objectAtIndex:i] objectAtIndex:j] forPointAtIndex:j inCurveAtIndex:i];
					[[pointColors objectAtIndex:i] replaceObjectAtIndex:j withObject:[(NSColorPanel*)[notification object] color]];
					[self updateView];
					return;
				}
			}
			NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
			if(controlPoint.x==selectedPoint.x && controlPoint.y==selectedPoint.y)
			{
				[[undoManager prepareWithInvocationTarget:self] setColors:[NSArray arrayWithArray:[pointColors objectAtIndex:i]] forCurveAtIndex:i];
				[self setColor:[(NSColorPanel*)[notification object] color] forCurveAtIndex:i];
//				for (j=0; j<[aCurve count]; j++)
//				{
//					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
//					[[pointColors objectAtIndex:i] replaceObjectAtIndex:j withObject:[(NSColorPanel*)[notification object] color]];
//				}
				[self updateView];
				return;
			}
		}
	}
}

- (void)setColor:(NSColor*)color forPointAtIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex;
{
	[[pointColors objectAtIndex:curveIndex] replaceObjectAtIndex:pointIndex withObject:color];
}

- (NSPoint)legalizePoint:(NSPoint)point inCurve:(NSArray*)aCurve atIndex:(int)j;
{
	if(point.y<0.0) point.y = 0.0;
//	if(point.y>1.0) point.y = 1.0;
//	if(point.x<HUmin) point.x = HUmin;
//	if(point.x>HUmax) point.x = HUmax;
	
	if(j==0 || j==[aCurve count]-1) point.y = 0.0;
					
	if(j>0)
		if(point.x<=[[aCurve objectAtIndex:j-1] pointValue].x) point.x = [[aCurve objectAtIndex:j-1] pointValue].x;
	if(j<[aCurve count]-1)
		if(point.x>=[[aCurve objectAtIndex:j+1] pointValue].x) point.x = [[aCurve objectAtIndex:j+1] pointValue].x;
	
	return point;
}

- (void)drawPointLabelAtPosition:(NSPoint)pt;
{
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:curveColor forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *label = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"value : %.0f\nalpha : %1.2f", pt.x, pt.y] attributes:attrsDictionary];
	NSAttributedString *labelValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"value : %.0f", pt.x] attributes:attrsDictionary];
	NSAttributedString *labelAlpha = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"alpha : %1.2f", pt.y] attributes:attrsDictionary];
	
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
	
//	NSRectFill(NSMakeRect(labelPosition.x-2.0,labelPosition.y,labelBounds.size.width,labelBounds.size.height));
	NSBezierPath *labelRect = [NSBezierPath bezierPathWithRect:NSMakeRect(labelPosition.x-2.0,labelPosition.y,labelBounds.size.width,labelBounds.size.height)];
	[[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
	[labelRect fill];
	[label drawAtPoint:labelPosition];
}

- (void)addPoint:(NSPoint)point atIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex withColor:(NSColor*)color;
{
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
		[theCurve removeObjectAtIndex:ip];
		[[pointColors objectAtIndex:ic] removeObjectAtIndex:ip];
	}
	[self unselectPoints];
	[self updateView];
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
			[self updateView];
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
		[transform invert];
		NSPoint newPoint = [transform transformPoint:position];
//	DELETE THIS LINE	[aCurve insertObject:[NSValue valueWithPoint:newPoint] atIndex:j-1];
		selectedPoint.x = newPoint.x;
		selectedPoint.y = newPoint.y;
		float blendingFactor = (newPoint.x - [[aCurve objectAtIndex:j-2] pointValue].x) / ([[aCurve objectAtIndex:j-1] pointValue].x - [[aCurve objectAtIndex:j-2] pointValue].x);
//	DELETE THIS LINE	[colors insertObject:[[colors objectAtIndex:j-2] blendedColorWithFraction:blendingFactor ofColor:[colors objectAtIndex:j-1]] atIndex:j-1];
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
	if(![self selectPointAtPosition:mousePositionInView])
	{
		[self unselectPoints];
		if(![self selectControlPointAtPosition:mousePositionInView])
			[self clickOnLineAtPosition:mousePositionInView];
		else if([theEvent clickCount] == 2)
			[colorPanel orderFront:self];
	}
	else if([theEvent clickCount] == 2)
	{
		[colorPanel orderFront:self];
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSLog(@"NSRightMouseDown");
	[NSMenu popUpContextMenu:contextualMenu withEvent:theEvent forView:self];
}

//- (void)mouseUp:(NSEvent *)theEvent
//{
//	if([theEvent type] == NSRightMouseUp)
//	{
//		NSLog(@"NSRightMouseUp");
//		[NSMenu popUpContextMenu:contextualMenu withEvent:theEvent forView:self];
//	}
//}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[super mouseDragged:theEvent];
	if([self isAnyPointSelected])
	{
		NSAffineTransform* transformCoordinate2View = [self transform];
		NSAffineTransform* transformView2Coordinate = [self transform];
		[transformView2Coordinate invert];
		NSPoint firstPoint, lastPoint;
				
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
						NSAffineTransform* transform = [self transform];
						[transform invert];
						NSPoint newPoint = [transform transformPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
						newPoint = [self legalizePoint:newPoint inCurve:aCurve atIndex:j];								
						[aCurve replaceObjectAtIndex:j withObject:[NSValue valueWithPoint:newPoint]];
						selectedPoint.x = newPoint.x;
						selectedPoint.y = newPoint.y;
						[self updateView];
					}
				}
			}
			else //if(([theEvent modifierFlags] & NSAlternateKeyMask))
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
						[aCurve replaceObjectAtIndex:j withObject:[NSValue valueWithPoint:shiftedPoint]];
					}
					for (j=0; j<[aCurve count]; j++)
					{
						NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
						pt = [self legalizePoint:pt inCurve:aCurve atIndex:j];
						[aCurve replaceObjectAtIndex:j withObject:[NSValue valueWithPoint:pt]];
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
							[aCurve replaceObjectAtIndex:j withObject:[NSValue valueWithPoint:shiftedPoint]];
							controlPoint = [self controlPointForCurveAtIndex:i];
						}
					}
					else
					{
						shiftedPoint = NSMakePoint(pt.x+shiftX, pt.y-shiftY);
						shiftedPoint = [transformView2Coordinate transformPoint:shiftedPoint];
						[aCurve replaceObjectAtIndex:j withObject:[NSValue valueWithPoint:shiftedPoint]];
						controlPoint = [self controlPointForCurveAtIndex:i];
					}
				}
				
				for (j=0; j<[aCurve count]; j++)
				{
					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
					pt = [self legalizePoint:pt inCurve:aCurve atIndex:j];
					[aCurve replaceObjectAtIndex:j withObject:[NSValue valueWithPoint:pt]];
				}
				controlPoint = [self controlPointForCurveAtIndex:i];
				selectedPoint.x = controlPoint.x;
				selectedPoint.y = controlPoint.y;
				[self updateView];
				return;
			}
		}
	}
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
//			int i, j;
//			for (i=0; i<[curves count]; i++)
//			{
//				NSMutableArray *aCurve = [curves objectAtIndex:i];
//				for (j=0; j<[aCurve count]; j++)
//				{
//					NSPoint pt = [[aCurve objectAtIndex:j] pointValue];
//					if(pt.x==selectedPoint.x && pt.y==selectedPoint.y)
//					{
//						[self removePointAtIndex:j inCurveAtIndex:i];
//						return;
//					}
//				}
//				
//				NSPoint controlPoint = [self controlPointForCurveAtIndex:i];
//				NSAffineTransform *transform = [self transform];
//				if(controlPoint.x==selectedPoint.x && controlPoint.y==selectedPoint.y)
//				{
//					[curves removeObjectAtIndex:i];
//					[pointColors removeObjectAtIndex:i];
//					[self updateView];
//					return;
//				}
//			}
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
	[self updateView];
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
	NSRect newFrame = [[[self window] screen] frame];
	newFrame.size.height = 200;
	[[self window] setFrame:newFrame display:YES animate:YES];
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
		
		[[undoManager prepareWithInvocationTarget:self] deleteCurveAtIndex:0];
		[curves insertObject:aNewCurve atIndex:0];
		[pointColors insertObject:newColors atIndex:0];
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
						[[undoManager prepareWithInvocationTarget:[pointColors objectAtIndex:i]] replaceObjectAtIndex:j withObject:[[pointColors objectAtIndex:i] objectAtIndex:j]];
						[[pointColors objectAtIndex:i] replaceObjectAtIndex:j withObject:color];
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
		[[undoManager prepareWithInvocationTarget:self] addCurveAtindex:curveIndex withPoints:[curves objectAtIndex:curveIndex] colors:[pointColors objectAtIndex:curveIndex]];
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
							[[undoManager prepareWithInvocationTarget:self] addCurveAtindex:i withPoints:[curves objectAtIndex:i] colors:[pointColors objectAtIndex:i]];
							[self deleteCurveAtIndex:i];
						}
						else
						{
							[[undoManager prepareWithInvocationTarget:self] addPoint:[[[curves objectAtIndex:i] objectAtIndex:j] pointValue] atIndex:j inCurveAtIndex:i withColor:[[pointColors
							 objectAtIndex:i] objectAtIndex:j]];
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
	[undoManager undo];
	[self updateView];
}

- (IBAction)redo:(id)sender;
{
	[undoManager redo];
	[self updateView];
}

@end
