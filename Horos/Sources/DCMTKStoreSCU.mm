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

#import "LogManager.h"
#import "AppController.h"
#import "DCMTKStoreSCU.h"
#import "BrowserController.h"
#import "DicomFile.h"
#import "Notifications.h"
#import "MutableArrayCategory.h"
#import "NSThread+N2.h"
#import "DicomDatabase.h"
#import "N2Debug.h"
#import "N2Stuff.h"
#undef verify
#include "osconfig.h" /* make sure OS specific configuration is included first */

#define  ON_THE_FLY_COMPRESSION 1

#define INCLUDE_CSTDLIB
#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#define INCLUDE_CERRNO
#define INCLUDE_CSTDARG
#define INCLUDE_CCTYPE
#include "ofstdinc.h"

BEGIN_EXTERN_C
#ifdef HAVE_SYS_FILE_H
#include <sys/file.h>
#endif
END_EXTERN_C

#ifdef HAVE_GUSI_H
#include <GUSI.h>
#endif

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
//#include "cmdlnarg.h"
#include "ofconapp.h"
#include "dcuid.h"     /* for dcmtk version name */
#include "dicom.h"     /* for DICOM_APPLICATION_REQUESTOR */
#include "dcostrmz.h"  /* for dcmZlibCompressionLevel */
#include "dcasccfg.h"  /* for class DcmAssociationConfiguration */
#include "dcasccff.h"  /* for class DcmAssociationConfigurationFile */

#ifdef ON_THE_FLY_COMPRESSION
#include "djdecode.h"  /* for dcmjpeg decoders */
#include "djencode.h"  /* for dcmjpeg encoders */
#include "dcrledrg.h"  /* for DcmRLEDecoderRegistration */
#include "dcrleerg.h"  /* for DcmRLEEncoderRegistration */
#include "djrploss.h"
#include "djrplol.h"
#include "dcpixel.h"
#include "dcrlerp.h"
#endif

#ifdef WITH_OPENSSL
#include "tlstrans.h"
#include "tlslayer.h"
#endif

#ifdef WITH_ZLIB
#include <zlib.h>          /* for zlibVersion() */
#endif

#import "BrowserController.h"
#import "DICOMToNSString.h"
#import "DCMObject.h"
#import "DCM.h"
#import "DCMTransferSyntax.h"
#import "SendController.h"

#import "OpenGLScreenReader.h"

#define OFFIS_CONSOLE_APPLICATION "storescu"

//static char rcsid[] = "$dcmtk: " OFFIS_CONSOLE_APPLICATION " v"
//  OFFIS_DCMTK_VERSION " " OFFIS_DCMTK_RELEASEDATE " $";

/* default application titles */
#define APPLICATIONTITLE        "STORESCU"
#define PEERAPPLICATIONTITLE    "ANY-SCP"

static OFBool opt_verbose = OFTrue;
static OFBool opt_showPresentationContexts = OFTrue;
static OFBool opt_debug = OFTrue;
static OFBool opt_abortAssociation = OFFalse;
static OFCmdUnsignedInt opt_maxReceivePDULength = ASC_DEFAULTMAXPDU;
//static OFCmdUnsignedInt opt_maxSendPDULength = 0;
static E_TransferSyntax opt_networkTransferSyntax = EXS_LittleEndianExplicit;

static int lastStatusCode = STATUS_Success;

static OFBool opt_proposeOnlyRequiredPresentationContexts = OFFalse;
static OFBool opt_combineProposedTransferSyntaxes = OFFalse;

static OFCmdUnsignedInt opt_repeatCount = 1;
//static OFCmdUnsignedInt opt_inventPatientCount = 25;
//static OFCmdUnsignedInt opt_inventStudyCount = 50;
//static OFCmdUnsignedInt opt_inventSeriesCount = 100;
static OFBool opt_correctUIDPadding = OFFalse;
//static OFBool opt_inventSOPInstanceInformation = OFFalse;
//static OFString patientNamePrefix("OSIRIX^PN_");   // PatientName is PN (maximum 16 chars)
//static OFString patientIDPrefix("PID_"); // PatientID is LO (maximum 64 chars)
//static OFString studyIDPrefix("SID_");   // StudyID is SH (maximum 16 chars)
//static OFString accessionNumberPrefix;  // AccessionNumber is SH (maximum 16 chars)
T_DIMSE_BlockingMode opt_blockMode = DIMSE_NONBLOCKING;
int opt_dimse_timeout = 0;
int opt_acse_timeout = 30;
int opt_Quality = 90;

//#ifdef WITH_ZLIB
//static OFCmdUnsignedInt opt_compressionLevel = 0;
//#endif

#ifdef WITH_OPENSSL
//static int         opt_keyFileFormat = SSL_FILETYPE_PEM;
//static OFBool      opt_doAuthenticate = OFFalse;
#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
static OFString    opt_ciphersuites(TLS1_TXT_RSA_WITH_AES_128_SHA ":" SSL3_TXT_RSA_DES_192_CBC3_SHA);
#else
static OFString    opt_ciphersuites(SSL3_TXT_RSA_DES_192_CBC3_SHA);
#endif
//static const char *opt_readSeedFile = NULL;
//static const char *opt_writeSeedFile = NULL;
//static DcmCertificateVerification opt_certVerification = DCV_requireCertificate;
//static const char *opt_dhparam = NULL;

static NSString *opensslSync = @"openssl";
#endif

static int inc = 0;

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

static OFCondition
addStoragePresentationContexts(T_ASC_Parameters *params, OFList<OFString>& sopClasses);

static OFCondition
cstore(T_ASC_Association *assoc, const OFString& fname);

#define SHORTCOL 4
#define LONGCOL 19

static OFBool
isaListMember(OFList<OFString>& lst, OFString& s)
{
    OFListIterator(OFString) cur = lst.begin();
    OFListIterator(OFString) end = lst.end();

    OFBool found = OFFalse;

    while (cur != end && !found) {

        found = (s == *cur);

        ++cur;
    }

    return found;
}

static OFCondition
addPresentationContext(T_ASC_Parameters *params,
    int presentationContextId, const OFString& abstractSyntax,
    const OFString& transferSyntax,
    T_ASC_SC_ROLE proposedRole = ASC_SC_ROLE_DEFAULT)
{
    const char* c_p = transferSyntax.c_str();
    OFCondition cond = ASC_addPresentationContext(params, presentationContextId,
        abstractSyntax.c_str(), &c_p, 1, proposedRole);
    return cond;
}

static OFCondition
addPresentationContext(T_ASC_Parameters *params,
    int presentationContextId, const OFString& abstractSyntax,
    const OFList<OFString>& transferSyntaxList,
    T_ASC_SC_ROLE proposedRole = ASC_SC_ROLE_DEFAULT)
{
    // create an array of supported/possible transfer syntaxes
    const char** transferSyntaxes = new const char*[transferSyntaxList.size()];
    int transferSyntaxCount = 0;
    OFListConstIterator(OFString) s_cur = transferSyntaxList.begin();
    OFListConstIterator(OFString) s_end = transferSyntaxList.end();
    while (s_cur != s_end) {
        transferSyntaxes[transferSyntaxCount++] = (*s_cur).c_str();
        ++s_cur;
    }

    OFCondition cond = ASC_addPresentationContext(params, presentationContextId,
        abstractSyntax.c_str(), transferSyntaxes, transferSyntaxCount, proposedRole);

    delete[] transferSyntaxes;
    return cond;
}

