/*
 *
 *  Copyright (C) 1997-2005, OFFIS
 *
 *  This software and supporting documentation were developed by
 *
 *    Kuratorium OFFIS e.V.
 *    Healthcare Information and Communication Systems
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *  THIS SOFTWARE IS MADE AVAILABLE,  AS IS,  AND OFFIS MAKES NO  WARRANTY
 *  REGARDING  THE  SOFTWARE,  ITS  PERFORMANCE,  ITS  MERCHANTABILITY  OR
 *  FITNESS FOR ANY PARTICULAR USE, FREEDOM FROM ANY COMPUTER DISEASES  OR
 *  ITS CONFORMITY TO ANY SPECIFICATION. THE ENTIRE RISK AS TO QUALITY AND
 *  PERFORMANCE OF THE SOFTWARE IS WITH THE USER.
 *
 *  Module:  dcmjpeg
 *
 *  Author:  Marco Eichelberg, Norbert Olges
 *
 *  Purpose: compression routines of the IJG JPEG library configured for 12 bits/sample. 
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:44 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmjpeg/djeijg12.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#include "osconfig.h"
#include "djeijg2k.h"
#include "djcparam.h"
#include "ofconsol.h"
#import "Accelerate/Accelerate.h"
#include "ofconsol.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#define INCLUDE_CSTDIO
#define INCLUDE_CSETJMP
#include "ofstdinc.h"

// These two macros are re-defined in the IJG header files.
// We undefine them here and hope that IJG's configure has
// come to the same conclusion that we have...
#ifdef HAVE_STDLIB_H
#undef HAVE_STDLIB_H
#endif
#ifdef HAVE_STDDEF_H
#undef HAVE_STDDEF_H
#endif

// KDU support
#include <CoreServices/CoreServices.h>
#include "kdu_OsiriXSupport.h"
extern short Use_kdu_IfAvailable;

// use 16K blocks for temporary storage of compressed JPEG data
#define IJGE12_BLOCKSIZE 16384

/**
sample error callback expecting a FILE* client object
*/
static void error_callback(const char *msg, void *a)
{
	printf( "%s", msg);
}
/**
sample warning callback expecting a FILE* client object
*/
static void warning_callback(const char *msg, void *a)
{
	printf( "%s", msg);
}
/**
sample debug callback expecting no client object
*/
static void info_callback(const char *msg, void *a)
{
//	NSLog( @"%s", msg);
}

static inline int int_ceildivpow2(int a, int b)
{
	return (a + (1 << b) - 1) >> b;
}


DJCompressJP2K::DJCompressJP2K(const DJCodecParameter& cp, EJ_Mode mode, Uint8 theQuality, Uint8 theBitsPerSample)
: DJEncoder()
, cparam(&cp)
, quality(theQuality)
, bitsPerSampleValue(theBitsPerSample)
, modeofOperation(mode)
{

}

DJCompressJP2K::~DJCompressJP2K()
{

}

