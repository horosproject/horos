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

#import "DataNodeIdentifier.h"
#import "PrettyCell.h"
#import "RemoteDicomDatabase.h"
#import "NSImage+N2.h"
#import "NSHost+N2.h"
#import <stdlib.h>

@implementation DataNodeIdentifier

@synthesize location = _location;
@synthesize description = _description;
@synthesize dictionary = _dictionary;
@synthesize detected = _detected;
@synthesize entered = _entered;

-(id)initWithLocation:(NSString*)location description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    if ((self = [self init])) {
        self.location = location;
        self.description = description;
        self.dictionary = dictionary;
    }
    
    return self;
}

-(void)dealloc {
	self.location = nil;
	self.description = nil;
	self.dictionary = nil;
	[super dealloc];
}

-(BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[DataNodeIdentifier class]])
        return [self isEqualToDataNodeIdentifier:object];
    return NO;
}

-(BOOL)isEqualToDataNodeIdentifier:(DataNodeIdentifier*)dni {
	if (self.dictionary && self.dictionary == dni.dictionary)
		return YES;
	return [self.location isEqualToString:dni.location];
}

+(CGFloat)sortValueForDataNodeIdentifier:(DataNodeIdentifier*)dni {
    if ([dni isKindOfClass:[LocalDatabaseNodeIdentifier class]])
        return 10;
    if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
        return 20;
    if ([dni isKindOfClass:[DicomNodeIdentifier class]])
        return 30;
    return 100;
}

-(CGFloat)sortValue {
    return [[self class] sortValueForDataNodeIdentifier:self];
}

-(NSComparisonResult)compare:(DataNodeIdentifier*)dni {
	NSInteger selfSortValue = [self sortValue], dniSortValue = [dni sortValue];
    if (selfSortValue != dniSortValue)
        return selfSortValue > dniSortValue;
    return [self.description caseInsensitiveCompare:dni.description];
}

-(DicomDatabase*)database { // for subclassers
	return nil;
}

-(NSString*)toolTip {
	return self.location;
}

-(BOOL)isReadOnly {
	return NO;
}

-(BOOL)available {
    return self.detected;
}

+(NSSet*)keyPathsForValuesAffectingAvailable {
    return [NSSet setWithObject:@"detected"];
}

+(NSSet*)keyPathsForValuesAffectingDescription {
    return [NSSet setWithObject:@"available"]; // this causes 
}

-(void)willDisplayCell:(PrettyCell*)cell {    
    static NSColor* gray = nil;
    if (!gray) gray = [[NSColor colorWithDeviceWhite:0.4 alpha:1] retain];
    
    if (!self.available) {
        cell.textColor = gray;
    }
    
    if( [_dictionary valueForKey: @"icon"] && [NSImage imageNamed:[_dictionary valueForKey:@"icon"]])
        cell.image = [NSImage imageNamed:[_dictionary valueForKey:@"icon"]];
}

@end

@implementation LocalDatabaseNodeIdentifier

+(id)localDatabaseNodeIdentifierWithPath:(NSString*)path {
    return [[self class] localDatabaseNodeIdentifierWithPath:path description:nil dictionary:nil];
}

+(id)localDatabaseNodeIdentifierWithPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    return [[[[self class] alloc] initWithLocation:path description:description dictionary:dictionary] autorelease];
}

-(BOOL)isEqualToDataNodeIdentifier:(DataNodeIdentifier*)dni {
    if (![dni isKindOfClass:[LocalDatabaseNodeIdentifier class]])
        return NO;
    if ([[DicomDatabase baseDirPathForPath:self.location] isEqualToString:[DicomDatabase baseDirPathForPath:dni.location]])
        return YES;
    return [super isEqualToDataNodeIdentifier:dni];
}

-(BOOL)available {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.location];
}

-(void)willDisplayCell:(PrettyCell*)cell {    
    [super willDisplayCell:cell];

    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.location isDirectory:&isDir]) {
        cell.image = [NSImage imageNamed:@"away.tif"];
        return;
    }
    
    if (!isDir) {
        cell.image = [NSImage imageNamed:@"FileIcon.tif"];
        return;
    }
    
    NSString* path = self.location;
    BOOL atMediaRoot = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:path];
    if (!atMediaRoot)
        path = [path stringByDeletingLastPathComponent];
    
    NSImage* im = [[NSWorkspace sharedWorkspace] iconForFile:self.location];
    im.size = [im sizeByScalingProportionallyToSize:NSMakeSize(16,16)];
    cell.image = im;
}

@end

@implementation RemoteDataNodeIdentifier

