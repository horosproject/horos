//
//  VRPresetPreview.m
//  OsiriX
//
//  Created by joris on 08/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "VRPresetPreview.h"


@implementation VRPresetPreview

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		lowResLODFactor = 1.0;
		isEmpty = YES;
		presetIndex = -1;
	}
    
    return self;
}

-(short) setPixSource:(NSMutableArray*)pix :(float*) volumeData
{
	short   error = 0;
	long	i;
    
	[[self window] setAcceptsMouseMovedEvents: YES];
	
    [pix retain];
    pixList = pix;
	
	projectionMode = 1;
	
	data = volumeData;
	
	aRenderer = [self renderer];
	cbStart = vtkCallbackCommand::New();
	//cbStart->SetCallback( startRendering);
	//cbStart->SetClientData( self);
	
	//vtkCommand.h
//	[self renderWindow]->AddObserver(vtkCommand::StartEvent, cbStart);
//	[self renderWindow]->AddObserver(vtkCommand::EndEvent, cbStart);
//	[self renderWindow]->AddObserver(vtkCommand::AbortCheckEvent, cbStart);

	firstObject = [pixList objectAtIndex:0];
	float sliceThickness = [firstObject sliceInterval];  //[[pixList objectAtIndex:1] sliceLocation] - [firstObject sliceLocation];
	
	if( sliceThickness == 0)
	{
		NSLog(@"slice interval = slice thickness!");
		sliceThickness = [firstObject sliceThickness];
	}
	
	NSLog(@"slice: %0.2f", sliceThickness);

	wl = [firstObject wl];
	ww = [firstObject ww];
	
	isRGB = NO;
	if( [firstObject isRGB])
	{
		isRGB = YES;
		
//		long	i, size, val;
//		unsigned char	*srcPtr = (unsigned char*) data;
//		float   *dstPtr;
//		
//		size = [firstObject pheight] * [pix count];
//		size *= [firstObject pwidth];
//		size *= sizeof( float);
//		
//		dataFRGB = (float*) malloc( size);
//		
//		size /= 4;
//		
//		dstPtr = dataFRGB;
//		for( i = 0 ; i < size; i++)
//		{
//			srcPtr++;
//			val = *srcPtr++;
//			val += *srcPtr++;
//			val += *srcPtr++;
//			*dstPtr++ = val/3;
//		}
		
//		long	i, size, val;
//		unsigned char	*srcPtr = (unsigned char*) data;
//		unsigned char   *dstPtr;
//		
//		size = [firstObject pheight] * [pix count];
//		size *= [firstObject pwidth];
//		
//		dataFRGB = (unsigned char*) malloc( size*3);
//		
//		dstPtr = dataFRGB;
//		i = size;
//		while( i-->0)
//		{
//			srcPtr++;
//			*dstPtr++ = *srcPtr++;
//			*dstPtr++ = *srcPtr++;
//			*dstPtr++ = *srcPtr++;
//		}
	}
	
//	else
//	{
//		// Convert float to char
//		
//		srcf.height = [firstObject pheight] * [pix count];
//		srcf.width = [firstObject pwidth];
//		srcf.rowBytes = [firstObject pwidth] * sizeof(float);
//		
//		dst8.height = [firstObject pheight] * [pix count];
//		dst8.width = [firstObject pwidth];
//		dst8.rowBytes = [firstObject pwidth] * sizeof(char);
//		
//		data8 = (char*) malloc( dst8.height * dst8.width * sizeof(char));
//		
//		dst8.data = data8;
//		srcf.data = data;
//		
//	//	vImageConvert_FTo16S( &srcf, &dst8, 0, 1, 0);
//		vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
//	}
	else
	{
		// Convert float to short !!!
//		srcf.height = [firstObject pheight] * [pix count];
//		srcf.width = [firstObject pwidth];
//		srcf.rowBytes = [firstObject pwidth] * sizeof(float);
//		
//		dst8.height = [firstObject pheight] * [pix count];
//		dst8.width = [firstObject pwidth];
//		dst8.rowBytes = [firstObject pwidth] * sizeof(short);
//		
//		data8 = (char*) malloc( dst8.height * dst8.width * sizeof(short));
//		if( data8 == 0L) return -1;
//		
//		dst8.data = data8;
//		srcf.data = data;
//		
//		NSLog( @"maxValueOfSeries = %f", [controller maximumValue]);
//		NSLog( @"minValueOfSeries = %f", [controller minimumValue]);
//		
//		firstPixel = *(data+0);
//		secondPixel = *(data+1);
//		
//		*(data+0) = [controller maximumValue];		// To avoid the min/max saturation problem with 4D data...
//		*(data+1) = [controller minimumValue];		// To avoid the min/max saturation problem with 4D data...
		
//		[self computeValueFactor];
//		vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
	}
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);	//AVOID VTK BUG
	reader->SetDataExtentToWholeExtent();
	
	if( isRGB)
	{
		reader->SetDataScalarTypeToUnsignedChar();
		reader->SetNumberOfScalarComponents( 4);
		reader->SetImportVoidPointer(data);
	}
	else 
	{
	//	reader->SetDataScalarTypeToFloat();
		reader->SetDataScalarTypeToUnsignedShort();
		reader->SetNumberOfScalarComponents( 1);
	//	reader->SetImportVoidPointer(data);
		reader->SetImportVoidPointer(data8);
	}
	
	[firstObject orientation:cosines];
	
