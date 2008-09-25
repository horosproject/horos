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

#import "BrowserControllerDCMTKCategory.h"
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMTransferSyntax.h>
#import "AppController.h"

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

//int testLocal(NSString *a, NSString *b, NSString *c)
//{
//	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
//	
//	//	argv[ 1] : in path
//	//	argv[ 2] : out path
//	//	argv[ 2] : what? compress or decompress?
//	
//	if( a && b)
//	{
//		// register global JPEG decompression codecs
//		DJDecoderRegistration::registerCodecs();
//
//		// register global JPEG compression codecs
//		DJEncoderRegistration::registerCodecs(
//			ECC_lossyYCbCr,
//			EUC_default,
//			OFFalse,
//			OFFalse,
//			0,
//			0,
//			0,
//			OFTrue,
//			ESS_444,
//			OFFalse,
//			OFFalse,
//			0,
//			0,
//			0.0,
//			0.0,
//			0,
//			0,
//			0,
//			0,
//			OFTrue,
//			OFFalse,
//			OFFalse,
//			OFFalse,
//			OFTrue);
//
//		// register RLE compression codec
//		DcmRLEEncoderRegistration::registerCodecs();
//
//		// register RLE decompression codec
//		DcmRLEDecoderRegistration::registerCodecs();
//	
//		NSString	*path = a;
//		NSString	*what = b;
//		NSString	*dest = 0L;
//		
//		dest = c;
//		
//		if( [what isEqualToString:@"compress"])
//		{
//			OFCondition cond;
//			OFBool status = YES;
//			const char *fname = (const char *)[path UTF8String];
//			const char *destination = 0L;
//			
//			if( dest && [dest isEqualToString:path] == NO) destination = (const char *)[dest UTF8String];
//			else
//			{
//				dest = path;
//				destination = fname;
//			}
//			
//			DcmFileFormat fileformat;
//			cond = fileformat.loadFile(fname);
//			// if we can't read it stop
//			if (!cond.good())
//				return NO;
//			E_TransferSyntax tSyntax = EXS_JPEGProcess14SV1TransferSyntax;
//			DcmDataset *dataset = fileformat.getDataset();
//			DcmItem *metaInfo = fileformat.getMetaInfo();
//			DcmXfer original_xfer(dataset->getOriginalXfer());
//			if (original_xfer.isEncapsulated())
//			{
//				NSLog(@"DICOM file is already compressed");
//				return 1;
//			}
//			
//			DJ_RPLossless losslessParams(6,0); 
//			//DJ_RPLossy lossyParams(0.8);
//			//DcmRLERepresentationParameter rleParams;
//			// Use fixed lossless for now
//			DcmRepresentationParameter *params = &losslessParams;
//			
//			/*
//				DJ_RPLossless losslessParams; // codec parameters, we use the defaults
//				if (transferSyntax == EXS_JPEGProcess14SV1TransferSyntax)
//				params = &losslessParams;
//				else if (transferSyntax == EXS_JPEGProcess2_4TransferSyntax)
//				params = &lossyParams; 
//				else if (transferSyntax == EXS_RLELossless)
//				params = &rleParams; 
//			*/
//
//			// this causes the lossless JPEG version of the dataset to be created
//			DcmXfer oxferSyn(tSyntax);
//			dataset->chooseRepresentation(tSyntax, params);
//			// check if everything went well
//			if (dataset->canWriteXfer(tSyntax))
//			{
//				// force the meta-header UIDs to be re-generated when storing the file 
//				// since the UIDs in the data set may have changed 
//				
//				//only need to do this for lossy
//				delete metaInfo->remove(DCM_MediaStorageSOPClassUID);
//				delete metaInfo->remove(DCM_MediaStorageSOPInstanceUID);
//				
//				// store in lossless JPEG format
//				fileformat.loadAllDataIntoMemory();
//				if( dest == path) [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:fname] handler:nil];
//				
//				cond = fileformat.saveFile(destination, tSyntax);
//				status =  (cond.good()) ? YES : NO;
//			}
//			else
//				status = NO;
//		}
//	}
//	
//	return 0;
//}

@implementation BrowserController (BrowserControllerDCMTKCategory)

- (BOOL)compressDICOMWithJPEG:(NSString *)path
{
//	testLocal(path, @"compress", 0L);
//	return YES;
//	
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects:path, @"compress", 0L]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
//	if( [NSThread currentThread] == [AppController mainThread]) [theTask waitUntilExit];	//<- The problem with this: it calls the current running loop.... problems with current Lock !
//	else
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];

	return YES;

}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest deleteOriginal:(BOOL) deleteOriginal
{
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects:path, @"decompress", dest,  0L]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
//	if( [NSThread currentThread] == [AppController mainThread]) [theTask waitUntilExit];	//<- The problem with this: it calls the current running loop.... problems with current Lock !
//	else
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];

	if( dest && [dest isEqualToString:path] == NO)
	{
		if( deleteOriginal) [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	}
	
	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest
{
	[self decompressDICOM: path to: dest deleteOriginal:YES];
}
@end
