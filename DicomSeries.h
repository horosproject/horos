/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/


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
