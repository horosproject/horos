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


#import "DCMTKQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
#import "DICOMToNSString.h"
#import "MoveManager.h"
#import "browserController.h"

#undef verify
#include "osconfig.h" /* make sure OS specific configuration is included first */

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

#define OFFIS_CONSOLE_APPLICATION "findscu"

static char rcsid[] = "$dcmtk: " OFFIS_CONSOLE_APPLICATION " v"
  OFFIS_DCMTK_VERSION " " OFFIS_DCMTK_RELEASEDATE " $";

/* default application titles */
#define APPLICATIONTITLE        "FINDSCU"
#define PEERAPPLICATIONTITLE    "ANY-SCP"



#ifdef WITH_OPENSSL

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
static OFString    opt_ciphersuites(TLS1_TXT_RSA_WITH_AES_128_SHA ":" SSL3_TXT_RSA_DES_192_CBC3_SHA);
#else
static OFString    opt_ciphersuites(SSL3_TXT_RSA_DES_192_CBC3_SHA);
#endif

#endif

NSException* queryException;
int debugLevel = 1;

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

	if (debugLevel > 0) {
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
	return;
	
//	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO) return;
//	
//	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
//	if( context == 0L) return;
//	
//    OFCondition cond = EC_Normal;
//    MyCallbackInfo *myCallbackData;
//
//    myCallbackData = (MyCallbackInfo*)callbackData;
//	DCMTKQueryNode *node = myCallbackData -> node;
//
//	NSManagedObject *logEntry = [node logEntry];
//	if (!logEntry)
//	{
//		[context retain];
//		[context lock];
//		
//		@try {
//		logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
//		[logEntry setValue:[NSDate date] forKey:@"startTime"];
//		[logEntry setValue:@"Move" forKey:@"type"];
//		[logEntry setValue:[node calledAET] forKey:@"destinationName"];
//		[logEntry setValue:[node callingAET] forKey:@"originName"];
//		//if (_patientName)
//		//	[logEntry setValue:_patientName forKey:@"patientName"];
//		//if (_studyDescription)
//		//	[logEntry setValue:_studyDescription forKey:@"studyName"];
//		[node setLogEntry:logEntry];
//		
//		}
//		@catch (NSException * e) {
//			NSLog( @"moveCallback exception");
//			NSLog( [e description]);
//		}
//
//		[context unlock];
//		[context release];
//	
//	}	
//	int numberPending = response -> NumberOfRemainingSubOperations;
//	int numberSent = response -> NumberOfCompletedSubOperations;
//	int numberErrors = response -> NumberOfFailedSubOperations + response -> NumberOfWarningSubOperations;
//	int numberImages = numberPending + numberSent + numberErrors ;
//	[logEntry setValue:[NSNumber numberWithInt:numberImages] forKey:@"numberImages"];
//	[logEntry setValue:[NSNumber numberWithInt:numberPending] forKey:@"numberPending"];
//	[logEntry setValue:[NSNumber numberWithInt:numberSent] forKey:@"numberSent"];
//	[logEntry setValue:[NSNumber numberWithInt:numberErrors] forKey:@"numberError"];
//	if (numberPending > 0) {
//		[logEntry setValue:@"In Progress" forKey:@"message"];
//	}
//	else{
//		[logEntry setValue:@"Complete" forKey:@"message"];
//	
//	}
//	[logEntry setValue:[NSDate date] forKey:@"endTime"];
//
//	if (debugLevel > 0) {
//        printf("Move Response %d: \n", responseCount);
//        DIMSE_printCMoveRSP(stdout, response);
//    }
//
//   
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

@implementation DCMTKQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
			callingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters{
	return [[[DCMTKQueryNode alloc] initWithDataset:(DcmDataset *)dataset
									callingAET:(NSString *)myAET  
									calledAET:(NSString *)theirAET  
									hostname:(NSString *)hostname 
									port:(int)port 
									transferSyntax:(int)transferSyntax
									compression: (float)compression
									extraParameters:(NSDictionary *)extraParameters] autorelease];
}
- (id)initWithDataset:(DcmDataset *)dataset
			callingAET:(NSString *)myAET  
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
		//_children = [[NSMutableArray alloc] init];
		debugLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"NetworkDebugLevel"];
		
		_children = nil;
		_uid = nil;
		_theDescription = nil;
		_name = nil;
		_patientID = nil;
		_accessionNumber = nil;
		_date = nil;
		_birthdate = nil;
		_time  = nil;
		_modality = nil;
		_numberImages = nil;
		_specificCharacterSet = nil;
		showErrorMessage = YES;
		if (debugLevel > 0)
			_verbose = YES;
		//if (debugLevel > 0) {	
			//dataset->print(COUT);
		//	if (dataset != NULL)
		//		dataset->writeXML(cout, 0); 
		//}
		
	}
	return self;
}

