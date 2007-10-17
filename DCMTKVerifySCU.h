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

#import <Cocoa/Cocoa.h>
#import "DCMTKServiceClassUser.h"
#undef verify

/** \brief DICOM verify/echo */

int runEcho(const char *myAET, const char*peerAET, const char*hostname, int port, NSDictionary *extraParameters);

@interface DCMTKVerifySCU : DCMTKServiceClassUser {
	NSException *verifyException;
}

- (BOOL)echo;
-(OFCondition)cecho:(T_ASC_Association *) assoc repeat:(int) num_repeat;
-(OFCondition)echoSCU:(T_ASC_Association *) assoc;

@end
