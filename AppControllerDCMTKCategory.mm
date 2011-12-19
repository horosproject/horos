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

#import "AppControllerDCMTKCategory.h"

#undef verify

#include "osconfig.h"
#include "djdecode.h"  /* for dcmjpeg decoders */
#include "djencode.h"  /* for dcmjpeg encoders */
#include "dcrledrg.h"  /* for DcmRLEDecoderRegistration */
#include "dcrleerg.h"  /* for DcmRLEEncoderRegistration */

#include "Binaries/dcmtk-source/dcmjpls/djdecode.h" //JPEG-LS
#include "Binaries/dcmtk-source/dcmjpls/djencode.h" //JPEG-LS

@implementation AppController (AppControllerDCMTKCategory)

- (void)initDCMTK
{
	#ifndef OSIRIX_LIGHT
    // register global JPEG decompression codecs
    DJDecoderRegistration::registerCodecs();
    DJLSDecoderRegistration::registerCodecs();
    
    // register global JPEG compression codecs
    DJEncoderRegistration::registerCodecs(
	 	ECC_lossyRGB,
		EUC_never,
		OFFalse,
		OFFalse,
		0,
		0,
		0,
		OFTrue,
		ESS_444,
		OFFalse,
		OFFalse,
		0,
		0,
		0.0,
		0.0,
		0,
		0,
		0,
		0,
		OFTrue,
		OFTrue,
		OFFalse,
		OFFalse,
		OFTrue);
    
    DJLSEncoderRegistration::registerCodecs();
    
    // register RLE compression codec
    DcmRLEEncoderRegistration::registerCodecs();

    // register RLE decompression codec
    DcmRLEDecoderRegistration::registerCodecs();
	#endif
}
- (void)destroyDCMTK
{
	#ifndef OSIRIX_LIGHT
    // deregister JPEG codecs
    DJDecoderRegistration::cleanup();
    DJEncoderRegistration::cleanup();

    // deregister RLE codecs
    DcmRLEDecoderRegistration::cleanup();
    DcmRLEEncoderRegistration::cleanup();
	#endif
}

@end
