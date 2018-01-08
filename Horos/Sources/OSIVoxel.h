/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/





#import <Cocoa/Cocoa.h>

@class Point3D;

/** \brief Represents a Voxel
*
*  Represents a Voxel
*  Has x, y, and z positions as float
*/


@interface OSIVoxel : NSObject {
	float _x;
	float _y;
	float _z;
	NSNumber *_value;
	float _voxelWidth;
	float _voxelHeight;
	float _voxelDepth;	
	id  _userInfo;
}

@property float voxelWidth;
@property float voxelHeight;
@property float voxelDepth;
@property float x;
@property float y;
@property float z;
@property (copy, readwrite) NSNumber *value;
@property (retain, readwrite) id userInfo;





/** set the x, y, z position */
- (void) setX:(float)x y:(float)y z:(float)z;


/** init with x, y, and z position and pixel value */
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
/**  init with image point and the slice */
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;
/** init with Point3D */
- (id)initWithPoint3D:(Point3D *)point3D;

/**  Class init with x, y, and z position and pixel value */
+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
/**  Class init with image point and the slice */
+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;
/** Class init with Point3D */
+ (id)pointWithPoint3D:(Point3D *)point3D;

/** export to xml */
-(NSMutableDictionary*) exportToXML;
/** init with xml dictonary */
-(id) initWithDictionary: (NSDictionary*) xml;






@end
