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
 
 /* Papyrus 3 redefined basic types */
#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif

#endif 				/* FILENAME83 defined */


#ifndef _IO
#define _IO

#include "jpeg.h"


/*
 * Size of the input and output buffer
 */
#define JPEG_BUF_SIZE   4096

/*
 * The following variables keep track of the input and output
 * buffer for the JPEG data.
 */
extern PapyUChar outputBuffer[JPEG_BUF_SIZE];    /* output buffer              */
extern PapyULong  numOutputBytes;		 /* bytes in the output buffer */
extern PapyUChar *inputBuffer;     		 /* Input buffer for JPEG data */
extern int inputBufferOffset;		         /* Offset of current byte     */

extern PapyUChar *readimBuffer;			 /* input buffer for image data 8 bytes (DB) */
extern PapyUShort *readim16Buffer;		 /* input buffer for image data 16bytes  (DB) */
extern int readimBufferOffset;                   /* Offset of current byte     */

/*
 * the output file pointer. 
 */
extern PAPY_FILE OutFile;

/*
 *--------------------------------------------------------------
 *
 * EmitByte --
 *
 *	Write a single byte out to the output buffer, and
 *	flush if it's full.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The outp[ut buffer may get flushed.
 *
 *--------------------------------------------------------------
 */
#define EmitByte(val)  {									\
    if (numOutputBytes >= JPEG_BUF_SIZE) {					\
	FlushBytes();											\
    }														\
    outputBuffer[numOutputBytes++] = (PapyUChar)(val);			\
}

/*
 *--------------------------------------------------------------
 *
 * GetJpegChar, UnGetJpegChar --
 *
 *      Macros to get the next character from the input stream.
 *
 * Results:
 *      GetJpegChar returns the next character in the stream, or EOF
 *      UnGetJpegChar returns nothing.
 *
 * Side effects:
 *      A byte is consumed or put back into the inputBuffer.
 *
 *--------------------------------------------------------------
 */
#define GetJpegChar()		(inputBuffer [inputBufferOffset++])                                           \

#define UnGetJpegChar(ch)       (inputBuffer[--inputBufferOffset]=(ch))

/*
 *--------------------------------------------------------------
 *
 * GetImChar and GetImShort
 *
 *      Macros to get the next character or short from the input stream.
 *
 * Results:
 *      GetImChar returns the next character in the stream, or EOF
 *		GetImShort returns the next Short in the stream, or EOF
 *
 * Side effects:
 *      A byte is consumed or put back into the readimBuffer.
 *
 *--------------------------------------------------------------
 */
#define GetImChar()		(readimBuffer[readimBufferOffset++]) 

#define GetImShort()	(readim16Buffer[readimBufferOffset++]) 

#endif /* _IO */
