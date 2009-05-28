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
#import <OsiriX/DCM.h>
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


@implementation BrowserController (BrowserControllerDCMTKCategory)

- (BOOL)compressDICOMWithJPEG:(NSString *)path
{
//	NSTask *theTask = [[NSTask alloc] init];
//	
//	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useJPEG2000forCompression"])
//		[theTask setArguments: [NSArray arrayWithObjects:path, @"compressJPEG2000", nil]];
//	else
//		[theTask setArguments: [NSArray arrayWithObjects:path, @"compress", nil]];
//		
//	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
//	[theTask launch];
//	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
//	[theTask release];

	NSString *dest = nil;
	
	OFCondition cond;
	OFBool status = YES;
	const char *fname = (const char *)[path UTF8String];
	const char *destination = nil;
	
	if( dest && [dest isEqualToString:path] == NO) destination = (const char *)[dest UTF8String];
	else
	{
		dest = path;
		destination = fname;
	}
	
	DcmFileFormat fileformat;
	cond = fileformat.loadFile(fname);
	// if we can't read it stop
	if (!cond.good()) return NO;
	E_TransferSyntax tSyntax = EXS_JPEGProcess14SV1TransferSyntax;
	DcmDataset *dataset = fileformat.getDataset();
	DcmItem *metaInfo = fileformat.getMetaInfo();
	DcmXfer original_xfer(dataset->getOriginalXfer());
	if (original_xfer.isEncapsulated())
	{
		
	}
	else
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useJPEG2000forCompression"])
		{
			int quality = [[NSUserDefaults standardUserDefaults] integerForKey:@"JPEG2000quality"];
			
			DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: path decodingPixelData:YES];
			[dcmObject writeToFile: [dest stringByAppendingString: @" temp"] withTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax] quality: quality AET:@"OsiriX" atomically:YES];
			[dcmObject release];
			
			if( dest == path)
				[[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
			[[NSFileManager defaultManager] movePath: [dest stringByAppendingString: @" temp"]  toPath: dest handler: nil];
		}
		else
		{
			DJ_RPLossless losslessParams(6,0); 
			DcmRepresentationParameter *params = &losslessParams;
			
			// this causes the lossless JPEG version of the dataset to be created
			DcmXfer oxferSyn(tSyntax);
			dataset->chooseRepresentation(tSyntax, params);
			// check if everything went well
			if (dataset->canWriteXfer(tSyntax))
			{
				// force the meta-header UIDs to be re-generated when storing the file 
				// since the UIDs in the data set may have changed 
				
				//only need to do this for lossy
				delete metaInfo->remove(DCM_MediaStorageSOPClassUID);
				delete metaInfo->remove(DCM_MediaStorageSOPInstanceUID);
				
				// store in lossless JPEG format
				fileformat.loadAllDataIntoMemory();
				if( dest == path) [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:fname] handler:nil];
				
				cond = fileformat.saveFile(destination, tSyntax);
				status =  (cond.good()) ? YES : NO;
			}
			else
				status = NO;
		}
	}
		
	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest deleteOriginal:(BOOL) deleteOriginal
{
//	NSTask *theTask = [[NSTask alloc] init];
//	
//	[theTask setArguments: [NSArray arrayWithObjects:path, @"decompress", dest,  nil]];
//	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
//	[theTask launch];
//	
//	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
//	[theTask release];
	
	OFCondition cond;
	OFBool status = YES;
	const char *fname = (const char *)[path UTF8String];
	
	const char *destination = nil;
	
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
		DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile:path decodingPixelData:YES];
		
		[dcmObject writeToFile:[path stringByAppendingString:@" temp"] withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:1 AET:@"OsiriX" atomically:YES];
		
		[dcmObject release];
		
		if( dest == path) [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		
		[[NSFileManager defaultManager] movePath:[path stringByAppendingString:@" temp"] toPath:dest handler: nil];
	}
	else if (filexfer.getXfer() != EXS_LittleEndianExplicit)
	{
		DcmDataset *dataset = fileformat.getDataset();
		
		// decompress data set if compressed
		dataset->chooseRepresentation(EXS_LittleEndianExplicit, NULL);
		
		// check if everything went well
		if (dataset->canWriteXfer(EXS_LittleEndianExplicit))
		{
			fileformat.loadAllDataIntoMemory();
			if( dest == path) [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:fname] handler:nil];
			cond = fileformat.saveFile(destination, EXS_LittleEndianExplicit);
			status =  (cond.good()) ? YES : NO;
		}
		else status = NO;
	}
	
	if( dest && [dest isEqualToString:path] == NO)
	{
		if( deleteOriginal) [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	}
	
	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest
{
	return [self decompressDICOM: path to: dest deleteOriginal:YES];
}
@end
