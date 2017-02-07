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
 *  Purpose: compression routines of the IJG JPEG library configured for 16 bits/sample. 
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:44 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmjpeg/djeijg16.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#include "osconfig.h"
#include "djeijg16.h"
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
#define IJGE16_BLOCKSIZE 16384

BEGIN_EXTERN_C
#define boolean ijg_boolean
#include "jpeglib16.h"
#include "jerror16.h"
#include "jpegint16.h"
#undef boolean

// disable any preprocessor magic the IJG library might be doing with the "const" keyword
#ifdef const
#undef const
#endif

// private error handler struct
struct DJEIJG16ErrorStruct
{
  // the standard IJG error handler object
  struct jpeg_error_mgr pub;

  // our jump buffer
  jmp_buf setjmp_buffer;

  // pointer to this
  DJCompressIJG16Bit *instance;
};

// callback forward declarations
void DJEIJG16ErrorExit(j_common_ptr);
void DJEIJG16OutputMessage(j_common_ptr cinfo);
void DJEIJG16initDestination(j_compress_ptr cinfo);
ijg_boolean DJEIJG16emptyOutputBuffer(j_compress_ptr cinfo);
void DJEIJG16termDestination(j_compress_ptr cinfo);

END_EXTERN_C


// error handler, executes longjmp

void DJEIJG16ErrorExit(j_common_ptr cinfo)
{
  DJEIJG16ErrorStruct *myerr = (DJEIJG16ErrorStruct *)cinfo->err;
  longjmp(myerr->setjmp_buffer, 1);
}

// message handler for warning messages and the like
void DJEIJG16OutputMessage(j_common_ptr cinfo)
{
  DJEIJG16ErrorStruct *myerr = (DJEIJG16ErrorStruct *)cinfo->err;
  myerr->instance->outputMessage(cinfo);
}


// callbacks for compress-destination-manager

void DJEIJG16initDestination(j_compress_ptr cinfo)
{
  DJCompressIJG16Bit *encoder = (DJCompressIJG16Bit *)cinfo->client_data;
  encoder->initDestination(cinfo);
}

ijg_boolean DJEIJG16emptyOutputBuffer(j_compress_ptr cinfo)
{
  DJCompressIJG16Bit *encoder = (DJCompressIJG16Bit *)cinfo->client_data;
  return encoder->emptyOutputBuffer(cinfo);
}

void DJEIJG16termDestination(j_compress_ptr cinfo)
{
  DJCompressIJG16Bit *encoder = (DJCompressIJG16Bit *)cinfo->client_data;
  encoder->termDestination(cinfo);
}


// converts dcmtk color space to IJG color space

static J_COLOR_SPACE getJpegColorSpace(EP_Interpretation interpr)
{
  switch (interpr)
  {
    case EPI_Unknown :return JCS_UNKNOWN;
    case EPI_Monochrome1 : return JCS_GRAYSCALE;
    case EPI_Monochrome2 : return JCS_GRAYSCALE;
    case EPI_PaletteColor : return JCS_UNKNOWN;
    case EPI_RGB : return JCS_RGB;
    case EPI_HSV : return JCS_UNKNOWN;
    case EPI_ARGB : return JCS_RGB;
    case EPI_CMYK : return JCS_CMYK;
    case EPI_YBR_Full : return JCS_YCbCr;
    case EPI_YBR_Full_422 : return JCS_YCbCr;
    case EPI_YBR_Partial_422 : return JCS_YCbCr;
    default : return JCS_UNKNOWN;
  }
}

DJCompressIJG16Bit::DJCompressIJG16Bit(const DJCodecParameter& cp, EJ_Mode mode, int prediction, int ptrans)
: DJEncoder()
, cparam(&cp)
, psv(prediction)
, pt(ptrans)
, modeofOperation(mode)
, pixelDataList()
, bytesInLastBlock(0)
{
  assert(mode == EJM_lossless);
}

DJCompressIJG16Bit::~DJCompressIJG16Bit()
{
  cleanup();
}

OFCondition DJCompressIJG16Bit::encode(
    Uint16 /* columns */,
    Uint16 /* rows */,
    EP_Interpretation /* interpr */,
    Uint16 /* samplesPerPixel */,
    Uint8 * /* image_buffer */,
    Uint8 *& /* to */,
    Uint32 & /* length */,
	Uint8 pixelRepresentation,
	double minUsed, double maxUsed)
{
  return EC_IllegalCall;
}

