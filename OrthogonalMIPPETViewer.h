//
//  OrthogonalMIPPETViewer.h
//  OsiriX
//
//  Created by joris on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OrthogonalMIPPETView.h"
#import "OrthogonalMIPPET.h"

@interface OrthogonalMIPPETViewer : NSWindowController {
	IBOutlet NSSlider				*angleSlider;
	IBOutlet NSTextField			*angleTextField, *betaTextField;
	IBOutlet OrthogonalMIPPETView	*mipView;
	OrthogonalMIPPET				*mip;
}

- (IBAction) setAlpha : (id) sender;

@end
