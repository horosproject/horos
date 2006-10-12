#import <Foundation/Foundation.h>
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

// WHY THIS EXTERNAL APPLICATION FOR COMPRESS OR DECOMPRESSION?

// Because the jpeg libs (8,12,16 bits and jpg2000 libs) are not multi-threading safe.
// If you run multiple instance of this libraries in the same process, they will crash.
// By creating an external application, we are sure that all global variables are independant
// and we can freely use the algorithms on all processors at the same time for better
// performances on multy processors system !

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	//	argv[ 1] : in path
	//	argv[ 2] : out path
	//	argv[ 2] : what? compress or decompress?
	
	if( argv[ 1] && argv[ 2])
	{
		// register global JPEG decompression codecs
		DJDecoderRegistration::registerCodecs();

		// register global JPEG compression codecs
		DJEncoderRegistration::registerCodecs();

		// register RLE compression codec
		DcmRLEEncoderRegistration::registerCodecs();

		// register RLE decompression codec
		DcmRLEDecoderRegistration::registerCodecs();
	
		NSString	*path = [NSString stringWithCString:argv[ 1]];
		NSString	*what = [NSString stringWithCString:argv[ 2]];
		NSString	*dest = 0L;
		
		if(argv[ 3]) dest = [NSString stringWithCString:argv[ 3]];
		
		if( [what isEqualToString:@"decompress"])
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
		
			if( status == NO) NSLog(@"decompress error");
		}
		
	    // deregister JPEG codecs
		DJDecoderRegistration::cleanup();
		DJEncoderRegistration::cleanup();

		// deregister RLE codecs
		DcmRLEDecoderRegistration::cleanup();
		DcmRLEEncoderRegistration::cleanup();
	}
	
	[pool release];
	
	return 0;
}
