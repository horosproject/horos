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
//	if( t == nil) t = [[NSLock alloc] init];
//	[t lock];
//	int quality = [[NSUserDefaults standardUserDefaults] integerForKey: @"JPEG2000quality"];
//	DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: path decodingPixelData:YES];
//	[dcmObject writeToFile: [path stringByAppendingString: @" temp.dcm"] withTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax] quality:quality AET:@"OsiriX" atomically:YES];
//	[dcmObject release];
//	[t unlock];
	
	NSTask *theTask = [[NSTask alloc] init];
	
//	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"useJPEG2000forCompression"];
//	[[NSUserDefaults standardUserDefaults] setInteger: DCMLosslessQuality  forKey: @"JPEG2000quality"];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useJPEG2000forCompression"])
		[theTask setArguments: [NSArray arrayWithObjects:path, @"compressJPEG2000", nil]];
	else
		[theTask setArguments: [NSArray arrayWithObjects:path, @"compress", nil]];
		
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];

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
