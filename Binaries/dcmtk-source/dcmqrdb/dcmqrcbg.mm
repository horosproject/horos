/*
 *
 *  Copyright (C) 1993-2005, OFFIS
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
 *  Module:  dcmqrdb
 *
 *  Author:  Marco Eichelberg
 *
 *  Purpose: class DcmQueryRetrieveGetContext
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:16:07 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmqrdb/dcmqrcbg.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#include <Cocoa/Cocoa.h>
#include"OsiriX/DCMNetServiceDelegate.h"
#import "SendController.h"
#import "browserController.h"
#import "OsiriX/DCMObject.h"
#import "OsiriX/DCM.h"
#import "OsiriX/DCMTransferSyntax.h"


#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "dcmqrcbg.h"

#include "dcmqrcnf.h"
#include "dcdeftag.h"
#include "dcmqropt.h"
#include "diutil.h"
#include "dcfilefo.h"
#include "dcmqrdbs.h"
#include "dcmqrdbi.h"


#include "ofstring.h"
#include "dimse.h"
#include "diutil.h"
#include "dcdatset.h"
#include "dcmetinf.h"
#include "dcfilefo.h"
#include "dcdebug.h"
#include "dcuid.h"
#include "dcdict.h"
#include "dcdeftag.h"

#include "ofconapp.h"
#include "dcuid.h"     /* for dcmtk version name */
#include "dicom.h"     /* for DICOM_APPLICATION_REQUESTOR */
#include "dcostrmz.h"  /* for dcmZlibCompressionLevel */
#include "dcasccfg.h"  /* for class DcmAssociationConfiguration */
#include "dcasccff.h"  /* for class DcmAssociationConfigurationFile */


#include "djdecode.h"  /* for dcmjpeg decoders */
#include "djencode.h"  /* for dcmjpeg encoders */
#include "dcrledrg.h"  /* for DcmRLEDecoderRegistration */
#include "dcrleerg.h"  /* for DcmRLEEncoderRegistration */
#include "djrploss.h"
#include "djrplol.h"
#include "dcpixel.h"
#include "dcrlerp.h"


BEGIN_EXTERN_C
#ifdef HAVE_FCNTL_H
#include <fcntl.h>       /* needed on Solaris for O_RDONLY */
#endif
END_EXTERN_C

extern OFCondition decompressFileFormat(DcmFileFormat fileformat, const char *fname);
extern OFBool compressFileFormat(DcmFileFormat fileformat, const char *fname, char *outfname, E_TransferSyntax newXfer);

static OFCondition
getTransferSyntax(T_ASC_Association * assoc, 
        T_ASC_PresentationContextID pid,
        E_TransferSyntax *xferSyntax)
    /*
     * This function checks if the presentation context id which was passed refers to a valid presentation
     * context. If this is the case, this function determines the transfer syntax the presentation context ID
     * refers to (will be returned to the user) and also checks if dcmtk supports this transfer syntax.
     *
     * Parameters:
     *   assoc      - [in] The association (network connection to another DICOM application).
     *   pid        - [in] The id of the presentation context which shall be checked regarding validity.
     *   xferSyntax - [out] If pid refers to a valuid presentation context, this variable contains in the
     *                     end the transfer syntax which is specified in the presentation context.
     */
{
    T_ASC_PresentationContext pc;
    char *ts = NULL;

    /* figure out if is this a valid presentation context */
    OFCondition cond = ASC_findAcceptedPresentationContext(assoc->params, pid, &pc);
    if (cond.bad())
    {
        return makeDcmnetSubCondition(DIMSEC_RECEIVEFAILED, OF_error, "DIMSE Failed to receive message", cond);
    }

    /* determine the transfer syntax which is specified in the presentation context */
    ts = pc.acceptedTransferSyntax;
    
    /* create a DcmXfer object on the basis of the transfer syntax which was determined above */
    DcmXfer xfer(ts);

    /* check if the transfer syntax is supported by dcmtk */
    *xferSyntax = xfer.getXfer();
    switch (*xferSyntax)
    {
        case EXS_LittleEndianImplicit:
        case EXS_LittleEndianExplicit:
        case EXS_BigEndianExplicit:
        case EXS_JPEGProcess1TransferSyntax:
        case EXS_JPEGProcess2_4TransferSyntax:
        case EXS_JPEGProcess3_5TransferSyntax:
        case EXS_JPEGProcess6_8TransferSyntax:
        case EXS_JPEGProcess7_9TransferSyntax:
        case EXS_JPEGProcess10_12TransferSyntax:
        case EXS_JPEGProcess11_13TransferSyntax:
        case EXS_JPEGProcess14TransferSyntax:
        case EXS_JPEGProcess15TransferSyntax:
        case EXS_JPEGProcess16_18TransferSyntax:
        case EXS_JPEGProcess17_19TransferSyntax:
        case EXS_JPEGProcess20_22TransferSyntax:
        case EXS_JPEGProcess21_23TransferSyntax:
        case EXS_JPEGProcess24_26TransferSyntax:
        case EXS_JPEGProcess25_27TransferSyntax:
        case EXS_JPEGProcess28TransferSyntax:
        case EXS_JPEGProcess29TransferSyntax:
        case EXS_JPEGProcess14SV1TransferSyntax:
        case EXS_RLELossless:
        case EXS_JPEGLSLossless:
        case EXS_JPEGLSLossy:
        case EXS_JPEG2000LosslessOnly:
        case EXS_JPEG2000:
        case EXS_MPEG2MainProfileAtMainLevel:
        case EXS_JPEG2000MulticomponentLosslessOnly:
        case EXS_JPEG2000Multicomponent:        	
#ifdef WITH_ZLIB
        case EXS_DeflatedLittleEndianExplicit:
#endif
        /* OK, these can be supported */
        break;
    default:
        /* all other transfer syntaxes are not supported; hence, set the error indicator variable */
        {
          char buf[256];
          sprintf(buf, "DIMSE Unsupported transfer syntax: %s", ts);
          OFCondition subCond = makeDcmnetCondition(DIMSEC_UNSUPPORTEDTRANSFERSYNTAX, OF_error, buf);
          cond = makeDcmnetSubCondition(DIMSEC_RECEIVEFAILED, OF_error, "DIMSE Failed to receive message", subCond);
        }
        break;
    }

    /* return result value */
    return cond;
}