OFCondition DJCompressIJG16Bit::encode( 
  Uint16 columns,
  Uint16 rows,
  EP_Interpretation colorSpace,
  Uint16 samplesPerPixel,
  Uint16 * image_buffer,
  Uint8 * & to,
  Uint32 & length,
  Uint8 pixelRepresentation,
  double minUsed, double maxUsed)
{

  struct jpeg_compress_struct cinfo;
  struct DJEIJG16ErrorStruct jerr;
  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.instance = this;
  jerr.pub.error_exit = DJEIJG16ErrorExit;
  jerr.pub.output_message = DJEIJG16OutputMessage;
  if (setjmp(jerr.setjmp_buffer))
  {
    // the IJG error handler will cause the following code to be executed
    char buffer[JMSG_LENGTH_MAX];    
    (*cinfo.err->format_message)((jpeg_common_struct *)(&cinfo), buffer); /* Create the message */
    jpeg_destroy_compress(&cinfo);
    return makeOFCondition(OFM_dcmjpeg, EJCode_IJG16_Compression, OF_error, buffer);
  }
  jpeg_create_compress(&cinfo);

  // initialize client_data
  cinfo.client_data = (void *)this;

  // Specify destination manager
  jpeg_destination_mgr dest;
  dest.init_destination = DJEIJG16initDestination;
  dest.empty_output_buffer = DJEIJG16emptyOutputBuffer;
  dest.term_destination = DJEIJG16termDestination;
  cinfo.dest = &dest;

  cinfo.image_width = columns;
  cinfo.image_height = rows;
  cinfo.input_components = samplesPerPixel;
  cinfo.in_color_space = getJpegColorSpace(colorSpace);

  jpeg_set_defaults(&cinfo);

  if (cparam->getCompressionColorSpaceConversion() != ECC_lossyYCbCr)
  {
    // prevent IJG library from doing any color space conversion
    jpeg_set_colorspace (&cinfo, cinfo.in_color_space);
  }

  cinfo.optimize_coding = OFTrue; // must always be true for 16 bit compression

  switch (modeofOperation)
  {
    case EJM_lossless:
     // always disables any kind of color space conversion
     jpeg_simple_lossless(&cinfo,psv,pt);
     break;
    default:
     return makeOFCondition(OFM_dcmjpeg, EJCode_IJG16_Compression, OF_error, "JPEG with 16 bits/sample only allowed with lossless compression");
     /* break; */
  }
  
  cinfo.smoothing_factor = cparam->getSmoothingFactor();

  // initialize sampling factors
  if (cinfo.jpeg_color_space == JCS_YCbCr)
  {
    switch(cparam->getSampleFactors())
    {
      case ESS_444: /* 4:4:4 sampling (no subsampling) */
        cinfo.comp_info[0].h_samp_factor = 1;
        cinfo.comp_info[0].v_samp_factor = 1;
        break;
      case ESS_422: /* 4:2:2 sampling (horizontal subsampling of chroma components) */
        cinfo.comp_info[0].h_samp_factor = 2;
        cinfo.comp_info[0].v_samp_factor = 1;
        break;
      case ESS_411: /* 4:1:1 sampling (horizontal and vertical subsampling of chroma components) */
        cinfo.comp_info[0].h_samp_factor = 2;
        cinfo.comp_info[0].v_samp_factor = 2;
        break;
    }
  }
  else
  {
    // JPEG color space is not YCbCr, disable subsampling.
    cinfo.comp_info[0].h_samp_factor = 1;
    cinfo.comp_info[0].v_samp_factor = 1;
  }

  // all other components are set to 1x1
  for (int sfi=1; sfi< MAX_COMPONENTS; sfi++)
  {
    cinfo.comp_info[sfi].h_samp_factor = 1;
    cinfo.comp_info[sfi].v_samp_factor = 1;
  }

  JSAMPROW row_pointer[1];
  jpeg_start_compress(&cinfo,TRUE);
  int row_stride = columns * samplesPerPixel;
  while (cinfo.next_scanline < cinfo.image_height) 
  {
    // JSAMPLE might be signed, typecast to avoid a warning
    row_pointer[0] = (JSAMPLE *)(& image_buffer[cinfo.next_scanline * row_stride]);
    jpeg_write_scanlines(&cinfo, row_pointer, 1);
  }
  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);

  length = (Uint32)bytesInLastBlock;
  if (pixelDataList.size() > 1) length += (pixelDataList.size() - 1)*IJGE16_BLOCKSIZE;
  if (length % 2) length++; // ensure even length    

  to = new Uint8[length];
  if (to == NULL) return EC_MemoryExhausted;
  if (length > 0) to[length-1] = 0;    

  size_t offset=0;
  OFListIterator(unsigned char *) first = pixelDataList.begin();
  OFListIterator(unsigned char *) last = pixelDataList.end();
  OFListIterator(unsigned char *) shortBlock = last;
  --shortBlock;
  while (first != last)
  {
    if (first == shortBlock)
    {
      memcpy(to+offset, *first, bytesInLastBlock);
      offset += bytesInLastBlock;
    }
    else
    {
      memcpy(to+offset, *first, IJGE16_BLOCKSIZE);
      offset += IJGE16_BLOCKSIZE;
    }
    ++first;
  }
  cleanup();

  return EC_Normal;
}