static OFCondition
addStoragePresentationContexts(T_ASC_Parameters *params, OFList<OFString>& sopClasses)
{
    /*
     * Each SOP Class will be proposed in two presentation contexts (unless
     * the opt_combineProposedTransferSyntaxes global variable is true).
     * The command line specified a preferred transfer syntax to use.
     * This prefered transfer syntax will be proposed in one
     * presentation context and a set of alternative (fallback) transfer
     * syntaxes will be proposed in a different presentation context.
     *
     * Generally, we prefer to use Explicitly encoded transfer syntaxes
     * and if running on a Little Endian machine we prefer
     * LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
     * Some SCP implementations will just select the first transfer
     * syntax they support (this is not part of the standard) so
     * organise the proposed transfer syntaxes to take advantage
     * of such behaviour.
     */

    // Which transfer syntax was preferred on the command line
    OFString preferredTransferSyntax;
    if (opt_networkTransferSyntax == EXS_Unknown) {
        /* gLocalByteOrder is defined in dcxfer.h */
        if (gLocalByteOrder == EBO_LittleEndian) {
            /* we are on a little endian machine */
            preferredTransferSyntax = UID_LittleEndianExplicitTransferSyntax;
        } else {
            /* we are on a big endian machine */
            preferredTransferSyntax = UID_BigEndianExplicitTransferSyntax;
        }
    } else {
        DcmXfer xfer(opt_networkTransferSyntax);
        preferredTransferSyntax = xfer.getXferID();
    }

    OFListIterator(OFString) s_cur;
    OFListIterator(OFString) s_end;


    OFList<OFString> fallbackSyntaxes;
    fallbackSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
    fallbackSyntaxes.push_back(UID_BigEndianExplicitTransferSyntax);
    fallbackSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
    // Remove the preferred syntax from the fallback list
    fallbackSyntaxes.remove(preferredTransferSyntax);
    // If little endian implicit is preferred then we don't need any fallback syntaxes
    // because it is the default transfer syntax and all applications must support it.
    if (opt_networkTransferSyntax == EXS_LittleEndianImplicit) {
        fallbackSyntaxes.clear();
    }

    // created a list of transfer syntaxes combined from the preferred and fallback syntaxes
    OFList<OFString> combinedSyntaxes;
    s_cur = fallbackSyntaxes.begin();
    s_end = fallbackSyntaxes.end();
    combinedSyntaxes.push_back(preferredTransferSyntax);
    while (s_cur != s_end)
    {
        if (!isaListMember(combinedSyntaxes, *s_cur)) combinedSyntaxes.push_back(*s_cur);
        ++s_cur;
    }

    if (!opt_proposeOnlyRequiredPresentationContexts) {
        // add the (short list of) known storage sop classes to the list
        // the array of Storage SOP Class UIDs comes from dcuid.h
        for (int i=0; i<numberOfDcmShortSCUStorageSOPClassUIDs; i++) {
            sopClasses.push_back(dcmShortSCUStorageSOPClassUIDs[i]);
        }
    }

    // thin out the sop classes to remove any duplicates.
    OFList<OFString> sops;
    s_cur = sopClasses.begin();
    s_end = sopClasses.end();
    while (s_cur != s_end) {
        if (!isaListMember(sops, *s_cur)) {
            sops.push_back(*s_cur);
        }
        ++s_cur;
    }

    // add a presentations context for each sop class / transfer syntax pair
    OFCondition cond = EC_Normal;
    int pid = 1; // presentation context id
    s_cur = sops.begin();
    s_end = sops.end();
    while (s_cur != s_end && cond.good()) {

        if (pid > 255) {
            errmsg("Too many presentation contexts");
            return ASC_BADPRESENTATIONCONTEXTID;
        }

        if (opt_combineProposedTransferSyntaxes) {
            cond = addPresentationContext(params, pid, *s_cur, combinedSyntaxes);
            pid += 2;   /* only odd presentation context id's */
        } else {

            // sop class with preferred transfer syntax
            cond = addPresentationContext(params, pid, *s_cur, preferredTransferSyntax);
            pid += 2;   /* only odd presentation context id's */

            if (fallbackSyntaxes.size() > 0) {
                if (pid > 255) {
                    errmsg("Too many presentation contexts");
                    return ASC_BADPRESENTATIONCONTEXTID;
                }

                // sop class with fallback transfer syntax
                cond = addPresentationContext(params, pid, *s_cur, fallbackSyntaxes);
                pid += 2;       /* only odd presentation context id's */
            }
        }
        ++s_cur;
    }

    return cond;
}

//static int
//secondsSince1970()
//{
//    time_t t = time(NULL);
//    return (int)t;
//}

//static OFString
//intToString(int i)
//{
//    char numbuf[32];
//    sprintf(numbuf, "%d", i);
//    return numbuf;
//}

//static OFString
//makeUID(OFString basePrefix, int counter)
//{
//    OFString prefix = basePrefix + "." + intToString(counter);
//    char uidbuf[65];
//    OFString uid = dcmGenerateUniqueIdentifier(uidbuf, prefix.c_str());
//    return uid;
//}
//
//static OFBool
//updateStringAttributeValue(DcmItem* dataset, const DcmTagKey& key, OFString& value)
//{
//    DcmStack stack;
//    DcmTag tag(key);
//
//    OFCondition cond = EC_Normal;
//    cond = dataset->search(key, stack, ESM_fromHere, OFFalse);
//    if (cond != EC_Normal) {
//        CERR << "error: updateStringAttributeValue: cannot find: " << tag.getTagName()
//             << " " << key << ": "
//             << cond.text() << endl;
//        return OFFalse;
//    }
//
//    DcmElement* elem = (DcmElement*) stack.top();
//
//    DcmVR vr(elem->ident());
//    if (elem->getLength() > vr.getMaxValueLength()) {
//        CERR << "error: updateStringAttributeValue: INTERNAL ERROR: " << tag.getTagName()
//             << " " << key << ": value too large (max "
//            << vr.getMaxValueLength() << ") for " << vr.getVRName() << " value: " << value << endl;
//        return OFFalse;
//    }
//
//    cond = elem->putOFStringArray(value);
//    if (cond != EC_Normal) {
//        CERR << "error: updateStringAttributeValue: cannot put string in attribute: " << tag.getTagName()
//             << " " << key << ": "
//             << cond.text() << endl;
//        return OFFalse;
//    }
//
//    return OFTrue;
//}

//static void
//replaceSOPInstanceInformation(DcmDataset* dataset)
//{
//    static OFCmdUnsignedInt patientCounter = 0;
//    static OFCmdUnsignedInt studyCounter = 0;
//    static OFCmdUnsignedInt seriesCounter = 0;
//    static OFCmdUnsignedInt imageCounter = 0;
//    static OFString seriesInstanceUID;
//    static OFString seriesNumber;
//    static OFString studyInstanceUID;
//    static OFString studyID;
//    static OFString accessionNumber;
//    static OFString patientID;
//    static OFString patientName;
//
//    if (seriesInstanceUID.length() == 0) seriesInstanceUID=makeUID(SITE_SERIES_UID_ROOT, (int)seriesCounter);
//    if (seriesNumber.length() == 0) seriesNumber = intToString((int)seriesCounter);
//    if (studyInstanceUID.length() == 0) studyInstanceUID = makeUID(SITE_STUDY_UID_ROOT, (int)studyCounter);
//    if (studyID.length() == 0) studyID = studyIDPrefix + intToString((int)secondsSince1970()) + intToString((int)studyCounter);
//    if (accessionNumber.length() == 0) accessionNumber = accessionNumberPrefix + intToString(secondsSince1970()) + intToString((int)studyCounter);
//    if (patientID.length() == 0) patientID = patientIDPrefix + intToString(secondsSince1970()) + intToString((int)patientCounter);
//    if (patientName.length() == 0) patientName = patientNamePrefix + intToString(secondsSince1970()) + intToString((int)patientCounter);
//
//    if (imageCounter >= opt_inventSeriesCount) {
//        imageCounter = 0;
//        seriesCounter++;
//        seriesInstanceUID = makeUID(SITE_SERIES_UID_ROOT, (int)seriesCounter);
//        seriesNumber = intToString((int)seriesCounter);
//    }
//    if (seriesCounter >= opt_inventStudyCount) {
//        seriesCounter = 0;
//        studyCounter++;
//        studyInstanceUID = makeUID(SITE_STUDY_UID_ROOT, (int)studyCounter);
//        studyID = studyIDPrefix + intToString(secondsSince1970()) + intToString((int)studyCounter);
//        accessionNumber = accessionNumberPrefix + intToString(secondsSince1970()) + intToString((int)studyCounter);
//    }
//    if (studyCounter >= opt_inventPatientCount) {
//        // we create as many patients as necessary */
//        studyCounter = 0;
//        patientCounter++;
//        patientID = patientIDPrefix + intToString(secondsSince1970()) + intToString((int)patientCounter);
//        patientName = patientNamePrefix + intToString(secondsSince1970()) + intToString((int)patientCounter);
//    }
//
//    OFString sopInstanceUID = makeUID(SITE_INSTANCE_UID_ROOT, (int)imageCounter);
//    OFString imageNumber = intToString((int)imageCounter);
//
//    if (opt_verbose) {
//        COUT << "Inventing Identifying Information (" <<
//            "pa" << patientCounter << ", st" << studyCounter <<
//            ", se" << seriesCounter << ", im" << imageCounter << "): " << endl;
//        COUT << "  PatientName=" << patientName << endl;
//        COUT << "  PatientID=" << patientID << endl;
//        COUT << "  StudyInstanceUID=" << studyInstanceUID << endl;
//        COUT << "  StudyID=" << studyID << endl;
//        COUT << "  SeriesInstanceUID=" << seriesInstanceUID << endl;
//        COUT << "  SeriesNumber=" << seriesNumber << endl;
//        COUT << "  SOPInstanceUID=" << sopInstanceUID << endl;
//        COUT << "  ImageNumber=" << imageNumber << endl;
//    }
//
//    updateStringAttributeValue(dataset, DCM_PatientsName, patientName);
//    updateStringAttributeValue(dataset, DCM_PatientID, patientID);
//    updateStringAttributeValue(dataset, DCM_StudyInstanceUID, studyInstanceUID);
//    updateStringAttributeValue(dataset, DCM_StudyID, studyID);
//    updateStringAttributeValue(dataset, DCM_SeriesInstanceUID, seriesInstanceUID);
//    updateStringAttributeValue(dataset, DCM_SeriesNumber, seriesNumber);
//    updateStringAttributeValue(dataset, DCM_SOPInstanceUID, sopInstanceUID);
//    updateStringAttributeValue(dataset, DCM_InstanceNumber, imageNumber);
//
//    imageCounter++;
//}

