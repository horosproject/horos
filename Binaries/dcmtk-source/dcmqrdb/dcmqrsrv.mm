/*
 *
 *  Copyright (C) 1993-2005, OFFIS
 *
 *  This software and supporting documentation were developed by
 *
 *    Kuratorium OFFIS e.V.x
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
 *  Module:  dcmqrdb
 *
 *  Author:  Marco Eichelberg
 *
 *  Purpose: class DcmQueryRetrieveSCP
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:16:07 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmqrdb/dcmqrsrv.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#import "browserController.h"
#import "ThreadsManager.h"
#import "DicomDatabase.h"
#import "NSThread+N2.h"
#import "AppController.h"
#import "N2Debug.h"
#import "ContextCleaner.h"

#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "dcmqrsrv.h"
#include "dcmqropt.h"
#include "dcfilefo.h"
#include "dcmqrdba.h"
#include "dcmqrcbf.h"    /* for class DcmQueryRetrieveFindContext */
#include "dcmqrcbm.h"    /* for class DcmQueryRetrieveMoveContext */
#include "dcmqrcbg.h"    /* for class DcmQueryRetrieveGetContext */
#include "dcmqrcbs.h"    /* for class DcmQueryRetrieveStoreContext */
#include "dcmetinf.h"
#include "dul.h"
#import "dcmqrdbq.h"

#include <signal.h>

extern int AbortAssociationTimeOut;

static int numberOfActiveAssociations = 0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//static N2ConnectionListener* listenerForSCPProcess = nil;
//
//@interface listenerForSCPProcessClass : N2Connection{
//    
//    NSPoint origin;
//}
//
//@end
//
//@implementation listenerForSCPProcessClass
//
//-(id)initWithAddress:(NSString *)address port:(NSInteger)port is:(NSInputStream *)is os:(NSOutputStream *)os
//{
//    if( (self = [super initWithAddress:address port:port is:is os:os]))
//    {
//        NSLog( @"SCP Process Connected");
//    }
//    
//    return self;
//}
//
//
//-(void)handleData:(NSMutableData*)data
//{
//    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
//    @try
//    {
//        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData: data];
//        
//        NSLog( @"***** %@", dict);
//        
//        NSDictionary *response = [NSDictionary dictionaryWithObjectsAndKeys: @"Hello World", @"message", nil];
//        
//        [self writeData: [NSKeyedArchiver archivedDataWithRootObject: response]];
//    }
//    @catch (NSException* e)
//    {
//        N2LogException( e);
//    }
//    @finally
//    {
//        [pool release];
//    }
//}
//@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ContextCleaner

