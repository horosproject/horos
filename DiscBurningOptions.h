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


#import <Cocoa/Cocoa.h>
#import "DicomCompressor.h"


@interface DiscBurningOptions : NSObject <NSCopying> {
	BOOL anonymize;
	NSArray* anonymizationTags;
	BOOL includeWeasis;
	BOOL includeOsirixLite;
	BOOL includeHTMLQT;
	BOOL includeReports;
	BOOL includeAuxiliaryDir;
	NSString* auxiliaryDirPath;
	Compression compression;
	BOOL compressJPEGNotJPEG2000;
	BOOL zip, zipEncrypt;
	NSString* zipEncryptPassword;
}

/*extern NSString* const DiscBurningOptionsAnonymizeArchivingKey;
extern NSString* const DiscBurningOptionsAnonymizationTagsArchivingKey;
extern NSString* const DiscBurningOptionsIncludeOsirixLiteArchivingKey;
extern NSString* const DiscBurningOptionsIncludeHTMLQTArchivingKey;
extern NSString* const DiscBurningOptionsIncludeReportsArchivingKey;
extern NSString* const DiscBurningOptionsIncludeAuxiliaryDirArchivingKey;
extern NSString* const DiscBurningOptionsAuxiliaryDirPathArchivingKey;
extern NSString* const DiscBurningOptionsCompressionArchivingKey;
extern NSString* const DiscBurningOptionsCompressJPEGNotJPEG2000ArchivingKey;
extern NSString* const DiscBurningOptionsZipArchivingKey;
extern NSString* const DiscBurningOptionsZipEncryptArchivingKey;
extern NSString* const DiscBurningOptionsZipEncryptPasswordArchivingKey;*/

@property BOOL anonymize;
@property(retain) NSArray* anonymizationTags;
@property BOOL includeWeasis;
@property BOOL includeOsirixLite;
@property BOOL includeHTMLQT;
@property BOOL includeReports;
@property BOOL includeAuxiliaryDir;
@property(retain) NSString* auxiliaryDirPath;
@property Compression compression;
@property BOOL compressJPEGNotJPEG2000;
@property BOOL zip;
@property BOOL zipEncrypt;
@property(retain) NSString* zipEncryptPassword;

-(void)encodeWithCoder:(NSCoder*)encoder;
-(id)initWithCoder:(NSCoder*)decoder;

@end
