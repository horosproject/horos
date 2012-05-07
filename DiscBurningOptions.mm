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


#import "DiscBurningOptions.h"


@implementation DiscBurningOptions

@synthesize anonymize;
@synthesize anonymizationTags;
@synthesize includeWeasis;
@synthesize includeOsirixLite;
@synthesize includeHTMLQT;
@synthesize includeReports;
@synthesize includeAuxiliaryDir;
@synthesize auxiliaryDirPath;
@synthesize compression;
@synthesize compressJPEGNotJPEG2000;
@synthesize zip;
@synthesize zipEncrypt;
@synthesize zipEncryptPassword;

-(id)copyWithZone:(NSZone*)zone {
	DiscBurningOptions* copy = [[[self class] allocWithZone:zone] init];
	if( copy == nil) return nil;
	copy.anonymize = self.anonymize;
	copy.anonymizationTags = [[self.anonymizationTags copyWithZone:zone] autorelease];
	copy.includeWeasis = self.includeWeasis;
	copy.includeOsirixLite = self.includeOsirixLite;
	copy.includeHTMLQT = self.includeHTMLQT;
	copy.includeReports = self.includeReports;
	copy.includeAuxiliaryDir = self.includeAuxiliaryDir;
	copy.auxiliaryDirPath = [[self.auxiliaryDirPath copyWithZone:zone] autorelease];
	copy.compression = self.compression;
	copy.compressJPEGNotJPEG2000 = self.compressJPEGNotJPEG2000;
	copy.zip = self.zip;
	copy.zipEncrypt = self.zipEncrypt;
	copy.zipEncryptPassword = [[self.zipEncryptPassword copyWithZone:zone] autorelease];
	
	return copy;
}

-(void)dealloc {
	self.anonymizationTags = NULL;
	self.auxiliaryDirPath = NULL;
	self.zipEncryptPassword = NULL;
	[super dealloc];
}

static NSString* const DiscBurningOptionsAnonymizeArchivingKey = @"anonymize";
static NSString* const DiscBurningOptionsAnonymizationTagsArchivingKey = @"anonymizationTags";
static NSString* const DiscBurningOptionsIncludeWeasisArchivingKey = @"includeWeasis";
static NSString* const DiscBurningOptionsIncludeOsirixLiteArchivingKey = @"includeOsirixLite";
static NSString* const DiscBurningOptionsIncludeHTMLQTArchivingKey = @"includeHTMLQT";
static NSString* const DiscBurningOptionsIncludeReportsArchivingKey = @"includeReports";
static NSString* const DiscBurningOptionsIncludeAuxiliaryDirArchivingKey = @"includeAuxiliaryDir";
static NSString* const DiscBurningOptionsAuxiliaryDirPathArchivingKey = @"auxiliaryDirPath";
static NSString* const DiscBurningOptionsCompressionArchivingKey = @"compression";
static NSString* const DiscBurningOptionsCompressJPEGNotJPEG2000ArchivingKey = @"compressJPEGNotJPEG2000";
static NSString* const DiscBurningOptionsZipArchivingKey = @"zip";
static NSString* const DiscBurningOptionsZipEncryptArchivingKey = @"zipEncrypt";
static NSString* const DiscBurningOptionsZipEncryptPasswordArchivingKey = @"zipEncryptPassword";

-(void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeBool:self.anonymize forKey:DiscBurningOptionsAnonymizeArchivingKey];
	[encoder encodeObject:self.anonymizationTags forKey:DiscBurningOptionsAnonymizationTagsArchivingKey];
	[encoder encodeBool:self.includeWeasis forKey:DiscBurningOptionsIncludeWeasisArchivingKey];
	[encoder encodeBool:self.includeOsirixLite forKey:DiscBurningOptionsIncludeOsirixLiteArchivingKey];
	[encoder encodeBool:self.includeHTMLQT forKey:DiscBurningOptionsIncludeHTMLQTArchivingKey];
	[encoder encodeBool:self.includeReports forKey:DiscBurningOptionsIncludeReportsArchivingKey];
	[encoder encodeBool:self.includeAuxiliaryDir forKey:DiscBurningOptionsIncludeAuxiliaryDirArchivingKey];
	[encoder encodeObject:self.auxiliaryDirPath forKey:DiscBurningOptionsAuxiliaryDirPathArchivingKey];
	[encoder encodeInt:(int)self.compression forKey:DiscBurningOptionsCompressionArchivingKey];
	[encoder encodeBool:self.compressJPEGNotJPEG2000 forKey:DiscBurningOptionsCompressJPEGNotJPEG2000ArchivingKey];
	[encoder encodeBool:self.zip forKey:DiscBurningOptionsZipArchivingKey];
	[encoder encodeBool:self.zipEncrypt forKey:DiscBurningOptionsZipEncryptArchivingKey];
	[encoder encodeObject:self.zipEncryptPassword forKey:DiscBurningOptionsZipEncryptPasswordArchivingKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
	self = [super init];
	self.anonymize = [decoder decodeBoolForKey:DiscBurningOptionsAnonymizeArchivingKey];
	self.anonymizationTags = [decoder decodeObjectForKey:DiscBurningOptionsAnonymizationTagsArchivingKey];
	self.includeWeasis = [decoder decodeBoolForKey:DiscBurningOptionsIncludeWeasisArchivingKey];
	self.includeOsirixLite = [decoder decodeBoolForKey:DiscBurningOptionsIncludeOsirixLiteArchivingKey];
	self.includeHTMLQT = [decoder decodeBoolForKey:DiscBurningOptionsIncludeHTMLQTArchivingKey];
	self.includeReports = [decoder decodeBoolForKey:DiscBurningOptionsIncludeReportsArchivingKey];
	self.includeAuxiliaryDir = [decoder decodeBoolForKey:DiscBurningOptionsIncludeAuxiliaryDirArchivingKey];
	self.auxiliaryDirPath = [decoder decodeObjectForKey:DiscBurningOptionsAuxiliaryDirPathArchivingKey];
	self.compression = (Compression)[decoder decodeIntForKey:DiscBurningOptionsCompressionArchivingKey];
	self.compressJPEGNotJPEG2000 = [decoder decodeBoolForKey:DiscBurningOptionsCompressJPEGNotJPEG2000ArchivingKey];
	self.zip = [decoder decodeBoolForKey:DiscBurningOptionsZipArchivingKey];
	self.zipEncrypt = [decoder decodeBoolForKey:DiscBurningOptionsZipEncryptArchivingKey];
	self.zipEncryptPassword = [decoder decodeObjectForKey:DiscBurningOptionsZipEncryptPasswordArchivingKey];
	return self;
}

@end