+ (void) waitUnlockFileWithPID: (NSDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Father
    [NSThread sleepForTimeInterval: 0.3]; // To allow the creation of lock_process file with corresponding pid
    
    NSPersistentStoreCoordinator *dbLock = [dict valueForKey: @"dbStoreCoordinator"];
    
    [dbLock lock];
    
    // Father
    [NSThread sleepForTimeInterval: 0.3]; // To allow the creation of lock_process file with corresponding pid
    
    
	BOOL fileExist = YES;
	int pid = [[dict valueForKey: @"pid"] intValue], inc = 0, rc = pid, state;
	char dir[ 1024];
	sprintf( dir, "%s-%d", "/tmp/lock_process", pid);

    #define TIMEOUT 1200 // 1200*100000 = 120 secs
    #define DBTIMEOUT 400 // = 40 secs
    
	do
	{
		FILE * pFile = fopen (dir,"r");
		if( pFile)
		{
			rc = waitpid( pid, &state, WNOHANG);	// Check to see if this pid is still alive?
			fclose (pFile);
		}
		else
			fileExist = NO;
            
            usleep( 100000);
            inc++;
        
        if( inc >= DBTIMEOUT)
        {
            [dbLock unlock];
            dbLock = nil;
        }
	}
    while( fileExist == YES && inc < TIMEOUT && rc >= 0);
	
	if( inc >= TIMEOUT)
	{
		kill( pid, 15);
		NSLog( @"******* waitUnlockFile for %d sec", inc/10);
	}
	
	if( rc < 0)
	{
        NSLog( @"******* waitUnlockFile : child process died... %d / %d", rc, errno);
		kill( pid, 15);
	}
	
	unlink( dir);
    
    [dbLock unlock];
    dbLock = nil;
	
    [dbLock unlock];
    dbLock = nil;
    
	if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"] == NO)
	{
		NSString *str = [NSString stringWithContentsOfFile: @"/tmp/error_message"];
		[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/error_message" handler: nil];
		
		if( str && [str length] > 0)
			[[AppController sharedAppController] performSelectorOnMainThread: @selector(displayListenerError:) withObject: str waitUntilDone: NO];
	}
    
    // And finally release memory on the father side, after the death of the process
    inc = 0;
    do
	{
		rc = waitpid( pid, &state, WNOHANG);	// Check to see if this pid is still alive?
		
        usleep( 100000);
        inc++;
	}
    #define TIMEOUTRELEASE 60000 // 60000*100000 = 6000 secs = 100 min
	while( inc < TIMEOUTRELEASE && rc >= 0);
    
    [NSThread sleepForTimeInterval: 5];
    
    T_ASC_Association *assoc = (T_ASC_Association*) [[dict valueForKey: @"assoc"] pointerValue];
    OFCondition cond = EC_Normal;
    
    /* the child will handle the association, we can drop it */
    cond = ASC_dropAssociation(assoc);
    if (cond.bad())
    {
        //DcmQueryRetrieveOptions::errmsg("Cannot Drop Association:");
        DimseCondition::dump(cond);
    }
    
    cond = ASC_destroyAssociation(&assoc);
    if (cond.bad())
    {
        //DcmQueryRetrieveOptions::errmsg("Cannot Destroy Association:");
        DimseCondition::dump(cond);
    }
    
	[pool release];
}

+ (void) waitForHandledAssociations
{
    while( numberOfActiveAssociations > 0)
        [NSThread sleepForTimeInterval: 0.1];
}

+ (void) handleAssociation: (NSDictionary*) d
{
    numberOfActiveAssociations++;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @try
    {
        T_ASC_Association * assoc = (T_ASC_Association*) [[d valueForKey: @"assoc"] pointerValue];
        DcmQueryRetrieveSCP *scp = (DcmQueryRetrieveSCP*) [[d valueForKey: @"DcmQueryRetrieveSCP"] pointerValue];
        
        if( assoc && scp)
        {
            OFCondition cond = scp->handleAssociation(assoc, YES);
            
            cond = ASC_dropAssociation(assoc);
            if (cond.bad())
                DimseCondition::dump(cond);
            
            cond = ASC_destroyAssociation(&assoc);
            if (cond.bad())
                DimseCondition::dump(cond);
        }
    }
    @catch (NSException *e) {
        N2LogException( e);
    }
    
    [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
    
    [pool release];
    
    numberOfActiveAssociations--;
}
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
extern "C"
{
	void (*signal(int signum, void (*sighandler)(int)))(int);
	
	void silent_exit_on_sig(int sig_num)
	{
		printf ("\rSignal %d received in OsiriX child process - will quit silently.\r", sig_num);
		_Exit(3);
	}
}

NSManagedObjectContext *staticContext = nil;
BOOL forkedProcess = NO;

static char *last(char *p, int c)
{
  char *t;              /* temporary variable */

  if ((t = strrchr(p, c)) != NULL) return t + 1;
  
  return p;
}

static void findCallback(
        /* in */
        void *callbackData,
        OFBool cancelled, T_DIMSE_C_FindRQ *request,
        DcmDataset *requestIdentifiers, int responseCount,
        /* out */
        T_DIMSE_C_FindRSP *response,
        DcmDataset **responseIdentifiers,
        DcmDataset **stDetail)
{
  DcmQueryRetrieveFindContext *context = OFstatic_cast(DcmQueryRetrieveFindContext *, callbackData);
  context->callbackHandler(cancelled, request, requestIdentifiers, responseCount, response, responseIdentifiers, stDetail);
}


static void getCallback(
        /* in */
        void *callbackData,
        OFBool cancelled, T_DIMSE_C_GetRQ *request,
        DcmDataset *requestIdentifiers, int responseCount,
        /* out */
        T_DIMSE_C_GetRSP *response, DcmDataset **stDetail,
        DcmDataset **responseIdentifiers)
{
  DcmQueryRetrieveGetContext *context = OFstatic_cast(DcmQueryRetrieveGetContext *, callbackData);
  context->callbackHandler(cancelled, request, requestIdentifiers, responseCount, response, stDetail, responseIdentifiers);
    
    if( forkedProcess == NO)
        [[NSThread currentThread] setProgress:1.0/(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations+response->NumberOfRemainingSubOperations)*(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations)];
}


static void moveCallback(
        /* in */
        void *callbackData,
        OFBool cancelled, T_DIMSE_C_MoveRQ *request,
        DcmDataset *requestIdentifiers, int responseCount,
        /* out */
        T_DIMSE_C_MoveRSP *response, DcmDataset **stDetail,
        DcmDataset **responseIdentifiers)
{
  DcmQueryRetrieveMoveContext *context = OFstatic_cast(DcmQueryRetrieveMoveContext *, callbackData);
  context->callbackHandler(cancelled, request, requestIdentifiers, responseCount, response, stDetail, responseIdentifiers);
  
    if( forkedProcess == NO)
        [[NSThread currentThread] setProgress:1.0/(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations+response->NumberOfRemainingSubOperations)*(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations)];
}

static void storeCallback(
    /* in */
    void *callbackData,
    T_DIMSE_StoreProgress *progress,    /* progress state */
    T_DIMSE_C_StoreRQ *req,             /* original store request */
    char *imageFileName,       /* being received into */
    char *sourceAETitle,
    char *destinationAETitle,
    DcmDataset **imageDataSet, /* being received into */
    /* out */
    T_DIMSE_C_StoreRSP *rsp,            /* final store response */
    DcmDataset **stDetail)
{
  DcmQueryRetrieveStoreContext *context = OFstatic_cast(DcmQueryRetrieveStoreContext *, callbackData);
  context->callbackHandler(progress, req, imageFileName, sourceAETitle, destinationAETitle, imageDataSet, rsp, stDetail);
}


/*
 * ============================================================================================================
 */


DcmQueryRetrieveSCP::DcmQueryRetrieveSCP(
  const DcmQueryRetrieveConfig& config,
  const DcmQueryRetrieveOptions& options,
  const DcmQueryRetrieveDatabaseHandleFactory& factory)
: config_(&config)
, dbCheckFindIdentifier_(OFFalse)
, dbCheckMoveIdentifier_(OFFalse)
, dbDebug_(OFFalse)
, factory_(factory)
, options_(options)
{
	activateCGETSCP_ = [[NSUserDefaults standardUserDefaults] boolForKey: @"activateCGETSCP"];
    activateCFINDSCP_ = [[NSUserDefaults standardUserDefaults] boolForKey: @"activateCFINDSCP"];
	secureConnection_ = 0;
}

DcmQueryRetrieveSCP::~DcmQueryRetrieveSCP()
{
}

void DcmQueryRetrieveSCP::lockFile(void)
{
    if( options_.singleProcess_)
        return;
	
    char dir[ 1024];
	
	sprintf( dir, "%s-%d", "/tmp/lock_process", getpid());
	unlink( dir);
	FILE * pFile = fopen (dir,"w+");
	if( pFile)
		fclose (pFile);
}

void DcmQueryRetrieveSCP::unlockFile(void)
{
    if( options_.singleProcess_)
        return;
    
	BOOL fileExist = YES;
	char dir[ 1024];
	sprintf( dir, "%s-%d", "/tmp/lock_process", getpid());
	
	int inc = 0;
	do
	{
		int err = unlink( dir);
		if( err  == 0 || errno == ENOENT) fileExist = NO;
		
		usleep( 1000);
		inc++;
	}
	while( fileExist == YES && inc < 100000);
}

void DcmQueryRetrieveSCP::writeStateProcess( const char *str, T_ASC_Association *assoc)
{
    if( options_.singleProcess_)
    {
        [NSThread currentThread].status = [NSString stringWithFormat: NSLocalizedString( @"%s %s", nil), assoc->params->DULparams.callingPresentationAddress, str];
    }
    else
    {
        char dir[ 1024];
        sprintf( dir, "%s-%d", "/tmp/process_state", getpid());
        
        FILE * pFile = fopen (dir,"r");
        if( pFile == nil)
        {
            pFile = fopen (dir,"w+");
            if( pFile)
            {
                fprintf( pFile, "%s", str);
                fclose (pFile);
            }
        }
        else fclose (pFile);
    }
}

void DcmQueryRetrieveSCP::writeErrorMessage( const char *str)
{
    if( options_.singleProcess_)
    {
        if( str)
            [[AppController sharedAppController] performSelectorOnMainThread: @selector(displayListenerError:) withObject: [NSString stringWithUTF8String: str] waitUntilDone: NO];
    }
    else
    {
        char dir[ 1024];
        sprintf( dir, "%s", "/tmp/error_message");
        unlink( dir);
        
        FILE * pFile = fopen (dir,"w+");
        if( pFile)
        {
            fprintf( pFile, "%s", str);
            fclose (pFile);
        }
    }
}

NSString* DcmQueryRetrieveSCP::getErrorMessage()	// see emptyDeleteQueue: for reading this error message
{
	NSString *str = [NSString stringWithContentsOfFile: @"/tmp/error_message"];
	
	[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/error_message" handler: nil];
	
	return str;
}

//void DcmQueryRetrieveSCP::waitUnlockFileWithPID(int pid)
//{
//	BOOL fileExist = YES;
//	int inc = 0, rc = pid, state;
//	char dir[ 1024];
//	sprintf( dir, "%s-%d", "/tmp/lock_process", pid);
//	
//	do
//	{
//		FILE * pFile = fopen (dir,"r");
//		if( pFile)
//		{
//			rc = waitpid( pid, &state, WNOHANG);	// Check to see if this pid is still alive?
//			fclose (pFile);
//		}
//		else
//			fileExist = NO;
//		
//		usleep( 100000);
//		inc++;
//	}
//	#define TIMEOUT 300 // 300*100000 = 30 secs
//	while( fileExist == YES && inc < TIMEOUT && rc >= 0);
//	
//	if( inc >= TIMEOUT)
//	{
//		kill( pid, 15);
//		NSLog( @"******* waitUnlockFile for %d sec", inc/10);
//	}
//	
//	if( rc < 0)
//	{
//		kill( pid, 15);
//		NSLog( @"******* waitUnlockFile : child process died...");
//	}
//	
//	unlink( dir);
//}

OFCondition DcmQueryRetrieveSCP::dispatch(T_ASC_Association *assoc, OFBool correctUIDPadding)
{
    OFCondition cond = EC_Normal;
    T_DIMSE_Message msg;
    T_ASC_PresentationContextID presID;
    OFBool firstLoop = OFTrue;
    
    // this while loop is executed exactly once unless the "keepDBHandleDuringAssociation_"
    // flag is not set, in which case the inner loop is executed only once and this loop
    // repeats for each incoming DIMSE command. In this case, the DB handle is created
    // and released for each DIMSE command.
    while (cond.good())
    {
        /* Create a database handle for this association */
        
        DcmQueryRetrieveDatabaseHandle *dbHandle = nil;
        
//        @synchronized( globalSync)
        {
            dbHandle = factory_.createDBHandle( assoc->params->DULparams.callingAPTitle, assoc->params->DULparams.calledAPTitle, cond);
		}
        
        if (cond.bad())
        {
          DcmQueryRetrieveOptions::errmsg("dispatch: cannot create DB Handle");
          return cond;
        }

        if (dbHandle == NULL)
        {
          // this should not happen, but we check it anyway
          DcmQueryRetrieveOptions::errmsg("dispatch: cannot create DB Handle");
          return EC_IllegalCall;
        }

        dbHandle->setDebugLevel(dbDebug_ ? 1 : 0);
        dbHandle->setIdentifierChecking(dbCheckFindIdentifier_, dbCheckMoveIdentifier_);
        firstLoop = OFTrue;

        // this while loop is executed exactly once unless the "keepDBHandleDuringAssociation_"
        // flag is set, in which case the DB handle remains open until something goes wrong
        // or the remote peer closes the association
        while (cond.good() && (firstLoop || options_.keepDBHandleDuringAssociation_) )
        {
            int timeout;
            
//            @synchronized( globalSync)
            {
                if( firstLoop)
                {
                    timeout = dcmConnectionTimeout.get();
                    
                    if( timeout <= 0)
                        timeout = 5;
                }
                else
                    timeout = options_.dimse_timeout_;
                
                cond = DIMSE_receiveCommand(assoc, DIMSE_NONBLOCKING, timeout, &presID, &msg, NULL);
            }
            
            firstLoop = OFFalse;
            
            /* did peer release, abort, or do we have a valid message ? */
            if (cond.good())
            {
                T_DIMSE_Command ms = msg.CommandField;
                
                if( ms == DIMSE_C_GET_RQ && activateCGETSCP_ == false)
                {
                    DcmQueryRetrieveOptions::errmsg("CGET NOT ACTIVATED - Cannot handle command: 0x%x\n", (unsigned)msg.CommandField);
                    ms = DIMSE_NOTHING;
                }
                
                if( ms == DIMSE_C_FIND_RQ && activateCFINDSCP_ == false)
                {
                    DcmQueryRetrieveOptions::errmsg("CFIND NOT ACTIVATED - Cannot handle command: 0x%x\n", (unsigned)msg.CommandField);
                    ms = DIMSE_NOTHING;
                }
                
                /* process command */
                switch ( ms)
				{
                case DIMSE_C_ECHO_RQ:
					if( secureConnection_)
                        writeStateProcess( "C-ECHO TLS SCP...", assoc);
                    else
                        writeStateProcess( "C-ECHO SCP...", assoc);
                    if( forkedProcess)
                        unlockFile();
                        
                    cond = echoSCP(assoc, &msg.msg.CEchoRQ, presID);
                    break;
                case DIMSE_C_STORE_RQ:
                    if( secureConnection_)
                        writeStateProcess( "C-STORE TLS SCP...", assoc);
                    else
                        writeStateProcess( "C-STORE SCP...", assoc);
					if( forkedProcess)
                        unlockFile();
                    cond = storeSCP(assoc, &msg.msg.CStoreRQ, presID, *dbHandle, correctUIDPadding);
                    break;
                case DIMSE_C_FIND_RQ:
                    if( secureConnection_)
                        writeStateProcess( "C-FIND TLS SCP...", assoc);
                    else
                        writeStateProcess( "C-FIND SCP...", assoc);
                    cond = findSCP(assoc, &msg.msg.CFindRQ, presID, *dbHandle);
                    break;
                case DIMSE_C_MOVE_RQ:
                    if( secureConnection_)
                        writeStateProcess( "C-MOVE TLS SCP...", assoc);
                    else
                        writeStateProcess( "C-MOVE SCP...", assoc);
					//* unlockFile(); is done in DCMTKDataHandlerCategory.mm
                    cond = moveSCP(assoc, &msg.msg.CMoveRQ, presID, *dbHandle);
                    break;
                case DIMSE_C_GET_RQ:
                    if( secureConnection_)
                        writeStateProcess( "C-GET TLS SCP...", assoc);
                    else
                        writeStateProcess( "C-GET SCP...", assoc);
                        //* unlockFile(); is done in DCMTKDataHandlerCategory.mm
						cond = getSCP(assoc, &msg.msg.CGetRQ, presID, *dbHandle);
					break;
                case DIMSE_C_CANCEL_RQ:
                    //* This is a late cancel request, just ignore it 
                    if (options_.verbose_)
                        printf("dispatch: late C-CANCEL-RQ, ignoring\n");
                    
                    if( forkedProcess)
                        unlockFile();
                    break;
				
                default:
                    /* we cannot handle this kind of message */
                    cond = DIMSE_BADCOMMANDTYPE;
                    DcmQueryRetrieveOptions::errmsg("Cannot handle command: 0x%x\n", (unsigned)msg.CommandField);
                        
                    if( forkedProcess)
                        unlockFile();
                    /* the condition will be returned, the caller will abort the association. */
                }
            }
            else if ((cond == DUL_PEERREQUESTEDRELEASE)||(cond == DUL_PEERABORTEDASSOCIATION))
            {
                if( forkedProcess)
                    unlockFile();
                // association gone
            }
            else
            {
                if( forkedProcess)
                    unlockFile();
                // the condition will be returned, the caller will abort the assosiation.
            }
        }
        
//        @synchronized( globalSync)
        {
            // release DB handle
            delete dbHandle;
            dbHandle = nil;
        }
    }

    // Association done
    return cond;
}


OFCondition DcmQueryRetrieveSCP::handleAssociation(T_ASC_Association * assoc, OFBool correctUIDPadding)
{
    OFCondition           cond = EC_Normal;
    DIC_NODENAME        peerHostName;
    DIC_AE              peerAETitle;
    DIC_AE              myAETitle;
	
	if( assoc == nil)
	{
		cond = DUL_PEERABORTEDASSOCIATION;
		return cond;
	}
	
    ASC_getPresentationAddresses(assoc->params, peerHostName, NULL);
    ASC_getAPTitles(assoc->params, peerAETitle, myAETitle, NULL);
	
    index = 0;
    
 /* now do the real work */
    cond = dispatch(assoc, correctUIDPadding);
	
    /* clean up on association termination */
    if (cond == DUL_PEERREQUESTEDRELEASE)
    {
        if (options_.verbose_)
            printf("Association Release\n");
        
        if( assoc)
        {
            cond = ASC_acknowledgeRelease(assoc);
            ASC_dropSCPAssociation(assoc);
        }
    }
    else if (cond == DUL_PEERABORTEDASSOCIATION)
    {
        if (options_.verbose_)
            printf("Association Aborted\n");
    }
    else
    {
        DcmQueryRetrieveOptions::errmsg("DIMSE Failure (aborting association):\n");
        DimseCondition::dump(cond);
        
        if( cond == DIMSE_NODATAAVAILABLE)
            NSLog( @"----- DIMSE_NODATAAVAILABLE no data available : %d (block mode: %d)", options_.dimse_timeout_, options_.blockMode_);
        
        AbortAssociationTimeOut = 2;
        /* some kind of error so abort the association */
        cond = ASC_abortAssociation(assoc);
        AbortAssociationTimeOut = -1;
    }
    
    return cond;
}

OFCondition DcmQueryRetrieveSCP::echoSCP(T_ASC_Association * assoc, T_DIMSE_C_EchoRQ * req,
        T_ASC_PresentationContextID presId)
{
    OFCondition cond = EC_Normal;

    if (options_.verbose_) {
        printf("Received Echo SCP RQ: MsgID %d\n",
                req->MessageID);
    }
    /* we send an echo response back */
    cond = DIMSE_sendEchoResponse(assoc, presId,
        req, STATUS_Success, NULL);

    if (cond.bad()) {
        DcmQueryRetrieveOptions::errmsg("echoSCP: Echo Response Failed:");
        DimseCondition::dump(cond);
    }
    return cond;
}


OFCondition DcmQueryRetrieveSCP::findSCP(T_ASC_Association * assoc, T_DIMSE_C_FindRQ * request,
        T_ASC_PresentationContextID presID,
        DcmQueryRetrieveDatabaseHandle& dbHandle)

{
    OFCondition cond = EC_Normal;
    DcmQueryRetrieveFindContext context(dbHandle, options_, STATUS_Pending);

    DIC_AE aeTitle;
    aeTitle[0] = '\0';
    ASC_getAPTitles(assoc->params, NULL, aeTitle, NULL);
    context.setOurAETitle(aeTitle);

    if (options_.verbose_) {
        printf("Received Find SCP: ");
        DIMSE_printCFindRQ(stdout, request);
    }

    cond = DIMSE_findProvider(assoc, presID, request,
        findCallback, &context, options_.blockMode_, options_.dimse_timeout_);
    if (cond.bad()) {
        DcmQueryRetrieveOptions::errmsg("Find SCP Failed:");
        DimseCondition::dump(cond);
    }
    return cond;
}


OFCondition DcmQueryRetrieveSCP::getSCP(T_ASC_Association * assoc, T_DIMSE_C_GetRQ * request,
        T_ASC_PresentationContextID presID, DcmQueryRetrieveDatabaseHandle& dbHandle)
{
    OFCondition cond = EC_Normal;
    DcmQueryRetrieveGetContext context(dbHandle, options_, STATUS_Pending, assoc, request->MessageID, request->Priority, presID);

    DIC_AE aeTitle;
    aeTitle[0] = '\0';
    ASC_getAPTitles(assoc->params, NULL, aeTitle, NULL);
    context.setOurAETitle(aeTitle);

    if (options_.verbose_) {
        printf("Received Get SCP: ");
        DIMSE_printCGetRQ(stdout, request);
    }

    cond = DIMSE_getProvider(assoc, presID, request,
        getCallback, &context, options_.blockMode_, options_.dimse_timeout_);
    if (cond.bad()) {
        DcmQueryRetrieveOptions::errmsg("Get SCP Failed:");
        DimseCondition::dump(cond);
    }
    return cond;
}


OFCondition DcmQueryRetrieveSCP::moveSCP(T_ASC_Association * assoc, T_DIMSE_C_MoveRQ * request,
        T_ASC_PresentationContextID presID, DcmQueryRetrieveDatabaseHandle& dbHandle)
{
    OFCondition cond = EC_Normal;
	//printf("move context\n");
    DcmQueryRetrieveMoveContext context(dbHandle, options_, NULL, STATUS_Pending, assoc, request->MessageID, request->Priority);

    DIC_AE aeTitle;
    aeTitle[0] = '\0';
	//printf("ASC_getAPTitles\n");
    ASC_getAPTitles(assoc->params, NULL, aeTitle, NULL);
	//printf("context.setOurAETitle\n");
    context.setOurAETitle(aeTitle);

    if (options_.verbose_) {
        printf("Received Move SCP: ");
        DIMSE_printCMoveRQ(stdout, request);
    }
	
    cond = DIMSE_moveProvider(assoc, presID, request,
        moveCallback, &context, options_.blockMode_, options_.dimse_timeout_);
    if (cond.bad()) {
        DcmQueryRetrieveOptions::errmsg("Move SCP Failed:");
        DimseCondition::dump(cond);
    }
    return cond;
}


OFCondition DcmQueryRetrieveSCP::storeSCP(T_ASC_Association * assoc, T_DIMSE_C_StoreRQ * request,
             T_ASC_PresentationContextID presId,
             DcmQueryRetrieveDatabaseHandle& dbHandle,
             OFBool correctUIDPadding)
{
	DcmFileFormat dcmff;
    OFCondition cond = EC_Normal;
    OFCondition dbcond = EC_Normal;
    char imageFileName[MAXPATHLEN+1];
   
    DcmQueryRetrieveStoreContext context(dbHandle, options_, STATUS_Success, &dcmff, correctUIDPadding);

    if (options_.verbose_) {
        printf("Received Store SCP: ");
        DIMSE_printCStoreRQ(stdout, request);
    }

    if (!dcmIsaStorageSOPClassUID(request->AffectedSOPClassUID)) {
        /* callback will send back sop class not supported status */
        context.setStatus(STATUS_STORE_Refused_SOPClassNotSupported);
        /* must still receive data */
        strcpy(imageFileName, NULL_DEVICE_NAME);
    } else if (options_.ignoreStoreData_) {
        strcpy(imageFileName, NULL_DEVICE_NAME);
    } else {
        dbcond = dbHandle.makeNewStoreFileName(
            request->AffectedSOPClassUID,
            request->AffectedSOPInstanceUID,
            imageFileName);
        
		if (dbcond.bad())
		{
            DcmQueryRetrieveOptions::errmsg("storeSCP: Database: makeNewStoreFileName Failed");
            /* must still receive data */
            strcpy(imageFileName, NULL_DEVICE_NAME);
            /* callback will send back out of resources status */
            context.setStatus(STATUS_STORE_Refused_OutOfResources);
        }
    }
	
	FILE * pFile = fopen ("/tmp/kill_all_storescu", "r");
	if( pFile)
	{
		fclose (pFile);
		cond = ASC_abortAssociation(assoc);
	}
	
#ifdef LOCK_IMAGE_FILES
    /* exclusively lock image file */
#ifdef O_BINARY
    int lockfd = open(imageFileName, (O_WRONLY | O_CREAT | O_TRUNC | O_BINARY), 0666);
#else
    int lockfd = open(imageFileName, (O_WRONLY | O_CREAT | O_TRUNC), 0666);
#endif
    if (lockfd < 0)
    {
        DcmQueryRetrieveOptions::errmsg("storeSCP: file locking failed, cannot create file");

        /* must still receive data */
        strcpy(imageFileName, NULL_DEVICE_NAME);

        /* callback will send back out of resources status */
        context.setStatus(STATUS_STORE_Refused_OutOfResources);
    }
    else
      dcmtk_flock(lockfd, LOCK_EX);
#endif

    context.setFileName(imageFileName);

    DcmDataset *dset = dcmff.getDataset();

    /* we must still retrieve the data set even if some error has occured */

    if (options_.bitPreserving_)
	{ /* the bypass option can be set on the command line */
        cond = DIMSE_storeProvider(assoc, presId, request, imageFileName, (int)options_.useMetaheader_,
                                   NULL, storeCallback,
                                   (void*)&context, options_.blockMode_, options_.dimse_timeout_);
    }
	else
	{
        cond = DIMSE_storeProvider(assoc, presId, request, (char *)NULL, (int)options_.useMetaheader_,
                                   &dset, storeCallback,
                                   (void*)&context, options_.blockMode_, options_.dimse_timeout_);
    }
	
	static_cast<DcmQueryRetrieveOsiriXDatabaseHandle *>(&dbHandle) -> updateLogEntry(dset);

    if (cond.bad())
	{
        DcmQueryRetrieveOptions::errmsg("Store SCP Failed:");
        DimseCondition::dump(cond);
		
		writeErrorMessage( cond.text());
    }
	
    if (!options_.ignoreStoreData_ && (cond.bad() || (context.getStatus() != STATUS_Success)))
    {
      /* remove file */
      if (strcmp(imageFileName, NULL_DEVICE_NAME) != 0) // don't try to delete /dev/null
      {
        if (options_.verbose_) fprintf(stderr, "Store SCP: Deleting Image File: %s\n", imageFileName);
        unlink(imageFileName);
      }
      dbHandle.pruneInvalidRecords();
    }

#ifdef LOCK_IMAGE_FILES
    /* unlock image file */
    if (lockfd >= 0)
    {
      dcmtk_flock(lockfd, LOCK_UN);
      close(lockfd);
    }
#endif

	if (strcmp(imageFileName, NULL_DEVICE_NAME) != 0)
	{
		char dir[ 1024];
		sprintf( dir, "%s/%s", [[BrowserController currentBrowser] cfixedIncomingNoIndexDirectory], last( imageFileName, '/'));
		rename( imageFileName, dir);
        
        if( forkedProcess == NO && index == 0)
        {
            [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
        }
        
        index++;
	}
	
    return cond;
}


/* Association negotiation */

void DcmQueryRetrieveSCP::refuseAnyStorageContexts(T_ASC_Association * assoc)
{
    int i;
    T_ASC_PresentationContextID pid;

    for (i = 0; i < numberOfAllDcmStorageSOPClassUIDs; i++) {
//        pid = ASC_findAcceptedPresentationContextID(assoc, dcmAllStorageSOPClassUIDs[i]);
//        if (pid != 0) {
//            /* refuse */
//            ASC_refusePresentationContext(assoc->params, pid, ASC_P_USERREJECTION);
//        }
		do {            
          pid = ASC_findAcceptedPresentationContextID(assoc, dcmAllStorageSOPClassUIDs[i]);
          if (pid != 0) ASC_refusePresentationContext(assoc->params, pid, ASC_P_USERREJECTION);
        } while (pid != 0); // repeat as long as we find presentation contexts for this SOP class - there might be multiple ones.
    }
}


OFCondition DcmQueryRetrieveSCP::refuseAssociation(T_ASC_Association ** assoc, CTN_RefuseReason reason)
{
    OFCondition cond = EC_Normal;
    T_ASC_RejectParameters rej;

    if (options_.verbose_)
    {
      printf("Refusing Association (");
      switch (reason)
      {
        case CTN_TooManyAssociations:
            printf("TooManyAssociations");
            break;
        case CTN_CannotFork:
            printf("CannotFork");
            break;
        case CTN_BadAppContext:
            printf("BadAppContext");
            break;
        case CTN_BadAEPeer:
            printf("BadAEPeer");
            break;
        case CTN_BadAEService:
            printf("BadAEService");
            break;
        case CTN_NoReason:
            printf("NoReason");
            break;
        default:
            printf("???");
            break;
      }
      printf(")\n");
    }

    switch (reason)
    {
      case CTN_TooManyAssociations:
        rej.result = ASC_RESULT_REJECTEDTRANSIENT;
        rej.source = ASC_SOURCE_SERVICEPROVIDER_PRESENTATION_RELATED;
        rej.reason = ASC_REASON_SP_PRES_LOCALLIMITEXCEEDED;
        break;
      case CTN_CannotFork:
        rej.result = ASC_RESULT_REJECTEDPERMANENT;
        rej.source = ASC_SOURCE_SERVICEPROVIDER_PRESENTATION_RELATED;
        rej.reason = ASC_REASON_SP_PRES_TEMPORARYCONGESTION;
        break;
      case CTN_BadAppContext:
        rej.result = ASC_RESULT_REJECTEDTRANSIENT;
        rej.source = ASC_SOURCE_SERVICEUSER;
        rej.reason = ASC_REASON_SU_APPCONTEXTNAMENOTSUPPORTED;
        break;
      case CTN_BadAEPeer:
        rej.result = ASC_RESULT_REJECTEDPERMANENT;
        rej.source = ASC_SOURCE_SERVICEUSER;
        rej.reason = ASC_REASON_SU_CALLINGAETITLENOTRECOGNIZED;
        break;
      case CTN_BadAEService:
        rej.result = ASC_RESULT_REJECTEDPERMANENT;
        rej.source = ASC_SOURCE_SERVICEUSER;
        rej.reason = ASC_REASON_SU_CALLEDAETITLENOTRECOGNIZED;
        break;
      case CTN_NoReason:
      default:
        rej.result = ASC_RESULT_REJECTEDPERMANENT;
        rej.source = ASC_SOURCE_SERVICEUSER;
        rej.reason = ASC_REASON_SU_NOREASON;
        break;
    }

    cond = ASC_rejectAssociation(*assoc, &rej);

    if (cond.bad())
    {
      fprintf(stderr, "Association Reject Failed:\n");
      DimseCondition::dump(cond);
    }

    cond = ASC_dropAssociation(*assoc);
    if (cond.bad())
    {
      fprintf(stderr, "Cannot Drop Association:\n");
      DimseCondition::dump(cond);
    }
    cond = ASC_destroyAssociation(assoc);
    if (cond.bad())
    {
      fprintf(stderr, "Cannot Destroy Association:\n");
      DimseCondition::dump(cond);
    }

    return cond;
}


OFCondition DcmQueryRetrieveSCP::negotiateAssociation(T_ASC_Association * assoc)
{
    OFCondition cond = EC_Normal;
    int i;

    DIC_AE calledAETitle;
    ASC_getAPTitles(assoc->params, NULL, calledAETitle, NULL);
	//change to have 10 possible Syntaxes. We want to accept any incoming Syntax
    const char* transferSyntaxes[] = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL }; // 12 transfer syntaxes
    int nTS = 0;
	
    switch (options_.networkTransferSyntax_)
    {
    case EXS_LittleEndianImplicit:
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
    break;
		
    default:
    case EXS_LittleEndianExplicit:
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGLSLossyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;
		transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
		transferSyntaxes[ nTS++] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
		
    case EXS_BigEndianExplicit:
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
		transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
    break;
		
#ifndef DISABLE_COMPRESSION_EXTENSION
    case EXS_JPEGProcess14SV1TransferSyntax:
        transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax ;                          
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLossyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
            
    case EXS_JPEGProcess1TransferSyntax:
        transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLossyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
            
    case EXS_JPEGProcess2_4TransferSyntax:
        transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLossyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
            
    case EXS_JPEG2000LosslessOnly: 
        transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;	
    break;
            
    case EXS_JPEG2000:
        transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLossyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;		
		transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
		transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
		transferSyntaxes[ nTS++] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
            
    case EXS_JPEGLSLossless:
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
            
    case EXS_JPEGLSLossy:
        transferSyntaxes[ nTS++] = UID_JPEGLSLossyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGLSLosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000LosslessOnlyTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
            
    case EXS_RLELossless:
        transferSyntaxes[ nTS++] = UID_RLELosslessTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEG2000TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess14SV1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_JPEGProcess2_4TransferSyntax;		
        transferSyntaxes[ nTS++] = UID_JPEGProcess1TransferSyntax;
        transferSyntaxes[ nTS++] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
        transferSyntaxes[ nTS++] = UID_BigEndianExplicitTransferSyntax;
    break;
#endif
    }
	
    if( nTS > 12)
        NSLog( @"******* MEMORY LEAK nTS > 12");
    
    const char * const nonStorageSyntaxes[] =
    {
        UID_VerificationSOPClass,
        UID_FINDPatientRootQueryRetrieveInformationModel,
        UID_MOVEPatientRootQueryRetrieveInformationModel,
        UID_GETPatientRootQueryRetrieveInformationModel,
#ifndef NO_PATIENTSTUDYONLY_SUPPORT
        UID_FINDPatientStudyOnlyQueryRetrieveInformationModel,
        UID_MOVEPatientStudyOnlyQueryRetrieveInformationModel,
        UID_GETPatientStudyOnlyQueryRetrieveInformationModel,
#endif
        UID_FINDStudyRootQueryRetrieveInformationModel,
        UID_MOVEStudyRootQueryRetrieveInformationModel,
        UID_GETStudyRootQueryRetrieveInformationModel,
        UID_PrivateShutdownSOPClass
    };
	
    const int numberOfNonStorageSyntaxes = DIM_OF(nonStorageSyntaxes);
    const char *selectedNonStorageSyntaxes[DIM_OF(nonStorageSyntaxes)];
    int numberOfSelectedNonStorageSyntaxes = 0;
    for (i=0; i<numberOfNonStorageSyntaxes; i++)
    {
        if (0 == strcmp(nonStorageSyntaxes[i], UID_FINDPatientRootQueryRetrieveInformationModel))
        {
          if (options_.supportPatientRoot_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_MOVEPatientRootQueryRetrieveInformationModel))
        {
          if (options_.supportPatientRoot_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_GETPatientRootQueryRetrieveInformationModel))
        {
          if (options_.supportPatientRoot_ && (! options_.disableGetSupport_)) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_FINDPatientStudyOnlyQueryRetrieveInformationModel))
        {
          if (options_.supportPatientStudyOnly_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_MOVEPatientStudyOnlyQueryRetrieveInformationModel))
        {
          if (options_.supportPatientStudyOnly_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_GETPatientStudyOnlyQueryRetrieveInformationModel))
        {
          if (options_.supportPatientStudyOnly_ && (! options_.disableGetSupport_)) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_FINDStudyRootQueryRetrieveInformationModel))
        {
          if (options_.supportStudyRoot_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_MOVEStudyRootQueryRetrieveInformationModel))
        {
          if (options_.supportStudyRoot_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_GETStudyRootQueryRetrieveInformationModel))
        {
          if (options_.supportStudyRoot_ && (! options_.disableGetSupport_)) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
        else if (0 == strcmp(nonStorageSyntaxes[i], UID_PrivateShutdownSOPClass))
        {
          if (options_.allowShutdown_) selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        } else {
            selectedNonStorageSyntaxes[numberOfSelectedNonStorageSyntaxes++] = nonStorageSyntaxes[i];
        }
    }

    /*  accept any of the non-storage syntaxes */
    cond = ASC_acceptContextsWithPreferredTransferSyntaxes(
    assoc->params,
    (const char**)selectedNonStorageSyntaxes, numberOfSelectedNonStorageSyntaxes,
    (const char**)transferSyntaxes, nTS);
    if (cond.bad()) {
    DcmQueryRetrieveOptions::errmsg("Cannot accept presentation contexts:");
    DimseCondition::dump(cond);
    }

    /*  accept any of the storage syntaxes */
    if (options_.disableGetSupport_)
    {
      /* accept storage syntaxes with default role only */
      cond = ASC_acceptContextsWithPreferredTransferSyntaxes(
        assoc->params,
        dcmAllStorageSOPClassUIDs, numberOfAllDcmStorageSOPClassUIDs,
        (const char**)transferSyntaxes, nTS);
      if (cond.bad()) {
        DcmQueryRetrieveOptions::errmsg("Cannot accept presentation contexts:");
        DimseCondition::dump(cond);
      }
    } else {
      /* accept storage syntaxes with proposed role */
      T_ASC_PresentationContext pc;
      T_ASC_SC_ROLE role;
      int npc = ASC_countPresentationContexts(assoc->params);
	  
      for (i=0; i<npc; i++)
      {
        ASC_getPresentationContext(assoc->params, i, &pc);
        if (dcmIsaStorageSOPClassUID(pc.abstractSyntax))
        {
          /*
          ** We are prepared to accept whatever role he proposes.
          ** Normally we can be the SCP of the Storage Service Class.
          ** When processing the C-GET operation we can be the SCU of the Storage Service Class.
          */
          role = pc.proposedRole;

          /*
          ** Accept in the order "least wanted" to "most wanted" transfer
          ** syntax.  Accepting a transfer syntax will override previously
          ** accepted transfer syntaxes.
          */
          for (int k=nTS-1; k>=0; k--)
          {
            for (int j=0; j < (int)pc.transferSyntaxCount; j++)
            {
              /* if the transfer syntax was proposed then we can accept it
               * appears in our supported list of transfer syntaxes
               */
              if (strcmp(pc.proposedTransferSyntaxes[j], transferSyntaxes[k]) == 0)
              {
                cond = ASC_acceptPresentationContext(
                    assoc->params, pc.presentationContextID, transferSyntaxes[k], role);
                if (cond.bad()) return cond;
              }
            }
          }
        }
//		else
//			printf("not a storage: %s\r", pc.abstractSyntax);
      } /* for */
	  
	  // NSLog( @"****************************");WARNING NO NSLOG !!! fork() !!!!!
	  
    } /* else */

    /*
     * check if we have negotiated the private "shutdown" SOP Class
     */
    if (0 != ASC_findAcceptedPresentationContextID(assoc, UID_PrivateShutdownSOPClass))
    {
      if (options_.verbose_) {
        printf("Shutting down server ... (negotiated private \"shut down\" SOP class)\n");
      }
      refuseAssociation(&assoc, CTN_NoReason);
      return ASC_SHUTDOWNAPPLICATION;
    }

    /*
     * Refuse any "Storage" presentation contexts to non-writable
     * storage areas.
     
    if (!config_->writableStorageArea(calledAETitle))
    {
      refuseAnyStorageContexts(assoc);
    }
	*/
	
	
    /*
     * Enforce RSNA'93 Demonstration Requirements about only
     * accepting a context for MOVE if a context for FIND is also present.
   

    for (i=0; i<(int)DIM_OF(queryRetrievePairs); i++) {
        movepid = ASC_findAcceptedPresentationContextID(assoc,
        queryRetrievePairs[i].moveSyntax);
        if (movepid != 0) {
        findpid = ASC_findAcceptedPresentationContextID(assoc,
            queryRetrievePairs[i].findSyntax);
        if (findpid == 0) {
        if (options_.requireFindForMove_) {
            // refuse the move 
            ASC_refusePresentationContext(assoc->params,
                movepid, ASC_P_USERREJECTION);
            } else {
            DcmQueryRetrieveOptions::errmsg("WARNING: Move PresCtx but no Find (accepting for now)");
        }
        }
        }
    }
	  */
	  
    /*
     * Enforce an Ad-Hoc rule to limit storage access.
     * If the storage area is "writable" and some other association has
     * already negotiated a "Storage" class presentation context,
     * then refuse any "storage" presentation contexts.
    

    if (options_.refuseMultipleStorageAssociations_)
    {
        if (config_->writableStorageArea(calledAETitle))
        {
          if (processtable_.haveProcessWithWriteAccess(calledAETitle))
          {
            refuseAnyStorageContexts(assoc);
          }
        }
    }
	 */
	 
	 
    return cond;
}


OFCondition DcmQueryRetrieveSCP::waitForAssociation(T_ASC_Network * theNet)
{
    OFCondition cond = EC_Normal;
#ifdef HAVE_FORK
    int                 pid;
#endif
    T_ASC_Association  *assoc = nil;
    char                buf[BUFSIZ];
    int timeout;
    OFBool go_cleanup = OFFalse;
	
	Boolean singleProcess = options_.singleProcess_;
	
//    if( secureConnection_)
//        singleProcess = YES;
    
    if (singleProcess) timeout = 30000;
    else
    {
//      if (processtable_.countChildProcesses() > 0)
//      {
//        timeout = 5;
//      }
//	  else
//	  {
//        timeout = 30000;
//      }
		
	  timeout = 30000;
    }

    if (ASC_associationWaiting(theNet, timeout))
    {
        cond = ASC_receiveAssociation(theNet, &assoc, (int)options_.maxPDU_, NULL, NULL, secureConnection_); // joris added , NULL, NULL, true)
        if (cond.bad())
        {
          if (options_.verbose_)
          {
            DcmQueryRetrieveOptions::errmsg("Failed to receive association:");
            DimseCondition::dump(cond);
          }
          go_cleanup = OFTrue;
        }
    } else return EC_Normal;

	if (! go_cleanup && secureConnection_) // joris
    {
		cond = ASC_setTransportLayerType(assoc->params, secureConnection_);
		if (cond.bad())
		{
			DimseCondition::dump(cond);
			go_cleanup = OFTrue;
		}
    }
	
    if (! go_cleanup)
    {
        if (options_.verbose_)
        {
            time_t t = time(NULL);
            printf("Association Received (%s:%s -> %s) %s",
               assoc->params->DULparams.callingPresentationAddress,
               assoc->params->DULparams.callingAPTitle,
               assoc->params->DULparams.calledAPTitle,
               ctime(&t));
        }

        if (options_.debug_)
        {
          printf("Parameters:\n");
          ASC_dumpParameters(assoc->params, COUT);
        }

        if (options_.refuse_)
        {
            if (options_.verbose_)
            {
                printf("Refusing Association (forced via command line)\n");
            }
            cond = refuseAssociation(&assoc, CTN_NoReason);
            go_cleanup = OFTrue;
        }
    }
	
    if (! go_cleanup)
    {
        /* Application Context Name */
        cond = ASC_getApplicationContextName(assoc->params, buf);
        if (cond.bad() || strcmp(buf, DICOM_STDAPPLICATIONCONTEXT) != 0)
        {
            /* reject: the application context name is not supported */
            if (options_.verbose_)
            {
                DcmQueryRetrieveOptions::errmsg("Bad AppContextName: %s", buf);
            }
            cond = refuseAssociation(&assoc, CTN_BadAppContext);
            go_cleanup = OFTrue;
        }
    }

    if (! go_cleanup)
    {
        /* Implementation Class UID */
        if (options_.rejectWhenNoImplementationClassUID_ && strlen(assoc->params->theirImplementationClassUID) == 0)
        {
            /* reject: no implementation Class UID provided */
            if (options_.verbose_)
            {
                DcmQueryRetrieveOptions::errmsg("No implementation Class UID provided");
            }
            cond = refuseAssociation(&assoc, CTN_NoReason);
            go_cleanup = OFTrue;
        }
    }
	
	if(! go_cleanup)
	{
		if( [BrowserController isHardDiskFull])
		{
			/* reject: no enough memory on the hard disk */
            if (options_.verbose_)
            {
                DcmQueryRetrieveOptions::errmsg("No enough memory on the hard disk");
            }
            cond = refuseAssociation(&assoc, CTN_NoReason);
            go_cleanup = OFTrue;
		}
	}
	
	/* Does peer AE have access to required service ?? */
	/*
    if (! go_cleanup)
    {
        
        if (! config_->peerInAETitle(assoc->params->DULparams.calledAPTitle,
        assoc->params->DULparams.callingAPTitle,
        assoc->params->DULparams.callingPresentationAddress))
        {
            cond = refuseAssociation(&assoc, CTN_BadAEService);
            go_cleanup = OFTrue;
        }
    }
	*/
	
    if (! go_cleanup)
    {
        // too many concurrent associations ??
//        if (processtable_.countChildProcesses() >= OFstatic_cast(size_t, options_.maxAssociations_))
//        {
//            cond = refuseAssociation(&assoc, CTN_TooManyAssociations);
//            go_cleanup = OFTrue;
//        }
    }

    if (! go_cleanup)
    {
        cond = negotiateAssociation(assoc);
		//printf("negotiateAssociation\n");
        if (cond.bad()) go_cleanup = OFTrue;
    }

    if (! go_cleanup)
    {
        cond = ASC_acknowledgeAssociation(assoc);
		//printf("acknowledgeAssociation\n");
        if (cond.bad())
        {
            DimseCondition::dump(cond);
            go_cleanup = OFTrue;
        }
    }
	
    if (! go_cleanup)
    {
		NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
		
		@try
		{
			if (options_.verbose_)
			{
				printf("Association Acknowledged (Max Send PDV: %u)\n", assoc->sendPDVLength);
				if (ASC_countAcceptedPresentationContexts(assoc->params) == 0)
					printf("    (but no valid presentation contexts)\n");
				if (options_.debug_)
					ASC_dumpParameters(assoc->params, COUT);
			}
			
//			if (singleProcess)
//			{
//				@try
//				{
//					@try
//					{
//						/* don't spawn a sub-process to handle the association */
//						cond = handleAssociation(assoc, options_.correctUIDPadding_);
//						assoc = nil;
//					}
//					@catch( NSException *e)
//					{
//                        N2LogExceptionWithStackTrace(e);
//					}
//				}
//				@catch( NSException *e)
//				{
//                    N2LogExceptionWithStackTrace(e);
//				}
//				
//				NSString *str = getErrorMessage();
//				
//				if( str)
//					[[AppController sharedAppController] performSelectorOnMainThread: @selector(displayListenerError:) withObject: str waitUntilDone: NO];
//			}
//            // TEST FOR MULTI-THREAD
//            else
            
            if( cond != ASC_SHUTDOWNAPPLICATION)
            {
                if (singleProcess) // But multi-threaded
                {
                    while( numberOfActiveAssociations > [[NSUserDefaults standardUserDefaults] integerForKey: @"maximumNumberOfConcurrentDICOMAssociations"])
                        [NSThread sleepForTimeInterval: 0.1];
                        
                    @try
                    {
                        NSThread *t = [[[NSThread alloc] initWithTarget: [ContextCleaner class] selector:@selector(handleAssociation:) object: [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithPointer: assoc], @"assoc", [NSValue valueWithPointer: this], @"DcmQueryRetrieveSCP", nil]] autorelease];
                        t.name = NSLocalizedString( @"DICOM Services...", nil);
                        if( assoc && assoc->params && assoc->params->DULparams.callingPresentationAddress)
                            t.status = [NSString stringWithFormat: NSLocalizedString( @"%s", nil), assoc->params->DULparams.callingPresentationAddress];
                        
                        t.supportsCancel = YES;
                        [[ThreadsManager defaultManager] addThreadAndStart: t];
                        
                        assoc = nil;
                    }
                    @catch( NSException *e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
    #ifdef HAVE_FORK
                else
                {
                    NSPersistentStoreCoordinator *dbStoreCoordinator = [[[DicomDatabase defaultDatabase] managedObjectContext] persistentStoreCoordinator];
                    
                    staticContext = [[NSManagedObjectContext alloc] init];
                    staticContext.undoManager = nil;
                    
                    [[DicomDatabase defaultDatabase] save]; // We have to save the sql file: the forked process "sees" only the file, not the store or the context.
                    
                    [dbStoreCoordinator lock];
                    
                    NSManagedObjectModel *model = [dbStoreCoordinator managedObjectModel];
                    
                    staticContext.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model] autorelease];
                    [staticContext.persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: [[DicomDatabase defaultDatabase] sqlFilePath]] options: nil error: nil];
                    
                    @try
                    {
                        // To update the AETitle list : required for C-MOVE SCP
                        [DCMNetServiceDelegate DICOMServersList];
                        
                        /* spawn a sub-process to handle the association */
                        pid = (int)(fork());
                        if (pid < 0)
                        {
                            printf("pid < 0. Cannot spawn new process\n");
                            DcmQueryRetrieveOptions::errmsg("Cannot create association sub-process: %s", strerror(errno));
                            cond = refuseAssociation(&assoc, CTN_CannotFork);
                            go_cleanup = OFTrue;
                        }
                        else if (pid > 0)
                        {
                            [NSThread detachNewThreadSelector: @selector(waitUnlockFileWithPID:) toTarget: [ContextCleaner class] withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: pid], @"pid", [NSValue valueWithPointer:assoc], @"assoc", dbStoreCoordinator, @"dbStoreCoordinator", nil]];
                            
                            [dbStoreCoordinator unlock];
                            
                            // Display a thread in the ThreadsManager for this pid
                            NSThread *t = [[[NSThread alloc] initWithTarget: [AppController sharedAppController] selector:@selector(waitForPID:) object: [NSNumber numberWithInt: pid]] autorelease];
                            t.name = NSLocalizedString( @"DICOM Services...", nil);
                            if( assoc && assoc->params && assoc->params->DULparams.callingPresentationAddress)
                                t.status = [NSString stringWithFormat: NSLocalizedString( @"%s", nil), assoc->params->DULparams.callingPresentationAddress];
                            [[ThreadsManager defaultManager] addThreadAndStart: t];
                        }
                        else
                        {
                            forkedProcess = YES;
                            
                            lockFile();
                            
                            // We are not interested to see crash report for the child process.
                            // It can safely and silently crash (can occur with network broken pipe)
                            
                            signal(SIGINT , silent_exit_on_sig);
                            signal(SIGABRT , silent_exit_on_sig);
                            signal(SIGILL , silent_exit_on_sig);
                            signal(SIGFPE , silent_exit_on_sig);
                            signal(SIGSEGV, silent_exit_on_sig);
                            signal(SIGTERM , silent_exit_on_sig);
                            signal(SIGBUS , silent_exit_on_sig);
                            
                            // Child
                            @try
                            {
                                try
                                {
                                    /* child process, handle the association */
                                    cond = handleAssociation(assoc, options_.correctUIDPadding_);
                                }
                                catch(...)
                                {
                                    printf( "***** C++ exception in %s\r", __PRETTY_FUNCTION__);
                                }
                            }
                            @catch (NSException * e)
                            {
                                N2LogExceptionWithStackTrace(e);
                            }
                            
                            unlockFile();
                            
                            char dir[ 1024];
                            sprintf( dir, "%s-%d", "/tmp/process_state", getpid());
                            unlink( dir);
                            
                            /* the child process is done so exit */
                            _Exit(3);	//to avoid spin_lock
                        }
                    }
                    @catch( NSException *e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                    
                    [staticContext release];
                    staticContext = nil;
                }
            }
            #endif
		}
		@catch (NSException * e)
		{
            N2LogExceptionWithStackTrace(e);
		}
		
		[p release];
    }
	
	if( go_cleanup)
	{
        if( assoc)
        {
            cond = ASC_dropAssociation(assoc);
            if (cond.bad())
            {
                //DcmQueryRetrieveOptions::errmsg("Cannot Drop Association:");
                DimseCondition::dump(cond);
            }
            
            cond = ASC_destroyAssociation(&assoc);
            if (cond.bad())
            {
                //DcmQueryRetrieveOptions::errmsg("Cannot Destroy Association:");
                DimseCondition::dump(cond);
            }
        }
	}
	
    return cond;
}


