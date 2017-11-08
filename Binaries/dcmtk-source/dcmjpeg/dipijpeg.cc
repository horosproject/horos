/*
 *
 *  Copyright (C) 2001-2005, OFFIS
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
 *  Author:  Joerg Riesmeier
 *
 *  Purpose: Implements JPEG interface for plugable image formats
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:43 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmjpeg/dipijpeg.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"
#include "ofconsol.h"
#include "dctypes.h"
#include "diimage.h"
#include "dipijpeg.h"

#define INCLUDE_CSETJMP
#define INCLUDE_CSTDIO
#include "ofstdinc.h"

BEGIN_EXTERN_C
#define boolean ijg_boolean
#include "jpeglib8.h"
#include "jerror8.h"
#include "jpegint8.h"
#include "jversion8.h"
#undef boolean

// disable any preprocessor magic the IJG library might be doing with the "const" keyword
#ifdef const
#undef const
#endif

// private error handler struct
struct DIEIJG8ErrorStruct
{
    // the standard IJG error handler object
    struct jpeg_error_mgr pub;
    // our jump buffer
    jmp_buf setjmp_buffer;
    // pointer to this
    const DiJPEGPlugin *instance;
};

// callback forward declarations
void DIEIJG8ErrorExit(j_common_ptr);
void DIEIJG8OutputMessage(j_common_ptr cinfo);

END_EXTERN_C


/*-------------*
 *  callbacks  *
 *-------------*/

// error handler, executes longjmp
void DIEIJG8ErrorExit(j_common_ptr cinfo)
{
  DIEIJG8ErrorStruct *myerr = (DIEIJG8ErrorStruct *)cinfo->err;
  longjmp(myerr->setjmp_buffer, 1);
}

// message handler for warning messages and the like
void DIEIJG8OutputMessage(j_common_ptr cinfo)
{
  DIEIJG8ErrorStruct *myerr = (DIEIJG8ErrorStruct *)cinfo->err;
  myerr->instance->outputMessage(cinfo);
}


/*----------------*
 *  constructors  *
 *----------------*/

DiJPEGPlugin::DiJPEGPlugin()
  : DiPluginFormat(),
    Quality(75),
    Sampling(ESS_444)
{
}


DiJPEGPlugin::~DiJPEGPlugin()
{
}


/*------------------*
 *  implementation  *
 *------------------*/

void DiJPEGPlugin::setQuality(const unsigned int quality)
{
    /* valid range: 0..100 (percent) */
    if (Quality <= 100)
        Quality = quality;
}


void DiJPEGPlugin::setSampling(const E_SubSampling sampling)
{
    Sampling = sampling;
}


void DiJPEGPlugin::outputMessage(void *arg) const
{
    jpeg_common_struct *cinfo = (jpeg_common_struct *)arg;
    if (cinfo && DicomImageClass::checkDebugLevel(DicomImageClass::DL_Warnings))
    {
        char buffer[JMSG_LENGTH_MAX];
        (*cinfo->err->format_message)(cinfo, buffer); /* Create the message */
        ofConsole.lockCerr() << buffer << endl;
        ofConsole.unlockCerr();
    }
}


