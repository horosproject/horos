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

#import "DICOMFilesTests.h"
#import "DCMPix.h"
#import "dicomFile.h"
#import "DDData.h"

#include "options.h"

@implementation DICOMFilesTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)checkFileAtPath:(NSString*)filePath
{
	STAssertNotNil(filePath, @"The file path is nil");
	STAssertTrue(filePath.length>0, @"The file path is empty");
	
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	STAssertTrue(fileExists, @"The file '%@' does not exist", filePath);
	
	NSData *content = [[NSFileManager defaultManager] contentsAtPath:filePath];
	STAssertTrue(content.length>0, @"The content of '%@' is empty", [filePath lastPathComponent]);
	
	BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:filePath];
	STAssertTrue(isReadable, @"The file '%@' is not readable", [filePath lastPathComponent]);
}

- (void)checkDICOMFileAtPath:(NSString*)filePath
{
	[self checkFileAtPath:filePath];
	BOOL isDICOM = [DicomFile isDICOMFile:filePath];
	STAssertTrue(isDICOM, @"The file '%@' is not a DICOM file", [filePath lastPathComponent]);
}

- (DCMPix*)dcmPixForFileNamed:(NSString*)filename
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *filePath = [bundle pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
	[self checkDICOMFileAtPath:filePath];
	
	DCMPix *pix = [[[DCMPix alloc] initWithContentsOfFile:filePath] autorelease];
	[pix CheckLoad];
	
	return pix;
}

- (void)validatePix:(DCMPix*)pix expectations:(NSDictionary*)expectations
{
	if ([expectations objectForKey:@"pwidth"])
	{
		float pwidth = [[expectations objectForKey:@"pwidth"] floatValue];
		STAssertTrue(pix.pwidth==pwidth, [NSString stringWithFormat:@"Image width should be %g pixels", pwidth]);
	}
	if ([expectations objectForKey:@"pheight"])
	{
		float pheight = [[expectations objectForKey:@"pheight"] floatValue];
		STAssertTrue(pix.pheight==pheight, [NSString stringWithFormat:@"Image height should be %g pixels", pheight]);
	}
	
	NSData *imageData = (NSData*)[NSData dataWithBytesNoCopy:(float*)pix.fImage length:pix.pwidth*pix.pheight*sizeof(float) freeWhenDone:NO];
	if ([expectations objectForKey:@"md5"])
	{
		NSString *md5 = [[imageData md5Digest] hexStringValue];
		NSString *expectedMD5 = [expectations objectForKey:@"md5"];
		STAssertTrue([md5 isEqualToString:expectedMD5], [NSString stringWithFormat:@"Image md5 should be %@", expectedMD5]);
	}
	if ([expectations objectForKey:@"sha1"])
	{
		NSString *sha1 = [[imageData sha1Digest] hexStringValue];
		NSString *expectedSHA1 = [expectations objectForKey:@"sha1"];
		STAssertTrue([sha1 isEqualToString:expectedSHA1], [NSString stringWithFormat:@"Image sha1 should be %@", expectedSHA1]);
	}
}

- (void)testDCMPixBasic
{
	DCMPix *pix;
	NSDictionary *expectations;
	
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *filePath = [bundle pathForResource:@"DICOMFiles" ofType:@"plist"];
	NSArray *files = [NSArray arrayWithContentsOfFile:filePath];
	
	for (NSDictionary *file in files)
	{
		NSString *filename = [file objectForKey:@"filename"];
		NSDictionary *expectations = [file objectForKey:@"expectations"];
		[self validatePix:[self dcmPixForFileNamed:filename] expectations:expectations];
	}
}

@end