static void getSubOpProgressCallback(void * callbackData, 
    T_DIMSE_StoreProgress *progress,
    T_DIMSE_C_StoreRQ * /*req*/)
{
  DcmQueryRetrieveGetContext *context = OFstatic_cast(DcmQueryRetrieveGetContext *, callbackData);
  if (context->isVerbose())
  {
    switch (progress->state)
    {
      case DIMSE_StoreBegin:
        printf("XMIT:");
        break;
      case DIMSE_StoreEnd:
        printf("\n");
        break;
      default:
        putchar('.');
        break;
    }
    fflush(stdout);
  }
}

OFBool DcmQueryRetrieveGetContext::isVerbose() const 
{ 
  return options_.verbose_ ? OFTrue : OFFalse;
}

void DcmQueryRetrieveGetContext::callbackHandler(
	/* in */ 
	OFBool cancelled, T_DIMSE_C_GetRQ *request, 
	DcmDataset *requestIdentifiers, int responseCount,
	/* out */
	T_DIMSE_C_GetRSP *response, DcmDataset **stDetail,	
	DcmDataset **responseIdentifiers)
{
    OFCondition dbcond = EC_Normal;
    DcmQueryRetrieveDatabaseStatus dbStatus(priorStatus);

    if (responseCount == 1) {
        /* start the database search */
	if (options_.verbose_) {
	    printf("Get SCP Request Identifiers:\n");
	    requestIdentifiers->print(COUT);
        }
        dbcond = dbHandle.startMoveRequest(
	    request->AffectedSOPClassUID, requestIdentifiers, &dbStatus);
        if (dbcond.bad()) {
	    DcmQueryRetrieveOptions::errmsg("getSCP: Database: startMoveRequest Failed (%s):",
		DU_cmoveStatusString(dbStatus.status()));
        }
    }
    
    /* only cancel if we have pending status */
    if (cancelled && dbStatus.status() == STATUS_Pending) {
	dbHandle.cancelMoveRequest(&dbStatus);
    }

    if (dbStatus.status() == STATUS_Pending) {
        getNextImage(&dbStatus);
    }

    if (dbStatus.status() != STATUS_Pending) {

	/*
	 * Need to adjust the final status if any sub-operations failed or
	 * had warnings 
	 */
	if (nFailed > 0 || nWarning > 0) {
	    dbStatus.setStatus(STATUS_GET_Warning_SubOperationsCompleteOneOrMoreFailures);
	}
        /*
         * if all the sub-operations failed then we need to generate a failed or refused status.
         * cf. DICOM part 4, C.4.3.3.1
         * we choose to generate a "Refused - Out of Resources - Unable to perform suboperations" status.
         */
        if ((nFailed > 0) && ((nCompleted + nWarning) == 0)) {
	    dbStatus.setStatus(STATUS_GET_Refused_OutOfResourcesSubOperations);
	}
    }
    
    if (options_.verbose_) {
        printf("Get SCP Response %d [status: %s]\n", responseCount,
	    DU_cmoveStatusString(dbStatus.status()));
    }

    if (dbStatus.status() != STATUS_Success && 
        dbStatus.status() != STATUS_Pending) {
	/* 
	 * May only include response identifiers if not Success 
	 * and not Pending 
	 */
	buildFailedInstanceList(responseIdentifiers);
    }

    /* set response status */
    response->DimseStatus = dbStatus.status();
    response->NumberOfRemainingSubOperations = nRemaining;
    response->NumberOfCompletedSubOperations = nCompleted;
    response->NumberOfFailedSubOperations = nFailed;
    response->NumberOfWarningSubOperations = nWarning;
    *stDetail = dbStatus.extractStatusDetail();
    
}

