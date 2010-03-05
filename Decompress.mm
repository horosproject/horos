#import <Foundation/Foundation.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMTransferSyntax.h>
#import <OsiriX/DCMPixelDataAttribute.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "DefaultsOsiriX.h"
#import "AppController.h"
#import "QTKit/QTMovie.h"
#import "DCMPix.h"

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

extern "C"
{
	extern short Papy3Init ();
}

NSLock					*PapyrusLock = 0L;
NSThread				*mainThread = 0L;
BOOL					NEEDTOREBUILD = NO;
NSMutableDictionary		*DATABASECOLUMNS = 0L;
short					Altivec = 0;
short					UseOpenJpeg = 0;

extern void dcmtkSetJPEGColorSpace( int);

// WHY THIS EXTERNAL APPLICATION FOR COMPRESS OR DECOMPRESSION?

// Because if a file is corrupted, it will not crash the OsiriX application, but only this small task.

// Always modify this function in sync with compressionForModality in Decompress.mm
int compressionForModality( NSArray *array, NSArray *arrayLow, int limit, NSString* mod, int* quality, int resolution)
{
	NSArray *s;
	if( resolution < limit)
		s = arrayLow;
	else
		s = array;
	
	for( NSDictionary *dict in s)
	{
		if( [[dict valueForKey: @"modality"] isEqualToString: mod])
		{
			int compression = compression_none;
			if( [[dict valueForKey: @"compression"] intValue] == compression_sameAsDefault)
				dict = [s objectAtIndex: 0];
			
			compression = [[dict valueForKey: @"compression"] intValue];
			
			if( quality)
			{
				if( compression == compression_JPEG2000)
					*quality = [[dict valueForKey: @"quality"] intValue];
				else
					*quality = 0;
			}
			
			return compression;
		}
	}
	
	if( [s count] == 0)
		return compression_none;
	
	if( quality)
		*quality = [[[s objectAtIndex: 0] valueForKey: @"quality"] intValue];
	
	return [[[s objectAtIndex: 0] valueForKey: @"compression"] intValue];
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	//	argv[ 1] : in path
	//	argv[ 2] : what
	
	NSLog(@"Decompress with %d args:", argc);
	for (int i = 0; i < argc; ++i)
		NSLog(@"\t%d: %s", i, argv[i]);
	
	if( argv[ 1] && argv[ 2])
	{
		// register global JPEG decompression codecs
		DJDecoderRegistration::registerCodecs();

		// register global JPEG compression codecs
		DJEncoderRegistration::registerCodecs(
			ECC_lossyYCbCr,
			EUC_default,
			OFFalse,
			OFFalse,
			0,
			0,
			0,
			OFTrue,
			ESS_444,
			OFFalse,
			OFFalse,
			0,
			0,
			0.0,
			0.0,
			0,
			0,
			0,
			0,
			OFTrue,
			OFFalse,
			OFFalse,
			OFFalse,
			OFTrue);

		// register RLE compression codec
		DcmRLEEncoderRegistration::registerCodecs();

		// register RLE decompression codec
		DcmRLEDecoderRegistration::registerCodecs();
		
		NSString	*path = [NSString stringWithUTF8String:argv[1]];
		NSString	*what = [NSString stringWithUTF8String:argv[2]];
		NSInteger fileListFirstItemIndex =3;
		
		NSMutableDictionary* dict = [DefaultsOsiriX getDefaults];
		[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"]];
		
		if ([what isEqualToString:@"SettingsPlist"]) {
			@try {
				[dict addEntriesFromDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithUTF8String:argv[fileListFirstItemIndex]]]];
				what = [NSString stringWithUTF8String:argv[4]];
				fileListFirstItemIndex += 2;
			} @catch (NSException* e) { // ignore evtl failures
				NSLog(@"Decompress failed reading settings plist at %s: %@", argv[fileListFirstItemIndex], e);
			}
		}
		
		dcmtkSetJPEGColorSpace( [[dict objectForKey:@"UseJPEGColorSpace"] intValue]);
		
		if( [what isEqualToString:@"compress"])
		{
			[DCMPixelDataAttribute setUseOpenJpeg: [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue]];
			
			NSArray *compressionSettings = [dict valueForKey: @"CompressionSettings"];
			NSArray *compressionSettingsLowRes = [dict valueForKey: @"CompressionSettingsLowRes"];
			
			int limit = [[dict objectForKey: @"CompressionResolutionLimit"] intValue];
			
			NSString *destDirec;
			if( [path isEqualToString: @"sameAsDestination"])
				destDirec = nil;
			else
				destDirec = path;
			
			int i;
			for( i = fileListFirstItemIndex; i < argc; i++)
			{
				NSString *curFile = [NSString stringWithUTF8String:argv[ i]];
				OFBool status = YES;
				NSString *curFileDest;
				
				if( destDirec)
					curFileDest = [destDirec stringByAppendingPathComponent: [curFile lastPathComponent]];
				else
					curFileDest = [curFile stringByAppendingString: @" temp"];
				
				if( [[curFile pathExtension] isEqualToString: @"zip"] || [[curFile pathExtension] isEqualToString: @"osirixzip"])
				{
					NSTask *t = [[[NSTask alloc] init] autorelease];
	
					@try
					{
						[t setLaunchPath: @"/usr/bin/unzip"];
						[t setCurrentDirectoryPath: @"/tmp/"];
						NSArray *args = [NSArray arrayWithObjects: @"-o", @"-d", curFileDest, curFile, nil];
						[t setArguments: args];
						[t launch];
						[t waitUntilExit];
					}
					@catch ( NSException *e)
					{
						NSLog( @"***** unzipFile exception: %@", e);
					}
					
					[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
				}
				else
				{
					DcmFileFormat fileformat;
					OFCondition cond = fileformat.loadFile( [curFile UTF8String]);
					// if we can't read it stop
					if( cond.good())
					{
						DcmDataset *dataset = fileformat.getDataset();
						DcmItem *metaInfo = fileformat.getMetaInfo();
						DcmXfer original_xfer(dataset->getOriginalXfer());
						if (original_xfer.isEncapsulated())
						{
							if( destDirec)
							{
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler: nil];
								[[NSFileManager defaultManager] movePath: curFile toPath: curFileDest handler: nil];
								[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
							}
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
							
							int quality, compression = compressionForModality( compressionSettings, compressionSettingsLowRes, limit, modality, &quality, resolution);
							
							if( compression == compression_JPEG2000)
							{
								DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: curFile decodingPixelData: NO];
								
								BOOL succeed = NO;
								
								if( [DCMAbstractSyntaxUID isImageStorage: [dcmObject attributeValueWithName:@"SOPClassUID"]] == YES && [[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]] == NO)
								{
									@try
									{
										DCMTransferSyntax *tsx = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
										succeed = [dcmObject writeToFile: curFileDest withTransferSyntax: tsx quality: quality AET:@"OsiriX" atomically:YES];
									}
									@catch (NSException *e)
									{
										NSLog( @"dcmObject writeToFile failed: %@", e);
									}
								}
								[dcmObject release];
								
								if( succeed)
								{
									[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
									if( destDirec == nil)
										[[NSFileManager defaultManager] movePath: curFileDest toPath: curFile handler: nil];
								}
								else
								{
									[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
									
									if( destDirec)
									{
										[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
										NSLog( @"failed to compress file: %@, the file is deleted", curFile);
									}
									else
										NSLog( @"failed to compress file: %@", curFile);
								}
							}
							else if( compression == compression_JPEG)
							{
								DJ_RPLossless losslessParams(6,0);
								
								DcmRepresentationParameter *params = &losslessParams;
								E_TransferSyntax tSyntax = EXS_JPEGProcess14SV1TransferSyntax;
								
								// this causes the lossless JPEG version of the dataset to be created
								DcmXfer oxferSyn( tSyntax);
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
									
									[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
									cond = fileformat.saveFile( [curFileDest UTF8String], tSyntax);
									status =  (cond.good()) ? YES : NO;
									
									if( status == NO)
									{
										[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
										if( destDirec)
										{
											[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
											NSLog( @"failed to compress file: %@, the file is deleted", curFile);
										}
										else
											NSLog( @"failed to compress file: %@", curFile);
									}
									else
									{
										[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
										if( destDirec == nil)
											[[NSFileManager defaultManager] movePath: curFileDest toPath: curFile handler: nil];
									}
								}
							}
							else
							{
								if( destDirec)
								{
									[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler: nil];
									[[NSFileManager defaultManager] movePath: curFile toPath: curFileDest handler: nil];
									[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
								}
							}
						}
					}
					else
						NSLog( @"compress : cannot read file: %@", curFile);
				}
			}
		}
		
		if( [what isEqualToString: @"testFiles"])
		{
			Papy3Init();
			
			[DCMPixelDataAttribute setUseOpenJpeg: [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue]];
			
			UseOpenJpeg = [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue];
			
			int i;
			for( i = fileListFirstItemIndex; i < argc ; i++)
			{
				NSString *curFile = [NSString stringWithUTF8String: argv[ i]];
				
				// Simply try to load and generate the image... will it crash?
				
				DCMPix *dcmPix = [[DCMPix alloc] initWithPath: curFile :0 :1 :nil :0 :0 isBonjour: NO imageObj: nil];
				
				if( dcmPix)
				{
					[dcmPix CheckLoad];
					
					//*(long*)0 = 0xDEADBEEF; // Dead Beef ? WTF ??? Will it unlock the matrix....
					
					[dcmPix release];
				}
				else NSLog( @"dcmPix == nil");
			}
		}
		
		if( [what isEqualToString:@"decompressList"])
		{
			NSString *destDirec;
			if( [path isEqualToString: @"sameAsDestination"])
				destDirec = nil;
			else
				destDirec = path;
			
			[DCMPixelDataAttribute setUseOpenJpeg: [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue]];
			
			int i;
			for( i = fileListFirstItemIndex; i < argc ; i++)
			{
				NSString *curFile = [NSString stringWithUTF8String:argv[ i]];
				
				NSString *curFileDest;
				
				if( destDirec)
					curFileDest = [destDirec stringByAppendingPathComponent: [curFile lastPathComponent]];
				else
					curFileDest = [curFile stringByAppendingString: @" temp"];
				
				OFBool status = NO;
				
				if( [[curFile pathExtension] isEqualToString: @"zip"] || [[curFile pathExtension] isEqualToString: @"osirixzip"])
				{
					NSTask *t = [[[NSTask alloc] init] autorelease];
	
					@try
					{
						[t setLaunchPath: @"/usr/bin/unzip"];
						[t setCurrentDirectoryPath: @"/tmp/"];
						NSArray *args = [NSArray arrayWithObjects: @"-o", @"-d", curFileDest, curFile, nil];
						[t setArguments: args];
						[t launch];
						[t waitUntilExit];
					}
					@catch ( NSException *e)
					{
						NSLog( @"***** unzipFile exception: %@", e);
					}
					
					[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
				}
				else
				{
					OFCondition cond;
					
					const char *fname = (const char *)[curFile UTF8String];
					const char *destination = (const char *)[curFileDest UTF8String];
					
					DcmFileFormat fileformat;
					cond = fileformat.loadFile(fname);
					
					if (cond.good())
					{
						DcmXfer filexfer(fileformat.getDataset()->getOriginalXfer());
						
						//hopefully dcmtk willsupport jpeg2000 compression and decompression in the future
						
						if (filexfer.getXfer() == EXS_JPEG2000LosslessOnly || filexfer.getXfer() == EXS_JPEG2000)
						{
							DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: curFile decodingPixelData: NO];
							@try
							{
								status = [dcmObject writeToFile: curFileDest withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:1 AET:@"OsiriX" atomically:YES];	//ImplicitVRLittleEndianTransferSyntax
							}
							@catch (NSException *e)
							{
								NSLog( @"dcmObject writeToFile failed: %@", e);
							}
							[dcmObject release];
							
							if( status == NO)
							{
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
								
								if( destDirec)
								{
									[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
									NSLog( @"failed to decompress file: %@, the file is deleted", curFile);
								}
								else
									NSLog( @"failed to decompress file: %@", curFile);
							}
						}
						else if( filexfer.getXfer() != EXS_LittleEndianExplicit || filexfer.getXfer() != EXS_LittleEndianImplicit)
						{
							DcmDataset *dataset = fileformat.getDataset();
							
							// decompress data set if compressed
							dataset->chooseRepresentation(EXS_LittleEndianExplicit, NULL);
							
							// check if everything went well
							if (dataset->canWriteXfer(EXS_LittleEndianExplicit))
							{
								fileformat.loadAllDataIntoMemory();
								cond = fileformat.saveFile(destination, EXS_LittleEndianExplicit);
								status =  (cond.good()) ? YES : NO;
							}
							else status = NO;
							
							if( status == NO) // Try DCM Framework...
							{
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
								
								DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: curFile decodingPixelData: NO];
								@try
								{
									status = [dcmObject writeToFile: curFileDest withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:1 AET:@"OsiriX" atomically:YES];	//ImplicitVRLittleEndianTransferSyntax
								}
								@catch (NSException *e)
								{
									NSLog( @"dcmObject writeToFile failed: %@", e);
								}
								[dcmObject release];
							}
							
							if( status == NO)
							{
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
								
								if( destDirec)
								{
									[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
									NSLog( @"failed to decompress file: %@, the file is deleted", curFile);
								}
								else
									NSLog( @"failed to decompress file: %@", curFile);
							}
						}
						else
						{
							if( destDirec)
							{
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler: nil];
								[[NSFileManager defaultManager] movePath: curFile toPath: curFileDest handler: nil];
								[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
							}
							status = NO;
						}
					}
				}
				
				if( status)
				{
					[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
					if( destDirec == nil)
						[[NSFileManager defaultManager] movePath: curFileDest toPath: curFile handler: nil];
				}
			}
		}
		
		if( [what isEqualToString: @"writeMovie"])
		{
			QTMovie *mMovie = nil;
			
			[[QTMovie movie] writeToFile: [path stringByAppendingString:@"temp"] withAttributes: nil];
			mMovie = [QTMovie movieWithFile:[path stringByAppendingString:@"temp"] error:nil];
			
			[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			
			long long timeValue = 60;
			long timeScale = 600;
			
			QTTime curTime = QTMakeTime(timeValue, timeScale);
			
			NSMutableDictionary *myDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: @"jpeg", QTAddImageCodecType, [NSNumber numberWithInt: codecNormalQuality], QTAddImageCodecQuality, nil];
			
			NSString *root = [NSString stringWithUTF8String: argv[fileListFirstItemIndex]];
			
			for( NSString *img in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: root error: nil])
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				
				[mMovie addImage: [[[NSImage alloc] initWithContentsOfFile: [root stringByAppendingPathComponent: img]] autorelease] forDuration:curTime withAttributes: myDict];
				
				[pool release];
			}
			
			[mMovie writeToFile: path withAttributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: QTMovieFlatten]];
			[[NSFileManager defaultManager] removeFileAtPath:[path stringByAppendingString:@"temp"] handler: nil];
			
			[[NSFileManager defaultManager] removeItemAtPath: root error: nil];
		}
		
		if( [what isEqualToString: @"writeMovieiPhone"])
		{
			NSError *error = nil;
			
			NSString *inFile = [NSString stringWithUTF8String: argv[fileListFirstItemIndex]];
			NSString *outFile = path;
			
			QTMovie *aMovie = [QTMovie movieWithFile: inFile error:nil];
			
			if (aMovie && error == nil)
			{
				if (NO == [aMovie attributeForKey:QTMovieHasApertureModeDimensionsAttribute])
				{
					[aMovie generateApertureModeDimensions];
				}
				
				[aMovie setAttribute:QTMovieApertureModeClean forKey:QTMovieApertureModeAttribute];
				
				NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												   [NSNumber numberWithBool:YES], QTMovieExport,
												   [NSNumber numberWithLong:'M4VP'], QTMovieExportType, nil];
				
				BOOL status = [aMovie writeToFile:outFile withAttributes:dictionary];
				
				if (NO == status)
				{
					// something didn't go right during the export process
					NSLog(@"%@ encountered a problem when writeMovieiPhone.\n", [outFile lastPathComponent]);
				}
			}
			else
				NSLog(@"writeMovieiPhone Error : %@", error);
				
			[[NSFileManager defaultManager] removeItemAtPath: inFile error: nil];
		}
		
	    // deregister JPEG codecs
		//DJDecoderRegistration::cleanup();	We dont care: we are just a small app : our memory will be killed by the system. Dont loose time here !
		//DJEncoderRegistration::cleanup();	We dont care: we are just a small app : our memory will be killed by the system. Dont loose time here !

		// deregister RLE codecs
		//DcmRLEDecoderRegistration::cleanup();	We dont care: we are just a small app : our memory will be killed by the system. Dont loose time here !
		//DcmRLEEncoderRegistration::cleanup();	We dont care: we are just a small app : our memory will be killed by the system. Dont loose time here !
	}
	
//	[pool release]; We dont care: we are just a small app : our memory will be killed by the system. Dont loose time here !
	
	return 0;
}
