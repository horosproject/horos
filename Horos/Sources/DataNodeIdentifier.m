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

#import "DataNodeIdentifier.h"
#import "PrettyCell.h"
#import "RemoteDicomDatabase.h"
#import "NSImage+N2.h"
#import "NSHost+N2.h"
#import <stdlib.h>
#import "N2Debug.h"

@implementation DataNodeIdentifier

@synthesize location = _location;
@synthesize port = _port;
@synthesize description = _description;
@synthesize dictionary = _dictionary;
@synthesize detected = _detected;
@synthesize entered = _entered;
@synthesize aetitle = _aetitle;

-(id)initWithLocation:(NSString*)location port:(NSUInteger) port aetitle:(NSString*) aetitle description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    if ((self = [self init])) {
        self.location = location;
        self.port = port;
        self.aetitle = aetitle;
        self.description = description;
        self.dictionary = dictionary;
    }
    
    return self;
}

-(void)dealloc {
	self.location = nil;
    self.aetitle = nil;
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

-(BOOL)isEqualToDictionary:(NSDictionary*)d {
    return [self.dictionary isEqual:d];
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
    NSString *tip = self.location;
    
    if( self.port > 0)
        tip = [tip stringByAppendingFormat: @" - %d", (int) self.port];
    
    if( self.aetitle.length)
        tip = [tip stringByAppendingFormat: @" - %@", self.aetitle];
    
	return tip;
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
    /*static NSColor* gray = nil;
    if (!gray) gray = [[NSColor colorWithDeviceWhite:0.4 alpha:1] retain];
    
    if (!self.available) { // TODO: this should only be enabled once we periodically verify every node's availability through DICOM ECHO or dummy TCP connections.. but is it worth it? won't that overload the network/servers for too little gain?
        cell.textColor = gray;
    }*/
    
    if( [_dictionary valueForKey: @"icon"] && [NSImage imageNamed:[_dictionary valueForKey:@"icon"]])
        cell.image = [NSImage imageNamed:[_dictionary valueForKey:@"icon"]];
}

@end

@implementation LocalDatabaseNodeIdentifier

+(id)localDatabaseNodeIdentifierWithPath:(NSString*)path {
    return [[self class] localDatabaseNodeIdentifierWithPath:path description:nil dictionary:nil];
}

+(id)localDatabaseNodeIdentifierWithPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    return [[[[self class] alloc] initWithLocation:path port:0 aetitle:@"" description:description dictionary:dictionary] autorelease];
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
    
    if( [_dictionary valueForKey: @"icon"] && [NSImage imageNamed:[_dictionary valueForKey:@"icon"]])
    {
        cell.image = [NSImage imageNamed:[_dictionary valueForKey:@"icon"]];
        return;
    }
    
//    NSString* path = self.location;
//    BOOL atMediaRoot = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:path];
//    if (!atMediaRoot)
//        path = [path stringByDeletingLastPathComponent];
    
    NSImage* im = [[NSWorkspace sharedWorkspace] iconForFile:self.location];
    im.size = [im sizeByScalingProportionallyToSize:NSMakeSize(16,16)];
    cell.image = im;
}

@end

@implementation RemoteDataNodeIdentifier

+(NSString*)location:(NSString*)location port:(NSUInteger)port toAddress:(NSString**)address port:(NSInteger*)outputPort defaultPort:(NSInteger)defaultPort
{
    NSString* localAddress = nil;
    if( !address) address = &localAddress;
    
    if( location == nil) {
        N2LogStackTrace( @"---- warning: location == nil");
        location = @"0.0.0.0";
    }
    
    if( address)
        *address = [NSString stringWithString: location];
    
	if( outputPort)
    {
        if( port) //IPv4 with port
			*outputPort = port;
        
		else
            *outputPort = defaultPort;
    }
    
	return *address;
}

-(void)willDisplayCell:(PrettyCell*)cell {    
    [super willDisplayCell:cell];
    
    if( [_dictionary valueForKey: @"icon"] && [NSImage imageNamed:[_dictionary valueForKey:@"icon"]])
    {
        cell.image = [NSImage imageNamed:[_dictionary valueForKey:@"icon"]];
        return;
    }
    
    cell.image = [NSImage imageNamed:@"Network.tif"];
}

@end

@implementation RemoteDatabaseNodeIdentifier

+(id)remoteDatabaseNodeIdentifierWithLocation:(NSString*)location port:(NSUInteger)port description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    return [[[[self class] alloc] initWithLocation:location port:port aetitle:@"" description:description dictionary:dictionary] autorelease];
}

