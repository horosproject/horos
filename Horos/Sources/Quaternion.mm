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
//  Quaternion.cpp
//  OsiriX_Lion
//
//  Created by Benoit Deville on 04.06.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "Quaternion.h"
#import <math.h>

void Quaternion::setX( const float & x )
{
    this->x = x;
    normalize();
}

void Quaternion::setY( const float & y )
{
    this->y = y;
    normalize();
}

void Quaternion::setZ( const float & z )
{
    this->z = z;
    normalize();
}

void Quaternion::setW( const float & w )
{
    this->w = w;
    normalize();
}

Quaternion::Quaternion( Point3D * axis, const float & theta )
{
    float radAngle = theta * M_PI * 180;
    float sinAngle = sinf( radAngle / 2 );
    
    x = [axis x] * sinAngle;
    y = [axis y] * sinAngle;
    z = [axis z] * sinAngle;
    w = cosf( radAngle / 2 );
    normalize();
}

Quaternion::Quaternion( const N3Vector & axis, const float & theta )
{
    float radAngle = theta * M_PI * 180;
    float sinAngle = sinf( radAngle / 2 );
    
    x = axis.x * sinAngle;
    y = axis.y * sinAngle;
    z = axis.z * sinAngle;
    w = cosf( radAngle / 2 );
    normalize();
}

Quaternion Quaternion::conjugate() const
{
    return Quaternion( -x, -y, -z, w );
}

void Quaternion::normalize()
{
    const float l = length();
    x /= l;
    y /= l;
    z /= l;
    w /= l;
}

float Quaternion::length() const
{
    return ( x*x + y*y + z*z + w*w );
}

void Quaternion::fromAxis( Point3D * axis, const float & theta )
{
    float radAngle = theta * M_PI * 180;
    float sinAngle = sinf( radAngle / 2 );
    
    x = [axis x] * sinAngle;
    y = [axis y] * sinAngle;
    z = [axis z] * sinAngle;
    w = cosf( radAngle / 2 );
    normalize();
}

void Quaternion::fromAxis( const N3Vector & axis, const float & theta )
{
    float radAngle = theta * M_PI * 180;
    float sinAngle = sinf( radAngle / 2 );
    
    x = axis.x * sinAngle;
    y = axis.y * sinAngle;
    z = axis.z * sinAngle;
    w = cosf( radAngle / 2 );
    normalize();
}

void Quaternion::fromAxis( const float & x, const float & y, const float & z, const float & theta )
{
    float radAngle = theta * M_PI * 180;
    float sinAngle = sinf( radAngle / 2 );
    
    this->x = x * sinAngle;
    this->y = y * sinAngle;
    this->z = z * sinAngle;
    w = cosf( radAngle / 2 );
    normalize();
}

Quaternion Quaternion::operator*( const Quaternion & q ) const
{
    return Quaternion( w*q.w - x*q.x - y*q.y - z*q.z,
                       w*q.x + x*q.w + y*q.z - z*q.y,
                       w*q.y - x*q.z + y*q.w + z*q.x,
                       w*q.z + x*q.y - y*q.x + z*q.w);
}

N3Vector Quaternion::operator*( const N3Vector & v ) const
{
	Quaternion vq(v.x, v.y, v.z, 0);
    Quaternion rq(*this * vq * conjugate());
    N3Vector rv;
    rv.x = rq.x;
    rv.y = rq.y;
    rv.z = rq.z;
    
	return rv;
}

Point3D * Quaternion::operator*( Point3D * p ) const
{
	Quaternion vq([p x], [p y], [p z], 0);
    Quaternion rq(*this * vq * conjugate());
    Point3D * rp = [[[Point3D alloc] initWithValues:rq.x :rq.y :rq.z] autorelease];
     
	return rp;
}

Quaternion Quaternion::rotate( const N3Vector & axis, const float & theta ) const
{
    return *this;
}

Quaternion Quaternion::rotate( const Quaternion & q ) const
{
    return *this;    
}
