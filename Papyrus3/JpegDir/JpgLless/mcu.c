/*
 * mcu.c --
 *
 * Support for MCU allocation, deallocation, and printing.
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

#include <stdio.h>
#include <stdlib.h>
/* #include <malloc.h> */
#include <string.h>
#include "jpeg.h"
#include "mcu.h"
#include "proto.h"


/* Papyrus 3 redefined basic types */
#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyEalloc3H
#include "PapyEalloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapyFileSystem3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyEalloc3H
#include "Papaloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapFSys3.h"
#endif

#endif

MCU *mcuTable;		  /* the global mcu table that buffers the source image */
MCU *mcuROW1, *mcuROW2;	  /* point to two rows of MCU in encoding & decoding */
int numMCU;		  /* number of MCUs in mcuTable */
/*
 *--------------------------------------------------------------
 *
 * MakeMCU, InitMcuTable --
 *
 *	InitMcuTable does a big malloc to get the amount of memory
 *	we'll need for storing MCU's, once we know the size of our
 *	input and output images.
 *	MakeMCU returns an MCU for input parsing.
 *
 * Results:
 *	A new MCU
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
void InitMcuTable (int numMCU,int compsInScan)
{
    int i, mcuSize;
    char *buffer;

    /*
     * Compute size of on MCU (in bytes).  Round up so it's on a
     * boundary for any alignment.  In this code, we assume this
     * is a whole multiple of sizeof(double).
     */
    mcuSize = compsInScan * sizeof (ComponentType);
    /* mcuSize = JroundUp(mcuSize,sizeof(double)); */

    /*
     * Allocate the MCU table, and a buffer which will contain all
     * the data.  Then carve up the buffer by hand.  Note that
     * mcuTable[0] points to the buffer, in case we want to free
     * it up later.
     */
    mcuTable = (MCU *) emalloc3 (numMCU * sizeof (MCU));
    if (mcuTable == NULL)
       fprintf(stderr,"Not enough memory for mcuTable\n");
    buffer = (char *) emalloc3 (numMCU * mcuSize);
    if (buffer == NULL)
       fprintf(stderr,"Not enough memory for buffer\n");
    
    for (i = 0; i < numMCU; i++) 
    {
	  mcuTable[i] = (MCU) (buffer + i * mcuSize);
    }
}

#define MakeMCU()		(mcuTable[numMCU++])


/*
 *--------------------------------------------------------------
 *
 * PrintMCU --
 *
 *	Send an MCU in quasi-readable form to stdout.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
void
PrintMCU (int compsInScan, MCU mcu)
{
    ComponentType r;
    int b;
    static int callCount;

    for (b=0; b<compsInScan; b++) {
	callCount++;
	r = mcu[b];
	/* printf ("%d: %d ", callCount, r);
	printf ("\n"); */
    }
}
