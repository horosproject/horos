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
//		DCMTransferSyntax *tsx = [DCMTransferSyntax JPEG2000LosslessTransferSyntax];
//		succeed = [dcmObject writeToFile: [[paths lastObject] stringByAppendingString:@"aa.dcm"] withTransferSyntax: tsx quality: 2 AET:@"OsiriX" atomically:YES];
//	}
//	@catch (NSException *e)
//	{
//		NSLog( @"dcmObject writeToFile failed: %@", e);
//	}
//	[dcmObject release];

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
