//
//  ForkedInterface.m
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 01.03.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "ForkedInterface.h"
#import "DicomDatabase.h"
#import "N2Debug.h"
#import "NSData+N2.h"

@interface ChildForkedObject ()

@property(readonly) NSMutableDictionary* dictionary;

+(id)mutatedObject:(id)obj cfi:(ChildForkedInterface*)cfi;

@end

@interface ParentForkedInterface ()

@end

@implementation ParentForkedInterface

const NSUInteger RecurseUp = 1 << 0;
const NSUInteger RecurseDown = 1 << 1;

// transforms parent objects (NSSet, NSManagedObject, NSData, NSDate, NSNumber, NSString) to serializable
+(id)mutatedObject:(id)obj keys:(NSArray*)inkeys recurse:(NSUInteger)recurse context:(NSMutableArray*)alreadyDetailedObjectIDs {
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray* r = [NSMutableArray array];
        for (id o in obj) {
            id m = [self mutatedObject:o keys:nil recurse:(recurse&RecurseDown) context:alreadyDetailedObjectIDs];
            if (m) [r addObject:m];
        }
        return r;
    } else if ([obj isKindOfClass:[NSSet class]]) {
        NSMutableSet* r = [NSMutableSet set];
        for (id o in obj) {
            id m = [self mutatedObject:o keys:nil recurse:(recurse&RecurseDown) context:alreadyDetailedObjectIDs];
            if (m) [r addObject:m];
        }
        return r;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary* r = [NSMutableDictionary dictionary];
        for (NSString* k in obj) {
            id m = [self mutatedObject:[obj objectForKey:k] keys:nil recurse:(recurse&RecurseDown) context:alreadyDetailedObjectIDs];
            if (m) [r setObject:m forKey:k];
        }
        return r;
    } else if ([obj isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([obj isKindOfClass:[NSManagedObject class]]) {
        NSMutableDictionary* r = [NSMutableDictionary dictionary];
        
        NSString* oid = [obj valueForKeyPath:@"objectID.URIRepresentation.absoluteString"];
        [r setObject:oid forKey:@"_ForkedInterfaceObjectID"];
        NSString* type = [obj valueForKey:@"type"];
        [r setObject:type forKey:@"type"];
        
        NSMutableArray* keys = [NSMutableArray arrayWithArray:inkeys];
        if (recurse && ![alreadyDetailedObjectIDs containsObject:oid]) {
            [alreadyDetailedObjectIDs addObject:oid];
            
            for (NSString* key in [[[(NSManagedObject*)obj entity] relationshipsByName] allKeys])
                if (![keys containsObject:key] && ![key isEqualToString:@"albums"])
                    [keys addObject:key];
            
            if ([type isEqualToString:@"Study"]) {
                for (NSString* key in [NSArray arrayWithObjects: @"noFiles", @"rawNoFiles", @"dateOfBirth", @"name", @"studyName", @"accessionNumber", @"studyInstanceUID", @"patientID", @"modality", @"date", @"institutionName", @"id", @"referringPhysician", @"comment", NULL])
                    if (![keys containsObject:key])
                        [keys addObject:key];
           //     [keys addObjectsFromArray:[NSArray arrayWithObjects: @"noFiles", @"rawNoFiles", NULL]];
            }
            
            if ([type isEqualToString:@"Series"]) {
        //        [keys addObjectsFromArray:[NSArray arrayWithObjects: @"modality", @"name", @"noFiles", @"rawNoFiles", @"id", @"seriesDICOMUID", @"date", NULL]];
            }
            
            if ([type isEqualToString:@"Image"]) {
                for (NSString* key in [NSArray arrayWithObjects: @"pathsForForkedProcess", NULL])
                    if (![keys containsObject:key])
                        [keys addObject:key];
            }
        }
        
        for (NSString* key in keys)
            @try {
                id obj = [obj valueForKey:key];
                id m = [self mutatedObject:obj keys:nil recurse:([obj isKindOfClass:[NSManagedObject class]]? (recurse&RecurseUp) : (recurse&RecurseDown)) context:alreadyDetailedObjectIDs];
                if (m) [r setObject:m forKey:key];    
            } @catch (NSException* e) {
                // ijpij
            }
        
        return r;
    } else if ([obj isKindOfClass:[NSData class]]) {
        return nil;
    } else if (!obj) {
        return [NSNull null];
    }
    
    
    return obj;
}

/*-(id)mutatedObject:(id)obj {
    return [self mutatedObject:obj keys:nil];
}*/

-(NSArray*)dictionariesForObjects:(NSArray*)objects keys:(NSArray*)keys {
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:objects.count];
    
    NSMutableArray* context = [NSMutableArray array];
    for (NSManagedObject* obj in objects) {
        id m = [[self class] mutatedObject:obj keys:keys recurse:RecurseUp+RecurseDown context:context];
        [r addObject:m];
    }
    
    return r;
}

