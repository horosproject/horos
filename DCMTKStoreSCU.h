/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/



#import <Cocoa/Cocoa.h>

#import "DICOMTLS.h"
#import "DDKeychain.h"

int runStoreSCU(const char *myAET, const char*peerAET, const char*hostname, int port, NSDictionary *extraParameters);

/** \brief  DICOM Send 
*
* DCMTKStoreSCU performs the DICOM send
* based on DCMTK 
*/
@interface DCMTKStoreSCU : NSObject {
	BOOL _threadStatus;
	
	NSString *_callingAET;
	NSString *_calledAET;
	int _port;
	NSString *_hostname;
	NSDictionary *_extraParameters;
	int _transferSyntax;
	float _compression;

	NSMutableArray *_filesToSend;
	int _numberOfFiles;
	int _numberSent;
	int _numberErrors;
	NSString *_patientName;
	NSString *_studyDescription; 
	id _logEntry;
	
	//TLS settings
	BOOL _secureConnection;
	BOOL _doAuthenticate;
	int  _keyFileFormat;
	NSArray *_cipherSuites;
	const char *_readSeedFile;
	const char *_writeSeedFile;
	TLSCertificateVerificationType certVerification;
	const char *_dhparam;	
}
+ (int) sendSyntaxForListenerSyntax: (int) listenerSyntax;
- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (void)run:(NSOperation*) operation;
- (void)updateLogEntry: (NSMutableDictionary*) userInfo;
@end



