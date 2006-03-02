//
//  OrthogonalMIPPET.h
//  OsiriX
//
//  Created by joris on 10/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCMPix.h"

@interface OrthogonalMIPPET : NSObject {
	NSArray				*pixList;
	NSMutableArray		*generatedPixList;
	float				alpha, beta, lineSlope;
	long				*line;
	long				fx; // #line# is a function of x if fx==1
	long				fy; // #line# is a function of y if fy==1
	long				imageWidth, imageHeight;
	long				lineLength;
}

#pragma mark-
#pragma mark init
- (id) initWithPixList : (NSArray*) newPixList;
- (void) setAlphaDegres : (float) newAlpha;
- (void) setAlpha : (float) newAlpha;

#pragma mark-
#pragma mark shift line
- (long) lineEquation : (double) a;
- (void) computeLine;
- (long) maxLine;
- (void) shiftLineToStartPosition;
- (void) shiftLine : (long) shift;

#pragma mark -
#pragma mark MIP
- (void) computeMIP;
- (NSMutableArray*) result;

#pragma mark -
#pragma mark accessors
- (float) alpha;
- (float) beta;
@end
