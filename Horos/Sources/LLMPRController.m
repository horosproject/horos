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

#import "LLMPRController.h"
#import "LLMPRViewer.h"
#import "LLMPRView.h"
#import "Notifications.h"

#define BONEVALUE 250

@implementation LLMPRController

//- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC:(id) newViewer
//{
//	[super initWithPixList: pix :files :vData :vC :bC:newViewer];
//	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resliceFromNotification:) name:OsirixLLMPRResliceNotification object:nil];
//}

- (void) reslice: (long) x :(long) y :(OrthogonalMPRView*) sender
{
//NSLog(@"- (void) reslice: (long) x: (long) y: (OrthogonalMPRView*) sender;");
//NSLog(@"super");
	[super reslice: x: y: sender];
//NSLog(@"NSMutableDictionary");
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[userInfo setObject:[NSNumber numberWithInt:x] forKey:@"x"];
	[userInfo setObject:[NSNumber numberWithInt:y] forKey:@"y"];
	if ([sender isEqualTo:originalView])
		[userInfo setObject:@"originalView" forKey:@"view"];
	else if ([sender isEqualTo:xReslicedView])
		[userInfo setObject:@"xReslicedView" forKey:@"view"];
	else if ([sender isEqualTo:yReslicedView])
		[userInfo setObject:@"yReslicedView" forKey:@"view"];
//NSLog(@"LLMPRController postNotificationName:LLMPRReslice");
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixLLMPRResliceNotification object:self userInfo:userInfo];
}

- (void) resliceFromNotification: (NSNotification*) notification;
{
	if([[notification object] isEqualTo:self])
		return;
	if(originalView==nil || xReslicedView==nil || yReslicedView==nil)
		return;
	if([[originalView dcmPixList] count]==0 || [[xReslicedView dcmPixList] count]==0 || [[yReslicedView dcmPixList] count]==0)
		return;
	if(![originalView curDCM] || ![xReslicedView curDCM] || ![yReslicedView curDCM])
		return;
	if([[notification object] thickSlab]!=[self thickSlab] || [[notification object] thickSlabMode]!=[self thickSlabMode])
		return;
	
	OrthogonalMPRView *sender = nil;
	if ([[[notification userInfo] objectForKey:@"view"] isEqualTo:@"originalView"])
		sender = originalView;
	else if ([[[notification userInfo] objectForKey:@"view"] isEqualTo:@"xReslicedView"])
		sender = xReslicedView;
	else if ([[[notification userInfo] objectForKey:@"view"] isEqualTo:@"yReslicedView"])
		sender = yReslicedView;
		
	[sender setCrossPositionX:[[[notification userInfo] objectForKey:@"x"] floatValue]];
	[sender setCrossPositionY:[[[notification userInfo] objectForKey:@"y"] floatValue]];
	[super reslice: [[[notification userInfo] objectForKey:@"x"] intValue]: [[[notification userInfo] objectForKey:@"y"] intValue]: sender];
}

- (void) shiftView:(OrthogonalMPRView*)view x:(int) deltaX y:(int) deltaY;
{
	//NSLog(@"LLMPRController shiftView x: %d y: %d", deltaX, deltaY);
	if ([view isEqualTo:originalView])
		[(LLMPRViewer*)viewer shiftSubtractionX:deltaX y:deltaY z:0];
	else if ([view isEqualTo:xReslicedView])
		[(LLMPRViewer*)viewer shiftSubtractionX:deltaX y:0 z:deltaY];
	else if ([view isEqualTo:yReslicedView])
		[(LLMPRViewer*)viewer shiftSubtractionX:0 y:deltaX z:deltaY];
}