//template<typename T>
//static void rawtoimage_fill(T *inputbuffer, int w, int h, int numcomps, opj_image_t *image, int pc)
//{
//  T *p = inputbuffer;
//  if( pc )
//    {
//    for(int compno = 0; compno < numcomps; compno++)
//      {
//      for (int i = 0; i < w * h; i++)
//        {
//        /* compno : 0 = GREY, (0, 1, 2) = (R, G, B) */
//        image->comps[compno].data[i] = *p;
//        ++p;
//        }
//      }
//    }
//  else
//    {
//    for (int i = 0; i < w * h; i++)
//      {
//      for(int compno = 0; compno < numcomps; compno++)
//        {
//        /* compno : 0 = GREY, (0, 1, 2) = (R, G, B) */
//        image->comps[compno].data[i] = *p;
//        ++p;
//        }
//      }
//    }
//}
//
//
//static opj_image_t* rawtoimage(char *inputbuffer, opj_cparameters_t *parameters,
//  int fragment_size, int image_width, int image_height, int sample_pixel,
//  int bitsallocated, int bitsstored, int sign, int pc)
//{
//  int w, h;
//  int numcomps;
//  OPJ_COLOR_SPACE color_space;
//  opj_image_cmptparm_t cmptparm[3]; /* maximum of 3 components */
//  opj_image_t * image = NULL;
//
//  assert( sample_pixel == 1 || sample_pixel == 3 );
//  if( sample_pixel == 1 )
//    {
//    numcomps = 1;
//    color_space = CLRSPC_GRAY;
//    }
//  else // sample_pixel == 3
//    {
//    numcomps = 3;
//    color_space = CLRSPC_SRGB;
//    /* Does OpenJPEg support: CLRSPC_SYCC ?? */
//    }
//  if( bitsallocated % 8 != 0 )
//    {
//    return 0;
//    }
//  assert( bitsallocated % 8 == 0 );
//  // eg. fragment_size == 63532 and 181 * 117 * 3 * 8 == 63531 ...
//  assert( ((fragment_size + 1)/2 ) * 2 == ((image_height * image_width * numcomps * (bitsallocated/8) + 1)/ 2 )* 2 );
//  int subsampling_dx = parameters->subsampling_dx;
//  int subsampling_dy = parameters->subsampling_dy;
//
//  // FIXME
//  w = image_width;
//  h = image_height;
//
//  /* initialize image components */
//  memset(&cmptparm[0], 0, 3 * sizeof(opj_image_cmptparm_t));
//  //assert( bitsallocated == 8 );
//  for(int i = 0; i < numcomps; i++) {
//    cmptparm[i].prec = bitsstored;
//    cmptparm[i].bpp = bitsallocated;
//    cmptparm[i].sgnd = sign;
//    cmptparm[i].dx = subsampling_dx;
//    cmptparm[i].dy = subsampling_dy;
//    cmptparm[i].w = w;
//    cmptparm[i].h = h;
//  }
//
//  /* create the image */
//  image = opj_image_create(numcomps, &cmptparm[0], color_space);
//  if(!image) {
//    return NULL;
//  }
//  /* set image offset and reference grid */
//  image->x0 = parameters->image_offset_x0;
//  image->y0 = parameters->image_offset_y0;
//  image->x1 = parameters->image_offset_x0 + (w - 1) * subsampling_dx + 1;
//  image->y1 = parameters->image_offset_y0 + (h - 1) * subsampling_dy + 1;
//
//  /* set image data */
//
//  //assert( fragment_size == numcomps*w*h*(bitsallocated/8) );
//  if (bitsallocated <= 8)
//    {
//    if( sign )
//      {
//      rawtoimage_fill<int8_t>((int8_t*)inputbuffer,w,h,numcomps,image,pc);
//      }
//    else
//      {
//      rawtoimage_fill<uint8_t>((uint8_t*)inputbuffer,w,h,numcomps,image,pc);
//      }
//    }
//  else if (bitsallocated <= 16)
//    {
//    if( sign )
//      {
//      rawtoimage_fill<int16_t>((int16_t*)inputbuffer,w,h,numcomps,image,pc);
//      }
//    else
//      {
//      rawtoimage_fill<uint16_t>((uint16_t*)inputbuffer,w,h,numcomps,image,pc);
//      }
//    }
//  else if (bitsallocated <= 32)
//    {
//    if( sign )
//      {
//      rawtoimage_fill<int32_t>((int32_t*)inputbuffer,w,h,numcomps,image,pc);
//      }
//    else
//      {
//      rawtoimage_fill<uint32_t>((uint32_t*)inputbuffer,w,h,numcomps,image,pc);
//      }
//    }
//  else
//    {
//    return NULL;
//    }
//
//  return image;
//}

void DJCompressJP2K::findMinMax( int &_min, int &_max, char *bytes, long length, OFBool isSigned, int rows, int columns, int bitsAllocated)
{
    _min = 0;
    _max = 0;
    
	float max = 0,  min = 0;
	
	if (bitsAllocated <= 8) 
		length = length;
	else if (bitsAllocated <= 16)
		length = length/2;
	else
		length = length/4;
		
	float *fBuffer = (float*) malloc(length * 4);
	if( fBuffer)
	{
		vImage_Buffer src, dstf;
		dstf.height = src.height = rows;
		dstf.width = src.width = columns;
		dstf.rowBytes = columns*sizeof(float);
		dstf.data = fBuffer;
		src.data = (void*) bytes;
		
		if (bitsAllocated <= 8)
		{
			src.rowBytes = columns;
			vImageConvert_Planar8toPlanarF( &src, &dstf, 0, 256, 0);
		}
		else if (bitsAllocated <= 16)
		{
			src.rowBytes = columns * 2;
			
			if( isSigned)
				vImageConvert_16SToF( &src, &dstf, 0, 1, 0);
			else
				vImageConvert_16UToF( &src, &dstf, 0, 1, 0);
		}
		
		vDSP_minv( fBuffer, 1, &min, length);
		vDSP_maxv( fBuffer, 1, &max, length);
		
        //        if( min < _min || max > _max)
        //        {
        //            float fmin = _min;
        //            float fmax = _max;
        //
        //            vDSP_vclip( fBuffer, nil, &fmin, &fmax, fBuffer, nil, columns * rows);
        //
        //            if( isSigned)
        //				vImageConvert_FTo16S( &dstf, &src, 0, 1, 0);
        //			else
        //				vImageConvert_FTo16U( &dstf, &src, 0, 1, 0);
        //        }

        
		_min = min;
		_max = max;
		
//		// The goal of this 'trick' is to avoid the problem that some annotations can generate, if they are 'incrusted' in the image
//		// the jp2k algorithm doesn't like them at all...
//		
//		if( isSigned == NO && _max == 65535)
//		{
//			long i = _columns * _rows;
//			// Compute the new max
//			while( i-->0)
//			{
//				if( fBuffer[ i] == 0xFFFF)
//					fBuffer[ i] = _min;
//			}
//			
//			vDSP_minv( fBuffer, 1, &min, length);
//			vDSP_maxv( fBuffer, 1, &max, length);
//			
//			_min = min;
//			_max = max;
//			
//			// Modify the original data
//			
//			unsigned short *ptr = (unsigned short*) bytes;
//			
//			i = _columns * _rows;
//			while( i-->0)
//			{
//				if( ptr[ i] == 0xFFFF)
//					ptr[ i] = _max;
//			}
//		}
		
		free(fBuffer);
	}
    else
        printf( "\r**** DJCompressJP2K::findMinMax malloc failed\r");
}