static void
progressCallback(void * /*callbackData*/,
    T_DIMSE_StoreProgress *progress,
    T_DIMSE_C_StoreRQ * /*req*/)
{
    if (opt_verbose) {
        switch (progress->state) {
        case DIMSE_StoreBegin:
            printf("XMIT:"); break;
        case DIMSE_StoreEnd:
            printf("\n"); break;
        default:
            putchar('.'); break;
        }
        fflush(stdout);
    }
}

static OFBool decompressFile(DcmFileFormat fileformat, const char *fname, char *outfname)
{
	OFBool status = YES;
	OFCondition cond;
	DcmXfer filexfer(fileformat.getDataset()->getOriginalXfer());
	
	NSLog( @"SEND - decompress: %@", [[NSString stringWithUTF8String: fname] lastPathComponent]);

	#ifndef OSIRIX_LIGHT
	BOOL useDCMTKForJP2K = [[NSUserDefaults standardUserDefaults] boolForKey: @"useDCMTKForJP2K"];
	if( useDCMTKForJP2K == NO && (filexfer.getXfer() == EXS_JPEG2000LosslessOnly || filexfer.getXfer() == EXS_JPEG2000))
	{
		NSString *path = [NSString stringWithUTF8String:fname];
		NSString *outpath = [NSString stringWithUTF8String:outfname];
		DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: path decodingPixelData: NO];
		
		unlink( outfname);
		[dcmObject writeToFile: outpath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:1 AET:@"Horos" atomically:YES];
		[dcmObject release];
	}
	else
	#endif
	{
        try
        {
              DcmDataset *dataset = fileformat.getDataset();

              // decompress data set if compressed
              dataset->chooseRepresentation(EXS_LittleEndianExplicit, NULL);

              // check if everything went well
              if (dataset->canWriteXfer(EXS_LittleEndianExplicit))
              {
                fileformat.loadAllDataIntoMemory();
                unlink( outfname);
                cond = fileformat.saveFile( outfname, EXS_LittleEndianExplicit);
                status =  (cond.good()) ? YES : NO;
              }
              else
                status = NO;
        }
        catch( ...)
        {
            status = NO;
        }
	}
	
	return status;
}

static OFBool compressFile(DcmFileFormat fileformat, const char *fname, char *outfname)
{
	OFCondition cond;
	OFBool status = YES;
    DcmDataset *dataset = fileformat.getDataset();
    
    if( dataset)
    {
        DcmXfer filexfer( dataset->getOriginalXfer());
        
        #ifndef OSIRIX_LIGHT
        BOOL useDCMTKForJP2K = [[NSUserDefaults standardUserDefaults] boolForKey: @"useDCMTKForJP2K"];
        if( useDCMTKForJP2K == NO && opt_networkTransferSyntax == EXS_JPEG2000)
        {
            NSLog(@"SEND - Compress JPEG 2000 Lossy (%d) : %s", opt_Quality, fname);
            NSString *path = [NSString stringWithUTF8String:fname];
            NSString *outpath = [NSString stringWithUTF8String:outfname];
            
            DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile:path decodingPixelData: NO];
            
            unlink( outfname);
            
            @try
            {
                DCMTransferSyntax *tsx = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
                                        
                [dcmObject writeToFile:outpath withTransferSyntax: tsx quality: opt_Quality AET:@"Horos" atomically:YES];
            }
            @catch( NSException *e)
            {
                NSLog( @"**** exception SendController dcmObject writeToFile: %@", e);
            }
            [dcmObject release];
        }
        else if( useDCMTKForJP2K == NO && opt_networkTransferSyntax == EXS_JPEG2000LosslessOnly)
        {
            NSLog(@"SEND - Compress JPEG 2000 Lossless: %s", fname);
            
            NSString *path = [NSString stringWithUTF8String:fname];
            NSString *outpath = [NSString stringWithUTF8String:outfname];
            
            DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile:path decodingPixelData: NO];
            
            unlink( outfname);
            
            @try
            {
                [dcmObject writeToFile:outpath withTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax] quality: DCMLosslessQuality AET:@"Horos" atomically:YES];
            }
            @catch( NSException *e)
            {
                NSLog( @"**** exception SendController dcmObject writeToFile: %@", e);
            }
            [dcmObject release];
        }
        else
        #endif
        {
            try
            {
                #ifndef OSIRIX_LIGHT
                //NSLog(@"SEND - Compress DCMTK JPEG: %s", fname);
                
//                DcmItem *metaInfo = fileformat.getMetaInfo();
                
                DcmRepresentationParameter *params = nil;
                DJ_RPLossy lossyParams( 90);
                DJ_RPLossy JP2KParams( opt_Quality);
                DJ_RPLossy JP2KParamsLossLess( DCMLosslessQuality);
                DcmRLERepresentationParameter rleParams;
                DJ_RPLossless losslessParams(6,0);
                
                if (opt_networkTransferSyntax == EXS_JPEGProcess14SV1TransferSyntax)
                    params = &losslessParams;
                else if (opt_networkTransferSyntax == EXS_JPEGProcess2_4TransferSyntax)
                    params = &lossyParams; 
                else if (opt_networkTransferSyntax == EXS_RLELossless)
                    params = &rleParams;
                else if (opt_networkTransferSyntax == EXS_JPEG2000LosslessOnly)
                    params = &JP2KParamsLossLess; 
                else if (opt_networkTransferSyntax == EXS_JPEG2000)
                    params = &JP2KParams;
                else if (opt_networkTransferSyntax == EXS_JPEGLSLossless)
                    params = &JP2KParamsLossLess; 
                else if (opt_networkTransferSyntax == EXS_JPEGLSLossy)
                    params = &JP2KParams;
                
                // this causes the lossless JPEG version of the dataset to be created
                dataset->chooseRepresentation(opt_networkTransferSyntax, params);

                // check if everything went well
                if (dataset->canWriteXfer(opt_networkTransferSyntax))
                {
                    // force the meta-header UIDs to be re-generated when storing the file 
                    // since the UIDs in the data set may have changed 
                    //delete metaInfo->remove(DCM_MediaStorageSOPClassUID);
                    //delete metaInfo->remove(DCM_MediaStorageSOPInstanceUID);
                    
                    // store in lossless JPEG format
                    
                    fileformat.loadAllDataIntoMemory();
                    
                    unlink( outfname);
                    
                    cond = fileformat.saveFile( outfname, opt_networkTransferSyntax);
                    status =  (cond.good()) ? YES : NO;
                }
                else
                    status = NO;
                #endif
            }
            catch(...)
            {
                status = NO;
            }
        }
    }
    else status = NO;

	return status;
}

static long seed = 0;

