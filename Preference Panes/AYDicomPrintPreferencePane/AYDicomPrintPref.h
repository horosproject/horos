//
//  AYDicomPrintPref.h
//  AYDicomPrint
//
//  Created by Tobias Hoehmann on 12.06.06.
//  Copyright (c) 2006 aycan digitalsysteme gmbh. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface AYDicomPrintPref : NSPreferencePane 
{
	NSArray *m_PrinterDefaults;
	IBOutlet NSArrayController *m_PrinterController;
	
	IBOutlet SFAuthorizationView			*_authView;
}

- (IBAction) addPrinter: (id) sender;
- (IBAction) setDefaultPrinter: (id) sender;

/* not needed by now
- (IBAction) applyChanges: (id) sender;
- (IBAction) restoreChanges: (id) sender;
*/
@end