//
//  HornRegistration.h
//  OsiriX
//
//  Created by joris on 07/03/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HornRegistration : NSObject {
	NSMutableArray	*modelPoints, *sensorPoints;
	double *adRot, *adTrans;
}

+ (void) test;
- (void) addModelPointX: (double) x Y: (double) y Z: (double) z;
- (void) addSensorPointX: (double) x Y: (double) y Z: (double) z;
- (void) addModelPoint: (double*) point;
- (void) addSensorPoint: (double*) point;
- (short) numberOfPoint;
- (void) compute;

- (double*) rotation;
- (double*) translation;

@end