static OFCondition
storeSCU(T_ASC_Association * assoc, const char *fname)
    /*
     * This function will read all the information from the given file,
     * figure out a corresponding presentation context which will be used
     * to transmit the information over the network to the SCP, and it
     * will finally initiate the transmission of all data to the SCP.
     *
     * Parameters:
     *   assoc - [in] The association (network connection to another DICOM application).
     *   fname - [in] Name of the file which shall be processed.
     */
{
    DIC_US msgId = assoc->nextMsgID++;
    T_ASC_PresentationContextID presId;
    T_DIMSE_C_StoreRQ req;
    T_DIMSE_C_StoreRSP rsp;
    DIC_UI sopClass;
    DIC_UI sopInstance;
    DcmDataset *statusDetail = NULL;
	char outfname[ 4096];
	
	sprintf( outfname, "%s/%ld.dcm", [[DicomDatabase activeLocalDatabase] tempDirPathC], seed++);

    OFBool unsuccessfulStoreEncountered = OFTrue; // assumption
	
    if (opt_verbose) {
        printf("--------------------------\n");
        printf("Sending file: %s\n", fname);
    }

    /* read information from file. After the call to DcmFileFormat::loadFile(...) the information */
    /* which is encapsulated in the file will be available through the DcmFileFormat object. */
    /* In detail, it will be available through calls to DcmFileFormat::getMetaInfo() (for */
    /* meta header information) and DcmFileFormat::getDataset() (for data set information). */
    DcmFileFormat dcmff;
    OFCondition cond = dcmff.loadFile(fname);

    /* figure out if an error occured while the file was read*/
    if (cond.bad()) {
        errmsg("Bad DICOM file: %s: %s", fname, cond.text());
        return cond;
    }

//    /* if required, invent new SOP instance information for the current data set (user option) */
//    if (opt_inventSOPInstanceInformation) {
//        replaceSOPInstanceInformation(dcmff.getDataset());
//    }

    /* figure out which SOP class and SOP instance is encapsulated in the file */
    if (!DU_findSOPClassAndInstanceInDataSet(dcmff.getDataset(),
        sopClass, sopInstance, opt_correctUIDPadding)) {
        errmsg("No SOP Class & Instance UIDs in file: %s", fname);
        return DIMSE_BADDATA;
    }
	
    /* figure out which of the accepted presentation contexts should be used */
    DcmXfer filexfer(dcmff.getDataset()->getOriginalXfer());

    /* special case: if the file uses an unencapsulated transfer syntax (uncompressed
     * or deflated explicit VR) and we prefer deflated explicit VR, then try
     * to find a presentation context for deflated explicit VR first.
     */
    if (filexfer.isNotEncapsulated() &&
        opt_networkTransferSyntax == EXS_DeflatedLittleEndianExplicit)
    {
        filexfer = EXS_DeflatedLittleEndianExplicit;
    }
	
	
	/************* do on the fly conversion here*********************/
	
	//printf("on the fly conversion\n");
	//we have a valid presentation ID,.Chaeck and see if file is consistent with it
	DcmXfer preferredXfer(opt_networkTransferSyntax);
	OFBool status = NO;
	presId = ASC_findAcceptedPresentationContextID(assoc, sopClass, preferredXfer.getXferID());
	T_ASC_PresentationContext pc;
	ASC_findAcceptedPresentationContext(assoc->params, presId, &pc);
	DcmXfer proposedTransfer(pc.acceptedTransferSyntax);
	 if (presId != 0)
	 {
		if (filexfer.isNotEncapsulated() && proposedTransfer.isNotEncapsulated())
		{
			// do nothing
			status = NO;
		}
		else if (filexfer.isEncapsulated() && proposedTransfer.isNotEncapsulated())
		{
			status = decompressFile(dcmff, fname, outfname);
		}
		else if (filexfer.isNotEncapsulated() && proposedTransfer.isEncapsulated())
		{
			status = compressFile(dcmff, fname, outfname);
		}
		else if (filexfer.getXfer() != opt_networkTransferSyntax)
		{
			// The file is already compressed, we will re-compress the file.....
//			E_TransferSyntax fileTS = filexfer.getXfer();
			
			if( (filexfer.getXfer() == EXS_JPEG2000LosslessOnly && preferredXfer.getXfer() == EXS_JPEG2000) ||
				(filexfer.getXfer() == EXS_JPEG2000 && preferredXfer.getXfer() == EXS_JPEG2000LosslessOnly))
				{
				}
            else if( (filexfer.getXfer() == EXS_JPEGLSLossless && preferredXfer.getXfer() == EXS_JPEGLSLossy) ||
                    (filexfer.getXfer() == EXS_JPEGLSLossy && preferredXfer.getXfer() == EXS_JPEGLSLossless))
            {
            }
			else
				printf("------ Warning! Recompression: presentation for syntax:\n%s -> %s\n", dcmFindNameOfUID(filexfer.getXferID()), dcmFindNameOfUID(preferredXfer.getXferID()));
			
			status = compressFile(dcmff, fname, outfname);
		}
	 }
	 else
		status = NO;
		
	if (status)
	{
		cond = 	dcmff.loadFile( outfname);
		filexfer = dcmff.getDataset()->getOriginalXfer();
		
		/* figure out which SOP class and SOP instance is encapsulated in the file */
		if (!DU_findSOPClassAndInstanceInDataSet(dcmff.getDataset(),
			sopClass, sopInstance, opt_correctUIDPadding)) {
			errmsg("No SOP Class & Instance UIDs in file: %s", outfname);
			return DIMSE_BADDATA;
		}
		
		fname = outfname;
	}
	
    if (filexfer.getXfer() != EXS_Unknown)
		presId = ASC_findAcceptedPresentationContextID(assoc, sopClass, filexfer.getXferID());
    else
		presId = ASC_findAcceptedPresentationContextID(assoc, sopClass);
	
    if (presId == 0) {
        const char *modalityName = dcmSOPClassUIDToModality(sopClass);
        if (!modalityName) modalityName = dcmFindNameOfUID(sopClass);
        if (!modalityName) modalityName = "unknown SOP class";
        errmsg("No presentation context for: (%s) %s", modalityName, sopClass);
        return DIMSE_NOVALIDPRESENTATIONCONTEXTID;
    }

    /* if required, dump general information concerning transfer syntaxes */
    if (opt_verbose) {
        DcmXfer fileTransfer(dcmff.getDataset()->getOriginalXfer());
        T_ASC_PresentationContext pc;
        ASC_findAcceptedPresentationContext(assoc->params, presId, &pc);
        DcmXfer netTransfer(pc.acceptedTransferSyntax);
        printf("Transfer: %s -> %s\n",
            dcmFindNameOfUID(fileTransfer.getXferID()), dcmFindNameOfUID(netTransfer.getXferID()));
    }

    /* prepare the transmission of data */
    bzero((char*)&req, sizeof(req));
    req.MessageID = msgId;
    strcpy(req.AffectedSOPClassUID, sopClass);
    strcpy(req.AffectedSOPInstanceUID, sopInstance);
    req.DataSetType = DIMSE_DATASET_PRESENT;
    req.Priority = DIMSE_PRIORITY_LOW;

    /* if required, dump some more general information */
    if (opt_verbose) {
        printf("Store SCU RQ: MsgID %d, (%s)\n", msgId, dcmSOPClassUIDToModality(sopClass));
    }

    /* finally conduct transmission of data */
    cond = DIMSE_storeUser(assoc, presId, &req,
        NULL, dcmff.getDataset(), progressCallback, NULL,
        opt_blockMode, opt_dimse_timeout,
        &rsp, &statusDetail, NULL, DU_fileSize(fname));

    /*
     * If store command completed normally, with a status
     * of success or some warning then the image was accepted.
     */
    if (cond == EC_Normal && (rsp.DimseStatus == STATUS_Success || DICOM_WARNING_STATUS(rsp.DimseStatus))) {
        unsuccessfulStoreEncountered = OFFalse;
    }
    else
    {
        if (cond == EC_Normal)
            DIMSE_printCStoreRSP(stdout, &rsp);
    }

    /* remember the response's status for later transmissions of data */
    lastStatusCode = rsp.DimseStatus;

    /* dump some more general information */
    if (cond == EC_Normal)
    {
        if (opt_verbose) {
            DIMSE_printCStoreRSP(stdout, &rsp);
        }
    }
    else
    {
        errmsg("Store Failed, file: %s:", fname);
        DimseCondition::dump(cond);
    }

    /* dump status detail information if there is some */
    if (statusDetail != NULL) {
        printf("  Status Detail:\n");
        statusDetail->print(COUT);
        delete statusDetail;
    }
	
	if( status) {
		// We created a temporary file. Delete it now.
		unlink( outfname);
	}
	
    if( unsuccessfulStoreEncountered)
        cond = DIMSE_BADMESSAGE;
    
    /* return */
    return cond;
}