-(DicomDatabase*)idd {
    if (!_idd)
        _idd = [[[DicomDatabase defaultDatabase] independentDatabase] retain];
    return _idd;
}

-(NSDictionary*)dictionaryForDefaultDatabaseItemWithID:(NSString*)objectIdUriString keys:(NSArray*)keys {
//    NSLog(@"\n\nForked detail:\n%@ for %@\n\n", keys, objectIdUriString);
    NSManagedObject* obj = [self.idd objectWithID:objectIdUriString];
    NSDictionary* r = [[self class] mutatedObject:obj keys:keys recurse:RecurseDown context:[NSMutableArray array]];
//    NSLog(@"\n\n%@\n\n", r);
    return r;
}

-(NSArray*)dictionariesForDefaultDatabaseItemsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate keys:(NSArray*)keys {
//    NSLog(@"\n\nForked search:\n%@ %@\n\n", entityName, predicate);
    NSArray* iobjects = [self.idd objectsForEntity:entityName predicate:predicate];
    NSArray* r = [self dictionariesForObjects:iobjects keys:keys];
//    NSLog(@"\n\n%@\n\n", r);
    return r;
}

+(id)readObjectFromBuffer:(NSMutableData*)data {
    // is there enough data for a request length?
    if (data.length >= sizeof(NSUInteger)) { // yes
        NSUInteger reqlen; [data getBytes:&reqlen length:sizeof(NSUInteger)];
        // is the request data complete?
        if (data.length-sizeof(NSUInteger) >= reqlen) { // yes
            // obtain the serialized request data and clear the buffer
            NSData* reqdata = [data subdataWithRange:NSMakeRange(sizeof(NSUInteger), reqlen)];
            [data replaceBytesInRange:NSMakeRange(0, sizeof(NSUInteger)+reqlen) withBytes:NULL length:0];
            // deserialize the request
            return [NSKeyedUnarchiver unarchiveObjectWithData:reqdata];
        }
    }
    
    return nil;
}

+(NSData*)writeObjectAsData:(id)object {
    NSData* tempdata = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSUInteger templen = tempdata.length;
    NSMutableData* data = [NSMutableData data];
    [data appendBytes:&templen length:sizeof(NSUInteger)];
    [data appendData:tempdata];
    return data;
}

