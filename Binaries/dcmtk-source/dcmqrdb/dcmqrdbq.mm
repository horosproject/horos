//
//  dcmqrdbq.m
//  OsiriX
//
//  Created by Lance Pysher on 3/19/06.

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
#import "browserController.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

BEGIN_EXTERN_C
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
END_EXTERN_C

#define INCLUDE_CCTYPE
#define INCLUDE_CSTDARG
#include "ofstdinc.h"

#include "dcmqrdbs.h"
// #include "dcmqrdbi.h"
#include "dcmqrcnf.h"

#include "dcmqridx.h"
#include "diutil.h"
#include "dcfilefo.h"
#include "ofstd.h"


#import "dcmqrdbq.h"

const OFConditionConst DcmQROsiriXDatabaseErrorC(OFM_imagectn, 0x001, OF_error, "DcmQR Index Database Error");
const OFCondition DcmQROsiriXDatabaseError(DcmQROsiriXDatabaseErrorC);


OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::pruneInvalidRecords()
{
    return (EC_Normal) ;
}




/************************************
				FIND
**************************************/

/********************
**      Get next find response in Database
 */

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::nextFindResponse (
                DcmDataset      **findResponseIdentifiers,
                DcmQueryRetrieveDatabaseStatus  *status)
		
{
	return DcmQROsiriXDatabaseError;
}

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::startFindRequest(
                const char      *SOPClassUID,
                DcmDataset      *findRequestIdentifiers,
                DcmQueryRetrieveDatabaseStatus  *status)
{
	return DcmQROsiriXDatabaseError;
}

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::cancelFindRequest (DcmQueryRetrieveDatabaseStatus *status)
{
	return DcmQROsiriXDatabaseError;
}

/************************************
			MOVE
**************************************/

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::nextMoveResponse(
                char            *SOPClassUID,
                char            *SOPInstanceUID,
                char            *imageFileName,
                unsigned short  *numberOfRemainingSubOperations,
                DcmQueryRetrieveDatabaseStatus  *status)
{
	return DcmQROsiriXDatabaseError;
}

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::startMoveRequest(
        const char      *SOPClassUID,
        DcmDataset      *moveRequestIdentifiers,
        DcmQueryRetrieveDatabaseStatus  *status)
{
	return DcmQROsiriXDatabaseError;
}

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::cancelMoveRequest (DcmQueryRetrieveDatabaseStatus *status)
{
	return DcmQROsiriXDatabaseError;
}



/***********************
 *      Creates a handle
 */

DcmQueryRetrieveOsiriXDatabaseHandle::DcmQueryRetrieveOsiriXDatabaseHandle(
    const char *storageArea,
    OFCondition& result)
:handle(NULL)
, quotaSystemEnabled(OFFalse)
, doCheckFindIdentifier(OFFalse)
, doCheckMoveIdentifier(OFFalse)
, fnamecreator()
, debugLevel(0)
{

    handle = (DB_Private_Handle *) malloc ( sizeof(DB_Private_Handle) );

#ifdef DEBUG
    dbdebug(1, "DB_createHandle () : Handle created for %s\n",storageArea);
    dbdebug(1, "                     maxStudiesPerStorageArea: %ld maxBytesPerStudy: %ld\n",
            maxStudiesPerStorageArea, maxBytesPerStudy);
#endif

    if (handle) {
        sprintf (handle -> storageArea,"%s", storageArea);
		handle -> idxCounter = -1;
		handle -> findRequestList = NULL;
		handle -> findResponseList = NULL;
		//handle -> maxBytesPerStudy = 0;
		//handle -> maxStudiesAllowed = maxStudiesPerStorageArea;
		handle -> uidList = NULL;
		result = EC_Normal;
	}
	else
		result = DcmQROsiriXDatabaseError;
	return;
}

/***********************
 *      Destroys a handle
 */

DcmQueryRetrieveOsiriXDatabaseHandle::~DcmQueryRetrieveOsiriXDatabaseHandle()
{
    int closeresult;

    if (handle)
    {


      /* Free lists */
     // DB_FreeElementList (handle -> findRequestList);
     // DB_FreeElementList (handle -> findResponseList);
    //  DB_FreeUidList (handle -> uidList);

      free ( (char *)(handle) );
    }
}

/**********************************
 *      Provides a storage filename
 *********************************/

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::makeNewStoreFileName(
                const char      *SOPClassUID,
                const char      * /* SOPInstanceUID */ ,
                char            *newImageFileName)
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *dstFolder = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"INCOMING"];
    OFString filename;
    char prefix[12];

    const char *m = dcmSOPClassUIDToModality(SOPClassUID);
    if (m==NULL) m = "XX";
    sprintf(prefix, "%s_", m);
    // unsigned int seed = fnamecreator.hashString(SOPInstanceUID);
    unsigned int seed = (unsigned int)time(NULL);
    newImageFileName[0]=0; // return empty string in case of error
    if (! fnamecreator.makeFilename(seed, handle->storageArea, prefix, ".dcm", filename)) return DcmQROsiriXDatabaseError;
//  if (! fnamecreator.makeFilename(seed, [dstFolder UTF8String], prefix, ".dcm", filename)) return DcmQRIndexDatabaseError;
	printf("newFileName: %s", filename.c_str());
    strcpy(newImageFileName, filename.c_str());
	[pool release];
    return EC_Normal;
}

OFCondition DcmQueryRetrieveOsiriXDatabaseHandle::storeRequest(
      const char *SOPClassUID,
      const char *SOPInstanceUID,
      const char *imageFileName,
      DcmQueryRetrieveDatabaseStatus  *status,
      OFBool     isNew){
	  
 return EC_Normal;
}

/* ========================= UTILS ========================= */


const char *DcmQueryRetrieveOsiriXDatabaseHandle::getStorageArea() const
{
  return handle->storageArea;
}

const char *DcmQueryRetrieveOsiriXDatabaseHandle::getIndexFilename() const
{
  return handle->indexFilename;
}

void DcmQueryRetrieveOsiriXDatabaseHandle::setDebugLevel(int dLevel)
{
    debugLevel = dLevel;
}

int DcmQueryRetrieveOsiriXDatabaseHandle::getDebugLevel() const
{
    return debugLevel;
}

void DcmQueryRetrieveOsiriXDatabaseHandle::dbdebug(int level, const char* format, ...) const
{
    va_list ap;
    char buf[4096]; /* we hope a message never gets larger */

    if (level <= debugLevel) {
        CERR << "DB:";
        va_start(ap, format);
        vsprintf(buf, format, ap);
        va_end(ap);
        CERR << buf << endl;
    }
}


void DcmQueryRetrieveOsiriXDatabaseHandle::setIdentifierChecking(OFBool checkFind, OFBool checkMove)
{
    doCheckFindIdentifier = checkFind;
    doCheckMoveIdentifier = checkMove;
}





/**************************************
	Handle Factory
***************************************/

DcmQueryRetrieveOsiriXDatabaseHandleFactory::DcmQueryRetrieveOsiriXDatabaseHandleFactory()
: DcmQueryRetrieveDatabaseHandleFactory()

{
}

DcmQueryRetrieveOsiriXDatabaseHandleFactory::~DcmQueryRetrieveOsiriXDatabaseHandleFactory()
{
}

DcmQueryRetrieveDatabaseHandle *DcmQueryRetrieveOsiriXDatabaseHandleFactory::createDBHandle(
    const char * /* callingAETitle */,
    const char *calledAETitle,
    OFCondition& result) const
{
  return new DcmQueryRetrieveOsiriXDatabaseHandle(
    NULL, result);
}





