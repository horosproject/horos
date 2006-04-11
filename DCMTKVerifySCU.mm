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
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

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

#ifdef PRIVATE_ECHOSCU_DECLARATIONS
PRIVATE_ECHOSCU_DECLARATIONS
#else
#define OFFIS_CONSOLE_APPLICATION "echoscu"
#endif

static char rcsid[] = "$dcmtk: " OFFIS_CONSOLE_APPLICATION " v"
  OFFIS_DCMTK_VERSION " " OFFIS_DCMTK_RELEASEDATE " $";

/* default application titles */
#define APPLICATIONTITLE     "ECHOSCU"
#define PEERAPPLICATIONTITLE "ANY-SCP"

static OFBool opt_verbose = OFFalse;
static OFBool opt_debug = OFFalse;
static T_DIMSE_BlockingMode opt_blockMode = DIMSE_BLOCKING;
static int opt_dimse_timeout = 0;

static void errmsg(const char *msg)
{
  if (msg) fprintf(stderr, "%s: %s\n", OFFIS_CONSOLE_APPLICATION, msg);
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

// ********************************************

#define SHORTCOL 4
#define LONGCOL 19

int
runEcho(const char *myAET, const char*peerAET, const char*hostname, int port, NSDictionary *extraParameters)
{
    const char *     opt_peer                = NULL;
    unsigned int     opt_port                = 104;
    const char *     opt_peerTitle           = PEERAPPLICATIONTITLE;
    const char *     opt_ourTitle            = APPLICATIONTITLE;
    OFCmdUnsignedInt opt_maxReceivePDULength = ASC_DEFAULTMAXPDU;
    OFCmdUnsignedInt opt_repeatCount         = 1;
    OFBool           opt_abortAssociation    = OFFalse;
    OFCmdUnsignedInt opt_numXferSyntaxes     = 1;
    OFCmdUnsignedInt opt_numPresentationCtx  = 1;
    OFCmdUnsignedInt maxXferSyntaxes         = (OFCmdUnsignedInt)(DIM_OF(transferSyntaxes));
    OFBool           opt_secureConnection    = OFFalse; /* default: no secure connection */
    int opt_acse_timeout = 30;
	int connection_Status = 1;

#ifdef WITH_OPENSSL
    int         opt_keyFileFormat = SSL_FILETYPE_PEM;
    OFBool      opt_doAuthenticate = OFFalse;
    const char *opt_privateKeyFile = NULL;
    const char *opt_certificateFile = NULL;
    const char *opt_passwd = NULL;
#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
    OFString    opt_ciphersuites(TLS1_TXT_RSA_WITH_AES_128_SHA ":" SSL3_TXT_RSA_DES_192_CBC3_SHA);
#else
    OFString    opt_ciphersuites(SSL3_TXT_RSA_DES_192_CBC3_SHA);
#endif
    const char *opt_readSeedFile = NULL;
    const char *opt_writeSeedFile = NULL;
    DcmCertificateVerification opt_certVerification = DCV_requireCertificate;
    const char *opt_dhparam = NULL;
#endif

    T_ASC_Network *net;
    T_ASC_Parameters *params;
    DIC_NODENAME localHost;
    DIC_NODENAME peerHost;
    T_ASC_Association *assoc;




      /* debug */
	  /*
	opt_verbose=OFTrue;

	opt_debug = OFTrue;
	DUL_Debug(OFTrue);
	DIMSE_debug(OFTrue);
	SetDebugLevel(5);
	*/

      if (myAET) opt_ourTitle = myAET;
      if (peerAET) opt_peerTitle = peerAET;
	  if (port) opt_port = port;
	  if (hostname) opt_peer = hostname;

      /*timeout*/
      //  OFCmdSignedInt opt_timeout = 0;
      //  app.checkValue(cmd.getValueAndCheckMin(opt_timeout, 1));
      //  dcmConnectionTimeout.set((Sint32) opt_timeout);


     /*acse-timeout */
      
     //   OFCmdSignedInt opt_timeout = 0;
     //   app.checkValue(cmd.getValueAndCheckMin(opt_timeout, 1));
     //   opt_acse_timeout = OFstatic_cast(int, opt_timeout);
      

      /*dimse-timeout */
      
     //   OFCmdSignedInt opt_timeout = 0;
     //   app.checkValue(cmd.getValueAndCheckMin(opt_timeout, 1));
     //   opt_dimse_timeout = OFstatic_cast(int, opt_timeout);
      //  opt_blockMode = DIMSE_NONBLOCKING;
      

      /*max-pdu*/ 
	  //opt_maxReceivePDULength, ASC_MINIMUMPDUSIZE, ASC_MAXIMUMPDUSIZE
	  


// #ifdef WITH_OPENSSL

#ifdef DEBUG
      /* prevent command line code from moaning that --add-cert-dir and --add-cert-file have not been checked */
#endif

      /*disable-tls*/
	   opt_secureConnection = OFFalse;
      /* enable */
      //  opt_secureConnection = OFTrue;
      //  opt_doAuthenticate = OFTrue;
      //  app.checkValue(cmd.getValue(opt_privateKeyFile));
      //  app.checkValue(cmd.getValue(opt_certificateFile));
      
      /*anonymous-tls */
       // opt_secureConnection = OFTrue;


      /*std-passwd*/
      
      //  if (! opt_doAuthenticate) app.printError("--std-passwd only with --enable-tls");
      //opt_passwd = NULL;
	  
     /*use-passwd*/
     // if (! opt_doAuthenticate) app.printError("--use-passwd only with --enable-tls");
     //   app.checkValue(cmd.getValue(opt_passwd));
    
     /*null-passwd */
      //  if (! opt_doAuthenticate) app.printError("--null-passwd only with --enable-tls");
      //  opt_passwd = "";


		/*keys and other ssl stuff 
      if (cmd.findOption("--pem-keys")) opt_keyFileFormat = SSL_FILETYPE_PEM;
      if (cmd.findOption("--der-keys")) opt_keyFileFormat = SSL_FILETYPE_ASN1;


      if (cmd.findOption("--dhparam"))
      {
        app.checkValue(cmd.getValue(opt_dhparam));
      }

      if (cmd.findOption("--seed"))
      {
        app.checkValue(cmd.getValue(opt_readSeedFile));
      }

      cmd.beginOptionBlock();
      if (cmd.findOption("--write-seed"))
      {
        if (opt_readSeedFile == NULL) app.printError("--write-seed only with --seed");
        opt_writeSeedFile = opt_readSeedFile;
      }
      if (cmd.findOption("--write-seed-file"))
      {
        if (opt_readSeedFile == NULL) app.printError("--write-seed-file only with --seed");
        app.checkValue(cmd.getValue(opt_writeSeedFile));
      }
      cmd.endOptionBlock();

      cmd.beginOptionBlock();
      if (cmd.findOption("--require-peer-cert")) opt_certVerification = DCV_requireCertificate;
      if (cmd.findOption("--verify-peer-cert"))  opt_certVerification = DCV_checkCertificate;
      if (cmd.findOption("--ignore-peer-cert"))  opt_certVerification = DCV_ignoreCertificate;
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

    /* make sure data dictionary is loaded */
    if (!dcmDataDict.isDictionaryLoaded()) {
        fprintf(stderr, "Warning: no data dictionary loaded, check environment variable: %s\n",
                DCM_DICT_ENVIRONMENT_VARIABLE);
		connection_Status = 0;
    }

    /* initialize network, i.e. create an instance of T_ASC_Network*. */
    OFCondition cond = ASC_initializeNetwork(NET_REQUESTOR, 0, opt_acse_timeout, &net);
    if (cond.bad()) {
        DimseCondition::dump(cond);
        connection_Status = 0;
    }

#ifdef WITH_OPENSSL
	/*
    DcmTLSTransportLayer *tLayer = NULL;
    if (opt_secureConnection)
    {
      tLayer = new DcmTLSTransportLayer(DICOM_APPLICATION_REQUESTOR, opt_readSeedFile);
      if (tLayer == NULL)
      {
        errmsg("unable to create TLS transport layer");
      }
		/*
      if (cmd.findOption("--add-cert-file", 0, OFCommandLine::FOM_First))
      {
        const char *current = NULL;
        do
        {
          app.checkValue(cmd.getValue(current));
          if (TCS_ok != tLayer->addTrustedCertificateFile(current, opt_keyFileFormat))
          {
            CERR << "warning unable to load certificate file '" << current << "', ignoring" << endl;
          }
        } while (cmd.findOption("--add-cert-file", 0, OFCommandLine::FOM_Next));
      }

      if (cmd.findOption("--add-cert-dir", 0, OFCommandLine::FOM_First))
      {
        const char *current = NULL;
        do
        {
          app.checkValue(cmd.getValue(current));
          if (TCS_ok != tLayer->addTrustedCertificateDir(current, opt_keyFileFormat))
          {
            CERR << "warning unable to load certificates from directory '" << current << "', ignoring" << endl;
          }
        } while (cmd.findOption("--add-cert-dir", 0, OFCommandLine::FOM_Next));
      }

      if (opt_dhparam && ! (tLayer->setTempDHParameters(opt_dhparam)))
      {
        CERR << "warning unable to load temporary DH parameter file '" << opt_dhparam << "', ignoring" << endl;
      }

      if (opt_doAuthenticate)
      {
        if (opt_passwd) tLayer->setPrivateKeyPasswd(opt_passwd);

        if (TCS_ok != tLayer->setPrivateKeyFile(opt_privateKeyFile, opt_keyFileFormat))
        {
          CERR << "unable to load private TLS key from '" << opt_privateKeyFile << "'" << endl;
          return 1;
        }
        if (TCS_ok != tLayer->setCertificateFile(opt_certificateFile, opt_keyFileFormat))
        {
          CERR << "unable to load certificate from '" << opt_certificateFile << "'" << endl;
          return 1;
        }
        if (! tLayer->checkPrivateKeyMatchesCertificate())
        {
          CERR << "private key '" << opt_privateKeyFile << "' and certificate '" << opt_certificateFile << "' do not match" << endl;
          return 1;
        }
      }

      if (TCS_ok != tLayer->setCipherSuites(opt_ciphersuites.c_str()))
      {
        CERR << "unable to set selected cipher suites" << endl;
        return 1;
      }

      tLayer->setCertificateVerification(opt_certVerification);


      cond = ASC_setTransportLayer(net, tLayer, 0);
      if (cond.bad())
      {
          DimseCondition::dump(cond);
          return 1;
      }
    }
	*/
#endif

	if (!cond.bad()) {
		/* initialize asscociation parameters, i.e. create an instance of T_ASC_Parameters*. */
		cond = ASC_createAssociationParameters(&params, opt_maxReceivePDULength);
		if (cond.bad()) {
			DimseCondition::dump(cond);
			connection_Status = 0;
		}
	}

#ifdef PRIVATE_ECHOSCU_CODE
    PRIVATE_ECHOSCU_CODE
#endif

    /* sets this application's title and the called application's title in the params */
    /* structure. The default values to be set here are "STORESCU" and "ANY-SCP". */
	if (!cond.bad()) 
		ASC_setAPTitles(params, opt_ourTitle, opt_peerTitle, NULL);

    /* Set the transport layer type (type of network connection) in the params */
    /* strucutre. The default is an insecure connection; where OpenSSL is  */
    /* available the user is able to request an encrypted,secure connection. */
	if (!cond.bad()) {
		cond = ASC_setTransportLayerType(params, opt_secureConnection);
		if (cond.bad()) {
			DimseCondition::dump(cond);
			connection_Status = 0;
		}
	}

    /* Figure out the presentation addresses and copy the */
    /* corresponding values into the association parameters.*/
	if (!cond.bad()) {
		gethostname(localHost, sizeof(localHost) - 1);
		sprintf(peerHost, "%s:%d", opt_peer, (int)opt_port);
		ASC_setPresentationAddresses(params, localHost, peerHost);
	}

    /* Set the presentation contexts which will be negotiated */
    /* when the network connection will be established */
    int presentationContextID = 1; /* odd byte value 1, 3, 5, .. 255 */
	if (!cond.bad()) {
		for (unsigned long ii=0; ii<opt_numPresentationCtx; ii++)
		{
		  cond = ASC_addPresentationContext(params, presentationContextID, UID_VerificationSOPClass,
					 transferSyntaxes, (int)opt_numXferSyntaxes);
		  presentationContextID += 2;
		  if (cond.bad())
		  {
				DimseCondition::dump(cond);
				connection_Status = 0;
		  }
		}
	}

    /* dump presentation contexts if required */
    if (opt_debug) {
        printf("Request Parameters:\n");
        ASC_dumpParameters(params, COUT);
    }

    /* create association, i.e. try to establish a network connection to another */
    /* DICOM application. This call creates an instance of T_ASC_Association*. */
	if (!cond.bad()) {
		if (opt_verbose)
			printf("Requesting Association\n");
		cond = ASC_requestAssociation(net, params, &assoc);
		if (cond.bad()) {
			if (cond == DUL_ASSOCIATIONREJECTED)
			{
				T_ASC_RejectParameters rej;

				ASC_getRejectParameters(params, &rej);
				errmsg("Association Rejected:");
				ASC_printRejectParameters(stderr, &rej);
				connection_Status = 0;
			} else {
				errmsg("Association Request Failed:");
				DimseCondition::dump(cond);
				connection_Status = 0;
			}
		}
	}

    /* dump the presentation contexts which have been accepted/refused */
    if (opt_debug) {
        printf("Association Parameters Negotiated:\n");
        ASC_dumpParameters(params, COUT);
    }

    /* count the presentation contexts which have been accepted by the SCP */
    /* If there are none, finish the execution */
	if (!cond.bad()) {
		if (ASC_countAcceptedPresentationContexts(params) == 0) {
			errmsg("No Acceptable Presentation Contexts");
			connection_Status = 0;
		}
	}

    /* dump general information concerning the establishment of the network connection if required */
    if (opt_verbose) {
        printf("Association Accepted (Max Send PDV: %lu)\n",
                assoc->sendPDVLength);
    }


    /* do the real work, i.e. send a number of C-ECHO-RQ messages to the DICOM application */
    /* this application is connected with and handle corresponding C-ECHO-RSP messages. */
	if (!cond.bad()) {
		cond = cecho(assoc, opt_repeatCount);

		/* tear down association, i.e. terminate network connection to SCP */
		if (cond == EC_Normal)
		{
			if (opt_abortAssociation) {
				if (opt_verbose)
					printf("Aborting Association\n");
				cond = ASC_abortAssociation(assoc);
				if (cond.bad())
				{
					errmsg("Association Abort Failed:");
					DimseCondition::dump(cond);
					connection_Status = 0;
				}
			} else {
				/* release association */
				if (opt_verbose)
					printf("Releasing Association\n");
				cond = ASC_releaseAssociation(assoc);
				if (cond.bad())
				{
					errmsg("Association Release Failed:");
					DimseCondition::dump(cond);
					//connection_Status = 0;
				}
			}
		}
		else if (cond == DUL_PEERREQUESTEDRELEASE)
		{
			errmsg("Protocol Error: peer requested release (Aborting)");
			if (opt_verbose)
				printf("Aborting Association\n");
			cond = ASC_abortAssociation(assoc);
			if (cond.bad()) {
				errmsg("Association Abort Failed:");
				DimseCondition::dump(cond);
				connection_Status = 0;
			}
		}
		else if (cond == DUL_PEERABORTEDASSOCIATION)
		{
			if (opt_verbose) printf("Peer Aborted Association\n");
		}
		else
		{
			errmsg("SCU Failed:");
			DimseCondition::dump(cond);
			if (opt_verbose)
				printf("Aborting Association\n");
			cond = ASC_abortAssociation(assoc);
			if (cond.bad()) {
				errmsg("Association Abort Failed:");
				DimseCondition::dump(cond);
				connection_Status = 0;
			}
		}
	}

    /* destroy the association, i.e. free memory of T_ASC_Association* structure. This */
    /* call is the counterpart of ASC_requestAssociation(...) which was called above. */
	if (!cond.bad()) {
		cond = ASC_destroyAssociation(&assoc);
		if (cond.bad()) {
			DimseCondition::dump(cond);
		   // connection_Status = 0;
		}
	}

    /* drop the network, i.e. free memory of T_ASC_Network* structure. This call */
    /* is the counterpart of ASC_initializeNetwork(...) which was called above. */
	if (!cond.bad()) {
		cond = ASC_dropNetwork(&net);
		if (cond.bad()) {
			DimseCondition::dump(cond);
		  //  connection_Status = 0;
		}
	}

#ifdef HAVE_WINSOCK_H
    WSACleanup();
#endif

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

   return !cond.bad();
	//return  connection_Status;
}

static OFCondition
echoSCU(T_ASC_Association * assoc)
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
    if (opt_verbose) {
        printf("Echo [%d], ", msgId);
        fflush(stdout);
    }

    /* send C-ECHO-RQ and handle response */
    OFCondition cond = DIMSE_echoUser(assoc, msgId, opt_blockMode, opt_dimse_timeout, &status, &statusDetail);

    /* depending on if a response was received, dump some information */
    if (cond.good()) {
        if (opt_verbose) {
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

static OFCondition
cecho(T_ASC_Association * assoc, unsigned long num_repeat)
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
    while (cond == EC_Normal && n--) cond = echoSCU(assoc); // compare with EC_Normal since DUL_PEERREQUESTEDRELEASE is also good()

    return cond;
}

@implementation DCMTKVerifySCU

@end


