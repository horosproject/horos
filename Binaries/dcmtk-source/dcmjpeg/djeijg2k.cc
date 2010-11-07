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

// use 16K blocks for temporary storage of compressed JPEG data
#define IJGE12_BLOCKSIZE 16384

#include "openjpeg.h"
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

//BEGIN_EXTERN_C
//#define boolean ijg_boolean
//#include "jpeglib12.h"
//#include "jerror12.h"
//#include "jpegint12.h"
//#undef boolean
//
//// disable any preprocessor magic the IJG library might be doing with the "const" keyword
//#ifdef const
//#undef const
//#endif
//
//// private error handler struct
//struct DJEIJG12ErrorStruct
//{
//  // the standard IJG error handler object
//  struct jpeg_error_mgr pub;
//
//  // our jump buffer
//  jmp_buf setjmp_buffer;
//
//  // pointer to this
//  DJCompressJP2K *instance;
//};
//
//// callback forward declarations
////void DJEIJG12ErrorExit(j_common_ptr);
////void DJEIJG12OutputMessage(j_common_ptr cinfo);
////void DJEIJG12initDestination(j_compress_ptr cinfo);
////ijg_boolean DJEIJG12emptyOutputBuffer(j_compress_ptr cinfo);
////void DJEIJG12termDestination(j_compress_ptr cinfo);
//
//END_EXTERN_C


// error handler, executes longjmp

//void DJEIJG12ErrorExit(j_common_ptr cinfo)
//{
//  DJEIJG12ErrorStruct *myerr = (DJEIJG12ErrorStruct *)cinfo->err;
//  longjmp(myerr->setjmp_buffer, 1);
//}
//
//// message handler for warning messages and the like
//void DJEIJG12OutputMessage(j_common_ptr cinfo)
//{
//  DJEIJG12ErrorStruct *myerr = (DJEIJG12ErrorStruct *)cinfo->err;
//  myerr->instance->outputMessage(cinfo);
//}

// callbacks for compress-destination-manager
//
//void DJEIJG12initDestination(j_compress_ptr cinfo)
//{
//  DJCompressJP2K *encoder = (DJCompressJP2K *)cinfo->client_data;
//  encoder->initDestination(cinfo);
//}
//
//ijg_boolean DJEIJG12emptyOutputBuffer(j_compress_ptr cinfo)
//{
//  DJCompressJP2K *encoder = (DJCompressJP2K *)cinfo->client_data;
//  return encoder->emptyOutputBuffer(cinfo);
//}
//
//void DJEIJG12termDestination(j_compress_ptr cinfo)
//{
//  DJCompressJP2K *encoder = (DJCompressJP2K *)cinfo->client_data;
//  encoder->termDestination(cinfo);
//}

/*
 * jpeg_simple_spectral_selection() creates a scan script
 * for progressive JPEG with spectral selection only,
 * similar to jpeg_simple_progression() for full progression.
 * The scan sequence for YCbCr is as proposed in the IJG documentation.
 * The scan sequence for all other color models is somewhat arbitrary.
 */
