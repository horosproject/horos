/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


/*

MODIFICATION HISTORY

	20051212	JH	Created.
	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).

  
*/

#import "EndoscopyVRController.h"
#import "DCMView.h"
#import "ROI.h"


extern NSString * documentsDirectory();

@implementation EndoscopyVRController

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	
	for( i = 0; i < 100; i++) undodata[ i] = 0L;
	
//	[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"MAPPERMODEVR"];	// texture mapping

	flyThruController = 0L;
	
	curMovieIndex = 0;
	maxMovieIndex = 1;
	
	fileList = f;
	[fileList retain];
	
	pixList[0] = pix;
	volumeData[0] = vData;
	
    DCMPix  *firstObject = [pixList[0] objectAtIndex:0];
    float sliceThickness = fabs( [firstObject sliceInterval]);
	
	// Find Minimum Value
	
	if( [firstObject isRGB] == NO)
	{
		float *tempData = (float*) [volumeData[0] bytes];
		
		i = [firstObject pwidth] * [firstObject pheight] * [pix count] / 16;
		i -= 32;
		minimumValue = *tempData;
		while( i-- > 0)
		{
			if( *tempData < minimumValue) minimumValue = *tempData;
			tempData += 16;
		}
	}
	else minimumValue = 0;
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
		testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval",nil), NSLocalizedString( @"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil), NSLocalizedString(@"OK",nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval/thickness",nil), NSLocalizedString( @"Problems with slice thickness/interval to do a 3D reconstruction.",nil),NSLocalizedString( @"OK",nil), nil, nil);
			return 0L;
		}
    }
    
    // CHECK IMAGE SIZE
    for( i =0 ; i < [pixList[0] count]; i++)
    {
        if( [firstObject pwidth] != [[pixList[0] objectAtIndex:i] pwidth]) err = -1;
        if( [firstObject pheight] != [[pixList[0] objectAtIndex:i] pheight]) err = -1;
    }
    if( err)
    {
        NSRunCriticalAlertPanel(NSLocalizedString( @"Images size",nil),  NSLocalizedString(@"These images don't have the same height and width to allow a 3D reconstruction...",nil),NSLocalizedString( @"OK",nil), nil, nil);
        return 0L;
    }

	[pixList[0] retain];
	[volumeData[0] retain];


    self = [super init];
    
    //[[self window] setDelegate:self];
    
	[view setViewportResizable: NO];
	
    err = [view setPixSource:pixList[0] :(float*) [volumeData[0] bytes]];
    if( err != 0)
    {
        //[self dealloc];
        return 0L;
    }
	
	blendingController = bC;
//	if( blendingController) // Blending! Activate image fusion
//	{
//		[view setBlendingPixSource: blendingController];
//		
//		[blendingSlider setEnabled:YES];
//		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
//		
//		//[self updateBlendingImage];
//	}
	
	curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
	
	roi2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	sliceNumber2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	x2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	y2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	z2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];

	viewer2D = [vC retain];
	if (viewer2D)
	{		
		long i, j;
		float x, y, z;
		NSMutableArray	*curRoiList;
		ROI	*curROI;
		
		for(i=0; i<[[[viewer2D imageView] dcmPixList] count]; i++)
		{
			curRoiList = [[viewer2D roiList] objectAtIndex: i];
			for(j=0; j<[curRoiList count];j++)
			{
				curROI = [curRoiList objectAtIndex:j];
				if ([curROI type] == t2DPoint)
				{
					float location[ 3 ];
					
					[[[viewer2D pixList] objectAtIndex: i] convertPixX: [[[curROI points] objectAtIndex:0] x] pixY: [[[curROI points] objectAtIndex:0] y] toDICOMCoords: location];
					
					x = location[ 0 ];
					y = location[ 1 ];
					z = location[ 2 ];

					// add the 3D Point to the SR view
					[[self view] add3DPoint:  x : y : z];
					// add the 2D Point to our list
					[roi2DPointsArray addObject:curROI];
					[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:i]];
					[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
					[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
					[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
				}
			}
		}
	}

	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver: self
		selector: @selector(remove3DPoint:)
		name: @"removeROI"
		object: nil];
	[nc addObserver: self
		selector: @selector(add3DPoint:)
		//name: @"roiChange"
		name: @"roiSelected"
		object: nil];

    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(updateVolumeData:)
               name: @"updateVolumeData"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	
    [nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	
	curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
	
    [nc addObserver: self
           selector: @selector(UpdateOpacityMenu:)
               name: @"UpdateOpacityMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
	
	[nc addObserver: self
           selector: @selector(CLUTChanged:)
               name: @"CLUTChanged"
             object: nil];
	
	[[self window] performZoom:self];

	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled: NO];
	
	[[enginePopup menu] setAutoenablesItems : NO];
	//[[[enginePopup menu] itemAtIndex: 3] setEnabled: NO];
	[[[enginePopup menu] itemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]+1] setState:NSOnState]; // texture mapping
//	NSLog(@"[[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] : %d", [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]);
	//[self updateEngine];
	
	//[view updateScissorStateButtons];
	
    return self;
}

