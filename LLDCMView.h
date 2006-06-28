//
//  LLDCMView.h
//  OsiriX
//
//  Created by joris on 28/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "LLMPRViewer.h"

@interface LLDCMView : DCMView {
	IBOutlet LLMPRViewer *viewer;
}

@end