//static void jpeg_simple_spectral_selection(j_compress_ptr cinfo)
//{
//  int ncomps = cinfo->num_components;
//  jpeg_scan_info *scanptr = NULL;
//  int nscans = 0;
//
//  /* Safety check to ensure start_compress not called yet. */
//  if (cinfo->global_state != CSTATE_START) ERREXIT1(cinfo, JERR_BAD_STATE, cinfo->global_state);
//
//  if (ncomps == 3 && cinfo->jpeg_color_space == JCS_YCbCr) nscans = 7;
//  else nscans = 1 + 2 * ncomps;	/* 1 DC scan; 2 AC scans per component */
//
//  /* Allocate space for script.
//   * We need to put it in the permanent pool in case the application performs
//   * multiple compressions without changing the settings.  To avoid a memory
//   * leak if jpeg_simple_spectral_selection is called repeatedly for the same JPEG
//   * object, we try to re-use previously allocated space, and we allocate
//   * enough space to handle YCbCr even if initially asked for grayscale.
//   */
//  if (cinfo->script_space == NULL || cinfo->script_space_size < nscans)
//  {
//    cinfo->script_space_size = nscans > 7 ? nscans : 7;
//    cinfo->script_space = (jpeg_scan_info *)
//      (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, 
//      JPOOL_PERMANENT, cinfo->script_space_size * sizeof(jpeg_scan_info));
//  }
//  scanptr = cinfo->script_space;
//  cinfo->scan_info = scanptr;
//  cinfo->num_scans = nscans;
//
//  if (ncomps == 3 && cinfo->jpeg_color_space == JCS_YCbCr)
//  {
//    /* Custom script for YCbCr color images. */
//
//    // Interleaved DC scan for Y,Cb,Cr:
//    scanptr[0].component_index[0] = 0;
//    scanptr[0].component_index[1] = 1;
//    scanptr[0].component_index[2] = 2;
//    scanptr[0].comps_in_scan = 3;
//    scanptr[0].Ss = 0;
//    scanptr[0].Se = 0;
//    scanptr[0].Ah = 0;
//    scanptr[0].Al = 0;
//    
//    // AC scans
//    // First two Y AC coefficients
//    scanptr[1].component_index[0] = 0;
//    scanptr[1].comps_in_scan = 1;
//    scanptr[1].Ss = 1;
//    scanptr[1].Se = 2;
//    scanptr[1].Ah = 0;
//    scanptr[1].Al = 0;
//    
//    // Three more
//    scanptr[2].component_index[0] = 0;
//    scanptr[2].comps_in_scan = 1;
//    scanptr[2].Ss = 3;
//    scanptr[2].Se = 5;
//    scanptr[2].Ah = 0;
//    scanptr[2].Al = 0;
//    
//    // All AC coefficients for Cb
//    scanptr[3].component_index[0] = 1;
//    scanptr[3].comps_in_scan = 1;
//    scanptr[3].Ss = 1;
//    scanptr[3].Se = 63;
//    scanptr[3].Ah = 0;
//    scanptr[3].Al = 0;
//    
//    // All AC coefficients for Cr
//    scanptr[4].component_index[0] = 2;
//    scanptr[4].comps_in_scan = 1;
//    scanptr[4].Ss = 1;
//    scanptr[4].Se = 63;
//    scanptr[4].Ah = 0;
//    scanptr[4].Al = 0;
//    
//    // More Y coefficients
//    scanptr[5].component_index[0] = 0;
//    scanptr[5].comps_in_scan = 1;
//    scanptr[5].Ss = 6;
//    scanptr[5].Se = 9;
//    scanptr[5].Ah = 0;
//    scanptr[5].Al = 0;
//    
//    // Remaining Y coefficients
//    scanptr[6].component_index[0] = 0;
//    scanptr[6].comps_in_scan = 1;
//    scanptr[6].Ss = 10;
//    scanptr[6].Se = 63;
//    scanptr[6].Ah = 0;
//    scanptr[6].Al = 0;
//  }
//  else
//  {
//    /* All-purpose script for other color spaces. */
//    int j=0;
//    
//    // Interleaved DC scan for all components
//    for (j=0; j<ncomps; j++) scanptr[0].component_index[j] = j;
//    scanptr[0].comps_in_scan = ncomps;
//    scanptr[0].Ss = 0;
//    scanptr[0].Se = 0;
//    scanptr[0].Ah = 0;
//    scanptr[0].Al = 0;
//
//    // first AC scan for each component
//    for (j=0; j<ncomps; j++) 
//    {
//      scanptr[j+1].component_index[0] = j;
//      scanptr[j+1].comps_in_scan = 1;
//      scanptr[j+1].Ss = 1;
//      scanptr[j+1].Se = 5;
//      scanptr[j+1].Ah = 0;
//      scanptr[j+1].Al = 0;
//    }
//
//    // second AC scan for each component
//    for (j=0; j<ncomps; j++) 
//    {
//      scanptr[j+ncomps+1].component_index[0] = j;
//      scanptr[j+ncomps+1].comps_in_scan = 1;
//      scanptr[j+ncomps+1].Ss = 6;
//      scanptr[j+ncomps+1].Se = 63;
//      scanptr[j+ncomps+1].Ah = 0;
//      scanptr[j+ncomps+1].Al = 0;
//    }
//  }
//}


