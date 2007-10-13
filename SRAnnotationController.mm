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

- (BOOL)exportAllROIs;
{
	if(!annotation) return NO;
	
	NSMutableArray *rois = [[NSMutableArray alloc] initWithCapacity:0];
	NSArray *dcmRoiList = [view dcmRoiList];
	
	NSEnumerator *enumerator = [dcmRoiList objectEnumerator];
	id roiListForThisDCMPix;
	int i, count=0;
	while (roiListForThisDCMPix = [enumerator nextObject])
	{
		for (i=0; i<[roiListForThisDCMPix count]; i++)
		{
			[[roiListForThisDCMPix objectAtIndex:i] setPix:[[view dcmPixList] objectAtIndex:i]];
			count++;
		}
		[rois addObjectsFromArray:roiListForThisDCMPix];
	}

	NSLog(@"exportAllROIs, count : %d", [rois count]);
	if(!count) return NO;
	[annotation addROIs:rois];
	return YES;
}

- (BOOL)exportAllROIsForCurrentDCMPix;
{
	if(!annotation) return NO;
	
	NSArray *rois = [[view dcmRoiList] objectAtIndex: [view curImage]];
	
	NSEnumerator *enumerator = [rois objectEnumerator];
	id roi;
	int count=0;
	while (roi = [enumerator nextObject])
	{
		[roi setPix:[view curDCM]];
		count++;
	}
	
	NSLog(@"exportAllROIsForCurrentDCMPix, count : %d", [rois count]);
	if(!count) return NO;
	[annotation addROIs:rois];
	return YES;
}

- (BOOL)exportSelectedROI;
{
	if(!annotation) return NO;
	
	ROI *roi = [viewer selectedROI];
	if(!roi) return NO;
	[roi setPix:[view curDCM]];
	NSLog(@"exportSelectedROI, name : %@", [roi name]);
	[annotation addROI:roi];
	return YES;
}

#pragma mark -
#pragma mark Result
//
//- (void)writeResult;
//{
//	if(!annotation) return;
//	
//	if([annotation save])
//	{
//		[annotation saveAsHTML];
//		NSLog(@"SR Annotation export done.");
//	}
//	else
//		NSLog(@"SR Annotation export failed.");
//}
//
//- (IBAction)export:(id)sender;
//{
//	NSLog(@"############## SR Annotation ##############");
//	if(annotation) [annotation release];
//	annotation = [[SRAnnotation alloc] init];
//	
//	BOOL result = NO;
//	NSString *alertTitle, *alertMessage;
//	
//	switch ([[whichROIsMatrix selectedCell] tag])
//	{
//		case 0:
//			result = [self exportSelectedROI];
//			alertTitle = NSLocalizedString(@"No ROI selected", 0L);
//			alertMessage = NSLocalizedString(@"Please select a ROI first.", 0L);
//		break;
//		
//		case 1:
//			result = [self exportAllROIsForCurrentDCMPix];
//			alertTitle = NSLocalizedString(@"No ROIs", 0L);
//			alertMessage = NSLocalizedString(@"There is no ROIs on current image.", 0L);
//		break;
//		
//		case 2:
//			result = [self exportAllROIs];
//			alertTitle = NSLocalizedString(@"No ROIs", 0L);
//			alertMessage = NSLocalizedString(@"There is no ROIs on this series.", 0L);
//		break;
//	}
//	
//	[self endSheet];
//	
//	if(result)
//		[self writeResult];
//	else
//		NSRunAlertPanel( alertTitle, alertMessage, NSLocalizedString(@"OK", nil), nil, nil);
//		
//	NSLog(@"!!!!!!!!!!!!!! SR Annotation !!!!!!!!!!!!!!");
//}

@end