void DcmQueryRetrieveGetContext::addFailedUIDInstance(const char *sopInstance)
{
    int len;

    if (failedUIDs == NULL) {
	if ((failedUIDs = (char*)malloc(DIC_UI_LEN+1)) == NULL) {
	    DcmQueryRetrieveOptions::errmsg("malloc failure: addFailedUIDInstance");
	    return;
	}
	strcpy(failedUIDs, sopInstance);
    } else {
	len = strlen(failedUIDs);
	if ((failedUIDs = (char*)realloc(failedUIDs, 
	    (len+strlen(sopInstance)+2))) == NULL) {
	    DcmQueryRetrieveOptions::errmsg("realloc failure: addFailedUIDInstance");
	    return;
	}
	/* tag sopInstance onto end of old with '\' between */
	strcat(failedUIDs, "\\");
	strcat(failedUIDs, sopInstance);
    }
}

OFCondition DcmQueryRetrieveGetContext::performGetSubOp(DIC_UI sopClass, DIC_UI sopInstance, char *fname)
{
    OFCondition cond = EC_Normal;
    T_DIMSE_C_StoreRQ req;
    T_DIMSE_C_StoreRSP rsp;
    DIC_US msgId;
    T_ASC_PresentationContextID presId;
    DcmDataset *stDetail = NULL;
	
#ifdef LOCK_IMAGE_FILES
    /* shared lock image file */
    int lockfd;
#ifdef O_BINARY
    lockfd = open(fname, O_RDONLY | O_BINARY, 0666);
#else
    lockfd = open(fname, O_RDONLY , 0666);
#endif
    if (lockfd < 0) {
        /* due to quota system the file could have been deleted */
	DcmQueryRetrieveOptions::errmsg("Get SCP: storeSCU: [file: %s]: %s", 
	    fname, strerror(errno));
	nFailed++;
	addFailedUIDInstance(sopInstance);
	return EC_Normal;
    }
    dcmtk_flock(lockfd, LOCK_SH);
#endif
	
    msgId = origAssoc->nextMsgID++;
	
    /* which presentation context should be used */
    presId = ASC_findAcceptedPresentationContextID(origAssoc, sopClass);	//ANRGET sopClass / UID_GETStudyRootQueryRetrieveInformationModel
    if (presId == 0)
	{
		nFailed++;
		addFailedUIDInstance(sopInstance);
		DcmQueryRetrieveOptions::errmsg("Get SCP: storeSCU: [file: %s] No presentation context for: (%s) %s", fname, dcmSOPClassUIDToModality(sopClass), sopClass);
		return DIMSE_NOVALIDPRESENTATIONCONTEXTID;
    }
	
    req.MessageID = msgId;
    strcpy(req.AffectedSOPClassUID, sopClass);
    strcpy(req.AffectedSOPInstanceUID, sopInstance);
    req.DataSetType = DIMSE_DATASET_PRESENT;
    req.Priority = priority;
    req.opts = 0;

    if (options_.verbose_) {
	printf("Store SCU RQ: MsgID %d, (%s)\n", 
	    msgId, dcmSOPClassUIDToModality(sopClass));
    }

    cond = DIMSE_storeUser(origAssoc, presId, &req,
        fname, NULL, getSubOpProgressCallback, this, options_.blockMode_, options_.dimse_timeout_, 
	&rsp, &stDetail);

#ifdef LOCK_IMAGE_FILES
    /* unlock image file */
    dcmtk_flock(lockfd, LOCK_UN);
    close(lockfd);
#endif

    if (cond.good())
	{
        if (options_.verbose_) {
	    printf("Get SCP: Received Store SCU RSP [Status=%s]\n",
	        DU_cstoreStatusString(rsp.DimseStatus));
        }
	if (rsp.DimseStatus == STATUS_Success) {
	    /* everything ok */
	    nCompleted++;
	} else if ((rsp.DimseStatus & 0xf000) == 0xb000) {
	    /* a warning status message */
	    nWarning++;
	    DcmQueryRetrieveOptions::errmsg("Get SCP: Store Warning: Response Status: %s", 
		DU_cstoreStatusString(rsp.DimseStatus));
        } else {
	    nFailed++;
	    addFailedUIDInstance(sopInstance);
	    /* print a status message */
	    DcmQueryRetrieveOptions::errmsg("Get SCP: Store Failed: Response Status: %s", 
		DU_cstoreStatusString(rsp.DimseStatus));
	}
    } else {
	nFailed++;
	addFailedUIDInstance(sopInstance);
	DcmQueryRetrieveOptions::errmsg("Get SCP: storeSCU: Store Request Failed:");
	DimseCondition::dump(cond);
    }
    if (stDetail) {
        if (options_.verbose_) {
	    printf("  Status Detail:\n");
	    stDetail->print(COUT);
	}
        delete stDetail;
    }
    return cond;
}