-(BOOL)isEqualToDataNodeIdentifier:(RemoteDatabaseNodeIdentifier*)dni {
    if (![dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
        return NO;
    
    NSHost* selfHost = nil; NSInteger selfPort;
    [[self class] location:self.location port:self.port toHost:&selfHost port:&selfPort];
    
    NSHost* dniHost = nil; NSInteger dniPort;
    [[self class] location:dni.location port:self.port toHost:&dniHost port:&dniPort];
    
    if ( selfHost && dniHost && selfPort == dniPort && [[selfHost address] isEqualToString: [dniHost address]])
        return YES;
    
    return NO;
}

+(NSString*)location:(NSString*)location port:(NSUInteger) port toAddress:(NSString**)address port:(NSInteger*)outputPort {
    return [[self class] location:location port:port toAddress:address port:outputPort defaultPort:8780];
}

+(NSHost*)location:(NSString*)location port:(NSUInteger) port toHost:(NSHost**)host port:(NSInteger*)outputPort {
    NSString* address = [self location:location port:port toAddress:NULL port:outputPort];
	
    NSHost* localHost = nil;
    if (!host) host = &localHost;
    
    if (address) *host = [NSHost hostWithAddressOrName:address];

	return *host;
}

//+(NSString*)locationWithHost:(NSHost*)host port:(NSInteger)port {
//	return [[self class] locationWithAddress:host.address port:port];
//}
//
//+(NSString*)locationWithAddress:(NSString*)address port:(NSInteger)port {
//	return [NSString stringWithFormat:@"%@:%d", address, (int) port];
//}

@end

@implementation DicomNodeIdentifier

+(id)dicomNodeIdentifierWithLocation:(NSString*)location port:(NSUInteger)port aetitle:(NSString*)aetitle description:(NSString*)description dictionary:(NSDictionary*)dictionary {
    return [[[[self class] alloc] initWithLocation:location port:port aetitle:aetitle description:description dictionary:dictionary] autorelease];
}

-(void)willDisplayCell:(PrettyCell*)cell {
    [super willDisplayCell:cell];
    
    if( [_dictionary valueForKey: @"icon"] && [NSImage imageNamed:[_dictionary valueForKey:@"icon"]])
    {
        cell.image = [NSImage imageNamed:[_dictionary valueForKey:@"icon"]];
        return;
    }
    
    cell.image = [NSImage imageNamed:@"DICOMDestination.tif"];
}

-(BOOL)isEqualToDataNodeIdentifier:(DicomNodeIdentifier*)dni {
    if (![dni isKindOfClass:[DicomNodeIdentifier class]])
        return NO;
    
    NSHost* selfHost; NSInteger selfPort; NSString* selfAet;
    [[self class] location:self.location port:self.port toHost:&selfHost port:&selfPort aet:&selfAet];
    
    NSHost* dniHost; NSInteger dniPort; NSString* dniAet;
    [[self class] location:dni.location port:self.port toHost:&dniHost port:&dniPort aet:&dniAet];
    
    if (selfPort == dniPort && [selfAet isEqualToString:dniAet] && [[selfHost address] isEqualToString: [dniHost address]])
        return YES;
    
    return NO;
}

-(BOOL)isEqualToDictionary:(NSDictionary*)d {
    if ([super isEqualToDictionary:d])
        return YES;
    
    return [self.location isEqualToString: [d objectForKey:@"Address"]] && self.port == [[d objectForKey:@"Port"] intValue] && [self.aetitle isEqualToString: [d objectForKey:@"AETitle"]];
}

+(NSString*)location:(NSString*)location port:(NSUInteger)port toAddress:(NSString**)address port:(NSInteger*)outputPort aet:(NSString**)aet {
	NSArray* parts = [location componentsSeparatedByString:@"@"];
    
    if (aet && parts.count > 0) *aet = [parts objectAtIndex:0];
    
    if (parts.count > 1)
        return [[self class] location:[[parts subarrayWithRange:NSMakeRange(1,(long)parts.count-1)] componentsJoinedByString:@"@"] port:port toAddress:address port:outputPort defaultPort:11112];
    
    return nil;
}


+(NSHost*)location:(NSString*)location port:(NSUInteger)port toHost:(NSHost**)host port:(NSInteger*)outputPort aet:(NSString**)aet {
    NSString* address = [self location:location port:port toAddress:NULL port:outputPort aet:aet];
	
    NSHost* localHost = nil;
    if (!host) host = &localHost;
    
    if (address) *host = [NSHost hostWithAddressOrName:address];
    
	return *host;
}

//+(NSString*)locationWithHost:(NSHost*)host port:(NSInteger)port aet:(NSString*)aet {
//	return [[self class] locationWithAddress:host.address port:port aet:aet];
//}
//
//+(NSString*)locationWithAddress:(NSString*)host port:(NSInteger)port aet:(NSString*)aet {
//	return [NSString stringWithFormat:@"%@@%@:%d", aet, host, (int) port];
//}

@end
