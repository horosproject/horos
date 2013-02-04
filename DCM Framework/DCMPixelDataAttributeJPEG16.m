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

#import "DCMPixelDataAttributeJPEG16.h"
#import "DCMPixelDataAttributeJPEG12.h"
#import "DCMPixelDataAttributeJPEG8.h"
#import "DCM.h"
#include "jinclude16.h"
#include "jpeglib16.h"
#include "jerror16.h"
#import <stdio.h>
#import "jpegdatasrc.h"

LOCAL(int)
readFromData16(NSData *data, JOCTET *buffer, int currentPosition, int length)
{
	int lengthToRead = 0;
	NSRange range;
	
	if ([data length] > length + currentPosition)
	{
		range = NSMakeRange(currentPosition, length);
		lengthToRead = length;
	}
	else{
		lengthToRead = [data length] - currentPosition;
		range = NSMakeRange(currentPosition, lengthToRead);
	}
	
	if (lengthToRead  > 0)
		[data getBytes:buffer range:range];
	
	return lengthToRead;
}

// private error handler struct
typedef struct 
{
  // the standard IJG error handler object
  struct jpeg_error_mgr pub;

  // pointer to this
  DCMPixelDataAttribute *instance;
} JPEG16ErrorStruct ;
typedef JPEG16ErrorStruct * JPEG16ErrorPtr;

//METHODDEF(void) JPEG16ErrorExit(j_common_ptr cinfo)
//{
//	(*cinfo->err->output_message)(cinfo);
//	char buffer[JMSG_LENGTH_MAX]; 
//	(*cinfo->err->format_message) (cinfo, buffer);
//	NSLog(@"JPEG error %s", buffer);
//	dcmException = [NSException exceptionWithName:@"DCM JPEG Encoding error" reason:[NSString stringWithCString:buffer] userInfo:nil];
//}
//
//METHODDEF(void) JPEG16OutputMessage(j_common_ptr cinfo)
//{
//	//JPEG8ErrorStruct *myerr = (JPEG8ErrorStruct *)cinfo->err;
//	char buffer[JMSG_LENGTH_MAX]; 
//	//char buffer[100];   
//	/* Create the message */
//  (*cinfo->err->format_message) (cinfo, buffer);
//	NSLog(@"JPEG error %s", buffer);
//  
//}



typedef struct {
  struct jpeg_source_mgr pub;	/* public fields */

  NSData *data;		/* source data */
  JOCTET * buffer;		/* start of buffer */
  BOOL start_of_data;	/* have we gotten any data yet? */
  long currentPosition;
} data16_source_mgr;

typedef data16_source_mgr * data16_src_ptr;

#define INPUT_BUF_SIZE  4096	/* choose an efficiently fread'able size */


/*
 * Initialize source --- called by jpeg_read_header
 * before any data is actually read.
 */

METHODDEF(void)
init_source (j_decompress_ptr cinfo)
{
  data16_src_ptr src = (data16_src_ptr) cinfo->src;

  /* We reset the empty-input-file flag for each image,
   * but we don't clear the input buffer.
   * This is correct behavior for reading a series of images from one source.
   */
  src->start_of_data = YES;
}


/*
 * Fill the input buffer --- called whenever buffer is emptied.
 *
 * In typical applications, this should read fresh data into the buffer
 * (ignoring the current state of next_input_byte & bytes_in_buffer),
 * reset the pointer & count to the start of the buffer, and return TRUE
 * indicating that the buffer has been reloaded.  It is not necessary to
 * fill the buffer entirely, only to obtain at least one more byte.
 *
 * There is no such thing as an EOF return.  If the end of the file has been
 * reached, the routine has a choice of ERREXIT() or inserting fake data into
 * the buffer.  In most cases, generating a warning message and inserting a
 * fake EOI marker is the best course of action --- this will allow the
 * decompressor to output however much of the image is there.  However,
 * the resulting error message is misleading if the real problem is an empty
 * input file, so we handle that case specially.
 *
 * In applications that need to be able to suspend compression due to input
 * not being available yet, a FALSE return indicates that no more data can be
 * obtained right now, but more may be forthcoming later.  In this situation,
 * the decompressor will return to its caller (with an indication of the
 * number of scanlines it has read, if any).  The application should resume
 * decompression after it has loaded more data into the input buffer.  Note
 * that there are substantial restrictions on the use of suspension --- see
 * the documentation.
 *
 * When suspending, the decompressor will back up to a convenient restart point
 * (typically the start of the current MCU). next_input_byte & bytes_in_buffer
 * indicate where the restart point will be if the current call returns FALSE.
 * Data beyond this point must be rescanned after resumption, so move it to
 * the front of the buffer rather than discarding it.
 */

