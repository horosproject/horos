/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
//
//  OPJSupport.cpp
//  OsiriX_Lion
//
//  Created by Aaron Boxer on 21 Jan 2014
//  Updated by Alex Bettarini on 17 Feb 2015

#include "OPJSupport.h"

#include <OpenJPEG/openjpeg.h>
#include <OpenJPEG/format_defs.h>

#define JPT_CFMT 2
#define OPJ_CODEC_JPT 1

#include <assert.h>
#include <stdlib.h>
#include <iostream>

#include <ofthread.h>

//#define WITH_OPJ_BUFFER_STREAM
#define WITH_OPJ_FILE_STREAM
//#define OPJ_VERBOSE


typedef struct decode_info
{
    opj_codec_t *codec;
    opj_stream_t *stream;
    opj_image_t *image;
    opj_codestream_info_v2_t* cstr_info;
    opj_codestream_index_t* cstr_index;
    OPJ_BOOL deleteImage;
    
} decode_info_t;

#define JP2_RFC3745_MAGIC "\x00\x00\x00\x0c\x6a\x50\x20\x20\x0d\x0a\x87\x0a"
#define JP2_MAGIC "\x0d\x0a\x87\x0a"
/* position 45: "\xff\x52" */
#define J2K_CODESTREAM_MAGIC "\xff\x4f\xff\x51"


// Adapted from infile_format() in /src/bin/jp2/opj_decompress.c
static int buffer_format(void * buf)
{
    int magic_format;
    
    if (memcmp(buf, JP2_RFC3745_MAGIC, 12) == 0 || memcmp(buf, JP2_MAGIC, 4) == 0)
    {
        magic_format = JP2_CFMT;
    }
    else if (memcmp(buf, J2K_CODESTREAM_MAGIC, 4) == 0)
    {
        magic_format = J2K_CFMT;
    }
    else
    {
        return -1;
    }
    
    return magic_format;
}

const char *clr_space(OPJ_COLOR_SPACE i)
{
    if(i == OPJ_CLRSPC_SRGB) return "OPJ_CLRSPC_SRGB";
    if(i == OPJ_CLRSPC_GRAY) return "OPJ_CLRSPC_GRAY";
    if(i == OPJ_CLRSPC_SYCC) return "OPJ_CLRSPC_SYCC";
    if(i == OPJ_CLRSPC_UNKNOWN) return "OPJ_CLRSPC_UNKNOWN";
    return "CLRSPC_UNDEFINED";
}

void release(decode_info_t *decodeInfo)
{
    if(decodeInfo->codec) {
        opj_destroy_codec(decodeInfo->codec);
        decodeInfo->codec = NULL;
    }
    
    if(decodeInfo->stream) {
        opj_stream_destroy(decodeInfo->stream);
        decodeInfo->stream = NULL;
    }
    
    if(decodeInfo->deleteImage && decodeInfo->image) {
        opj_image_destroy(decodeInfo->image);
        decodeInfo->image = NULL;
    }
}

OPJSupport::OPJSupport() {}

OPJSupport::~OPJSupport() {}

/* -------------------------------------------------------------------------- */
// from "src/bin/jp2/opj_dump.c"


/**
 sample error debug callback expecting no client object
 */
static void error_callback(const char *msg, void *client_data)
{
    (void)client_data;
    fprintf(stdout, "[OPJ ERROR] %s", msg);
}


#ifdef OPJ_VERBOSE
/**
 sample warning debug callback expecting no client object
 */
static void warning_callback(const char *msg, void *client_data)
{
    (void)client_data;
    fprintf(stdout, "[OPJ WARNING] %s", msg);
}


/**
 sample debug callback expecting no client object
 */
static void info_callback(const char *msg, void *client_data)
{
    (void)client_data;
    fprintf(stdout, "[OPJ INFO] %s", msg);
}
#endif

/* -------------------------------------------------------------------------- */


void* OPJSupport::decompressJPEG2K( void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel)
{
    return decompressJPEG2KWithBuffer(NULL, jp2Data, jp2DataSize, decompressedBufferSize, colorModel);
}