void DcmQueryRetrieveSCP::cleanChildren(OFBool verbose)
{
//  processtable_.cleanChildren(verbose);
}


void DcmQueryRetrieveSCP::setDatabaseFlags(
  OFBool dbCheckFindIdentifier,
  OFBool dbCheckMoveIdentifier,
  OFBool dbDebug)
{
  dbCheckFindIdentifier_ = dbCheckFindIdentifier;
  dbCheckMoveIdentifier_ = dbCheckMoveIdentifier;
  dbDebug_ = dbDebug;
}


void DcmQueryRetrieveSCP::setSecureConnection(OFBool secureConnection)
{
	secureConnection_ = secureConnection;
}

/*
 * CVS Log
 * $Log: dcmqrsrv.cc,v $
 * Revision 1.1  2006/03/01 20:16:07  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.1  2005/12/16 12:41:35  joergr
 * Renamed file to avoid naming conflicts when linking on SunOS 5.5.1 with
 * Sun CC 2.0.1.
 *
 * Revision 1.7  2005/12/08 15:47:13  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.6  2005/11/29 11:27:20  meichel
 * Added new flag keepDBHandleDuringAssociation_ which allows to determine
 *   whether a DB handle is kept open for a complete association or a single
 *   DIMSE message only. Also improved error handling of file locking.
 *
 * Revision 1.5  2005/11/29 10:54:52  meichel
 * Added minimal support for compressed transfer syntaxes to dcmqrscp.
 *   No on-the-fly decompression is performed, but compressed images can
 *   be stored and retrieved.
 *
 * Revision 1.4  2005/11/17 13:44:40  meichel
 * Added command line options for DIMSE and ACSE timeouts
 *
 * Revision 1.3  2005/10/25 08:56:18  meichel
 * Updated list of UIDs and added support for new transfer syntaxes
 *   and storage SOP classes.
 *
 * Revision 1.2  2005/04/22 15:36:32  meichel
 * Passing calling aetitle to DcmQueryRetrieveDatabaseHandleFactory::createDBHandle
 *   to allow configuration retrieval based on calling aetitle.
 *
 * Revision 1.1  2005/03/30 13:34:53  meichel
 * Initial release of module dcmqrdb that will replace module imagectn.
 *   It provides a clear interface between the Q/R DICOM front-end and the
 *   database back-end. The imagectn code has been re-factored into a minimal
 *   class structure.
 *
 *
 */
