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
 *  Purpose: class DcmQueryRetrieveStoreContext
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:16:07 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmqrdb/dcmqrcbs.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "dcmqrcbs.h"

#include "dcmqrcnf.h"
#include "dcdeftag.h"
#include "dcmqropt.h"
#include "diutil.h"
#include "dcfilefo.h"
#include "dcmqrdbs.h"
#include "dcmqrdbi.h"
#include "dcmetinf.h"

//@interface writeClass : NSObject
//{
//	
//}
//+(void) writeFile: (NSDictionary*) params;
//
//@end
//
//@implementation writeClass
//
//+(void) writeFile: (NSDictionary*) params
//{
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	
//	const char* fname = (const char*) [[params objectForKey: @"fname"] UTF8String];
//	DcmQueryRetrieveOptions *options = (DcmQueryRetrieveOptions*) [[params objectForKey: @"options"] pointerValue];
//	DcmFileFormat *ff = (DcmFileFormat*) [[params objectForKey: @"ff"] pointerValue];
//	E_TransferSyntax xfer = (E_TransferSyntax) [[params objectForKey: @"xfer"] intValue];
//
//	E_TransferSyntax ofer = ff->getDataset()->getOriginalXfer();
//	
//	DcmXfer oType( ofer), xType( xfer);
//	
//	if( (ofer == EXS_JPEG2000LosslessOnly || ofer == EXS_JPEG2000) &&
//	   (xfer == EXS_JPEG2000LosslessOnly || xfer == EXS_JPEG2000))
//		xfer = ff->getDataset()->getOriginalXfer();
//	
//	else if( ofer == xfer)
//		xfer = ff->getDataset()->getOriginalXfer();
//	
//	else if( oType.isEncapsulated() == OFFalse && xType.isEncapsulated() == OFFalse)
//		xfer = xfer;
//	
//	else
//	{
//		if( ff->getDataset()->chooseRepresentation( xfer, NULL) != EC_Normal)
//			xfer = ff->getDataset()->getOriginalXfer();
//	}
//	
//	
//	OFCondition cond = ff->saveFile(fname, xfer, options->sequenceType_, 
//									options->groupLength_, options->paddingType_, (Uint32)options->filepad_, 
//									(Uint32)options->itempad_, (!options->useMetaheader_));
//	
//	if (cond.bad())
//	{
//		fprintf(stderr, "storescp: Cannot write image file: %s\n", fname);
//		DimseCondition::dump(cond);
////		rsp->DimseStatus = STATUS_STORE_Refused_OutOfResources;
//	}
//	
//	[pool release];
//}
//
//@end

int gPutDstAETitleInPrivateInformationCreatorUID = 0, gPutSrcAETitleInSourceApplicationEntityTitle = 0;

