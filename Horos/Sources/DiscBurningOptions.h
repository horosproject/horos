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
