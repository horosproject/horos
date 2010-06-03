//
//  N2CustomTitledPopUpButtonCell.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/25/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface N2CustomTitledPopUpButtonCell : NSPopUpButtonCell {
	NSString* displayedTitle;
}

@property(retain) NSString* displayedTitle;


@end
