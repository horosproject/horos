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

#import <Cocoa/Cocoa.h>
#import "BrowserController.h"
#import "WaitRendering.h"

/** \brief  Searches and retrieves Bonjour shared databases */

@interface BonjourBrowser : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate>
{
    NSNetServiceBrowser* browser;
	NSMutableArray* services;
	BrowserController* interfaceOsiriX;
}

+ (BonjourBrowser*) currentBrowser;

- (id) initWithBrowserController: (BrowserController*) bC;

- (NSMutableArray*) services;

- (void) buildFixedIPList;
- (void) buildLocalPathsList;
- (void) buildDICOMDestinationsList;
- (void) arrangeServices;

@end
