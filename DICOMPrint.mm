/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import <Foundation/Foundation.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMTransferSyntax.h>
#import <OsiriX/DCMTransferSyntax.h>

#include "AYDcmPrintSCU.h"

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	int status = -1;
	
	//	argv[ 1] : logPath
	//	argv[ 2] : baseName
	//	argv[ 3] : xmlPath
	
	NSLog(@"DICOM Print Process Start");
	
	if( argv[ 1] && argv[ 2] && argv[ 3])
	{
		// send printjob
		AYDcmPrintSCU printSCU = AYDcmPrintSCU( argv[ 1], 0, argv[ 2]);
		
		status = printSCU.sendPrintjob( argv[ 3]);
	}

	NSLog(@"DICOM Print Process End");
	
	[pool release];
	
	return status;
}
