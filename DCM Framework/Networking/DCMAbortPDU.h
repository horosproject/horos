//
//  DCMAbortPDU.h
//  OsiriX
//
//  Created by Lance Pysher on 11/28/04.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/


#import <Cocoa/Cocoa.h>
#import "DCM_PDU.h"


@interface DCMAbortPDU : DCM_PDU {

	unsigned char source;
	unsigned char reason;


}
 + (id)abortWithSource:(unsigned char)aSource  reason:(unsigned char)aReason;
 + (id)abortWithData:(NSData *)data;
- (id)initWithSource:(unsigned char)aSource  reason:(unsigned char)aReason;
- (id)initWithData:(NSData *)data;



@end
