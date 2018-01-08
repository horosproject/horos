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
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "DCMTKStudyQueryNode.h"
#import "DCMTKSeriesQueryNode.h"
#import "DCMTKImageQueryNode.h"
#import "DicomStudy.h"
#import "WaitRendering.h"
#import "DCMTKQueryNode.h"
#import "DCMCalendarDate.h"
#import "DCMNetServiceDelegate.h"
#import "DICOMToNSString.h"
#import "MoveManager.h"
#import "BrowserController.h"
#import "AppController.h"
#import "SendController.h"
#import "DCMTKQueryRetrieveSCP.h"
#import "DicomSeries.h"
#import "MutableArrayCategory.h"
#import "WADODownload.h"
#import "N2Debug.h"
#import "DicomDatabase.h"
#import "NSThread+N2.h"
#import "N2MutableUInteger.h"

#include <libkern/OSAtomic.h>

#undef verify
#include "dccodec.h"

#include "osconfig.h" /* make sure OS specific configuration is included first */

#include "dctag.h"
#include "ofstring.h"
#include "dimse.h"
#include "diutil.h"
#include "dcdatset.h"
#include "dcmetinf.h"
#include "dcfilefo.h"
#include "dcdebug.h"
#include "dcdict.h"
#include "dcdeftag.h"
//#include "cmdlnarg.h"
#include "ofconapp.h"
#include "dcuid.h"     /* for dcmtk version name */
#include "dicom.h"     /* for DICOM_APPLICATION_REQUESTOR */
#include "dcostrmz.h"  /* for dcmZlibCompressionLevel */

#ifdef WITH_OPENSSL
#include "tlstrans.h"
#include "tlslayer.h"
#endif

#define OFFIS_CONSOLE_APPLICATION "DCMTKQueryNode"

/* default application titles */
#define APPLICATIONTITLE        "FINDSCU"
#define PEERAPPLICATIONTITLE    "ANY-SCP"

extern int AbortAssociationTimeOut;

#ifdef WITH_OPENSSL

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
static OFString    opt_ciphersuites(TLS1_TXT_RSA_WITH_AES_128_SHA ":" SSL3_TXT_RSA_DES_192_CBC3_SHA);
#else
static OFString    opt_ciphersuites(SSL3_TXT_RSA_DES_192_CBC3_SHA);
#endif

#endif

static int inc = 0;
static int debugLevel = 0;
//static int wadoUnique = 0;	//wadoUniqueThreadID = 0;

typedef struct {
    T_ASC_Association *assoc;
    T_ASC_PresentationContextID presId;
	DCMTKQueryNode *node;
} MyCallbackInfo;

static void
errmsg(const char *msg,...)
{
    va_list args;

    fprintf(stderr, "%s: ", OFFIS_CONSOLE_APPLICATION);
    va_start(args, msg);
    vfprintf(stderr, msg, args);
    va_end(args);
    fprintf(stderr, "\n");
}




static void
progressCallback(
        void *callbackData,
        T_DIMSE_C_FindRQ *request,
        int responseCount,
        T_DIMSE_C_FindRSP *rsp,
        DcmDataset *responseIdentifiers
        )
    /*
     * This function.is used to indicate progress when findscu receives search results over the
     * network. This function will simply cause some information to be dumped to stdout.
     *
     * Parameters:
     *   callbackData        - [in] data for this callback function
     *   request             - [in] The original find request message.
     *   responseCount       - [in] Specifies how many C-FIND-RSP were received including the current one.
     *   rsp                 - [in] the C-FIND-RSP message which was received shortly before the call to
     *                              this function.
     *   responseIdentifiers - [in] Contains the record which was received. This record matches the search
     *                              mask of the C-FIND-RQ which was sent.
     */
{	

	if (debugLevel > 0)
	{
		/* dump response number */
		printf("RESPONSE: %d (%s)\n", responseCount,
			DU_cfindStatusString(rsp->DimseStatus));

		/* dump data set which was received */
		responseIdentifiers->print(COUT);
   }

	MyCallbackInfo *callbackInfo = (MyCallbackInfo *)callbackData;
	DCMTKQueryNode *node = callbackInfo -> node;
	[node addChild:responseIdentifiers];
}

static void
moveCallback(void *callbackData, T_DIMSE_C_MoveRQ *request,
    int responseCount, T_DIMSE_C_MoveRSP *response)
{
	[[NSThread currentThread] setProgress:1.0/(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations+response->NumberOfRemainingSubOperations)*(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations)];
    return;
}


static void
getCallback(void *callbackData, T_DIMSE_C_GetRQ *request,
    int responseCount, T_DIMSE_C_GetRSP *response)
{
	[[NSThread currentThread] setProgress:1.0/(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations+response->NumberOfRemainingSubOperations)*(response->NumberOfCompletedSubOperations+response->NumberOfFailedSubOperations+response->NumberOfWarningSubOperations)];
	return;
}

//static OFCondition
//acceptSubAssoc(T_ASC_Network * aNet, T_ASC_Association ** assoc)
//{
//    const char* knownAbstractSyntaxes[] = {
//        UID_VerificationSOPClass
//    };
//    const char* transferSyntaxes[] = { NULL, NULL, NULL, NULL };
//    int numTransferSyntaxes;
//	
//	OFCmdUnsignedInt  opt_maxPDU = ASC_DEFAULTMAXPDU;
//	E_TransferSyntax opt_in_networkTransferSyntax = EXS_JPEGProcess14SV1TransferSyntax;
//	
//    OFCondition cond = ASC_receiveAssociation(aNet, assoc, opt_maxPDU);
//    if (cond.good())
//    {
//      switch (opt_in_networkTransferSyntax)
//      {
//        case EXS_LittleEndianImplicit:
//          /* we only support Little Endian Implicit */
//          transferSyntaxes[0]  = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 1;
//          break;
//        case EXS_LittleEndianExplicit:
//          /* we prefer Little Endian Explicit */
//          transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
//          transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
//          transferSyntaxes[2]  = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 3;
//          break;
//        case EXS_BigEndianExplicit:
//          /* we prefer Big Endian Explicit */
//          transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
//          transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//          transferSyntaxes[2]  = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 3;
//          break;
//        case EXS_JPEGProcess14SV1TransferSyntax:
//          /* we prefer JPEGLossless:Hierarchical-1stOrderPrediction (default lossless) */
//          transferSyntaxes[0] = UID_JPEGProcess14SV1TransferSyntax;
//          transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//          transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
//          transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 4;
//          break;
//        case EXS_JPEGProcess1TransferSyntax:
//          /* we prefer JPEGBaseline (default lossy for 8 bit images) */
//          transferSyntaxes[0] = UID_JPEGProcess1TransferSyntax;
//          transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//          transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
//          transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 4;
//          break;
//        case EXS_JPEGProcess2_4TransferSyntax:
//          /* we prefer JPEGExtended (default lossy for 12 bit images) */
//          transferSyntaxes[0] = UID_JPEGProcess2_4TransferSyntax;
//          transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//          transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
//          transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 4;
//          break;
//        case EXS_RLELossless:
//          /* we prefer RLE Lossless */
//          transferSyntaxes[0] = UID_RLELosslessTransferSyntax;
//          transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//          transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
//          transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 4;
//          break;
//        default:
//          /* We prefer explicit transfer syntaxes.
//           * If we are running on a Little Endian machine we prefer
//           * LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
//           */
//          if (gLocalByteOrder == EBO_LittleEndian)  /* defined in dcxfer.h */
//          {
//            transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
//            transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
//          } else {
//            transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
//            transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//          }
//          transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
//          numTransferSyntaxes = 3;
//          break;
//
//        }
//
//        /* accept the Verification SOP Class if presented */
//        cond = ASC_acceptContextsWithPreferredTransferSyntaxes(
//            (*assoc)->params,
//            knownAbstractSyntaxes, DIM_OF(knownAbstractSyntaxes),
//            transferSyntaxes, numTransferSyntaxes);
//
//        if (cond.good())
//        {
//            /* the array of Storage SOP Class UIDs comes from dcuid.h */
//            cond = ASC_acceptContextsWithPreferredTransferSyntaxes(
//                (*assoc)->params,
//                dcmAllStorageSOPClassUIDs, numberOfAllDcmStorageSOPClassUIDs,
//                transferSyntaxes, numTransferSyntaxes);
//        }
//    }
//    if (cond.good()) cond = ASC_acknowledgeAssociation(*assoc);
//    if (cond.bad()) {
//        ASC_dropAssociation(*assoc);
//        ASC_destroyAssociation(assoc);
//    }
//    return cond;
//}

//static OFCondition
//subOpSCP(T_ASC_Association **subAssoc)
//{
//    T_DIMSE_Message     msg;
//    T_ASC_PresentationContextID presID;
//
//    if (!ASC_dataWaiting(*subAssoc, 0)) /* just in case */
//        return DIMSE_NODATAAVAILABLE;
//
//    OFCondition cond = DIMSE_receiveCommand(*subAssoc, DIMSE_BLOCKING, 0, &presID,
//            &msg, NULL);
//
//    if (cond == EC_Normal) {
//        switch (msg.CommandField) {
//        case DIMSE_C_STORE_RQ:
//            cond = storeSCP(*subAssoc, &msg, presID);
//            break;
//        case DIMSE_C_ECHO_RQ:
//            cond = echoSCP(*subAssoc, &msg, presID);
//            break;
//        default:
//            cond = DIMSE_BADCOMMANDTYPE;
//            break;
//        }
//    }
//    /* clean up on association termination */
//    if (cond == DUL_PEERREQUESTEDRELEASE)
//    {
//        cond = ASC_acknowledgeRelease(*subAssoc);
//        ASC_dropSCPAssociation(*subAssoc);
//        ASC_destroyAssociation(subAssoc);
//        return cond;
//    }
//    else if (cond == DUL_PEERABORTEDASSOCIATION)
//    {
//    }
//    else if (cond != EC_Normal)
//    {
//        errmsg("DIMSE Failure (aborting sub-association):\n");
//        DimseCondition::dump(cond);
//        /* some kind of error so abort the association */
//        cond = ASC_abortAssociation(*subAssoc);
//    }
//
//    if (cond != EC_Normal)
//    {
//        ASC_dropAssociation(*subAssoc);
//        ASC_destroyAssociation(subAssoc);
//    }
//    return cond;
//}

static void
subOpCallback(void * /*subOpCallbackData*/ ,
        T_ASC_Network *aNet, T_ASC_Association **subAssoc)
{
//	if (aNet == NULL) return;   /* help no net ! */
//
//	if (*subAssoc == NULL)
//	{
//        /* negotiate association */
//		acceptSubAssoc(aNet, subAssoc);
//	}
//	else
//	{
//        /* be a service class provider */
//		//subOpSCP(subAssoc);
//	}
}

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation DCMTKQueryNode

@synthesize dontCatchExceptions = _dontCatchExceptions;
@synthesize isAutoRetrieve = _isAutoRetrieve;
@synthesize noSmartMode = _noSmartMode;

@synthesize countOfSuboperations = _countOfSuboperations, countOfSuccessfulSuboperations = _countOfSuccessfulSuboperations;

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
			callingAET:(NSString *)myAET
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters
{
	return [[[DCMTKQueryNode alloc] initWithDataset:(DcmDataset *)dataset
									callingAET:(NSString *)myAET  
									calledAET:(NSString *)theirAET  
									hostname:(NSString *)hostname 
									port:(int)port 
									transferSyntax:(int)transferSyntax
									compression: (float)compression
									extraParameters:(NSDictionary *)extraParameters] autorelease];
}

- (id) initWithCallingAET:(NSString *)myAET  
				calledAET:(NSString *)theirAET  
				 hostname:(NSString *)hostname 
					 port:(int)port 
		   transferSyntax:(int)transferSyntax
			  compression: (float)compression
		  extraParameters:(NSDictionary *)extraParameters
{
	return [self initWithDataset: nil
				callingAET: myAET
				calledAET: theirAET
				hostname: hostname
				port: port
				transferSyntax: transferSyntax
				compression: compression
				extraParameters: extraParameters];
}

- (id)initWithDataset:(DcmDataset *)dataset
			callingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters
			{
			
	if (self = [super initWithCallingAET:(NSString *)myAET  
							calledAET:(NSString *)theirAET  
							hostname:(NSString *)hostname 
							port:(int)port 
							transferSyntax:(int)transferSyntax
							compression: (float)compression
							extraParameters:(NSDictionary *)extraParameters])
	{
		showErrorMessage = YES;
	}
	return self;
}

- (BOOL) isDistant
{
    return YES;
}

- (void)dealloc
{
	[_children release];
	[_uid release];
	[_theDescription release];
	[_name release];
	[_patientID release];
	[_accessionNumber release];
	[_referringPhysician release];
    
    [_performingPhysician release];
	[_institutionName release];
	[_comments release];
    [_interpretationStatusID release];
	[_date release];
	[_birthdate release];
	[_time release];
	[_modality release];
	[_numberImages release];
	[_specificCharacterSet release];
	[_logEntry release];
	
	[super dealloc];
}

