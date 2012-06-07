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