static int seed = 0;

void DcmQueryRetrieveGetContext::getNextImage(DcmQueryRetrieveDatabaseStatus * dbStatus)
{
    OFCondition cond = EC_Normal;
    OFCondition dbcond = EC_Normal;
    DIC_UI subImgSOPClass;	/* sub-operation image SOP Class */
    DIC_UI subImgSOPInstance;	/* sub-operation image SOP Instance */
    char subImgFileName[MAXPATHLEN + 1];	/* sub-operation image file */

    /* clear out strings */
    bzero(subImgFileName, sizeof(subImgFileName));
    bzero(subImgSOPClass, sizeof(subImgSOPClass));
    bzero(subImgSOPInstance, sizeof(subImgSOPInstance));

    /* get DB response */
    dbcond = dbHandle.nextMoveResponse( subImgSOPClass, subImgSOPInstance, subImgFileName, &nRemaining, dbStatus);
	
    if (dbcond.bad())
	{
		DcmQueryRetrieveOptions::errmsg("getSCP: Database: nextMoveResponse Failed (%s):", DU_cmoveStatusString(dbStatus->status()));
    }

	E_TransferSyntax xferSyntax;
	T_ASC_PresentationContextID presId;
	char outfname[ 4096];
	
	strcpy( outfname, "");
	sprintf( outfname, "%s/QR-CGET-%d-%d.dcm", [[BrowserController currentBrowser] cfixedTempNoIndexDirectory], seed++, getpid());
	unlink( outfname);
	
	presId = ASC_findAcceptedPresentationContextID(origAssoc, subImgSOPClass);
	cond = getTransferSyntax(origAssoc, presId, &xferSyntax);

	if (cond.good())
	{
		DcmFileFormat fileformat;
		cond = fileformat.loadFile( subImgFileName);
	
		/* figure out which of the accepted presentation contexts should be used */
		E_TransferSyntax originalXFer = fileformat.getDataset()->getOriginalXfer();
		DcmXfer filexfer( originalXFer);
		
		//on the fly conversion:
		
		DcmXfer preferredXfer( xferSyntax);
		OFBool status = YES;
		
		sprintf( outfname, "%s/QR-CGET-%d-%d.dcm", [[BrowserController currentBrowser] cfixedTempNoIndexDirectory], seed++, getpid());
		unlink( outfname);
		
		if (filexfer.isNotEncapsulated() && preferredXfer.isNotEncapsulated())
		{
			// do nothing
		}
		else if (filexfer.isNotEncapsulated() && preferredXfer.isEncapsulated())
		{
			status = compressFileFormat(fileformat, subImgFileName, outfname, xferSyntax);
			
			if( status)
				strcpy( subImgFileName, outfname);
		}
		else if (filexfer.isEncapsulated() && preferredXfer.isEncapsulated())
		{
			// The file is already compressed, we will re-compress the file.....
			if( strcmp( filexfer.getXferID(), preferredXfer.getXferID()) != 0)
			{
				if( (filexfer.getXfer() == EXS_JPEG2000LosslessOnly && preferredXfer.getXfer() == EXS_JPEG2000) ||
				   (filexfer.getXfer() == EXS_JPEG2000 && preferredXfer.getXfer() == EXS_JPEG2000LosslessOnly))
				{
					// Switching from JPEG2000 <-> JPEG2000Lossless : we only change the transfer syntax....
					printf( "JPEG2000 <-> JPEG2000Lossless switch\n");
					status = compressFileFormat(fileformat, subImgFileName, outfname, xferSyntax);
					
					if( status)
						strcpy( subImgFileName, outfname);
				}
                else if( (filexfer.getXfer() == EXS_JPEGLSLossless && preferredXfer.getXfer() == EXS_JPEGLSLossy) ||
				   (filexfer.getXfer() == EXS_JPEGLSLossy && preferredXfer.getXfer() == EXS_JPEGLSLossless))
				{
					// Switching from EXS_JPEGLSLossy <-> EXS_JPEGLSLossless : we only change the transfer syntax....
					printf( "EXS_JPEGLSLossy <-> EXS_JPEGLSLossless switch\n");
					status = compressFileFormat(fileformat, subImgFileName, outfname, xferSyntax);
					
					if( status)
						strcpy( subImgFileName, outfname);
				}
				else
				{
					printf("---- Warning! I'm recompressing files that are already compressed, you should optimize your ts parameters to avoid this: presentation for syntax:%s -> %s\n", dcmFindNameOfUID( filexfer.getXferID()), dcmFindNameOfUID( preferredXfer.getXferID()));
					cond = decompressFileFormat(fileformat, subImgFileName);
					
					DcmFileFormat fileformatDecompress;
					cond = fileformatDecompress.loadFile( subImgFileName);
					
					status = compressFileFormat( fileformatDecompress, subImgFileName, outfname, xferSyntax);
					
					if( status)
						strcpy( subImgFileName, outfname);
				}
			}
		}
		else if (filexfer.isEncapsulated() && preferredXfer.isNotEncapsulated())
		{
			cond = decompressFileFormat(fileformat, subImgFileName);
		}
	}
	
    if (dbStatus->status() == STATUS_Pending)
	{
		/* perform sub-op */
		cond = performGetSubOp(subImgSOPClass, subImgSOPInstance, subImgFileName);

        if (getCancelled)
		{
            dbStatus->setStatus(STATUS_GET_Cancel_SubOperationsTerminatedDueToCancelIndication);
            if (options_.verbose_)
			{
				printf("Get SCP: Received C-Cancel RQ\n");
            }
       }

        if (cond != EC_Normal)
		{
			DcmQueryRetrieveOptions::errmsg("getSCP: Get Sub-Op Failed:");
			DimseCondition::dump(cond);
	    	/* clear condition stack */
		}
	
		if( strlen( outfname) > 0)
			unlink( outfname);
    }
}