- (NSString *)comment{
	return @"";
}
- (NSNumber *)stateText{
	return 0;
}
- (NSString *)uid{
    if( _uid == nil)
        return @"";
    
	return _uid;
}
- (NSString *)theDescription
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_theDescription capitalizedString];
        
    return _theDescription;
}
- (NSString *)name
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_name capitalizedString];
    
	return _name;
}
- (NSString *)accessionNumber{
	return _accessionNumber;
}
- (NSString *)referringPhysician
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_referringPhysician capitalizedString];
    
	return _referringPhysician;
}
- (NSString *)performingPhysician
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_performingPhysician capitalizedString];
    
	return _performingPhysician;
}
- (NSString *)institutionName
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [_institutionName capitalizedString];
    
	return _institutionName;
}
- (NSString *)comments{
	return _comments;
}
- (NSString*) interpretationStatusID{
    return _interpretationStatusID;
}
- (NSString *)patientID{
	return _patientID;
}
- (DCMCalendarDate *)date{
	return _date;
}
- (DCMCalendarDate *)birthdate{
	return _birthdate;
}
- (NSString*) yearOld
{
    return [DicomStudy yearOldFromDateOfBirth: _birthdate];
}
- (NSString*) yearOldAcquisition
{
    return [DicomStudy yearOldAcquisition: _date FromDateOfBirth: _birthdate];
}
- (NSNumber*) intervalSinceBirth
{
    if( [[NSUserDefaults standardUserDefaults] integerForKey: @"yearOldDatabaseDisplay"] == 0)
        return [NSNumber numberWithDouble: [[NSDate date] timeIntervalSinceDate: _birthdate]];
    else
        return [NSNumber numberWithDouble: [self.date timeIntervalSinceDate: _birthdate]];
}
- (DCMCalendarDate *)time{
	return _time;
}
- (NSString *)modality{
	return _modality;
}
- (NSNumber *)numberImages{
	return _numberImages;
}
- (NSArray *)children
{
    @synchronized( _children)
    {
        return [[_children mutableCopy] autorelease];
    }
    
    return nil;
}
- (void) setChildren: (NSArray *) c
{
    @synchronized( _children)
    {
        [_children autorelease];
        _children = [c mutableCopy];
    }
}
- (void)purgeChildren
{
    @synchronized( _children)
    {
        [_children autorelease];
        _children = nil;
    }
}
- (void)addChild:(DcmDataset *)dataset{

}
- (DcmDataset *)queryPrototype{
	return nil;
}

- (DcmDataset *)moveDataset{
	return nil;
}

// values are a NSDictionary the key for the value is @"value" key for the name is @"name"  name is the tag descriptor from the tag dictionary
/***** possible names **********
	STUDY NAMES
		PatientsName
		PatientID
		AccessionNumber
		StudyDescription
		StudyDate
		StudyTime
		StudyID
		ModalitiesInStudy
	SERIES
		SeriesDescription
		SeriesDate
		SeriesTime
		SeriesNumber
		Modality
	IMAGE
		InstanceCreationDate
		InstanceCreationTime
		StudyInstanceUID
		SeriesInstanceUID
		SOPInstanceUID
		InstanceNumber
		
		



*******************************/
- (void) queryWithValues:(NSArray *)values
{
	return [self queryWithValues: values dataset: nil];
}

- (void) queryWithValues:(NSArray *)values dataset:(DcmDataset*) dataset
{
	@synchronized( self)
	{
        @try
        {
            [self purgeChildren];
            
            BOOL localAllocatedDataset = NO;
            
            if( dataset == nil)
            {
                localAllocatedDataset = YES;
                dataset = [self queryPrototype];
            }
            
            NSString *stringEncoding = [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"];
            
            NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet:stringEncoding];
            
            dataset->putAndInsertString(DCM_SpecificCharacterSet, [stringEncoding UTF8String]);
            
        //	const char *queryLevel;
        //	if (dataset->findAndGetString(DCM_QueryRetrieveLevel, queryLevel).good())
        //	{
        //		const char *string = [[NSString stringWithUTF8String: queryLevel] cStringUsingEncoding: encoding];
        //		dataset->putAndInsertString(DCM_QueryRetrieveLevel, string);
        //	}
            
            if( values)
            {
                NSEnumerator *enumerator = [values objectEnumerator];
                NSDictionary *dictionary;
                
                while (dictionary = [enumerator nextObject])
                {
                    const char *string;
                    NSString *key = [dictionary objectForKey:@"name"];
                    id value  = [dictionary objectForKey:@"value"];
                    if ([key isEqualToString:@"PatientsName"])
                    {	
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_PatientsName, string);
                    }
                    else if ([key isEqualToString:@"ReferringPhysiciansName"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_ReferringPhysiciansName, string);
                    }
                    else if ([key isEqualToString:@"PerformingPhysiciansName"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_PerformingPhysiciansName, string);
                    }
                    else if ([key isEqualToString:@"InstitutionName"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_InstitutionName, string);
                    }
                    else if ([key isEqualToString:@"Comments"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_ImageComments, string);
                    }
                    else if ([key isEqualToString:@"AccessionNumber"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_AccessionNumber, string);
                    }
                    else if ([key isEqualToString:@"PatientID"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_PatientID, string);
                    }
                    else if ([key isEqualToString:@"StudyDescription"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_StudyDescription, string);
                    }
                    else if ([key isEqualToString:@"Comments"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_ImageComments, string);
                    }
                    else if ([key isEqualToString:@"StudyDate"])
                    {
                        NSString *date = [(DCMCalendarDate *)value queryString];
                        string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
                        dataset->putAndInsertString(DCM_StudyDate, string);
                    }
                    else if ([key isEqualToString:@"PatientBirthDate"])
                    {
                        NSString *date = [(DCMCalendarDate *)value queryString];
                        string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
                        dataset->putAndInsertString(DCM_PatientsBirthDate, string);
                    }
                    else if ([key isEqualToString:@"PatientsBirthDate"])
                    {
                        NSString *date = [(DCMCalendarDate *)value queryString];
                        string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
                        dataset->putAndInsertString(DCM_PatientsBirthDate, string);
                    }
                    else if ([key isEqualToString:@"StudyTime"])
                    {
                        NSString *date = [(DCMCalendarDate *)value queryString];
                        string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
                        dataset->putAndInsertString(DCM_StudyTime, string);
                    }
                    else if ([key isEqualToString:@"StudyInstanceUID"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_StudyInstanceUID, string);
                    }
                    else if ([key isEqualToString:@"StudyID"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_StudyID, string);
                    }
                    else if ([key isEqualToString:@"ModalitiesinStudy"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_ModalitiesInStudy, string);
                    }
                    else if ([key isEqualToString:@"Modality"])
                    {
                        string = [(NSString*)value cStringUsingEncoding:encoding];
                        dataset->putAndInsertString(DCM_Modality, string);
                    }
                    else
                    {
                        DcmTag tag;
                        OFCondition result = DcmTag::findTagFromName( [key UTF8String], tag);
                        
                        if( result.good())
                        {
                            string = [(NSString*)value cStringUsingEncoding:encoding];
                            dataset->putAndInsertString( tag.getXTag(), string);
                        }
                        else
                            NSLog( @"**** DICOM C-FIND with unknown value: %@ : %@", key, value);
                    }
                }
            }
            
            if ([self setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:dataset])
            {
            
            }
            else NSLog( @"---- SetupNetworkWithSyntax error : queryWithValues DCMTKQueryNode");
            
            if (dataset != NULL && localAllocatedDataset) delete dataset;
        }
        @catch (NSException* e) {
            if (_dontCatchExceptions)
                @throw e;
            if (![NSThread.currentThread isCancelled])
                N2LogExceptionWithStackTrace(e);
        }
	}
}

- (void) move:(NSDictionary*) dict
{
	return [self move: dict retrieveMode: CMOVERetrieveMode];
}

- (NSString*) syntaxStringFor:( int) ts imageQuality: (int*) q
{
	*q = 100;
	switch ( ts)
	{
		case SendExplicitLittleEndian:
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_LittleEndianExplicitTransferSyntax];
		break;
		case SendJPEG2000Lossless:
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEG2000LosslessOnlyTransferSyntax];
		break;
		case SendJPEG2000Lossy10: 
			*q = 90;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEG2000TransferSyntax];
		break;
		case SendJPEG2000Lossy20:
			*q = 70;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEG2000TransferSyntax];
		break;
		case SendJPEG2000Lossy50:
			*q = 50;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEG2000TransferSyntax];
		break;
        case SendJPEGLSLossless:
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGLSLosslessTransferSyntax];
            break;
		case SendJPEGLSLossy10:
			*q = 90;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGLSLossyTransferSyntax];
            break;
		case SendJPEGLSLossy20:
			*q = 70;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGLSLossyTransferSyntax];
            break;
		case SendJPEGLSLossy50:
			*q = 50;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGLSLossyTransferSyntax];
            break;
		case SendJPEGLossless: 
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGProcess14SV1TransferSyntax];
		break;
		case SendJPEGLossy9:
			*q = 90;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGProcess2_4TransferSyntax];
		break;
		case SendJPEGLossy8:
			*q = 70;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGProcess2_4TransferSyntax];
		break;
		case SendJPEGLossy7:
			*q = 50;
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_JPEGProcess2_4TransferSyntax];
		break;
		case SendImplicitLittleEndian:
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_LittleEndianImplicitTransferSyntax];
		break;
		case SendRLE:
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_RLELosslessTransferSyntax];
		break;
		case SendExplicitBigEndian:
			return [NSString stringWithFormat: @"&transferSyntax=%s", UID_BigEndianExplicitTransferSyntax];
		break;
	}
	
//    return [NSString stringWithFormat: @"&transferSyntax=preserved"];
    
	return [NSString stringWithFormat: @"&useOrig=true"];
}

//- (void) WADODownload: (NSDictionary*) dict
//{
//	[dict retain];
//	
//	@synchronized( self)
//	{
//		wadoUniqueThreadID++;
//	}
//	
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	
//	@try 
//	{
//		NSArray *urlToDownload = [dict valueForKey: @"URLs"];
//		
//		for( NSURL *url in urlToDownload)
//		{
//			NSError *error = nil;
//			NSData *dicom = [[NSData alloc] initWithContentsOfURL: url options: 0 error: &error];
//			
//			if( error)
//			{
//				NSLog( @"****** error WADO download: %@ - url: %@", error, url);
//				
//				if( firstWadoErrorDisplayed == NO)
//				{
//					firstWadoErrorDisplayed = YES;
//                  if( showErrorMessage)
//                      [DCMTKQueryNode performSelectorOnMainThread :@selector(errorMessage:) withObject: [NSArray arrayWithObjects: NSLocalizedString(@"WADO Retrieve Failed", nil), [NSString stringWithFormat: @"%@ - %@", [error localizedDescription], url], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
//				}
//			}
//			
//			NSString *path = [[BrowserController currentBrowser] INCOMINGPATH];
//			
//			@synchronized( self)
//			{
//				wadoUnique++;
//			}
//			[dicom writeToFile: [path stringByAppendingFormat: @"WADO-%d-%d.dcm", wadoUnique, wadoUniqueThreadID] atomically: YES];
//			[dicom release];
//			
//			if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"])
//				break;
//			
//			if( [[dict valueForKey: @"mainThread"] isCancelled])
//				break;
//		}
//	}
//	@catch (NSException * e) 
//	{
//      if (_dontCatchExceptions)
//          @throw e;
//      if (![NSThread.currentThread isCancelled])
//          N2LogExceptionWithStackTrace(e);
//	}
//
//	[pool release];
//	
//	[dict release];
//	
//	@synchronized( self)
//	{
//		WADOThreads--;
//	}
//}

//- (void) realtimeCFindResults: (NSNotification*) notification
//{
//    if( [notification object] == self)
//    {
//        NSLog( @"%d", [[self children] count]);
//    }
//}

- (void) WADOCFindThread: (id) sender
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
#ifndef NDEBUG
    NSLog( @"--- WADO CFIND Start");
#endif
    [NSThread currentThread].name = @"WADO C-FIND Thread";
    
    DcmDataset dataset;
    
    dataset.insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
    dataset.insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
    dataset.insertEmptyElement(DCM_SOPInstanceUID, OFTrue);
    dataset.putAndInsertString(DCM_StudyInstanceUID, [_uid UTF8String], OFTrue);
    dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE", OFTrue);
    
    [self queryWithValues: nil dataset: &dataset];
#ifndef NDEBUG
    NSLog( @"--- WADO CFIND Done");
#endif
    [pool release];
}

- (NSUInteger) childrenCount
{
    if( _children == nil)
        return 0;
    
    @synchronized( _children)
    {
        return _children.count;
    }
}

