//
//  DCMRejecttPDU.h
//  OsiriX
//
//  Created by Lance Pysher on 11/28/04.

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
//
/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/


#import <Cocoa/Cocoa.h>
#import "DCM_PDU.h"


@interface DCMRejectPDU : DCM_PDU {

	unsigned char source;
	unsigned char reason;
	unsigned char result;
}
+ (id)rejectWithData:(NSData *)data;
+ (id)rejectWithSource:(unsigned char)aSource  reason:(unsigned char)aReason  result:(unsigned char)aResult;
- (id)initWithData:(NSData *)data;
- (id)initWithSource:(unsigned char)aSource  reason:(unsigned char)aReason  result:(unsigned char)aResult;

@end