void DcmQueryRetrieveGetContext::buildFailedInstanceList(DcmDataset ** rspIds)
{
    OFBool ok;

    if (failedUIDs != NULL) {
	*rspIds = new DcmDataset();
	ok = DU_putStringDOElement(*rspIds, DCM_FailedSOPInstanceUIDList,
	    failedUIDs);
	if (!ok) {
	    DcmQueryRetrieveOptions::errmsg("getSCP: failed to build DCM_FailedSOPInstanceUIDList");
	}
	free(failedUIDs);
	failedUIDs = NULL;
    }
}


/*
 * CVS Log
 * $Log: dcmqrcbg.cc,v $
 * Revision 1.1  2006/03/01 20:16:07  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.5  2005/12/08 15:47:05  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.4  2005/11/17 13:44:40  meichel
 * Added command line options for DIMSE and ACSE timeouts
 *
 * Revision 1.3  2005/06/16 08:02:43  meichel
 * Added system include files needed on Solaris
 *
 * Revision 1.2  2005/04/04 14:23:21  meichel
 * Renamed application "dcmqrdb" into "dcmqrscp" to avoid name clash with
 *   dcmqrdb library, which confuses the MSVC build system.
 *
 * Revision 1.1  2005/03/30 13:34:53  meichel
 * Initial release of module dcmqrdb that will replace module imagectn.
 *   It provides a clear interface between the Q/R DICOM front-end and the
 *   database back-end. The imagectn code has been re-factored into a minimal
 *   class structure.
 *
 *
 */
