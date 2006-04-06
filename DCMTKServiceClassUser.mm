//
//  DCMTKServiceClassUser.mm
//  OsiriX
//
//  Created by Lance Pysher on 4/5/06.

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

#import "DCMTKServiceClassUser.h"


@implementation DCMTKServiceClassUser

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters{
	
	if (self = [super init]) {
	_callingAET = [myAET retain];
		_calledAET = [theirAET retain];
		_port = port;
		_hostname = [hostname retain];
		_extraParameters = [extraParameters retain];
		_shouldAbort = NO;
		_transferSyntax = transferSyntax;
		_compression = compression;
		
		_verbose = YES;
		_debug = YES;
		_abortAssociation = NO;
		_maxReceivePDULength = ASC_DEFAULTMAXPDU;
		_repeatCount = -1;
		_cancelAfterNResponses = -1;
		_networkTransferSyntax = EXS_Unknown;
		_blockMode = DIMSE_BLOCKING;
		_dimse_timeout = 0;
		_acse_timeout = 30;
		
		//SSL
		_keyFileFormat = SSL_FILETYPE_PEM;
		_doAuthenticate = NO;
		_privateKeyFile = NULL;
		_certificateFile = NULL;
		_passwd = NULL;
		
		_readSeedFile = NULL;
		_writeSeedFile = NULL;
		_certVerification = DCV_requireCertificate;
		_dhparam = NULL;
	}
	return self;
			
	
}

- (void)dealloc{
	[_callingAET release];
	[_calledAET release];
	[_hostname release];
	[_extraParameters release];
	[_privateKeyFile release];
	[_certificateFile release];
	[_passwd release];

	[super dealloc];
}

@end
