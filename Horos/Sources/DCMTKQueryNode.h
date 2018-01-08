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
#import "DCMTKServiceClassUser.h"

@class DCMCalendarDate;
/** \brief Base class for query nodes */
@interface DCMTKQueryNode : DCMTKServiceClassUser
{
	NSMutableArray *_children;
	NSString *_uid;
	NSString *_theDescription;
	NSString *_name;
	NSString *_patientID;
	NSString *_referringPhysician;
    NSString *_performingPhysician;
	NSString *_institutionName;
	NSString *_comments;
    NSString *_interpretationStatusID;
	NSString *_accessionNumber;
	DCMCalendarDate *_date;
	DCMCalendarDate *_birthdate;
	DCMCalendarDate *_time;
	NSString *_modality;
	NSNumber *_numberImages;
	NSString *_specificCharacterSet;
	NSManagedObject *_logEntry;
	BOOL showErrorMessage, firstWadoErrorDisplayed, _dontCatchExceptions, _isAutoRetrieve, _noSmartMode;
	OFCondition globalCondition;
    NSUInteger _countOfSuboperations, _countOfSuccessfulSuboperations;
}

@property BOOL dontCatchExceptions;
@property BOOL isAutoRetrieve;
@property BOOL noSmartMode;
@property NSUInteger countOfSuboperations, countOfSuccessfulSuboperations;

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
- (BOOL) isDistant;
- (NSString *)theDescription;
- (NSString *)name;
- (NSString *)patientID;
- (NSString *)accessionNumber;
- (NSString *)referringPhysician;
- (NSString *)performingPhysician;
- (NSString *)institutionName;
- (DCMCalendarDate *)date;
- (DCMCalendarDate *)time;
- (NSString *)modality;
- (NSNumber *)numberImages;
- (NSArray *)children;
- (void) setChildren: (NSArray *) c;
- (void)purgeChildren;
- (void)addChild:(DcmDataset *)dataset;
- (DcmDataset *)queryPrototype;
- (DcmDataset *)moveDataset;
// values are a NSDictionary the key for the value is @"value" key for the name is @"name"  name is the tag descriptor from the tag dictionary
- (void)queryWithValues:(NSArray *)values;
- (void) queryWithValues:(NSArray *)values dataset:(DcmDataset*) dataset;
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

+ (dispatch_semaphore_t)semaphoreForServerHostAndPort:(NSString*)key;

@end
