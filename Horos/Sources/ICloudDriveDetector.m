/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================*/
//
//  ICloudDriveDetector.m
//  Horos
//
//  Created by Fauze Polpeta on 30/01/18.
//  Copyright © 2018 The Horos Project. All rights reserved.
//

#import "ICloudDriveDetector.h"

#import "BrowserController.h"
#import "DicomDatabase.h"
#import "AppController.h"


@interface ICloudDriveDetector ()

+ (NSString*) databasePath;
+ (BOOL) isICloudDriveEnabled;
+ (BOOL) hasNoSyncDeployed:(NSString*) databasePath;
+ (BOOL) isDatabaseLocatedInICloudDrive:(NSString*) databasePath;
+ (BOOL) hasUserIgnoredICloudDriveSyncRisk;
+ (BOOL) requiresUserNotificationOnICloudDrive;
    
@end

@implementation ICloudDriveDetector
    

+ (NSString*) databasePath
{
    return [[DicomDatabase activeLocalDatabase] baseDirPath];
}
 
    
+ (BOOL) isICloudDriveEnabled
{
    NSString* mobileDocumentsPath = [NSString stringWithFormat:@"%@/Library/Mobile Documents", NSHomeDirectory()];
    return [[NSFileManager defaultManager] fileExistsAtPath:mobileDocumentsPath isDirectory:nil];
}
    
    
+ (BOOL) hasNoSyncDeployed:(NSString*) databasePath
{
    return [databasePath containsString:@".nosync/"];
}
    
    
+ (BOOL) isDatabaseLocatedInICloudDrive:(NSString*) databasePath
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docFolder = [NSString stringWithString:[paths objectAtIndex:0]];
    paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    NSString* desktopFolder = [NSString stringWithString:[paths objectAtIndex:0]];
    
    if ([databasePath hasPrefix:docFolder] || [databasePath hasPrefix:desktopFolder])
    {
        return YES;
    }

    return NO;
}

    
+ (BOOL) hasUserIgnoredICloudDriveSyncRisk
{
    NSNumber* flag = [[NSUserDefaults standardUserDefaults] objectForKey:@"ICLOUD_DRIVE_SYNC_RISK_USER_IGNORED"];
    
    if (flag != nil && ([flag integerValue] != 0))
        return YES;
    
    return NO;
}

    
+ (BOOL) requiresUserNotificationOnICloudDrive
{
    NSString* databasePath = [NSString stringWithString:[ICloudDriveDetector databasePath]];
    
    if (![ICloudDriveDetector hasUserIgnoredICloudDriveSyncRisk])
    {
        if ([ICloudDriveDetector isDatabaseLocatedInICloudDrive:databasePath])
        {
            if (![ICloudDriveDetector hasNoSyncDeployed:databasePath])
            {
                if ([ICloudDriveDetector isICloudDriveEnabled])
                {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}
    

+ (void) performStartupICloudDriveTasks:(BrowserController*) browserController
{
    if ([ICloudDriveDetector requiresUserNotificationOnICloudDrive])
    {
        //Launch the assistant
        ICloudDriveDetector* detector = [[ICloudDriveDetector alloc] initWithWindowNibName:@"ICloudDriveDetector"];
        
        detector.browserController = browserController;
        
        if ([NSApp isHidden])
            [[detector window] makeKeyAndOrderFront:self];
        else
            [NSApp runModalForWindow:[detector window]];
    }
}
   
    
    
/*-----------------------------------------------------
 * Instance methods
 ------------------------------------------------------*/

@synthesize browserController = _browserController;

    
- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
    
    
- (void) awakeFromNib
{
    NSWindow* browserControllerWindow = [self.browserController window];
    
    CGFloat xPos = browserControllerWindow.frame.origin.x + browserControllerWindow.frame.size.width/2 - self.window.frame.size.width/2;
    CGFloat yPos = browserControllerWindow.frame.origin.y + browserControllerWindow.frame.size.height/2 - self.window.frame.size.height/2;;
    [[self window] makeKeyAndOrderFront:self];
    [[self window] setFrame:NSMakeRect(xPos, yPos, NSWidth([[self window] frame]),
                                       NSHeight([[self window] frame])) display:YES];
}
    
    
- (void)windowWillClose:(NSNotification *)notification
{
    if ([NSApp isHidden])
        [[self window] orderOut:self];
    else
        [NSApp stopModal];
    
    [self autorelease];
}
    
    
- (IBAction) askLater:(id)sender
{
    [[self window] close];
}


- (IBAction) dontSync:(id)sender
{
    NSString* databasePath = [NSString stringWithString:[ICloudDriveDetector databasePath]];
    
    NSString* nosyncPath = [NSString stringWithFormat:@"%@.nosync",databasePath];
    
    
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:nosyncPath])
    {
        // Convert date object to desired output format
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyyMMddhhmmss"];
        NSDate *date = [NSDate date];
        NSString* timestamp = [dateFormat stringFromDate:date];
        [dateFormat release];
        
        nosyncPath = [NSString stringWithFormat:@"%@_%@.nosync",databasePath,timestamp];
    }

    
    NSError *error = nil;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:nosyncPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        //TODO - Alert user
        [[self window] close];
        return;
    }
    
     
    error = nil;
    
    NSString* newDatabasePath = [NSString stringWithFormat:@"%@.nosync/%@",databasePath,[databasePath lastPathComponent]];
    [[NSFileManager defaultManager] moveItemAtPath:databasePath toPath:newDatabasePath error:&error];
    
    if (error) {
        //TODO - Alert user
        [[self window] close];
        return;
    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:newDatabasePath forKey:@"DEFAULT_DATABASELOCATIONURL"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"DEFAULT_DATABASELOCATION"];
    
    //RESTART or REOPEN DATABSE?
    
    // reopenDatabase - it seems it does not work at all
    /*
    {
        [[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
        [[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
        [[BrowserController currentBrowser] resetToLocalDatabase];
        
        [[self window] close];
        return;
    }
    */
    
    // Restart
    {
        //reopenDatabase - but it doesn't work at all
        [[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
        [[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
        [[BrowserController currentBrowser] resetToLocalDatabase];
        
        [[self window] orderOut:self];
        [NSApp stopModal];
     
        int processIdentifier = [[NSProcessInfo processInfo] processIdentifier];
        NSString *myPath = [NSString stringWithFormat:@"%s", [[[NSBundle mainBundle] executablePath] fileSystemRepresentation]];
        [NSTask launchedTaskWithLaunchPath:myPath arguments:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", processIdentifier]]];
        [NSApp terminate:self];
    }
}

    
    
- (IBAction) keepSync:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:1] forKey:@"ICLOUD_DRIVE_SYNC_RISK_USER_IGNORED"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[self window] close];
}

@end