OFCondition DJCompressJP2K::encode( 
  Uint16 columns,
  Uint16 rows,
  EP_Interpretation colorSpace,
  Uint16 samplesPerPixel,
  Uint8 * image_buffer,
  Uint8 * & to,
  Uint32 & length,
  Uint8 pixelRepresentation,
  double minUsed, double maxUsed)
{
	return encode( columns, rows, colorSpace, samplesPerPixel, (Uint8*) image_buffer, to, length, 8, pixelRepresentation, minUsed, maxUsed);
}

OFCondition DJCompressJP2K::encode(
    Uint16  columns ,
    Uint16  rows ,
    EP_Interpretation  interpr ,
    Uint16  samplesPerPixel ,
    Uint16 *  image_buffer ,
    Uint8 *&  to ,
    Uint32 &  length,
	Uint8 pixelRepresentation,
	double minUsed, double maxUsed)
{
	return encode( columns, rows, interpr, samplesPerPixel, (Uint8*) image_buffer, to, length, 16, pixelRepresentation, minUsed, maxUsed);
}

Uint16 DJCompressJP2K::bytesPerSample() const
{
	if( bitsPerSampleValue <= 8)
		return 1;
	else
		return 2;
}

Uint16 DJCompressJP2K::bitsPerSample() const
{
	return bitsPerSampleValue;
}

