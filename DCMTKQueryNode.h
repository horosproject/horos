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
#import "DCMTKServiceClassUser.h"

#undef verify

#include "osconfig.h" /* make sure OS specific configuration is included first */
#include "dcdatset.h"
#include "dimse.h"
#include "dccodec.h"
//#include "tlstrans.h"
//#include "tlslayer.h"
//#include "ofstring.h"



@class DCMCalendarDate;
/** \brief Base class for query nodes */
@interface DCMTKQueryNode : DCMTKServiceClassUser {
	NSMutableArray *_children;
	NSString *_uid;
	NSString *_theDescription;
	NSString *_name;
	NSString *_patientID;
	NSString *_referringPhysician;
	NSString *_accessionNumber;
	DCMCalendarDate *_date;
	DCMCalendarDate *_birthdate;
	DCMCalendarDate *_time;
	NSString *_modality;
	NSNumber *_numberImages;
	NSString *_specificCharacterSet;
	NSManagedObject *_logEntry;
	BOOL showErrorMessage;
}

+ (id)queryNodeWithDataset:(DcmDataset *)dataset
			callingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (id)initWithDataset:(DcmDataset *)dataset
			callingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (NSString *)uid;
- (NSString *)theDescription;
- (NSString *)name;
- (NSString *)patientID;
- (NSString *)accessionNumber;
- (NSString *)referringPhysician;
- (DCMCalendarDate *)date;
- (DCMCalendarDate *)time;
- (NSString *)modality;
- (NSNumber *)numberImages;
- (NSMutableArray *)children;
- (void)purgeChildren;
- (void)addChild:(DcmDataset *)dataset;
- (DcmDataset *)queryPrototype;
- (DcmDataset *)moveDataset;
// values are a NSDictionary the key for the value is @"value" key for the name is @"name"  name is the tag descriptor from the tag dictionary
- (void)queryWithValues:(NSArray *)values;
- (void) queryWithValues:(NSArray *)values dataset:(DcmDataset*) dataset;
- (void)move:(NSDictionary*) dict;
- (NSManagedObject *)logEntry;
- (void)setLogEntry:(NSManagedObject *)logEntry;
- (void)setShowErrorMessage:(BOOL) m;
//common network code for move and query
- (BOOL)setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset;
- (BOOL)setupNetworkWithSyntax:(const char *)abstractSyntax dataset:(DcmDataset *)dataset destination:(NSString*) destination;
- (OFCondition) addPresentationContext:(T_ASC_Parameters *)params abstractSyntax:(const char *)abstractSyntax;

- (OFCondition)findSCU:(T_ASC_Association *)assoc dataset:( DcmDataset *)dataset;
- (OFCondition) cfind:(T_ASC_Association *)assoc dataset:(DcmDataset *)dataset;

- (OFCondition) cmove:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset;
- (OFCondition) cmove:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset destination: (char*) destination;
- (OFCondition) moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset;
- (OFCondition) moveSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset destination: (char*) destination;

- (OFCondition) cget:(T_ASC_Association *)assoc network:(T_ASC_Network *)net dataset:(DcmDataset *)dataset;
- (OFCondition) getSCU:(T_ASC_Association *)assoc  network:(T_ASC_Network *)net dataset:( DcmDataset *)dataset;

- (void) move:(NSDictionary*) dict retrieveMode: (int) retrieveMode;
- (void) move:(NSDictionary*) dict;
@end
