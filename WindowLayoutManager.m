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

#import "WindowLayoutManager.h"
#import "ViewerController.h"
#import "AppController.h"
#import "ToolbarPanel.h"
#import "OSIWindowController.h"
#import "Window3DController.h"
#import "browserController.h"
#import "VRController.h"
#import "VRControllerVPRO.h"
#import "MPR2DController.h"
#import "OrthogonalMPRViewer.h"
#import "SRController.h"
#import "EndoscopyViewer.h"
#import "PlaceholderWindowController.h"
#import "OrthogonalMPRPETCTViewer.h"
#import "N2Debug.h"

static WindowLayoutManager *sharedLayoutManager = nil;

@implementation WindowLayoutManager

@synthesize currentHangingProtocol = _currentHangingProtocol;

+ (WindowLayoutManager*)sharedWindowLayoutManager
{
	if (!sharedLayoutManager)
		sharedLayoutManager = [[WindowLayoutManager alloc] init];
	return sharedLayoutManager;
}

- (id)init
{
	if (self = [super init])
	{
	}
	return self;
}

- (int) windowsRows
{
    if( [self.currentHangingProtocol objectForKey: @"WindowsTiling"])
    {
        int tag = [[self.currentHangingProtocol objectForKey: @"WindowsTiling"] intValue];
        
        if (tag < 16)
            return (tag / 4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[self.currentHangingProtocol objectForKey: @"Rows"] intValue] > 0)
        return [[self.currentHangingProtocol objectForKey: @"Rows"] intValue];
    
    return 1;
}

- (int) windowsColumns
{
    if( [self.currentHangingProtocol objectForKey: @"WindowsTiling"])
    {
        int tag = [[self.currentHangingProtocol objectForKey: @"WindowsTiling"] intValue];
        
        if (tag < 16)
            return (tag %  4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[self.currentHangingProtocol objectForKey: @"Columns"] intValue] > 0)
        return [[self.currentHangingProtocol objectForKey: @"Columns"] intValue];
    
	return 1;
}

- (int) imagesRows
{
    if( [self.currentHangingProtocol objectForKey: @"ImageTiling"])
    {
        int tag = [[self.currentHangingProtocol objectForKey: @"ImageTiling"] intValue];
        
        if (tag < 16)
            return (tag / 4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[self.currentHangingProtocol objectForKey: @"Image Rows"] intValue] > 0)
        return [[self.currentHangingProtocol objectForKey: @"Image Rows"] intValue];
    
    return 1;
}

- (int) imagesColumns
{
    if( [self.currentHangingProtocol objectForKey: @"ImageTiling"])
    {
        int tag = [[self.currentHangingProtocol objectForKey: @"ImageTiling"] intValue];
        
        if (tag < 16)
            return (tag %  4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[self.currentHangingProtocol objectForKey: @"Image Columns"] intValue] > 0)
        return [[self.currentHangingProtocol objectForKey: @"Image Columns"] intValue];
    
	return 1;
}

#pragma mark-
#pragma mark hanging protocol setters and getters

+ (NSDictionary*) hangingProtocolForModality: (NSString*) modalities description: (NSString *) description
{
	// if no modalities set to 1 row and 1 column
	if ( !modalities)
	{
	}
	else
	{
		//Search for a hanging Protocol for the study description in the modality array
        NSArray *hangingProtocolArray = [NSArray array];
        for( NSString *hangingModality in [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] allKeys])
        {
            if( [modalities rangeOfString: hangingModality].location != NSNotFound)
            {
                hangingProtocolArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] objectForKey: hangingModality];
                break;
            }
        }
        
		if( [hangingProtocolArray count] > 0)
		{
			@try
			{
                NSDictionary *foundProtocol = [hangingProtocolArray objectAtIndex: 0]; //First one is the default protocol
                
				for( NSDictionary *protocol in hangingProtocolArray)
				{
					if( [[protocol objectForKey: @"Study Description"] isKindOfClass: [NSString class]])
					{
						NSRange searchRange = [description rangeOfString:[protocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
						if (searchRange.location != NSNotFound)
							foundProtocol = protocol;
					}
				}
                
                return foundProtocol;
			}
			@catch (NSException *e) {
				N2LogException( e);
			}
		}
	}
	
    return nil;
}

- (void) setCurrentHangingProtocolForModality: (NSString *) modalities description: (NSString *) description
{
    self.currentHangingProtocol = [WindowLayoutManager hangingProtocolForModality: modalities description: description];
}

- (void) dealloc
{
    self.currentHangingProtocol = nil;
    [super dealloc];
}

@end
