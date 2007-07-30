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
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMTKServiceClassUser.h"

#include "tlstrans.h"
#include "tlslayer.h"
#include "ofstring.h"


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
		_debug = NO;
		_abortAssociation = NO;
		_maxReceivePDULength = ASC_DEFAULTMAXPDU;
		_repeatCount = -1;
		_cancelAfterNResponses = -1;
		_networkTransferSyntax = EXS_Unknown;
		_blockMode = DIMSE_BLOCKING;
		_dimse_timeout = 0;
		_acse_timeout = _dimse_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];

		//SSL
		//_keyFileFormat = SSL_FILETYPE_PEM;
		_doAuthenticate = NO;
		_privateKeyFile = NULL;
		_certificateFile = NULL;
		_passwd = NULL;
		
		_readSeedFile = NULL;
		_writeSeedFile = NULL;
		//_certVerification = DCV_requireCertificate;
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

/* does nothing . Don't call
- (void)finalize {
}
*/

- (OFCondition) addPresentationContext:(T_ASC_Parameters *)params abstractSyntax:(const char *)abstractSyntax{
   /*
    ** We prefer to use Explicitly encoded transfer syntaxes.
    ** If we are running on a Little Endian machine we prefer
    ** LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
    ** Some SCP implementations will just select the first transfer
    ** syntax they support (this is not part of the standard) so
    ** organise the proposed transfer syntaxes to take advantage
    ** of such behaviour.
    **
    ** The presentation contexts proposed here are only used for
    ** C-FIND and C-MOVE and C-ECHO, so there is no need to support compressed
    ** transmission.
    */

    const char* transferSyntaxes[] = { NULL, NULL, NULL };
    int numTransferSyntaxes = 0;

    switch (_networkTransferSyntax) {
    case EXS_LittleEndianImplicit:
        /* we only support Little Endian Implicit */
        transferSyntaxes[0]  = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 1;
        break;
    case EXS_LittleEndianExplicit:
        /* we prefer Little Endian Explicit */
        transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 3;
        break;
    case EXS_BigEndianExplicit:
        /* we prefer Big Endian Explicit */
        transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
        transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 3;
        break;
    default:
        /* We prefer explicit transfer syntaxes.
         * If we are running on a Little Endian machine we prefer
         * LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
         */
        if (gLocalByteOrder == EBO_LittleEndian)  /* defined in dcxfer.h */
        {
            transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
            transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
        } else {
            transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
            transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
        }
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 3;
        break;
    }

    return ASC_addPresentationContext(
        params, 1, abstractSyntax,
        transferSyntaxes, numTransferSyntaxes);
}

- (NSString *)calledAET{
	return _calledAET;
}

- (NSString *)callingAET{
	return _callingAET;
}

@end
