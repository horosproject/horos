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



#import <Cocoa/Cocoa.h>

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

#define TLS_SEED_FILE @"/tmp/OsiriXTLSSeed"
#define TLS_WRITE_SEED_FILE "/tmp/OsiriXTLSSeedWrite"

int runStoreSCU(const char *myAET, const char*peerAET, const char*hostname, int port, NSDictionary *extraParameters);

/** \brief  DICOM Send 
*
* DCMTKStoreSCU performs the DICOM send
* based on DCMTK 
*/
@interface DCMTKStoreSCU : NSObject {
	NSString *_callingAET;
	NSString *_calledAET;
	int _port;
	NSString *_hostname;
	NSDictionary *_extraParameters;
	BOOL _shouldAbort;
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
	TLSCertificateVerificationType certVerification;
	const char *_dhparam;	
}

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (void)run:(id)sender;
- (void)updateLogEntry: (NSMutableDictionary*) userInfo;
- (void)abort;
@end



