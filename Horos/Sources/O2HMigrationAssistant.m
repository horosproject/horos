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

#import "O2HMigrationAssistant.h"

#import "BrowserController.h"
#import "AppController.h"

enum
{
    MIGRATION_DENIED    = 1,
    MIGRATION_POSTPONED = 2,
    MIGRATION_ACCEPTED  = 3,
};

@interface O2HMigrationAssistant ()

@end

@implementation O2HMigrationAssistant


@synthesize browserController = _browserController;

+ (BOOL) isOsiriXInstalled
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* osirixPath = [NSString stringWithFormat:@"%@/OsiriX Data/DATABASE.noindex",[paths objectAtIndex:0]];
    
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:osirixPath isDirectory:&isDirectory] && isDirectory)
    {
        return YES;
    }
    
    return NO;
}

+ (void) performStartupO2HTasks:(BrowserController*) browserController
{
    //Check if user already said NO or YES before
    NSNumber* o2h_migration_user_action = [[NSUserDefaults standardUserDefaults] objectForKey:@"O2H_MIGRATION_USER_ACTION"];

    if (o2h_migration_user_action != nil && [o2h_migration_user_action integerValue] == MIGRATION_DENIED)
        return;
    
    if (o2h_migration_user_action != nil && [o2h_migration_user_action integerValue] == MIGRATION_ACCEPTED)
        return;
    
    //Open Assistant if OsiriX is installed
    if ([O2HMigrationAssistant isOsiriXInstalled])
    {
        //Launch the assistant
        O2HMigrationAssistant* migrationAssistant = [[O2HMigrationAssistant alloc] initWithWindowNibName:@"O2HMigrationAssistant"];
        migrationAssistant.browserController = browserController;
        
        if ([NSApp isHidden])
            [[migrationAssistant window] makeKeyAndOrderFront:self];
        else
            [NSApp runModalForWindow:[migrationAssistant window]];
    }
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) awakeFromNib {

    NSWindow* browserControllerWindow = [self.browserController window];

    CGFloat xPos = browserControllerWindow.frame.origin.x + browserControllerWindow.frame.size.width/2 - self.window.frame.size.width/2;
    CGFloat yPos = browserControllerWindow.frame.origin.y + browserControllerWindow.frame.size.height/2 - self.window.frame.size.height/2;;
    [[self window] makeKeyAndOrderFront:self];
    [[self window] setFrame:NSMakeRect(xPos, yPos, NSWidth([[self window] frame]),
                                                   NSHeight([[self window] frame])) display:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSNumber* o2h_migration_user_action = [[NSUserDefaults standardUserDefaults] objectForKey:@"O2H_MIGRATION_USER_ACTION"];

    if (o2h_migration_user_action == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:MIGRATION_POSTPONED] forKey:@"O2H_MIGRATION_USER_ACTION"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if ([NSApp isHidden])
        [[self window] orderOut:self];
    else
        [NSApp stopModal];
    
    [self autorelease];
}


- (IBAction) doNotMigrateFromOsiriX:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:MIGRATION_DENIED] forKey:@"O2H_MIGRATION_USER_ACTION"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[self window] close];
}


- (IBAction) askMeLaterToMigrateFromOsiriX:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:MIGRATION_POSTPONED] forKey:@"O2H_MIGRATION_USER_ACTION"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[self window] close];
}


- (IBAction) doMigrationFromOsiriX:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:MIGRATION_ACCEPTED] forKey:@"O2H_MIGRATION_USER_ACTION"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* osirixPath = [NSString stringWithFormat:@"%@/OsiriX Data/DATABASE.noindex",[paths objectAtIndex:0]];
        
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:osirixPath isDirectory:&isDirectory] && isDirectory)
        {
            BOOL COPYDATABASE = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYDATABASE"];
            int COPYDATABASEMODE = [[NSUserDefaults standardUserDefaults] integerForKey: @"COPYDATABASEMODE"];
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"COPYDATABASE"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:always] forKey:@"COPYDATABASEMODE"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [self.browserController subSelectFilesAndFoldersToAdd:[NSArray arrayWithObjects:osirixPath, nil]];
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:COPYDATABASE] forKey:@"COPYDATABASE"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:COPYDATABASEMODE] forKey:@"COPYDATABASEMODE"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [[self window] close];
    });
}

@end