void DJCompressIJG16Bit::initDestination(jpeg_compress_struct *cinfo)
{
  cleanup(); // erase old list of compressed blocks, if any

  unsigned char *newBlock = new unsigned char[IJGE16_BLOCKSIZE];
  if (newBlock)
  {
    pixelDataList.push_back(newBlock);
    cinfo->dest->next_output_byte = newBlock;
    cinfo->dest->free_in_buffer = IJGE16_BLOCKSIZE;    
  }
  else
  {
    cinfo->dest->next_output_byte = NULL;
    cinfo->dest->free_in_buffer = 0;    
  }
}

int DJCompressIJG16Bit::emptyOutputBuffer(jpeg_compress_struct *cinfo)
{
  bytesInLastBlock = 0;
  unsigned char *newBlock = new unsigned char[IJGE16_BLOCKSIZE];
  if (newBlock)
  {
    pixelDataList.push_back(newBlock);
    cinfo->dest->next_output_byte = newBlock;
    cinfo->dest->free_in_buffer = IJGE16_BLOCKSIZE;    
  }
  else
  {
    cinfo->dest->next_output_byte = NULL;
    cinfo->dest->free_in_buffer = 0;    
    ERREXIT1(cinfo, JERR_OUT_OF_MEMORY, 0xFF);
  }
  return TRUE;
}


void DJCompressIJG16Bit::termDestination(jpeg_compress_struct *cinfo)
{
  bytesInLastBlock = IJGE16_BLOCKSIZE - cinfo->dest->free_in_buffer;
}

void DJCompressIJG16Bit::cleanup()
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

void DJCompressIJG16Bit::outputMessage(void *arg) const
{
  jpeg_common_struct *cinfo = (jpeg_common_struct *)arg;
  if (cinfo && cparam->isVerbose())
  {
    char buffer[JMSG_LENGTH_MAX];    
    (*cinfo->err->format_message)(cinfo, buffer); /* Create the message */
    ofConsole.lockCerr() << buffer << endl;
    ofConsole.unlockCerr();
  }
}


/*
 * CVS/RCS Log
 * $Log: djeijg16.cc,v $
 * Revision 1.1  2006/03/01 20:15:44  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.8  2005/12/08 15:43:40  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.7  2005/11/28 17:09:52  meichel
 * Fixed bug affecting JPEG compression with 12 or 16 bits/pixel,
 *   where Huffman table optimization is required but was not always enabled.
 *
 * Revision 1.6  2005/11/14 17:09:39  meichel
 * Changed some function return types from int to ijg_boolean, to avoid
 *   compilation errors if the ijg_boolean type is ever changed.
 *
 * Revision 1.5  2003/10/13 13:25:49  meichel
 * Added workaround for name clash of typedef "boolean" in the IJG header files
 *   and the standard headers for Borland C++.
 *
 * Revision 1.4  2002/11/27 15:40:01  meichel
 * Adapted module dcmjpeg to use of new header file ofstdinc.h
 *
 * Revision 1.3  2001/12/18 09:48:59  meichel
 * Modified configure test for "const" support of the C compiler
 *   in order to avoid a macro recursion error on Sun CC 2.0.1
 *
 * Revision 1.2  2001/11/19 15:13:32  meichel
 * Introduced verbose mode in module dcmjpeg. If enabled, warning
 *   messages from the IJG library are printed on ofConsole, otherwise
 *   the library remains quiet.
 *
 * Revision 1.1  2001/11/13 15:58:30  meichel
 * Initial release of module dcmjpeg
 *
 *
 */