//	float invThick;
	
//	if( cosines[6] + cosines[7] + cosines[8] < 0) invThick = -1;
//	else invThick = 1;
	
	factor = 1.0;
//	if( [firstObject pixelSpacingX] < 0.5 || [firstObject pixelSpacingY] < 0.5 || fabs( sliceThickness) < 0.3) factor = 10;
	
	needToFlip = NO;
	if( sliceThickness < 0 )
	{
		sliceThickness = fabs( sliceThickness);
		NSLog(@"We should not be here....");
		needToFlip = YES;
		NSLog(@"Flip !!");
	}
	//
//	if( needToFlip)
//	{
//		[self flipData: (char*) volumeData :[pixList count] :[firstObject pheight] * [firstObject pwidth]];
//		
//		for(  i = 0 ; i < [pixList count]; i++)
//		{
//			[[pixList objectAtIndex: i] setfImage: volumeData + ([pixList count]-1-i)*[firstObject pheight] * [firstObject pwidth]];
//			[[pixList objectAtIndex: i] setSliceInterval: sliceThickness];
//		}
//		
//		id tempObj;
//		
//		for( i = 0; i < [pixList count]/2 ; i++)
//		{
//			tempObj = [[pixList objectAtIndex: i] retain];
//			
//			[pixList replaceObjectAtIndex: i withObject:[pixList objectAtIndex: [pixList count]-i-1]];
//			[pixList replaceObjectAtIndex: [pixList count]-i-1 withObject: tempObj];
//			
//			[tempObj release];
//		}
//		
//		firstObject = [pixList objectAtIndex: 0];
//	}
//	
//	if( [firstObject flipData])
//	{
//		NSLog(@"firstObject = [pixList lastObject]");
//		firstObject = [pixList lastObject];
//	}
	
	factor = 1.0 / [firstObject pixelSpacingX];
	NSLog(@"Thickness: %2.2f Factor: %2.2f", sliceThickness, factor);
//	factor = 1.0;
	
	if( [firstObject pixelSpacingX] == 0 || [firstObject pixelSpacingY] == 0) reader->SetDataSpacing( 1, 1, sliceThickness);
	else reader->SetDataSpacing( factor*[firstObject pixelSpacingX], factor*[firstObject pixelSpacingY], factor * sliceThickness);
	
		
//	reader->SetDataOrigin(  [firstObject originX],
//							[firstObject originY],
//							[firstObject originZ]);