- (void)removeBonesAtX:(int)x y:(int)y fromView:(LLMPRView*)view;
{
	int xx = 0, yy = 0, zz = 0;
	float pixelMax = 0, currentPixel = 0;
	float *buffer = nil;
	long res = 0;
	int i = 0, s = 0, minI = 0, maxI = 0;
	DCMPix *curPix = nil;
	
	if ([view isEqualTo:originalView])
	{
		xx = x;
		yy = y;
		if(thickSlabMode==0)
			zz = pixListRange.location+[originalView curImage];
		else
		{
			pixelMax = -1000.0;
			s = ([view flippedData])? -1 : 1;
			zz = pixListRange.location+[view curImage];
						
			for(i=0; i<=thickSlab; i++)
			{
				res = pixListRange.location+[view curImage]+s*i;
				if( res < pixListRange.location+pixListRange.length-1 && res >= pixListRange.location)
				{
					buffer = [[[originalView dcmPixList] objectAtIndex:res-pixListRange.location] fImage];
					currentPixel = buffer[y*[[[originalView dcmPixList] objectAtIndex:res-pixListRange.location] pwidth]+x];
					if(currentPixel > pixelMax)
					{
						pixelMax = currentPixel;
						zz = res;
					}
					//NSLog(@"zz : %d", zz);
					//NSLog(@"pixelMax : %f", pixelMax);
				}
			}
		}
	}
	else if ([view isEqualTo:xReslicedView])
	{
		xx = x;
		//zz = (sign>0)? [[originalView dcmPixList] count]-1 -y : y;
		zz = (sign>0)? pixListRange.location+pixListRange.length-1-y : pixListRange.location+y;
		if(thickSlabMode==0)
			yy = [originalView crossPositionY];
		else
		{
			pixelMax = -1000.0;
			//s = ([view flippedData])? -1 : 1;
			yy = [originalView crossPositionY];
			
			curPix = [[originalView dcmPixList] objectAtIndex:zz-pixListRange.location];
			
			minI = [originalView crossPositionY]-floor((float)[view thickSlabX]/2.0);
			maxI = [originalView crossPositionY]+ceil((float)[view thickSlabX]/2.0);
			
			minI = (minI<0)? 0: minI;
			maxI = (maxI>=[curPix pheight])? [curPix pheight]-1 : maxI;
						
			for(i=minI; i<=maxI; i++)
			{
				buffer = [curPix fImage];
				currentPixel = buffer[i*[curPix pwidth]+x];
				if(currentPixel > pixelMax)
				{
					pixelMax = currentPixel;
					yy = i;
				}
				//NSLog(@"i : %d", i);
				//NSLog(@"pixelMax : %f", pixelMax);
			}
		}
	}
	else if ([view isEqualTo:yReslicedView])
	{
		yy = x;
//		zz = (sign>0)? [[originalView dcmPixList] count]-1 -y : y;
		zz = (sign>0)? pixListRange.location+pixListRange.length-1-y : pixListRange.location+y;
		if(thickSlabMode==0)
			xx = [originalView crossPositionX];
		else
		{
			pixelMax = -1000.0;
			//s = ([view flippedData])? -1 : 1;
			xx = [originalView crossPositionY];

			curPix = [[originalView dcmPixList] objectAtIndex:zz-pixListRange.location];

			minI = [originalView crossPositionX]-floor((float)[view thickSlabX]/2.0);
			maxI = [originalView crossPositionX]+ceil((float)[view thickSlabX]/2.0);
			
			minI = (minI<0)? 0: minI;
			maxI = (maxI>=[curPix pwidth])? [curPix pwidth]-1 : maxI;
						
			for(i=minI; i<=maxI; i++)
			{
				buffer = [curPix fImage];
				currentPixel = buffer[x*[curPix pwidth]+i];
				if(currentPixel > pixelMax)
				{
					pixelMax = currentPixel;
					xx = i;
				}
				//NSLog(@"i : %d", i);
				//NSLog(@"pixelMax : %f", pixelMax);
			}
		}
	}
	NSLog(@"xx: %d yy: %d zz : %d", xx, yy, zz);
	[viewer removeBonesAtX:xx y:yy z:zz];
}

-(void)setPixListRange:(NSRange)range;
{
	pixListRange = range;
	//NSLog(@"pixListRange.location : %d .. pixListRange.length : %d", pixListRange.location, pixListRange.length);
}

- (void) dealloc {
	//NSLog(@"LLMPR Controller dealloc");
	[super dealloc];
}

@end
