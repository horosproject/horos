//
//  O2HMigrationAssistant.h
//  
//
//  Created by Fauze Polpeta on 9/26/15.
//
//

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