int DiJPEGPlugin::write(DiImage *image,
                        FILE *stream,
                        const unsigned int frame) const
{
    int result = 0;
    if ((image != NULL) && (stream != NULL))
    {
        /* create bitmap with 8 bits per sample */
        const void *data = image->getOutputData(frame, 8 /*bits*/, 0 /*planar*/);
        if (data != NULL)
        {
            const OFBool isMono = (image->getInternalColorModel() == EPI_Monochrome1) ||
                                  (image->getInternalColorModel() == EPI_Monochrome2);

            /* taking the address of the variable prevents register allocation
             * which is needed here because otherwise longjmp might clobber
             * the content of the variable
             */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpointer-bool-conversion"
            if (& isMono) { /* nothing */ };
#pragma clang diagnostic pop

            /* code derived from "cjpeg.c" (IJG) and "djeijg8.cc" (DCMJPEG) */
            struct jpeg_compress_struct cinfo;
            struct DIEIJG8ErrorStruct jerr;
            /* Initialize the JPEG compression object with default error handling. */
            cinfo.err = jpeg_std_error(&jerr.pub);
            /* overwrite with specific error handling */
            jerr.instance = this;
            jerr.pub.error_exit = DIEIJG8ErrorExit;
            jerr.pub.output_message = DIEIJG8OutputMessage;
            if (setjmp(jerr.setjmp_buffer))
            {
                // the IJG error handler will cause the following code to be executed
                char buffer[JMSG_LENGTH_MAX];
                /* Create the message */
                (*cinfo.err->format_message)((jpeg_common_struct *)(&cinfo), buffer);
                /* Release memory */
                jpeg_destroy_compress(&cinfo);
                image->deleteOutputData();
                /* return error code */
                return 0;
            }
            jpeg_create_compress(&cinfo);
            /* Initialize JPEG parameters. */
            cinfo.image_width = image->getColumns();
            cinfo.image_height = image->getRows();
            cinfo.input_components = (isMono) ? 1 : 3;
            cinfo.in_color_space = (isMono) ? JCS_GRAYSCALE : ((image->getInternalColorModel() == EPI_YBR_Full) ? JCS_YCbCr : JCS_RGB);
            jpeg_set_defaults(&cinfo);
            cinfo.optimize_coding = TRUE;
            /* Set quantization tables for selected quality. */
            jpeg_set_quality(&cinfo, Quality, TRUE /*force_baseline*/);
            /* Specify data destination for compression */
            jpeg_stdio_dest(&cinfo, stream);
            /* initialize sampling factors */
            if (cinfo.jpeg_color_space == JCS_YCbCr)
            {
                switch(Sampling)
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
            } else {
                // JPEG color space is not YCbCr, disable subsampling.
                cinfo.comp_info[0].h_samp_factor = 1;
                cinfo.comp_info[0].v_samp_factor = 1;
            }
            // all other components are set to 1x1
            for (int sfi = 1; sfi < MAX_COMPONENTS; sfi++)
            {
                cinfo.comp_info[sfi].h_samp_factor = 1;
                cinfo.comp_info[sfi].v_samp_factor = 1;
            }
            /* Start compressor */
            jpeg_start_compress(&cinfo, TRUE);
            /* Process data */
            JSAMPROW row_pointer[1];
            Uint8 *image_buffer = (Uint8 *)data;
            const unsigned int row_stride = cinfo.image_width * cinfo.input_components;
            while (cinfo.next_scanline < cinfo.image_height)
            {
                row_pointer[0] = &image_buffer[cinfo.next_scanline * row_stride];
                (void)jpeg_write_scanlines(&cinfo, row_pointer, 1);
            }
            /* Finish compression and release memory */
            jpeg_finish_compress(&cinfo);
            jpeg_destroy_compress(&cinfo);
            /* All done. */
            result = 1;
        }
        /* delete pixel data */
        image->deleteOutputData();
    }
    return result;
}


OFString DiJPEGPlugin::getLibraryVersionString()
{
    /* create version information */
    return "IJG, Version " JVERSION " (modified)";
}


/*
 *
 * CVS/RCS Log:
 * $Log: dipijpeg.cc,v $
 * Revision 1.1  2006/03/01 20:15:43  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.9  2005/12/08 15:43:25  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.8  2004/02/06 11:20:59  joergr
 * Distinguish more clearly between const and non-const access to pixel data.
 *
 * Revision 1.7  2003/10/13 13:25:49  meichel
 * Added workaround for name clash of typedef "boolean" in the IJG header files
 *   and the standard headers for Borland C++.
 *
 * Revision 1.6  2002/12/11 14:55:24  meichel
 * Further code correction to avoid warning on MSVC6.
 *
 * Revision 1.5  2002/12/11 13:37:14  meichel
 * Minor code correction fixing a warning re setjmp and variable
 *   register allocation issued by gcc 3.2 -Wuninitialized
 *
 * Revision 1.4  2002/11/27 15:39:59  meichel
 * Adapted module dcmjpeg to use of new header file ofstdinc.h
 *
 * Revision 1.3  2002/09/19 08:35:51  joergr
 * Added static method getLibraryVersionString().
 *
 * Revision 1.2  2001/12/18 09:48:55  meichel
 * Modified configure test for "const" support of the C compiler
 *   in order to avoid a macro recursion error on Sun CC 2.0.1
 *
 * Revision 1.1  2001/11/27 18:27:19  joergr
 * Added support for plugable output formats in class DicomImage. First
 * implementation is JPEG.
 *
 *
 */
