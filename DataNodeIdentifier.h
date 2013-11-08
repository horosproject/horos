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