//
//  RemoteDicomDatabase.h
//  OsiriX
//
//  Created by Alessandro Volz on 04.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase.h"


@interface RemoteDicomDatabase : DicomDatabase {
	NSString* _address;
}

@property(readonly,retain) NSString* address;

+(DicomDatabase*)databaseForAddress:(NSString*)path;
+(DicomDatabase*)databaseForAddress:(NSString*)path name:(NSString*)name;

-(id)initWithAddress:(NSString*)address;

@end