- (void)dealloc{
	[_children release];
	[_uid release];
	[_theDescription release];
	[_name release];
	[_patientID release];
	[_accessionNumber release];
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
	return _uid;
}
- (NSString *)theDescription{
	return _theDescription;
}
- (NSString *)name{
	return _name;
}
- (NSString *)accessionNumber{
	return _accessionNumber;
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
- (DCMCalendarDate *)time{
	return _time;
}
- (NSString *)modality{
	return _modality;
}
- (NSNumber *)numberImages{
	return _numberImages;
}
- (NSMutableArray *)children{
	return _children;
}
- (void)addChild:(DcmDataset *)dataset{

}
- (DcmDataset *)queryPrototype{
	return nil;
}

- (DcmDataset *)moveDataset{

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
- (void)queryWithValues:(NSArray *)values
{
	//add query keys
	DcmDataset *dataset = [self queryPrototype];
	NSString *stringEncoding = [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"];
	
//	NSLog(@"default string Encoding: %@",stringEncoding );
	//hard code for UTF8
	//stringEncoding = @"ISO_IR 192";
	
	int encoding = [NSString encodingForDICOMCharacterSet:stringEncoding];
	dataset->putAndInsertString(DCM_SpecificCharacterSet, [stringEncoding UTF8String]);
	const char *queryLevel;
	if (dataset->findAndGetString(DCM_QueryRetrieveLevel, queryLevel).good()){}
	
	//Keys are only modified at the study level.  At other levels the UIDs will be used
	if (strcmp(queryLevel, "STUDY") == 0) {
		NSEnumerator *enumerator = [values objectEnumerator];
		NSDictionary *dictionary;
		// need to get actual encoding from preferences
		
		while (dictionary = [enumerator nextObject]) {
			const char *string;
			NSString *key = [dictionary objectForKey:@"name"];
			id value  = [dictionary objectForKey:@"value"];
			if ([key isEqualToString:@"PatientsName"]) {	
				string = [(NSString*)value cStringUsingEncoding:encoding];
				dataset->putAndInsertString(DCM_PatientsName, string);
			}
			else if ([key isEqualToString:@"AccessionNumber"]) {
				string = [(NSString*)value cStringUsingEncoding:encoding];
				dataset->putAndInsertString(DCM_AccessionNumber, string);
			}
			else if ([key isEqualToString:@"PatientID"]) {
				string = [(NSString*)value cStringUsingEncoding:encoding];
				dataset->putAndInsertString(DCM_PatientID, string);
			}
			else if ([key isEqualToString:@"StudyDescription"]) {
				string = [(NSString*)value cStringUsingEncoding:encoding];
				dataset->putAndInsertString(DCM_StudyDescription, string);
			}
			else if ([key isEqualToString:@"StudyDate"]) {
				NSString *date = [(DCMCalendarDate *)value queryString];
				string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
				dataset->putAndInsertString(DCM_StudyDate, string);
			}
			else if ([key isEqualToString:@"PatientBirthDate"]) {
				NSString *date = [(DCMCalendarDate *)value queryString];
				string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
				dataset->putAndInsertString(DCM_PatientsBirthDate, string);
			}
			else if ([key isEqualToString:@"StudyTime"]) {
				NSString *date = [(DCMCalendarDate *)value queryString];
				string = [(NSString*)date cStringUsingEncoding:NSISOLatin1StringEncoding];
				dataset->putAndInsertString(DCM_StudyTime, string);
			}
			else if ([key isEqualToString:@"StudyID"]) {
				string = [(NSString*)value cStringUsingEncoding:encoding];
				dataset->putAndInsertString(DCM_StudyID, string);
			}
			else if ([key isEqualToString:@"ModalitiesinStudy"])
			{
				string = [(NSString*)value cStringUsingEncoding:encoding];
				
				dataset->putAndInsertString(DCM_ModalitiesInStudy, string);
				dataset->putAndInsertString(DCM_Modality, string);
			}
		}
	}
	if ([self setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:dataset])
	{
	
	}
	else NSLog( @"setupNetworkWithSyntax error");
	 
	if (dataset != NULL) delete dataset;
}

- (void) move:(NSDictionary*) dict
{
	DcmDataset *dataset = [self moveDataset];
	if ([self setupNetworkWithSyntax:UID_MOVEStudyRootQueryRetrieveInformationModel dataset:dataset destination: [dict objectForKey:@"moveDestination"]])
	{
	
	}
	
	if (dataset != NULL) delete dataset;
	 
}

- (OFCondition) addPresentationContext:(T_ASC_Parameters *)params abstractSyntax:(const char *)abstractSyntax{
   /*
    ** We prefer to use Explicitly encoded transfer syntaxes.
    ** If we are running on a Little Endian machine we prefer
    ** LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
    ** Some SCP implementations will just select the first transfer
    ** syntax they support (this is not part of the standard) so
    ** organise the proposed transfer syntaxes to take advantage
    ** of such behaviour.
    **
    ** The presentation contexts proposed here are only used for
    ** C-FIND and C-MOVE, so there is no need to support compressed
    ** transmission.
    */

    const char* transferSyntaxes[] = { NULL, NULL, NULL };
    int numTransferSyntaxes = 0;

    switch (_networkTransferSyntax) {
    case EXS_LittleEndianImplicit:
        /* we only support Little Endian Implicit */
        transferSyntaxes[0]  = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 1;
        break;
    case EXS_LittleEndianExplicit:
        /* we prefer Little Endian Explicit */
        transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 3;
        break;
    case EXS_BigEndianExplicit:
        /* we prefer Big Endian Explicit */
        transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
        transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 3;
        break;
    default:
        /* We prefer explicit transfer syntaxes.
         * If we are running on a Little Endian machine we prefer
         * LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
         */
        if (gLocalByteOrder == EBO_LittleEndian)  /* defined in dcxfer.h */
        {
            transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
            transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
        } else {
            transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
            transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
        }
        transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
        numTransferSyntaxes = 3;
        break;
    }
	
    return ASC_addPresentationContext(
        params, 1, abstractSyntax,
        transferSyntaxes, numTransferSyntaxes);
}

- (void)setShowErrorMessage:(BOOL) m
{
	showErrorMessage = m;
}

- (void) errorMessage:(NSArray*) msg
{
	if( showErrorMessage)
		NSRunCriticalAlertPanel( [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2], nil, nil) ;
}

- (BOOL)setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset
{
	return [self setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset destination: 0L];
}

//common network code for move and query
- (BOOL)setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset destination:(NSString*) destination
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
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
	
//	//verbose option set to true for now
	_verbose = OFFalse;
//
//	
//	//debug code activated for now
//	_debug = OFTrue;
//	DUL_Debug(OFTrue);
//	DIMSE_debug(OFTrue);
//	SetDebugLevel(3);
	
	//Use Little Endian TS
	_networkTransferSyntax = EXS_LittleEndianExplicit;	//EXS_LittleEndianExplicit;	//EXS_LittleEndianExplicit;
	
	
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
		queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Could create association parameters" userInfo:nil];
		[queryException raise];
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
//	DimseCondition::dump(cond);
    if (cond.bad()) {
        DimseCondition::dump(cond);
		queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Could create association parameters" userInfo:nil];
		[queryException raise];
		//return;
    }
	
	/* sets this application's title and the called application's title in the params */
	/* structure. The default values to be set here are "STORESCU" and "ANY-SCP". */
	ASC_setAPTitles(params, opt_ourTitle, opt_peerTitle, NULL);

	/* Set the transport layer type (type of network connection) in the params */
	/* strucutre. The default is an insecure connection; where OpenSSL is  */
	/* available the user is able to request an encrypted,secure connection. */
	cond = ASC_setTransportLayerType(params, _secureConnection);
	if (cond.bad()) {
		DimseCondition::dump(cond);
		queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Could not set transport layer" userInfo:nil];
		[queryException raise];
		//return;
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
					or 
	UID_FINDStudyRootQueryRetrieveInformationModel
	*/
	cond = [self addPresentationContext:params abstractSyntax:abstractSyntax];
    //cond = addPresentationContext(params, UID_FINDStudyRootQueryRetrieveInformationModel);
    if (cond.bad()) {
        DimseCondition::dump(cond);
        [queryException raise];
    }

    /* dump presentation contexts if required */
    if (_verbose) {
        printf("Request Parameters:\n");
        ASC_dumpParameters(params, COUT);
    }
	
		/* create association, i.e. try to establish a network connection to another */
	/* DICOM application. This call creates an instance of T_ASC_Association*. */
	if (_verbose)
		printf("Requesting Association\n");
	cond = ASC_requestAssociation(net, params, &assoc);
	if (cond.bad()) {
		if (cond == DUL_ASSOCIATIONREJECTED) {
			T_ASC_RejectParameters rej;
			ASC_getRejectParameters(params, &rej);
			errmsg("Association Rejected:");
			ASC_printRejectParameters(stderr, &rej);
			queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Association Rejected" userInfo:nil];
			[queryException raise];
			//return;

		} else {
			errmsg("Association Request Failed:");
			DimseCondition::dump(cond);
			queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Association request failed" userInfo:nil];
			[queryException raise];
			//return;
		}
	}
	
	  /* dump the presentation contexts which have been accepted/refused */
if (_verbose)
	{
        printf("Association Parameters Negotiated:\n");
        ASC_dumpParameters(params, COUT);
    }
	
		/* count the presentation contexts which have been accepted by the SCP */
	/* If there are none, finish the execution */
	if (ASC_countAcceptedPresentationContexts(params) == 0) {
		errmsg("No Acceptable Presentation Contexts");
		queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"No acceptable presentation contexts" userInfo:nil];
		[queryException raise];
		//return;
	}
	
	//specific for Move vs find
	if (strcmp(abstractSyntax, UID_FINDStudyRootQueryRetrieveInformationModel) == 0) {
		if (cond == EC_Normal) // compare with EC_Normal since DUL_PEERREQUESTEDRELEASE is also good()
		  {
			cond = [self cfind:assoc dataset:dataset];
		  }
	}
	else if (strcmp(abstractSyntax, UID_MOVEStudyRootQueryRetrieveInformationModel) == 0)
	{
		if( destination) cond = [self cmove:assoc network:net dataset:dataset destination: (char*) [destination UTF8String]];
		else cond = [self cmove:assoc network:net dataset:dataset];
	}
	else {
		NSLog(@"Q/R SCU bad Abstract Sytnax: %s", abstractSyntax);
		//shouldn't get here
	}
	
	/* tear down association, i.e. terminate network connection to SCP */
    if (cond == EC_Normal)
    {
        if (_abortAssociation) {
            if (_verbose)
                printf("Aborting Association\n");
            cond = ASC_abortAssociation(assoc);
            if (cond.bad()) {
                errmsg("Association Abort Failed:");
                DimseCondition::dump(cond);
                queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Abort Failed" userInfo:nil];
				[queryException raise];
				//return;
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
                queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Release Failed" userInfo:nil];
				[queryException raise];
				//return;
            }
        }
    }
    else if (cond == DUL_PEERREQUESTEDRELEASE)
    {
        errmsg("Protocol Error: peer requested release (Aborting)");
        if (_verbose)
            printf("Aborting Association\n");
        cond = ASC_abortAssociation(assoc);
        if (cond.bad()) {
            errmsg("Association Abort Failed:");
            DimseCondition::dump(cond);
            queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Abort Failed" userInfo:nil];
			[queryException raise];
			//return;
        }
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
        cond = ASC_abortAssociation(assoc);
        if (cond.bad()) {
            errmsg("Association Abort Failed:");
            DimseCondition::dump(cond);
			queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Abort Failed" userInfo:nil];
			[queryException raise];
			//return;
        }
    }
	

NS_HANDLER
	{
	NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r%@\r%@", _calledAET, _hostname, _port, [queryException name], [queryException description]];
	[self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Query Failed (1)", nil), response, NSLocalizedString(@"Continue", nil), 0L] waitUntilDone:YES];
	NSLog(@"Exception: %@", [queryException description]);
	}
NS_ENDHANDLER
	


// CLEANUP

    /* destroy the association, i.e. free memory of T_ASC_Association* structure. This */
    /* call is the counterpart of ASC_requestAssociation(...) which was called above. */
    cond = ASC_destroyAssociation(&assoc);
    if (cond.bad()) {
        DimseCondition::dump(cond);  
		//queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Destroy Association" userInfo:nil];
		//[queryException raise]; 
		//return;     
    }
	
    /* drop the network, i.e. free memory of T_ASC_Network* structure. This call */
    /* is the counterpart of ASC_initializeNetwork(...) which was called above. */
    cond = ASC_dropNetwork(&net);
    if (cond.bad()) {
        DimseCondition::dump(cond);
		//queryException = [NSException exceptionWithName:@"DICOM Network Failure (query)" reason:@"Drop Network" userInfo:nil];
		//[queryException raise];
		//return;
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



#ifdef DEBUG
    dcmDataDict.clear();  /* useful for debugging with dmalloc */
#endif
 
	//NS_HANDLER
	//NS_ENDHANDLER
	[pool release];
	return YES;
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
    if (presId == 0) {
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
    if (_verbose) {
        printf("Find SCU RQ: MsgID %d\n", msgId);
        printf("REQUEST:\n");
        dataset->print(COUT);
        printf("--------\n");
    }

    /* finally conduct transmission of data */
    OFCondition cond = DIMSE_findUser(assoc, presId, &req, dataset,
                          progressCallback, &callbackData,
                          _blockMode, _dimse_timeout,
                          &rsp, &statusDetail);


    /* dump some more general information */
    if (cond == EC_Normal)
	{
		if( rsp.DimseStatus != STATUS_Success && rsp.DimseStatus != STATUS_Pending)
		{
			NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", _calledAET, _hostname, _port];
			
			response = [response stringByAppendingString: [NSString stringWithCString: DU_cfindStatusString(rsp.DimseStatus)]];
			
			 if (statusDetail != NULL)
			 {
				OFOStringStream oss;
				
				statusDetail->print( oss);
				OFSTRINGSTREAM_GETSTR(oss, tmpString)
				response = [response stringByAppendingFormat:@"\r\r\r%s", tmpString];
				OFSTRINGSTREAM_FREESTR(tmpString)
			  }
			
			[self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Query Failed (2)", nil), response, NSLocalizedString(@"Continue", nil), 0L] waitUntilDone:YES];
		}
				
        if (_verbose) {
            DIMSE_printCFindRSP(stdout, &rsp);
        } else {
            if (rsp.DimseStatus != STATUS_Success)
			{
                printf("Response: %s\n", DU_cfindStatusString(rsp.DimseStatus));
				
				
            }
        }
    } else {
		errmsg("Find Failed\n Condition:\n");
		//dataset->print(COUT);
        DimseCondition::dump(cond);
		NSLog(@"Dimse Status: %@", [NSString stringWithCString: DU_cfindStatusString(rsp.DimseStatus)]);
    }

    /* dump status detail information if there is some */
    if (statusDetail != NULL) {
        printf("  Status Detail:\n");
        statusDetail->print(COUT);
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
	return [self cmove:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset destination: (char*) 0L];
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

- (OFCondition)moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset
{
	return [self moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset destination: 0L];
}

- (OFCondition)moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset destination: (char*) destination
{
	//add self to list of moves. Prevents deallocating  the move if a new query is done
	[[MoveManager sharedManager] addMove:self];

  T_ASC_PresentationContextID presId;
    T_DIMSE_C_MoveRQ    req;
    T_DIMSE_C_MoveRSP   rsp;
    DIC_US              msgId = assoc->nextMsgID++;
    DcmDataset          *rspIds = NULL;
    const char          *sopClass;
    DcmDataset          *statusDetail = NULL;
    MyCallbackInfo      callbackData;
		
   // sopClass = querySyntax[opt_queryModel].moveSyntax;

    /* which presentation context should be used */
    presId = ASC_findAcceptedPresentationContextID(assoc, UID_MOVEStudyRootQueryRetrieveInformationModel);
    if (presId == 0) return DIMSE_NOVALIDPRESENTATIONCONTEXTID;

    if (_verbose) {
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
	{
		strcpy(req.MoveDestination, destination);
	}
	else
	{
		/* set the destination to be me */
		ASC_getAPTitles(assoc->params, req.MoveDestination, NULL, NULL);
	}

    OFCondition cond = DIMSE_moveUser(assoc, presId, &req, dataset,
        moveCallback, &callbackData, _blockMode, _dimse_timeout,
        net, subOpCallback, NULL,
        &rsp, &statusDetail, &rspIds , OFTrue);

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
			
			[self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Move Failed", nil), [NSString stringWithCString: DU_cmoveStatusString(rsp.DimseStatus)], NSLocalizedString(@"Continue", nil), 0L] waitUntilDone:YES];
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
		[self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Move Failed", nil), [NSString stringWithCString: DU_cmoveStatusString(rsp.DimseStatus)], NSLocalizedString(@"Continue", nil), 0L] waitUntilDone:YES];
        errmsg("Move Failed:");
        DimseCondition::dump(cond);
    }
	
    if (statusDetail != NULL) {
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
@end
