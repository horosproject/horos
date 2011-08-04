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
#import <WebKit/WebKit.h>
#include <mingpp.h>

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
short					UseOpenJpeg = 1, Use_kdu_IfAvailable = 1;

extern void dcmtkSetJPEGColorSpace( int);

// WHY THIS EXTERNAL APPLICATION FOR COMPRESS OR DECOMPRESSION?

// Because if a file is corrupted, it will not crash the OsiriX application, but only this small task.

// Always modify this function in sync with compressionForModality in Decompress.mm / BrowserController.m
int compressionForModality( NSArray *array, NSArray *arrayLow, int limit, NSString* mod, int* quality, int resolution)
{
	NSArray *s;
	if( resolution < limit)
		s = arrayLow;
	else
		s = array;
	
	if( [mod isEqualToString: @"SR"]) // No compression for DICOM SR
		return compression_none;
	
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

void createSwfMovie(NSArray* inputFiles, NSString* path);

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// To avoid:
	// http://lists.apple.com/archives/quicktime-api/2007/Aug/msg00008.html
	// _NXCreateWindow: error setting window property (1002)
	// _NXTermWindow: error releasing window (1002)
	[NSApplication sharedApplication];
	
	
	//	argv[ 1] : in path
	//	argv[ 2] : what
	
	if( argv[ 1] && argv[ 2])
	{
		// register global JPEG decompression codecs
		DJDecoderRegistration::registerCodecs();

		// register global JPEG compression codecs
		DJEncoderRegistration::registerCodecs(
			ECC_lossyRGB,
			EUC_never,
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
			OFTrue,
			OFFalse,
			OFFalse,
			OFTrue);

		// register RLE compression codec
		DcmRLEEncoderRegistration::registerCodecs();

		// register RLE decompression codec
		DcmRLEDecoderRegistration::registerCodecs();
		
		NSString	*path = [NSString stringWithUTF8String:argv[1]];
		NSString	*what = [NSString stringWithUTF8String:argv[2]];
		NSInteger fileListFirstItemIndex = 3;
		
		NSMutableDictionary* dict = [DefaultsOsiriX getDefaults];
		[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"]];
		
		if ([what isEqualToString:@"SettingsPlist"])
		{
			@try
			{
				[dict addEntriesFromDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithUTF8String:argv[fileListFirstItemIndex]]]];
				what = [NSString stringWithUTF8String:argv[4]];
				fileListFirstItemIndex += 2;
			}
			@catch (NSException* e)
			{ // ignore evtl failures
				NSLog(@"Decompress failed reading settings plist at %s: %@", argv[fileListFirstItemIndex], e);
			}
		}
		
		dcmtkSetJPEGColorSpace( [[dict objectForKey:@"UseJPEGColorSpace"] intValue]);
		
		BOOL useDCMTKForJP2K = [[dict objectForKey:@"useDCMTKForJP2K"] intValue];
		
# pragma mark compress
		if( [what isEqualToString:@"compress"])
		{
			[DCMPixelDataAttribute setUse_kdu_IfAvailable: [[dict objectForKey:@"UseKDUForJPEG2000"] intValue]];
			
			UseOpenJpeg = [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue];
			Use_kdu_IfAvailable = [[dict objectForKey:@"UseKDUForJPEG2000"] intValue];
			
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
						
						const char *string = NULL;
						
//						NSString *sopClassUID = nil;
//						if (dataset->findAndGetString(DCM_SOPClassUID, string, OFFalse).good() && string != NULL)
//							sopClassUID = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
						
						if (original_xfer.isEncapsulated())
						{
							if( destDirec)
							{
								[[NSFileManager defaultManager] removeItemAtPath: curFileDest error: nil];
								[[NSFileManager defaultManager] moveItemAtPath: curFile toPath: curFileDest error: nil];
								[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
							}
						}
						else
						{
                            delete dataset->remove( DcmTagKey( 0x0009, 0x1110)); // "GEIIS" The problematic private group, containing a *always* JPEG compressed PixelData
                            
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
							
							if( useDCMTKForJP2K == NO && compression == compression_JPEG2000)
							{
								DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: curFile decodingPixelData: NO];
								
								BOOL succeed = NO;
								
								// See - (BOOL) needToCompressFile: (NSString*) path in BrowserControllerDCMTKCategory for these exceptions
								if( [DCMAbstractSyntaxUID isImageStorage: [dcmObject attributeValueWithName:@"SOPClassUID"]] == YES && [[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]] == NO && [DCMAbstractSyntaxUID isStructuredReport: [dcmObject attributeValueWithName:@"SOPClassUID"]] == NO)
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
								else
								{
									succeed = [[NSData dataWithContentsOfFile: curFile] writeToFile: curFileDest atomically: YES];
								}
								
								[dcmObject release];
								
								if( succeed)
								{
									[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
									if( destDirec == nil)
										[[NSFileManager defaultManager] moveItemAtPath: curFileDest toPath: curFile error: nil];
								}
								else
								{
									[[NSFileManager defaultManager] removeItemAtPath: curFileDest error:nil];
									
									if ([[dict objectForKey: @"DecompressMoveIfFail"] boolValue])
									{
										[[NSFileManager defaultManager] moveItemAtPath: curFile toPath: curFileDest error: nil];
									}
									else if( destDirec)
									{
										[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
										NSLog( @"failed to compress file: %@, the file is deleted", curFile);
									}
									else
										NSLog( @"failed to compress file: %@", curFile);
								}
							}
							else if( compression == compression_JPEG || compression == compression_JPEG2000)
							{
								DcmRepresentationParameter *params = nil;
								E_TransferSyntax tSyntax;
								DJ_RPLossless losslessParams(6,0);
								DJ_RPLossy JP2KParams( quality);
								DJ_RPLossy JP2KParamsLossLess( DCMLosslessQuality);
								
								if( compression == compression_JPEG)
								{
									params = &losslessParams;
									tSyntax = EXS_JPEGProcess14SV1TransferSyntax;
								}
								else if( compression == compression_JPEG2000)
								{
									if( quality == DCMLosslessQuality)
									{
										params = &JP2KParamsLossLess;
										tSyntax = EXS_JPEG2000LosslessOnly;
									}
									else
									{
										params = &JP2KParams;
										tSyntax = EXS_JPEG2000;
									}
								}
								else
								{
									params = &JP2KParamsLossLess;
									tSyntax = EXS_JPEG2000LosslessOnly;
									
									NSLog( @" ****** UNKNOW compression Decompress.mm");
								}
								
								// this causes the lossless JPEG version of the dataset to be created
								DcmXfer oxferSyn( tSyntax);
								dataset->chooseRepresentation(tSyntax, params);
								
								// check if everything went well
								if (dataset->canWriteXfer(tSyntax))
								{
									// force the meta-header UIDs to be re-generated when storing the file 
									// since the UIDs in the data set may have changed 
									
									//only need to do this for lossy
									//delete metaInfo->remove(DCM_MediaStorageSOPClassUID);
									//delete metaInfo->remove(DCM_MediaStorageSOPInstanceUID);
									
									// store in lossless JPEG format
									fileformat.loadAllDataIntoMemory();
									
									[[NSFileManager defaultManager] removeItemAtPath: curFileDest error:nil];
									cond = fileformat.saveFile( [curFileDest UTF8String], tSyntax);
									status =  (cond.good()) ? YES : NO;
									
									if( status == NO)
									{
										[[NSFileManager defaultManager] removeItemAtPath: curFileDest error:nil];
										if ([[dict objectForKey: @"DecompressMoveIfFail"] boolValue]) {
											[[NSFileManager defaultManager] moveItemAtPath: curFile toPath: curFileDest error: nil];
										} else
											if( destDirec)
											{
												[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
												NSLog( @"failed to compress file: %@, the file is deleted", curFile);
											}
											else
												NSLog( @"failed to compress file: %@", curFile);
									}
									else
									{
										[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
										if( destDirec == nil)
											[[NSFileManager defaultManager] moveItemAtPath: curFileDest toPath: curFile error: nil];
									}
								}
							}
							else
							{
								if( destDirec)
								{
									[[NSFileManager defaultManager] removeItemAtPath: curFileDest error: nil];
									[[NSFileManager defaultManager] moveItemAtPath: curFile toPath: curFileDest error: nil];
									[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
								}
							}
						}
					}
					else
						if ([[dict objectForKey: @"DecompressMoveIfFail"] boolValue]) {
							[[NSFileManager defaultManager] removeItemAtPath: curFileDest error: nil];
							[[NSFileManager defaultManager] moveItemAtPath: curFile toPath: curFileDest error: nil];
						} else NSLog( @"compress : cannot read file: %@", curFile);
				}
			}
		}
		
# pragma mark testFiles
		if( [what isEqualToString: @"testFiles"])
		{
			Papy3Init();
			
			[DCMPixelDataAttribute setUse_kdu_IfAvailable: [[dict objectForKey:@"UseKDUForJPEG2000"] intValue]];
			
			UseOpenJpeg = [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue];
			Use_kdu_IfAvailable = [[dict objectForKey:@"UseKDUForJPEG2000"] intValue];
			
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
		
# pragma mark decompressList
		if( [what isEqualToString:@"decompressList"])
		{
			NSString *destDirec;
			if( [path isEqualToString: @"sameAsDestination"])
				destDirec = nil;
			else
				destDirec = path;
			
			[DCMPixelDataAttribute setUse_kdu_IfAvailable: [[dict objectForKey:@"UseKDUForJPEG2000"] intValue]];
			
			UseOpenJpeg = [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue];
			Use_kdu_IfAvailable = [[dict objectForKey:@"UseKDUForJPEG2000"] intValue];
			
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
						
						//hopefully dcmtk willsupport jpeg2000 compression and decompression in the future: November 7th 2010 : I did it !
						
						if( useDCMTKForJP2K == NO && (filexfer.getXfer() == EXS_JPEG2000LosslessOnly || filexfer.getXfer() == EXS_JPEG2000))
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
								[[NSFileManager defaultManager] removeItemAtPath: curFileDest error:nil];
								
								if( destDirec)
								{
									[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
									NSLog( @"failed to decompress file: %@, the file is deleted", curFile);
								}
								else
									NSLog( @"failed to decompress file: %@", curFile);
							}
						}
						else if( filexfer.getXfer() != EXS_LittleEndianExplicit || filexfer.getXfer() != EXS_LittleEndianImplicit)
						{
							DcmDataset *dataset = fileformat.getDataset();
							
                            delete dataset->remove( DcmTagKey( 0x0009, 0x1110)); // "GEIIS" The problematic private group, containing a *always* JPEG compressed PixelData
                            
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
								[[NSFileManager defaultManager] removeItemAtPath: curFileDest error:nil];
								
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
								[[NSFileManager defaultManager] removeItemAtPath: curFileDest error:nil];
								
								if( destDirec)
								{
									[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
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
								[[NSFileManager defaultManager] removeItemAtPath: curFileDest error: nil];
								[[NSFileManager defaultManager] moveItemAtPath: curFile toPath: curFileDest error: nil];
								[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
							}
							status = NO;
						}
					}
				}
				
				if( status)
				{
					[[NSFileManager defaultManager] removeItemAtPath: curFile error: nil];
					if( destDirec == nil)
						[[NSFileManager defaultManager] moveItemAtPath: curFileDest toPath: curFile error: nil];
				}
			}
		}
		
# pragma mark writeMovie
		if( [what isEqualToString: @"writeMovie"])
		{
			if( ![path hasSuffix:@".swf"])
			{
				NSString *root = [NSString stringWithUTF8String: argv[fileListFirstItemIndex++]];
				
				long rateValue = 10;
				
				if( fileListFirstItemIndex <= argc)
				{
					rateValue = [[NSString stringWithUTF8String:argv[ fileListFirstItemIndex]] integerValue];
					
					if( rateValue <= 0)
						rateValue = 10;
					
					fileListFirstItemIndex++;
				}
				
				QTMovie *mMovie = nil;
				
				[[QTMovie movie] writeToFile: [path stringByAppendingString:@"temp"] withAttributes: nil];
				mMovie = [QTMovie movieWithFile:[path stringByAppendingString:@"temp"] error:nil];
				
				[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
				
				long long timeValue = 600 / rateValue;
				long timeScale = 600;
				
				QTTime curTime = QTMakeTime(timeValue, timeScale);
				
				NSMutableDictionary *myDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: @"jpeg", QTAddImageCodecType, [NSNumber numberWithInt: codecNormalQuality], QTAddImageCodecQuality, nil];
				
				for( NSString *img in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: root error: nil])
				{
					NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
					
					[mMovie addImage: [[[NSImage alloc] initWithContentsOfFile: [root stringByAppendingPathComponent: img]] autorelease] forDuration:curTime withAttributes: myDict];
					
					[pool release];
				}
				
				[mMovie writeToFile: path withAttributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: QTMovieFlatten]];
				[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"temp"] error: nil];
				
				if( root)
					[[NSFileManager defaultManager] removeItemAtPath: root error: nil];
			}
			else
			{ // SWF!!
				NSString* inputDir = [NSString stringWithUTF8String:argv[fileListFirstItemIndex++]];
				NSArray* inputFiles = [inputDir stringsByAppendingPaths:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:inputDir error:NULL]];
				createSwfMovie(inputFiles, path);
			}
		}
		
