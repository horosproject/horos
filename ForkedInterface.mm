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

-(id)mutatedObject:(id)obj;

@end

@implementation ParentForkedInterface

// transforms parent objects (NSSet, NSManagedObject, NSData, NSDate, NSNumber, NSString) to serializable
-(id)mutatedObject:(id)obj keys:(NSArray*)inkeys detailed:(BOOL)detailed {
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray* r = [NSMutableArray array];
        for (id o in obj) {
            id m = [self mutatedObject:o];
            if (m) [r addObject:m];
        }
        return r;
    } else if ([obj isKindOfClass:[NSSet class]]) {
        NSMutableSet* r = [NSMutableSet set];
        for (id o in obj) {
            id m = [self mutatedObject:o];
            if (m) [r addObject:m];
        }
        return r;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary* r = [NSMutableDictionary dictionary];
        for (NSString* k in obj) {
            id m = [self mutatedObject:[obj objectForKey:k]];
            if (m) [r setObject:m forKey:k];
        }
        return r;
    } else if ([obj isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([obj isKindOfClass:[NSManagedObject class]]) {
        NSMutableDictionary* r = [NSMutableDictionary dictionary];
        
        [r setObject:[obj valueForKeyPath:@"objectID.URIRepresentation.absoluteString"] forKey:@"ForkedInterfaceObjectID"];
        [r setObject:[obj valueForKey:@"type"] forKey:@"type"];
        
        NSMutableArray* keys = [NSMutableArray arrayWithArray:inkeys];
        if (detailed) {
            for (NSString* key in [obj valueForKeyPath:@"entity.attributeKeys"])
                if (![keys containsObject:key])
                    [keys addObject:key];
        }

        for (NSString* key in keys)
            [r setObject:[self mutatedObject:[obj valueForKey:key] keys:nil detailed:YES] forKey:key];
        
        return r;
    } else if (!obj)
        return [NSNull null];
        
    
    return obj;
}

-(id)mutatedObject:(id)obj {
    return [self mutatedObject:obj keys:nil detailed:NO];
}

-(NSArray*)dictionariesForObjects:(NSArray*)objects keys:(NSArray*)keys {
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:objects.count];
    
    for (NSManagedObject* obj in objects)
        [r addObject:[self mutatedObject:obj keys:keys detailed:YES]];
    
    return r;
}

-(NSDictionary*)dictionaryForDefaultDatabaseItemWithID:(NSString*)objectIdUriString keys:(NSArray*)keys {
    DicomDatabase* idd = [[DicomDatabase defaultDatabase] independentDatabase];
    NSManagedObject* obj = [idd objectWithID:objectIdUriString];
    return [self mutatedObject:obj keys:keys detailed:YES];
}

-(NSArray*)dictionariesForDefaultDatabaseItemsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate keys:(NSArray*)keys {
    DicomDatabase* idd = [[DicomDatabase defaultDatabase] independentDatabase];
    
    NSArray* iobjects = [idd objectsForEntity:entityName predicate:predicate];
    
    return [self dictionariesForObjects:iobjects keys:keys];
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
        BOOL done = NO;
        do {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            @try {
                [NSThread sleepForTimeInterval: 0.001];
                // read the child2parent pipe for requests from the child process
                NSData* temp = [c2p availableData];
                if (temp.length) {
                    [c2pbuf appendData:temp];
                    NSDictionary* req = [[self class] readObjectFromBuffer:c2pbuf];
                    if (req) {
                        NSString* selectorString = [req objectForKey:@"selectorString"];
                        NSArray* arguments = [req objectForKey:@"arguments"];
                        
                        if ([selectorString isEqualToString:@"done"]) {
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
    do {
        [NSThread sleepForTimeInterval: 0.001];
        // read the parent2child pipe for responses from the parent process
        NSData* temp = [_p2c availableData];
        if (temp.length) {
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
    return [self forkedRequest:request];
}

-(void)sendDone {
    NSDictionary* request = [NSDictionary dictionaryWithObjectsAndKeys: 
                             @"done", @"selectorString",
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

+(id)mutatedObject:(id)obj cfi:(ChildForkedInterface*)cfi {
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
        if ([obj objectForKey:@"ForkedInterfaceObjectID"]) // NSManagedObject
            return [[[ChildForkedObject alloc] initWithDictionary:r cfi:cfi] autorelease];
        return r;
    } else if ([obj isKindOfClass:[NSNull class]])
        return nil;
    
    return obj;
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
    
    ChildForkedObject* cfo = [_cfi defaultDatabaseItemWithID:[_dictionary valueForKey:@"ForkedInterfaceObjectID"] keys:[NSArray arrayWithObject:key]];
    [_dictionary addEntriesFromDictionary:cfo.dictionary];
    
    return [_dictionary valueForKey:key];
}

@end

