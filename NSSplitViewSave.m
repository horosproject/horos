/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "NSSplitViewSave.h"

@implementation NSSplitView(Defaults)

- (void) restoreDefault: (NSString *) defaultName
{
        NSString * string = [[NSUserDefaults standardUserDefaults] objectForKey: defaultName];

        if (string == nil)
                return;         // there was no saved default

        NSScanner* scanner = [NSScanner scannerWithString: string];
        NSRect r0, r1;

        BOOL didScan =
                [scanner scanFloat: &(r0.origin.x)]             &&
                [scanner scanFloat: &(r0.origin.y)]             &&
                [scanner scanFloat: &(r0.size.width)]   &&
                [scanner scanFloat: &(r0.size.height)]  &&
                [scanner scanFloat: &(r1.origin.x)]             &&
                [scanner scanFloat: &(r1.origin.y)]             &&
                [scanner scanFloat: &(r1.size.width)]   &&
                [scanner scanFloat: &(r1.size.height)];

        if (didScan == NO)
                return; // probably should throw an exception at this point

        [[[self subviews] objectAtIndex: 0] setFrame: r0];
        [[[self subviews] objectAtIndex: 1] setFrame: r1];

        [self adjustSubviews];
}

- (void) saveDefault: (NSString *) defaultName
{
        NSRect r0 = [[[self subviews] objectAtIndex: 0] frame];
        NSRect r1 = [[[self subviews] objectAtIndex: 1] frame];

        NSString * string = [NSString stringWithFormat: @"%f %f %f %f %f %f %f %f",
                r0.origin.x, r0.origin.y, r0.size.width, r0.size.height,
                r1.origin.x, r1.origin.y, r1.size.width, r1.size.height];

        [[NSUserDefaults standardUserDefaults] setObject: string forKey: defaultName];
}

@end
