//
//  dcmqrdbq.m
//  OsiriX
//
//  Created by Lance Pysher on 3/19/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

BEGIN_EXTERN_C
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
END_EXTERN_C

#define INCLUDE_CCTYPE
#define INCLUDE_CSTDARG
#include "ofstdinc.h"

#include "dcmqrdbs.h"
// #include "dcmqrdbi.h"
#include "dcmqrcnf.h"

#include "dcmqridx.h"
#include "diutil.h"
#include "dcfilefo.h"
#include "ofstd.h"


#import "dcmqrdbq.h"