// converts dcmtk color space to IJG color space

//static J_COLOR_SPACE getJpegColorSpace(EP_Interpretation interpr)
//{
//  switch (interpr)
//  {
//    case EPI_Unknown :return JCS_UNKNOWN;
//    case EPI_Monochrome1 : return JCS_GRAYSCALE;
//    case EPI_Monochrome2 : return JCS_GRAYSCALE;
//    case EPI_PaletteColor : return JCS_UNKNOWN;
//    case EPI_RGB : return JCS_RGB;
//    case EPI_HSV : return JCS_UNKNOWN;
//    case EPI_ARGB : return JCS_RGB;
//    case EPI_CMYK : return JCS_CMYK;
//    case EPI_YBR_Full : return JCS_YCbCr;
//    case EPI_YBR_Full_422 : return JCS_YCbCr;
//    case EPI_YBR_Partial_422 : return JCS_YCbCr;
//    default : return JCS_UNKNOWN;
//  }
//}



DJCompressJP2K::DJCompressJP2K(const DJCodecParameter& cp, EJ_Mode mode, Uint8 theQuality, Uint8 theBitsAllocated)
: DJEncoder()
, cparam(&cp)
, quality(theQuality)
, bitsAllocated (theBitsAllocated)
, modeofOperation(mode)
, pixelDataList()
, bytesInLastBlock(0)
{

}

DJCompressJP2K::~DJCompressJP2K()
{
  cleanup();
}

OFCondition DJCompressJP2K::encode(
    Uint16 /* columns */,
    Uint16 /* rows */,
    EP_Interpretation /* interpr */,
    Uint16 /* samplesPerPixel */,
    Uint8 * /* image_buffer */,
    Uint8 *& /* to */,
    Uint32 & /* length */)
{
  return EC_IllegalCall;
}

template<typename T>
static void rawtoimage_fill(T *inputbuffer, int w, int h, int numcomps, opj_image_t *image, int pc)
{
  T *p = inputbuffer;
  if( pc )
    {
    for(int compno = 0; compno < numcomps; compno++)
      {
      for (int i = 0; i < w * h; i++)
        {
        /* compno : 0 = GREY, (0, 1, 2) = (R, G, B) */
        image->comps[compno].data[i] = *p;
        ++p;
        }
      }
    }
  else
    {
    for (int i = 0; i < w * h; i++)
      {
      for(int compno = 0; compno < numcomps; compno++)
        {
        /* compno : 0 = GREY, (0, 1, 2) = (R, G, B) */
        image->comps[compno].data[i] = *p;
        ++p;
        }
      }
    }
}


