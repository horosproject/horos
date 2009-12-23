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
