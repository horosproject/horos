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
