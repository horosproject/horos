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


@class DicomDatabase, PrettyCell;

/*enum {
	DataNodeIdentifierTypeDefault,
	DataNodeIdentifierTypeLocal,
	DataNodeIdentifierTypeRemote,
	DataNodeIdentifierTypeDicom,
	DataNodeIdentifierTypeOther
};
typedef NSInteger DataNodeIdentifierType;*/


@interface DataNodeIdentifier : NSObject {
//	DataNodeIdentifierType _type;
	NSString* _location;
    NSString* _aetitle;
    NSUInteger _port;
	NSString* _description;
	NSDictionary* _dictionary;
    BOOL _detected; // i.e. if this node was detected through bonjour, or mounted
    BOOL _entered; // if this node is listed in the user defaults, entered by the user
}

//+(id)dataNodeIdentifierForLocation:(NSString*)location description:(NSString*)description dictionary:(NSDictionary*)dictionary;

//@property(readonly) DataNodeIdentifierType type;
@property(retain) NSString* location;
@property(retain) NSString* aetitle;
@property NSUInteger port;
@property(retain) NSString* description;
@property(retain) NSDictionary* dictionary;
@property BOOL detected;
@property BOOL entered;

-(id)initWithLocation:(NSString*)location port:(NSUInteger) port aetitle:(NSString*) aetitle description:(NSString*)description dictionary:(NSDictionary*)dictionary;

-(BOOL)isEqualToDataNodeIdentifier:(DataNodeIdentifier*)dni;
-(BOOL)isEqualToDictionary:(NSDictionary*)d;
-(NSComparisonResult)compare:(DataNodeIdentifier*)other;

-(DicomDatabase*)database;

-(BOOL)isReadOnly;
-(NSString*)toolTip;

-(void)willDisplayCell:(PrettyCell*)cell;

@end

@interface LocalDatabaseNodeIdentifier : DataNodeIdentifier

+(id)localDatabaseNodeIdentifierWithPath:(NSString*)path;
+(id)localDatabaseNodeIdentifierWithPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary;
    
@end

@interface RemoteDataNodeIdentifier : DataNodeIdentifier

@end

@interface RemoteDatabaseNodeIdentifier : RemoteDataNodeIdentifier

+(id)remoteDatabaseNodeIdentifierWithLocation:(NSString*)location port:(NSUInteger)port description:(NSString*)description dictionary:(NSDictionary*)dictionary;

+(NSHost*)location:(NSString*)location port:(NSUInteger)port toHost:(NSHost**)host port:(NSInteger*)port;
+(NSString*)location:(NSString*)location port:(NSUInteger) port toAddress:(NSString**)address port:(NSInteger*)outputPort;

@end

@interface DicomNodeIdentifier : RemoteDataNodeIdentifier

+(id)dicomNodeIdentifierWithLocation:(NSString*)location port:(NSUInteger)port aetitle:(NSString*)aetitle description:(NSString*)description dictionary:(NSDictionary*)dictionary;

+(NSString*)location:(NSString*)location port:(NSUInteger)port toAddress:(NSString**)address port:(NSInteger*)port aet:(NSString**)aet;

@end
