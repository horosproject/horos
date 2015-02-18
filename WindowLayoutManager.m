/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "WindowLayoutManager.h"
#import "ViewerController.h"
#import "AppController.h"
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

+ (int) windowsRowsForHangingProtocol:(NSDictionary*) protocol
{
    if( [protocol objectForKey: @"WindowsTiling"])
    {
        int tag = [[protocol objectForKey: @"WindowsTiling"] intValue];
        
        if( tag == 1000)
            return 1000; // All windows
        
        if (tag < 16)
            return (tag / 4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[protocol objectForKey: @"Rows"] intValue] > 0)
        return [[protocol objectForKey: @"Rows"] intValue];
    
    return 1;
}

+ (int) windowsColumnsForHangingProtocol:(NSDictionary*) protocol
{
    if( [protocol objectForKey: @"WindowsTiling"])
    {
        int tag = [[protocol objectForKey: @"WindowsTiling"] intValue];
        
        if( tag == 1000)
            return 1000;  // All windows
        
        if (tag < 16)
            return (tag %  4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[protocol objectForKey: @"Columns"] intValue] > 0)
        return [[protocol objectForKey: @"Columns"] intValue];
    
	return 1;
}

- (int) windowsRows
{
    return [WindowLayoutManager windowsRowsForHangingProtocol: self.currentHangingProtocol];
}

- (int) windowsColumns
{
    return [WindowLayoutManager windowsColumnsForHangingProtocol: self.currentHangingProtocol];
}

+ (int) imagesRowsForHangingProtocol:(NSDictionary*) protocol
{
    if( [protocol objectForKey: @"ImageTiling"])
    {
        int tag = [[protocol objectForKey: @"ImageTiling"] intValue];
        
        if (tag < 16)
            return (tag / 4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[protocol objectForKey: @"Image Rows"] intValue] > 0)
        return [[protocol objectForKey: @"Image Rows"] intValue];
    
    return 1;
}

+ (int) imagesColumnsForHangingProtocol:(NSDictionary*) protocol
{
    if( [protocol objectForKey: @"ImageTiling"])
    {
        int tag = [[protocol objectForKey: @"ImageTiling"] intValue];
        
        if (tag < 16)
            return (tag %  4) + 1; // See SetImageTiling ViewerController.m
    }
    
	if( [[protocol objectForKey: @"Image Columns"] intValue] > 0)
        return [[protocol objectForKey: @"Image Columns"] intValue];
    
	return 1;
}

- (int) imagesRows
{
    return [WindowLayoutManager imagesRowsForHangingProtocol: self.currentHangingProtocol];
}

- (int) imagesColumns
{
    return [WindowLayoutManager imagesColumnsForHangingProtocol: self.currentHangingProtocol];
}

#pragma mark-
#pragma mark hanging protocol setters and getters

+ (NSArray*) hangingProtocolsForModality: (NSString*) modality
{
    NSArray *hangingProtocolArray = nil;
    for( NSString *hangingModality in [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] allKeys])
    {
        if( [modality rangeOfString: hangingModality].location != NSNotFound)
        {
            hangingProtocolArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] objectForKey: hangingModality];
            return hangingProtocolArray;
        }
    }
    
    return nil;
}

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
                NSMutableDictionary *foundProtocol = [NSMutableDictionary dictionaryWithDictionary: [hangingProtocolArray objectAtIndex: 0]]; //First one is the default protocol
                [foundProtocol setValue: @YES forKey: @"isDefaultProtocolForModality"];
                
				for( NSDictionary *protocol in hangingProtocolArray)
				{
					if( [[protocol objectForKey: @"Study Description"] isKindOfClass: [NSString class]])
					{
						NSRange searchRange = [description rangeOfString:[protocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
						if (searchRange.location != NSNotFound)
                        {
							foundProtocol = [NSMutableDictionary dictionaryWithDictionary: protocol];
                            [foundProtocol setValue: @NO forKey: @"isDefaultProtocolForModality"];
                            
                            break;
                        }
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
    if( modalities == nil)
        self.currentHangingProtocol = nil;
    else
        self.currentHangingProtocol = [WindowLayoutManager hangingProtocolForModality: modalities description: description];
}

- (void) dealloc
{
    self.currentHangingProtocol = nil;
    [super dealloc];
}

@end
