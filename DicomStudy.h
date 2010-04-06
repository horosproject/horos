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

@class DicomSeries;

/** \brief  Core Data Entity for a Study */
@interface DicomStudy : NSManagedObject
{
	BOOL isHidden;
	NSNumber *dicomTime;
}

@property(nonatomic, retain) NSString* accessionNumber;
@property(nonatomic, retain) NSString* comment;
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

+ (NSString*) soundex: (NSString*) s;
- (NSNumber *) noFiles;
- (NSSet *) paths;
- (NSSet *) keyImages;
- (NSArray *)imageSeries;
- (NSArray *)reportSeries;
- (NSArray *)keyObjectSeries;
- (NSArray *)keyObjects;
- (NSArray *)presentationStateSeries;
- (NSArray *)waveFormSeries;
- (NSManagedObject *) roiSRSeries;
- (NSManagedObject *) reportSRSeries;
- (NSManagedObject *) commentAndStatusSRSeries;
- (void) syncReportAndComments;
- (NSDictionary *)dictionary;
- (BOOL) isHidden;
- (void) setHidden: (BOOL) h;
- (NSNumber *) noFilesExcludingMultiFrames;

- (NSComparisonResult)compareName:(DicomStudy*)study;

-(BOOL)isBonjour;

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

@end

