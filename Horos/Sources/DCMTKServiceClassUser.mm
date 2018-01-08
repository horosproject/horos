/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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


#import "DCMTKServiceClassUser.h"

#include "tlstrans.h"
#include "tlslayer.h"
#include "ofstring.h"


@implementation DCMTKServiceClassUser

@synthesize _abortAssociation, _hostname, _port;

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters
{	
	if (self = [super init])
	{
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
		_blockMode = DIMSE_BLOCKING;	//DIMSE_BLOCKING; ANR JANUARY 2009 - Move failed on HUG PACS
		
		if( [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"] <= 0)
			[[NSUserDefaults standardUserDefaults] setInteger: 20 forKey:@"DICOMTimeout"];
		
		_acse_timeout = _dimse_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];
		
		//TLS
		_secureConnection = [[extraParameters objectForKey:@"TLSEnabled"] boolValue];
		_doAuthenticate = NO;
		_cipherSuites = nil;
		_dhparam = NULL;
		
		if (_secureConnection)
		{
			_doAuthenticate = [[extraParameters objectForKey:@"TLSAuthenticated"] boolValue];
			_keyFileFormat = SSL_FILETYPE_PEM;
			certVerification = (TLSCertificateVerificationType)[[extraParameters objectForKey:@"TLSCertificateVerification"] intValue];
			
			NSArray *suites = [extraParameters objectForKey:@"TLSCipherSuites"];
			NSMutableArray *selectedCipherSuites = [NSMutableArray array];
			
			for (NSDictionary *suite in suites)
			{
				if ([[suite objectForKey:@"Supported"] boolValue])
					[selectedCipherSuites addObject:[suite objectForKey:@"Cipher"]];
			}
			
			_cipherSuites = [[NSArray arrayWithArray:selectedCipherSuites] retain];
			
			if([[extraParameters objectForKey:@"TLSUseDHParameterFileURL"] boolValue])
				_dhparam = [[extraParameters objectForKey:@"TLSDHParameterFileURL"] cStringUsingEncoding:NSUTF8StringEncoding];
			
			[DDKeychain generatePseudoRandomFileToPath:TLS_SEED_FILE];
			_readSeedFile = [TLS_SEED_FILE cStringUsingEncoding:NSUTF8StringEncoding];
			_writeSeedFile = TLS_WRITE_SEED_FILE;
		}
        
        if( numberOfDcmLongSCUStorageSOPClassUIDs > 120)
            NSLog( @"******** numberOfDcmLongSCUStorageSOPClassUIDs > 120");
        
        if( numberOfDcmShortSCUStorageSOPClassUIDs > 64)
             NSLog( @"******** numberOfDcmShortSCUStorageSOPClassUIDs > 64");
	}
	return self;
}

- (void)dealloc{
	[_callingAET release];
	[_calledAET release];
	[_hostname release];
	[_extraParameters release];
	
	// TLS
	[_cipherSuites release];
	
	[super dealloc];
}

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

- (NSDictionary*) extraParameters
{
	return _extraParameters;
}
@end
