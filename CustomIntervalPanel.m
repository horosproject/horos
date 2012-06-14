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

#import "CustomIntervalPanel.h"
#import "browserController.h"

@interface CustomIntervalPanel ()

@end

@implementation CustomIntervalPanel

@synthesize fromDate, toDate;

+ (CustomIntervalPanel*) sharedCustomIntervalPanel
{
    static CustomIntervalPanel *sharedCustomIntervalPanel = nil;
    
    if( sharedCustomIntervalPanel == nil)
    {
        sharedCustomIntervalPanel = [[CustomIntervalPanel alloc] initWithWindowNibName: @"CustomIntervalPanel"];
        
        sharedCustomIntervalPanel.fromDate = [NSDate date];
        sharedCustomIntervalPanel.toDate = [NSDate date];
    }
    
    return sharedCustomIntervalPanel;
}
    
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
		[fromPicker setLocale: [NSLocale currentLocale]];
		[toPicker setLocale: [NSLocale currentLocale]];
		[textualFromPicker setLocale: [NSLocale currentLocale]];
		[textualToPicker setLocale: [NSLocale currentLocale]];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (void) setFromDate:(NSDate *) date
{
    if( [fromDate isEqualToDate: date] == NO)
    {
        [fromDate release];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"customIntervalWithHoursAndMinutes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"betweenDatesMode"])
        {
            fromDate = [date copy];
        }
        else
        {
            unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
            NSDateComponents *components = [[NSCalendar currentCalendar] components: unitFlags fromDate: date];
            
            fromDate = [[[NSCalendar currentCalendar] dateFromComponents: components] retain];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"betweenDatesMode"] == NO)
                self.toDate = date;
        }
        
        [[BrowserController currentBrowser] outlineViewRefresh];
    }
}

- (void) setToDate:(NSDate *) date
{
    if( [toDate isEqualToDate: date] == NO)
    {
        [toDate release];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"customIntervalWithHoursAndMinutes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"betweenDatesMode"])
        {
            toDate = [date copy];
        }
        else
        {
            unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
            NSDateComponents *components = [[NSCalendar currentCalendar] components: unitFlags fromDate: date];
            
            [components setHour: 23];
            [components setMinute: 59];
            [components setSecond: 59];
            
            toDate = [[[NSCalendar currentCalendar] dateFromComponents: components] retain];
        }
        
        [[BrowserController currentBrowser] outlineViewRefresh];
    }
}
- (IBAction) nowFrom:(id)sender;
{
    self.fromDate = [NSDate date];
}

- (IBAction) nowTo:(id) sender;
{
     self.toDate = [NSDate date];
}

- (void) dealloc
{
    [fromDate release];
    [toDate release];
    
    [super dealloc];
}
@end
