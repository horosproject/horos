//
//  DCMTKQueryRetrieveSCP.mm
//  OsiriX
//
//  Created by Lance Pysher on 3/16/06.

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

#import "DCMTKQueryRetrieveSCP.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#define INCLUDE_CSTDLIB
#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#define INCLUDE_CSTDARG
#define INCLUDE_CERRNO
#define INCLUDE_CTIME
#define INCLUDE_LIBC
#include "ofstdinc.h"

BEGIN_EXTERN_C
#ifdef HAVE_SYS_FILE_H
#include <sys/file.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_SYS_RESOURCE_H
#include <sys/resource.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
#ifdef HAVE_SYS_ERRNO_H
#include <sys/errno.h>
#endif
#ifdef HAVE_IO_H
#include <io.h>
#endif
#ifdef HAVE_PWD_H
#include <pwd.h>
#endif
#ifdef HAVE_GRP_H
#include <grp.h>
#endif
END_EXTERN_C

#include "dicom.h"
#include "dcmqropt.h"
#include "dimse.h"
#include "dcmqrcnf.h"
#include "dcmqrsrv.h"
#include "dcdict.h"
#include "dcdebug.h"
#include "cmdlnarg.h"
#include "ofconapp.h"
#include "dcuid.h"       /* for dcmtk version name */

//#ifdef WITH_SQL_DATABASE
#include "dcmqrdbq.h"
//#else
//#include "dcmqrdbi.h"
//#endif

#ifdef WITH_ZLIB
#include <zlib.h>        /* for zlibVersion() */
#endif

#ifndef OFFIS_CONSOLE_APPLICATION
#define OFFIS_CONSOLE_APPLICATION "dcmqrscp"
#endif

static char rcsid[] = "$dcmtk: " OFFIS_CONSOLE_APPLICATION " v"
  OFFIS_DCMTK_VERSION " " OFFIS_DCMTK_RELEASEDATE " $";

#define APPLICATIONTITLE    "DCMQRSCP"

const char *opt_configFileName = "dcmqrscp.cfg";
OFBool      opt_checkFindIdentifier = OFFalse;
OFBool      opt_checkMoveIdentifier = OFFalse;
OFCmdUnsignedInt opt_port = 0;
DcmQueryRetrieveSCP *scp;

void errmsg(const char* msg, ...)
{
    va_list args;

    fprintf(stderr, "%s: ", OFFIS_CONSOLE_APPLICATION);
    va_start(args, msg);
    vfprintf(stderr, msg, args);
    va_end(args);
    fprintf(stderr, "\n");
}


@implementation DCMTKQueryRetrieveSCP

- (id)initWithPort:(int)port aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params{
	if (self = [super init]) {
		_port = port;
		_aeTitle = [aeTitle retain];
		_params = [params retain];
		//Create a timer to cleanup scp children every  hour
		[NSTimer scheduledTimerWithTimeInterval:3600 target:self  selector:@selector(cleanup:) userInfo:nil repeats:YES];
	}
	return self;
}

- (void)dealloc{

	if (scp != NULL) {
		 scp->cleanChildren(OFTrue);  // clean up any child processes 		 
		 delete scp;
	}

	[_aeTitle release];
	[_params release];
	[super dealloc];
}

- (void)cleanup:(NSTimer *)timer{
	if (scp != NULL) 
		scp->cleanChildren(OFTrue);  // clean up any child processes 	
}