METHODDEF(boolean)
fill_input_buffer (j_decompress_ptr cinfo)
{
	
  data16_src_ptr src = (data16_src_ptr) cinfo->src;
  size_t nbytes;
	nbytes = readFromData16(src->data, src->buffer, src->currentPosition, INPUT_BUF_SIZE);
  //nbytes = JFREAD(src->infile, src->buffer, INPUT_BUF_SIZE);

  if (nbytes <= 0) {
	if (src->start_of_data)	/* Treat empty input file as fatal error */
	  ERREXIT(cinfo, JERR_INPUT_EMPTY);
	WARNMS(cinfo, JWRN_JPEG_EOF);
	/* Insert a fake EOI marker */
	src->buffer[0] = (JOCTET) 0xFF;
	src->buffer[1] = (JOCTET) JPEG_EOI;
	nbytes = 2;
  }
	src->currentPosition += nbytes;
  src->pub.next_input_byte = src->buffer;
  src->pub.bytes_in_buffer = nbytes;
  src->start_of_data = FALSE;
	//NSLog(@"end fill_input_buffer");
  return TRUE;
}


/*
 * Skip data --- used to skip over a potentially large amount of
 * uninteresting data (such as an APPn marker).
 *
 * Writers of suspendable-input applications must note that skip_input_data
 * is not granted the right to give a suspension return.  If the skip extends
 * beyond the data currently in the buffer, the buffer can be marked empty so
 * that the next read will cause a fill_input_buffer call that can suspend.
 * Arranging for additional bytes to be discarded before reloading the input
 * buffer is the application writer's problem.
 */

METHODDEF(void)
skip_input_data (j_decompress_ptr cinfo, long num_bytes)
{
  data16_src_ptr src = (data16_src_ptr) cinfo->src;
//NSLog(@"skip data");
  /* Just a dumb implementation for now.  Could use fseek() except
   * it doesn't work on pipes.  Not clear that being smart is worth
   * any trouble anyway --- large skips are infrequent.
   */
  if (num_bytes > 0) {
    while (num_bytes > (long) src->pub.bytes_in_buffer) {
      num_bytes -= (long) src->pub.bytes_in_buffer;
      (void) fill_input_buffer(cinfo);
      /* note we assume that fill_input_buffer will never return FALSE,
       * so suspension need not be handled.
       */
    }
    src->pub.next_input_byte += (size_t) num_bytes;
    src->pub.bytes_in_buffer -= (size_t) num_bytes;
  }
}


/*
 * An additional method that can be provided by data source modules is the
 * resync_to_restart method for error recovery in the presence of RST markers.
 * For the moment, this source module just uses the default resync method
 * provided by the JPEG library.  That method assumes that no backtracking
 * is possible.
 */


/*
 * Terminate source --- called by jpeg_finish_decompress
 * after all data has been read.  Often a no-op.
 *
 * NB: *not* called by jpeg_abort or jpeg_destroy; surrounding
 * application must deal with any cleanup that should happen even
 * for error exit.
 */

METHODDEF(void)
term_source (j_decompress_ptr cinfo)
{
  /* no work necessary here */
}


/*
 * Prepare for input from a stdio stream.
 * The caller must have already opened the stream, and is responsible
 * for closing it after finishing decompression.
 */

