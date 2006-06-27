//
//  LLMPRView.h
//  OsiriX
//
//  Created by Joris Heuberger on 08/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OrthogonalMPRView.h"
#import "LLMPRViewer.h"

@interface LLMPRView : OrthogonalMPRView {
	IBOutlet LLMPRViewer* viewer;
}

-(long)thickSlabX;
-(long)thickSlabY;

@end