- (void) WADORetrieve: (DCMTKStudyQueryNode*) study // requestService: WFIND?
{
#ifndef NDEBUG
	if( [self isKindOfClass:[DCMTKSeriesQueryNode class]])
		NSLog( @"------ WADO download : starting... %@ %@", study.theDescription, study.patientID);
	else
		NSLog( @"------ WADO download : starting... %@ %@", self.theDescription, self.patientID);
#endif
    
	NSString *protocol = [[_extraParameters valueForKey: @"WADOhttps"] intValue] ? @"https" : @"http";
	
	NSString *wadoSubUrl = [_extraParameters valueForKey: @"WADOUrl"];
	
	if( [wadoSubUrl hasPrefix: @"/"])
		wadoSubUrl = [wadoSubUrl substringFromIndex: 1];
	
    NSString* lpbit = @"";
    if ([[_extraParameters valueForKey:@"WADOUsername"] length] && [[_extraParameters valueForKey:@"WADOPassword"] length])
        lpbit = [NSString stringWithFormat:@"%@:%@@", [_extraParameters valueForKey:@"WADOUsername"], [_extraParameters valueForKey:@"WADOPassword"]];
    
	NSString *baseURL = [NSString stringWithFormat: @"%@://%@%@:%d/%@?requestType=WADO", protocol, lpbit, _hostname, [[_extraParameters valueForKey: @"WADOPort"] intValue], wadoSubUrl];
	
    if( baseURL == nil)
        N2LogStackTrace( @"No baseURL !");
    
	@try
	{
		if( [protocol isEqualToString: @"https"])
			[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[[NSURL URLWithString: baseURL] host]];
	}
	@catch (NSException *e)
	{
        if (_dontCatchExceptions)
            @throw e;
		if (![NSThread.currentThread isCancelled])
            N2LogExceptionWithStackTrace(e);
	}
	
	int quality = 100;
	NSString *ts = [self syntaxStringFor: [[_extraParameters valueForKey: @"WADOTransferSyntax"] intValue] imageQuality: &quality];
	
	// Local Study?
	NSMutableArray *localObjectUIDs = [NSMutableArray array];
	@try
	{
		NSError *error = nil;
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		NSManagedObjectContext *context = [NSThread isMainThread] ? [[DicomDatabase activeLocalDatabase] managedObjectContext] : [[DicomDatabase activeLocalDatabase] independentContext];
		
		NSPredicate *predicate = [NSPredicate predicateWithValue: NO];
		if( [self isKindOfClass: [DCMTKSeriesQueryNode class]])
			predicate = [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", [study uid]];
		if( [self isKindOfClass: [DCMTKStudyQueryNode class]])
			predicate = [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", [self uid]];
			
		[request setEntity: [[context.persistentStoreCoordinator.managedObjectModel entitiesByName] objectForKey: @"Study"]];
		[request setPredicate: predicate];
		
		DicomStudy *localStudy = [[context executeFetchRequest: request error: &error] lastObject];
		
		for( DicomSeries *s in [localStudy valueForKey: @"series"])
			[localObjectUIDs addObjectsFromArray: [[[s images] valueForKey: @"sopInstanceUID"] allObjects]];
	}
	@catch (NSException * e) {
        if (_dontCatchExceptions)
            @throw e;
		if (![NSThread.currentThread isCancelled])
            N2LogExceptionWithStackTrace(e);
    }
	
	if( [self isKindOfClass:[DCMTKStudyQueryNode class]])
	{
		// We are at STUDY level, and we want to go direclty to IMAGE level
		
//		DcmDataset dataset;
//		
//		dataset.insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
//		dataset.insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
//		dataset.insertEmptyElement(DCM_SOPInstanceUID, OFTrue);
//		dataset.putAndInsertString(DCM_StudyInstanceUID, [_uid UTF8String], OFTrue);
//		dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE", OFTrue);
		
		NSThread *WADOCFind = [[[NSThread alloc] initWithTarget: self selector: @selector( WADOCFindThread:) object: nil] autorelease];
		
        [WADOCFind start];
        [NSThread sleepForTimeInterval: 0.1];
        
        WADODownload *downloader = [[WADODownload alloc] init];
        
        downloader.showErrorMessage = showErrorMessage;
        downloader.WADOBaseTotal = 0;
        downloader.WADOGrandTotal = self.numberImages.integerValue; // For the GUI progress bar
        
        while( (WADOCFind.isExecuting || self.childrenCount) && [[NSThread currentThread] isCancelled] == NO)
        {
            if( self.childrenCount > 50 || WADOCFind.isExecuting == NO)
            {
                NSArray *childrenArray = nil;
                @synchronized( _children)
                {
                    childrenArray = [[_children copy] autorelease];
                    [_children removeAllObjects];
                }
                
                NSMutableArray *urlToDownload = [NSMutableArray array];
                @try
                {
                    childrenArray = [childrenArray sortedArrayUsingDescriptors: [NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey: @"seriesInstanceUID" ascending: YES], nil]];
                    
                    for( DCMTKImageQueryNode *image in childrenArray)
                    {
                        if( [image uid])
                        {
                            if( [localObjectUIDs containsObject: [image uid]] == NO)
                            {
                                NSURL *url = [NSURL URLWithString: [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@", [self uid], [image seriesInstanceUID], [image uid], ts]];
                                
                                if( url)
                                    [urlToDownload addObject: url];
                                else
                                    NSLog( @"****** no url : %@", [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@", [self uid], [image seriesInstanceUID], [image uid], ts]);
                            }
                            else
                                downloader.WADOBaseTotal++;
                        }
                        else NSLog( @"****** no image uid !");
                    }
                }
                @catch (NSException* e)
                {
                    if (_dontCatchExceptions)
                        @throw e;
                    if (![NSThread.currentThread isCancelled])
                        N2LogExceptionWithStackTrace(e);
                }
                
                [downloader WADODownload: urlToDownload];
                downloader.WADOBaseTotal += urlToDownload.count; // For the GUI progress bar
                
                self.countOfSuboperations += urlToDownload.count;
                self.countOfSuccessfulSuboperations += downloader.countOfSuccesses;
            }
            
            [NSThread sleepForTimeInterval: 0.1];
        }
        
        [downloader release];
        
		[self purgeChildren];
	}
	
	if( [self isKindOfClass:[DCMTKSeriesQueryNode class]])
	{
        NSArray *childrenArray = nil;
        @synchronized( self)
        {
            childrenArray = [self children];
            
            // search the images
            if( childrenArray == nil)
                [self queryWithValues: nil];
            
            childrenArray = [self children];
        }
        
        NSMutableArray *urlToDownload = [NSMutableArray array];
        
        @try
        {
            for( DCMTKQueryNode *image in childrenArray)
            {
                if( [image uid])
                {
                    if( [localObjectUIDs containsObject: [image uid]] == NO)
                    {
                        NSURL *url = [NSURL URLWithString: [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@", [study uid], [self uid], [image uid], ts]];
                        if( url)
                            [urlToDownload addObject: url];
                        else
                            NSLog( @"****** no url : %@", [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@", [study uid], [self uid], [image uid], ts]);
                    }
                }
                else NSLog( @"****** no image uid !");
            }
        }
        @catch (NSException* e) {
            if (_dontCatchExceptions)
                @throw e;
            if (![NSThread.currentThread isCancelled])
                N2LogExceptionWithStackTrace(e);
        }
        
		[self purgeChildren];
        
        WADODownload *downloader = [[WADODownload alloc] init];
        
        downloader.showErrorMessage = showErrorMessage;
        
        [downloader WADODownload: urlToDownload];
        
        self.countOfSuboperations = urlToDownload.count;
        self.countOfSuccessfulSuboperations = downloader.countOfSuccesses;
        
        [downloader release];
    }
}

- (void) CFINDThread: (NSString*) studyInstanceUID
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    if( [self isKindOfClass:[DCMTKStudyQueryNode class]])
    {
        // We are at STUDY level, and we want to go direclty to IMAGE level
        
        DcmDataset dataset;
        
        dataset.insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
        dataset.insertEmptyElement(DCM_SOPInstanceUID, OFTrue);
        dataset.putAndInsertString(DCM_StudyInstanceUID, [studyInstanceUID UTF8String], OFTrue);
        dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE", OFTrue);
        
        [self queryWithValues: nil dataset: &dataset];
    }
    
    if( [self isKindOfClass:[DCMTKSeriesQueryNode class]])
    {
        NSArray *childrenArray = [self children];
        
        // search the images
        if( childrenArray == nil)
            [self queryWithValues: nil];
        
        childrenArray = [self children];
    }
    
    [pool release];
}

- (void) move:(NSDictionary*) dict retrieveMode: (int) retrieveMode
{
    NSArray *childrenCopy = [self children];
    
    dispatch_semaphore_t mpsid = nil;
    if (_isAutoRetrieve) {
        mpsid = [[self class] semaphoreForServerHostAndPort:[NSString stringWithFormat:@"%@:%d", self._hostname, self._port]];
        dispatch_semaphore_wait(mpsid, DISPATCH_TIME_FOREVER);
    }
    
    @try
    {
        if( [[dict valueForKey: @"retrieveMode"] intValue] == WADORetrieveMode && retrieveMode == WADORetrieveMode)
        {
            [self WADORetrieve: [dict valueForKey: @"study"]];
        }
        else // DICOM retrieve
        {
            NSMutableArray *localObjectUIDs = [NSMutableArray array];
            
            BOOL retrievedDone = NO;
            
            if( !_noSmartMode && [[NSUserDefaults standardUserDefaults] boolForKey: @"TryIMAGELevelDICOMRetrieveIfLocalImages"])
            {
                NSString *studyInstanceUID = nil;
                
                if( [self isKindOfClass: [DCMTKSeriesQueryNode class]])
                {
                    id study = [dict valueForKey: @"study"];
                    studyInstanceUID = [study uid];
                }
                
                if( [self isKindOfClass: [DCMTKStudyQueryNode class]])
                    studyInstanceUID = [self uid];
                
                // Local Study with images? -> try a C-Move/C-Get at IMAGE level to download only required images
                
                @try
                {
                    if( studyInstanceUID.length > 0)
                    {
                        @try
                        {
                            NSError *error = nil;
                            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
                            
                            [request setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyInstanceUID]];
                            
                            NSManagedObjectContext *context = [NSThread isMainThread] ? [[DicomDatabase activeLocalDatabase] managedObjectContext] : [[DicomDatabase activeLocalDatabase] independentContext];
                            
                            DicomStudy *localStudy = [[context executeFetchRequest: request error: &error] lastObject];
                            
                            for( DicomSeries *s in [localStudy valueForKey: @"series"])
                                [localObjectUIDs addObjectsFromArray: [[[s images] valueForKey: @"sopInstanceUID"] allObjects]];
                        }
                        @catch (NSException* e)
                        {
                            if (_dontCatchExceptions)
                                @throw e;
                            if (![NSThread.currentThread isCancelled])
                                N2LogExceptionWithStackTrace(e);
                        }
                    }
                }
                @catch (NSException* e)
                {
                    NSLog( @"%@", studyInstanceUID);
                    N2LogExceptionWithStackTrace(e);
                }
                
                if( (localObjectUIDs.count || [[NSUserDefaults standardUserDefaults] boolForKey: @"MultipleAssociationsRetrieve"]) && [[NSThread currentThread] isCancelled] == NO) // We have already local images !
                {
                    NSThread *WADOCFind = [[[NSThread alloc] initWithTarget: self selector: @selector( CFINDThread:) object: studyInstanceUID] autorelease];
                    
                    [WADOCFind start];
                    [NSThread sleepForTimeInterval: 0.1];
                    
                    while( (WADOCFind.isExecuting || self.childrenCount) && [[NSThread currentThread] isCancelled] == NO)
                    {
                        if( self.childrenCount > 50 || WADOCFind.isExecuting == NO)
                        {
                            NSMutableDictionary *seriesUIDsToRetrieve = [NSMutableDictionary dictionary];
                            NSMutableArray *imagesUIDsWithoutSeriesInstanceUID = [NSMutableArray array];
                            
                            NSArray *childrenArray = nil;
                            @synchronized( _children)
                            {
                                childrenArray = [[_children copy] autorelease];
                                [_children removeAllObjects];
                            }
                            
                            @try
                            {
                                if( [self isKindOfClass:[DCMTKStudyQueryNode class]])
                                {
                                    childrenArray = [childrenArray sortedArrayUsingDescriptors: [NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey: @"seriesInstanceUID" ascending: YES], nil]];
                                    
                                    for( DCMTKImageQueryNode *image in childrenArray)
                                    {
                                        if( [image uid])
                                        {
                                            if( [localObjectUIDs containsObject: [image uid]] == NO)
                                            {
                                                if( [image seriesInstanceUID])
                                                {
                                                    if( [seriesUIDsToRetrieve objectForKey: [image seriesInstanceUID]] == nil)
                                                        [seriesUIDsToRetrieve setObject: [NSMutableArray array] forKey: [image seriesInstanceUID]];
                                                    
                                                    [[seriesUIDsToRetrieve objectForKey: [image seriesInstanceUID]] addObject: [image uid]];
                                                }
                                                else
                                                    [imagesUIDsWithoutSeriesInstanceUID addObject: [image uid]];
                                            }
                                        }
                                        else NSLog( @"****** no image uid !");
                                        
                                        if( [[NSThread currentThread] isCancelled]) break;
                                    }
                                }
                                else
                                {
                                    for( DCMTKImageQueryNode *image in childrenArray)
                                    {
                                        if( [image uid])
                                        {
                                            if( [localObjectUIDs containsObject: [image uid]] == NO)
                                            {
                                                if( [seriesUIDsToRetrieve objectForKey: [image seriesInstanceUID]] == nil)
                                                    [seriesUIDsToRetrieve setObject: [NSMutableArray array] forKey: [image seriesInstanceUID]];
                                                
                                                [[seriesUIDsToRetrieve objectForKey: [image seriesInstanceUID]] addObject: [image uid]];
                                            }
                                        }
                                        else NSLog( @"****** no image uid !");
                                        
                                        if( [[NSThread currentThread] isCancelled]) break;
                                    }
                                }
                            }
                            @catch (NSException* e)
                            {
                                if (_dontCatchExceptions)
                                    @throw e;
                                if (![NSThread.currentThread isCancelled])
                                    N2LogExceptionWithStackTrace(e);
                            }
                            
                            if(([seriesUIDsToRetrieve count] || [imagesUIDsWithoutSeriesInstanceUID count]) && [[NSThread currentThread] isCancelled] == NO)
                            {
                                if( [seriesUIDsToRetrieve count])
                                {
                                    int noOfAssociations = 1;
                                    
//                                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"MultipleAssociationsRetrieve"] && [[NSUserDefaults standardUserDefaults] integerForKey: @"NoOfMultipleAssociationsRetrieve"] > 1)
//                                        noOfAssociations = [[NSUserDefaults standardUserDefaults] integerForKey: @"NoOfMultipleAssociationsRetrieve"];
                                    
                                    NSMutableArray *threads = [NSMutableArray array];
                                    NSThread *mainThread = [NSThread currentThread];
                                    
                                    for( int i = 0; i < noOfAssociations; i++)
                                    {
                                        [threads addObject: [NSThread performBlockInBackground: ^
                                                             {
                                                                 NSRange range = NSMakeRange( i * (seriesUIDsToRetrieve.count / noOfAssociations), seriesUIDsToRetrieve.count / noOfAssociations);
                                                                 
                                                                 if( i == noOfAssociations-1)
                                                                     range.length = seriesUIDsToRetrieve.count - range.location;
                                                                 
                                                                 //To avoid incompatible PACS, retrieve each series independently
                                                                 for( NSString *seriesInstanceUID in [seriesUIDsToRetrieve.allKeys subarrayWithRange: range])
                                                                 {
                                                                     DcmDataset dataset;
                                                                     
                                                                     dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
                                                                     dataset.putAndInsertOFStringArray(DCM_SOPInstanceUID, [[[seriesUIDsToRetrieve objectForKey: seriesInstanceUID] componentsJoinedByString:@"\\"] UTF8String]);
                                                                     dataset.putAndInsertOFStringArray(DCM_SeriesInstanceUID, [seriesInstanceUID UTF8String]);
                                                                     dataset.putAndInsertOFStringArray(DCM_StudyInstanceUID, [studyInstanceUID UTF8String]);
                                                                     
                                                                     if( [[dict valueForKey: @"retrieveMode"] intValue] == CGETRetrieveMode && retrieveMode == CGETRetrieveMode)
                                                                     {
                                                                         if( [DCMTKQueryRetrieveSCP storeSCP] == NO)
                                                                             [[NSException exceptionWithName: @"DICOM Network Failure" reason: NSLocalizedString( @"DICOM Listener is not activated", nil) userInfo:nil] raise];
                                                                         
                                                                         else
                                                                         {
                                                                             if ([self setupNetworkWithSyntax: UID_GETStudyRootQueryRetrieveInformationModel dataset: &dataset destination: [dict objectForKey:@"moveDestination"]])
                                                                             {
                                                                             }
                                                                             else
                                                                             {
                                                                                 NSLog( @"***** IMAGE Level retrieve failed... try STUDY/SERIES Level retrieve");
                                                                                 [[NSThread currentThread] cancel];
                                                                             }
                                                                         }
                                                                     }
                                                                     else
                                                                     {
                                                                         if( [DCMTKQueryRetrieveSCP storeSCP] == NO && [dict objectForKey: @"moveDestination"] == nil)
                                                                             [[NSException exceptionWithName: @"DICOM Network Failure" reason: NSLocalizedString( @"DICOM Listener is not activated", nil) userInfo:nil] raise];
                                                                         
                                                                         else
                                                                         {
                                                                             if ([self setupNetworkWithSyntax:UID_MOVEStudyRootQueryRetrieveInformationModel dataset: &dataset destination: [dict objectForKey: @"moveDestination"]])
                                                                             {
                                                                             }
                                                                             else
                                                                             {
                                                                                 NSLog( @"***** IMAGE Level retrieve failed... try STUDY/SERIES Level retrieve");
                                                                                 [[NSThread currentThread] cancel];
                                                                             }
                                                                         }
                                                                     }
                                                                     
                                                                     if( [mainThread isCancelled]) break;
                                                                 }
                                                             }
                                                             ]];
                                    }
                                    
                                    BOOL executing = NO;
                                    do
                                    {
                                        executing = NO;
                                        
                                        for( NSThread *t in threads)
                                            if( t.isExecuting) executing = YES;
                                        
                                        if( [[NSThread currentThread] isCancelled])
                                            for( NSThread *t in threads)
                                                [t cancel];
                                        
                                        [NSThread sleepForTimeInterval: 0.05];
                                    }
                                    while( executing);
                                    
                                    retrievedDone = YES;
                                    
                                    for( NSThread *t in threads)
                                        if( t.isCancelled) retrievedDone = NO;
                                }
                                else
                                {
                                    int noOfAssociations = 1;
                                    
//                                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"MultipleAssociationsRetrieve"] && [[NSUserDefaults standardUserDefaults] integerForKey: @"NoOfMultipleAssociationsRetrieve"] > 1)
//                                        noOfAssociations = [[NSUserDefaults standardUserDefaults] integerForKey: @"NoOfMultipleAssociationsRetrieve"];
                                    
                                    NSMutableArray *threads = [NSMutableArray array];
                                    
                                    for( int i = 0; i < noOfAssociations; i++)
                                    {
                                        [threads addObject: [NSThread performBlockInBackground: ^
                                                             {
                                                                 DcmDataset dataset;
                                                                 
                                                                 NSRange range = NSMakeRange( i * (imagesUIDsWithoutSeriesInstanceUID.count / noOfAssociations), imagesUIDsWithoutSeriesInstanceUID.count / noOfAssociations);
                                                                 
                                                                 if( i == noOfAssociations-1)
                                                                     range.length = imagesUIDsWithoutSeriesInstanceUID.count - range.location;
                                                                 
                                                                 NSArray *subArray = [imagesUIDsWithoutSeriesInstanceUID subarrayWithRange: range];
                                                                 
                                                                 dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
                                                                 dataset.putAndInsertOFStringArray(DCM_SOPInstanceUID, [[subArray componentsJoinedByString:@"\\"] UTF8String]);
                                                                 dataset.putAndInsertOFStringArray(DCM_StudyInstanceUID, [studyInstanceUID UTF8String]);
                                                                 
                                                                 if( [[dict valueForKey: @"retrieveMode"] intValue] == CGETRetrieveMode && retrieveMode == CGETRetrieveMode)
                                                                 {
                                                                     if( [DCMTKQueryRetrieveSCP storeSCP] == NO)
                                                                         [[NSException exceptionWithName: @"DICOM Network Failure" reason: NSLocalizedString( @"DICOM Listener is not activated", nil) userInfo:nil] raise];
                                                                     
                                                                     else
                                                                     {
                                                                         if ([self setupNetworkWithSyntax: UID_GETStudyRootQueryRetrieveInformationModel dataset: &dataset destination: [dict objectForKey:@"moveDestination"]])
                                                                         {
                                                                         }
                                                                         else
                                                                         {
                                                                             NSLog( @"***** IMAGE Level retrieve failed... try STUDY/SERIES Level retrieve");
                                                                             [[NSThread currentThread] cancel];
                                                                         }
                                                                     }
                                                                 }
                                                                 else
                                                                 {
                                                                     if( [DCMTKQueryRetrieveSCP storeSCP] == NO && [dict objectForKey: @"moveDestination"] == nil)
                                                                         [[NSException exceptionWithName: @"DICOM Network Failure" reason: NSLocalizedString( @"DICOM Listener is not activated", nil) userInfo:nil] raise];
                                                                     
                                                                     else
                                                                     {
                                                                         if ([self setupNetworkWithSyntax:UID_MOVEStudyRootQueryRetrieveInformationModel dataset: &dataset destination: [dict objectForKey: @"moveDestination"]])
                                                                         {
                                                                         }
                                                                         else
                                                                         {
                                                                             NSLog( @"***** IMAGE Level retrieve failed... try STUDY/SERIES Level retrieve");
                                                                             [[NSThread currentThread] cancel];
                                                                         }
                                                                     }
                                                                 }
                                                             }
                                                             ]];
                                    }
                                    
                                    BOOL executing = NO;
                                    do
                                    {
                                        executing = NO;
                                        
                                        for( NSThread *t in threads)
                                            if( t.isExecuting) executing = YES;
                                        
                                        if( [[NSThread currentThread] isCancelled])
                                            for( NSThread *t in threads)
                                                [t cancel];
                                        
                                        [NSThread sleepForTimeInterval: 0.05];
                                    }
                                    while( executing);
                                    
                                    retrievedDone = YES;
                                    
                                    for( NSThread *t in threads)
                                        if( t.isCancelled) retrievedDone = NO;
                                }
                            }
                            else
                            {
                                if (!childrenArray.count) { // this message is misleaging without this condition: the IMAGE level DID work, but we already have all the images locally
                                    NSLog( @"***** IMAGE Level retrieve failed... try STUDY/SERIES Level retrieve");
                                    localObjectUIDs = nil;
                                }
                            }
                        }
                        
                        [NSThread sleepForTimeInterval: 0.1];
                    }
                    [self purgeChildren];
                    
                    [self setChildren: childrenCopy];
                }
            }
            
            if( retrievedDone == NO && [[NSThread currentThread] isCancelled] == NO)// STUDY / SERIES LEVEL retrieve
            {
                [self setChildren: childrenCopy];
                
                DcmDataset *dataset = [self moveDataset];
                
                if( [[dict valueForKey: @"retrieveMode"] intValue] == CGETRetrieveMode && retrieveMode == CGETRetrieveMode)
                {
                    if( [DCMTKQueryRetrieveSCP storeSCP] == NO)
                        [[NSException exceptionWithName: @"DICOM Network Failure" reason: NSLocalizedString( @"DICOM Listener is not activated", nil) userInfo:nil] raise];
                    
                    else
                    {
                        
                        if ([self setupNetworkWithSyntax: UID_GETStudyRootQueryRetrieveInformationModel dataset:dataset destination: [dict objectForKey:@"moveDestination"]])
                        {
                        }
                        else
                            NSLog( @"UID_GETStudyRootQueryRetrieveInformationModel failed : %s", __PRETTY_FUNCTION__);
                    }
                }
                else
                {
                    if( [DCMTKQueryRetrieveSCP storeSCP] == NO && [dict objectForKey: @"moveDestination"] == nil)
                        [[NSException exceptionWithName: @"DICOM Network Failure" reason: NSLocalizedString( @"DICOM Listener is not activated", nil) userInfo:nil] raise];
                    
                    else
                    {
                        if ([self setupNetworkWithSyntax:UID_MOVEStudyRootQueryRetrieveInformationModel dataset:dataset destination: [dict objectForKey: @"moveDestination"]])
                        {
                        }
                        else
                            NSLog( @"UID_MOVEStudyRootQueryRetrieveInformationModel failed : %s", __PRETTY_FUNCTION__);
                    }
                }
                
                if (dataset != NULL)
                    delete dataset;
            }
        }
            
    }
    @catch (...) {
        @throw;
    }
    @finally {
        if (mpsid)
            dispatch_semaphore_signal(mpsid);
        [self setChildren: childrenCopy];
    }
}

- (OFCondition) addPresentationContext:(T_ASC_Parameters *)params abstractSyntax:(const char *)abstractSyntax
{
   /*
    ** We prefer to use Explicitly encoded transfer syntaxes.
    ** If we are running on a Little Endian machine we prefer
    ** LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
    ** Some SCP implementations will just select the first transfer
    ** syntax they support (this is not part of the standard) so
    ** organise the proposed transfer syntaxes to take advantage
    ** of such behaviour.
    */

	const char* transferSyntaxes[] = { NULL, NULL, NULL, NULL,NULL, NULL, NULL, NULL, NULL, NULL, NULL };
    int numTransferSyntaxes = 0;

    switch (_networkTransferSyntax) 
	{
	case EXS_LittleEndianImplicit:
        /* we only support Little Endian Implicit */
        transferSyntaxes[0] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 1;
        break;
		
	  default:
      case EXS_LittleEndianExplicit:
        /* we prefer Little Endian Explicit */
        transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;	//;
        transferSyntaxes[1] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
		transferSyntaxes[3] = UID_JPEG2000LosslessOnlyTransferSyntax ;			//jpeg 2000
		transferSyntaxes[4] = UID_JPEG2000TransferSyntax;						//jpeg 2000
		transferSyntaxes[5] = UID_JPEGProcess14SV1TransferSyntax;				//jpeg lossless
		transferSyntaxes[6] = UID_JPEGProcess1TransferSyntax;					//jpeg 8
		transferSyntaxes[7] = UID_JPEGProcess2_4TransferSyntax;					//jpeg 12
//		transferSyntaxes[8] = UID_DeflatedExplicitVRLittleEndianTransferSyntax;	//bzip
		transferSyntaxes[8] = UID_RLELosslessTransferSyntax;					//RLE
		transferSyntaxes[9] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
		
        numTransferSyntaxes = 10;
        break;
		
      case EXS_BigEndianExplicit:
        /* we prefer Big Endian Explicit */
        transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
        transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[3] = UID_JPEG2000TransferSyntax;						//jpeg 2000
		transferSyntaxes[4] = UID_JPEGProcess14SV1TransferSyntax;				//jpeg lossless
		transferSyntaxes[5] = UID_JPEGProcess1TransferSyntax;					//jpeg 8
		transferSyntaxes[6] = UID_JPEGProcess2_4TransferSyntax;					//jpeg 12
//		transferSyntaxes[7] = UID_DeflatedExplicitVRLittleEndianTransferSyntax;	//bzip
		transferSyntaxes[7] = UID_RLELosslessTransferSyntax;					//RLE
        numTransferSyntaxes = 8;
        break;
		
#ifndef DISABLE_COMPRESSION_EXTENSION
      case EXS_JPEGProcess14SV1TransferSyntax:
        /* we prefer JPEGLossless:Hierarchical-1stOrderPrediction (default lossless) */
        transferSyntaxes[0] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[1] = UID_JPEGProcess1TransferSyntax;					//jpeg 8
		transferSyntaxes[2] = UID_JPEGProcess2_4TransferSyntax;					//jpeg 12
        transferSyntaxes[3] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[4] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[5] = UID_BigEndianExplicitTransferSyntax;
		
        numTransferSyntaxes = 6;
        break;
      case EXS_JPEGProcess1TransferSyntax:
        /* we prefer JPEGBaseline (default lossy for 8 bit images) */
        transferSyntaxes[0] = UID_JPEGProcess1TransferSyntax;
		transferSyntaxes[1] = UID_JPEGProcess2_4TransferSyntax;					//jpeg 12
		transferSyntaxes[2] = UID_JPEGProcess14SV1TransferSyntax;
        transferSyntaxes[3] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[4] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[5] = UID_BigEndianExplicitTransferSyntax;
		
        numTransferSyntaxes = 6;
        break;
      case EXS_JPEGProcess2_4TransferSyntax:
        /* we prefer JPEGExtended (default lossy for 12 bit images) */
        transferSyntaxes[0] = UID_JPEGProcess2_4TransferSyntax;
		transferSyntaxes[1] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[2] = UID_JPEGProcess1TransferSyntax;
        transferSyntaxes[3] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[4] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[5] = UID_BigEndianExplicitTransferSyntax;
		
        numTransferSyntaxes = 6;
        break;
      case EXS_JPEG2000LosslessOnly:
        /* we prefer JPEG 2000 lossless */
        transferSyntaxes[0] = UID_JPEG2000LosslessOnlyTransferSyntax;
		transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
		transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[3] = UID_BigEndianExplicitTransferSyntax;
		
        numTransferSyntaxes = 4;
        break;
      case EXS_JPEG2000:
        /* we prefer JPEG 2000 lossy or lossless */
        transferSyntaxes[0] = UID_JPEG2000TransferSyntax; //UID_JPEG2000TransferSyntax;
		transferSyntaxes[1] = UID_JPEG2000LosslessOnlyTransferSyntax;
		transferSyntaxes[2] = UID_LittleEndianExplicitTransferSyntax;
		transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
		transferSyntaxes[4] = UID_BigEndianExplicitTransferSyntax;
		
        numTransferSyntaxes = 5;
        break;
        
        case EXS_JPEGLSLossless:
            /* we prefer JPEG LS lossless */
            transferSyntaxes[0] = UID_JPEGLSLosslessTransferSyntax;
            transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
            transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
            transferSyntaxes[3] = UID_BigEndianExplicitTransferSyntax;
            
            numTransferSyntaxes = 4;
            break;
        case EXS_JPEGLSLossy:
            /* we prefer JPEG LS lossy or lossless */
            transferSyntaxes[0] = UID_JPEGLSLossyTransferSyntax;
            transferSyntaxes[1] = UID_JPEGLSLosslessTransferSyntax;
            transferSyntaxes[2] = UID_LittleEndianExplicitTransferSyntax;
            transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
            transferSyntaxes[4] = UID_BigEndianExplicitTransferSyntax;
            
            numTransferSyntaxes = 5;
            break;
            
//#ifdef WITH_ZLIB
//      case EXS_DeflatedLittleEndianExplicit:
//        /* we prefer deflated transmission */
//        transferSyntaxes[0] = UID_DeflatedExplicitVRLittleEndianTransferSyntax;
//        transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
//        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
//        transferSyntaxes[3] = UID_BigEndianExplicitTransferSyntax;
//		transferSyntaxes[4] = UID_JPEG2000TransferSyntax;
//		transferSyntaxes[5] = UID_JPEGProcess14SV1TransferSyntax;
//		transferSyntaxes[6] = UID_JPEGProcess2_4TransferSyntax;		
//		transferSyntaxes[7] = UID_JPEGProcess1TransferSyntax;
//		transferSyntaxes[8] = UID_RLELosslessTransferSyntax;					//RLE
//        transferSyntaxes[9] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
//		
//        numTransferSyntaxes = 10;
//        break;
//#endif
      case EXS_RLELossless:
        /* we prefer RLE Lossless */
        transferSyntaxes[0] = UID_RLELosslessTransferSyntax;
        transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        transferSyntaxes[3] = UID_BigEndianExplicitTransferSyntax;
		transferSyntaxes[4] = UID_JPEG2000TransferSyntax;
		transferSyntaxes[5] = UID_JPEGProcess14SV1TransferSyntax;
		transferSyntaxes[6] = UID_JPEGProcess2_4TransferSyntax;		
		transferSyntaxes[7] = UID_JPEGProcess1TransferSyntax;
//		transferSyntaxes[8] = UID_DeflatedExplicitVRLittleEndianTransferSyntax;
        transferSyntaxes[8] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
		
        numTransferSyntaxes = 9;
        break;
#endif
    }
	
	OFCondition cond = EC_Normal;

    int i;
    int pid = 1;
	
	ASC_addPresentationContext(
        params, 1, abstractSyntax,
        transferSyntaxes, numTransferSyntaxes);
		
	// For C-GET we also need the storage presentation contexts : the is only one association
	if( strcmp(abstractSyntax, UID_GETPatientRootQueryRetrieveInformationModel) == 0 ||
		strcmp(abstractSyntax, UID_GETStudyRootQueryRetrieveInformationModel) == 0 ||
		strcmp(abstractSyntax, UID_GETPatientStudyOnlyQueryRetrieveInformationModel) == 0)
	if( abstractSyntax)
	{
		pid += 2;
		
		for (i=0; i<numberOfDcmLongSCUStorageSOPClassUIDs && cond.good(); i++)
		{
			cond = ASC_addPresentationContext(
				params, pid, dcmLongSCUStorageSOPClassUIDs[i],
				transferSyntaxes, numTransferSyntaxes);
			pid += 2;	/* only odd presentation context id's */
		}
	}
	
    return cond;
}

- (void)setShowErrorMessage:(BOOL) m
{
	showErrorMessage = m;
}

+ (void) errorMessage:(NSArray*) msg
{
    NSString *alertSuppress = @"hideListenerError";
    
    static BOOL avoidErrorMessageReentry = NO;
    
    if( avoidErrorMessageReentry == NO)
    {
        NSLog( @"*** listener error (not displayed - hideListenerError): %@ %@ %@", [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2]);
        
        avoidErrorMessageReentry = YES;
        if ([[NSUserDefaults standardUserDefaults] boolForKey: alertSuppress] == NO)
            NSRunCriticalAlertPanel( [msg objectAtIndex: 0], @"%@", [msg objectAtIndex: 2], nil, nil, [msg objectAtIndex: 1]);
        
        avoidErrorMessageReentry = NO;
    }
    else
        NSLog( @"*** listener error (not displayed - hideListenerError): %@ %@ %@", [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2]);
}

- (BOOL)setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset
{
	return [self setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset destination: nil];
}

- (void) requestAssociationThread: (NSMutableDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	T_ASC_Network *net = (T_ASC_Network*) [[dict objectForKey: @"net"] pointerValue];
	T_ASC_Parameters *params = (T_ASC_Parameters*) [[dict objectForKey: @"params"] pointerValue];
	NSRecursiveLock *lock = [dict objectForKey: @"lock"];
	
	[self retain];
	[dict retain];
	[lock retain];
	
	[lock lock];
	
    [NSThread currentThread].name = @"DCMTKQueryNode ASC_requestAssociation";
    
    T_ASC_Association *assoc = NULL;
    if( _abortAssociation == NO)
    {
        @try
        {
            OFCondition cond = ASC_requestAssociation(net, params, &assoc);
            globalCondition = cond;
            
            if( cond == EC_Normal)
                [dict setObject: [NSValue valueWithPointer: assoc] forKey: @"assoc"];
        }
        @catch (NSException* e) {
            if (_dontCatchExceptions)
                @throw e;
            if (![NSThread.currentThread isCancelled])
                N2LogExceptionWithStackTrace(e);
        }
    }
    
    if( _abortAssociation && assoc)
    {
        AbortAssociationTimeOut = 2;
        ASC_abortAssociation( assoc);
        AbortAssociationTimeOut = -1;
    }
	
	[lock unlock];
	[lock release];
	[dict release];
	[self autorelease];
	
	[pool release];
}


- (void) cFindThread: (NSMutableDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [NSThread currentThread].name = @"CFind Thread";
    
	T_ASC_Association *assoc = (T_ASC_Association*) [[dict objectForKey: @"assoc"] pointerValue];
	DcmDataset *dataset = (DcmDataset*) [[dict objectForKey: @"dataset"] pointerValue];
	NSRecursiveLock *lock = [dict objectForKey: @"lock"];
	
	[self retain];
	[dict retain];
	[lock retain];
	
	[lock lock];
	
	@try
	{
		OFCondition cond = [self cfind:assoc dataset:dataset];
		globalCondition = cond;
	}
    @catch (NSException* e) {
        if (_dontCatchExceptions)
            @throw e;
		if (![NSThread.currentThread isCancelled])
            N2LogExceptionWithStackTrace(e);
    }
	
	[lock unlock];
	[lock release];
	[dict release];
	[self autorelease];
	
	[pool release];
}

static NSMutableArray *releaseNetworkVariablesDictionaries = nil;
static NSString *releaseNetworkVariablesSync = @"releaseNetworkVariablesSync";

+ (void) releaseNetworkVariables
{
    @autoreleasepool {
	
    [NSThread currentThread].name = @"DCMTK Network release variables";
    
    while( 1) @autoreleasepool // Infinite loop
    {
        BOOL abortAssociations = [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"];
        
        NSArray *copyArray = nil;
        
        @synchronized( releaseNetworkVariablesDictionaries)
        {
            copyArray = [[releaseNetworkVariablesDictionaries copy] autorelease];
        }
        
        for( NSDictionary *dict in copyArray)
        {
            if( abortAssociations || [[dict valueForKey: @"date"] timeIntervalSinceNow] < -120) // seconds
            {
                T_ASC_Association *assoc = (T_ASC_Association*) [[dict objectForKey: @"assoc"] pointerValue];
                T_ASC_Network *net = (T_ASC_Network*) [[dict objectForKey: @"net"] pointerValue];
                DcmTLSTransportLayer *tLayer = (DcmTLSTransportLayer*) [[dict objectForKey: @"tLayer"] pointerValue];
                OFCondition cond;
                
                // CLEANUP
                
                /* destroy the association, i.e. free memory of T_ASC_Association* structure. This */
                /* call is the counterpart of ASC_requestAssociation(...) which was called above. */
                if( assoc)
                {
                    cond = ASC_destroyAssociation(&assoc);
                    if (cond.bad())
                        DimseCondition::dump(cond); 
                }
                
                /* drop the network, i.e. free memory of T_ASC_Network* structure. This call */
                /* is the counterpart of ASC_initializeNetwork(...) which was called above. */
                if( net)
                {
                    cond = ASC_dropNetwork(&net);
                    if (cond.bad())
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
                if( tLayer)
                    delete tLayer;
#endif
                @synchronized( releaseNetworkVariablesDictionaries)
                {
                    [releaseNetworkVariablesDictionaries removeObject: dict];
                }
            }
        }
        
        [NSThread sleepForTimeInterval: 1];
    }
    }
}

//common network code for move and query
- (BOOL)setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset destination:(NSString*) destination
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL succeed = YES;
	
	@try 
	{
		OFCondition cond;
		const char *opt_peer = NULL;
		OFCmdUnsignedInt opt_port = 104;
		const char *opt_peerTitle = PEERAPPLICATIONTITLE;
		const char *opt_ourTitle = APPLICATIONTITLE;
		
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
		_abortAssociation = NO;
		
	//
	//	
	//	//debug code activated for now
	//	_debug = OFTrue;
	//	DUL_Debug(OFTrue);
	//	DIMSE_debug(OFTrue);
	//	SetDebugLevel(3);
		
		if( strcmp(abstractSyntax, UID_GETPatientRootQueryRetrieveInformationModel) == 0 ||
			strcmp(abstractSyntax, UID_GETStudyRootQueryRetrieveInformationModel) == 0 ||
			strcmp(abstractSyntax, UID_GETPatientStudyOnlyQueryRetrieveInformationModel) == 0)
		{
			_networkTransferSyntax = (E_TransferSyntax) [[NSUserDefaults standardUserDefaults] integerForKey: @"preferredSyntaxForIncoming"];
		}
		else
			_networkTransferSyntax = EXS_LittleEndianExplicit;
		
		WaitRendering *wait = nil;
		
		if( [NSThread isMainThread] == YES)// && [[NSUserDefaults standardUserDefaults] boolForKey: @"dontUseThreadForAssociationAndCFind"] == NO)
		{
			wait = [[WaitRendering alloc] init: [NSString stringWithFormat: NSLocalizedString(@"Connecting to %@...", nil), _hostname]];
			[wait setCancel: YES];
			[wait start];
		}
		
		DcmTLSTransportLayer *tLayer = NULL;
		NSString *uniqueStringID = [NSString stringWithFormat:@"%d.%d.%d", getpid(), inc++, (int) random()];
		
	//	if (_secureConnection)
	//		[DDKeychain lockTmpFiles];
        
		@try
		{
			#ifdef WITH_OPENSSL		
			if(_cipherSuites)
			{
				const char *current = NULL;
				const char *currentOpenSSL;
				
				opt_ciphersuites.clear();
				
				for (NSString *suite in _cipherSuites)
				{
					current = [suite cStringUsingEncoding:NSUTF8StringEncoding];
					
					if (NULL == (currentOpenSSL = DcmTLSTransportLayer::findOpenSSLCipherSuiteName(current)))
					{
						NSLog(@"ciphersuite '%s' is unknown.", current);
						NSLog(@"Known ciphersuites are:");
						unsigned long numSuites = DcmTLSTransportLayer::getNumberOfCipherSuites();
						for (unsigned long cs=0; cs < numSuites; cs++)
						{
							NSLog(@"%s", DcmTLSTransportLayer::getTLSCipherSuiteName(cs));
						}
						
                        [[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat:@"Ciphersuite '%s' is unknown.", current] userInfo:nil] raise];
					}
					else
					{
						if (opt_ciphersuites.length() > 0) opt_ciphersuites += ":";
						opt_ciphersuites += currentOpenSSL;
					}
					
				}
			}
			
			#endif

			/* make sure data dictionary is loaded */
			if (!dcmDataDict.isDictionaryLoaded()) {
				fprintf(stderr, "Warning: no data dictionary loaded, check environment variable: %s\n",
						DCM_DICT_ENVIRONMENT_VARIABLE);
			}
			
			/* initialize network, i.e. create an instance of T_ASC_Network*. */
			cond = ASC_initializeNetwork(NET_REQUESTOR, 0, _acse_timeout, &net);
			if (cond.bad())
			{
                if (_verbose)
                    DimseCondition::dump(cond);
                [[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"ASC_initializeNetwork - %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
			}
			
		#ifdef WITH_OPENSSL // joris
				
			if (_secureConnection)
			{
				[DDKeychain generatePseudoRandomFileToPath:TLS_SEED_FILE];
				tLayer = new DcmTLSTransportLayer(DICOM_APPLICATION_REQUESTOR, _readSeedFile);
				if (tLayer == NULL)
				{
					NSLog(@"unable to create TLS transport layer");
					[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:@"unable to create TLS transport layer" userInfo:nil] raise];
				}
				
				if(certVerification==VerifyPeerCertificate || certVerification==RequirePeerCertificate)
				{
					NSString *trustedCertificatesDir = [NSString stringWithFormat:@"%@%@", TLS_TRUSTED_CERTIFICATES_DIR, uniqueStringID];
					[DDKeychain KeychainAccessExportTrustedCertificatesToDirectory:trustedCertificatesDir];
					NSArray *trustedCertificates = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:trustedCertificatesDir error:nil];
					
					for (NSString *cert in trustedCertificates)
					{
						if (TCS_ok != tLayer->addTrustedCertificateFile([[trustedCertificatesDir stringByAppendingPathComponent:cert] cStringUsingEncoding:NSUTF8StringEncoding], _keyFileFormat))
						{
							[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat:@"Unable to load certificate file %@", [trustedCertificatesDir stringByAppendingPathComponent:cert]] userInfo:nil] raise];
						}
					}
							//--add-cert-dir //// add certificates in d to list of certificates
							//.... needs to use OpenSSL & rename files (see http://forum.dicom-cd.de/viewtopic.php?p=3237&sid=bd17bd76876a8fd9e7fdf841b90cf639 )
							
							//			if (cmd.findOption("--add-cert-dir", 0, OFCommandLine::FOM_First))
							//			{
							//				const char *current = NULL;
							//				do
							//				{
							//					app.checkValue(cmd.getValue(current));
							//					if (TCS_ok != tLayer->addTrustedCertificateDir(current, opt_keyFileFormat))
							//					{
							//						CERR << "warning unable to load certificates from directory '" << current << "', ignoring" << endl;
							//					}
							//				} while (cmd.findOption("--add-cert-dir", 0, OFCommandLine::FOM_Next));
							//			}
				}		
				
				if (_dhparam && ! (tLayer->setTempDHParameters(_dhparam)))
				{
					[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat:@"Unable to load temporary DH parameter file %s", _dhparam] userInfo:nil] raise];
				}
				
				if (_doAuthenticate)
				{				
					tLayer->setPrivateKeyPasswd([[DICOMTLS TLS_PRIVATE_KEY_PASSWORD] cStringUsingEncoding:NSUTF8StringEncoding]);
					
					[DICOMTLS generateCertificateAndKeyForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID]; // export certificate/key from the Keychain to the disk
					
					NSString *_privateKeyFile = [DICOMTLS keyPathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID]; // generates the PEM file for the private key
					NSString *_certificateFile = [DICOMTLS certificatePathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID]; // generates the PEM file for the certificate
					
					if (TCS_ok != tLayer->setPrivateKeyFile([_privateKeyFile cStringUsingEncoding:NSUTF8StringEncoding], SSL_FILETYPE_PEM))
					{
						[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat:@"Unable to load private TLS key from %@", _privateKeyFile] userInfo:nil] raise];
					}
					
					if (TCS_ok != tLayer->setCertificateFile([_certificateFile cStringUsingEncoding:NSUTF8StringEncoding], SSL_FILETYPE_PEM))
					{
						[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat:@"Unable to load certificate from %@", _certificateFile] userInfo:nil] raise];
					}
					
					if (!tLayer->checkPrivateKeyMatchesCertificate())
					{
						[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat:@"private key '%@' and certificate '%@' do not match", _privateKeyFile, _certificateFile] userInfo:nil] raise];
					}
				}
				
				if (TCS_ok != tLayer->setCipherSuites(opt_ciphersuites.c_str()))
				{
					[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:@"Unable to set selected cipher suites" userInfo:nil] raise];
				}
				
				DcmCertificateVerification _certVerification;
				
				if(certVerification==RequirePeerCertificate)
					_certVerification = DCV_requireCertificate;
				else if(certVerification==VerifyPeerCertificate)
					_certVerification = DCV_checkCertificate;
				else
					_certVerification = DCV_ignoreCertificate;
				
				tLayer->setCertificateVerification(_certVerification);
				
				cond = ASC_setTransportLayer(net, tLayer, 0);
				if (cond.bad())
				{
                    if (_verbose)
                        DimseCondition::dump(cond);
					[[NSException exceptionWithName:@"DICOM Network Failure (TLS query)" reason:[NSString stringWithFormat: @"ASC_setTransportLayer - %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
				}
			}

		#endif
			
			
		/* initialize asscociation parameters, i.e. create an instance of T_ASC_Parameters*. */
			cond = ASC_createAssociationParameters(&params, _maxReceivePDULength);
	//		DimseCondition::dump(cond);
			if (cond.bad()) {
                if (_verbose)
                    DimseCondition::dump(cond);
				[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"ASC_createAssociationParameters - %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
			}
			
			/* sets this application's title and the called application's title in the params */
			/* structure. The default values to be set here are "STORESCU" and "ANY-SCP". */
			ASC_setAPTitles(params, opt_ourTitle, opt_peerTitle, NULL);

			/* Set the transport layer type (type of network connection) in the params */
			/* strucutre. The default is an insecure connection; where OpenSSL is  */
			/* available the user is able to request an encrypted,secure connection. */
			cond = ASC_setTransportLayerType(params, _secureConnection);
			if (cond.bad()) {
                if (_verbose)
                    DimseCondition::dump(cond);
				[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"ASC_setTransportLayerType - %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
			}
			
			/* Figure out the presentation addresses and copy the */
			/* corresponding values into the association parameters.*/
			gethostname(localHost, sizeof(localHost) - 1);
			sprintf(peerHost, "%s:%d", opt_peer, (int)opt_port);
			//NSLog(@"peer host: %s", peerHost);
			ASC_setPresentationAddresses(params, localHost, peerHost);	//localHost
			
			/* Set the presentation contexts which will be negotiated */
			/* when the network connection will be established */
			/*
			abstract syntax should be 
			UID_MOVEStudyRootQueryRetrieveInformationModel
			UID_FINDStudyRootQueryRetrieveInformationModel
			UID_GETStudyRootQueryRetrieveInformationModel
			*/
			cond = [self addPresentationContext:params abstractSyntax:abstractSyntax];
			
			if (cond.bad())
			{
                if (_verbose)
                    DimseCondition::dump(cond);
				[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"addPresentationContext - %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
			}

			/* dump presentation contexts if required */
			if (_verbose)
			{
				if( strcmp(abstractSyntax, UID_GETPatientRootQueryRetrieveInformationModel) == 0 ||
				strcmp(abstractSyntax, UID_GETStudyRootQueryRetrieveInformationModel) == 0 ||
				strcmp(abstractSyntax, UID_GETPatientStudyOnlyQueryRetrieveInformationModel) == 0)
				{
				
				}
				else
				{
					printf("Request Parameters:\n");
					ASC_dumpParameters(params, COUT);
				}
			}
			
			/* create association, i.e. try to establish a network connection to another */
			/* DICOM application. This call creates an instance of T_ASC_Association*. */
			if (_verbose)
				printf("Requesting Association\n");
			
//			if( [NSThread isMainThread] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"dontUseThreadForAssociationAndCFind"] == NO)
			{
				NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
				NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: lock, @"lock", [NSValue valueWithPointer: net], @"net", [NSValue valueWithPointer: params], @"params", nil];
				
				globalCondition = EC_Normal;
                
                [NSThread detachNewThreadSelector: @selector(requestAssociationThread:) toTarget: self withObject: dict];
				[NSThread sleepForTimeInterval: 0.05];
				
				while( [wait aborted] == NO && _abortAssociation == NO && [NSThread currentThread].isCancelled == NO && [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"] == NO)
				{
					[wait run];
					[NSThread sleepForTimeInterval: 0.05];
                    
                    if( [lock tryLock])
                    {
                        [lock unlock];
                        break;
                    }
				}
				
				if( [wait aborted] || _abortAssociation || [NSThread currentThread].isCancelled || [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"])
				{
					_abortAssociation = YES;
					cond = DUL_NETWORKCLOSED;
				}
				else
					cond = globalCondition;
                
                if( [dict objectForKey: @"assoc"])
                    assoc = (T_ASC_Association *) [[dict objectForKey: @"assoc"] pointerValue];
                else
                    cond = EC_IllegalParameter;
				
				if( cond != EC_Normal)
				{
					[wait end];
					[wait autorelease];
					wait = nil;
				}
				
				[lock release];
			}
//			else cond = ASC_requestAssociation(net, params, &assoc);
			
			if (cond.bad())
			{
				if (cond == DUL_ASSOCIATIONREJECTED)
				{
                    if (_verbose) {
                        T_ASC_RejectParameters rej;
                        ASC_getRejectParameters(params, &rej);
                        errmsg("Association Rejected:");
                        ASC_printRejectParameters(stderr, &rej);
                        
                    }
					[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"Association Rejected : %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];

				}
				else
				{
                    if (_verbose) {
                        errmsg("Association Request Failed:");
                        DimseCondition::dump(cond);
                    }
					[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"Association Request Failed : %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
				}
			}
			
			  /* dump the presentation contexts which have been accepted/refused */
			if (_verbose)
			{
				if( strcmp(abstractSyntax, UID_GETPatientRootQueryRetrieveInformationModel) == 0 ||
				strcmp(abstractSyntax, UID_GETStudyRootQueryRetrieveInformationModel) == 0 ||
				strcmp(abstractSyntax, UID_GETPatientStudyOnlyQueryRetrieveInformationModel) == 0)
				{
	//				printf("Association Parameters Negotiated:\n");
	//				ASC_dumpParameters(params, COUT);
				}
				else
				{
					printf("Association Parameters Negotiated:\n");
					ASC_dumpParameters(params, COUT);
				}
			}
			
				/* count the presentation contexts which have been accepted by the SCP */
			/* If there are none, finish the execution */
			if (ASC_countAcceptedPresentationContexts(params) == 0) {
				errmsg("No Acceptable Presentation Contexts");
				[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"No acceptable presentation contexts" userInfo:nil] raise];
			}
			
			//specific for Move vs find
			if (strcmp(abstractSyntax, UID_FINDStudyRootQueryRetrieveInformationModel) == 0)
			{
				if (cond == EC_Normal) // compare with EC_Normal since DUL_PEERREQUESTEDRELEASE is also good()
				{
//					if( [NSThread isMainThread] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"dontUseThreadForAssociationAndCFind"] == NO)
					{
						NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
						NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: lock, @"lock", [NSValue valueWithPointer: assoc], @"assoc", [NSValue valueWithPointer: dataset], @"dataset", nil];
						
						globalCondition = EC_Normal;
						[NSThread detachNewThreadSelector: @selector(cFindThread:) toTarget: self withObject: dict];
						[NSThread sleepForTimeInterval: 0.05];
						
						while( [wait aborted] == NO && _abortAssociation == NO && [NSThread currentThread].isCancelled == NO && [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"] == NO)
						{
							[wait run];
							[NSThread sleepForTimeInterval: 0.05];
                            
                            if( [lock tryLock])
                            {
                                [lock unlock];
                                break;
                            }
						}
						
						if( [wait aborted] || _abortAssociation || [NSThread currentThread].isCancelled || [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"])
						{
							_abortAssociation = YES;
							cond = DUL_NETWORKCLOSED;
						}
						else
						{
							cond = globalCondition;
						}
						[lock release];
						
						[wait end];
						[wait autorelease];
						wait = nil;
					}
//					else cond = [self cfind:assoc dataset:dataset];
				}
			}
			else if (strcmp(abstractSyntax, UID_MOVEStudyRootQueryRetrieveInformationModel) == 0)
			{
				if( destination) cond = [self cmove:assoc network:net dataset:dataset destination: (char*) [destination UTF8String]];
				else cond = [self cmove:assoc network:net dataset:dataset];
			}
			else if (strcmp(abstractSyntax, UID_GETStudyRootQueryRetrieveInformationModel) == 0 || strcmp(abstractSyntax, UID_GETPatientStudyOnlyQueryRetrieveInformationModel) == 0)
			{
				cond = [self cget:assoc network:net dataset:dataset];
			}
			else
			{
				NSLog(@"Q/R SCU bad Abstract Sytnax: %s", abstractSyntax);
				//shouldn't get here
			}
			
			/* tear down association, i.e. terminate network connection to SCP */
			if (cond == EC_Normal)
			{
				if (_abortAssociation)
				{
					if (_verbose)
						printf("Aborting Association\n");
						
					AbortAssociationTimeOut = 2;
					cond = ASC_abortAssociation(assoc);
					AbortAssociationTimeOut = -1;
					
					if (cond.bad())
					{
                        if (_verbose) {
                            errmsg("Association Abort Failed:");
                            DimseCondition::dump(cond);
                        }
                        [[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"Association Abort Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
					}
				}
				else
				{
					/* release association */
					if (_verbose)
						printf("Releasing Association\n");
					cond = ASC_releaseAssociation(assoc);
					if (cond.bad())
					{
                        if (_verbose) {
                            errmsg("Association Release Failed:");
                            DimseCondition::dump(cond);
                        }
                        [[NSException exceptionWithName:@"DICOM Network Failure (query)" reason:[NSString stringWithFormat: @"Association Release Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] raise];
					}
				}
			}
			else if (cond == DUL_PEERREQUESTEDRELEASE)
			{
				errmsg("Protocol Error: peer requested release (Aborting)");
				if (_verbose)
					printf("Aborting Association\n");
				
                NSString *reason = [NSString stringWithFormat: @"Protocol Error: peer requested release (Aborting) %04x:%04x %s", cond.module(), cond.code(), cond.text()];
				
				AbortAssociationTimeOut = 2;
				cond = ASC_abortAssociation(assoc);
				AbortAssociationTimeOut = -1;
				
				if (cond.bad())
				{
                    if (_verbose) {
                        errmsg("Association Abort Failed:");
                        DimseCondition::dump(cond);
                    }
				}
				[[NSException exceptionWithName:@"DICOM Network Failure (query)" reason: reason userInfo:nil] raise];
			}
			else if (cond == DUL_PEERABORTEDASSOCIATION)
			{
				if (_verbose) printf("Peer Aborted Association\n");
			}
			else
			{
				if (_verbose) {
                    errmsg("SCU Failed:");
                    DimseCondition::dump(cond);
					printf("Aborting Association\n");
				}
                
                NSString *reason = [NSString stringWithFormat: @"SCU Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()];
                
				AbortAssociationTimeOut = 2;
				cond = ASC_abortAssociation(assoc);
				AbortAssociationTimeOut = -1;
				
				if (cond.bad())
				{
                    if (_verbose) {
                        errmsg("Association Abort Failed:");
                        DimseCondition::dump(cond);
                    }
				}
				
				[[NSException exceptionWithName: @"DICOM Network Failure (query)" reason: reason userInfo:nil] raise];
			}
		}
		@catch (NSException *e)
		{
			NSString *response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r%@\r%@", _calledAET, _hostname, _port, [e name], [e description]];
			
            if (_abortAssociation == NO)
            {
                if( showErrorMessage == YES)
                    [DCMTKQueryNode performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Query Failed (1)", nil), response, NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
                else
                    [[AppController sharedAppController] growlTitle: NSLocalizedString(@"Query Failed (1)", nil) description: response name: @"autoquery"];
			}
            
            NSLog(@"---- DCMTKQueryNode failed: %@", e);
            
			succeed = NO;
            
            [NSThread sleepForTimeInterval: 0.05];
		}
        @finally {
            [wait end];
            [wait autorelease];
            wait = nil;
        }
		
		//We want to give time for other threads that are maybe using assoc or net variables
        @synchronized( releaseNetworkVariablesSync)
        {
            if( releaseNetworkVariablesDictionaries == nil)
            {
                releaseNetworkVariablesDictionaries = [[NSMutableArray array] retain];
                [NSThread detachNewThreadSelector: @selector(releaseNetworkVariables) toTarget: [DCMTKQueryNode class] withObject: nil];
            }
        }
        
        @synchronized( releaseNetworkVariablesDictionaries)
        {
            [releaseNetworkVariablesDictionaries addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], @"date", [NSValue valueWithPointer: assoc], @"assoc", [NSValue valueWithPointer: net], @"net", [NSValue valueWithPointer: tLayer], @"tLayer", nil]];
        }
        
//		// CLEANUP
//		
//		/* destroy the association, i.e. free memory of T_ASC_Association* structure. This */
//		/* call is the counterpart of ASC_requestAssociation(...) which was called above. */
//		if( assoc)
//		{
//			cond = ASC_destroyAssociation(&assoc);
//			if (cond.bad())
//				DimseCondition::dump(cond); 
//		}
//		
//		/* drop the network, i.e. free memory of T_ASC_Network* structure. This call */
//		/* is the counterpart of ASC_initializeNetwork(...) which was called above. */
//		if( net)
//		{
//			cond = ASC_dropNetwork(&net);
//			if (cond.bad())
//				DimseCondition::dump(cond);
//		}
//
//	#ifdef WITH_OPENSSL
//	/*
//		if (tLayer && opt_writeSeedFile)
//		{
//		  if (tLayer->canWriteRandomSeed())
//		  {
//			if (!tLayer->writeRandomSeed(opt_writeSeedFile))
//			{
//			  CERR << "Error while writing random seed file '" << opt_writeSeedFile << "', ignoring." << endl;
//			}
//		  } else {
//			CERR << "Warning: cannot write random seed, ignoring." << endl;
//		  }
//		}
//		delete tLayer;
//	*/
//		if( tLayer)
//			delete tLayer;
	
		
	#ifdef WITH_OPENSSL
		// cleanup
		if (_secureConnection)
		{
	//		[DDKeychain unlockTmpFiles];
			[[NSFileManager defaultManager] removeItemAtPath:[DICOMTLS keyPathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID] error:NULL];
			[[NSFileManager defaultManager] removeItemAtPath:[DICOMTLS certificatePathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID] error:NULL];
			[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", TLS_TRUSTED_CERTIFICATES_DIR, uniqueStringID] error:NULL];
		}
	#endif
	}
	@catch (NSException* e)
	{
        if (_dontCatchExceptions)
            @throw e;
		if (![NSThread.currentThread isCancelled])
            N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [pool release];
	}
    
	return succeed;
}

- (OFCondition)findSCU:(T_ASC_Association *)assoc dataset:( DcmDataset *)dataset 
    /*
     * This function will read all the information from the given file
     * (this information specifies a search mask), figure out a corresponding
     * presentation context which will be used to transmit a C-FIND-RQ message
     * over the network to the SCP, and it will finally initiate the transmission
     * of data to the SCP.
     *
     * Parameters:
     *   assoc - [in] The association (network connection to another DICOM application).
     *   fname - [in] Name of the file which shall be processed.
     */
{
    DIC_US msgId = assoc->nextMsgID++;
    T_ASC_PresentationContextID presId;
    T_DIMSE_C_FindRQ req;
    T_DIMSE_C_FindRSP rsp;
    DcmDataset *statusDetail = NULL;
    MyCallbackInfo callbackData;
    
    /* figure out which of the accepted presentation contexts should be used */
    presId = ASC_findAcceptedPresentationContextID(
        assoc, UID_FINDStudyRootQueryRetrieveInformationModel);
    if (presId == 0)
	{
        errmsg("No presentation context");
        return DIMSE_NOVALIDPRESENTATIONCONTEXTID;
    }
	
    /* prepare the transmission of data */
    bzero((char*)&req, sizeof(req));
    req.MessageID = msgId;
    strcpy(req.AffectedSOPClassUID, UID_FINDStudyRootQueryRetrieveInformationModel);
    req.DataSetType = DIMSE_DATASET_PRESENT;
    req.Priority = DIMSE_PRIORITY_LOW;

    /* prepare the callback data */
    callbackData.assoc = assoc;
    callbackData.presId = presId;
	callbackData.node = self;

    /* if required, dump some more general information */
    if (_verbose)
	{
        printf("Find SCU RQ: MsgID %d\n", msgId);
        printf("REQUEST:\n");
        dataset->print(COUT);
        printf("--------\n");
    }

    /* finally conduct transmission of data */
    OFCondition cond = DIMSE_findUser(assoc, presId, &req, dataset,
                          progressCallback, &callbackData,
                          DIMSE_NONBLOCKING, _dimse_timeout,	// DIMSE_BLOCKING - _blockMode ANR 2009
                          &rsp, &statusDetail);


    /* dump some more general information */
    if (cond == EC_Normal)
	{
		if( rsp.DimseStatus != STATUS_Success && rsp.DimseStatus != STATUS_Pending)
		{
			NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", _calledAET, _hostname, _port];
			
			response = [response stringByAppendingString: [NSString stringWithUTF8String: DU_cfindStatusString(rsp.DimseStatus)]];
			
			 if (statusDetail != NULL)
			 {
				OFOStringStream oss;
				
				statusDetail->print( oss);
				OFSTRINGSTREAM_GETSTR(oss, tmpString)
				response = [response stringByAppendingFormat:@"\r\r\r%s", tmpString];
				OFSTRINGSTREAM_FREESTR(tmpString)
			  }
			
			if( showErrorMessage == YES && _abortAssociation == NO)
				[DCMTKQueryNode performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Query Failed (2)", nil), response, NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
			else
				[[AppController sharedAppController] growlTitle: NSLocalizedString(@"Query Failed (2)", nil) description: response name: @"autoquery"];
				
		}
				
        if (_verbose)
		{
            DIMSE_printCFindRSP(stdout, &rsp);
        }
		else
		{
            if (rsp.DimseStatus != STATUS_Success)
			{
                printf("Response: %s\n", DU_cfindStatusString(rsp.DimseStatus));
				
				
            }
        }
    }
	else
	{
        if (_verbose) {
            errmsg("Find Failed\n Condition:\n");
            //dataset->print(COUT);
            DimseCondition::dump(cond);
            NSLog(@"Dimse Status: %@", [NSString stringWithUTF8String: DU_cfindStatusString(rsp.DimseStatus)]);
        }
    }

    /* dump status detail information if there is some */
    if (statusDetail != NULL) {
        if (_verbose) {
            printf("  Status Detail:\n");
            statusDetail->print(COUT);
        }
        delete statusDetail;
    }

    /* return */
    return cond;
}

- (OFCondition) cfind:(T_ASC_Association *)assoc dataset:(DcmDataset *)dataset
    /*
     * This function will process the given file as often as is specified by opt_repeatCount.
     * "Process" in this case means "read file, send C-FIND-RQ, receive C-FIND-RSP messages".
     *
     * Parameters:
     *   assoc - [in] The association (network connection to another DICOM application).
     *   fname - [in] Name of the file which shall be processed (contains search mask information).
     */
{
    OFCondition cond = EC_Normal;

    /* opt_repeatCount specifies how many times a certain file shall be processed */
    //int n = (int)_repeatCount;
	int n = 1;
    /* as long as no error occured and the counter does not equal 0 */
    while (cond == EC_Normal && n--) {
        /* process file (read file, send C-FIND-RQ, receive C-FIND-RSP messages) */
        cond = [self findSCU:assoc dataset:dataset];
    }

    /* return result value */
    return cond;
}

- (OFCondition) cmove:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset
{
	return [self cmove:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset destination: (char*) nil];
}

- (OFCondition) cmove:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset destination: (char*) destination
{
    /* opt_repeatCount specifies how many times a certain file shall be processed */
    //int n = (int)_repeatCount;
	int n = 1;
	OFCondition cond = EC_Normal;
    /* as long as no error occured and the counter does not equal 0 */
	//only do move if we aren't already moving
    while (cond == EC_Normal && n-- && ![[MoveManager sharedManager] containsMove:self]) {
        /* process file (read file, send C-FIND-RQ, receive C-FIND-RSP messages) */
        cond = [self moveSCU:assoc network:(T_ASC_Network *)net dataset:dataset destination: destination];
    }

    /* return result value */
    return cond;
}

- (OFCondition) cget:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset
{
    /* opt_repeatCount specifies how many times a certain file shall be processed */
    //int n = (int)_repeatCount;
	int n = 1;
	OFCondition cond = EC_Normal;
    /* as long as no error occured and the counter does not equal 0 */
	//only do move if we aren't already moving
    while (cond == EC_Normal && n-- && ![[MoveManager sharedManager] containsMove:self]) {
        /* process file (read file, send C-FIND-RQ, receive C-FIND-RSP messages) */
        cond = [self getSCU:assoc network:(T_ASC_Network *)net dataset:dataset];
    }

    /* return result value */
    return cond;
}

- (OFCondition)moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset
{
	return [self moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset destination: nil];
}

- (OFCondition)moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset destination: (char*) destination
{
	T_ASC_PresentationContextID presId;
    T_DIMSE_C_MoveRQ    req;
    T_DIMSE_C_MoveRSP   rsp;
    DIC_US              msgId = assoc->nextMsgID++;
    DcmDataset          *rspIds = NULL;
    DcmDataset          *statusDetail = NULL;
    MyCallbackInfo      callbackData;
	OFCondition			cond = EC_Normal;
	
   // sopClass = querySyntax[opt_queryModel].moveSyntax;

    /* which presentation context should be used */
    presId = ASC_findAcceptedPresentationContextID(assoc, UID_MOVEStudyRootQueryRetrieveInformationModel);
    if (presId == 0) return DIMSE_NOVALIDPRESENTATIONCONTEXTID;

	//add self to list of moves. Prevents deallocating  the move if a new query is done
	[[MoveManager sharedManager] addMove:self];
	
	@try
	{
		if (_verbose)
		{
			printf("Move SCU RQ: MsgID %d\n", msgId);
			printf("Request:\n");
			dataset->print(COUT);
		}

		/* prepare the callback data */
		callbackData.assoc = assoc;
		callbackData.presId = presId;
		callbackData.node = self;

		req.MessageID = msgId;
		strcpy(req.AffectedSOPClassUID, UID_MOVEStudyRootQueryRetrieveInformationModel);
		req.Priority = DIMSE_PRIORITY_MEDIUM;
		req.DataSetType = DIMSE_DATASET_PRESENT;
	 
		if( destination)
			strcpy(req.MoveDestination, destination);
		else
		{
			/* set the destination to be me */
			ASC_getAPTitles(assoc->params, req.MoveDestination, NULL, NULL);
		}
		
		cond = DIMSE_moveUser(assoc, presId, &req, dataset,
			moveCallback, &callbackData, _blockMode, _dimse_timeout, //  _blockMode
			net, subOpCallback, NULL,
			&rsp, &statusDetail, &rspIds , OFTrue);
		
        self.countOfSuboperations = rsp.NumberOfCompletedSubOperations+rsp.NumberOfFailedSubOperations+rsp.NumberOfWarningSubOperations+rsp.NumberOfRemainingSubOperations;
        self.countOfSuccessfulSuboperations = rsp.NumberOfCompletedSubOperations;
        
		if (cond == EC_Normal)
		{
			if( DICOM_WARNING_STATUS(rsp.DimseStatus))
			{
				 DIMSE_printCMoveRSP(stdout, &rsp);
			}
			else if (DICOM_PENDING_STATUS(rsp.DimseStatus))
			{
				 DIMSE_printCMoveRSP(stdout, &rsp);
			}
			else if( rsp.DimseStatus != STATUS_Success && rsp.DimseStatus != STATUS_Pending)
			{
				DIMSE_printCMoveRSP(stdout, &rsp);
				
                if( showErrorMessage)
                    [DCMTKQueryNode performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Move Failed", nil), [NSString stringWithUTF8String: DU_cmoveStatusString(rsp.DimseStatus)], NSLocalizedString(@"Continue", nil), nil] waitUntilDone: NO];
			}
			
			if (_verbose)
			{
				DIMSE_printCMoveRSP(stdout, &rsp);
				if (rspIds != NULL) {
					printf("Response Identifiers:\n");
					rspIds->print(COUT);
				}
			}
		}
		else
		{
            if (showErrorMessage)
                [DCMTKQueryNode performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Move Failed", nil), [NSString stringWithUTF8String: cond.text()], NSLocalizedString(@"Continue", nil), nil] waitUntilDone: NO];
            if (_verbose) {
                errmsg("Move Failed:");
                DimseCondition::dump(cond);
            }
		}
	}
	@catch (NSException* e)
	{
        if (_dontCatchExceptions)
            @throw e;
		if (![NSThread.currentThread isCancelled])
            N2LogExceptionWithStackTrace(e);
	}
    @finally
    {
        if (statusDetail != NULL) {
            printf("  Status Detail:\n");
            statusDetail->print(COUT);
            delete statusDetail;
        }
        
        if (rspIds != NULL) delete rspIds;
        
        [[MoveManager sharedManager] removeMove:self];
    }
	
    return cond;
}

- (OFCondition)getSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset
{
	//add self to list of moves. Prevents deallocating  the move if a new query is done
	[[MoveManager sharedManager] addMove:self];

	T_ASC_PresentationContextID presId;
    T_DIMSE_C_GetRQ    req;
    T_DIMSE_C_GetRSP   rsp;
    DIC_US              msgId = assoc->nextMsgID++;
    DcmDataset          *rspIds = NULL;
    DcmDataset          *statusDetail = NULL;
    MyCallbackInfo      callbackData;
		
   // sopClass = querySyntax[opt_queryModel].moveSyntax;

    /* which presentation context should be used */
    presId = ASC_findAcceptedPresentationContextID(assoc, UID_GETStudyRootQueryRetrieveInformationModel); //UID_GETStudyRootQueryRetrieveInformationModel UID_GETPatientStudyOnlyQueryRetrieveInformationModel
    if (presId == 0) return DIMSE_NOVALIDPRESENTATIONCONTEXTID;

    if (_verbose)
	{
        printf("Get SCU RQ: MsgID %d\n", msgId);
        printf("Request:\n");
        dataset->print(COUT);
    }
	
    /* prepare the callback data */
    callbackData.assoc = assoc;
    callbackData.presId = presId;
	callbackData.node = self;
	
    req.MessageID = msgId;
    strcpy(req.AffectedSOPClassUID, UID_GETStudyRootQueryRetrieveInformationModel); //UID_GETStudyRootQueryRetrieveInformationModel UID_GETPatientStudyOnlyQueryRetrieveInformationModel
    req.Priority = DIMSE_PRIORITY_MEDIUM;
    req.DataSetType = DIMSE_DATASET_PRESENT;
 
//	if( destination)
//	{
//		strcpy(req.MoveDestination, destination);
//	}
//	else
//	{
//		/* set the destination to be me */
//		ASC_getAPTitles(assoc->params, req.MoveDestination, NULL, NULL);
//	}
	
	OFCondition cond;
	
	cond = DIMSE_getUser(assoc, presId, &req, dataset, getCallback, &callbackData, _blockMode, _dimse_timeout, net, subOpCallback, NULL, &rsp, &statusDetail, &rspIds);
	
    self.countOfSuboperations = rsp.NumberOfCompletedSubOperations+rsp.NumberOfFailedSubOperations+rsp.NumberOfWarningSubOperations+rsp.NumberOfRemainingSubOperations;
    self.countOfSuccessfulSuboperations = rsp.NumberOfCompletedSubOperations;
    
    if (cond == EC_Normal)
	{
		if( DICOM_WARNING_STATUS(rsp.DimseStatus))
		{
			 DIMSE_printCGetRSP(stdout, &rsp);
		}
		else if (DICOM_PENDING_STATUS(rsp.DimseStatus))
		{
			 DIMSE_printCGetRSP(stdout, &rsp);
		}
		else if( rsp.DimseStatus != STATUS_Success && rsp.DimseStatus != STATUS_Pending)
		{
			DIMSE_printCGetRSP(stdout, &rsp);
			
            if( showErrorMessage)
                [DCMTKQueryNode performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Get Failed", nil), [NSString stringWithUTF8String: DU_cmoveStatusString(rsp.DimseStatus)], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
		}
		
        if (_verbose)
		{
            DIMSE_printCGetRSP(stdout, &rsp);
            if (rspIds != NULL)
			{
                printf("Response Identifiers:\n");
                rspIds->print(COUT);
			}
        }
    }
	else
	{
        if( showErrorMessage)
            [DCMTKQueryNode performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Get Failed", nil), [NSString stringWithUTF8String: cond.text()], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
        if (_verbose) {
            errmsg("Get Failed:");
            DimseCondition::dump(cond);
        }
    }
	
    if (statusDetail != NULL)
	{
        printf("  Status Detail:\n");
        statusDetail->print(COUT);
        delete statusDetail;
    }
	
    if (rspIds != NULL) delete rspIds;
	
	[[MoveManager sharedManager] removeMove:self];
	
    return cond;
}

- (NSManagedObject *)logEntry{
	return _logEntry;
}

- (void)setLogEntry:(NSManagedObject *)logEntry{
	if( logEntry == _logEntry) return;

	[_logEntry release];
	_logEntry = [logEntry retain];
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"QueryNode: %@ %@ %@ %@", _name, _accessionNumber, _modality, _calledAET];
}

#pragma mark Max simultaneous auto-retrieve requests

static NSMutableDictionary* semaphores = [[NSMutableDictionary alloc] init];
//static const MPSemaphoreCount virtualLimit = 1000; // this value must higher that the maximum possible number of allowed simultaneous retrieves... the GUI limit is currently 9

+ (dispatch_semaphore_t)semaphoreForServerHostAndPort:(NSString*)key { // this method can lock the thread (that happens when the user has diminished the limit and requests are already past the limit)
    dispatch_semaphore_t mpsid = nil;
    
    @synchronized (semaphores) {
        long mpsc = [NSUserDefaults.standardUserDefaults integerForKey:@"MaxConcurrentPODRetrieves"];
        NSArray* a = [semaphores objectForKey:key];
        if (a) {
            mpsid = (dispatch_semaphore_t)[[a objectAtIndex:0] pointerValue];
            N2MutableUInteger* mui = [a objectAtIndex:1];
            while (mui.unsignedIntegerValue > mpsc) {
                dispatch_semaphore_wait(mpsid, DISPATCH_TIME_FOREVER); // this may cause this method to take a long time to return
                [mui decrement];
            }
            while (mui.unsignedIntegerValue < mpsc) {
                dispatch_semaphore_signal(mpsid);
                [mui increment];
            }
        } else {
            mpsid = dispatch_semaphore_create(mpsc);
            [semaphores setObject:[NSArray arrayWithObjects: [NSValue valueWithPointer:mpsid], [N2MutableUInteger mutableUIntegerWithUInteger:mpsc], nil] forKey:key];
        }
    }
    
    return mpsid;
}


























@end