//	vtkPlane *aplane = vtkPlane::New();
//	aplane->SetNormal( normalv[0], normalv[1], normalv[2]);
//	aplane->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
	
	
//	vtkPlaneWidget  *aplaneWidget = vtkPlaneWidget::New();
//	aplaneWidget->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
//	aplaneWidget->SetNormal( normal[0], normal[1], normal[2] );
//	aplaneWidget->SetResolution(10);
//	aplaneWidget->PlaceWidget();
//    aplaneWidget->SetInteractor( [self renderWindowInteractor]);
	
	opacityTransferFunction = vtkPiecewiseFunction::New();
	opacityTransferFunction->AddPoint(0, 0);
	opacityTransferFunction->AddPoint(255, 1);
//	opacityTransferFunction->ClampingOff();
	
//	vtkPiecewiseFunction	*colorTransferFunction = vtkPiecewiseFunction::New();
//	colorTransferFunction->AddPoint(0, 0);
//	colorTransferFunction->AddPoint(255, 1);
	
	colorTransferFunction = vtkColorTransferFunction::New();
//	colorTransferFunction->ClampingOff();
	
	red = vtkColorTransferFunction::New();
	red->AddRGBPoint(   0, 0, 0, 0 );
	red->AddRGBPoint( 255, 1, 0, 0 );
	
	green = vtkColorTransferFunction::New();
	green->AddRGBPoint(   0, 0, 0, 0 );
	green->AddRGBPoint( 255, 0, 1, 0 );
	
	blue = vtkColorTransferFunction::New();
	blue->AddRGBPoint(   0, 0, 0, 0 );
	blue->AddRGBPoint( 255, 0, 0, 1 );
	
	volumeProperty = vtkVolumeProperty::New();
	if( isRGB)
	{
		volumeProperty->IndependentComponentsOn();
		
		volumeProperty->SetColor( 1,red);
		volumeProperty->SetColor( 2,green);
		volumeProperty->SetColor( 3,blue);
		
		volumeProperty->SetScalarOpacity( 1, opacityTransferFunction);
		volumeProperty->SetScalarOpacity( 2, opacityTransferFunction);
		volumeProperty->SetScalarOpacity( 3, opacityTransferFunction);
		
		volumeProperty->SetComponentWeight( 0, 0);

//		volumeProperty->SetColor( 0,red);
//		volumeProperty->SetColor( 1,green);
//		volumeProperty->SetColor( 2,blue);
//		
//		volumeProperty->SetScalarOpacity( 0, opacityTransferFunction);
//		volumeProperty->SetScalarOpacity( 1, opacityTransferFunction);
//		volumeProperty->SetScalarOpacity( 2, opacityTransferFunction);
		
	}
	else
	{
		volumeProperty->SetColor( colorTransferFunction);	//	if( isRGB == NO) 
		volumeProperty->SetScalarOpacity( opacityTransferFunction);
	}
	
	
	[self setCLUT:0L :0L :0L];
	
	[self setShadingValues:0.15 :0.9 :0.3 :15];

//	volumeProperty->ShadeOn();

	if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) volumeProperty->SetInterpolationTypeToNearest();
    else volumeProperty->SetInterpolationTypeToLinear();//SetInterpolationTypeToNearest();	//SetInterpolationTypeToLinear
		
	compositeFunction = vtkVolumeRayCastCompositeFunction::New();
//	compositeFunction->SetCompositeMethodToClassifyFirst();
//	compositeFunction = vtkVolumeRayCastMIPFunction::New();
	
	LOD = 2.0;
	#if __ppc__
	LOD += 0.5;
	#endif
	
	volume = vtkVolume::New();
    volume->SetProperty( volumeProperty);
	