void* OPJSupport::decompressJPEG2KWithBuffer(void* inputBuffer,
                                             void* jp2Data,
                                             long jp2DataSize,
                                             long *decompressedBufferSize,
                                             int *colorModel)
{
    //opj_initialize("");
    opj_dparameters_t parameters;
    int i;
    int width, height;
    OPJ_BOOL hasAlpha, fails = OPJ_FALSE;
    OPJ_CODEC_FORMAT codec_format;
    unsigned char rc, gc, bc, ac;
    
    if (jp2DataSize<12)
    {
        
        return 0;
    }
    
    /*-----------------------------------------------*/
    
    decode_info_t decodeInfo;
    memset(&decodeInfo, 0, sizeof(decode_info_t));
    
    opj_set_default_decoder_parameters(&parameters);
    parameters.decod_format = buffer_format(jp2Data);
    
    // Create buffer stream
    decodeInfo.stream = opj_stream_create_buffer_stream((OPJ_BYTE *)jp2Data, (OPJ_SIZE_T) jp2DataSize , false, OPJ_STREAM_READ);
    
    
    if (!decodeInfo.stream)
    {
        fprintf(stderr,"%s:%d:\n\tNO decodeInfo.stream\n",__FILE__,__LINE__);
        
        return NULL;
    }
    
    /*-----------------------------------------------*/
    
    switch (parameters.decod_format)
    {
            case J2K_CFMT:                      /* JPEG-2000 codestream */
            codec_format = OPJ_CODEC_J2K;
            break;
            
            case JP2_CFMT:                      /* JPEG 2000 compressed image data */
            codec_format = OPJ_CODEC_JP2;
            break;
            
            case JPT_CFMT:                      /* JPEG 2000, JPIP */
            codec_format = (OPJ_CODEC_FORMAT) OPJ_CODEC_JPT;
            break;
            
            case -1:
            
        default:
            
            release(&decodeInfo);
            
            fprintf(stderr,"%s:%d: decode format missing\n",__FILE__,__LINE__);
            
            return NULL;
    }
    
    /*-----------------------------------------------*/
    
    while(1)
    {
        int user_changed_tile=0, user_changed_reduction=0;
        int max_tiles=0, max_reduction=0;
        fails = OPJ_TRUE;
        
        decodeInfo.codec = opj_create_decompress(codec_format);
        if (decodeInfo.codec == NULL)
        {
            fprintf(stderr,"%s:%d:\n\tNO codec\n",__FILE__,__LINE__);
            break;
        }
        
#ifdef OPJ_VERBOSE
        opj_set_info_handler(decodeInfo.codec, info_callback, this);
        opj_set_warning_handler(decodeInfo.codec, warning_callback, this);
#endif
        opj_set_error_handler(decodeInfo.codec, error_callback, this);
        
        // Setup the decoder decoding parameters
        if ( !opj_setup_decoder(decodeInfo.codec, &parameters))
        {
            fprintf(stderr,"%s:%d:\n\topj_setup_decoder failed\n",__FILE__,__LINE__);
            break;
        }
        
        if (user_changed_tile && user_changed_reduction)
        {
            int reduction=0;
            opj_set_decoded_resolution_factor(decodeInfo.codec, reduction);
        }
        
        /* Read the main header of the codestream and if necessary the JP2 boxes
         * see openjpeg.c
         * For OPJ_CODEC_JP2 it will call 'opj_jp2_read_header()' in jp2.c:2276
         * then call 'opj_j2k_read_header()'
         */
        if( !opj_read_header(decodeInfo.stream, decodeInfo.codec, &(decodeInfo.image)))
        {
            fprintf(stderr,"%s:%d:\n\topj_read_header failed\n",__FILE__,__LINE__);
            break;
        }
        
        if ( !(user_changed_tile && user_changed_reduction)
            || (max_tiles <= 0) || (max_reduction <= 0) )
        {
            decodeInfo.cstr_info = opj_get_cstr_info(decodeInfo.codec);
            
            max_reduction = decodeInfo.cstr_info->m_default_tile_info.tccp_info->numresolutions;
            max_tiles = decodeInfo.cstr_info->tw * decodeInfo.cstr_info->th;
            
            decodeInfo.cstr_index = opj_get_cstr_index(decodeInfo.codec);
        }
        
        if (!parameters.nb_tile_to_decode)
        {
            int user_changed_area=0;
            
            if(user_changed_area)
            {
                
            }
            
            /* Optional if you want decode the entire image */
            if (!opj_set_decode_area(decodeInfo.codec, decodeInfo.image,
                                     (OPJ_INT32)parameters.DA_x0,
                                     (OPJ_INT32)parameters.DA_y0,
                                     (OPJ_INT32)parameters.DA_x1,
                                     (OPJ_INT32)parameters.DA_y1)) {
                fprintf(stderr,"%s:%d:\n\topj_set_decode_area failed\n",__FILE__,__LINE__);
                break;
            }
            
            /* Get the decoded image */
            if (!opj_decode(decodeInfo.codec, decodeInfo.stream, decodeInfo.image)) {
                fprintf(stderr,"%s:%d:\n\topj_decode failed\n",__FILE__,__LINE__);
                
                
                return NULL;
            }
            
            if (!opj_end_decompress(decodeInfo.codec, decodeInfo.stream)) {
                fprintf(stderr,"%s:%d:\n\topj_end_decompress failed\n",__FILE__,__LINE__);
                break;
            }
            
        }
        else
        {
            if (!opj_get_decoded_tile(decodeInfo.codec, decodeInfo.stream, decodeInfo.image, parameters.tile_index))
            {
                fprintf(stderr,"%s:%d:\n\topj_get_decoded_tile failed\n",__FILE__,__LINE__);
                break;
            }
        }
        
        fails = OPJ_FALSE;
        break;
    } // while
    
    decodeInfo.deleteImage = fails;
    
    if (fails)
    {
        
        return NULL;
    }
    
    decodeInfo.deleteImage = OPJ_TRUE;
    
    if(decodeInfo.image->color_space == OPJ_CLRSPC_SYCC)
    {
        //disable for now
        //color_sycc_to_rgb(decodeInfo.image);
    }
    
    if (decodeInfo.image->color_space != OPJ_CLRSPC_SYCC
        && decodeInfo.image->numcomps == 3
        && decodeInfo.image->comps[0].dx == decodeInfo.image->comps[0].dy
        && decodeInfo.image->comps[1].dx != 1)
    {
        decodeInfo.image->color_space = OPJ_CLRSPC_SYCC;
    }
    else if(decodeInfo.image->numcomps <= 2)
    {
        decodeInfo.image->color_space = OPJ_CLRSPC_GRAY;
    }
    
    if (decodeInfo.image->icc_profile_buf)
    {
#if defined(HAVE_LIBLCMS1) || defined(HAVE_LIBLCMS2)
        color_apply_icc_profile(decodeInfo.image);
#endif
        free(decodeInfo.image->icc_profile_buf);
        decodeInfo.image->icc_profile_buf = NULL;
        decodeInfo.image->icc_profile_len = 0;
    }
    
    //---
    
    width = decodeInfo.image->comps[0].w;
    height = decodeInfo.image->comps[0].h;
    
    long depth = (decodeInfo.image->comps[0].prec + 7)/8;
    long decompressSize = width * height * decodeInfo.image->numcomps * depth;
    if (decompressedBufferSize)
    *decompressedBufferSize = decompressSize;;
    
    if (!inputBuffer )
    {
        inputBuffer =  malloc(decompressSize);
    }
    
    if (colorModel)
    *colorModel = 0;
    
    if ((decodeInfo.image->numcomps >= 3
         && decodeInfo.image->comps[0].dx == decodeInfo.image->comps[1].dx
         && decodeInfo.image->comps[1].dx == decodeInfo.image->comps[2].dx
         && decodeInfo.image->comps[0].dy == decodeInfo.image->comps[1].dy
         && decodeInfo.image->comps[1].dy == decodeInfo.image->comps[2].dy
         && decodeInfo.image->comps[0].prec == decodeInfo.image->comps[1].prec
         && decodeInfo.image->comps[1].prec == decodeInfo.image->comps[2].prec
         )/* RGB[A] */
        ||
        (decodeInfo.image->numcomps == 2
         && decodeInfo.image->comps[0].dx == decodeInfo.image->comps[1].dx
         && decodeInfo.image->comps[0].dy == decodeInfo.image->comps[1].dy
         && decodeInfo.image->comps[0].prec == decodeInfo.image->comps[1].prec
         )
        ) /* GA */
    {
        int  has_alpha4, has_alpha2, has_rgb;
        int *red, *green, *blue, *alpha;
        
        if (colorModel)
        *colorModel = 1;
        
        alpha = NULL;
        
        has_rgb = (decodeInfo.image->numcomps == 3);
        has_alpha4 = (decodeInfo.image->numcomps == 4);
        has_alpha2 = (decodeInfo.image->numcomps == 2);
        hasAlpha = (has_alpha4 || has_alpha2);
        
        if(has_rgb)
        {
            red = decodeInfo.image->comps[0].data;
            green = decodeInfo.image->comps[1].data;
            blue = decodeInfo.image->comps[2].data;
            
            if(has_alpha4)
            {
                alpha = decodeInfo.image->comps[3].data;
            }
            
        }    /* if(has_rgb) */
        else
        {
            red = green = blue = decodeInfo.image->comps[0].data;
            if(has_alpha2)
            {
                alpha = decodeInfo.image->comps[1].data;
            }
        }    /* if(has_rgb) */
        
        ac = 255;/* 255: FULLY_OPAQUE; 0: FULLY_TRANSPARENT */
        
        unsigned char* ptrIBody = (unsigned char*)inputBuffer;
        for(i = 0; i < width*height; i++)
        {
            rc = (unsigned char)*red++;
            gc = (unsigned char)*green++;
            bc = (unsigned char)*blue++;
            if(hasAlpha)
            {
                ac = (unsigned char)*alpha++;;
            }
            
            /*                         A        R          G       B
             */
            //*ptrIBody++ = (int)((ac<<24) | (rc<<16) | (gc<<8) | bc);
            *ptrIBody = rc;
            ptrIBody++;
            *ptrIBody = gc;
            ptrIBody++;
            *ptrIBody = bc;
            ptrIBody++;
            if (hasAlpha)
            {
                *ptrIBody = ac;
                ptrIBody++;
            }
        }    /* for(i) */
    }/* if (decodeInfo.image->numcomps >= 3  */
    else if(decodeInfo.image->numcomps == 1) /* Grey */
    {
        /* 1 component 8 or 16 bpp decodeInfo.image
         */
        int *grey = decodeInfo.image->comps[0].data;
        if(decodeInfo.image->comps[0].prec <= 8)
        {
            char* ptrBBody = (char*)inputBuffer;
            for(i=0; i<width*height; i++)
            {
                *ptrBBody++ = *grey++;
            }
            /* Replace image8 buffer:
             */
        }
        else /* prec[9:16] */
        {
            int *grey = decodeInfo.image->comps[0].data;
            //int ushift = 0, dshift = 0, force16 = 0;
            
            short* ptrSBody = (short*)inputBuffer;
            
            for(i=0; i<width*height; i++)
            {
                //disable shift up for signed data: don't know why we are doing this
                *ptrSBody++ = *grey++;
            }
            /* Replace image16 buffer:
             */
        }
    }
    else
    {
        int *grey;
        
        fprintf(stderr,"%s:%d:Can show only first component of decodeInfo.image\n"
                "  components(%d) prec(%d) color_space[%d](%s)\n"
                "  RECT(%d,%d,%d,%d)\n",__FILE__,__LINE__,decodeInfo.image->numcomps,
                decodeInfo.image->comps[0].prec,
                decodeInfo.image->color_space,clr_space(decodeInfo.image->color_space),
                decodeInfo.image->x0,decodeInfo.image->y0,decodeInfo.image->x1,decodeInfo.image->y1 );
        
        for(i = 0; i < decodeInfo.image->numcomps; ++i)
        {
            fprintf(stderr,"[%d]dx(%d) dy(%d) w(%d) h(%d) signed(%u)\n",i,
                    decodeInfo.image->comps[i].dx ,decodeInfo.image->comps[i].dy,
                    decodeInfo.image->comps[i].w,decodeInfo.image->comps[i].h,
                    decodeInfo.image->comps[i].sgnd);
        }
        
        /* 1 component 8 or 16 bpp decodeInfo.image
         */
        grey = decodeInfo.image->comps[0].data;
        if(decodeInfo.image->comps[0].prec <= 8)
        {
            char* ptrBBody = (char*)inputBuffer;
            for(i=0; i<width*height; i++)
            {
                *ptrBBody++ = *grey++;
            }
            /* Replace image8 buffer:
             */
        }
        else /* prec[9:16] */
        {
            int *grey;
            //int ushift = 0, dshift = 0, force16 = 0;
            
            grey = decodeInfo.image->comps[0].data;
            
            short* ptrSBody = (short*)inputBuffer;
            
            for(i=0; i<width*height; i++)
            {
                *ptrSBody++ = *grey++;
            }
            /* Replace image16 buffer:
             */
        }
    }
    
    release(&decodeInfo);
    opj_destroy_cstr_index(&(decodeInfo.cstr_index));
    
    
    return inputBuffer;
}




