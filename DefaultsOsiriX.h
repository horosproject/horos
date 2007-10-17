//
//  Defaults.h
//  OsiriX
//
//  Created by Antoine Rosset on 20.06.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum HotKeyActions {DefaultWWWLHotKeyAction, FullDynamicWWWLHotKeyAction, 
	Preset1WWWLHotKeyAction, Preset2WWWLHotKeyAction, Preset3WWWLHotKeyAction, 
	Preset4WWWLHotKeyAction, Preset5WWWLHotKeyAction, Preset6WWWLHotKeyAction, 
	Preset7WWWLHotKeyAction, Preset8WWWLHotKeyAction, Preset9WWWLHotKeyAction,
	FlipVerticalHotKeyAction, FlipHorizontalHotKeyAction,
	WWWLToolHotKeyAction, MoveHotKeyAction, ZoomHotKeyAction, RotateHotKeyAction,
	ScrollHotKeyAction, LengthHotKeyAction, AngleHotKeyAction, RectangleHotKeyAction,
	OvalHotKeyAction, TextHotKeyAction, ArrowHotKeyAction, OpenPolygonHotKeyAction,
	ClosedPolygonHotKeyAction, PencilHotKeyAction, ThreeDPointHotKeyAction, PlainToolHotKeyAction,
	BoneRemovalHotKeyAction, Rotate3DHotKeyAction, Camera3DotKeyAction, scissors3DHotKeyAction, RepulsorHotKeyAction};


/** \brief Sets up user defaults */
@interface DefaultsOsiriX : NSObject {

}

+ (BOOL) isHUG;
+ (BOOL) isUniGE;
+ (BOOL) isLAVIM;
+ (NSMutableDictionary*) getDefaults;
+ (NSString*) hostName;
+ (NSHost*) currentHost;

@end
