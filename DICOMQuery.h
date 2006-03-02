/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Foundation/Foundation.h>

#define PatientNameTag 0x0010,0x0010
#define PatientIDTag 0x0010,0x0020
#define PatientBDTag 0x0010,0x0030
#define PatientSexTag 0x0010,0x0040
#define PatientAgeTag 0x0010,0x1010

#define StudyIDTag 0x0020,0x0010
#define StudyDescriptionTag 0x0008,0x1030
#define ModalitiesInStudyTag 0x0008,0x0061
#define ModalityTag 0x0008,0x0060
#define StudyDateTag 0x0008,0x0020
#define StudyTimeTag 0x0008,0x0030
#define StudyInstanceUIDTag 0x0020,0x000d

#define SeriesDescriptionTag 0x0008,0x103e
#define SeriesNumberTag 0x0020,0x0011
#define SeriesDateTag 0x0008,0x0021
#define SeriesTimeTag 0x0008,0x0031
#define SeriesInStudyTag 0x0020,0x1000
#define SeriesInstanceUIDTag 0x0020,0x000e

#define InstanceNumberTag 0x0020,0x0013
#define ContentDateTag 0x0008,0x0023
#define ContentTimeTag 0x0008,0x0033
#define ImageTypeTag 0x0008,0x0008
#define NumberOfFramesTag 0x0028,0x0008
#define SOPInstanceUIDTag 0x0008,0x0018

#define SpecificCharacterSetTag 0x0008,0x0005
#define SOPClassUIDTag 0x0008,0x0016
#define QueryRetrieveLevelTag 0x0008,0x0052


@class PMQueryTreeModel;


@interface DICOMQuery : NSObject {
NSString *callingAET;
NSString *calledAET;
NSString *hostname;
NSString *port;
NSMutableDictionary *filters;
id queryModel;
PMQueryTreeModel *tree;
NSArray *tags;
NSArray *keys;
NSArray *javaNames;

}

- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort;

- (void)addFilter:(NSString *)filter forTag:(NSString *)tag;
- (void)addFilter:(NSString *)filter forDescription:(NSString *)description;
- (BOOL)performQuery;
- (BOOL)performRetrieveWithValue:(NSString *) forTag:(NSString *)tag;
- (BOOL)performRetrieveWithAttributeList:(id)attrList atLevel:(NSString*)description;
- (id)queryRoot;

@end
