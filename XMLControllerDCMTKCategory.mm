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

#import "XMLControllerDCMTKCategory.h"

#undef verify

#include "osconfig.h"
#include "mdfconen.h"

@implementation XMLController (XMLControllerDCMTKCategory)

-(void) modifyDicom
{
	int argc;
	char *argv[ 99];
	
    int error_count=0;
    MdfConsoleEngine engine( argc, argv,"dcmodify");
    error_count=engine.startProvidingService();
    if (error_count > 0)
	    CERR << "There were " << error_count << " error(s)" << endl;
    return ;
}

@end
