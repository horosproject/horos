/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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