//	[self setEngine: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]];
	
	vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
	matrice->Element[0][0] = cosines[0];		matrice->Element[1][0] = cosines[1];		matrice->Element[2][0] = cosines[2];		matrice->Element[3][0] = 0;
	matrice->Element[0][1] = cosines[3];		matrice->Element[1][1] = cosines[4];		matrice->Element[2][1] = cosines[5];		matrice->Element[3][1] = 0;
	matrice->Element[0][2] = cosines[6];		matrice->Element[1][2] = cosines[7];		matrice->Element[2][2] = cosines[8];		matrice->Element[3][2] = 0;
	matrice->Element[0][3] = 0;					matrice->Element[1][3] = 0;					matrice->Element[2][3] = 0;					matrice->Element[3][3] = 1;

//	volume->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
	volume->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
							factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
							factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);
//	volume->SetPosition(	[firstObject originX],// * matrice->Element[0][0] + [firstObject originY] * matrice->Element[1][0] + [firstObject originZ]*matrice->Element[2][0],
//							[firstObject originY],// * matrice->Element[0][1] + [firstObject originY] * matrice->Element[1][1] + [firstObject originZ]*matrice->Element[2][1],
//							[firstObject originZ]);// * matrice->Element[0][2] + [firstObject originY] * matrice->Element[1][2] + [firstObject originZ]*matrice->Element[2][2]);
	volume->SetUserMatrix( matrice);
	matrice->Delete();
	
	volume->PickableOff();
	
	outlineData = vtkOutlineFilter::New();
	outlineData->SetInput((vtkDataSet *) reader->GetOutput());
	
    mapOutline = vtkPolyDataMapper::New();
    mapOutline->SetInput(outlineData->GetOutput());
    
    outlineRect = vtkActor::New();
    outlineRect->SetMapper(mapOutline);
    outlineRect->GetProperty()->SetColor(0,1,0);
    outlineRect->GetProperty()->SetOpacity(0.5);
//	outlineRect->SetUserMatrix( matrice);
//	outlineRect->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
//								factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
//								factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);
	outlineRect->PickableOff();

	vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
	cube->SetXPlusFaceText ( "L" );
	cube->SetXMinusFaceText( "R" );
	cube->SetYPlusFaceText ( "P" );
	cube->SetYMinusFaceText( "A" );
	cube->SetZPlusFaceText ( "S" );
	cube->SetZMinusFaceText( "I" );
	cube->SetFaceTextScale( 0.67 );

	vtkProperty* property = cube->GetXPlusFaceProperty();
	property->SetColor(0, 0, 1);
	property = cube->GetXMinusFaceProperty();
	property->SetColor(0, 0, 1);
	property = cube->GetYPlusFaceProperty();
	property->SetColor(0, 1, 0);
	property = cube->GetYMinusFaceProperty();
	property->SetColor(0, 1, 0);
	property = cube->GetZPlusFaceProperty();
	property->SetColor(1, 0, 0);
	property = cube->GetZMinusFaceProperty();
	property->SetColor(1, 0, 0);

	vtkProperty* propertyEdges = cube->GetTextEdgesProperty();
	propertyEdges->SetColor(0.5, 0.5, 0.5);
	cube->CubeOn();
	cube->FaceTextOn();
	
	orientationWidget = vtkOrientationMarkerWidget::New();
	orientationWidget->SetOrientationMarker( cube );

	cube->Delete();

	croppingBox = vtkBoxWidget::New();
//	
	croppingBox->GetHandleProperty()->SetColor(0, 1, 0);
	croppingBox->SetProp3D( volume);
	croppingBox->SetPlaceFactor( 1.0);
	croppingBox->SetHandleSize( 0.005);
	croppingBox->PlaceWidget();
	croppingBox->SetInteractor( [self getInteractor]);
	croppingBox->SetRotationEnabled( false);
	croppingBox->SetInsideOut( true);
	croppingBox->OutlineCursorWiresOff();
//	
//	cropcallback = vtkMyCallbackVR::New();
//	cropcallback->setBlendingVolume( 0L);
//	croppingBox->AddObserver(vtkCommand::InteractionEvent, cropcallback);
//		
	textWLWW = vtkTextActor::New();
	if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f", wl, ww);
	else sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
	textWLWW->SetInput( WLWWString);
	textWLWW->SetScaledText( false);												//vtkviewPort
	textWLWW->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
	textWLWW->GetPositionCoordinate()->SetValue( 0,0);
