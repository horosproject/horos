//
//  DicomDatabase+Scan.mm
//  OsiriX
//
//  Created by Alessandro Volz on 25.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase+Scan.h"
#import "NSThread+N2.h"
#import "dcdicdir.h"
#import "NSString+N2.h"

@interface _DicomDatabaseScanDcmElement : NSObject {
	DcmElement* _element;
}

+(id)elementWithElement:(DcmElement*)element;
-(id)initWithElement:(DcmElement*)element;
-(DcmElement*)element;
-(NSString*)stringValue;

@end


@implementation DicomDatabase (Scan)

/*-(NSString*)describeObject:(DcmObject*)obj {
	const DcmTagKey& key = obj->getTag();
	DcmTag dcmtag(key);
	DcmVR dcmev(obj->ident());
	
	return [NSString stringWithFormat:@"%s %s %s %s", dcmev.getVRName(), key.toString().c_str(), dcmtag.getTagName(), dcmtag.getVRName()];
}

-(NSArray*)describeElementValues:(DcmElement*)obj {
	NSMutableArray* v = [NSMutableArray array];
	
	unsigned int vm = obj->getVM();
	if (vm)
		for (int i = 0; i < vm; ++i) {
			OFString value;
			if (((DcmByteString*)obj)->getOFString(value,i).good())
				[v addObject:[NSString stringWithFormat:@"[%d] %s", i, value.c_str()]];
		}
	
	return v;
}*/

-(_DicomDatabaseScanDcmElement*)_dcmElementForKey:(NSString*)key inContext:(NSArray*)context {
	for (NSInteger i = context.count-1; i >= 0; --i) {
		NSDictionary* elements = [context objectAtIndex:i];
		_DicomDatabaseScanDcmElement* ddsde = [elements objectForKey:key];
		if (ddsde) return ddsde;
	}
	
	return nil;
}

static NSString* _dcmElementKey(Uint16 group, Uint16 element) {
	return [NSString stringWithFormat:@"%04X,%04X", group, element];
}

static NSString* _dcmElementKey(DcmElement* element) {
	const DcmTagKey& key = element->getTag();
	return _dcmElementKey(key.getGroup(), key.getElement());
}

-(void)addItemsInRecord:(DcmDirectoryRecord*)record context:(NSMutableArray*)context {
	NSString* tabs = [NSString stringByRepeatingString:@" " times:context.count*4];
	
	NSMutableDictionary* elements = [NSMutableDictionary dictionary];
	[context addObject:elements];
	
	//NSLog(@"%@Record %@", tabs, [self describeObject:record]);
	
	for (unsigned int i = 0; i < record->card(); ++i) {
		DcmElement* element = record->getElement(i);
		
		//NSLog(@"%@Element %@", tabs, [self describeObject:element]);
		//NSArray* values = [self describeElementValues:element];
		//for (NSString* s in values)
		//	NSLog(@"%@%@", tabs, s);
		
		[elements setObject:[_DicomDatabaseScanDcmElement elementWithElement:element] forKey:_dcmElementKey(element)];
	}
	
	_DicomDatabaseScanDcmElement* elementReferencedFileID = [self _dcmElementForKey:_dcmElementKey(0x0004,0x1500) inContext:context];
	if (elementReferencedFileID) {
		NSLog(@"Image %@ %@ %@ %@",
			  [[self _dcmElementForKey:_dcmElementKey(0x0020,0x000d) inContext:context] stringValue] /* StudyInstanceUID */,
			  [[self _dcmElementForKey:_dcmElementKey(0x0020,0x000e) inContext:context] stringValue] /* SeriesInstanceUID */,
			  [[self _dcmElementForKey:_dcmElementKey(0x0008,0x0018) inContext:context] stringValue] /* SOPInstanceUID */,
			  [elementReferencedFileID stringValue]);
		
		[self addFilesAtPaths:paths];
		
	}
	
	
	for (unsigned long i = 0; i < record->cardSub(); ++i)
		[self addItemsInRecord:record->getSub(i) context:context];
	
	[context removeLastObject];
}

-(void)addItemsInRecord:(DcmDirectoryRecord*)record {
	[self addItemsInRecord:record context:[NSMutableArray array]];
}

-(void)scanDicomdirAt:(NSString*)path {
	DcmDicomDir dcmdir([path fileSystemRepresentation]);
	DcmDirectoryRecord& record = dcmdir.getRootRecord();
	[self addItemsInRecord:&record];
}

-(void)scanAtPath:(NSString*)path {
	NSThread* thread = [NSThread currentThread];
	[thread enterOperation];
	
	BOOL isDir;
	NSFileManager* fm = NSFileManager.defaultManager;
	
	// first read the DICOMDIR file
	NSString* dicomdirPath = [path stringByAppendingPathComponent:@"DICOMDIR"];
	if ([fm fileExistsAtPath:dicomdirPath isDirectory:&isDir] && !isDir) // it is available
		[self scanDicomdirAt:dicomdirPath];
		
	
	
	
	
	NSMutableArray* paths = [NSMutableArray array];
	
	for (int i = 0; i < 200; ++i) {
		thread.status = [NSString stringWithFormat:@"Iteration %d.", i];
		[NSThread sleepForTimeInterval:0.1];
	}
	
	[thread exitOperation];
}

@end


@implementation _DicomDatabaseScanDcmElement

+(id)elementWithElement:(DcmElement*)element {
	return [[[[self class] alloc] initWithElement:element] autorelease];
}

-(id)initWithElement:(DcmElement*)element {
	if ((self = [super init])) {
		_element = element; // new DcmElement(element)
	}
	
	return self;
}

-(void)dealloc {
	//delete _element;
	[super dealloc];
}

-(DcmElement*)element {
	return _element;
}

-(NSString*)stringValue {
	NSMutableString* str = [NSMutableString string];
	unsigned int vm = _element->getVM();
	if (vm > 1)
		for (unsigned int i = 0; i < vm; ++i) {
			OFString ofstr;
			if (_element->getOFString(ofstr,i).good())
				[str appendFormat:@"[%d][%s] ", i, ofstr.c_str()];
		}
	else {
		OFString ofstr;
		if (_element->getOFString(ofstr,0).good())
			[str appendFormat:@"%s", ofstr.c_str()];
	}
	
	return str;
}

@end