# pragma mark writeMovieiPhone
		if( [what isEqualToString: @"writeMovieiPhone"])
		{
			NSError *error = nil;
			
			NSString *inFile = [NSString stringWithUTF8String: argv[fileListFirstItemIndex++]];
			NSString *outFile = path;
			
			QTMovie *aMovie = [QTMovie movieWithFile: inFile error:&error];
			
			if (aMovie && error == nil)
			{
				if (NO == [aMovie attributeForKey:QTMovieHasApertureModeDimensionsAttribute])
				{
					[aMovie generateApertureModeDimensions];
				}
				
				[aMovie setAttribute:QTMovieApertureModeClean forKey:QTMovieApertureModeAttribute];
				
				long exportType = 'M4VP';
				if (fileListFirstItemIndex <= argc)
				{
					if (!strcmp(argv[fileListFirstItemIndex], "iPad"))
						exportType = 'M4VH';
					if (!strcmp(argv[fileListFirstItemIndex], "iPod"))
						exportType = 'M4V ';
					
					fileListFirstItemIndex++;
				}
				
				NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												   [NSNumber numberWithBool: YES], QTMovieExport,
												   [NSNumber numberWithBool: YES] ,QTMovieFlatten,
												   [NSNumber numberWithLong: exportType], QTMovieExportType, nil]; // 'M4VP'
				
				BOOL status = [aMovie writeToFile:outFile withAttributes:dictionary];
				
				if (NO == status)
				{
					// something didn't go right during the export process
					NSLog(@"%@ encountered a problem when writeMovieiPhone.\n", [outFile lastPathComponent]);
				}
			}
			else
				NSLog(@"writeMovieiPhone Error : %@", error);
			
			if( inFile)
				[[NSFileManager defaultManager] removeItemAtPath: inFile error: nil];
		}
		
