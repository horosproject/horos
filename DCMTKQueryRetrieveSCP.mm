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

#import "DCMTKQueryRetrieveSCP.h"
#import "AppController.h"

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

- (BOOL) running
{
	return running;
}

- (int) port
{
	return _port;
}

- (NSString*) aeTitle
{
	return _aeTitle;
}

- (id)initWithPort:(int)port aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params{
	if (self = [super init]) {
		_port = port;
		_aeTitle = [aeTitle retain];
		_params = [params retain];
//		This seems to generate some problems when it happens in the middle of a store-scp... I removed it for now.
//		//Create a timer to cleanup scp children every 8 hours
//		[NSTimer scheduledTimerWithTimeInterval:3600*8 target:self  selector:@selector(cleanup:) userInfo:nil repeats:YES];
	}
	return self;
}

- (void)dealloc{

	if (scp != NULL) {
		 scp->cleanChildren(OFTrue);  // clean up any child processes 		 
		 delete scp;
		 scp = 0L;
	}

	[_aeTitle release];
	[_params release];
	[super dealloc];
}


//- (void)cleanup:(NSTimer *)timer{
//	if (scp != NULL) 
//		scp->cleanChildren(OFTrue);  // clean up any child processes 	
//}

- (void)run
{
	OFCondition cond = EC_Normal;
    OFCmdUnsignedInt overridePort = 0;
    OFCmdUnsignedInt overrideMaxPDU = 0;
    DcmQueryRetrieveOptions options;


	//verbose
	options.verbose_= 0;
	
	//single process
	options.singleProcess_ = [[NSUserDefaults standardUserDefaults] boolForKey: @"SINGLEPROCESS"];
	
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
	
	options.networkTransferSyntax_ = (E_TransferSyntax) [[NSUserDefaults standardUserDefaults] integerForKey: @"preferredSyntaxForIncoming"];
	
//	options.networkTransferSyntax_ = EXS_LittleEndianImplicit;		// See dcmqrsrv.mm
//	else options.networkTransferSyntax_ = EXS_LittleEndianExplicit;																								// See dcmqrsrv.mm
	
	options.networkTransferSyntaxOut_ =  EXS_LittleEndianExplicit;	//;	//EXS_LittleEndianExplicit;	//;		EXS_JPEG2000		// See dcmqrcbm.mm - NOT USED
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
	OFCmdSignedInt opt_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];
	dcmConnectionTimeout.set((Sint32) opt_timeout);
	
	//acse-timeout
	opt_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];
	options.acse_timeout_ = OFstatic_cast(int, opt_timeout);
	
	//dimse-timeout
	opt_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];
	options.dimse_timeout_ = OFstatic_cast(int, opt_timeout);
	options.blockMode_ = DIMSE_NONBLOCKING;
	
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
	options.writeTransferSyntax_ = EXS_Unknown;	//;
	
	//remove group lengths
	options.groupLength_ = EGL_withoutGL;
	
	//number of associations
	options.maxAssociations_ = 800;
	
	//port
	opt_port = _port;
	
	//max PDU size
	options.maxPDU_ = ASC_DEFAULTMAXPDU;
	if (overrideMaxPDU > 0) options.maxPDU_ = overrideMaxPDU;	//;
	
	    /* make sure data dictionary is loaded */
    if (!dcmDataDict.isDictionaryLoaded()) {
    fprintf(stderr, "Warning: no data dictionary loaded, check environment variable: %s\n",
        DCM_DICT_ENVIRONMENT_VARIABLE);
		return;
    }
	
	//init the network
	cond = ASC_initializeNetwork(NET_ACCEPTORREQUESTOR, (int)opt_port, options.acse_timeout_, &options.net_);
    if (cond.bad())
	{
		errmsg("Error initialising network:");
		DimseCondition::dump(cond);
        [[AppController sharedAppController] performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"LISTENER" waitUntilDone:YES];
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
    	
	_abort = NO;
	running = YES;
	
	// ********* WARNING -- NEVER NEVER CALL ANY COCOA (NSobject) functions after this point... fork() will be used ! fork is INCOMPATIBLE with NSObject ! See http://www.cocoadev.com/index.pl?ForkSafety
	// Even a simple NSLog() will cause many many problems......
	
    /* loop waiting for associations */
    while (cond.good() && !_abort)
    {
		if( _abort == NO) cond = scp->waitForAssociation(options.net_);
		if( _abort == NO) scp->cleanChildren(OFTrue);  /* clean up any child processes  This needs to be here*/
	}
	
	delete scp;
	scp = NULL;
	
	if (cond.bad())
	{
		NSLog(@"wwwwwwww");
	}
	
	cond = ASC_dropNetwork(&options.net_);
    if (cond.bad()) {
        errmsg("Error dropping network:");
        DimseCondition::dump(cond);
    }
	
	running = NO;
	
	return;
}

-(void)abort
{
	_abort = YES;
}

@end