+(NSString*)location:(NSString*)location toAddress:(NSString**)address port:(NSInteger*)port defaultPort:(NSInteger)defaultPort {
	NSArray* parts = [location componentsSeparatedByString:@":"];
	
    NSString* localAddress = nil;
    if (!address) address = &localAddress;
    
    if (address && parts.count > 0) *address = [parts objectAtIndex:0];
    
	if (port)
        if (parts.count > 1)
			*port = [[parts objectAtIndex:1] integerValue];
		else *port = defaultPort;
    
	return *address;
}

-(void)willDisplayCell:(PrettyCell*)cell {    
    [super willDisplayCell:cell];
    cell.image = [NSImage imageNamed:@"FixedIP.tif"];
}

@end

@implementation RemoteDatabaseNodeIdentifier

+(id)remoteDatabaseNodeIdentifierWithLocation:(NSString*)location description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    return [[[[self class] alloc] initWithLocation:location description:description dictionary:dictionary] autorelease];
}

-(BOOL)isEqualToDataNodeIdentifier:(RemoteDatabaseNodeIdentifier*)dni {
    if (![dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
        return NO;
    
    NSHost* selfHost; NSInteger selfPort;
    [[self class] location:self.location toHost:&selfHost port:&selfPort];
    NSHost* dniHost; NSInteger dniPort;
    [[self class] location:dni.location toHost:&dniHost port:&dniPort];
    
    if (selfPort == dniPort && [selfHost isEqualToHost:dniHost])
        return YES;
    
    return NO;
}

+(NSString*)location:(NSString*)location toAddress:(NSString**)address port:(NSInteger*)port {
    return [[self class] location:location toAddress:address port:port defaultPort:8780];
}

+(NSHost*)location:(NSString*)location toHost:(NSHost**)host port:(NSInteger*)port {
    NSString* address = [self location:location toAddress:NULL port:port]; 
	
    NSHost* localHost = nil;
    if (!host) host = &localHost;
    
    if (address) *host = [NSHost hostWithAddressOrName:address];

	return *host;
}

+(NSString*)locationWithHost:(NSHost*)host port:(NSInteger)port {
	return [[self class] locationWithAddress:host.address port:port];
}

+(NSString*)locationWithAddress:(NSString*)address port:(NSInteger)port {
	return [NSString stringWithFormat:@"%@:%d", address, port];
}

@end

@implementation DicomNodeIdentifier

+(id)dicomNodeIdentifierWithLocation:(NSString*)location description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    return [[[[self class] alloc] initWithLocation:location description:description dictionary:dictionary] autorelease];
}

-(void)willDisplayCell:(PrettyCell*)cell {
    [super willDisplayCell:cell];
    cell.image = [NSImage imageNamed:@"DICOMDestination.tif"];
}

-(BOOL)isEqualToDataNodeIdentifier:(DicomNodeIdentifier*)dni {
    if (![dni isKindOfClass:[DicomNodeIdentifier class]])
        return NO;
    
    NSHost* selfHost; NSInteger selfPort; NSString* selfAet;
    [[self class] location:self.location toHost:&selfHost port:&selfPort aet:&selfAet];
    NSHost* dniHost; NSInteger dniPort; NSString* dniAet;
    [[self class] location:dni.location toHost:&dniHost port:&dniPort aet:&dniAet];
    
    if (selfPort == dniPort && [selfHost isEqualToHost:dniHost] && [selfAet isEqualToString:dniAet])
        return YES;
    
    return NO;
}

+(NSString*)location:(NSString*)location toAddress:(NSString**)address port:(NSInteger*)port aet:(NSString**)aet {
	NSArray* parts = [location componentsSeparatedByString:@"@"];
    
    if (aet && parts.count > 0) *aet = [parts objectAtIndex:0];
    
    if (parts.count > 1)
        return [[self class] location:[[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@"@"] toAddress:address port:port defaultPort:11112];
    
    return nil;
}


+(NSHost*)location:(NSString*)location toHost:(NSHost**)host port:(NSInteger*)port aet:(NSString**)aet {
    NSString* address = [self location:location toAddress:NULL port:port aet:aet]; 
	
    NSHost* localHost = nil;
    if (!host) host = &localHost;
    
    if (address) *host = [NSHost hostWithAddressOrName:address];
    
	return *host;
}

+(NSString*)locationWithHost:(NSHost*)host port:(NSInteger)port aet:(NSString*)aet {
	return [[self class] locationWithAddress:host.address port:port aet:aet];
}

+(NSString*)locationWithAddress:(NSString*)host port:(NSInteger)port aet:(NSString*)aet {
	return [NSString stringWithFormat:@"%@@%@:%d", aet, host, port];
}

@end