# pragma mark pdfFromURL
		if( [what isEqualToString: @"pdfFromURL"])
		{
			@try
			{
				WebView *webView = [[[WebView alloc] initWithFrame: NSMakeRect(0,0,1,1) frameName: @"myFrame" groupName: @"myGroup"] autorelease];
				WebPreferences *webPrefs = [WebPreferences standardPreferences];
				
				[webPrefs setLoadsImagesAutomatically: YES];
				[webPrefs setAllowsAnimatedImages: YES];
				[webPrefs setAllowsAnimatedImageLooping: NO];
				[webPrefs setJavaEnabled: NO];
				[webPrefs setPlugInsEnabled: NO];
				[webPrefs setJavaScriptEnabled: YES];
				[webPrefs setJavaScriptCanOpenWindowsAutomatically: NO];
				[webPrefs setShouldPrintBackgrounds: YES];
				
				[webView setApplicationNameForUserAgent: @"OsiriX"];
				[webView setPreferences: webPrefs];
				[webView setMaintainsBackForwardList: NO];
				
				NSURL *theURL = [NSURL fileURLWithPath: path];
				if( theURL)
				{
					NSURLRequest *request = [NSURLRequest requestWithURL: theURL];
					
					[[webView mainFrame] loadRequest: request];
					
					NSTimeInterval oneMinute = [NSDate timeIntervalSinceReferenceDate] + 60;
					
					while( [[webView mainFrame] dataSource] == nil || [[[webView mainFrame] dataSource] isLoading] == YES || [[[webView mainFrame] provisionalDataSource] isLoading] == YES)
					{
						[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
						
						if( [NSDate timeIntervalSinceReferenceDate] > oneMinute)
							break;
					}
					
					NSPrintInfo *sharedInfo = [NSPrintInfo sharedPrintInfo];
					NSMutableDictionary *sharedDict = [sharedInfo dictionary];
					NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary: sharedDict];
					
					[printInfoDict setObject: NSPrintSaveJob forKey: NSPrintJobDisposition];
					
					[[NSFileManager defaultManager] removeItemAtPath: [path stringByAppendingPathExtension: @"pdf"] error: nil];
					[printInfoDict setObject: [path stringByAppendingPathExtension: @"pdf"] forKey: NSPrintSavePath];
					
					NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
					
					[printInfo setHorizontalPagination: NSAutoPagination];
					[printInfo setVerticalPagination: NSAutoPagination];
					[printInfo setVerticallyCentered:NO];
					
					NSView *viewToPrint = [[[webView mainFrame] frameView] documentView];
					NSPrintOperation *printOp = [NSPrintOperation printOperationWithView: viewToPrint printInfo: printInfo];
					[printOp setShowsPrintPanel: NO];
					[printOp setShowsProgressPanel: NO];
					[printOp runOperation];
				}
			}
			@catch (NSException * e)
			{
				NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			}
			return 0;
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

void createSwfMovie(NSArray* inputFiles, NSString* path) {
	if (path)
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	
	Ming_init();
	Ming_setSWFCompression(9); // 9 = maximum compression
	SWFMovie* swf = new SWFMovie(7);
	swf->setBackground(0x88, 0x88, 0x88);
	swf->setRate(10);
	
	BOOL sizeSet = NO;
	NSSize swfSize;
	
	NSString* as = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SWFInit" ofType:@"as"] encoding:NSUTF8StringEncoding error:NULL];
	//NSLog(@"AS:\n%@", as);
	SWFAction* action = new SWFAction([as cStringUsingEncoding:NSISOLatin1StringEncoding]);
	//		int len, res = action->compile(7, &len);
	//	NSLog(@"compile ret:%d len:%d", res, len);
	swf->add(action);
	
	const CGFloat ControllerHeight = 10, PlayPauseWidth = 0;
	const CGFloat ControllerPadTop = 1, ControllerPadBottom = 1;
	const CGFloat MarkHeight = ControllerHeight-ControllerPadTop-ControllerPadBottom, MarkWidth = MarkHeight-2;
	const CGFloat ControllerPadLeft = MarkWidth/2, ControllerPadRight = MarkWidth/2+PlayPauseWidth;
	NSRect ControllerRect;
	NSRect ControllerNavigationRect;
	const CGFloat ControllerBarThickness = 2, ControllerBarPadLeft = -ControllerBarThickness/2, ControllerBarPadRight = -ControllerBarThickness/2;
	
	// movie controller left of mark
	SWFShape* squareS = new SWFShape();
	squareS->setRightFillStyle(SWFFillStyle::SolidFillStyle(0,0,0,0));
	squareS->movePenTo(0,0);
	squareS->drawLine(1,0);
	squareS->drawLine(0,MarkHeight);
	squareS->drawLine(-1,0);
	squareS->drawLine(0,-MarkHeight);
	SWFButton* leftBarB = new SWFButton();
	leftBarB->addShape(squareS, SWFBUTTON_HIT|SWFBUTTON_UP|SWFBUTTON_DOWN|SWFBUTTON_OVER);
	leftBarB->addAction(new SWFAction("leftBarMouseDown();"), SWFBUTTON_MOUSEDOWN);
	SWFDisplayItem* leftBarDI = swf->add(leftBarB);
	leftBarDI->setName("leftBarDI");
	// movie controller right of mark
	squareS = new SWFShape();
	squareS->setRightFillStyle(SWFFillStyle::SolidFillStyle(0,0,0,0));
	squareS->movePenTo(0,0);
	squareS->drawLine(-1,0);
	squareS->drawLine(0,MarkHeight);
	squareS->drawLine(1,0);
	squareS->drawLine(0,-MarkHeight);
	SWFButton* rightBarB = new SWFButton();
	rightBarB->addShape(squareS, SWFBUTTON_HIT|SWFBUTTON_UP|SWFBUTTON_DOWN|SWFBUTTON_OVER);
	rightBarB->addAction(new SWFAction("rightBarMouseDown();"), SWFBUTTON_MOUSEDOWN);
	SWFDisplayItem* rightBarDI = swf->add(rightBarB);
	rightBarDI->setName("rightBarDI");
	
	// movie controller mark
	SWFShape* markS = new SWFShape();
	markS->setRightFillStyle(SWFFillStyle::SolidFillStyle(64,64,64,191));
	markS->movePenTo(-MarkWidth/2, -MarkHeight/2);
	markS->drawLine(MarkWidth,0);
	markS->drawLine(0,MarkHeight);
	markS->drawLine(-MarkWidth,0);
	markS->drawLine(0,-MarkHeight);
	SWFButton* markB = new SWFButton();
	markB->addShape(markS, SWFBUTTON_HIT|SWFBUTTON_UP|SWFBUTTON_DOWN|SWFBUTTON_OVER);
	markB->addAction(new SWFAction("markMouseDown();"), SWFBUTTON_MOUSEDOWN);
	SWFDisplayItem* markDI = swf->add(markB);
	markDI->setName("markDI");
	
	SWFBitmap* bitmap[inputFiles.count];
	SWFDisplayItem* displayItem[inputFiles.count];
//#pragma omp parallel for default(private)				
	for (int i = 0; i < inputFiles.count; ++i) {
		NSString* imgPath = [inputFiles objectAtIndex:i];
//		NSLog(@"%@", imgPath);
		
		bitmap[i] = new SWFBitmap(imgPath.UTF8String, NULL);
		if (!bitmap[i])
			NSLog(@"SWF creation FAILED: could not read %@", imgPath);
		NSSize bitmapSize = NSMakeSize(bitmap[i]->getWidth(), bitmap[i]->getHeight());
		
		if (!sizeSet) {
			swfSize = NSMakeSize(bitmapSize.width, bitmapSize.height+ControllerHeight); // 15 is the controller height
			swf->setDimension(swfSize.width, swfSize.height);
			sizeSet = YES;
		}
		
		SWFShape* shape = new SWFShape();
		shape->setRightFillStyle(SWFFillStyle::BitmapFillStyle(bitmap[i], SWFFILL_CLIPPED_BITMAP));
		shape->drawLine(bitmapSize.width,0);
		shape->drawLine(0,bitmapSize.height);
		shape->drawLine(-bitmapSize.width,0);
		shape->drawLine(0,-bitmapSize.height);
		
		displayItem[i] = swf->add(shape);
		displayItem[i]->moveTo(0,0);
		displayItem[i]->scaleTo(0);
	}
	
	// controller
	
	ControllerRect = NSMakeRect(0, swfSize.height-ControllerHeight, swfSize.width, ControllerHeight);
	ControllerNavigationRect = NSMakeRect(ControllerRect.origin.x+ControllerPadLeft, ControllerRect.origin.y+ControllerPadTop, ControllerRect.size.width-ControllerPadLeft-ControllerPadRight, ControllerRect.size.height-ControllerPadTop-ControllerPadBottom);
	swf->add(new SWFAction([[NSString stringWithFormat:@"_root.ControllerOriginX = %f; _root.ControllerWidth = %f;", ControllerNavigationRect.origin.x, ControllerNavigationRect.size.width] cStringUsingEncoding:NSISOLatin1StringEncoding]));
	NSRect ControllerBarRect = NSMakeRect(ControllerNavigationRect.origin.x+ControllerBarPadLeft, (ControllerNavigationRect.origin.y*2+ControllerNavigationRect.size.height-ControllerBarThickness)/2, ControllerNavigationRect.size.width-ControllerBarPadLeft-ControllerBarPadRight, ControllerBarThickness);
	
	SWFShape* controllerBar = new SWFShape();
	controllerBar->setRightFillStyle(SWFFillStyle::SolidFillStyle(191,191,191,127));
	controllerBar->movePenTo(0, 0);
	controllerBar->drawLine(1,0);
	controllerBar->drawLine(0,1);
	controllerBar->drawLine(-1,0);
	controllerBar->drawLine(0,-1);
	controllerBar->setRightFillStyle(SWFFillStyle::SolidFillStyle(191,191,191,127));
	SWFDisplayItem* controllerBarDisplayItem = swf->add(controllerBar);
	controllerBarDisplayItem->moveTo(ControllerBarRect.origin.x, ControllerBarRect.origin.y);
	controllerBarDisplayItem->scaleTo(ControllerBarRect.size.width, ControllerBarRect.size.height);	
	
	// TODO: play/pause
	
	// animation
	
	for (int i = 0; i < inputFiles.count; ++i) {
		markDI->moveTo(ControllerNavigationRect.origin.x+ControllerNavigationRect.size.width/(inputFiles.count-1)*i, ControllerNavigationRect.origin.y+ControllerNavigationRect.size.height/2);
		leftBarDI->scaleTo(ControllerNavigationRect.size.width/(inputFiles.count-1)*i, 1);
		leftBarDI->moveTo(ControllerNavigationRect.origin.x, ControllerNavigationRect.origin.y);
		rightBarDI->scaleTo(ControllerNavigationRect.size.width/(inputFiles.count-1)*(inputFiles.count-1-i),1);
		rightBarDI->moveTo(ControllerNavigationRect.origin.x+ControllerNavigationRect.size.width, ControllerNavigationRect.origin.y);
		
		for (int d = MAX(0,i-1); d < MIN(inputFiles.count,i+1); ++d)
			if (d == i)
				displayItem[d]->scaleTo(1);
			else displayItem[d]->scaleTo(0);
		
		swf->nextFrame();
	}
	
	swf->save(path.UTF8String);
	
	for (int i = 0; i < inputFiles.count; ++i)
		delete bitmap[i];
	
	delete swf;
	Ming_cleanup();	
}