static OFCondition cstore(T_ASC_Association * assoc, const OFString& fname)
    /*
     * This function will process the given file as often as is specified by opt_repeatCount.
     * "Process" in this case means "read file, send C-STORE-RQ, receive C-STORE-RSP".
     *
     * Parameters:
     *   assoc - [in] The association (network connection to another DICOM application).
     *   fname - [in] Name of the file which shall be processed.
     */
{
    OFCondition cond = EC_Normal;
	
    /* opt_repeatCount specifies how many times a certain file shall be processed */
    int n = (int)opt_repeatCount;

    /* as long as no error occured and the counter does not equal 0 */
    while ((cond.good()) && n--)
    {
        /* process file (read file, send C-STORE-RQ, receive C-STORE-RSP) */
        cond = storeSCU(assoc, fname.c_str());
    }
    
    /* return result value */
    return cond;
}



@implementation DCMTKStoreSCU

+ (int) sendSyntaxForListenerSyntax: (int) listenerSyntax
{
	switch( listenerSyntax)
	{
		case EXS_LittleEndianExplicit:				return SendExplicitLittleEndian;	break;
		case EXS_JPEG2000:							return SendJPEG2000Lossless;	break;
		case EXS_JPEGProcess14SV1TransferSyntax:	return SendJPEGLossless;	break;
		case EXS_JPEGProcess1TransferSyntax:		return SendJPEGLossless;	break;
		case EXS_JPEGProcess2_4TransferSyntax:		return SendJPEGLossless;	break;
		case EXS_RLELossless:						return SendRLE;	break;
		case EXS_LittleEndianImplicit:				return SendImplicitLittleEndian;	break;
		case EXS_JPEG2000LosslessOnly:				return SendJPEG2000Lossless;	break;
        case EXS_JPEGLSLossless:                    return SendJPEGLSLossless;	break;
        case EXS_JPEGLSLossy:                       return SendJPEGLSLossless;	break;
	}
	
	return SendExplicitLittleEndian;
}

- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters
{
	if (self = [super init])
	{
		_threadStatus = YES;
		if ([extraParameters objectForKey:@"threadStatus"])
			_threadStatus = [[extraParameters objectForKey:@"threadStatus"] boolValue];
		
		_callingAET = [myAET retain];
		_calledAET = [theirAET retain];
		_port = port;
		_hostname = [hostname retain];
		_extraParameters = [extraParameters retain];
		_transferSyntax = transferSyntax;
		_compression = compression;
		
        
        if( extraParameters == nil)
            NSLog( @"--- DCMTKStoreSCU extraParameters == nil : TLS support not available");
        
		//TLS
		_secureConnection = [[extraParameters objectForKey:@"TLSEnabled"] boolValue];
		_doAuthenticate = NO;
		_cipherSuites = nil;
		_dhparam = NULL;
		
		if (_secureConnection)
		{
			_doAuthenticate = [[extraParameters objectForKey:@"TLSAuthenticated"] boolValue];
			_keyFileFormat = SSL_FILETYPE_PEM;
			certVerification = (TLSCertificateVerificationType)[[extraParameters objectForKey:@"TLSCertificateVerification"] intValue];
			
			NSArray *suites = [extraParameters objectForKey:@"TLSCipherSuites"];
			NSMutableArray *selectedCipherSuites = [NSMutableArray array];
			
			for (NSDictionary *suite in suites)
			{
				if ([[suite objectForKey:@"Supported"] boolValue])
					[selectedCipherSuites addObject:[suite objectForKey:@"Cipher"]];
			}
			
			_cipherSuites = [[NSArray arrayWithArray:selectedCipherSuites] retain];
			
			if([[extraParameters objectForKey:@"TLSUseDHParameterFileURL"] boolValue])
				_dhparam = [[extraParameters objectForKey:@"TLSDHParameterFileURL"] cStringUsingEncoding:NSUTF8StringEncoding];
			
			_readSeedFile = [TLS_SEED_FILE cStringUsingEncoding:NSUTF8StringEncoding];
			_writeSeedFile = TLS_WRITE_SEED_FILE;
		}
		
		_filesToSend = [[NSMutableArray arrayWithArray: filesToSend] retain];
		[_filesToSend removeDuplicatedStrings];
        
        NSMutableArray *toBeRemoved = [NSMutableArray array];
        for( NSString *f in _filesToSend)
        {
            if( [[NSFileManager defaultManager] fileExistsAtPath: f] == NO)
            {
                [toBeRemoved addObject: f];
                NSLog( @"**** DCMTKStoreSCU: file not available: %@", f);
            }
        }
        [_filesToSend removeObjectsInArray: toBeRemoved];
        
		_numberOfFiles = _filesToSend.count;
		_numberSent = 0;
		_numberErrors = 0;
		_logEntry = nil;
		
		DcmFileFormat fileformat;
		if ([_filesToSend count])
		{
			OFCondition status = fileformat.loadFile([ [_filesToSend objectAtIndex:0] UTF8String]);
			if (status.good())
			{
				const char *string = NULL;
				NSStringEncoding encoding[ 10];
				for( int i = 0; i < 10; i++) encoding[ i] = 0;
				encoding[ 0] = NSISOLatin1StringEncoding;
				
				if (fileformat.getDataset()->findAndGetString(DCM_SpecificCharacterSet, string, OFFalse).good() && string != nil)
				{
					NSArray	*c = [[NSString stringWithUTF8String:string] componentsSeparatedByString:@"\\"];

					if( [c count] >= 10) NSLog( @"Encoding number >= 10 ???");

					if( [c count] < 10)
					{
						for( int i = 0; i < [c count]; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c objectAtIndex: i]];
					}
				}

				if (fileformat.getDataset()->findAndGetString(DCM_PatientsName, string, OFFalse).good() && string != nil)
					_patientName = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
				else _patientName = [@"Unnamed" retain];
				
				if (fileformat.getDataset()->findAndGetString(DCM_StudyDescription, string, OFFalse).good() && string != nil)
					_studyDescription = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
				else _studyDescription = [@"Unnamed" retain];
			}
		}
	}
	
	return self;
}

- (void)dealloc 
{
	[_callingAET release];
	[_calledAET release];
	[_hostname release];
	[_extraParameters release];
	[_filesToSend release];
	[_patientName release];
	[_studyDescription release];
	[_logEntry release];
    
	// TLS
	[_cipherSuites release];
	
//	NSLog( @"dealloc DICOM Send");
	
	[super dealloc];
}
	
- (void)run:(NSOperation*) operation
{
	NSException* localException = nil;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[AppController sharedAppController] growlTitle: NSLocalizedString( @"DICOM Send", nil) description: [NSString stringWithFormat: NSLocalizedString(@"Sending %@...\rTo: %@ - %@", nil), N2LocalizedSingularPluralCount( _filesToSend.count, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil)), _calledAET, _hostname] name:@"send"];
	
//	NSString *tempFolder = [NSString stringWithFormat:@"/tmp/DICOMSend_%@-%@", _callingAET, [[NSDate date] description]];
	NSMutableArray *paths = [[NSMutableArray alloc] init];
	
	//delete if necessary and create temp folder. Allows us to compress and deompress files. Wish we could do on the fly
