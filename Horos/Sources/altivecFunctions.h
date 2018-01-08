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

#import <Accelerate/Accelerate.h>

#ifdef __cplusplus
extern "C"
{
#endif /*cplusplus*/
	#if __ppc__ || __ppc64__
	// ALTIVEC FUNCTIONS
	extern void InverseLongs(vector unsigned int *unaligned_input, long size);
	extern void InverseShorts( vector unsigned short *unaligned_input, long size);
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
