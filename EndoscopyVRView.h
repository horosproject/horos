//
//  EndoscopyVRView.h
//  OsiriX
//
//  Created by joris on 2/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VRView.h"

@interface EndoscopyVRView : VRView {

}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower;

@end
