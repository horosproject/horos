/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================*/

#import <Cocoa/Cocoa.h>

@class BrowserController;

@interface O2HMigrationAssistant : NSWindowController
{
    BrowserController* _browserController;
}

+ (BOOL) isOsiriXInstalled;
+ (void) performStartupO2HTasks:(BrowserController*) browserController;

@property (assign) BrowserController* browserController;

- (IBAction) doNotMigrateFromOsiriX:(id)sender;
- (IBAction) askMeLaterToMigrateFromOsiriX:(id)sender;
- (IBAction) doMigrationFromOsiriX:(id)sender;

@end