static opj_image_t* rawtoimage(char *inputbuffer, opj_cparameters_t *parameters,
  int fragment_size, int image_width, int image_height, int sample_pixel,
  int bitsallocated, int bitsstored, int sign, int pc)
{
  int w, h;
  int numcomps;
  OPJ_COLOR_SPACE color_space;
  opj_image_cmptparm_t cmptparm[3]; /* maximum of 3 components */
  opj_image_t * image = NULL;

  assert( sample_pixel == 1 || sample_pixel == 3 );
  if( sample_pixel == 1 )
    {
    numcomps = 1;
    color_space = CLRSPC_GRAY;
    }
  else // sample_pixel == 3
    {
    numcomps = 3;
    color_space = CLRSPC_SRGB;
    /* Does OpenJPEg support: CLRSPC_SYCC ?? */
    }
  if( bitsallocated % 8 != 0 )
    {
    return 0;
    }
  assert( bitsallocated % 8 == 0 );
  // eg. fragment_size == 63532 and 181 * 117 * 3 * 8 == 63531 ...
  assert( ((fragment_size + 1)/2 ) * 2 == ((image_height * image_width * numcomps * (bitsallocated/8) + 1)/ 2 )* 2 );
  int subsampling_dx = parameters->subsampling_dx;
  int subsampling_dy = parameters->subsampling_dy;

  // FIXME
  w = image_width;
  h = image_height;

  /* initialize image components */
  memset(&cmptparm[0], 0, 3 * sizeof(opj_image_cmptparm_t));
  //assert( bitsallocated == 8 );
  for(int i = 0; i < numcomps; i++) {
    cmptparm[i].prec = bitsstored;
    cmptparm[i].bpp = bitsallocated;
    cmptparm[i].sgnd = sign;
    cmptparm[i].dx = subsampling_dx;
    cmptparm[i].dy = subsampling_dy;
    cmptparm[i].w = w;
    cmptparm[i].h = h;
  }

  /* create the image */
  image = opj_image_create(numcomps, &cmptparm[0], color_space);
  if(!image) {
    return NULL;
  }
  /* set image offset and reference grid */
  image->x0 = parameters->image_offset_x0;
  image->y0 = parameters->image_offset_y0;
  image->x1 = parameters->image_offset_x0 + (w - 1) * subsampling_dx + 1;
  image->y1 = parameters->image_offset_y0 + (h - 1) * subsampling_dy + 1;

  /* set image data */

  //assert( fragment_size == numcomps*w*h*(bitsallocated/8) );
  if (bitsallocated <= 8)
    {
    if( sign )
      {
      rawtoimage_fill<int8_t>((int8_t*)inputbuffer,w,h,numcomps,image,pc);
      }
    else
      {
      rawtoimage_fill<uint8_t>((uint8_t*)inputbuffer,w,h,numcomps,image,pc);
      }
    }
  else if (bitsallocated <= 16)
    {
    if( sign )
      {
      rawtoimage_fill<int16_t>((int16_t*)inputbuffer,w,h,numcomps,image,pc);
      }
    else
      {
      rawtoimage_fill<uint16_t>((uint16_t*)inputbuffer,w,h,numcomps,image,pc);
      }
    }
  else if (bitsallocated <= 32)
    {
    if( sign )
      {
      rawtoimage_fill<int32_t>((int32_t*)inputbuffer,w,h,numcomps,image,pc);
      }
    else
      {
      rawtoimage_fill<uint32_t>((uint32_t*)inputbuffer,w,h,numcomps,image,pc);
      }
    }
  else
    {
    return NULL;
    }

  return image;
}

