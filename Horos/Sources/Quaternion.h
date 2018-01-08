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
//
//  Quaternion.h
//  OsiriX_Lion
//
//  Created by Benoit Deville on 04.06.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#ifndef OsiriX_Lion_Quaternion_h
#define OsiriX_Lion_Quaternion_h

#import "Point3D.h"
#import "N3Geometry.h"

/** \brief  Represents a Quaternion
 *
 *  Represents an element of a 4D vector-space.
 *  Defined as w + xi + yj + zk where w, x, y, z are floats and i, j, k imaginary numbers.
 *  In our case, we only use unit quaternion, so we normalize it everytime we modify it
 */

class Quaternion {
    float x;
    float y;
    float z;
    float w;
    
public:
    Quaternion() : x(0), y(0), z(0), w(0) {};
    Quaternion( const float & x, const float & y, const float & z, const float & w ) : x(x), y(y), z(z), w(w) {} ;
    Quaternion( Point3D * axis, const float & theta );
    Quaternion( const N3Vector & axis, const float & theta );
    
    float getX() const { return x; };
    float getY() const { return y; };
    float getZ() const { return z; };
    float getW() const { return w; };
    
    void setX( const float & x );
    void setY( const float & y );
    void setZ( const float & z );
    void setW( const float & w );
    
    Quaternion conjugate() const;
    float length() const;
    void normalize();
       
    /**
     *  Theta angle in degrees.
     */
    void fromAxis( Point3D * axis, const float & theta );
    void fromAxis( const N3Vector & axis, const float & theta );
    void fromAxis(const float & x, const float & y, const float & z, const float & theta );

    /**
     * Cross product between two quaternions.
     */
    Quaternion operator*( const Quaternion & q ) const;
    
    /**
     * Rotation of vector v along current quaternion.
     */
    N3Vector operator*( const N3Vector & v ) const;
    Point3D * operator*( Point3D * v ) const;

    /**
     * Rotation of current quaternion along axis with theta angle.
     * currently returns ID rot
     */
    Quaternion rotate( const N3Vector & axis, const float & theta ) const;
    
    /**
     * Rotation of current quaternion using rotation quaternion q.
     * currently returns ID rot
     */
    Quaternion rotate( const Quaternion & q ) const;
};

#endif