//	aRenderer->AddActor2D(textWLWW);
	
	textX = vtkTextActor::New();
//	if (isViewportResizable)
//		textX->SetInput( "X");
//	else
//		textX->SetInput( "");
//	textX->SetScaledText( false);
//	textX->GetPositionCoordinate()->SetCoordinateSystemToViewport();
//	textX->GetPositionCoordinate()->SetValue( 2., 2.);
//	aRenderer->AddActor2D(textX);
	
	for( i = 0; i < 4; i++)
	{
		oText[ i]= vtkTextActor::New();
		oText[ i]->SetInput( "X");
		oText[ i]->SetScaledText( false);
		oText[ i]->GetPositionCoordinate()->SetCoordinateSystemToNormalizedViewport();
		oText[ i]->GetTextProperty()->SetFontSize( 16);
		oText[ i]->GetTextProperty()->SetBold( true);
		oText[ i]->GetTextProperty()->SetShadow( true);
//		
//		aRenderer->AddActor2D( oText[ i]);
	}
//	oText[ 0]->GetPositionCoordinate()->SetValue( 0.01, 0.5);
//	oText[ 1]->GetPositionCoordinate()->SetValue( 0.99, 0.5);
//	oText[ 1]->GetTextProperty()->SetJustificationToRight();
//	
//	oText[ 2]->GetPositionCoordinate()->SetValue( 0.5, 0.03);
//	oText[ 2]->GetTextProperty()->SetVerticalJustificationToTop();
//	oText[ 3]->GetPositionCoordinate()->SetValue( 0.5, 0.97);
		
    aCamera = vtkCamera::New();
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
	aCamera->SetParallelProjection( true);
	
//	aCamera->ComputeViewPlaneNormal();
//	aCamera->OrthogonalizeViewUp();
    
	aCamera->Dolly(1.5);

//	_cocoaRenderWindow->SetLineSmoothing( true);
//	_cocoaRenderWindow->SetPolygonSmoothing(true);
    aRenderer->AddVolume( volume);
//	aRenderer->AddActor(outlineRect);

	aRenderer->SetActiveCamera(aCamera);
	aRenderer->ResetCamera();
	
//	[self renderWindow]->StereoRenderOn();
//	[self renderWindow]->SetStereoTypeToRedBlue();
	
	
	// 3D Cut ROI
	vtkPoints *pts = vtkPoints::New();
	vtkCellArray *rect = vtkCellArray::New();
//	
	ROI3DData = vtkPolyData::New();
    ROI3DData-> SetPoints( pts);
//	pts->Delete();
    ROI3DData-> SetLines( rect);
//	rect->Delete();
//	
	ROI3D = vtkPolyDataMapper2D::New();
//	ROI3D->SetInput( ROI3DData);
//	
	ROI3DActor = vtkActor2D::New();
//	ROI3DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
//    ROI3DActor->SetMapper( ROI3D);
//	ROI3DActor->GetProperty()->SetPointSize( 1);	//vtkProperty2D
//	ROI3DActor->GetProperty()->SetLineWidth( 2);
//	ROI3DActor->GetProperty()->SetColor(0.3,1,0);
//	
//	aRenderer->AddActor2D( ROI3DActor);
	
	//	2D Line
//	pts = vtkPoints::New();
//	rect = vtkCellArray::New();
	
	Line2DData = vtkPolyData::New();
    Line2DData-> SetPoints( pts);
	pts->Delete();
    Line2DData-> SetLines( rect);
	rect->Delete();
//	
	Line2D = vtkPolyDataMapper2D::New();
	Line2D->SetInput( Line2DData);
//	
	Line2DActor = vtkActor2D::New();
//	Line2DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
	Line2DActor->SetMapper( Line2D);
