/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "DicomDatabase+DCMTK.h"
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMTransferSyntax.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "DCMPix.h"
#import "AppController.h"
#import "BrowserController.h"

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

#define CHUNK_SUBPROCESS 500

@implementation DicomDatabase (DCMTK)

+(BOOL)fileNeedsDecompression:(NSString*)path {
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
			NSString *modality = @"OT";
			if (dataset->findAndGetString(DCM_Modality, string, OFFalse).good() && string != NULL)
				modality = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
			
			NSString *SOPClassUID = @"";
			if (dataset->findAndGetString(DCM_SOPClassUID, string, OFFalse).good() && string != NULL)
				SOPClassUID = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
			
			// See Decompress.mm for these exceptions
			if( [DCMAbstractSyntaxUID isImageStorage: SOPClassUID] == YES && [SOPClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]] == NO && [DCMAbstractSyntaxUID isStructuredReport: SOPClassUID] == NO)
			{
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
	}
	
	return NO;
}


+(BOOL)compressDicomFilesAtPaths:(NSArray*)paths {
	return [self compressDicomFilesAtPaths:paths intoDirAtPath:nil];
}

+(BOOL)decompressDicomFilesAtPaths:(NSArray*)paths {
	return [self decompressDicomFilesAtPaths:paths intoDirAtPath:nil];
}

+(BOOL)compressDicomFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)dest {
	if (dest == nil)
		dest = @"sameAsDestination";
	
	
	int total = [paths count];
	
	for( int i = 0; i < total;)
	{
		int no;
		
		if( i + CHUNK_SUBPROCESS >= total) no = total - i; 
		else no = CHUNK_SUBPROCESS;
		
		NSRange range = NSMakeRange( i, no);
		
		id *objs = (id*) malloc( no * sizeof( id));
		if( objs)
		{
			[paths getObjects: objs range: range];
			
			NSArray *subArray = [NSArray arrayWithObjects: objs count: no];
			
			NSTask *theTask = [[NSTask alloc] init];
			@try
			{
				[theTask setArguments: [[NSArray arrayWithObjects: dest, @"compress", nil] arrayByAddingObjectsFromArray: subArray]];
				[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
				[theTask launch];
				while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
			}
			@catch ( NSException *e)
			{
				NSLog( @"***** compressDICOMWithJPEG exception : %@", e);
			}
			[theTask release];
			
			free( objs);
		}
		
		i += no;
	}
	
	return YES;
}

+(BOOL)decompressDicomFilesAtPaths:(NSArray*)files intoDirAtPath:(NSString*)dest {
	if (dest == nil)
		dest = @"sameAsDestination";
	
	int total = [files count];
	
	for( int i = 0; i < total;)
	{
		int no;
		
		if( i + CHUNK_SUBPROCESS >= total) no = total - i; 
		else no = CHUNK_SUBPROCESS;
		
		NSRange range = NSMakeRange( i, no);
		
		id *objs = (id*) malloc( no * sizeof( id));
		if( objs)
		{
			[files getObjects: objs range: range];
			
			NSArray *subArray = [NSArray arrayWithObjects: objs count: no];
			
			NSTask *theTask = [[NSTask alloc] init];
			
			@try
			{
				NSArray *parameters = [[NSArray arrayWithObjects: dest, @"decompressList", nil] arrayByAddingObjectsFromArray: subArray];
				
				[theTask setArguments: parameters];
				[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
				[theTask launch];
				
				while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
			}
			@catch ( NSException *e)
			{
				NSLog( @"***** decompressDICOMList exception : %@", e);
			}
			[theTask release];
			
			free( objs);
		}
		
		i += no;
	}
	
	return YES;
}

@end