void DcmQueryRetrieveStoreContext::updateDisplay(T_DIMSE_StoreProgress * progress)
{
  if (options_.verbose_)
  {
    switch (progress->state)
    {
      case DIMSE_StoreBegin:
        printf("RECV:");
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


void DcmQueryRetrieveStoreContext::saveImageToDB(
    T_DIMSE_C_StoreRQ *req,             /* original store request */
    const char *imageFileName,
    /* out */
    T_DIMSE_C_StoreRSP *rsp,            /* final store response */
    DcmDataset **stDetail)
{
    OFCondition dbcond = EC_Normal;
    DcmQueryRetrieveDatabaseStatus dbStatus(STATUS_Success);
    
    /* Store image */
    if (options_.ignoreStoreData_) {
        rsp->DimseStatus = STATUS_Success;
        *stDetail = NULL;
        return; /* nothing else to do */
    }
    
    if (status == STATUS_Success)
    {    
        dbcond = dbHandle.storeRequest(
            req->AffectedSOPClassUID, req->AffectedSOPInstanceUID,
            imageFileName, &dbStatus);
        if (dbcond.bad())
        {
            DcmQueryRetrieveOptions::errmsg("storeSCP: Database: storeRequest Failed (%s)",
               DU_cstoreStatusString(dbStatus.status()));
            DimseCondition::dump(dbcond);
        }
        status = dbStatus.status();
    }

    rsp->DimseStatus = status;
    *stDetail = dbStatus.extractStatusDetail();
}

void DcmQueryRetrieveStoreContext::writeToFile(
    DcmFileFormat *ff,
    const char* fname,
    T_DIMSE_C_StoreRSP *rsp)
{
	
	E_TransferSyntax xfer = ff->getDataset()->getOriginalXfer();
	
	OFCondition cond = ff->saveFile(fname, xfer, options_.sequenceType_, 
									options_.groupLength_, options_.paddingType_, (Uint32)options_.filepad_, 
									(Uint32)options_.itempad_, (!options_.useMetaheader_));
	
	if (cond.bad())
	{
		fprintf(stderr, "storescp: Cannot write image file: %s\n", fname);
		DimseCondition::dump(cond);
		rsp->DimseStatus = STATUS_STORE_Refused_OutOfResources;
	}
	
//    E_TransferSyntax xfer = options_.writeTransferSyntax_;
//    if (xfer == EXS_Unknown)
//	{
//		xfer = ff->getDataset()->getOriginalXfer();
//		
//		OFCondition cond = ff->saveFile(fname, xfer, options_.sequenceType_, 
//			options_.groupLength_, options_.paddingType_, (Uint32)options_.filepad_, 
//			(Uint32)options_.itempad_, (!options_.useMetaheader_));
//		
//		if (cond.bad())
//		{
//		  fprintf(stderr, "storescp: Cannot write image file: %s\n", fname);
//		  DimseCondition::dump(cond);
//		  rsp->DimseStatus = STATUS_STORE_Refused_OutOfResources;
//		}
//	}
//	else
//	{
//		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//		
//		NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithPointer: ff->clone()], @"ff", [NSString stringWithUTF8String: fname], @"fname", [NSNumber numberWithInt: xfer], @"xfer", [NSValue valueWithPointer: &options_], @"options", nil];
//	
//		[NSThread detachNewThreadSelector: @selector(writeFile:) toTarget: [writeClass class] withObject: params];
//		
//		[pool release];
//	}
}

void DcmQueryRetrieveStoreContext::checkRequestAgainstDataset(
    T_DIMSE_C_StoreRQ *req,   
															  /* original store request */
    const char* fname,          /* filename of dataset */
    DcmDataset *dataSet,        /* dataset to check */
    T_DIMSE_C_StoreRSP *rsp,    /* final store response */
    OFBool uidPadding)          /* correct UID passing */
{
    DcmFileFormat ff;

    if (dataSet == NULL)
    {
      ff.loadFile(fname);
      dataSet = ff.getDataset();
    }

    /* which SOP class and SOP instance ? */
    DIC_UI sopClass;
    DIC_UI sopInstance;
    
    if (!DU_findSOPClassAndInstanceInDataSet(dataSet, sopClass, sopInstance, uidPadding)) 
    {
        DcmQueryRetrieveOptions::errmsg("Bad image file: %s", fname);
        rsp->DimseStatus = STATUS_STORE_Error_CannotUnderstand;
    } else if (strcmp(sopClass, req->AffectedSOPClassUID) != 0) {
        rsp->DimseStatus = STATUS_STORE_Error_DataSetDoesNotMatchSOPClass;
    } else if (strcmp(sopInstance, req->AffectedSOPInstanceUID) != 0) {
        rsp->DimseStatus = STATUS_STORE_Error_DataSetDoesNotMatchSOPClass;
    }
}

void DcmQueryRetrieveStoreContext::callbackHandler(
    /* in */
    T_DIMSE_StoreProgress *progress,    /* progress state */
    T_DIMSE_C_StoreRQ *req,             /* original store request */
    char *imageFileName,
    char *sourceAETitle,
    char *destinationAETitle,
    DcmDataset **imageDataSet, /* being received into */
    /* out */
    T_DIMSE_C_StoreRSP *rsp,            /* final store response */
    DcmDataset **stDetail)
{
    updateDisplay(progress);

    if (progress->state == DIMSE_StoreEnd) {
		/*
        if (!options_.ignoreStoreData_ && rsp->DimseStatus == STATUS_Success) {
            if ((imageDataSet)&&(*imageDataSet)) {
                checkRequestAgainstDataset(req, NULL, *imageDataSet, rsp, correctUIDPadding);
            } else {
                checkRequestAgainstDataset(req, imageFileName, NULL, rsp, correctUIDPadding);
            }
        }
		*/
        if (!options_.ignoreStoreData_ && rsp->DimseStatus == STATUS_Success) {
            if ((imageDataSet)&&(*imageDataSet))
			{
                DcmMetaInfo *metaInfo = dcmff->getMetaInfo();
                if( metaInfo)
                {
                    if( gPutSrcAETitleInSourceApplicationEntityTitle)
                    {
                        if( sourceAETitle)
                            metaInfo->putAndInsertString( DCM_SourceApplicationEntityTitle, sourceAETitle);
                    }
                    
                    if( gPutDstAETitleInPrivateInformationCreatorUID)
                    {
                        if( destinationAETitle)
                            metaInfo->putAndInsertString( DCM_PrivateInformationCreatorUID, destinationAETitle);
                    }
                }
                
				writeToFile(dcmff, fileName, rsp);
            }
            if (rsp->DimseStatus == STATUS_Success)
			{
                saveImageToDB(req, fileName, rsp, stDetail);
            }
        }

        if (options_.verbose_) {
            printf("Sending:\n");
            DIMSE_printCStoreRSP(stdout, rsp);
        } else if (rsp->DimseStatus != STATUS_Success) {
            fprintf(stdout, "NOTICE: StoreSCP:\n");
            DIMSE_printCStoreRSP(stdout, rsp);
        }
        status = rsp->DimseStatus;
    }
}


/*
 * CVS Log
 * $Log: dcmqrcbs.cc,v $
 * Revision 1.1  2006/03/01 20:16:07  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.3  2005/12/15 12:38:06  joergr
 * Removed naming conflicts.
 *
 * Revision 1.2  2005/12/08 15:47:07  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.1  2005/03/30 13:34:53  meichel
 * Initial release of module dcmqrdb that will replace module imagectn.
 *   It provides a clear interface between the Q/R DICOM front-end and the
 *   database back-end. The imagectn code has been re-factored into a minimal
 *   class structure.
 *
 *
 */
