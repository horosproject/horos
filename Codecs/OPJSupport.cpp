//
//  OPJSupport.cpp
//  OsiriX_Lion
//
//  Created by Aaron Boxer on 1/21/14.
//

#include "OPJSupport.h"
#include "../Binaries/openjpeg/openjpeg.h"
#include "format_defs.h"

typedef struct decode_info
{
	opj_codec_t *codec;
	opj_stream_t *stream;
	opj_image_t *image;
    opj_codestream_info_v2_t* cstr_info;
	opj_codestream_index_t* cstr_index;
	OPJ_BOOL   deleteImage;

} decode_info_t;

#define JP2_RFC3745_MAGIC "\x00\x00\x00\x0c\x6a\x50\x20\x20\x0d\x0a\x87\x0a"
#define JP2_MAGIC "\x0d\x0a\x87\x0a"
/* position 45: "\xff\x52" */
#define J2K_CODESTREAM_MAGIC "\xff\x4f\xff\x51"

// Adapted from infile_format() in /src/bin/jp2/opj_decompress.c
static int buffer_format(void * buf)
{
	int magic_format;
    
	if (memcmp(buf, JP2_RFC3745_MAGIC, 12) == 0 || memcmp(buf, JP2_MAGIC, 4) == 0) {
		magic_format = JP2_CFMT;
	}
	else if (memcmp(buf, J2K_CODESTREAM_MAGIC, 4) == 0) {
		magic_format = J2K_CFMT;
	}
	else
		return -1;
    
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
static void error_callback(const char *msg, void *client_data) {
	(void)client_data;
	fprintf(stdout, "[OPJ ERROR] %s", msg);
}
#if 0
/**
 sample warning debug callback expecting no client object
 */
static void warning_callback(const char *msg, void *client_data) {
	(void)client_data;
	fprintf(stdout, "[OPJ WARNING] %s", msg);
}
/**
 sample debug callback expecting no client object
 */
static void info_callback(const char *msg, void *client_data) {
	(void)client_data;
	fprintf(stdout, "[OPJ INFO] %s", msg);
}
#endif

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
    
    if (jp2DataSize<12)
        return 0;
    
    opj_dparameters_t parameters;
	//OPJ_BOOL hasFile = OPJ_FALSE;

	int i;
	int width, height;
	OPJ_BOOL hasAlpha, fails = OPJ_FALSE;
	OPJ_CODEC_FORMAT codec_format;
	unsigned char rc, gc, bc, ac;

	decode_info_t decodeInfo;
	memset(&decodeInfo, 0, sizeof(decode_info_t));
    
	opj_set_default_decoder_parameters(&parameters);   
	parameters.decod_format = buffer_format(jp2Data);
    
	/*-----------------------------------------------*/
    switch (parameters.decod_format) {
        case J2K_CFMT:                      /* JPEG-2000 codestream */
            codec_format = OPJ_CODEC_J2K;
            break;
            
        case JP2_CFMT:                      /* JPEG 2000 compressed image data */
            codec_format = OPJ_CODEC_JP2;
            break;
            
        case JPT_CFMT:                      /* JPEG 2000, JPIP */
            codec_format = OPJ_CODEC_JPT;
            break;
            
        case -1:
        default:
            /* clarified in infile_format() : */
            release(&decodeInfo);
            fprintf(stderr,"%s:%d: decode format missing\n",__FILE__,__LINE__);
            return 0;
            //break;
    }
    
    while(1)
    {
        int tile_index=-1, user_changed_tile=0, user_changed_reduction=0;
        int max_tiles=0, max_reduction=0;
        fails = OPJ_TRUE;
        
        // Create the stream
        decodeInfo.stream = opj_stream_create_buffer_stream((OPJ_BYTE *)jp2Data, (OPJ_SIZE_T)jp2DataSize, OPJ_STREAM_READ);

        if (decodeInfo.stream == NULL) {
            fprintf(stderr,"%s:%d:\n\tNO decodeInfo.stream\n",__FILE__,__LINE__);
            break;
        }
        
        /* see openjpeg.c:164 */
        decodeInfo.codec = opj_create_decompress(codec_format);
        if (decodeInfo.codec == NULL) {
            fprintf(stderr,"%s:%d:\n\tNO codec\n",__FILE__,__LINE__);
            break;
        }

        opj_set_error_handler(decodeInfo.codec, error_callback, this);
        
        // Setup the decoder decoding parameters
        if ( !opj_setup_decoder(decodeInfo.codec, &parameters)) {
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
        if( !opj_read_header(decodeInfo.stream, decodeInfo.codec, &(decodeInfo.image))) {
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

        if (tile_index < 0)
        {
            unsigned int x0, y0, x1, y1;
            int user_changed_area=0;

            x0 = y0 = x1 = y1 = 0;


            if(user_changed_area)
            {

            }

            if( !opj_set_decode_area(decodeInfo.codec, decodeInfo.image, x0, y0, x1, y1)) {
                fprintf(stderr,"%s:%d:\n\topj_set_decode_area failed\n",__FILE__,__LINE__);
                break;
            }

            if( !opj_decode(decodeInfo.codec, decodeInfo.stream, decodeInfo.image)) {
                fprintf(stderr,"%s:%d:\n\topj_decode failed\n",__FILE__,__LINE__);
                break;
            }
        }	/* if(tile_index < 0) */
        else
        {
// [4]
            if( !opj_get_decoded_tile(decodeInfo.codec, decodeInfo.stream, decodeInfo.image, tile_index))
            {
                fprintf(stderr,"%s:%d:\n\topj_get_decoded_tile failed\n",__FILE__,__LINE__);
                break;
            }
        }

        if( !opj_end_decompress(decodeInfo.codec, decodeInfo.stream)) {
            fprintf(stderr,"%s:%d:\n\topj_end_decompress failed\n",__FILE__,__LINE__);
            break;
        }

        fails = OPJ_FALSE;
        break;
        
    } // while

    decodeInfo.deleteImage = fails;

    if (fails)
        return 0;
    
    decodeInfo.deleteImage = OPJ_TRUE;

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

    if(decodeInfo.image->color_space == OPJ_CLRSPC_SYCC)
    {
        //disable for now
        //color_sycc_to_rgb(decodeInfo.image);
    }
    
    if (decodeInfo.image->icc_profile_buf)
    {
#if defined(HAVE_LIBLCMS1) || defined(HAVE_LIBLCMS2)
        color_apply_icc_profile(decodeInfo.image);
#endif
        decodeInfo.image->icc_profile_buf = NULL;
        decodeInfo.image->icc_profile_len = 0;
    }

    width = decodeInfo.image->comps[0].w;
    height = decodeInfo.image->comps[0].h;

    long depth = (decodeInfo.image->comps[0].prec + 7)/8;
    long decompressSize = width * height * decodeInfo.image->numcomps * depth;
    if (decompressedBufferSize)
        *decompressedBufferSize = decompressSize;;

   
    if (!inputBuffer ) {
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

        }	/* if(has_rgb) */
        else
        {
            red = green = blue = decodeInfo.image->comps[0].data;
            if(has_alpha2)
            {
            alpha = decodeInfo.image->comps[1].data;
            }
        }	/* if(has_rgb) */

        ac = 255;/* 255: FULLY_OPAQUE; 0: FULLY_TRANSPARENT */
        
        int* ptrIBody = (int*)inputBuffer;
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
            *ptrIBody++ = (int)((ac<<24) | (rc<<16) | (gc<<8) | bc);

        }	/* for(i) */
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

    return inputBuffer;
}

void* OPJSupport::compressJPEG2K( void *data, int samplesPerPixel, int rows, int columns, int precision, bool sign, int rate, long *compressedDataSize)
{
    // TODO
    return 0;
}
