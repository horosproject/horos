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

#import "DCMTKPrintSCU.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#define INCLUDE_CCTYPE
#include "ofstdinc.h"

#include "ofstream.h"
#include "dviface.h"
#include "dvpssp.h"
#include "dcmimage.h"
#include "cmdlnarg.h"
#include "ofcmdln.h"
#include "ofconapp.h"
#include "dcuid.h"       /* for dcmtk version name */
#include "oflist.h"
#include "dcdebug.h"


@implementation DCMTKPrintSCU

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			extraParameters:(NSDictionary *)extraParameters{
	if (self = [super initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:0
			compression: 0
			extraParameters:(NSDictionary *)extraParameters]) {
			
	_debug      = 0;           /* default: no debug */
    _verbose    = OFFalse;     /* default: do not dump presentation state */
    _printerID = NULL;             /* printer ID */
	_cfgName = NULL;               /* config read file name */
    _filmorientation = DVPSF_default;
    _trim = DVPSH_default;
	_decimate = DVPSI_default;
    _columns = 1;
    _rows = 1;
    _copies = 0;
    _ovl_graylevel = 4095;
	_filmsize = NULL;
	_magnification = NULL;
    _smoothing = NULL;
    _configuration = NULL;
    _img_polarity = NULL;
    _img_request_size = NULL;
    _img_magnification = NULL;
    _img_smoothing = NULL;
    _img_configuration = NULL;
    _resolution = NULL;
    _border = NULL;
	_emptyimage = NULL;
    _maxdensity = NULL;
    _mindensity = NULL;
    _plutname = NULL;

	_LUTshape = 0; // 0=use SCP default, 1=IDENTITY, 2=LIN OD.
	_inverse_plut = OFFalse;
    _spool = OFFalse;
    _mediumtype = NULL;
    _destination     = NULL;
	_sessionlabel    = NULL;
    _priority        = NULL;
    _ownerID         = NULL;

    _annotation = OFFalse;
    _annotationDatetime = OFTrue;
    _annotationPrinter = OFTrue;
    _annotationIllumination = OFTrue;
    _annotationString = NULL;

	_illumination = (OFCmdUnsignedInt)-1;
	_reflection = (OFCmdUnsignedInt)-1;	
	
	_filenames = [filesToSend retain];
	}
	return self;
}

- (void)dealloc {
	[_filenames release];
	[super dealloc];
}

- (void)createPrintJob{
	// turn on debug code
	_verbose=OFTrue;
     _debug = 3;
	
	// film orientation
	 _filmorientation = DVPSF_default;
	 if ([[_extraParameters objectForKey:@"Film Orientation"] isEqualToString:@"landscape"])
		_filmorientation = DVPSF_landscape;
	else if ([[_extraParameters objectForKey:@"Film Orientation"] isEqualToString:@"portrait"])
		_filmorientation = DVPSF_portrait;
	 
	// trim
	 _trim = DVPSH_default;
	 if ([[_extraParameters objectForKey:@"Trim"] boolValue] == YES )
		_trim = DVPSH_trim_on;
	else if ([_extraParameters objectForKey:@"Trim"] && [[_extraParameters objectForKey:@"Trim"] boolValue] == NO)
		_trim = DVPSH_trim_off;
		
	//decimate
	_decimate = DVPSI_default;
	if ([[_extraParameters objectForKey:@"Decimate"] isEqualToString:@"decimate"]) _decimate = DVPSI_decimate;
	if ([[_extraParameters objectForKey:@"Decimate"] isEqualToString:@"crop"])   _decimate = DVPSI_crop;
	if ([[_extraParameters objectForKey:@"Decimate"] isEqualToString:@"fail"])   _decimate = DVPSI_fail;
	
	//LUT shape
	_LUTshape = 0;
	if ([[_extraParameters objectForKey:@"LUT Shape"] isEqualToString:@"identity"]) _LUTshape = 1;
	if ([[_extraParameters objectForKey:@"LUT Shape"] isEqualToString:@"lin-od"]) _LUTshape = 2;
	
	//PLUT
	if ([_extraParameters objectForKey:@"PLUT"])
		_plutname = [[_extraParameters objectForKey:@"PLUT"] UTF8String];
	
	//Inverse PLUT	
	_inverse_plut = [[_extraParameters objectForKey:@"Inverse PLUT"] boolValue];

	 
	 
}

@end