OFCondition DJCompressJP2K::encode( 
  Uint16 columns,
  Uint16 rows,
  EP_Interpretation colorSpace,
  Uint16 samplesPerPixel,
  Uint16 * image_buffer,
  Uint8 * & to,
  Uint32 & length)
{
		opj_cparameters_t parameters;
		opj_event_mgr_t event_mgr;
		opj_image_t *image = NULL;
		
		memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
		event_mgr.error_handler = error_callback;
		event_mgr.warning_handler = warning_callback;
		event_mgr.info_handler = info_callback;

		memset(&parameters, 0, sizeof(parameters));
		opj_set_default_encoder_parameters(&parameters);
		
		parameters.tcp_numlayers = 1;
		parameters.cp_disto_alloc = 1;
		
		switch( quality)
		{
			case 0: // DCMLosslessQuality
				parameters.tcp_rates[0] = 0;
			break;
			
			case 1: // DCMHighQuality
				parameters.tcp_rates[0] = 4;
			break;
			
			case 2: // DCMMediumQuality
				if( columns <= 600 || rows <= 600)
					parameters.tcp_rates[0] = 6;
				else
					parameters.tcp_rates[0] = 8;
			break;
			
			case 3: // DCMLowQuality
				parameters.tcp_rates[0] = 16;
			break;
			
			default:
				printf( "****** warning unknown compression rate -> lossless : %d", quality);
				parameters.tcp_rates[0] = 0;
			break;
		}
		
		int image_width = columns;
		int image_height = rows;
		int sample_pixel = samplesPerPixel;
		
		if (colorSpace == EPI_Monochrome1 || colorSpace == EPI_Monochrome2)
		{
		
		}
		else
		{
			if( sample_pixel != 3)
				printf( "*** RGB Photometric?, but... SamplesPerPixel != 3 ?");
			sample_pixel = 3;
		}
		
		int bitsstored = bitsAllocated;
		
		if( bitsAllocated >= 16)
		{
//			[self findMinAndMax: data];
//			
//			int amplitude = _max;
//			
//			if( _min < 0)
//				amplitude -= _min;
//			
//			int bits = 1, value = 2;
//			
//			while( value < amplitude)
//			{
//				value *= 2;
//				bits++;
//			}
//			
//			if( _min < 0)
//			{
//				[_dcmObject setAttributeValues: [NSMutableArray arrayWithObject: [NSNumber numberWithBool: YES]] forName:@"PixelRepresentation"];
//				bits++;  // For the sign
//			}
//			else
//				[_dcmObject setAttributeValues: [NSMutableArray arrayWithObject: [NSNumber numberWithBool: NO]] forName:@"PixelRepresentation"];
//			
//			if( bits < 9) bits = 9;
//			
//			// avoid the artifacts... switch to lossless
//			if( (_max >= 32000 && _min <= -32000) || _max >= 65000 || bits > 16)
//			{
//				parameters.tcp_rates[0] = 0;
//				parameters.tcp_numlayers = 1;
//				parameters.cp_disto_alloc = 1;
//			}
//			
//			if( bits > 16) bits = 16;
//			
//			bitsstored = bits;
		}
		
//		DCMAttribute *signedAttr = [[_dcmObject attributes] objectForKey:[[DCMAttributeTag tagWithName:@"PixelRepresentation"] stringValue]];
//		BOOL sign = [[signedAttr value] boolValue];
		
		int sign = 1; // PixelRepresentation
		
		image = rawtoimage( (char*) image_buffer, &parameters,  static_cast<int>( columns*rows*samplesPerPixel*bitsAllocated/8),  image_width, image_height, sample_pixel, bitsAllocated, bitsstored, sign, 0);
		
		parameters.cod_format = 0; /* J2K format output */
		int codestream_length;
		opj_cio_t *cio = NULL;
		
		opj_cinfo_t* cinfo = opj_create_compress(CODEC_J2K);

		/* catch events using our callbacks and give a local context */
		opj_set_event_mgr((opj_common_ptr)cinfo, &event_mgr, stderr);

		/* setup the encoder parameters using the current image and using user parameters */
		opj_setup_encoder(cinfo, &parameters, image);

		/* open a byte stream for writing */
		/* allocate memory for all tiles */
		cio = opj_cio_open((opj_common_ptr)cinfo, NULL, 0);

		/* encode the image */
		int bSuccess = opj_encode(cinfo, cio, image, NULL);
		if (!bSuccess) {
		  opj_cio_close(cio);
		  fprintf(stderr, "failed to encode image\n");
		  return false;
		}
		codestream_length = cio_tell(cio);
		
		to = new Uint8[ codestream_length];
		memcpy( to, cio->buffer, codestream_length);
		length = codestream_length;
		
		 /* close and free the byte stream */
		opj_cio_close(cio);
		
		/* free remaining compression structures */
		opj_destroy_compress(cinfo);
		
		opj_image_destroy(image);
		
	return EC_Normal;

//
//  struct jpeg_compress_struct cinfo;
//  struct DJEIJG12ErrorStruct jerr;
//  cinfo.err = jpeg_std_error(&jerr.pub);
//  jerr.instance = this;
//  jerr.pub.error_exit = DJEIJG12ErrorExit;
//  jerr.pub.output_message = DJEIJG12OutputMessage;
//  if (setjmp(jerr.setjmp_buffer))
//  {
//    // the IJG error handler will cause the following code to be executed
//    char buffer[JMSG_LENGTH_MAX];    
//    (*cinfo.err->format_message)((jpeg_common_struct *)(&cinfo), buffer); /* Create the message */
//    jpeg_destroy_compress(&cinfo);
//    return makeOFCondition(OFM_dcmjpeg, EJCode_IJG12_Compression, OF_error, buffer);
//  }
//  jpeg_create_compress(&cinfo);
//
//  // initialize client_data
//  cinfo.client_data = (void *)this;
//
//  // Specify destination manager
//  jpeg_destination_mgr dest;
//  dest.init_destination = DJEIJG12initDestination;
//  dest.empty_output_buffer = DJEIJG12emptyOutputBuffer;
//  dest.term_destination = DJEIJG12termDestination;
//  cinfo.dest = &dest;
//
//  cinfo.image_width = columns;
//  cinfo.image_height = rows;
//  cinfo.input_components = samplesPerPixel;
//  cinfo.in_color_space = getJpegColorSpace(colorSpace);
//
//  jpeg_set_defaults(&cinfo);
//
//  if (cparam->getCompressionColorSpaceConversion() != ECC_lossyYCbCr)
//  {
//    // prevent IJG library from doing any color space conversion
//    jpeg_set_colorspace (&cinfo, cinfo.in_color_space);
//  }
//
//  cinfo.optimize_coding = OFTrue; // must always be true for 12 bit compression
//
//  switch (modeofOperation)
//  {
//    case EJM_baseline: // baseline only supports 8 bits/sample. Assume sequential.
//    case EJM_sequential:
//      jpeg_set_quality(&cinfo, quality, 0);
//      break;
//    case EJM_spectralSelection:
//      jpeg_set_quality(&cinfo, quality, 0);
//      jpeg_simple_spectral_selection(&cinfo);
//      break;
//    case EJM_progressive:
//      jpeg_set_quality(&cinfo, quality, 0);
//      jpeg_simple_progression(&cinfo);
//      break;
//    case EJM_lossless:
//     // always disables any kind of color space conversion
//     jpeg_simple_lossless(&cinfo,psv,pt);
//     break;
//  }
//  
//  cinfo.smoothing_factor = cparam->getSmoothingFactor();
//
//  // initialize sampling factors
//  if (cinfo.jpeg_color_space == JCS_YCbCr)
//  {
//    switch(cparam->getSampleFactors())
//    {
//      case ESS_444: /* 4:4:4 sampling (no subsampling) */
//        cinfo.comp_info[0].h_samp_factor = 1;
//        cinfo.comp_info[0].v_samp_factor = 1;
//        break;
//      case ESS_422: /* 4:2:2 sampling (horizontal subsampling of chroma components) */
//        cinfo.comp_info[0].h_samp_factor = 2;
//        cinfo.comp_info[0].v_samp_factor = 1;
//        break;
//      case ESS_411: /* 4:1:1 sampling (horizontal and vertical subsampling of chroma components) */
//        cinfo.comp_info[0].h_samp_factor = 2;
//        cinfo.comp_info[0].v_samp_factor = 2;
//        break;
//    }
//  }
//  else
//  {
//    // JPEG color space is not YCbCr, disable subsampling.
//    cinfo.comp_info[0].h_samp_factor = 1;
//    cinfo.comp_info[0].v_samp_factor = 1;
//  }
//
//  // all other components are set to 1x1
//  for (int sfi=1; sfi< MAX_COMPONENTS; sfi++)
//  {
//    cinfo.comp_info[sfi].h_samp_factor = 1;
//    cinfo.comp_info[sfi].v_samp_factor = 1;
//  }
//
//  JSAMPROW row_pointer[1];
//  jpeg_start_compress(&cinfo,TRUE);
//  int row_stride = columns * samplesPerPixel;
//  while (cinfo.next_scanline < cinfo.image_height) 
//  {
//    // JSAMPLE is signed, typecast to avoid a warning
//    row_pointer[0] = (JSAMPLE *)(& image_buffer[cinfo.next_scanline * row_stride]);
//    jpeg_write_scanlines(&cinfo, row_pointer, 1);
//  }
//  jpeg_finish_compress(&cinfo);
//  jpeg_destroy_compress(&cinfo);
//
//  length = bytesInLastBlock;
//  if (pixelDataList.size() > 1) length += (pixelDataList.size() - 1)*IJGE12_BLOCKSIZE;
//  if (length % 2) length++; // ensure even length    
//
//  to = new Uint8[length];
//  if (to == NULL) return EC_MemoryExhausted;
//  if (length > 0) to[length-1] = 0;    
//
//  size_t offset=0;
//  OFListIterator(unsigned char *) first = pixelDataList.begin();
//  OFListIterator(unsigned char *) last = pixelDataList.end();
//  OFListIterator(unsigned char *) shortBlock = last;
//  --shortBlock;
//  while (first != last)
//  {
//    if (first == shortBlock)
//    {
//      memcpy(to+offset, *first, bytesInLastBlock);
//      offset += bytesInLastBlock;
//    }
//    else
//    {
//      memcpy(to+offset, *first, IJGE12_BLOCKSIZE);
//      offset += IJGE12_BLOCKSIZE;
//    }
//    ++first;
//  }
//  cleanup();

  return EC_Normal;
}