- (void)run{


	OFCondition cond = EC_Normal;
    OFCmdUnsignedInt overridePort = 0;
    OFCmdUnsignedInt overrideMaxPDU = 0;
    DcmQueryRetrieveOptions options;


	//verbose
	options.verbose_= 0;
	
	//debug
//	options.debug_ = OFTrue;
//	DUL_Debug(OFTrue);
//	DIMSE_debug(OFTrue);
//	SetDebugLevel(3);
	
	//no restrictions on moves
	options.restrictMoveToSameAE_ = OFFalse;
    options.restrictMoveToSameHost_ = OFFalse;
    options.restrictMoveToSameVendor_ = OFFalse;
	
	//only suppport Study Root fornow
	options.supportPatientRoot_ = OFFalse;
	options.supportPatientStudyOnly_ = OFFalse;
	
	options.networkTransferSyntax_     = EXS_LittleEndianExplicit;	//We are now in an Intel world and Papyrus TK doesn't support BigEndian. Antoine
	/*we will stick to the default for now for incoming syntaxes
	options.networkTransferSyntax_     = EXS_LittleEndianExplicit;
	options.networkTransferSyntax_     = EXS_BigEndianExplicit;
	options.networkTransferSyntax_     = EXS_LittleEndianImplicit;
#ifndef DISABLE_COMPRESSION_EXTENSION
	options.networkTransferSyntax_     = EXS_JPEGProcess14SV1TransferSyntax;
	options.networkTransferSyntax_     = EXS_JPEGProcess1TransferSyntax;
    options.networkTransferSyntax_     = EXS_JPEGProcess2_4TransferSyntax;
    options.networkTransferSyntax_ = EXS_JPEG2000LosslessOnly;
    options.networkTransferSyntax_ = EXS_JPEG2000;
	options.networkTransferSyntax_     = EXS_RLELossless;
#ifdef WITH_ZLIB
	options.networkTransferSyntax_ = EXS_DeflatedLittleEndianExplicit
	*/
	
	//outgoing syntaxes we should determine this by server. not globally
	options.networkTransferSyntaxOut_ = EXS_Unknown;
	/*
	options.networkTransferSyntaxOut_ = EXS_LittleEndianExplicit;
	options.networkTransferSyntaxOut_ = EXS_BigEndianExplicit;
	options.networkTransferSyntaxOut_ = EXS_JPEGProcess14SV1TransferSyntax;
	options.networkTransferSyntaxOut_ = EXS_JPEGProcess1TransferSyntax;
	options.networkTransferSyntaxOut_ = EXS_JPEGProcess2_4TransferSyntax;
	options.networkTransferSyntaxOut_ = EXS_JPEG2000LosslessOnly;
	options.networkTransferSyntaxOut_ = EXS_JPEG2000;
	options.networkTransferSyntaxOut_ = EXS_RLELossless;
#ifdef WITH_ZLIB
	options.networkTransferSyntaxOut_ = EXS_DeflatedLittleEndianExplicit;
#endif
	options.networkTransferSyntaxOut_ = EXS_LittleEndianImplicit;
*/

	//timeout
	//opt_timeout = 0;
	//dcmConnectionTimeout.set((Sint32) opt_timeout);
	
	//acse-timeout
	//opt_timeout = 0;
	//options.acse_timeout_ = OFstatic_cast(int, opt_timeout);
	
	//dimse-timeout
	// opt_timeout = 0;
	//options.dimse_timeout_ = OFstatic_cast(int, opt_timeout);
	//options.blockMode_ = DIMSE_NONBLOCKING;
	
	//maxpdu
	//overrideMaxPDU = 
	
	//correct UID padding
	//options.correctUIDPadding_ = OFTrue
	
	//enble new VR
	dcmEnableUnknownVRGeneration.set(OFTrue);
	dcmEnableUnlimitedTextVRGeneration.set(OFTrue);
	
	//fix padding
	options.bitPreserving_ = OFFalse;
	
	//write metaheader
	options.useMetaheader_ = OFTrue;
	
	//write with same syntax as it came in
	options.writeTransferSyntax_ = EXS_Unknown;
	
	//remove group lengths
	options.groupLength_ = EGL_withoutGL;
	
	//number of associations
	options.maxAssociations_ = 20;
	
	//port
	opt_port = _port;
	
	//max PDU size
	options.maxPDU_ = ASC_DEFAULTMAXPDU;
	if (overrideMaxPDU > 0) options.maxPDU_ = overrideMaxPDU;
	
	    /* make sure data dictionary is loaded */
    if (!dcmDataDict.isDictionaryLoaded()) {
    fprintf(stderr, "Warning: no data dictionary loaded, check environment variable: %s\n",
        DCM_DICT_ENVIRONMENT_VARIABLE);
		return;
    }
	
	//init the network
	cond = ASC_initializeNetwork(NET_ACCEPTORREQUESTOR, (int)opt_port, options.acse_timeout_, &options.net_);
    if (cond.bad()) {
    errmsg("Error initialising network:");
    DimseCondition::dump(cond);
        return;
    }
	
#if defined(HAVE_SETUID) && defined(HAVE_GETUID)
    /* return to normal uid so that we can't do too much damage in case
     * things go very wrong.   Only relevant if the program is setuid root,
     * and run by another user.  Running as root user may be
     * potentially disasterous if this program screws up badly.
     */
    setuid(getuid());
#endif


// Have this to avoid errors until I can get rid of it
DcmQueryRetrieveConfig config;

//#ifdef WITH_SQL_DATABASE
    // use SQL database
    DcmQueryRetrieveOsiriXDatabaseHandleFactory factory;
//#else
    // use linear index database (index.dat)
//    DcmQueryRetrieveIndexDatabaseHandleFactory factory(&config);
//#endif
	 //use if static scp rather than pointer
    //DcmQueryRetrieveSCP scp(config, options, factory);
	//scp.setDatabaseFlags(opt_checkFindIdentifier, opt_checkMoveIdentifier, options.debug_);
   scp = new DcmQueryRetrieveSCP(config, options, factory);
   scp->setDatabaseFlags(opt_checkFindIdentifier, opt_checkMoveIdentifier, options.debug_);
    
	
	//Start Bonjour 
	NSNetService *netService = [[NSNetService  alloc] initWithDomain:@"" type:@"_dicom._tcp." name:_aeTitle port:_port];
	[netService setDelegate:nil];
	[netService publish];
	
	_abort = NO;
	
    /* loop waiting for associations */
    while (cond.good() && !_abort)
    {
      cond = scp->waitForAssociation(options.net_);
	  scp->cleanChildren(OFTrue);  /* clean up any child processes  This needs to be here*/
	}
	
	delete scp;
	scp = NULL;
	
	//stop bonjour
	[netService stop];
	[netService release];
	
	cond = ASC_dropNetwork(&options.net_);
    if (cond.bad()) {
        errmsg("Error dropping network:");
        DimseCondition::dump(cond);
    }
	
	return;
}
-(void)abort
{
	_abort = YES;
}

@end
