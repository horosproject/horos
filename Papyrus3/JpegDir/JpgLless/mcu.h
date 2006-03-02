/*
 * mcu.h --
 *
 * Copyright (C) 1991, 1992, Thomas G. Lane.
 * Part of the Independent JPEG Group's software.
 * See the file Copyright for more details.
 *
 * Copyright (c) 1993 Brian C. Smith, The Regents of the University
 * of California
 * All rights reserved.
 * 
 * Copyright (c) 1994 Kongji Huang and Brian C. Smith.
 * Cornell University
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CORNELL UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF CORNELL
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * CORNELL UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND CORNELL UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#ifndef _MCU
#define _MCU
 
/*
 * An MCU (minimum coding unit) is an array of samples.
 */
typedef unsigned short ComponentType; /* the type of image components */
typedef ComponentType *MCU;  /* MCU - array of samples */

extern MCU *mcuTable; /* the global mcu table that buffers the source image */
extern int numMCU;    /* number of MCUs in mcuTable */
extern MCU *mcuROW1,*mcuROW2; /* pt to two rows of MCU in encoding & decoding */

/*
 *--------------------------------------------------------------
 *
 * MakeMCU --
 *
 *      MakeMCU returns an MCU for input parsing.
 *
 * Results:
 *      A new MCU
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
#define MakeMCU()	(mcuTable[numMCU++])

#endif /* _MCU */