//void DJCompressJP2K::initDestination(jpeg_compress_struct *cinfo)
//{
//  cleanup(); // erase old list of compressed blocks, if any
//
//  unsigned char *newBlock = new unsigned char[IJGE12_BLOCKSIZE];
//  if (newBlock)
//  {
//    pixelDataList.push_back(newBlock);
//    cinfo->dest->next_output_byte = newBlock;
//    cinfo->dest->free_in_buffer = IJGE12_BLOCKSIZE;    
//  }
//  else
//  {
//    cinfo->dest->next_output_byte = NULL;
//    cinfo->dest->free_in_buffer = 0;    
//  }
//}

//int DJCompressJP2K::emptyOutputBuffer(jpeg_compress_struct *cinfo)
//{
//  bytesInLastBlock = 0;
//  unsigned char *newBlock = new unsigned char[IJGE12_BLOCKSIZE];
//  if (newBlock)
//  {
//    pixelDataList.push_back(newBlock);
//    cinfo->dest->next_output_byte = newBlock;
//    cinfo->dest->free_in_buffer = IJGE12_BLOCKSIZE;    
//  }
//  else
//  {
//    cinfo->dest->next_output_byte = NULL;
//    cinfo->dest->free_in_buffer = 0;    
//    ERREXIT1(cinfo, JERR_OUT_OF_MEMORY, 0xFF);
//  }
//  return TRUE;
//}
//
//
//void DJCompressJP2K::termDestination(jpeg_compress_struct *cinfo)
//{
//  bytesInLastBlock = IJGE12_BLOCKSIZE - cinfo->dest->free_in_buffer;
//}

void DJCompressJP2K::cleanup()
{
  OFListIterator(unsigned char *) first = pixelDataList.begin();
  OFListIterator(unsigned char *) last = pixelDataList.end();
  while (first != last)
  {
    delete[] *first;
    first = pixelDataList.erase(first);
  }
  bytesInLastBlock = 0;
}

//void DJCompressJP2K::outputMessage(void *arg) const
//{
//  jpeg_common_struct *cinfo = (jpeg_common_struct *)arg;
//  if (cinfo && cparam->isVerbose())
//  {
//    char buffer[JMSG_LENGTH_MAX];    
//    (*cinfo->err->format_message)(cinfo, buffer); /* Create the message */
//    ofConsole.lockCerr() << buffer << endl;
//    ofConsole.unlockCerr();
//  }
//}