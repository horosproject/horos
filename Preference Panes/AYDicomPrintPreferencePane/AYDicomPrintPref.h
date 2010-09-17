//
//  AYDicomPrintPref.h
//  AYDicomPrint
//
//  Created by Tobias Hoehmann on 12.06.06.
//  Copyright (c) 2006 aycan digitalsysteme gmbh. All rights reserved.
//

const NSString *filmOrientationTag[] = {@"Portrait", @"Landscape"};
const NSString *filmDestinationTag[] = {@"Processor", @"Magazine"};
const NSString *filmSizeTag[] = {@"8 IN x 10 IN", @"8.5 IN x 11 IN", @"10 IN x 12 IN", @"10 IN x 14 IN", @"11 IN x 14 IN", @"11 IN x 17 IN", @"14 IN x 14 IN", @"24 CM x  24 CM", @"24 CM x  30 CM", @"A4", @"A3"};
const NSString *magnificationTypeTag[] = {@"NONE", @"BILINEAR", @"CUBIC", @"REPLICATE"};
const NSString *trimTag[] = {@"NO", @"YES"};
const NSString *imageDisplayFormatTag[] = {@"Standard 1,1",@"Standard 1,2",@"Standard 2,1",@"Standard 2,2",@"Standard 2,3",@"Standard 2,4",@"Standard 3,3",@"Standard 3,4",@"Standard 3,5",@"Standard 4,4",@"Standard 4,5",@"Standard 4,6",@"Standard 5,6",@"Standard 5,7"};
const int imageDisplayFormatNumbers[] = {1,2,2,4,6,8,9,12,15,16,20,24,30,35};
const int imageDisplayFormatRows[] =    {1,1,2,2,2,2,3, 3, 3, 4, 4, 4, 5, 5};
const int imageDisplayFormatColumns[] = {1,2,1,2,3,4,3, 4, 5, 4, 5, 6, 6, 7};
const NSString *borderDensityTag[] = {@"BLACK", @"WHITE"};
const NSString *emptyImageDensityTag[] = {@"BLACK", @"WHITE"};
const NSString *priorityTag[] = {@"HIGH", @"MED", @"LOW"};
const NSString *mediumTag[] = {@"Blue Film", @"Clear Film", @"Paper"};

#import <PreferencePanes/PreferencePanes.h>

@interface AYDicomPrintPref : NSPreferencePane 
{
	NSArray *m_PrinterDefaults;
	IBOutlet NSArrayController *m_PrinterController;
}

- (IBAction) addPrinter: (id) sender;
- (IBAction) setDefaultPrinter: (id) sender;

- (IBAction) loadList: (id) sender;
- (IBAction) saveList: (id) sender;

@end