//	NSFileManager *fileManager = [NSFileManager defaultManager];
//	if ([fileManager fileExistsAtPath:tempFolder]) [fileManager removeItemAtPath:tempFolder error:NULL];
//	
//	if ([fileManager createDirectoryAtPath:tempFolder attributes:nil]) NSLog(@"created Folder: %@", tempFolder);
	
	OFCondition cond;
	const char *opt_peer = NULL;
    OFCmdUnsignedInt opt_port = 104;
    const char *opt_peerTitle = PEERAPPLICATIONTITLE;
    const char *opt_ourTitle = APPLICATIONTITLE;
	
	if (_callingAET)
		opt_ourTitle = [_callingAET UTF8String];
		
	if (_calledAET)
		opt_peerTitle = [_calledAET UTF8String];
    
    OFList<OFString> fileNameList;       // list of files to transfer to SCP
    OFList<OFString> sopClassUIDList;    // the list of sop classes
    OFList<OFString> sopInstanceUIDList; // the list of sop instances
    
    T_ASC_Network *net = NULL;
    T_ASC_Parameters *params;
    DIC_NODENAME localHost;
    DIC_NODENAME peerHost;
    T_ASC_Association *assoc = NULL;
    DcmAssociationConfiguration asccfg; // handler for association configuration profiles
    
	//NSLog(@"set hostname: %@", _hostname);
	opt_peer = [_hostname UTF8String];
	opt_port = _port;
	
    [[NSUserDefaults standardUserDefaults] setBool: 0 forKey: @"verbose_dcmtkStoreScu"];
    
	opt_verbose = [[NSUserDefaults standardUserDefaults] boolForKey: @"verbose_dcmtkStoreScu"];
	opt_showPresentationContexts = [[NSUserDefaults standardUserDefaults] boolForKey: @"verbose_dcmtkStoreScu"];
	opt_debug = [[NSUserDefaults standardUserDefaults] boolForKey: @"verbose_dcmtkStoreScu"];
	DUL_Debug( [[NSUserDefaults standardUserDefaults] boolForKey: @"verbose_dcmtkStoreScu"]);
	DIMSE_debug( [[NSUserDefaults standardUserDefaults] boolForKey: @"verbose_dcmtkStoreScu"]);
	SetDebugLevel( [[NSUserDefaults standardUserDefaults] boolForKey: @"verbose_dcmtkStoreScu"]);
	
	switch (_transferSyntax)
	{
		default:
		case SendExplicitLittleEndian:
			opt_networkTransferSyntax = EXS_LittleEndianExplicit;
			break;
		case SendJPEG2000Lossless:
			opt_networkTransferSyntax = EXS_JPEG2000LosslessOnly;
			opt_Quality = 0;
			break;
		case SendJPEG2000Lossy10: 
			opt_networkTransferSyntax = EXS_JPEG2000;
			opt_Quality = 1;
			break;
		case SendJPEG2000Lossy20:
			opt_networkTransferSyntax = EXS_JPEG2000;
			opt_Quality = 2;
			break;
		case SendJPEG2000Lossy50:
			opt_networkTransferSyntax = EXS_JPEG2000;
			opt_Quality = 3;
			break;
        case SendJPEGLSLossless:
			opt_networkTransferSyntax = EXS_JPEGLSLossless;
			opt_Quality = 0;
			break;
		case SendJPEGLSLossy10: 
			opt_networkTransferSyntax = EXS_JPEGLSLossy;
			opt_Quality = 1;
			break;
		case SendJPEGLSLossy20:
			opt_networkTransferSyntax = EXS_JPEGLSLossy;
			opt_Quality = 2;
			break;
		case SendJPEGLSLossy50:
			opt_networkTransferSyntax = EXS_JPEGLSLossy;
			opt_Quality = 3;
			break;
		case SendJPEGLossless: 
			opt_networkTransferSyntax = EXS_JPEGProcess14SV1TransferSyntax;
			break;
		case SendJPEGLossy9:
			opt_networkTransferSyntax = EXS_JPEGProcess2_4TransferSyntax;
			opt_Quality = 90;
			break;
		case SendJPEGLossy8:
			opt_networkTransferSyntax = EXS_JPEGProcess2_4TransferSyntax;
			opt_Quality = 80;
			break;
		case SendJPEGLossy7:
			opt_networkTransferSyntax = EXS_JPEGProcess2_4TransferSyntax;
			opt_Quality = 70;
			break;
		case SendImplicitLittleEndian:
			opt_networkTransferSyntax = EXS_LittleEndianImplicit;
			break;
		case SendRLE:
			opt_networkTransferSyntax = EXS_RLELossless;
			break;
		case SendExplicitBigEndian:
			opt_networkTransferSyntax = EXS_BigEndianExplicit;
			break;
		case SendBZip:
			opt_networkTransferSyntax = EXS_DeflatedLittleEndianExplicit;
			break;
	}
    
#ifdef WITH_ZLIB

#endif

	//default should be False
	opt_proposeOnlyRequiredPresentationContexts = OFFalse;
//	opt_combineProposedTransferSyntaxes = OFTrue;
	
#ifdef WITH_ZLIB
	if (opt_networkTransferSyntax == EXS_DeflatedLittleEndianExplicit)
		dcmZlibCompressionLevel.set((int) _compression);
