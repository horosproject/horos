/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


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
