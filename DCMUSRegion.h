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

#import <Foundation/Foundation.h>

@interface DCMUSRegion: NSObject
{
    // DICOM TAGS
    int regionSpatialFormat;        // (0018,6012) [0000H...0005H]
    int regionDataType;             // (0018,6014) [0000H...0012H]
    int regionFlags;                // (0018,6016) [0,1]
    
    int regionLocationMinX0;        // (0018,6018)
    int regionLocationMinY0;        // (0018,601A)
    int regionLocationMaxX1;        // (0018,601C)
    int regionLocationMaxY1;        // (0018,601E)
    
    int referencePixelX0;           // (0018,6020) [optional]
    int referencePixelY0;           // (0018,6022) [optional]
    
    int physicalUnitsXDirection;    // (0018,6024) [0000H...000CH]
    int physicalUnitsYDirection;    // (0018,6026) [0000H...000CH]
    
    double refPixelPhysicalValueX;  // (0018,6028)
    double refPixelPhysicalValueY;  // (0018,602A)
    
    double physicalDeltaX;          // (0018,602C)
    double physicalDeltaY;          // (0018,602E) [<0:dir=up, >0:dir=down]
    
    double dopplerCorrectionAngle;  // (0018,6034)
    
    // Optional Tags
    BOOL isReferencePixelX0Present;
    BOOL isReferencePixelY0Present;
}

// Accessors (getter & setter)
@property int regionSpatialFormat;
@property int regionDataType;
@property int regionFlags;

@property int regionLocationMinX0;
@property int regionLocationMinY0;
@property int regionLocationMaxX1;
@property int regionLocationMaxY1;

@property int referencePixelX0;
@property int referencePixelY0;

@property int physicalUnitsXDirection;
@property int physicalUnitsYDirection;

@property double refPixelPhysicalValueX;
@property double refPixelPhysicalValueY;

@property double physicalDeltaX;
@property double physicalDeltaY;

@property double dopplerCorrectionAngle;

@property BOOL isReferencePixelX0Present;
@property BOOL isReferencePixelY0Present;

// Methods
- (NSString*) toString;

@end
