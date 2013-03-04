//
//  Unit_Tests.m
//  Unit Tests
//
//  Created by Joris Heuberger on 25.02.13.
//  Copyright (c) 2013 OsiriX Team. All rights reserved.
//

#import "Unit_Tests.h"
#import "DCMPix.h"
#import "dicomFile.h"
#import "Papyrus3/Papyrus3.h"

@implementation Unit_Tests

- (void)setUp
{
    [super setUp];
    
    Papy3Init();
    
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

- (void)testExample
{
	DCMPix *pix = [self dcmPixForFileNamed:@"MANIX-IM-0001-0021.dcm"];
	STAssertTrue(pix.pwidth==512, @"Image width should be 512 pixels");
	STAssertTrue(pix.pheight==512, @"Image height should be 512 pixels");
	
	pix = [self dcmPixForFileNamed:@"PNEUMATIX-IM-0001-0010.dcm"];
	STAssertTrue(pix.pwidth==224, @"Image width should be 224 pixels");
	STAssertTrue(pix.pheight==256, @"Image height should be 256 pixels");
}

@end