-(void)childProcessAssistantThread:(NSArray*)args {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        int childpid = [[args objectAtIndex:0] intValue];
        NSPipe* child2parent = [args objectAtIndex:1];
        NSPipe* parent2child = [args objectAtIndex:2];
        
        NSFileHandle* c2p = [child2parent fileHandleForReading];
        NSFileHandle* p2c = [parent2child fileHandleForWriting];
        
        NSMutableData* c2pbuf = [NSMutableData data];
        
        int rc, state;
        BOOL done = NO, waitNext = NO;
        do {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            @try {
                if (waitNext) [NSThread sleepForTimeInterval: 0.001];
                waitNext = YES;
                // read the child2parent pipe for requests from the child process
                NSData* temp = [c2p availableData];
                if (temp.length) {
                    waitNext = NO;
                    [c2pbuf appendData:temp];
                    NSDictionary* req = [[self class] readObjectFromBuffer:c2pbuf];
                    if (req) {
                        NSString* selectorString = [req objectForKey:@"selectorString"];
                        NSArray* arguments = [req objectForKey:@"arguments"];
                        
                        if ([selectorString isEqualToString:@"childIsDone"]) {
                            done = YES;
                            [p2c writeData:[[self class] writeObjectAsData:@"bye"]];
                        } else {
                            SEL sel = NSSelectorFromString(selectorString);
                            NSMethodSignature* methodSignature = [self methodSignatureForSelector:sel];
                            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
                            invocation.target = self;
                            invocation.selector = sel;
                            
                            for (int i = 0; i < arguments.count; ++i) {
                                id arg = [arguments objectAtIndex:i];
                                if ([arg isKindOfClass:[NSNull class]]) arg = nil;
                                [invocation setArgument:&arg atIndex:i+2];
                            }
                            
                            [invocation invoke];
                            
                            id result;
                            [invocation getReturnValue:&result];
                            
                            [p2c writeData:[[self class] writeObjectAsData:result]];
                        }
                    }
                }
            } @catch (NSException* e) {
                N2LogExceptionWithStackTrace(e);
            } @finally {
                [pool release];
            }
            
            // check if the process is still running
            rc = waitpid(childpid, &state, WNOHANG);
        } while (!done && rc >= 0); // process still running
        
        //NSLog(@"pipe watcher exiting");
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

-(void)dealloc {
    [_idd release];
    [super dealloc];
}

@end

@implementation ChildForkedInterface

-(id)initWithC2PPipe:(NSPipe*)c2ppipe P2CPipe:(NSPipe*)p2cpipe {
    if ((self = [super init])) {
        _c2ppipe = [c2ppipe retain];
        _p2cpipe = [p2cpipe retain];
        _c2p = [[_c2ppipe fileHandleForWriting] retain];
        _p2c = [[_p2cpipe fileHandleForReading] retain];
    }

    return self;
}

-(void)dealloc {
    [_c2p release];
    [_p2c release];
    [_c2ppipe release];
    [_p2cpipe release];
    [super dealloc];
}

-(id)forkedRequest:(NSDictionary*)request {
    // send the request
    NSData* data = [ParentForkedInterface writeObjectAsData:request];
    [_c2p writeData:data];
    // wait for a response
    id response = nil;
    NSMutableData* p2cbuf = [NSMutableData data];
    BOOL waitNext = NO;
    do {
        if (waitNext) [NSThread sleepForTimeInterval: 0.001];
        waitNext = YES;
        // read the parent2child pipe for responses from the parent process
        NSData* temp = [_p2c availableData];
        if (temp.length) {
            waitNext = NO;
            [p2cbuf appendData:temp];
            response = [ParentForkedInterface readObjectFromBuffer:p2cbuf];
        }
    } while (!response);
    
    return [ChildForkedObject mutatedObject:response cfi:self];
}

-(ChildForkedObject*)defaultDatabaseItemWithID:(NSString*)objectIdUriString keys:(NSArray*)keys {
    if (keys == nil) keys = [NSArray array];
    NSDictionary* request = [NSDictionary dictionaryWithObjectsAndKeys: 
                             @"dictionaryForDefaultDatabaseItemWithID:keys:", @"selectorString",
                             [NSArray arrayWithObjects: objectIdUriString, keys, nil], @"arguments",
                             nil];
    return [self forkedRequest:request];
}

-(NSArray*)defaultDatabaseItemsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate keys:(NSArray*)keys {
    if (keys == nil) keys = [NSArray array];
    NSDictionary* request = [NSDictionary dictionaryWithObjectsAndKeys: 
                             @"dictionariesForDefaultDatabaseItemsWithEntityName:predicate:keys:", @"selectorString",
                             [NSArray arrayWithObjects: entityName, predicate, keys, nil], @"arguments",
                             nil];
    NSArray* r = [self forkedRequest:request];
    NSLog(@"items: %@", r);
    return r;
}

-(void)informParentThatChildIsDone {
    NSDictionary* request = [NSDictionary dictionaryWithObjectsAndKeys: 
                             @"childIsDone", @"selectorString",
                             nil];
    [self forkedRequest:request]; // should return @"bye"
}

@end

@implementation ChildForkedObject

@synthesize dictionary = _dictionary;

-(id)initWithDictionary:(NSMutableDictionary*)dictionary cfi:(ChildForkedInterface*)cfi {
    if ((self = [super init])) {
        _dictionary = [dictionary retain];
        _cfi = [cfi retain];
    }
    
    return self;
}

+(id)mutatedObject:(id)obj cfi:(ChildForkedInterface*)cfi context:(NSMutableDictionary*)alreadyForkedObjects {
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray* r = [NSMutableArray array];
        for (id o in obj) {
            id m = [self mutatedObject:o cfi:cfi];
            if (m) [r addObject:m];
        }
        return r;
    } else if ([obj isKindOfClass:[NSSet class]]) {
        NSMutableSet* r = [NSMutableSet set];
        for (id o in obj) {
            id m = [self mutatedObject:o cfi:cfi];
            if (m) [r addObject:m];
        }
        return r;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary* r = [NSMutableDictionary dictionary];
        for (NSString* k in obj) {
            id m = [self mutatedObject:[obj objectForKey:k] cfi:cfi];
            if (m) [r setObject:m forKey:k];
        }
        
        NSString* objectID = [obj objectForKey:@"_ForkedInterfaceObjectID"];
        if (objectID) { // is actually an NSManagedObject
            // is it already visited?
            ChildForkedObject* cfo = [alreadyForkedObjects objectForKey:objectID];
            if (cfo) return cfo;
            cfo = [[[ChildForkedObject alloc] initWithDictionary:r cfi:cfi] autorelease];
            [alreadyForkedObjects setObject:cfo forKey:objectID];
            return cfo;
        }
        
        return r;
    }
    
    return obj;
}

