//
//  BrowserControllerDCMTKCategory.m
//  OsiriX
//
//  Created by Lance Pysher on 6/27/06.

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

#import "BrowserControllerDCMTKCategory.h"
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMTransferSyntax.h>

#undef verify
#include "osconfig.h" /* make sure OS specific configuration is included first */
#include "djdecode.h"  /* for dcmjpeg decoders */
#include "djencode.h"  /* for dcmjpeg encoders */
#include "dcrledrg.h"  /* for DcmRLEDecoderRegistration */
#include "dcrleerg.h"  /* for DcmRLEEncoderRegistration */
#include "djrploss.h"
#include "djrplol.h"
#include "dcpixel.h"
#include "dcrlerp.h"

#include "dcdatset.h"
#include "dcmetinf.h"
#include "dcfilefo.h"
#include "dcdebug.h"
#include "dcuid.h"
#include "dcdict.h"
#include "dcdeftag.h"



@implementation BrowserController (BrowserControllerDCMTKCategory)

- (BOOL)compressDICOMWithJPEG:(NSString *)path{
	OFCondition cond;
	OFBool status = YES;
	const char *fname = (const char *)[path UTF8String];
	DcmFileFormat fileformat;
	cond = fileformat.loadFile(fname);
	// if we can't read it stop
	if (!cond.good())
		return NO;
			
	E_TransferSyntax tSyntax = EXS_JPEGProcess14SV1TransferSyntax;
	DcmDataset *dataset = fileformat.getDataset();
	DcmItem *metaInfo = fileformat.getMetaInfo();
	E_TransferSyntax originalXfer = dataset->getOriginalXfer ();
	// only compress if an unencapsulated syntax
	if ((originalXfer == EXS_LittleEndianImplicit) || 
		(originalXfer == EXS_BigEndianImplicit) ||
		(originalXfer == EXS_LittleEndianExplicit) ||
		(originalXfer == EXS_BigEndianExplicit))
	{

		DcmRepresentationParameter *params;
		DJ_RPLossless losslessParams; 
		DJ_RPLossy lossyParams(0.8);
		DcmRLERepresentationParameter rleParams;
		// Use fixed lossless for now
		params = &losslessParams;
		
		
		/*
			DJ_RPLossless losslessParams; // codec parameters, we use the defaults
			if (transferSyntax == EXS_JPEGProcess14SV1TransferSyntax)
			params = &losslessParams;
			else if (transferSyntax == EXS_JPEGProcess2_4TransferSyntax)
			params = &lossyParams; 
			else if (transferSyntax == EXS_RLELossless)
			params = &rleParams; 
		*/

		// this causes the lossless JPEG version of the dataset to be created
		dataset->chooseRepresentation(tSyntax, params);
		// check if everything went well
		if (dataset->canWriteXfer(tSyntax))
		{
		// force the meta-header UIDs to be re-generated when storing the file 
		// since the UIDs in the data set may have changed 
	
		/*
			//only need to do this for lossy
		delete metaInfo->remove(DCM_MediaStorageSOPClassUID);
		delete metaInfo->remove(DCM_MediaStorageSOPInstanceUID);
		*/

			// store in lossless JPEG format
			
			fileformat.loadAllDataIntoMemory();
			[[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:fname] handler:nil];
			cond = fileformat.saveFile(fname, tSyntax);
			status =  (cond.good()) ? YES : NO;
		}
		else
			status = NO;
			
		return status;
	}
	else
		return YES;

}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest
{
	OFCondition cond;
	OFBool status = YES;
	const char *fname = (const char *)[path UTF8String];
	
	const char *destination = 0L;
	if( dest) destination = (const char *)[dest UTF8String];
	else
	{
		dest = path;
		destination = fname;
	}
	DcmFileFormat fileformat;
	cond = fileformat.loadFile(fname);
	DcmXfer filexfer(fileformat.getDataset()->getOriginalXfer());
	
	//hopefully dcmtk willsupport jpeg2000 compression and decompression in the future
	
	if (filexfer.getXfer() == EXS_JPEG2000LosslessOnly || filexfer.getXfer() == EXS_JPEG2000)
	{
		NSString *path = [NSString stringWithCString:fname encoding:[NSString defaultCStringEncoding]];
		DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile:path decodingPixelData:YES];
		
		[dcmObject writeToFile:[path stringByAppendingString:@" temp"] withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:1 AET:@"OsiriX" atomically:YES];
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		[[NSFileManager defaultManager] movePath:[path stringByAppendingString:@" temp"] toPath:dest handler: 0L];
		
		[dcmObject release];
	}
	else
	{
		  DcmDataset *dataset = fileformat.getDataset();

		  // decompress data set if compressed
		  dataset->chooseRepresentation(EXS_LittleEndianExplicit, NULL);

		  // check if everything went well
		  if (dataset->canWriteXfer(EXS_LittleEndianExplicit))
		  {
			fileformat.loadAllDataIntoMemory();
			[[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:fname] handler:nil];
			cond = fileformat.saveFile(destination, EXS_LittleEndianExplicit);
			status =  (cond.good()) ? YES : NO;
			
		  }
		  else
			status = NO;

	}

	return status;
}


@end
