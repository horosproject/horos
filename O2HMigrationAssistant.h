//
//  O2HMigrationAssistant.h
//  
//
//  Created by Fauze Polpeta on 9/26/15.
//
//

#import <Cocoa/Cocoa.h>

@interface O2HMigrationAssistant : NSWindowController

- (IBAction) doNotMigrateFromOsiriX:(id)sender;
- (IBAction) askMeLaterToMigrateFromOsiriX:(id)sender;
- (IBAction) doMigrationFromOsiriX:(id)sender;

@end


