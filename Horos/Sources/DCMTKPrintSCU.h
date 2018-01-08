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

#import <Cocoa/Cocoa.h>
#import "DCMTKServiceClassUser.h"

#undef verify

#include "osconfig.h" 
#include "ofstdinc.h"
#include "dviface.h"
#include "dvpssp.h"

/** \brief DCMTK based PrintSCU Not in use */
@interface DCMTKPrintSCU : DCMTKServiceClassUser {

    const char *              _printerID;             /* printer ID */
    const char *              _cfgName;               /* config read file name */
    DVPSFilmOrientation       _filmorientation;
    DVPSTrimMode              _trim;
    DVPSDecimateCropBehaviour _decimate;
    unsigned int          _columns;
    unsigned int          _rows;
    unsigned int          _copies;
    unsigned int          _ovl_graylevel;
    const char *              _filmsize;
    const char *              _magnification;
    const char *              _smoothing;
    const char *              _configuration;
    const char *              _img_polarity;
    const char *              _img_request_size;
    const char *              _img_magnification;
    const char *              _img_smoothing;
    const char *              _img_configuration;
    const char *              _resolution;
    const char *              _border;
    const char *              _emptyimage;
    const char *              _maxdensity;
    const char *              _mindensity;
    const char *              _plutname;
    NSArray*				  _filenames;
    int                       _LUTshape; // 0=use SCP default, 1=IDENTITY, 2=LIN OD.
    OFBool                    _inverse_plut;
    OFBool                    _spool;
    const char *              _mediumtype;
    const char *              _destination;
    const char *              _sessionlabel;
    const char *              _priority;
    const char *              _ownerID;

    OFBool                    _annotation;
    OFBool                    _annotationDatetime;
    OFBool                    _annotationPrinter;
    OFBool                    _annotationIllumination;
    const char *              _annotationString;

    unsigned int          _illumination;
    unsigned int          _reflection;

}

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			extraParameters:(NSDictionary *)extraParameters;

@end