OFCondition DJCompressJP2K::encode( 
  Uint16 columns,
  Uint16 rows,
  EP_Interpretation colorSpace,
  Uint16 samplesPerPixel,
  Uint8 * image_buffer,
  Uint8 * & to,
  Uint32 & length,
  Uint8 bitsAllocated,
  Uint8 pixelRepresentation,
  double minUsed, double maxUsed)
{
	int bitsstored = bitsAllocated;
	
    if( samplesPerPixel > 1)
        bitsstored = bitsAllocated = 8;
    
	OFBool isSigned = 0;
	
	if( bitsAllocated >= 16)
	{
		if( minUsed == 0 && maxUsed == 0)
		{
			int _min = 0, _max = 0;
			findMinMax( _min, _max, (char*) image_buffer, columns*rows*samplesPerPixel*bitsAllocated/8, isSigned, rows, columns, bitsAllocated);
			
//			if( minUsed != _min || maxUsed != _max)
//				printf("\r******* ( minUsed != _min || maxUsed != _max) ********\r");
			
			minUsed = _min;
			maxUsed = _max;
		}
		
		int amplitude = maxUsed;
		
		if( minUsed < 0)
			amplitude -= minUsed;
		
		int bits = 1, value = 2;
		
		while( value < amplitude && bits <= 16)
		{
			value *= 2;
			bits++;
		}
		
		if( minUsed < 0) // K A10009536850 22.06.12
			bits++;
		
		if( bits < 9)
			bits = 9;
		
		// avoid the artifacts... switch to lossless
		if( (maxUsed >= 32000 && minUsed <= -32000) || maxUsed >= 65000 || bits > 16)
			quality = 0;
		
		if( bits > 16) bits = 16;
		
		bitsstored = bits;
	}
	
	if( Use_kdu_IfAvailable && kdu_available())
	{
//		printf( "JP2K KDU-DCMTK-Encode ");
		
//		int precision = bitsstored;
		int rate = 0;
		
		switch( quality)
		{
			case 0: //DCMLosslessQuality:
				rate = 0;
				break;
				
			case 1: //DCMHighQuality:
				rate = 5;
				break;
				
			case 2: //DCMMediumQuality:
				if( columns <= 600 || rows <= 600) rate = 6;
				else rate = 8;
				break;
				
			case 3: //DCMLowQuality:
				rate = 16;
				break;
				
			default:
				printf( "****** warning unknown compression rate -> lossless : %d", quality);
				rate = 0;
				break;
		}
		
		long compressedLength = 0;
		
		int processors = 0;
		
		if( rows*columns > 256*1024) // 512 * 512
        {
            int mib[2] = {CTL_HW, HW_NCPU};
            size_t dataLen = sizeof(int); // 'num' is an 'int'
            int result = sysctl(mib, 2, &processors, &dataLen, NULL, 0);
            if (result == -1)
                processors = 1;
            if( processors > 8)
                processors = 8;
        }
		
		void *outBuffer = kdu_compressJPEG2K( (void*) image_buffer, samplesPerPixel, rows, columns, bitsstored, false, rate, &compressedLength, processors);
		
		if( outBuffer)
		{
			to = new Uint8[ compressedLength];
			memcpy( to, outBuffer, compressedLength);
			length = compressedLength;
		
			free( outBuffer);
		}
	}
//	else
//	{
//		opj_cparameters_t parameters;
//		opj_event_mgr_t event_mgr;
//		opj_image_t *image = NULL;
//		
////		printf( "JP2K OPJ-DCMTK-Encode ");
//		
//		memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
//		event_mgr.error_handler = error_callback;
//		event_mgr.warning_handler = warning_callback;
//		event_mgr.info_handler = info_callback;
//
//		memset(&parameters, 0, sizeof(parameters));
//		opj_set_default_encoder_parameters(&parameters);
//		
//		parameters.tcp_numlayers = 1;
//		parameters.cp_disto_alloc = 1;
//		
//		switch( quality)
//		{
//			case 0: // DCMLosslessQuality
//				parameters.tcp_rates[0] = 0;
//			break;
//			
//			case 1: // DCMHighQuality
//				parameters.tcp_rates[0] = 4;
//			break;
//			
//			case 2: // DCMMediumQuality
//				if( columns <= 600 || rows <= 600)
//					parameters.tcp_rates[0] = 6;
//				else
//					parameters.tcp_rates[0] = 8;
//			break;
//			
//			case 3: // DCMLowQuality
//				parameters.tcp_rates[0] = 16;
//			break;
//			
//			default:
//				printf( "****** warning unknown compression rate -> lossless : %d", quality);
//				parameters.tcp_rates[0] = 0;
//			break;
//		}
//		
//		int image_width = columns;
//		int image_height = rows;
//		int sample_pixel = samplesPerPixel;
//		
//		if (colorSpace == EPI_Monochrome1 || colorSpace == EPI_Monochrome2)
//		{
//		
//		}
//		else
//		{
//			if( sample_pixel != 3)
//				printf( "*** RGB Photometric?, but... SamplesPerPixel != 3 ?");
//			sample_pixel = 3;
//		}
//		
//		image = rawtoimage( (char*) image_buffer, &parameters,  static_cast<int>( columns*rows*samplesPerPixel*bitsAllocated/8),  image_width, image_height, sample_pixel, bitsAllocated, bitsstored, isSigned, 0);
//		
//		parameters.cod_format = 0; /* J2K format output */
//		int codestream_length;
//		opj_cio_t *cio = NULL;
//		
//		opj_cinfo_t* cinfo = opj_create_compress(CODEC_J2K);
//
//		/* catch events using our callbacks and give a local context */
//		opj_set_event_mgr((opj_common_ptr)cinfo, &event_mgr, stderr);
//
//		/* setup the encoder parameters using the current image and using user parameters */
//		opj_setup_encoder(cinfo, &parameters, image);
//
//		/* open a byte stream for writing */
//		/* allocate memory for all tiles */
//		cio = opj_cio_open((opj_common_ptr)cinfo, NULL, 0);
//
//		/* encode the image */
//		int bSuccess = opj_encode(cinfo, cio, image, NULL);
//		if (!bSuccess) {
//		  opj_cio_close(cio);
//		  fprintf(stderr, "failed to encode image\n");
//		  return false;
//		}
//		codestream_length = cio_tell(cio);
//		
//		to = new Uint8[ codestream_length];
//		memcpy( to, cio->buffer, codestream_length);
//		length = codestream_length;
//		
//		 /* close and free the byte stream */
//		opj_cio_close(cio);
//		
//		/* free remaining compression structures */
//		opj_destroy_compress(cinfo);
//		
//		opj_image_destroy(image);
//	}
	return EC_Normal;
}