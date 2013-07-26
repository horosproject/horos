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

@class DicomSeries, DicomImage;

/** \brief  Core Data Entity for a Study */
@interface DicomStudy : NSManagedObject
{
	BOOL isHidden;
	NSNumber *dicomTime;
    NSUInteger _numberOfImagesWhenCachedModalities;
	NSString *cachedModalites;
    BOOL reentry;
}

@property(nonatomic, retain) NSString* accessionNumber;
@property(nonatomic, retain) NSString* comment;
@property(nonatomic, retain) NSString* comment2;
@property(nonatomic, retain) NSString* comment3;
@property(nonatomic, retain) NSString* comment4;
@property(nonatomic, retain) NSDate* date;
@property(nonatomic, retain) NSDate* dateAdded;
@property(nonatomic, retain) NSDate* dateOfBirth;
@property(nonatomic, retain) NSDate* dateOpened;
@property(nonatomic, retain) NSString* dictateURL;
@property(nonatomic, retain) NSNumber* expanded;
@property(nonatomic, retain) NSNumber* hasDICOM;
@property(nonatomic, retain) NSString* id;
@property(nonatomic, retain) NSString* institutionName;
@property(nonatomic, retain) NSNumber* lockedStudy;
@property(nonatomic, retain) NSString* modality;
@property(nonatomic, retain) NSString* name;
@property(nonatomic, retain) NSNumber* numberOfImages;
@property(nonatomic, retain) NSString* patientID;
@property(nonatomic, retain) NSString* patientSex;
@property(nonatomic, retain) NSString* patientUID;
@property(nonatomic, retain) NSString* performingPhysician;
@property(nonatomic, retain) NSString* referringPhysician;
@property(nonatomic, retain) NSString* reportURL;
@property(nonatomic, retain) NSNumber* stateText;
@property(nonatomic, retain) NSString* studyInstanceUID;
@property(nonatomic, retain) NSString* studyName;
@property(nonatomic, retain) NSData* windowsState;
@property(nonatomic, retain) NSSet* albums;
@property(nonatomic, retain) NSSet* series;

+ (NSRecursiveLock*) dbModifyLock;
+ (NSString*) soundex: (NSString*) s;
- (NSString*) soundex;
+ (NSString*) yearOldFromDateOfBirth: (NSDate*) dateOfBirth;
+ (NSString*) yearOldAcquisition:(NSDate*) acquisitionDate FromDateOfBirth: (NSDate*) dateOfBirth;
+ (BOOL) displaySeriesWithSOPClassUID: (NSString*) uid andSeriesDescription: (NSString*) description;
- (NSNumber *) noFiles;
- (NSSet *) paths;
- (NSSet *) keyImages;
- (NSSet *) images;
- (NSNumber *) rawNoFiles;
- (NSString*) modalities;
+ (NSString*) displayedModalitiesForSeries: (NSArray*) seriesModalities;
- (NSArray *) imageSeries;
- (NSArray*) imageSeriesContainingPixels:(BOOL) pixels;
- (NSArray *) keyObjectSeries;
- (NSArray *) keyObjects;
- (NSArray *) presentationStateSeries;
- (NSArray *) waveFormSeries;
- (NSString*) roiPathForImage: (DicomImage*) image inArray: (NSArray*) roisArray;
- (NSString*) roiPathForImage: (DicomImage*) image;
- (DicomImage*) roiForImage: (DicomImage*) image inArray: (NSArray*) roisArray;
- (DicomSeries *) roiSRSeries;
- (DicomSeries *) reportSRSeries;
- (DicomImage*) reportImage;
- (DicomImage *) annotationsSRImage;
- (void) archiveReportAsDICOMSR;
- (void) archiveAnnotationsAsDICOMSR;
- (BOOL) isHidden;
- (BOOL) isDistant;
- (void) setHidden: (BOOL) h;
- (NSNumber *) noFilesExcludingMultiFrames;
- (NSDictionary*) annotationsAsDictionary;
- (void) applyAnnotationsFromDictionary: (NSDictionary*) rootDict;
- (void) reapplyAnnotationsFromDICOMSR;
- (NSComparisonResult) compareName:(DicomStudy*)study;
-(NSArray*) roiImages;
@end

@interface DicomStudy (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(NSManagedObject *)value;
- (void)removeAlbumsObject:(NSManagedObject *)value;
- (void)addAlbums:(NSSet *)value;
- (void)removeAlbums:(NSSet *)value;

- (void)addSeriesObject:(DicomSeries *)value;
- (void)removeSeriesObject:(DicomSeries *)value;
- (void)addSeries:(NSSet *)value;
- (void)removeSeries:(NSSet *)value;

- (NSArray*) imagesForKeyImages:(BOOL) keyImages andForROIs:(BOOL)alsoImagesWithROIs;

+ (NSString*) scrambleString: (NSString*) t;

@end

