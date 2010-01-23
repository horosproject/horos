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

#import <Accelerate/Accelerate.h>

#ifdef __cplusplus
extern "C"
{
#endif /*cplusplus*/
	#if __ppc__ || __ppc64__
	// ALTIVEC FUNCTIONS
	extern void InverseLongs(register vector unsigned int *unaligned_input, register long size);
	extern void InverseShorts( register vector unsigned short *unaligned_input, register long size);
	extern void vmultiply(vector float *a, vector float *b, vector float *r, long size);
	extern void vsubtract(vector float *a, vector float *b, vector float *r, long size);
	extern void vsubtractAbs(vector float *a, vector float *b, vector float *r, long size);
	extern void vmax8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size);
	extern void vmax(vector float *a, vector float *b, vector float *r, long size);
	extern void vmin(vector float *a, vector float *b, vector float *r, long size);
	extern void vmin8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size);
	#else
	extern void vmaxIntel( vFloat *a, vFloat *b, vFloat *r, long size);
	extern void vminIntel( vFloat *a, vFloat *b, vFloat *r, long size);
	extern void vmax8Intel( vUInt8 *a, vUInt8 *b, vUInt8 *r, long size);
	extern void vmin8Intel( vUInt8 *a, vUInt8 *b, vUInt8 *r, long size);
	#endif
	
	extern void vmultiplyNoAltivec( float *a,  float *b,  float *r, long size);
	extern void vminNoAltivec( float *a,  float *b,  float *r, long size);
	extern void vmaxNoAltivec(float *a, float *b, float *r, long size);
	extern void vsubtractNoAltivec( float *a,  float *b,  float *r, long size);
	extern void vsubtractNoAltivecAbs( float *a,  float *b,  float *r, long size);
	
	extern short Altivec;

#ifdef __cplusplus
}
#endif /*cplusplus*/