template<typename T>
void rawtoimage_fill(T *inputbuffer, int w, int h, int numcomps, opj_image_t *image, int pc)
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




static
opj_image_t* rawtoimage(char *inputbuffer, opj_cparameters_t *parameters,
                        int fragment_size, int image_width, int image_height, int sample_pixel,
                        int bitsallocated, int bitsstored, int sign, /*int quality,*/ int pc)
{
    //(void)quality;
    int w, h;
    int numcomps;
    OPJ_COLOR_SPACE color_space;
    opj_image_cmptparm_t cmptparm[3]; /* maximum of 3 components */
    opj_image_t * image = NULL;
    
    assert( sample_pixel == 1 || sample_pixel == 3 );
    if( sample_pixel == 1 )
    {
        numcomps = 1;
        color_space = OPJ_CLRSPC_GRAY;
    }
    else // sample_pixel == 3
    {
        numcomps = 3;
        color_space = OPJ_CLRSPC_SRGB;
        /* Does OpenJPEG support: OPJ_CLRSPC_SYCC ?? */
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
    
    for(int i = 0; i < numcomps; i++)
    {
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
    if (!image)
    {
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



unsigned char *
OPJSupport::compressJPEG2K(void *data,
                           int samplesPerPixel,
                           int rows,
                           int columns,
                           int bitsstored, //precision,
                           unsigned char bitsAllocated,
                           bool sign,
                           int rate,
                           long *compressedDataSize)
{
    
    opj_cparameters_t parameters;
    
    opj_stream_t *l_stream = 00;
    opj_codec_t* l_codec = 00;
    opj_image_t *image = NULL;
    
    OPJ_BOOL bSuccess;
    OPJ_BOOL bUseTiles = OPJ_FALSE; /* OPJ_TRUE */
    OPJ_UINT32 l_nb_tiles = 4;
    
    OPJ_BOOL fails = OPJ_FALSE;
    OPJ_CODEC_FORMAT codec_format;
    
    memset(&parameters, 0, sizeof(parameters));
    opj_set_default_encoder_parameters(&parameters);
    parameters.outfile[0] = '\0';
    parameters.tcp_numlayers = 1;
    parameters.cp_disto_alloc = 1;
    parameters.tcp_rates[0] = rate;
    parameters.cod_format = JP2_CFMT; //JP2_CFMT; //J2K_CFMT;
    OPJ_BOOL forceJ2K = (parameters.cod_format == J2K_CFMT ? OPJ_FALSE:(((OPJ_TRUE /*force here*/))));
    
#ifdef WITH_OPJ_FILE_STREAM
    tmpnam(parameters.outfile);
#endif
    
    image = rawtoimage( (char*) data,
                       &parameters,
                       static_cast<int>( columns*rows*samplesPerPixel*bitsAllocated/8), // [data length], fragment_size
                       columns, rows,
                       samplesPerPixel,
                       bitsAllocated,
                       bitsstored,
                       sign,
                       /*quality,*/ 0);
    
    if (image == NULL)
    {
        /* close and free the byte stream */
        if (l_stream) opj_stream_destroy(l_stream);
        
        /* free remaining compression structures */
        if (l_codec) opj_destroy_codec(l_codec);
        
        /* free image data */
        if (image) opj_image_destroy(image);
        
        *compressedDataSize = 0;
        
        
        return NULL;
    }
    
    /*-----------------------------------------------*/
    
    switch (parameters.cod_format)
    {
            case J2K_CFMT:                      /* JPEG-2000 codestream */
            codec_format = OPJ_CODEC_J2K;
            break;
            
            case JP2_CFMT:                      /* JPEG 2000 compressed image data */
            codec_format = OPJ_CODEC_JP2;
            break;
            
            case JPT_CFMT:                      /* JPEG 2000, JPIP */
            codec_format = (OPJ_CODEC_FORMAT) OPJ_CODEC_JPT;
            break;
            
            case -1:
        default:
            fprintf(stderr,"%s:%d: encode format missing\n",__FILE__,__LINE__);
            
            /* close and free the byte stream */
            if (l_stream) opj_stream_destroy(l_stream);
            
            /* free remaining compression structures */
            if (l_codec) opj_destroy_codec(l_codec);
            
            /* free image data */
            if (image) opj_image_destroy(image);
            
            *compressedDataSize = 0;
            
            
            return NULL;
    }
    
    /* see test_tile_encoder.c:232 and opj_compress.c:1746 */
    l_codec = opj_create_compress(codec_format);
    if (!l_codec)
    {
        fprintf(stderr,"%s:%d:\n\tNO codec\n",__FILE__,__LINE__);
        
        /* close and free the byte stream */
        if (l_stream) opj_stream_destroy(l_stream);
        
        /* free remaining compression structures */
        if (l_codec) opj_destroy_codec(l_codec);
        
        /* free image data */
        if (image) opj_image_destroy(image);
        
        *compressedDataSize = 0;
        
        
        return NULL;
    }
    
    
#ifdef OPJ_VERBOSE
    opj_set_info_handler(l_codec, info_callback, this);
    opj_set_warning_handler(l_codec, warning_callback, this);
#endif
    
    opj_set_error_handler(l_codec, error_callback, this);
    
    if ( !opj_setup_encoder(l_codec, &parameters, image))
    {
        fprintf(stderr,"%s:%d:\n\topj_setup_encoder failed\n",__FILE__,__LINE__);
        
        /* close and free the byte stream */
        if (l_stream) opj_stream_destroy(l_stream);
        
        /* free remaining compression structures */
        if (l_codec) opj_destroy_codec(l_codec);
        
        /* free image data */
        if (image) opj_image_destroy(image);
        
        *compressedDataSize = 0;
        
        return NULL;
    }
    
    
    // Create the stream
#ifdef WITH_OPJ_BUFFER_STREAM
    opj_buffer_info_t bufferInfo;
    bufferInfo.cur = bufferInfo.buf = (OPJ_BYTE *)data;
    bufferInfo.len = (OPJ_SIZE_T) rows * columns;
    l_stream = opj_stream_create_buffer_stream(&bufferInfo, OPJ_STREAM_WRITE);
    
    //printf("%p\n",bufferInfo.buf);
    //printf("%lu\n",bufferInfo.len);
#endif
    
    
#ifdef WITH_OPJ_FILE_STREAM
    l_stream = opj_stream_create_default_file_stream(parameters.outfile, OPJ_STREAM_WRITE);
#endif
    
    
    if (!l_stream)
    {
        fprintf(stderr,"%s:%d:\n\tstream creation failed\n",__FILE__,__LINE__);
        
        /* close and free the byte stream */
        if (l_stream) opj_stream_destroy(l_stream);
        
        /* free remaining compression structures */
        if (l_codec) opj_destroy_codec(l_codec);
        
        /* free image data */
        if (image) opj_image_destroy(image);
        
        *compressedDataSize = 0;
        
        
        return NULL;
    }
    
    
    while(1)
    {
        //        int tile_index=-1, user_changed_tile=0, user_changed_reduction=0;
        //        int max_tiles=0, max_reduction=0;
        fails = OPJ_TRUE;
        
        /* encode the image */
        bSuccess = opj_start_compress(l_codec, image, l_stream);
        
        if (!bSuccess)
        {
            fprintf(stderr,"%s:%d:\n\topj_start_compress failed\n",__FILE__,__LINE__);
            break;
        }
        
        if ( bSuccess && bUseTiles )
        {
            OPJ_BYTE *l_data = NULL;
            OPJ_UINT32 l_data_size = 512*512*3; //FIXME
            l_data = (OPJ_BYTE*) malloc(l_data_size * sizeof(OPJ_BYTE));
            memset(l_data, 0, l_data_size * sizeof(OPJ_BYTE));
            
            //assert( l_data );
            if (!l_data)
            {
                /* close and free the byte stream */
                if (l_stream) opj_stream_destroy(l_stream);
                
                /* free remaining compression structures */
                if (l_codec) opj_destroy_codec(l_codec);
                
                /* free image data */
                if (image) opj_image_destroy(image);
                
                *compressedDataSize = 0;
                
                
                return NULL;
            }
            
            for (int i=0;i<l_nb_tiles;++i)
            {
                if (! opj_write_tile(l_codec,i,l_data,l_data_size,l_stream))
                {
                    fprintf(stderr, "\nERROR -> test_tile_encoder: failed to write the tile %d!\n",i);
                    /* close and free the byte stream */
                    if (l_stream) opj_stream_destroy(l_stream);
                    
                    /* free remaining compression structures */
                    if (l_codec) opj_destroy_codec(l_codec);
                    
                    /* free image data */
                    if (image) opj_image_destroy(image);
                    
                    free(l_data);
                    
                    *compressedDataSize = 0;
                    
                    
                    return NULL;
                }
            }
            
            free(l_data);
        }
        else
        {
            if (!opj_encode(l_codec, l_stream))
            {
                fprintf(stderr,"%s:%d:\n\topj_encode failed\n",__FILE__,__LINE__);
                break;
            }
        }
        
        if (!opj_end_compress(l_codec, l_stream))
        {
            fprintf(stderr,"%s:%d:\n\topj_end_compress failed\n",__FILE__,__LINE__);
            break;
        }
        
        fails = OPJ_FALSE;
        break;
        
    } // while
    
    *compressedDataSize = 0;
    unsigned char *to = NULL;
    
    /* close and free the byte stream */
    if (l_stream) opj_stream_destroy(l_stream);
    
    /* free remaining compression structures */
    if (l_codec) opj_destroy_codec(l_codec);
    
    /* free image data */
    if (image) opj_image_destroy(image);
    
    if (fails)
    {
#ifdef WITH_OPJ_FILE_STREAM
        if (parameters.outfile[0] != '\0')
        remove(parameters.outfile);
#endif
    }
    else
    {
#ifdef WITH_OPJ_BUFFER_STREAM
        //printf("%p\n",bufferInfo.buf);
        //printf("%lu\n",bufferInfo.len);
        //to=(unsigned char *) malloc(bufferInfo.len);
        //memcpy(to,l_stream,bufferInfo.len);
#endif
        
#ifdef WITH_OPJ_FILE_STREAM
        // Open the temp file and get the encoded data into 'to'
        // and the length into 'length'
        FILE *f = NULL;
        if (parameters.outfile[0] != '\0')
        {
            f = fopen(parameters.outfile, "rb");
        }
        
        long length = 0;
        
        if (f != NULL)
        {
            fseek(f, 0, SEEK_END);
            length = ftell(f);
            fseek(f, 0, SEEK_SET);
            if (forceJ2K)
            {
                length -= 85;
                fseek(f, 85, SEEK_SET);
            }
            
            if (length % 2)
            {
                length++; // ensure even length
                //fprintf(stdout,"Padded to %li\n", length);
            }
            
            to = (unsigned char *) malloc(length);
            
            fread(to, length, 1, f);
            
            //printf("%s %lu\n",parameters.outfile,length);;
            
            fclose(f);
        }
        
        *compressedDataSize = length;
        
        if (parameters.outfile[0] != '\0')
        {
            remove(parameters.outfile);
        }
#endif
    }
    return to;
}

