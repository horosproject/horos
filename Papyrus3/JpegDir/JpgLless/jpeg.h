/*
 * jpeg.h --
 *
 * Basic jpeg data structure definitions.
 *
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

#ifndef _JPEG
#define _JPEG

typedef unsigned char Uchar;
typedef unsigned short Ushort;
typedef unsigned int Uint;

/*
 * The following structure stores basic information about one component.
 */
typedef struct JpegComponentInfo {
    /*
     * These values are fixed over the whole image.
     * They are read from the SOF marker.
     */
    short componentId;		/* identifier for this component (0..255) */
    short componentIndex;	/* its index in SOF or cPtr->compInfo[]   */

    /*
     * Downsampling is not normally used in lossless JPEG, although
     * it is permitted by the JPEG standard (DIS). We set all sampling 
     * factors to 1 in this program.
     */
    short hSampFactor;		/* horizontal sampling factor */
    short vSampFactor;		/* vertical sampling factor   */

    /*
     * Huffman table selector (0..3). The value may vary
     * between scans. It is read from the SOS marker.
     */
    short dcTblNo;
} JpegComponentInfo ;


/*
 * One of the following structures is created for each huffman coding
 * table.  We use the same structure for encoding and decoding, so there
 * may be some extra fields for encoding that aren't used in the decoding
 * and vice-versa.
 */
typedef struct HuffmanTable {
    /*
     * These two fields directly represent the contents of a JPEG DHT
     * marker
     */
    Uchar bits[17];
    Uchar huffval[256];

    /*
     * This field is used only during compression.  It's initialized
     * FALSE when the table is created, and set TRUE when it's been
     * output to the file.
     */
    int sentTable;

    /*
     * The remaining fields are computed from the above to allow more
     * efficient coding and decoding.  These fields should be considered
     * private to the Huffman compression & decompression modules.
     */
    Ushort ehufco[256];
    char ehufsi[256];

    Ushort mincode[17];
    int maxcode[18];
    short valptr[17];
    int numbits[256];
    int value[256];
} HuffmanTable ;

/*
 * One of the following structures is used to pass around the
 * compression information.
 */
typedef struct CompressInfo {
    /*
     * Image width, height, and image data precision (bits/sample)
     */ 
    int imageWidth;
    int imageHeight;
    int dataPrecision;

    /*
     * compInfo[i] describes component that appears i'th in SOF
     * numComponents is the # of color components in JPEG image.
     */
    JpegComponentInfo *compInfo;
    short numComponents;

    /*
     * *curCompInfo[i] describes component that appears i'th in SOS.
     * compsInScan is the # of color components in current scan.
     */
    JpegComponentInfo *curCompInfo[4];
    short compsInScan;

    /*
     * MCUmembership[i] indexes the i'th component of MCU into the
     * curCompInfo array.
     */
    short MCUmembership[10];

    /*
     * Pointers to Huffman coding tables, or NULL if not defined.
     */
    HuffmanTable *dcHuffTblPtrs[4];

    /* 
     * prediction seletion value (PSV) and point transform parameter (Pt)
     */
    int Ss;
    int Pt;

    /*
     * In lossless JPEG, restart interval shall be an integer
     * multiple of the number of MCU in a MCU row.
     */
    int restartInRows; /*if > 0, MCU rows per restart interval; 0 = no restart*/

    /* 
     * These fields are private data for the entropy encoder
     */
    int restartRowsToGo;	/* MCUs rows left in this restart interval */
    short nextRestartNum;	/* # of next RSTn marker (0..7) */
} CompressInfo ;


/*
 * One of the following structures is used to pass around the
 * decompression information.
 */
typedef struct DecompressInfo {
    /*
     * Image width, height, and image data precision (bits/sample)
     * These fields are set by ReadFileHeader or ReadScanHeader
     */ 
    int imageWidth;
    int imageHeight;
    int dataPrecision;

    /*
     * compInfo[i] describes component that appears i'th in SOF
     * numComponents is the # of color components in JPEG image.
     */
    JpegComponentInfo compInfo[4];
    short numComponents;

    /*
     * *curCompInfo[i] describes component that appears i'th in SOS.
     * compsInScan is the # of color components in current scan.
     */
    JpegComponentInfo *curCompInfo[4];
    short compsInScan;

    /*
     * MCUmembership[i] indexes the i'th component of MCU into the
     * curCompInfo array.
     */
    short MCUmembership[10];

    /*
     * ptrs to Huffman coding tables, or NULL if not defined
     */
    HuffmanTable *dcHuffTblPtrs[4];

    /* 
     * prediction seletion value (PSV) and point transform parameter (Pt)
     */
    int Ss;
    int Pt;

    /*
     * In lossless JPEG, restart interval shall be an integer
     * multiple of the number of MCU in a MCU row.
     */
    int restartInterval;/* MCUs per restart interval, 0 = no restart */
    int restartInRows; /*if > 0, MCU rows per restart interval; 0 = no restart*/

    /*
     * these fields are private data for the entropy decoder
     */
    int restartRowsToGo;	/* MCUs rows left in this restart interval */
    short nextRestartNum;	/* # of next RSTn marker (0..7) */
} DecompressInfo;


/*
 *--------------------------------------------------------------
 *
 * swap --
 *
 *      Swap the contents stored in a and b.
 *	"type" is the variable type of a and b.
 *
 * Results:
 *	The values in a and b are swapped.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
#define swap(type,a,b) {type c; c=(a); (a)=(b); (b)=c;}

#define MEMSET(s,c,n) memset((void *)(s),(int)(c),(int)(n))
#define MEMCPY(s1,s2,n) memcpy((void *)(s1),(void *)(s2),(int)(n))

/*
 * Lossless JPEG specifies data precision to be from 2 to 16 bits/sample.
 */ 
#define MinPrecisionBits 2
#define MaxPrecisionBits 16
#define MinPrecisionValue 2
#define MaxPrecisionValue 65535

#endif /* _JPEG */

