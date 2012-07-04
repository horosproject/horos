/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



/********** 
Super Class for SCU classes such as verifySCU, storeSCU, moveSCU, findSCU
**********/

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
#undef verify
#include "osconfig.h" /* make sure OS specific configuration is included first */
#include "dcdatset.h"
#include "dimse.h"
#include "dccodec.h"

#else

typedef int E_TransferSyntax;
typedef int T_DIMSE_BlockingMode;
typedef char* OFCondition;
typedef char* T_ASC_Parameters;
typedef char* DcmDataset;
typedef char* T_ASC_Association;
typedef char* T_ASC_Network;

#endif

/** \brief  Base Class for SCU classes such as verifySCU, storeSCU, moveSCU, findSCU 
*
* SCU classes are usually outgoing connections
* based on DCMTK 
*/

#import "DICOMTLS.h"
#import "DDKeychain.h"

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
	int  _keyFileFormat;
	NSArray *_cipherSuites;
	const char *_readSeedFile;
	const char *_writeSeedFile;
	TLSCertificateVerificationType certVerification;
	const char *_dhparam;
}

@property BOOL _abortAssociation;
@property (readonly) NSString *_hostname;
@property int _port;

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
