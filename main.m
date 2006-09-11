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


#import <Cocoa/Cocoa.h>
#import "Papyrus3/Papyrus3.h"
#import "NSFont_OpenGL.h"

#include "QuickTime/QuickTime.h"

#include "FVTiff.h"

int main(int argc, const char *argv[])
{
	#if !__LP64__
    EnterMovies();
    #endif
	
    Papy3Init();
    FVTIFFInitialize();
	
	static char rev[] = "$Revision$"; 
	printf( "Revision of this file is %s.\n", rev );
	
    return NSApplicationMain(argc, argv);
}
