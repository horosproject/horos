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



/********** 
Super Class for SCU classes such as verifySCU, storeSCU, moveSCU, findSCU
**********/

#import <Cocoa/Cocoa.h>

#undef verify

#include "osconfig.h" /* make sure OS specific configuration is included first */
#include "dcdatset.h"
#include "dimse.h"
#include "dccodec.h"
//#include "tlstrans.h"
//#include "tlslayer.h"
//#include "ofstring.h"


/** \brief  Base Class for SCU classes such as verifySCU, storeSCU, moveSCU, findSCU 
*
* SCU classes are usually outgoing connections
* based on DCMTK 
*/

typedef enum
{
	PasswordNone = 0,
	PasswordAsk,
	PasswordString
} TLSPasswordType;

typedef enum
{
	PEM = 0,
	DER
} TLSFileFormat;

typedef enum
{
	RequirePeerCertificate = 0,
	VerifyPeerCertificate,
	IgnorePeerCertificate
} TLSCertificateVerificationType;

#define TLS_SEED_FILE "/tmp/OsiriXTLSSeed"
#define TLS_WRITE_SEED_FILE "/tmp/OsiriXTLSSeedWrite"

@interface DCMTKServiceClassUser : NSObject {
	NSString *_callingAET;
	NSString *_calledAET;
	int _port;
	NSString *_hostname;
	NSDictionary *_extraParameters;
	BOOL _shouldAbort;
	int _transferSyntax;
	float _compression;
	
	//network parameters
	BOOL _verbose;
	BOOL _debug;
	BOOL _abortAssociation;
	unsigned long _maxReceivePDULength ;
	//unsigned long _repeatCount ;
	int _repeatCount ;
	int _cancelAfterNResponses;
	E_TransferSyntax _networkTransferSyntax;
	T_DIMSE_BlockingMode    _blockMode;
	int  _dimse_timeout;
	int  _acse_timeout;
	
	//TLS settings
	BOOL _secureConnection;
	BOOL _doAuthenticate;
	NSString *_privateKeyFile;
	NSString *_certificateFile;
	TLSPasswordType passwordType;
	NSString *_passwd;
	int  _keyFileFormat;
	
	NSArray *_cipherSuites;

	BOOL _useTrustedCA;
	NSString *_trustedCAURL;
	
	const char *_readSeedFile;
	const char *_writeSeedFile;
	//DcmCertificateVerification _certVerification;
	TLSCertificateVerificationType certVerification;
	const char *_dhparam;


}

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (OFCondition) addPresentationContext:(T_ASC_Parameters *)params abstractSyntax:(const char *)abstractSyntax;
- (NSString *)calledAET;
- (NSString *)callingAET;
- (NSDictionary *) extraParameters;
@end
