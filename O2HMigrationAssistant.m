//
//  O2HMigrationAssistant.m
//  
//
//  Created by Fauze Polpeta on 9/26/15.
//
//

#import "O2HMigrationAssistant.h"

enum
{
    MIGRATION_DENIED    = 1,
    MIGRATION_POSTPONED = 2,
    MIGRATION_ACCEPTED  = 3,
};

@interface O2HMigrationAssistant ()

@end

@implementation O2HMigrationAssistant

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction) doNotMigrateFromOsiriX:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MIGRATION_DENIED] forKey:@"O2H_MIGRATION_USER_ACTION"];
}


- (IBAction) askMeLaterToMigrateFromOsiriX:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MIGRATION_POSTPONED] forKey:@"O2H_MIGRATION_USER_ACTION"];
}


- (IBAction) doMigrationFromOsiriX:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:MIGRATION_ACCEPTED] forKey:@"O2H_MIGRATION_USER_ACTION"];
}

@end
