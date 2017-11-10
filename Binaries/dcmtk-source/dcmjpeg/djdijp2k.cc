#include "options.h"

#include "osconfig.h"
#include "djdijp2k.h"
#include "djcparam.h"
#include "ofconsol.h"
#include "OPJSupport.h"

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

BEGIN_EXTERN_C
#define boolean ijg_boolean
#include "jpeglib16.h"
#include "jerror16.h"
#undef boolean

// disable any preprocessor magic the IJG library might be doing with the "const" keyword
#ifdef const
#undef const
#endif


////#include "openjpeg.h"
///**
//sample error callback expecting a FILE* client object
//*/
//static void error_callback(const char *msg, void *a)
//{
////	printf( "%s\r\r", msg);
//}
///**
//sample warning callback expecting a FILE* client object
//*/
//static void warning_callback(const char *msg, void *a)
//{
////	printf( "%s\r\r", msg);
//}
//
///**
//sample debug callback expecting no client object
//*/
//static void info_callback(const char *msg, void *a)
//{
////	printf( "%s\r\r", msg);
//}
//
//static inline int int_ceildivpow2(int a, int b) {
//	return (a + (1 << b) - 1) >> b;
//}



DJDecompressJP2k::DJDecompressJP2k(const DJCodecParameter& cp, OFBool isYBR)
: DJDecoder()
, cparam(&cp)
, cinfo(NULL)
, suspension(0)
, jsampBuffer(NULL)
, dicomPhotometricInterpretationIsYCbCr(isYBR)
, decompressedColorModel(EPI_Unknown)
{
}

DJDecompressJP2k::~DJDecompressJP2k()
{
  cleanup();
}


OFCondition DJDecompressJP2k::init()
{
  // everything OK
  return EC_Normal;
}


void DJDecompressJP2k::cleanup()
{
}


