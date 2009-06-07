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

- (BOOL)compressDICOMWithJPEG:(NSString *)path
{
	DcmFileFormat fileformat;
	OFCondition cond = fileformat.loadFile( [path UTF8String]);
	// if we can't read it stop
	if (!cond.good())
		return NO;
	DcmDataset *dataset = fileformat.getDataset();
	DcmItem *metaInfo = fileformat.getMetaInfo();
	DcmXfer original_xfer(dataset->getOriginalXfer());
	if (original_xfer.isEncapsulated())
	{
		NSLog( @"file already compressed: %@", [path lastPathComponent]);
		return YES;
	}
	
	const char *string = NULL;
	NSString *modality;
	if (dataset->findAndGetString(DCM_Modality, string, OFFalse).good() && string != NULL)
		modality = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
	else
		modality = @"OT";
	
	int quality, compression = [BrowserController compressionForModality: modality quality: &quality];
	
	if( compression != compression_none)
	{
//			NSString *dest2 = path;
//			
//			DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: path decodingPixelData:YES];
//			
//			BOOL succeed = NO;
//			
//			@try
//			{
//				succeed = [dcmObject writeToFile: [dest2 stringByAppendingString: @" temp"] withTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax] quality: quality AET:@"OsiriX" atomically:YES];
//			}
//			@catch (NSException *e)
//			{
//				NSLog( @"dcmObject writeToFile failed: %@", e);
//			}
//			[dcmObject release];
//			
//			if( succeed)
//			{
//				if( dest2 == path)
//					[[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
//				[[NSFileManager defaultManager] movePath: [dest2 stringByAppendingString: @" temp"] toPath: dest2 handler: nil];
//			}
//			else
//			{
//				NSLog( @"failed to compress file: %@", path);
//				[[NSFileManager defaultManager] removeFileAtPath: [dest2 stringByAppendingString: @" temp"] handler: nil];
//			}
		
		NSTask *theTask = [[NSTask alloc] init];
		
		if( compression == compression_JPEG2000)
			[theTask setArguments: [NSArray arrayWithObjects:path, @"compressJPEG2000", [NSString stringWithFormat: @"%d", quality], nil]];
		else
			[theTask setArguments: [NSArray arrayWithObjects:path, @"compress", nil]];
		
		[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
		[theTask launch];
		while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
		[theTask release];
	}
	
	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest deleteOriginal:(BOOL) deleteOriginal
{
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects:path, @"decompress", dest,  nil]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
	
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];
	
	
	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest
{
	return [self decompressDICOM: path to: dest deleteOriginal:YES];
}
@end
