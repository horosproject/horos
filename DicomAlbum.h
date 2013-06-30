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

@class DicomStudy;

/** \brief  Core Data Entity for an Album */

@interface DicomAlbum : NSManagedObject {
    int numberOfStudies;
}

@property(nonatomic, retain) NSNumber* index;
@property(nonatomic, retain) NSString* name;
@property(nonatomic, retain) NSString* predicateString;
//@property(nonatomic, retain) NSDictionary *correspondingDICOMNodeQuery;
@property(nonatomic, retain) NSNumber* smartAlbum;
@property(nonatomic, retain) NSSet* studies;
@property int numberOfStudies;

@end

@interface DicomAlbum (CoreDataGeneratedAccessors)

- (void)addStudiesObject:(DicomStudy *)value;
- (void)removeStudiesObject:(DicomStudy *)value;
- (void)addStudies:(NSSet *)value;
- (void)removeStudies:(NSSet *)value;

@end

