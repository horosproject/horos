/*
 *
 *  Copyright (C) 1994-2005, OFFIS
 *
 *  This software and supporting documentation were developed by
 *
 *    Kuratorium OFFIS e.V.
 *    Healthcare Information and Communication Systems
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *  THIS SOFTWARE IS MADE AVAILABLE,  AS IS,  AND OFFIS MAKES NO  WARRANTY
 *  REGARDING  THE  SOFTWARE,  ITS  PERFORMANCE,  ITS  MERCHANTABILITY  OR
 *  FITNESS FOR ANY PARTICULAR USE, FREEDOM FROM ANY COMPUTER DISEASES  OR
 *  ITS CONFORMITY TO ANY SPECIFICATION. THE ENTIRE RISK AS TO QUALITY AND
 *  PERFORMANCE OF THE SOFTWARE IS WITH THE USER.
 *
 *  Module:  dcmnet
 *
 *  Author:  Andrew Hewett
 *
 *  Purpose: Verification Service Class User (C-ECHO operation)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 21:01:06 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/DCMTKVerifySCU.mm,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */
 
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
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#include "DCMTKVerifySCU.h"
#include "osconfig.h"    /* make sure OS specific configuration is included first */

#define INCLUDE_CSTDLIB
#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#define INCLUDE_CSTDARG
#include "ofstdinc.h"

#include "dimse.h"
#include "diutil.h"
#include "dcfilefo.h"
#include "dcdebug.h"
#include "dcdict.h"
#include "dcuid.h"
#include "cmdlnarg.h"
#include "ofconapp.h"
//#include "dcuid.h"    /* for dcmtk version name */

#ifdef WITH_OPENSSL
#include "tlstrans.h"
#include "tlslayer.h"
#endif

#ifdef WITH_ZLIB
#include <zlib.h>     /* for zlibVersion() */
#endif



static void errmsg(const char *msg)
{
  if (msg) fprintf(stderr, "%s: %s\n", "echoscu", msg);
}


static OFCondition cecho(T_ASC_Association * assoc, unsigned long num_repeat);

/* DICOM standard transfer syntaxes */
static const char* transferSyntaxes[] = {
      UID_LittleEndianImplicitTransferSyntax, /* default xfer syntax first */
      UID_LittleEndianExplicitTransferSyntax,
      UID_BigEndianExplicitTransferSyntax,
      UID_JPEGProcess1TransferSyntax,
      UID_JPEGProcess2_4TransferSyntax,
      UID_JPEGProcess3_5TransferSyntax,
      UID_JPEGProcess6_8TransferSyntax,
      UID_JPEGProcess7_9TransferSyntax,
      UID_JPEGProcess10_12TransferSyntax,
      UID_JPEGProcess11_13TransferSyntax,
      UID_JPEGProcess14TransferSyntax,
      UID_JPEGProcess15TransferSyntax,
      UID_JPEGProcess16_18TransferSyntax,
      UID_JPEGProcess17_19TransferSyntax,
      UID_JPEGProcess20_22TransferSyntax,
      UID_JPEGProcess21_23TransferSyntax,
      UID_JPEGProcess24_26TransferSyntax,
      UID_JPEGProcess25_27TransferSyntax,
      UID_JPEGProcess28TransferSyntax,
      UID_JPEGProcess29TransferSyntax,
      UID_JPEGProcess14SV1TransferSyntax,
      UID_RLELosslessTransferSyntax,
      UID_JPEGLSLosslessTransferSyntax,
      UID_JPEGLSLossyTransferSyntax,
      UID_DeflatedExplicitVRLittleEndianTransferSyntax,
      UID_JPEG2000LosslessOnlyTransferSyntax,
      UID_JPEG2000TransferSyntax,
      UID_MPEG2MainProfileAtMainLevelTransferSyntax,
      UID_JPEG2000Part2MulticomponentImageCompressionLosslessOnlyTransferSyntax,
      UID_JPEG2000Part2MulticomponentImageCompressionTransferSyntax
};


@implementation DCMTKVerifySCU

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters{
			
	if (self = [super initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters]){
			
		_acse_timeout = _dimse_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];
	}
	return self;
}
		
			


