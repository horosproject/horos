/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/



#import <Cocoa/Cocoa.h>

#define THUMBNAILSIZE 70

@class DicomStudy, DicomImage;

/** \brief  Core Data Entity for a Series */

@interface DicomSeries : NSManagedObject
{
	NSNumber	*dicomTime;
}

@property(nonatomic, retain, readonly) NSNumber* dicomTime;

@property(nonatomic, retain) NSString* comment;
@property(nonatomic, retain) NSString* comment2;
@property(nonatomic, retain) NSString* comment3;
@property(nonatomic, retain) NSString* comment4;
@property(nonatomic, retain) NSDate* date;
@property(nonatomic, retain) NSDate* dateAdded;
@property(nonatomic, retain) NSDate* dateOpened;
@property(nonatomic, retain) NSNumber* displayStyle;
@property(nonatomic, retain) NSNumber* id;
@property(nonatomic, retain) NSString* modality;
@property(nonatomic, retain) NSNumber* mountedVolume __deprecated;
@property(nonatomic, retain) NSString* name;
@property(nonatomic, retain) NSNumber* numberOfImages;
@property(nonatomic, retain) NSNumber* numberOfKeyImages;
@property(nonatomic, retain) NSNumber* rotationAngle;
@property(nonatomic, retain) NSNumber* scale;
@property(nonatomic, retain) NSString* seriesDescription;
@property(nonatomic, retain) NSString* seriesDICOMUID;
@property(nonatomic, retain) NSString* seriesInstanceUID;
@property(nonatomic, retain) NSString* seriesSOPClassUID;
@property(nonatomic, retain) NSNumber* stateText;
@property(nonatomic, retain) NSData* thumbnail;
@property(nonatomic, retain) NSNumber* windowLevel;
@property(nonatomic, retain) NSNumber* windowWidth;
@property(nonatomic, retain) NSNumber* xFlipped;
@property(nonatomic, retain) NSNumber* xOffset;
@property(nonatomic, retain) NSNumber* yFlipped;
@property(nonatomic, retain) NSNumber* yOffset;
@property(nonatomic, retain) NSSet* images;
@property(nonatomic, retain) DicomStudy* study;

- (NSSet*) paths;
- (NSSet*) keyImages;
- (NSArray*) sortedImages;
- (NSComparisonResult) compareName:(DicomSeries*)series;
- (NSNumber*) noFilesExcludingMultiFrames;
- (NSNumber*) rawNoFiles;
- (DicomSeries*) previousSeries;
- (DicomSeries*) nextSeries;
- (NSArray*) sortDescriptorsForImages;
- (NSString*) uniqueFilename;
@end

@interface DicomSeries (CoreDataGeneratedAccessors)

- (void) addImagesObject:(DicomImage *)value;
- (void) removeImagesObject:(DicomImage *)value;
- (void) addImages:(NSSet *)value;
- (void) removeImages:(NSSet *)value;

@end
