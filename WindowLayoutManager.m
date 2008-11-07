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
#import "LayoutWindowController.h";
#import "PlaceholderWindowController.h"
#import "OrthogonalMPRPETCTViewer.h"

static WindowLayoutManager *sharedLayoutManager = nil;

@implementation WindowLayoutManager

+ (id)sharedWindowLayoutManager{
	if (!sharedLayoutManager)
		sharedLayoutManager = [[WindowLayoutManager alloc] init];
	return sharedLayoutManager;
}

- (id)init
{
	if (self = [super init])
	{
//		_windowControllers = [[NSMutableArray alloc] init];
//		_hangingProtocolInUse = NO;
//		_seriesSetIndex = 0;
		
		IMAGEROWS = 1;
		IMAGECOLUMNS = 1;
	}
	return self;
}

- (int) IMAGEROWS
{
	return IMAGEROWS;
}

- (int) IMAGECOLUMNS
{
	return IMAGECOLUMNS;
}

#pragma mark-
#pragma mark hanging protocol setters and getters
- (void) setCurrentHangingProtocolForModality: (NSString *) modality description: (NSString *) description
{
	// if no modality set to 1 row and 1 column
	if (!modality )
	{
		IMAGECOLUMNS = 1;
		IMAGEROWS = 1;
	}
	else
	{
		//Search for a hanging Protocol for the study description in the modality array
		NSArray *hangingProtocolArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] objectForKey: modality];
		if ([hangingProtocolArray count] > 0)
		{
			[_currentHangingProtocol release];
			_currentHangingProtocol = nil;
			_currentHangingProtocol = [hangingProtocolArray objectAtIndex:0];
			
			@try
			{
				IMAGEROWS = [[_currentHangingProtocol objectForKey: @"Image Rows"] intValue];
				IMAGECOLUMNS =  [[_currentHangingProtocol objectForKey: @"Image Columns"] intValue];
				
				NSMutableDictionary *protocol;
				for (protocol in hangingProtocolArray)
				{
					if( [[protocol objectForKey: @"Study Description"] isKindOfClass: [NSString class]])
					{
						NSRange searchRange = [description rangeOfString:[protocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
						if (searchRange.location != NSNotFound)
						{
							_currentHangingProtocol = protocol;
							
							IMAGEROWS = [[_currentHangingProtocol objectForKey: @"Image Rows"] intValue];
							IMAGECOLUMNS =  [[_currentHangingProtocol objectForKey: @"Image Columns"] intValue];
							
							break;
						}
					}
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"setCurrentHangingProtocolForModality exception : %@", e);
				IMAGEROWS = 1;
				IMAGECOLUMNS = 1;
			}
			
			if( IMAGEROWS < 1) IMAGEROWS = 1;
			if( IMAGECOLUMNS < 1) IMAGECOLUMNS = 1;
			
			[_currentHangingProtocol retain];
		}
	}
	
}


- (NSDictionary *) currentHangingProtocol
{
	return _currentHangingProtocol;
}

@end
