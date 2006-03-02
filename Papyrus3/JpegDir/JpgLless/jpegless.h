/*
 * JPEGLess.h
 *
 * ---------------------------------------------------------------
 *
 * Lossless JPEG compression and decompression algorithms.
 *
 * ---------------------------------------------------------------
 *
 * It is based on the program originally named ljpgtopnm and pnmtoljpg.
 * Major portions taken from the Independetn JPEG Group' software, and
 * from the Cornell lossless JPEG code (the original copyright notices
 * for those packages appears below).
 * Changes were done by the Osiris Team for Papyrus integration and 
 * optimization purposes.
 *
 * ---------------------------------------------------------------
 *
 * This is the main routine for the lossless JPEG decoder.  Large
 * parts are stolen from the IJG code, so:
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
 * Copyright (c) 1997 OSIRIS Team. Digital Imaging Unit
 * University Hospital of Geneva
 * Changes made by Yves Ligier and David Bandon
 * All rights reserved
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

/* includes */

#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif

#endif 				/* FILENAME83 defined */


#include "jpeg.h"


/* Global variables for lossless encoding process */

extern int psvSet[7];        /* the PSV (prediction selection value) set    */
extern int numSelValue;      /* number of PSVs in psvSet                    */
extern PapyULong inputFileBytes;  /* the input file size in bytes                */
extern PapyULong outputFileBytes; /* the output file size in bytes               */
extern long totalHuffSym[7]; /* total bits of category symbols for each PSV */
extern long totalAddBits[7]; /* total bits of additional bits for each PSV  */
extern int verbose;          /* the verbose flag                            */


/*
 * read a JPEG lossless (8 or 16 bit) image in a file and decode it
 */
extern void JPEGLosslessDecodeImage (PAPY_FILE, PapyUShort *, int , PapyULong);

extern void JPEGDecode_WithoutFile (PapyUShort *, PapyUShort *,int, PapyULong);


/*
 * Encode a (8 or 16 bit) image according to the JPEG lossless algorithm
 */
extern void JPEGLosslessEncodeImage (PapyUShort *, PapyUChar **, PapyULong *, int, int, int);