//	Line2DActor->GetProperty()->SetPointSize( 6);	//vtkProperty2D
//	Line2DActor->GetProperty()->SetLineWidth( 3);
//	Line2DActor->GetProperty()->SetColor(1,1,0);

	Line2DText = vtkTextActor::New();
//	Line2DText->SetInput( "");
//	Line2DText->SetScaledText( false);
//	Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
//	Line2DText->GetPositionCoordinate()->SetValue( 2., 2.);
//	Line2DText->GetTextProperty()->SetShadow( YES);
//	
//	aRenderer->AddActor2D( Line2DActor);
	
//	#if !__LP64__
//	orientationWidget->SetInteractor( [self getInteractor] );
//	orientationWidget->SetEnabled( 1 );
//	orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
//	orientationWidget->InteractiveOff();
//	#endif
	
	firstTime = NO;
	
	[self saView:self];
	
	[self setNeedsDisplay:YES];
	
    return error;
}

- (void) setEngine: (long) engineID
{
	[self setEngine: engineID showWait:NO];
}

- (void) dealloc
{
	volumeMapper = 0L;
	data8 = 0L;
	[super dealloc];
}

- (void)setIsEmpty:(BOOL)empty;
{
	isEmpty = empty;
	[self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)aRect
{
//	[[NSColor whiteColor] set];
//	NSRectFill(aRect);
//	NSRect newRect = NSMakeRect(aRect.origin.x+1, aRect.origin.y+1, aRect.size.width-2, aRect.size.height-2);
	
	if(isEmpty)
	{
		// trick to "hide" content of the vr view
		[self setShadingValues: 0.0 :0.0 :0.0 :0.0];
		[self changeColorWith:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
	}
	
	[super drawRect:aRect];
	
//	if(isEmpty)
//	{
//		[self setShadingValues: 0.0 :0.0 :0.0 :0.0];// trick to "hide" the view
//		[self lockFocus];
//		[[NSColor blackColor] set];
//		NSRectFill(aRect);
//		[self unlockFocus];
//	}
	
//    glEnable(GL_POINT_SMOOTH);
//    glEnable(GL_LINE_SMOOTH);
//	glEnable(GL_POLYGON_SMOOTH);
//	glEnable(GL_BLEND);
//	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
//
//	
//	glColor3f(1.0, 1.0, 1.0);
//	glLineWidth(1.0);
//	glBegin(GL_LINE_LOOP);
//		glVertex2f(0.0 - aRect.size.width * 0.5, 0.0 - aRect.size.height * 0.5);
//		glVertex2f(0.0 + aRect.size.width * 0.5, 0.0 - aRect.size.height * 0.5);
//		glVertex2f(0.0 + aRect.size.width * 0.5, 0.0 + aRect.size.height * 0.5);
//		glVertex2f(0.0 - aRect.size.width * 0.5, 0.0 + aRect.size.height * 0.5);
//	glEnd();

	
}

- (void)setSelected;
{
	if(isEmpty) return;
	[selectionView setFrame:NSMakeRect([self frame].origin.x-2,[self frame].origin.y-2,[self frame].size.width+4,[self frame].size.height+4)];
	[selectionView setHidden:NO];
	
	[presetController setSelectedPresetPreview:self];
	
	[[self window] display];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if(isEmpty) return;
	[self setSelected];
	
	if([theEvent clickCount]>=2)
	{
		[presetController load3DSettings];
	}
	
	[super mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if(isEmpty) return;
	[super mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if(isEmpty) return;
	[super mouseUp:theEvent];
}

-(void) setCursorForView: (long) tool
{
	if(isEmpty)
	{
		NSCursor *c;
		c = [NSCursor arrowCursor];
		
		if( c != cursor)
		{
			[cursor release];
			cursor = [c retain];
			[[self window] invalidateCursorRectsForView: self];
			[self resetCursorRects];
			[cursor set];
		}
	}
	else
	{
		[super setCursorForView:tool];
	}
}

- (void)setIndex:(int)index;
{
	presetIndex = index;
}

- (int)index;
{
	return presetIndex;
}

@end
