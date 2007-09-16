//
//  DCMPDataPDU.h
//  OsiriX
//
//  Created by Lance Pysher on 12/12/04.
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

@interface DCMPDataPDU : DCM_PDU {
	NSMutableArray *pdvList;
}

@property(readonly) NSArray *pdvList;

//outgoing PDU
+ (id)pDataPDUWithPDVs:(NSMutableArray *)pdvs;
//incoming PDU
+ (id)pDataPDUWithData:(NSData *)data;
- (id)initPDVs:(NSMutableArray *)pdvs;
- (id)initWithData:(NSData *)data;
- (BOOL)containsLastCommandFragment;
- (BOOL)containsLastDataFragment;
@end
