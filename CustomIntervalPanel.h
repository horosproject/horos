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

@interface CustomIntervalPanel : NSWindowController
{
    NSDate *fromDate;
    NSDate *toDate;
    
    IBOutlet NSDatePicker *fromPicker;
    IBOutlet NSDatePicker *toPicker;
    IBOutlet NSDatePicker *textualFromPicker;
    IBOutlet NSDatePicker *textualToPicker;
}

@property (nonatomic, retain) NSDate *fromDate, *toDate;

+ (CustomIntervalPanel*) sharedCustomIntervalPanel;
- (IBAction) nowFrom:(id)sender;
- (IBAction) nowTo:(id) sender;
- (void) sizeWindowAccordingToSettings;
- (void) setFormatAccordingToSettings;

@end
