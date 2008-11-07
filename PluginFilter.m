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


#import "PluginFilter.h"

@implementation PluginFilter

+ (PluginFilter *)filter
{
    return [[[self alloc] init] autorelease];
}

- (void) dealloc
{
	NSLog( @"PluginFilter dealloc");

	[super dealloc];
}

- (id)init {
	if (self = [super init])
	{
		[self initPlugin];
	}
	return self;
}

- (void) initPlugin
{
	return;
}

- (void)setMenus {  // Opportunity for plugins to make Menu changes if necessary
	return;
}

- (long) prepareFilter:(ViewerController*) vC
{
	NSLog( @"Prepare Filter");
	viewerController = vC;
	
	return 0;
}

- (ViewerController*) duplicateCurrent2DViewerWindow
{
	long							i;
	ViewerController				*new2DViewer;
	unsigned char					*fVolumePtr;
	
	// We will read our current series, and duplicate it by creating a new series!
	
	// First calculate the amount of memory needed for the new serie
	NSArray		*pixList = [viewerController pixList];		
	DCMPix		*curPix;
	long		mem = 0;
	
	for( i = 0; i < [pixList count]; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	
	fVolumePtr = malloc( mem);	// ALWAYS use malloc for allocating memory !
	if( fVolumePtr)
	{
		// Copy the source series in the new one !
		memcpy( fVolumePtr, [viewerController volumePtr], mem);
		
		// Create a NSData object to control the new pointer
		NSData		*volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new fVolumePtr
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * 4 * i)];
			[newPixList addObject: curPix];
		}
		
		// We don't need to duplicate the DicomFile array, because it is identical!
		
		// A 2D Viewer window needs 3 things:
		// A mutable array composed of DCMPix objects
		// A mutable array composed of DicomFile objects
		// Number of DCMPix and DicomFile has to be EQUAL !
		// NSData volumeData contains the images, represented in the DCMPix objects
		new2DViewer = [viewerController newWindow:newPixList :[viewerController fileList] :volumeData];
		
		[new2DViewer roiDeleteAll:self];
		
		return new2DViewer;
	}
	
	return nil;
}

- (NSArray*) viewerControllersList
{
	return [ViewerController getDisplayed2DViewers];
}

- (long) filterImage:(NSString*) menuName
{
	NSLog( @"Error, you should not be here!: %@", menuName);
    return -1;
}

- (long) processFiles: (NSArray*) files
{
	
	return 0;
}

- (id) report: (NSManagedObject*) study action:(NSString*) action
{
	return 0;
}

// Following stubs are to be subclassed.  Included here to remove compile-time warning messages.

- (id)reportDateForStudy: (NSManagedObject*)study {
	return nil;
}

- (void)deleteReportForStudy: (NSManagedObject*)study {
	return;
}

- (void)createReportForStudy: (NSManagedObject*)study {
	return;
}

@end
