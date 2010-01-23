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

#include "altivecFunctions.h"

#if __ppc__ || __ppc64__
// ALTIVEC FUNCTIONS

void InverseLongs(register vector unsigned int *unaligned_input, register long size)
{
	register long						i = size / 4;
	register vector unsigned char		identity = vec_lvsl(0, (int*) NULL );
	register vector unsigned char		byteSwapLongs = vec_xor( identity, vec_splat_u8(sizeof( int )- 1 ) );
	
	while(i-- > 0)
	{
		*unaligned_input++ = vec_perm( *unaligned_input, *unaligned_input, byteSwapLongs);
	}
}

void InverseShorts( register vector unsigned short *unaligned_input, register long size)
{
	register long						i = size / 8;
	register vector unsigned char		identity = vec_lvsl(0, (int*) NULL );
	register vector unsigned char		byteSwapShorts = vec_xor( identity, vec_splat_u8(sizeof( short) - 1) );
	
	while(i-- > 0)
	{
		*unaligned_input++ = vec_perm( *unaligned_input, *unaligned_input, byteSwapShorts);
	}
}

void vmultiply(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	register vector float zero = (vector float) vec_splat_u32(0);
	
	while(i-- > 0)
	{
		*r++ = vec_madd( *a++, *b++, zero);
	}
}

void vsubtract(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_sub( *a++, *b++);
	}
}

void vsubtractAbs(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_abs(vec_sub( *a++, *b++));
	}
}

void vmax8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_max( *a++, *b++);
	}
}

void vmax(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_max( *a++, *b++);
	}
}

void vmin(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_min( *a++, *b++);
	}
}

void vmin8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_min( *a++, *b++);
	}
}
#else
void vmaxIntel( vFloat *a, vFloat *b, vFloat *r, long size)
{
	long i = size/4;
	
	while(i-- > 0)
	{
		*r++ = _mm_max_ps( *a++, *b++);
	}
}
void vminIntel( vFloat *a, vFloat *b, vFloat *r, long size)
{
	long i = size/4;
	
	while(i-- > 0)
	{
		*r++ = _mm_min_ps( *a++, *b++);
	}
}
void vmax8Intel( vUInt8 *a, vUInt8 *b, vUInt8 *r, long size)
{
	long i = size/4;
	
	while(i-- > 0)
	{
		*r++ = _mm_max_epu8( *a++, *b++);
	}
}
void vmin8Intel( vUInt8 *a, vUInt8 *b, vUInt8 *r, long size)
{
	long i = size/4;
	
	while(i-- > 0)
	{
		*r++ = _mm_min_epu8( *a++, *b++);
	}
}
#endif

void vmultiplyNoAltivec( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		*r++ = *a++ * *b++;
	}
}

void vsubtractNoAltivec( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		*r++ = *a++ - *b++;
	}
}

void vsubtractNoAltivecAbs( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		*r++ = fabsf(*a++ - *b++);
	}
}

void vmaxNoAltivec(float *a, float *b, float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		if( *a > *b) { *r++ = *a++; b++; }
		else { *r++ = *b++; a++; }
	}
}

void vminNoAltivec( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		if( *a < *b) { *r++ = *a++; b++; }
		else { *r++ = *b++; a++; }
	}
}
