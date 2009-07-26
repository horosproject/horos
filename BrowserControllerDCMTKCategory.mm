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

extern NSRecursiveLock *PapyrusLock;

@implementation BrowserController (BrowserControllerDCMTKCategory)

- (BOOL) needToCompressFile: (NSString*) path
{
	DcmFileFormat fileformat;
	OFCondition cond = fileformat.loadFile( [path UTF8String]);
	if( cond.good())
	{
		DcmDataset *dataset = fileformat.getDataset();
		DcmItem *metaInfo = fileformat.getMetaInfo();
		DcmXfer original_xfer(dataset->getOriginalXfer());
		if (original_xfer.isEncapsulated())
		{
			return NO;
		}
		else
		{
			const char *string = NULL;
			NSString *modality;
			if (dataset->findAndGetString(DCM_Modality, string, OFFalse).good() && string != NULL)
				modality = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
			else
				modality = @"OT";
			
			int resolution = 0;
			unsigned short rows = 0;
			if (dataset->findAndGetUint16( DCM_Rows, rows, OFFalse).good())
			{
				if( resolution == 0 || resolution > rows)
					resolution = rows;
			}
			unsigned short columns = 0;
			if (dataset->findAndGetUint16( DCM_Columns, columns, OFFalse).good())
			{
				if( resolution == 0 || resolution > columns)
					resolution = columns;
			}
			
			int quality, compression = [BrowserController compressionForModality: modality quality: &quality resolution: resolution];
			
			if( compression == compression_none)
				return NO;
				
			return YES;
		}
	}
	
	return NO;
}

+ (NSString*) compressionString: (NSString*) string
{
	if( [string isEqualToString: @"1.2.840.10008.1.2"])
		return NSLocalizedString( @"Uncompressed", nil);
	if( [string isEqualToString: @"1.2.840.10008.1.2.1"])
		return NSLocalizedString( @"Uncompressed", nil);
	if( [string isEqualToString: @"1.2.840.10008.1.2.2"])
		return NSLocalizedString( @"Uncompressed BigEndian", nil);
	
	return [NSString stringWithFormat:@"%s", dcmFindNameOfUID( [string UTF8String])];
}

- (BOOL)compressDICOMWithJPEG:(NSArray *) paths
{
	return [self compressDICOMWithJPEG: paths to: nil];
}

- (BOOL)compressDICOMWithJPEG:(NSArray *) paths to:(NSString*) dest
{
//	DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: [paths lastObject] decodingPixelData: NO];
//							
//	BOOL succeed = NO;
//	
//	@try
//	{
//		DCMTransferSyntax *tsx = [DCMTransferSyntax JPEG2000LosslessTransferSyntax]; // JPEG2000LosslessTransferSyntax];
//		succeed = [dcmObject writeToFile: [[paths lastObject] stringByAppendingString:@"aa.dcm"] withTransferSyntax: tsx quality: 1 AET:@"OsiriX" atomically:YES];
//	}
//	@catch (NSException *e)
//	{
//		NSLog( @"dcmObject writeToFile failed: %@", e);
//	}
//	[dcmObject release];
//	
//	return YES;

// ********

//	NSLog( @"** START");
//	NSString *dest2 = [paths lastObject];
//	
//	DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: [paths lastObject] decodingPixelData: NO];
//	
//	BOOL succeed = NO;
//	
//	@try
//	{
//		succeed = [dcmObject writeToFile: [dest2 stringByAppendingString: @" temp"] withTransferSyntax:[DCMTransferSyntax JPEG2000LossyTransferSyntax] quality: 0 AET:@"OsiriX" atomically:YES];
//	}
//	@catch (NSException *e)
//	{
//		NSLog( @"dcmObject writeToFile failed: %@", e);
//	}
//	[dcmObject release];
//	
//	if( succeed)
//	{
//		if( dest2 == [paths lastObject])
//			[[NSFileManager defaultManager] removeFileAtPath: [paths lastObject] handler: nil];
//		[[NSFileManager defaultManager] movePath: [dest2 stringByAppendingString: @" temp"] toPath: dest2 handler: nil];
//	}
//	else
//	{
//		NSLog( @"failed to compress file: %@", [paths lastObject]);
//		[[NSFileManager defaultManager] removeFileAtPath: [dest2 stringByAppendingString: @" temp"] handler: nil];
//	}
//	NSLog( @"** END");
	
	if( dest == nil)
		dest = @"sameAsDestination";
	
	NSTask *theTask = [[NSTask alloc] init];
	[theTask setArguments: [[NSArray arrayWithObjects: dest, @"compress", nil] arrayByAddingObjectsFromArray: paths]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];
	
	return YES;
}

- (BOOL)decompressDICOMList:(NSArray *) files to:(NSString*) dest
{
	NSTask *theTask = [[NSTask alloc] init];
	
	if( dest == nil)
		dest = @"sameAsDestination";
	
	NSArray *parameters = [[NSArray arrayWithObjects: dest, @"decompressList", nil] arrayByAddingObjectsFromArray: files];
	
	[theTask setArguments: parameters];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
	
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];
	
	return YES;
}
@end
