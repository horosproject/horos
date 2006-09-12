//
//  SRAnnotationController.m
//  OsiriX
//
//  Created by joris on 11/09/06.
//  Copyright 2006 OsiriX Team. All rights reserved.
//

#import "SRAnnotationController.h"
#import "SRAnnotation.h"

@implementation SRAnnotationController

#pragma mark -
#pragma mark basics

- (id)initWithViewerController:(ViewerController*)aViewer;
{
	if(![super initWithWindowNibName:@"SRAnnotation"]) return nil;
	viewer = [aViewer retain];
	view = [[aViewer imageView] retain];
	return self;
}

- (void)dealloc;
{
	NSLog(@"SRAnnotationController dealloc");
	if(annotation) [annotation release];
	[viewer release];
	[view release];
	[super dealloc];
}

#pragma mark -
#pragma mark sheet

- (void)beginSheet;
{
	[NSApp beginSheet:[self window] modalForWindow:[viewer window] modalDelegate:self didEndSelector:@selector(autorelease) contextInfo:nil];
}

- (void)endSheet;
{
	[[self window] orderOut:nil];
	[NSApp endSheet:[self window]];
	[[self window] close];
}

- (IBAction)endSheet:(id)sender;
{
	[self endSheet];
}

#pragma mark -
#pragma mark ROIs

- (void)exportAllROIs;
{
	if(!annotation) return;
	
	NSMutableArray *rois = [[NSMutableArray alloc] initWithCapacity:0];
	NSArray *dcmRoiList = [view dcmRoiList];
	
	NSEnumerator *enumerator = [dcmRoiList objectEnumerator];
	id roiListForThisDCMPix;
	while (roiListForThisDCMPix = [enumerator nextObject])
	{
		[rois addObjectsFromArray:roiListForThisDCMPix];
	}

	NSLog(@"exportAllROIs, count : %d", [rois count]);
	[annotation addROIs:rois];
}

- (void)exportAllROIsForCurrentDCMPix;
{
	if(!annotation) return;
	
	NSArray *rois = [[view dcmRoiList] objectAtIndex: [view curImage]];
	
	NSLog(@"exportAllROIsForCurrentDCMPix, count : %d", [rois count]);
	[annotation addROIs:rois];
}

- (void)exportSelectedROI;
{
	if(!annotation) return;
	
	ROI *roi = [viewer selectedROI];
	
	NSLog(@"exportSelectedROI, name : %@", [roi name]);
	[annotation addROI:roi];
}

#pragma mark -
#pragma mark Result

- (void)writeResult;
{
	if(!annotation) return;
	
	if([annotation save])
		NSLog(@"SR Annotation export done.");
	else
		NSLog(@"SR Annotation export failed.");
}

- (IBAction)export:(id)sender;
{
	if(annotation) [annotation release];
	annotation = [[SRAnnotation alloc] init];
	
	switch ([[whichROIsMatrix selectedCell] tag])
	{
		case 0:
			[self exportSelectedROI];
		break;
		
		case 1:
			[self exportAllROIsForCurrentDCMPix];
		break;
		
		case 2:
			[self exportAllROIs];
		break;
	}
	[self writeResult];
	[self endSheet];
}

@end