- (BOOL)echo{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL connection_Status = NO;
	OFCondition cond;
	const char *opt_peer = NULL;
    OFCmdUnsignedInt opt_port = 104;
    const char *opt_peerTitle;
    const char *opt_ourTitle;
	
	if (_callingAET)
		opt_ourTitle = [_callingAET UTF8String];
		
	if (_calledAET)
		opt_peerTitle = [_calledAET UTF8String];
		
    T_ASC_Network *net = NULL;
    T_ASC_Parameters *params;
    DIC_NODENAME localHost;
    DIC_NODENAME peerHost;
    T_ASC_Association *assoc = NULL;
   
//	NSLog(@"hostname: %@ calledAET %@", _hostname, _calledAET);

	opt_peer = [_hostname UTF8String];
	opt_port = _port;
	
//	//verbose option set to true for now
//	_verbose=OFTrue;
//
//	
//	//debug code activated for now
//	_debug = OFTrue;
//	DUL_Debug(OFTrue);
//	DIMSE_debug(OFFalse);
//	SetDebugLevel(3);
	
	//Use Little Endian TS
	_networkTransferSyntax = EXS_LittleEndianExplicit;
	
	
	NS_DURING
	
#ifdef WITH_OPENSSL

	//disable TLS
	_secureConnection = OFFalse;
	
	//enable TLS
	//        _secureConnection = OFTrue;
	//_doAuthenticate = OFTrue;
	//app.checkValue(cmd.getValue(opt_privateKeyFile));
	//app.checkValue(cmd.getValue(opt_certificateFile));
	
	//anonymous-tls
	// _secureConnection = OFTrue;
	
	//Password
	//opt_passwd
	
	//pem-keys 
	//_keyFileFormat = SSL_FILETYPE_PEM;
	
	/*
	 if (cmd.findOption("--dhparam"))
      {
        app.checkValue(cmd.getValue(_dhparam));
      }

      if (cmd.findOption("--seed"))
      {
        app.checkValue(cmd.getValue(_readSeedFile));
      }

      cmd.beginOptionBlock();
      if (cmd.findOption("--write-seed"))
      {
        if (_readSeedFile == NULL) app.printError("--write-seed only with --seed");
        _writeSeedFile = _readSeedFile;
      }
      if (cmd.findOption("--write-seed-file"))
      {
        if (_readSeedFile == NULL) app.printError("--write-seed-file only with --seed");
        app.checkValue(cmd.getValue(_writeSeedFile));
      }
      cmd.endOptionBlock();

      cmd.beginOptionBlock();
      if (cmd.findOption("--require-peer-cert")) _certVerification = DCV_requireCertificate;
      if (cmd.findOption("--verify-peer-cert"))  _certVerification = DCV_checkCertificate;
      if (cmd.findOption("--ignore-peer-cert"))  _certVerification = DCV_ignoreCertificate;
      cmd.endOptionBlock();

      const char *current = NULL;
      const char *currentOpenSSL;
      if (cmd.findOption("--cipher", 0, OFCommandLine::FOM_First))
      {
        opt_ciphersuites.clear();
        do
        {
          app.checkValue(cmd.getValue(current));
          if (NULL == (currentOpenSSL = DcmTLSTransportLayer::findOpenSSLCipherSuiteName(current)))
          {
            CERR << "ciphersuite '" << current << "' is unknown. Known ciphersuites are:" << endl;
            unsigned long numSuites = DcmTLSTransportLayer::getNumberOfCipherSuites();
            for (unsigned long cs=0; cs < numSuites; cs++)
            {
              CERR << "    " << DcmTLSTransportLayer::getTLSCipherSuiteName(cs) << endl;
            }
            return 1;
          } else {
            if (opt_ciphersuites.length() > 0) opt_ciphersuites += ":";
            opt_ciphersuites += currentOpenSSL;
          }
        } while (cmd.findOption("--cipher", 0, OFCommandLine::FOM_Next));
      }
	*/
#endif

    /* make sure data dictionary is loaded */
    if (!dcmDataDict.isDictionaryLoaded()) {
        fprintf(stderr, "Warning: no data dictionary loaded, check environment variable: %s\n",
                DCM_DICT_ENVIRONMENT_VARIABLE);
    }
	
	/* initialize network, i.e. create an instance of T_ASC_Network*. */
    cond = ASC_initializeNetwork(NET_REQUESTOR, 0, _acse_timeout, &net);
    if (cond.bad()) {
        DimseCondition::dump(cond);
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"ASC_initializeNetwork %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
		[verifyException raise];
        //return;
    }
	
#ifdef WITH_OPENSSL

    DcmTLSTransportLayer *tLayer = NULL;
    if (_secureConnection)
    {
	}

#endif

/* initialize asscociation parameters, i.e. create an instance of T_ASC_Parameters*. */
    cond = ASC_createAssociationParameters(&params, _maxReceivePDULength);
	DimseCondition::dump(cond);
    if (cond.bad()) {
        DimseCondition::dump(cond);
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"ASC_createAssociationParameters %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
		[verifyException raise];
		//return;
    }
	
	/* sets this application's title and the called application's title in the params */
	/* structure. The default values to be set here are "verifyscu" and "ANY-SCP". */
	ASC_setAPTitles(params, opt_ourTitle, opt_peerTitle, NULL);

	/* Set the transport layer type (type of network connection) in the params */
	/* strucutre. The default is an insecure connection; where OpenSSL is  */
	/* available the user is able to request an encrypted,secure connection. */
	cond = ASC_setTransportLayerType(params, _secureConnection);
	if (cond.bad()) {
		DimseCondition::dump(cond);
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (findscu)" reason:[NSString stringWithFormat: @"ASC_setTransportLayerType %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
		[verifyException raise];
		//return;
	}
	
	/* Figure out the presentation addresses and copy the */
	/* corresponding values into the association parameters.*/
	gethostname(localHost, sizeof(localHost) - 1);
	sprintf(peerHost, "%s:%d", opt_peer, (int)opt_port);
	//NSLog(@"peer host: %s", peerHost);
	ASC_setPresentationAddresses(params, localHost, peerHost);
	
	/* Set the presentation contexts which will be negotiated */
    /* when the network connection will be established */
	/*
	abstract syntax should be 
	UID_MOVEStudyRootQueryRetrieveInformationModel
					or 
	UID_FINDStudyRootQueryRetrieveInformationModel
	*/
	cond = [self addPresentationContext:params abstractSyntax:UID_VerificationSOPClass];
    
    if (cond.bad()) {
        DimseCondition::dump(cond);
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (findscu)" reason:[NSString stringWithFormat: @"addPresentationContext %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
        [verifyException raise];
    }

    /* dump presentation contexts if required */
    if (_debug) {
        printf("Request Parameters:\n");
        ASC_dumpParameters(params, COUT);
    }
	
	    /* create association, i.e. try to establish a network connection to another */
    /* DICOM application. This call creates an instance of T_ASC_Association*. */
	if (!cond.bad()) {
		if (_verbose)
			printf("Requesting Association\n");
		cond = ASC_requestAssociation(net, params, &assoc);
		if (cond.bad()) {
			if (cond == DUL_ASSOCIATIONREJECTED)
			{
				T_ASC_RejectParameters rej;

				ASC_getRejectParameters(params, &rej);
				errmsg("Association Rejected:");
				ASC_printRejectParameters(stderr, &rej);
				verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"Association Rejected %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
				[verifyException raise];
			} else {
				errmsg("Association Request Failed:");
				DimseCondition::dump(cond);
				verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"Association Request Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
				[verifyException raise];
			}
		}
	}

    /* dump the presentation contexts which have been accepted/refused */
    if (_debug) {
        printf("Association Parameters Negotiated:\n");
        ASC_dumpParameters(params, COUT);
    }
	
			/* count the presentation contexts which have been accepted by the SCP */
	/* If there are none, finish the execution */
	if (ASC_countAcceptedPresentationContexts(params) == 0) {
		errmsg("No Acceptable Presentation Contexts");
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (qrscu)" reason:@"No acceptable presentation contexts" userInfo:nil];
		[verifyException raise];
		//return;
	}
	
	    /* dump general information concerning the establishment of the network connection if required */
    if (_verbose) {
        printf("Association Accepted (Max Send PDV: %u)\n",
                assoc->sendPDVLength);
    }
	
	 /* do the real work, i.e. send a number of C-ECHO-RQ messages to the DICOM application */
    /* this application is connected with and handle corresponding C-ECHO-RSP messages. */
	if (!cond.bad()) 
		cond = [self cecho: assoc repeat:1];
		//cond = cecho(assoc, 1);

		/* tear down association, i.e. terminate network connection to SCP */
    if (cond == EC_Normal)
    {
		connection_Status = YES;
        if (_abortAssociation) {
            if (_verbose)
                printf("Aborting Association\n");
            cond = ASC_abortAssociation(assoc);
            if (cond.bad()) {
                errmsg("Association Abort Failed:");
                DimseCondition::dump(cond);
                verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"Association Abort Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
				[verifyException raise];
            }
        } else {
            /* release association */
            if (_verbose)
                printf("Releasing Association\n");
            cond = ASC_releaseAssociation(assoc);
            if (cond.bad())
            {
                errmsg("Association Release Failed:");
                DimseCondition::dump(cond);
                verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"Association Release Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
				[verifyException raise];
            }
        }
    }
    else if (cond == DUL_PEERREQUESTEDRELEASE)
    {
        errmsg("Protocol Error: peer requested release (Aborting)");
        if (_verbose)
            printf("Aborting Association\n");
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"Protocol Error: peer requested release (Aborting) %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
        cond = ASC_abortAssociation(assoc);
        if (cond.bad()) {
            errmsg("Association Abort Failed:");
            DimseCondition::dump(cond);
        }
		[verifyException raise];
    }
    else if (cond == DUL_PEERABORTEDASSOCIATION)
    {
        if (_verbose) printf("Peer Aborted Association\n");
    }
    else
    {
        errmsg("SCU Failed:");
        DimseCondition::dump(cond);
        if (_verbose)
            printf("Aborting Association\n");
		verifyException = [NSException exceptionWithName:@"DICOM Network Failure (verifyscu)" reason:[NSString stringWithFormat: @"SCU Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil];
        cond = ASC_abortAssociation(assoc);
        if (cond.bad()) {
            errmsg("Association Abort Failed:");
            DimseCondition::dump(cond);
        }
		[verifyException raise];
    }
	
	NS_HANDLER
	NSLog(@"Verify SCU Exception: %@", [verifyException description]);
	NS_ENDHANDLER
	


// CLEANUP

    /* destroy the association, i.e. free memory of T_ASC_Association* structure. This */
    /* call is the counterpart of ASC_requestAssociation(...) which was called above. */
    cond = ASC_destroyAssociation(&assoc);
    if (cond.bad()) {
        DimseCondition::dump(cond);  
    
    }
	
    /* drop the network, i.e. free memory of T_ASC_Network* structure. This call */
    /* is the counterpart of ASC_initializeNetwork(...) which was called above. */
    cond = ASC_dropNetwork(&net);
    if (cond.bad()) {
        DimseCondition::dump(cond);

    }
	

#ifdef WITH_OPENSSL
/*
    if (tLayer && opt_writeSeedFile)
    {
      if (tLayer->canWriteRandomSeed())
      {
        if (!tLayer->writeRandomSeed(opt_writeSeedFile))
        {
          CERR << "Error while writing random seed file '" << opt_writeSeedFile << "', ignoring." << endl;
        }
      } else {
        CERR << "Warning: cannot write random seed, ignoring." << endl;
      }
    }
    delete tLayer;
*/
#endif



//#ifdef DEBUG
//    dcmDataDict.clear();  /* useful for debugging with dmalloc */
//#endif
 
	[pool release];
	return connection_Status;
}

-(OFCondition)cecho:(T_ASC_Association *) assoc repeat:(int) num_repeat
    /*
     * This function will send num_repeat C-ECHO-RQ messages to the DICOM application
     * this application is connected with and handle corresponding C-ECHO-RSP messages.
     *
     * Parameters:
     *   assoc      - [in] The association (network connection to another DICOM application).
     *   num_repeat - [in] The amount of C-ECHO-RQ messages which shall be sent.
     */
{
    OFCondition cond = EC_Normal;
    unsigned long n = num_repeat;

    /* as long as no error occured and the counter does not equal 0 */
    /* send an C-ECHO-RQ and handle the response */
    while (cond == EC_Normal && n--) cond = [self echoSCU:assoc]; // compare with EC_Normal since DUL_PEERREQUESTEDRELEASE is also good()

    return cond;
}

-(OFCondition)echoSCU:(T_ASC_Association *) assoc
    /*
     * This function will send a C-ECHO-RQ over the network to another DICOM application
     * and handle the response.
     *
     * Parameters:
     *   assoc - [in] The association (network connection to another DICOM application).
     */
{
    DIC_US msgId = assoc->nextMsgID++;
    DIC_US status;
    DcmDataset *statusDetail = NULL;

    /* dump information if required */
    if (_verbose) {
        printf("Echo [%d], ", msgId);
        fflush(stdout);
    }

    /* send C-ECHO-RQ and handle response */
    OFCondition cond = DIMSE_echoUser(assoc, msgId, _blockMode, _dimse_timeout, &status, &statusDetail);

    /* depending on if a response was received, dump some information */
    if (cond.good()) {
        if (_verbose) {
            printf("Complete [Status: %s]\n",
                DU_cstoreStatusString(status));
        }
    } else {
        errmsg("Failed:");
        DimseCondition::dump(cond);
    }

    /* check for status detail information, there should never be any */
    if (statusDetail != NULL) {
        printf("  Status Detail (should never be any):\n");
        statusDetail->print(COUT);
        delete statusDetail;
    }

    /* return result value */
    return cond;
}



@end