#endif
	
	//	enable-new-vr 
	dcmEnableUnknownVRGeneration.set(OFTrue);
	dcmEnableUnlimitedTextVRGeneration.set(OFTrue);
	
	//Timeout
	OFCmdSignedInt opt_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"];

    if( opt_timeout < 2)
        opt_timeout = 2;
    
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMConnectionTimeout"] > 0)
    {
        NSLog( @"--- DICOMConnectionTimeout: %d", (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMConnectionTimeout"]);
        dcmConnectionTimeout.set( (Sint32) [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMConnectionTimeout"]);
    }
    else
        dcmConnectionTimeout.set( (Sint32) opt_timeout);
    
   //acse-timeout
    
	opt_acse_timeout = OFstatic_cast(int, opt_timeout);
	
	//dimse-timeout
	//OFCmdSignedInt opt_timeout = 0;
	
	opt_dimse_timeout = OFstatic_cast(int, opt_timeout);
	opt_blockMode = DIMSE_NONBLOCKING;
	
	//max PUD
	//opt_maxReceivePDULength = 
	
	//max-send-pdu
	//opt_maxSendPDULength = 
	//dcmMaxOutgoingPDUSize.set((Uint32)opt_maxSendPDULength);
	
	DcmTLSTransportLayer *tLayer = NULL;
	
	#ifndef OSIRIX_LIGHT
//	if( _secureConnection)
//		[DDKeychain lockTmpFiles];
	NSString *uniqueStringID = [NSString stringWithFormat:@"%d.%d.%d", getpid(), inc++, (int) random()];
	#endif
	
	@try
	{
	#ifndef OSIRIX_LIGHT
	#ifdef WITH_OPENSSL
		if(_cipherSuites)
		{
            @synchronized( opensslSync)
            {
                @try
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
                            
                            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat:@"Ciphersuite '%s' is unknown.", current] userInfo:nil] retain];
                            [localException raise];
                        }
                        else
                        {
                            if (opt_ciphersuites.length() > 0) opt_ciphersuites += ":";
                            opt_ciphersuites += currentOpenSSL;
                        }
                        
                    }
                }
                @catch ( NSException *e)
                {
                    NSLog(@"******** cipherSuites Exception: %@", e);
                }
            }
		}
		
	#endif
	#endif
		
		  int paramCount = [_filesToSend count];
		  const char *currentFilename = NULL;
		  OFString errormsg;
		  char sopClassUID[128];
		  char sopInstanceUID[128];
		  OFBool ignoreName;
		  
		 /* finally parse filenames */
		  for (int i=0; i < paramCount; i++)
		  {
			[paths addObject:[_filesToSend objectAtIndex:i]];
		  }
		  
		  for (int i=0; i < paramCount; i++)
		  {
			ignoreName = OFFalse;
			currentFilename = [[paths objectAtIndex:i] UTF8String];
			
			if (access(currentFilename, R_OK) < 0)
			{
			  errormsg = "cannot access file: ";
			  errormsg += currentFilename;
//			  if (opt_haltOnUnsuccessfulStore)
//				 errmsg(errormsg.c_str());
//				 else CERR << "warning: " << errormsg << ", ignoring file" << endl;
			}
			else
			{
			  if (opt_proposeOnlyRequiredPresentationContexts)
			  {
				  if (!DU_findSOPClassAndInstanceInFile(currentFilename, sopClassUID, sopInstanceUID))
				  {
					ignoreName = OFTrue;
					errormsg = "missing SOP class (or instance) in file: ";
					errormsg += currentFilename;
//					if (opt_haltOnUnsuccessfulStore)
//					   errmsg(errormsg.c_str());
//					   else CERR << "warning: " << errormsg << ", ignoring file" << endl;
				  }
				  else if (!dcmIsaStorageSOPClassUID(sopClassUID))
				  {
					ignoreName = OFTrue;
					errormsg = "unknown storage sop class in file: ";
					errormsg += currentFilename;
					errormsg += ": ";
					errormsg += sopClassUID;
//					if (opt_haltOnUnsuccessfulStore)
//					   errmsg(errormsg.c_str());
//					   else CERR << "warning: " << errormsg << ", ignoring file" << endl;
				  }
				  else
				  {
					sopClassUIDList.push_back(sopClassUID);
					sopInstanceUIDList.push_back(sopInstanceUID);
				  }
			  }
			  if (!ignoreName) fileNameList.push_back(currentFilename);
			}
		  }

	#ifdef ON_THE_FLY_COMPRESSION
		// register global JPEG decompression codecs
	   // DJDecoderRegistration::registerCodecs();

		// register global JPEG compression codecs
	  //  DJEncoderRegistration::registerCodecs();

		// register RLE compression codec
	 //   DcmRLEEncoderRegistration::registerCodecs();

		// register RLE decompression codec
	//    DcmRLEDecoderRegistration::registerCodecs();
	#endif

		/* make sure data dictionary is loaded */
		if (!dcmDataDict.isDictionaryLoaded()) {
			fprintf(stderr, "Warning: no data dictionary loaded, check environment variable: %s\n",
					DCM_DICT_ENVIRONMENT_VARIABLE);
		}
		
		/* initialize network, i.e. create an instance of T_ASC_Network*. */
		cond = ASC_initializeNetwork(NET_REQUESTOR, 0, opt_acse_timeout, &net);
		if (cond.bad())
		{
			DimseCondition::dump(cond);
			localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"ASC_initializeNetwork %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
			[localException raise];
			//return;
		}
	
	#ifndef OSIRIX_LIGHT
	#ifdef WITH_OPENSSL // joris
		
		if( _secureConnection)
        {
            @synchronized( opensslSync)
            {
                tLayer = new DcmTLSTransportLayer(DICOM_APPLICATION_REQUESTOR, _readSeedFile);
                if (tLayer == NULL)
                {
                    NSLog(@"unable to create TLS transport layer");
                    localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:@"unable to create TLS transport layer" userInfo:nil] retain];
                    [localException raise];
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
                            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat:@"Unable to load certificate file %@", [trustedCertificatesDir stringByAppendingPathComponent:cert]] userInfo:nil] retain];
                            [localException raise];
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
                    localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat:@"Unable to load temporary DH parameter file %s", _dhparam] userInfo:nil] retain];
                    [localException raise];
                }
                
                if (_doAuthenticate)
                {			
                    tLayer->setPrivateKeyPasswd([[DICOMTLS TLS_PRIVATE_KEY_PASSWORD] cStringUsingEncoding:NSUTF8StringEncoding]);
                    
                    [DICOMTLS generateCertificateAndKeyForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID]; // export certificate/key from the Keychain to the disk
                    
                    NSString *_privateKeyFile = [DICOMTLS keyPathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID]; // generates the PEM file for the private key
                    NSString *_certificateFile = [DICOMTLS certificatePathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID]; // generates the PEM file for the certificate		
                    
                    if (TCS_ok != tLayer->setPrivateKeyFile([_privateKeyFile cStringUsingEncoding:NSUTF8StringEncoding], SSL_FILETYPE_PEM))
                    {
                        localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat:@"Unable to load private TLS key from %@", _privateKeyFile] userInfo:nil] retain];
                        [localException raise];
                    }
                    
                    if (TCS_ok != tLayer->setCertificateFile([_certificateFile cStringUsingEncoding:NSUTF8StringEncoding], SSL_FILETYPE_PEM))
                    {
                        localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat:@"Unable to load certificate from %@", _certificateFile] userInfo:nil] retain];
                        [localException raise];
                    }
                    
                    if (!tLayer->checkPrivateKeyMatchesCertificate())
                    {
                        localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat:@"private key '%@' and certificate '%@' do not match", _privateKeyFile, _certificateFile] userInfo:nil] retain];
                        [localException raise];
                    }
                }
                
                if (TCS_ok != tLayer->setCipherSuites(opt_ciphersuites.c_str()))
                {
                    localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:@"Unable to set selected cipher suites" userInfo:nil] retain];
                    [localException raise];
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
                    DimseCondition::dump(cond);
                    localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU TLS)" reason:[NSString stringWithFormat: @"ASC_setTransportLayer - %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
                    [localException raise];
                }
            }
        }
        #endif
        #endif
            
         /* initialize asscociation parameters, i.e. create an instance of T_ASC_Parameters*. */
        cond = ASC_createAssociationParameters(&params, opt_maxReceivePDULength);
        if (cond.bad())
        {
            DimseCondition::dump(cond);
            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"ASC_createAssociationParameters %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
            [localException raise];
            //return;
        }
        
        /* sets this application's title and the called application's title in the params */
        /* structure. The default values to be set here are "STORESCU" and "ANY-SCP". */
        ASC_setAPTitles(params, opt_ourTitle, opt_peerTitle, NULL);

        /* Set the transport layer type (type of network connection) in the params */
        /* strucutre. The default is an insecure connection; where OpenSSL is  */
        /* available the user is able to request an encrypted,secure connection. */
        cond = ASC_setTransportLayerType(params, _secureConnection);
        if (cond.bad())
        {
            DimseCondition::dump(cond);
            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"ASC_setTransportLayerType %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
            [localException raise];
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
        cond = addStoragePresentationContexts(params, sopClassUIDList);
        if (cond.bad())
        {
            DimseCondition::dump(cond);
            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"addStoragePresentationContexts %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
            [localException raise];
            //return;
        }

        
        /* dump presentation contexts if required */
        if (opt_showPresentationContexts || opt_debug)
        {
            printf("Request Parameters:\n");
            ASC_dumpParameters(params, COUT);
        }
        
        
        /* create association, i.e. try to establish a network connection to another */
        /* DICOM application. This call creates an instance of T_ASC_Association*. */
        if (opt_verbose)
            printf("Requesting Association\n");
        cond = ASC_requestAssociation(net, params, &assoc);
        if (cond.bad())
        {
            if (cond == DUL_ASSOCIATIONREJECTED)
            {
                T_ASC_RejectParameters rej;
                ASC_getRejectParameters(params, &rej);
                errmsg("Association Rejected:");
                ASC_printRejectParameters(stderr, &rej);
                localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"Association Rejected %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
                [localException raise];

            } else {
                errmsg("Association Request Failed:");
                DimseCondition::dump(cond);
                localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"Association Request Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
                [localException raise];
            }
        }
        
        
        /* dump the connection parameters if in debug mode*/
        if (opt_debug)
        {
            ostream& out = ofConsole.lockCout();     
            ASC_dumpConnectionParameters(assoc, out);
            ofConsole.unlockCout();
        }

        /* dump the presentation contexts which have been accepted/refused */
        if (opt_showPresentationContexts || opt_debug)
        {
            printf("Association Parameters Negotiated:\n");
            ASC_dumpParameters(params, COUT);
        }

        /* count the presentation contexts which have been accepted by the SCP */
        /* If there are none, finish the execution */
        if (ASC_countAcceptedPresentationContexts(params) == 0)
        {
            errmsg("No Acceptable Presentation Contexts");
            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:@"No acceptable presentation contexts" userInfo:nil] retain];
            [localException raise];
            //return;
        }

        /* dump general information concerning the establishment of the network connection if required */
        if (opt_verbose) {
            printf("Association Accepted (Max Send PDV: %u)\n",
                    assoc->sendPDVLength);
        }

         /* do the real work, i.e. for all files which were specified in the */
        /* command line, transmit the encapsulated DICOM objects to the SCP. */
        cond = EC_Normal;
        OFListIterator(OFString) iter = fileNameList.begin();
        OFListIterator(OFString) enditer = fileNameList.end();
        
        while ((iter != enditer) && (cond == EC_Normal)) // compare with EC_Normal since DUL_PEERREQUESTEDRELEASE is also good()
        {
            cond = cstore(assoc, *iter);
            
            ++iter;
            
            if (cond == EC_Normal)
                _numberSent++;
            else
                _numberErrors = _numberOfFiles - _numberSent;
            
            NSMutableDictionary  *userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:[NSNumber numberWithInt:_numberOfFiles] forKey:@"SendTotal"];
            [userInfo setObject:[NSNumber numberWithInt:_numberSent] forKey:@"NumberSent"];
            [userInfo setObject:[NSNumber numberWithInt:_numberErrors] forKey:@"ErrorCount"];
            [userInfo setObject:[NSNumber numberWithInt:NO] forKey:@"Sent"];
            [userInfo setObject:@"In Progress" forKey:@"Message"];
            
            if( [operation isCancelled] || (operation == nil && [[NSThread currentThread] isCancelled]))
                [userInfo setObject:@"Incomplete" forKey:@"Message"];
            
            [self updateLogEntry: userInfo];
            
            if( [[userInfo objectForKey: @"SendTotal"] floatValue] >= 1)
            {
                NSString *extraInfo = @"";
                if( _secureConnection)
                    extraInfo = NSLocalizedString(@" (TLS)", @"don't remove leading space");
                NSInteger theNumber = [[userInfo objectForKey: @"SendTotal"] intValue] - [[userInfo objectForKey: @"NumberSent"] intValue];
                [NSThread currentThread].status = [NSString stringWithFormat:@"%d %@%@", (int) theNumber, (theNumber != 1? NSLocalizedString(@"files", nil) : NSLocalizedString(@"file", nil)), extraInfo];
                [NSThread currentThread].progress = [[userInfo objectForKey: @"NumberSent"] floatValue] / [[userInfo objectForKey: @"SendTotal"] floatValue];
            }
            
            if ([operation isCancelled] || (operation == nil && [[NSThread currentThread] isCancelled]))
                break;
        }
        
        /* tear down association, i.e. terminate network connection to SCP */
        if (cond == EC_Normal)
        {
            if (opt_abortAssociation)
            {
                if (opt_verbose)
                    printf("Aborting Association\n");
                cond = ASC_abortAssociation(assoc);
                if (cond.bad())
                {
                    errmsg("Association Abort Failed:");
                    DimseCondition::dump(cond);
                    localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"Association Abort Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
                    [localException raise];
                }
            } else
            {
                /* release association */
                if (opt_verbose)
                    printf("Releasing Association\n");
                cond = ASC_releaseAssociation(assoc);
                if (cond.bad())
                {
                    errmsg("Association Release Failed:");
                    DimseCondition::dump(cond);
                    localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"Association Release Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
                    [localException raise];
                }
            }
        }
        else if (cond == DUL_PEERREQUESTEDRELEASE)
        {
            errmsg("Protocol Error: peer requested release (Aborting)");
            if (opt_verbose)
                printf("Aborting Association\n");
            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"Protocol Error: peer requested release (Aborting) %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
            cond = ASC_abortAssociation(assoc);
            if (cond.bad())
            {
                errmsg("Association Abort Failed:");
                DimseCondition::dump(cond);
            }
            [localException raise];
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
            
            localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"SCU Failed %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
            cond = ASC_abortAssociation(assoc);
            if (cond.bad())
            {
                errmsg("Association Abort Failed:");
                DimseCondition::dump(cond);
                
            }
            [localException raise];
        }
    }
	@catch ( NSException *e)
	{
		NSLog(@"********* Store Exception: %@", e);
	}
	
	// CLEANUP
	// Give time for other threads that are maybe using these variables
	[NSThread sleepForTimeInterval: 1];
	
    /* destroy the association, i.e. free memory of T_ASC_Association* structure. This */
    /* call is the counterpart of ASC_requestAssociation(...) which was called above. */
	if( assoc)
	{
		cond = ASC_destroyAssociation(&assoc);
		if (cond.bad())
		{
			DimseCondition::dump(cond);
			localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"ASC_destroyAssociation %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
		}
	}
	
	
    /* drop the network, i.e. free memory of T_ASC_Network* structure. This call */
    /* is the counterpart of ASC_initializeNetwork(...) which was called above. */
	if( net)
	{
		cond = ASC_dropNetwork(&net);
		if (cond.bad())
		{
			DimseCondition::dump(cond);
			localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:[NSString stringWithFormat: @"ASC_dropNetwork %04x:%04x %s", cond.module(), cond.code(), cond.text()] userInfo:nil] retain];
		}
	}
	