-(void) save3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingPathComponent:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VRENDOSCOPY-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
	NSMutableDictionary *dict = [view get3DStateDictionary];
	[dict setObject:curCLUTMenu forKey:@"CLUTName"];
	[dict setObject:curOpacityMenu forKey:@"OpacityName"];
	[dict setObject:[[shadingsPresetsController selection] valueForKey:@"name"]  forKey:@"shading"];
	
	if( [viewer2D postprocessed] == NO)
		[dict writeToFile:str atomically:YES];
}


-(void) load3DState
{
	NSLog (@"Load Endoscopy 3d State");
	NSString		*path = [documentsDirectory() stringByAppendingPathComponent:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VRENDOSCOPY-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
	
	if( [viewer2D postprocessed]) dict = 0L;
	
	[view set3DStateDictionary:dict];
	NSLog(@"3d Dict: %@", dict);
	if(dict==nil)
	{
		[self applyWLWWForString:@"VR - Endoscopy"];
	}
	
	if( [dict objectForKey:@"CLUTName"]) [self ApplyCLUTString:[dict objectForKey:@"CLUTName"]];
	else [self ApplyCLUTString:@"Endoscopy"];
	
	if( [dict objectForKey:@"OpacityName"]) [self ApplyOpacityString:[dict objectForKey:@"OpacityName"]];
	else [self ApplyOpacityString: @"Logarithmic Table"];
	
	NSString *shadingName = [dict objectForKey:@"shading"];
	if (!shadingName)
		shadingName = @"Endoscopy";

	NSEnumerator *enumerator = [[shadingsPresetsController arrangedObjects] objectEnumerator];
	NSDictionary *shading;
	while (shading = [enumerator nextObject]) {
		if ([[shading valueForKey:@"name"] isEqualToString:shadingName]) {
			[shadingsPresetsController setSelectedObjects:[NSArray arrayWithObject:shading]];
			[self applyShading:nil];
		}
	}
	
	if( [view shading]) [shadingCheck setState: NSOnState];
	else [shadingCheck setState: NSOffState];
	
	float ambient = 0.12;
	float diffuse = 0.62;
	float specular = 0.73;
	float specularpower = 1.0;
	//[view setShadingValues:0.12 :0.62 :0.73 :50.0];
	[view getShadingValues: &ambient :&diffuse :&specular :&specularpower];
	NSLog([NSString stringWithFormat:@"Ambient: %2.1f\nDiffuse: %2.1f\nSpecular :%2.1f-%2.1f", ambient, diffuse, specular, specularpower]);
	[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.1f\nDiffuse: %2.1f\nSpecular :%2.1f-%2.1f", ambient, diffuse, specular, specularpower]];
}


@end