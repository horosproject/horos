//
//  N2DirectoryEnumerator.mm
//  OsiriX
//
//  Created by Alessandro Volz on 21.03.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "N2DirectoryEnumerator.h"
#include <dirent.h>

@interface N2DirectoryEnumerator ()

-(void)pushDIR:(DIR*)dir subpath:(NSString*)p;
-(DIR*)DIR;
-(DIR*)DIRAndSubpath:(NSString**)subpath;
-(void)popDIR;

@end



@implementation N2DirectoryEnumerator

@synthesize filesOnly = _filesOnly;

-(id)initWithPath:(NSString*)path maxNumberOfFiles:(NSInteger)m {
	self = [super init];
	
	counter = 0;
	max = m;
	currpath = nil;
	basepath = [path retain];
	DIRs = [[NSMutableArray alloc] init];
	
	DIR* dir = opendir(path.fileSystemRepresentation);
	if (dir) [self pushDIR:dir subpath:NULL];
	
	return self;
}

-(void)dealloc {
	[currpath release];
	while (DIRs.count)
		[self popDIR];
	[DIRs release];
	[basepath release];
	[super dealloc];
}

#pragma mark NSEnumerator API

-(NSArray*)allObjects {
	NSMutableArray* all = [NSMutableArray array];
	
	id i;
	do {
		i = [self nextObject];
		//NSLog(@"i is %@", i);
		if (i) [all addObject:i];
	} while (i);
	
	return all;
}

-(id)nextObject {
	if (max >= 0 && counter >= max)
		return nil;
	++counter;
	
	NSFileManager* fm = NSFileManager.defaultManager;
	
	NSString* subpath;
	DIR* dir;
	while (dir = [self DIRAndSubpath:&subpath]) {
		//NSLog(@"dir %X subpath %@", dir, subpath);
		struct dirent* dirp = readdir(dir);
		if (dirp) {
			NSString* subsubpath = [fm stringWithFileSystemRepresentation:dirp->d_name length:strlen(dirp->d_name)];
			//NSLog(@"nextItem %@", subsubpath);
			if ([subsubpath isEqualToString:@"."] || [subsubpath isEqualToString:@".."])
				continue;
			
			[currpath release];
			currpath = [(subpath? [subpath stringByAppendingPathComponent:subsubpath] : subsubpath) retain];
			NSString* fullpath = [basepath stringByAppendingPathComponent:currpath];
			
			BOOL isDir;
			if (dirp->d_type == DT_DIR || (dirp->d_type == DT_UNKNOWN && [NSFileManager.defaultManager fileExistsAtPath:fullpath isDirectory:&isDir] && isDir)) {
				DIR* sdir = opendir([fullpath fileSystemRepresentation]);
				//NSLog(@"\tPushed");
				if (sdir) [self pushDIR:sdir subpath:currpath];
				if (_filesOnly) continue;
			}
			
			return currpath;
		} else
			[self popDIR];
	}
	
	return nil;
}

#pragma mark NSDirectoryEnumerator API

-(NSDictionary*)fileAttributes {
	return [NSFileManager.defaultManager attributesOfItemAtPath:[basepath stringByAppendingPathComponent:currpath] error:NULL];
}

-(NSDictionary*)directoryAttributes {
	return [NSFileManager.defaultManager attributesOfItemAtPath:[basepath stringByAppendingPathComponent:currpath] error:NULL];
}

-(void)skipDescendants {
	[self skipDescendents];
}

-(void)skipDescendents {
	[self popDIR];
}

- (NSUInteger)level {
	NSUInteger c = DIRs.count;
	return c? c-1 : c;
}

#pragma mark Private API

-(void)pushDIR:(DIR*)dir subpath:(NSString*)p {
	[DIRs addObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:dir], p, NULL]];
}

-(DIR*)DIR {
	return [self DIRAndSubpath:NULL];
}

-(DIR*)DIRAndSubpath:(NSString**)name {
	if (DIRs.count) {
		NSArray* d = DIRs.lastObject;
		if (name)
			if (d.count > 1)
				*name = [d objectAtIndex:1];
			else *name = NULL;
		return (DIR*)[[d objectAtIndex:0] pointerValue];
	} else return nil;
}

-(void)popDIR {
	if (DIRs.count) {
		DIR* dir = self.DIR;
		[DIRs removeLastObject];
		closedir(dir);
	}
}

@end