GLOBAL(void)
jpeg16_nsdata_src (j_decompress_ptr cinfo, NSData *aData)
{
  data16_src_ptr src;

  /* The source object and input buffer are made permanent so that a series
   * of JPEG images can be read from the same file by calling jpeg_stdio_src
   * only before the first one.  (If we discarded the buffer at the end of
   * one image, we'd likely lose the start of the next one.)
   * This makes it unsafe to use this manager and a different source
   * manager serially with the same JPEG object.  Caveat programmer.
   */
   //NSLog(@"init jpeg_nsdata_src");
  if (cinfo->src == NULL) {	/* first time for this JPEG object? */
    cinfo->src = (struct jpeg_source_mgr *)
      (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
				  SIZEOF(data16_source_mgr));
    src = (data16_src_ptr) cinfo->src;
    src->buffer = (JOCTET *)
      (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
				  INPUT_BUF_SIZE * SIZEOF(JOCTET));
	src->currentPosition = 0;
  }

  src = (data16_src_ptr) cinfo->src;
  src->pub.init_source = init_source;
  src->pub.fill_input_buffer = fill_input_buffer;
  src->pub.skip_input_data = skip_input_data;
  src->pub.resync_to_restart = jpeg_resync_to_restart; /* use default method */
  src->pub.term_source = term_source;
  src->data = aData;
  src->pub.bytes_in_buffer = 0; /* forces fill_input_buffer on first read */
  src->pub.next_input_byte = NULL; /* until buffer loaded */
}


@implementation DCMPixelDataAttribute (DCMPixelDataAttributeJPEG16)

- (NSData *)convertJPEG16ToHost:(NSData *)jpegData{

	//struct SErrorMgr				theJErr;		 /* the JPEG error manager var */
	struct jpeg_error_mgr			theJErr;		 /* the JPEG error manager var */
	struct jpeg_decompress_struct	theCInfo;
	//unsigned char					theTmpBuf [256];
	//unsigned char					*theTmpBufP;
	//unsigned short					theGroup, theElement;
	//short							theErr = 0;
	unsigned long					 theLimit;
	int								theRowStride;	 	/* physical row width in output buffer */
	//unsigned char					*theWrkChP; 		/* ptr to the image */
	//unsigned char					*theWrkCh8P; 		/* ptr to the image 8 bits */
	unsigned short					*theWrkCh16P; 		/* ptr to the image 16 bits */
	unsigned short					*theBuffer16P;
	NSMutableData					*rawData = nil ;
	//initialize jpeg dcecompressor

//	NSLog(@"decompress JPEG 16 frame length: %d", [jpegData length]);
	
	theCInfo.err = jpeg_std_error (&theJErr);
	jpeg_create_decompress (&theCInfo);

	jpeg16_nsdata_src (&theCInfo, jpegData);
	//NSLog(@"read header");
	if (jpeg_read_header (&theCInfo, TRUE) != JPEG_HEADER_OK){
		//NSLog(@"Invalid header");
		return rawData;
	}
	if (_samplesPerPixel == 1)
		theCInfo.out_color_space = JCS_GRAYSCALE;

	if (_samplesPerPixel == 3)
		theCInfo.out_color_space = JCS_RGB;
	//NSLog(@"jpeg color space: %d", theCInfo.out_color_space);
	//start decompress	
	//NSLog(@"Start decompress");
	 (void) jpeg_start_decompress (&theCInfo);
	 
	/* JSAMPLEs per row in output buffer */
	theRowStride = theCInfo.output_width * theCInfo.output_components * 2;
	/*
		multiply be number of bytes
		should be 2 if we are here
	*/

	

    theBuffer16P = (unsigned short *) malloc ((unsigned long) theRowStride);
	rawData = [NSMutableData dataWithLength:2 * _rows * _columns * _samplesPerPixel];
    theWrkCh16P = [rawData mutableBytes];
	

  
  theLimit = theCInfo.output_width * theCInfo.output_components;
  

    while (theCInfo.output_scanline < theCInfo.output_height) 
    {
      (void) jpeg_read_scanlines (&theCInfo, (JSAMPARRAY) &theWrkCh16P, 1);
		theWrkCh16P += theLimit;
		
//      /* put the scanline in the image */
//      for (theLoop = 0; theLoop < (int) theLimit; theLoop ++)
//      {
//        *theWrkCh16P = theBuffer16P [theLoop];
//        theWrkCh16P++;
//      } /* for */

    } /* while ...line by line decompression of the image */
    
    /* frees the row used by the decompressor */
   // free ((void **) &theBuffer16P);
   free(theBuffer16P);


	(void) jpeg_finish_decompress (&theCInfo);
  
  /* MAL added : cf Example.c */
  /* Step 8: Release JPEG decompression object */

  /* This is an important step since it will release a good deal of memory. */
	jpeg_destroy_decompress(&theCInfo);
	//NSLog(@"finISH decompression");
	return rawData;
}


@end
