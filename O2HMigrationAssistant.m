//
//  O2HMigrationAssistant.m
//  
//
//  Created by Fauze Polpeta on 9/26/15.
//
//

#import "O2HMigrationAssistant.h"

#import "browserController.h"
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


+ (void) performStartupO2HTasks:(BrowserController*) browserController
{
    //////////////////
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"O2H_MIGRATION_USER_ACTION"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    //////////////////
    
    //Check if user already said NO or YES before
    NSNumber* o2h_migration_user_action = [[NSUserDefaults standardUserDefaults] objectForKey:@"O2H_MIGRATION_USER_ACTION"];

    if (o2h_migration_user_action != nil && [o2h_migration_user_action integerValue] == MIGRATION_DENIED)
        return;
    
    if (o2h_migration_user_action != nil && [o2h_migration_user_action integerValue] == MIGRATION_ACCEPTED)
        return;
    
    //Check if we have OsiriX
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* osirixPath = [NSString stringWithFormat:@"%@/OsiriX Data/DATABASE.noindex",[paths objectAtIndex:0]];
    
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:osirixPath isDirectory:&isDirectory] && isDirectory)
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