OFCondition DJDecompressJP2k::decode(
  Uint8 *compressedFrameBuffer,
  Uint32 compressedFrameBufferSize,
  Uint8 *uncompressedFrameBuffer,
  Uint32 uncompressedFrameBufferSize,
  OFBool isSigned)
{    
	{
		int processors = 0;
		
		if( compressedFrameBufferSize > 512*1024)
        {
            int mib[2] = {CTL_HW, HW_NCPU};
            size_t dataLen = sizeof(int); // 'num' is an 'int'
            int result = sysctl(mib, 2, &processors, &dataLen, NULL, 0);
            if (result == -1)
                processors = 1;
            if( processors > 8)
                processors = 8;
        }
		
		long decompressedBufferSize = 0;
		int colorModel;
		
        OPJSupport opj;
        opj.decompressJPEG2KWithBuffer( uncompressedFrameBuffer,
                                       compressedFrameBuffer,
                                       compressedFrameBufferSize,
                                       &decompressedBufferSize,
                                       &colorModel);
        
		if( colorModel == 1)
			decompressedColorModel = (EP_Interpretation) EPI_RGB;
	}
//	else
//	{
//		opj_dparameters_t parameters;  /* decompression parameters */
//		opj_event_mgr_t event_mgr;    /* event manager */
//		opj_image_t *image = 0L;
//		opj_dinfo_t* dinfo;  /* handle to a decompressor */
//		opj_cio_t *cio;
//		unsigned char *src = (unsigned char*) compressedFrameBuffer; 
//		int file_length = compressedFrameBufferSize;
//
//		/* configure the event callbacks (not required) */
//		memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
//		event_mgr.error_handler = error_callback;
//		event_mgr.warning_handler = warning_callback;
//		event_mgr.info_handler = info_callback;
//
//	  /* set decoding parameters to default values */
//	  opj_set_default_decoder_parameters(&parameters);
//	 
//	   // default blindly copied
//	   parameters.cp_layer=0;
//	   parameters.cp_reduce=0;
//	//   parameters.decod_format=-1;
//	//   parameters.cod_format=-1;
//
//		  /* JPEG-2000 codestream */
//		parameters.decod_format = 0;
//	  parameters.cod_format = 1;
//
//		  /* get a decoder handle */
//		  dinfo = opj_create_decompress(CODEC_J2K);
//
//		  /* catch events using our callbacks and give a local context */
//		  opj_set_event_mgr((opj_common_ptr)dinfo, &event_mgr, NULL);
//
//		  /* setup the decoder decoding parameters using user parameters */
//		  opj_setup_decoder(dinfo, &parameters);
//
//		  /* open a byte stream */
//		  cio = opj_cio_open((opj_common_ptr)dinfo, src, file_length);
//
//		  /* decode the stream and fill the image structure */
//		  image = opj_decode(dinfo, cio);
//		  if(!image)
//		  {
//			opj_destroy_decompress(dinfo);
//			opj_cio_close(cio);
//			return false;
//		  }
//		  
//		  /* close the byte stream */
//		  opj_cio_close(cio);
//
//	  /* free the memory containing the code-stream */
//
////	   printf( "JP2K-DCMTK-Decode ");
//
//	   // Copy buffer
//	   for (int compno = 0; compno < image->numcomps; compno++)
//	   {
//		  opj_image_comp_t *comp = &image->comps[compno];
//
//		  int w = image->comps[compno].w;
//		  int wr = int_ceildivpow2(image->comps[compno].w, image->comps[compno].factor);
//		   int numcomps = image->numcomps;
//		   
//		  int hr = int_ceildivpow2(image->comps[compno].h, image->comps[compno].factor);
//		   
//		   if( wr == w && numcomps == 1)
//		   {
////			   decompressedColorModel = EPI_Monochrome2; //It could be EPI_Monochrome1
//			   
//			   if (comp->prec <= 8)
//			   {
//				   uint8_t *data8 = (uint8_t*)uncompressedFrameBuffer + compno;
//				   int *data = image->comps[compno].data;
//				   int i = wr * hr;
//				   while( i -- > 0)
//					   *data8++ = (uint8_t) *data++;
//			   }
//			   else if (comp->prec <= 16)
//			   {
//				   uint16_t *data16 = (uint16_t*)uncompressedFrameBuffer + compno;
//				   int *data = image->comps[compno].data;
//				   int i = wr * hr;
//					while( i -- > 0)
//						*data16++ = (uint16_t) *data++;
//			   }
//			   else
//			   {
//					printf( "****** 32-bit jpeg encoded is NOT supported\r");
//	//			   uint32_t *data32 = (uint32_t*)raw + compno;
//	//			   int *data = image->comps[compno].data;
//	//			   int i = wr * hr;
//	//			   while( i -- > 0)
//	//				   *data32++ = (uint32_t) *data++;
//			   }
//		   }
//		   else
//		   {
//				decompressedColorModel = EPI_RGB;
//				
//				if (comp->prec <= 8)
//				{
//				 uint8_t *data8 = (uint8_t*)uncompressedFrameBuffer + compno;
//				 for (int i = 0; i < wr * hr; i++)
//				 {
//					*data8 = (uint8_t) (image->comps[compno].data[i / wr * w + i % wr]);
//					data8 += numcomps;
//				 }
//				}
//				else if (comp->prec <= 16)
//				{
//				 uint16_t *data16 = (uint16_t*)uncompressedFrameBuffer + compno;
//				 for (int i = 0; i < wr * hr; i++)
//				 {
//					*data16 = (uint16_t) (image->comps[compno].data[i / wr * w + i % wr]);
//					data16 += numcomps;
//				 }
//				}
//				else
//				{
//					printf( "****** 32-bit jpeg encoded is NOT supported\r");
//	//			 uint32_t *data32 = (uint32_t*)raw + compno;
//	//			 for (int i = 0; i < wr * hr; i++)
//	//			 {
//	//				*data32 = (uint32_t) (image->comps[compno].data[i / wr * w + i % wr]);
//	//				data32 += numcomps;
//	//			 }
//				}
//		   }
//		  //free(image.comps[compno].data);
//	   }
//
//
//	  /* free remaining structures */
//	  if(dinfo) {
//		opj_destroy_decompress(dinfo);
//	  }
//
//	  /* free image data structure */
//	  if( image)
//		opj_image_destroy(image);
//
//	}
	
	return EC_Normal;
}

void DJDecompressJP2k::outputMessage() const
{

}
}
