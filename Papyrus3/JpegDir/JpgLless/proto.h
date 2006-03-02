/*
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

#ifndef _PROTO
#define _PROTO

#ifdef __STDC__
# define	P(s) s
#else
# define P(s) ()
#endif

#include "mcu.h"

#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif

#endif 				/* FILENAME83 defined */


/* huffc.c */
void FlushBytes P((void ));
void HuffEncoderInit P((CompressInfo *cPtr ));
void HuffEncode P((CompressInfo *cPtr, PapyUShort *Image)); 
void HuffEncoderTerm P((void ));

/* huffd.c */
void HuffDecoderInit P((DecompressInfo *dcPtr ));
void DecodeImage P((DecompressInfo *dcPtr, PapyUShort **image, int depth));

/* pnmtoljpg.c ljpgtopnm.c */
PapyULong ReadJpegData P((PapyUChar *buffer , PapyULong numBytes));
PapyULong WriteJpegData P((PapyUChar *buffer , PapyULong numBytes));
void StdPickSelValue P((CompressInfo *cPtr, long *bestTotalBits));

/* read.c */
int ReadFileHeader P((DecompressInfo *dcPtr ));
int ReadScanHeader P((DecompressInfo *dcPtr ));

/* write.c */
void WriteFileTrailer P((CompressInfo *cPtr ));
void WriteScanHeader P((CompressInfo *cPtr ));
void WriteFileHeader P((CompressInfo *cPtr ));

/* util.c */
int JroundUp P((int a , int b ));
void DecoderStructInit P((DecompressInfo *dcPtr ));
void FixHuffTbl P((HuffmanTable *htbl));
    
 /* mcu.c */
void InitMcuTable P((int numMCU , int blocksInMCU ));
void PrintMCU P((int blocksInMCU , MCU mcu ));

#undef P

#endif /* _PROTO */

