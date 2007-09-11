/*
 *  altivecFunctions.h
 *  OsiriX
 *
 *  Created by Bruce Rakes on 9/11/07.
 *
 */

#import <Accelerate/Accelerate.h>

#if __ppc__ || __ppc64__
// ALTIVEC FUNCTIONS

extern void InverseLongs(register vector unsigned int *unaligned_input, register long size);
extern void InverseShorts( register vector unsigned short *unaligned_input, register long size);
extern void vmultiply(vector float *a, vector float *b, vector float *r, long size);
extern void vsubtract(vector float *a, vector float *b, vector float *r, long size);
extern void vmax8(vector float *a, vector float *b, vector float *r, long size);
extern void vmax(vector float *a, vector float *b, vector float *r, long size);
extern void vmin(vector float *a, vector float *b, vector float *r, long size);
extern void vmin8(vector float *a, vector float *b, vector float *r, long size);
#else
extern void vmaxIntel( vFloat *a, vFloat *b, vFloat *r, long size);
extern void vminIntel( vFloat *a, vFloat *b, vFloat *r, long size);
#endif