#ifdef HAVE_WINSOCK_H
    WSACleanup();
#endif

#ifndef OSIRIX_LIGHT
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
    @synchronized( opensslSync)
    {
        if( tLayer)
            delete tLayer;

        // cleanup
        if( _secureConnection)
        {
    //		[DDKeychain unlockTmpFiles];
            [[NSFileManager defaultManager] removeItemAtPath:[DICOMTLS keyPathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID] error:NULL];
            [[NSFileManager defaultManager] removeItemAtPath:[DICOMTLS certificatePathForServerAddress:_hostname port:_port AETitle:_calledAET withStringID:uniqueStringID] error:NULL];
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", TLS_TRUSTED_CERTIFICATES_DIR, uniqueStringID] error:NULL];
        }
    }
#endif
#endif

//    if (opt_haltOnUnsuccessfulStore && unsuccessfulStoreEncountered)
//	{
//        if (lastStatusCode == STATUS_Success)
//		{
//           
//        }
//		else
//		{
//           
//        }
//		
//		localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:@"Unsuccessful Store Encountered" userInfo:nil] retain];
//    }

#ifdef ON_THE_FLY_COMPRESSION
    // deregister JPEG codecs
   // DJDecoderRegistration::cleanup();
   // DJEncoderRegistration::cleanup();

    // deregister RLE codecs
  //  DcmRLEDecoderRegistration::cleanup();
  //  DcmRLEEncoderRegistration::cleanup();
#endif

//#ifdef DEBUG
//    dcmDataDict.clear();  /* useful for debugging with dmalloc */
//#endif

	{
		NSMutableDictionary  *userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:_numberOfFiles] forKey:@"SendTotal"];
		[userInfo setObject:[NSNumber numberWithInt:_numberSent] forKey:@"NumberSent"];
		[userInfo setObject:[NSNumber numberWithInt:_numberErrors] forKey:@"ErrorCount"];
		[userInfo setObject:[NSNumber numberWithInt:NO] forKey:@"Sent"];
		
		if( _numberSent != _numberOfFiles || localException != nil)
		{
			if( [operation isCancelled] || (operation == nil && [[NSThread currentThread] isCancelled]))
                [userInfo setObject:@"Aborted" forKey:@"Message"];
			else
                [userInfo setObject:@"Incomplete" forKey:@"Message"];
			
			_numberErrors = _numberOfFiles - _numberSent;
			
			[userInfo setObject:[NSNumber numberWithInt:_numberErrors] forKey:@"ErrorCount"];
			
			[[AppController sharedAppController] growlTitle: NSLocalizedString( @"DICOM Send", nil) description: [NSString stringWithFormat: NSLocalizedString(@"Errors ! %@ of %@ generated errors.", nil), N2LocalizedDecimal( _numberErrors) , N2LocalizedSingularPluralCount( _numberOfFiles, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil))]  name:@"send"];
            
            NSLog( @"DCMTKStoreSCU: _numberSent: %d / _numberOfFiles : %d", _numberSent, _numberOfFiles);
            
            if( localException == nil)
                localException = [[NSException exceptionWithName:@"DICOM Network Failure (STORE-SCU)" reason:@"Unsuccessful Store Encountered, see Applications/Utilities/Console.app for more detailed informations." userInfo:nil] retain];
		}
		else
			[userInfo setObject:@"Complete" forKey:@"Message"];
		
		[self updateLogEntry: userInfo];
		
		if( [[userInfo objectForKey: @"SendTotal"] floatValue] >= 1)
		{
            NSString *extraInfo = @"";
            if( _secureConnection)
                extraInfo = @" (TLS Activated)";
            
			[NSThread currentThread].status = [NSString stringWithFormat: NSLocalizedString( @"%@%@", nil), N2LocalizedSingularPluralCount( [[userInfo objectForKey: @"SendTotal"] intValue] - [[userInfo objectForKey: @"NumberSent"] intValue], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil)), extraInfo];
			[NSThread currentThread].progress = [[userInfo objectForKey: @"NumberSent"] floatValue] / [[userInfo objectForKey: @"SendTotal"] floatValue];
		}
//		[self sendStatusNotification: userInfo];
//		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixDCMSendStatusNotification object:self userInfo:userInfo];
	}

	[paths release];
	[pool release];
	
	[localException autorelease];
	
	[localException raise];
}

//- (void) sendStatusNotification:(NSMutableDictionary*) userInfo
//{
//	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixDCMSendStatusNotification object:self userInfo:userInfo];
//}

- (void) updateLogEntry: (NSMutableDictionary*) userInfo
{
	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO) return;
	
	@try
	{
		if (!_logEntry)
		{
			_logEntry = [[NSMutableDictionary dictionary] retain];
            
            [_logEntry setValue: [NSString stringWithFormat: @"%lf", [[NSDate date] timeIntervalSince1970]] forKey:@"logUID"];
			[_logEntry setValue: [NSDate date] forKey:@"logStartTime"];
			[_logEntry setValue:@"Send" forKey:@"logType"];
			[_logEntry setValue:_calledAET forKey:@"logCalledAET"];
			[_logEntry setValue:_callingAET forKey:@"logCallingAET"];
			
			if (_patientName)
				[_logEntry setValue:_patientName forKey: @"logPatientName"];
			
			if (_studyDescription)
				[_logEntry setValue:_studyDescription forKey:@"logStudyDescription"];
		}
		
		[_logEntry setValue:[NSNumber numberWithInt: _numberOfFiles] forKey:@"logNumberTotal"];
		[_logEntry setValue:[NSNumber numberWithInt: _numberSent] forKey:@"logNumberReceived"];
		[_logEntry setValue:[NSNumber numberWithInt: _numberErrors] forKey:@"logNumberError"];
		[_logEntry setValue:[NSDate date] forKey:@"logEndTime"];
		[_logEntry setValue:[userInfo valueForKey:@"Message"] forKey:@"logMessage"];
        
        [[LogManager currentLogManager] addLogLine: _logEntry];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
    }
}

@end
