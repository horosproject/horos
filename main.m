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
#import "NSFont_OpenGL.h"

#include "options.h"

#ifndef OSIRIX_LIGHT
#include "FVTiff.h"
#endif

int main(int argc, const char *argv[])
{	
	#ifndef OSIRIX_LIGHT
    FVTIFFInitialize();
	#endif
	
    return NSApplicationMain(argc, argv);
}