+(id)mutatedObject:(id)obj cfi:(ChildForkedInterface*)cfi {
    return [self mutatedObject:obj cfi:cfi context:[NSMutableDictionary dictionary]];
}

-(void)dealloc {
    [_dictionary release];
    [_cfi release];
    [super dealloc];
}

-(id)valueForKey:(NSString*)key {
    id value = [_dictionary valueForKey:key];
    if (value) {
        if ([value isKindOfClass:[NSNull class]])
            return nil;
        return value;
    }
    
    NSLog(@"\n\nGetting detail: %@ for %@ with %@\n\n", key, self, [[_dictionary allKeys] componentsJoinedByString:@", "]);
    
    ChildForkedObject* cfo = [_cfi defaultDatabaseItemWithID:[_dictionary valueForKey:@"_ForkedInterfaceObjectID"] keys:[NSArray arrayWithObject:key]];
    [_dictionary addEntriesFromDictionary:cfo.dictionary];
    
    return [_dictionary valueForKey:key];
}

-(NSString*)description {
    NSMutableString* ms = [NSMutableString string];
    [ms appendFormat:@"[Forked %@ with ID %@ with keys: %@] {", [self valueForKey:@"type"], [self valueForKey:@"_ForkedInterfaceObjectID"], [[_dictionary allKeys] componentsJoinedByString:@", "]];
    if ([[self valueForKey:@"type"] isEqualToString:@"Study"])
        if ([[_dictionary allKeys] containsObject:@"series"])
            for (id obj in [self valueForKey:@"series"])
                [ms appendFormat:@" %@", obj];
    if ([[self valueForKey:@"type"] isEqualToString:@"Series"])
        if ([[_dictionary allKeys] containsObject:@"images"])
            for (id obj in [self valueForKey:@"images"])
                [ms appendFormat:@" %@", obj];
    [ms appendFormat:@" }"];
    return ms;
}

@end

