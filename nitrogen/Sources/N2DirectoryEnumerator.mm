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

#import "N2DirectoryEnumerator.h"
#include <dirent.h>

@interface N2DirectoryEnumerator ()

-(void)pushDIR:(DIR*)dir subpath:(NSString*)p;
-(DIR*)DIR;
-(DIR*)DIRAndSubpath:(NSString**)subpath;
-(void)popDIR;

@end


@interface N2DirectoryEnumeratorReleaser : NSThread {
    DIR* _dir;
}

+ (void)releaseDIR:(DIR*)dir;

@end


@implementation N2DirectoryEnumerator

@synthesize filesOnly = _filesOnly;
@synthesize recursive = _recursive;

-(id)initWithPath:(NSString*)path maxNumberOfFiles:(NSInteger)m
{
	self = [super init];
	
	counter = 0;
	max = m;
	currpath = nil;
	basepath = [path retain];
	DIRs = [[NSMutableArray alloc] init];
	_recursive = YES;
	
	DIR* dir = opendir(path.fileSystemRepresentation);
	if (dir) [self pushDIR:dir subpath:NULL];
	
	return self;
}

-(void)dealloc
{
	[currpath release];
    
	while (DIRs.count)
		[self popDIR];
	[DIRs release];
    
	[basepath release];
	[super dealloc];
}

#pragma mark NSEnumerator API

-(NSArray*)allObjects
{
	NSMutableArray* all = [NSMutableArray array];
	
	id i;
	do
    {
		i = [self nextObject];
		if (i) [all addObject:i];
	}
    while (i);
	
	return all;
}

-(id)nextObject
{
	if (counter >= max)
		return nil;
	++counter;
	
	NSFileManager* fm = NSFileManager.defaultManager;
	
//    if (currpath && ![fm fileExistsAtPath:[basepath stringByAppendingPathComponent:currpath]]) 
//        rewinddir(self.DIR); Why this? Antoine: this can lead to infinite loop
    
	NSString* subpath;
	DIR* dir;
	while((dir = [self DIRAndSubpath:&subpath]))
    {
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
				if (_recursive) {
					DIR* sdir = opendir([fullpath fileSystemRepresentation]);
					//NSLog(@"\tPushed");
					if (sdir) [self pushDIR:sdir subpath:currpath];
				}
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
	NSDictionary* d = [NSFileManager.defaultManager attributesOfItemAtPath:[basepath stringByAppendingPathComponent:currpath] error:NULL];
    [d allKeys]; // http://www.noodlesoft.com/blog/2007/03/07/mystery-bug-heisenbergs-uncertainty-principle/
    return d;
}

-(NSDictionary*)directoryAttributes {
	NSDictionary* d = [NSFileManager.defaultManager attributesOfItemAtPath:[basepath stringByAppendingPathComponent:currpath] error:NULL];
    [d allKeys]; // http://www.noodlesoft.com/blog/2007/03/07/mystery-bug-heisenbergs-uncertainty-principle/
    return d;
}

- (int)stat:(struct stat*)s {
    return stat([[basepath stringByAppendingPathComponent:currpath] fileSystemRepresentation], s);
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
        {
			if (d.count > 1)
				*name = [d objectAtIndex:1];
			else *name = NULL;
        }
		return (DIR*)[[d objectAtIndex:0] pointerValue];
	} else return nil;
}

-(void)popDIR {
	if (DIRs.count) {
		DIR* dir = self.DIR;
		[DIRs removeLastObject];
		[N2DirectoryEnumeratorReleaser releaseDIR:dir];
	}
}

@end

@implementation N2DirectoryEnumeratorReleaser

+ (void)releaseDIR:(DIR*)dir {
    [[[[self alloc] initWithDIR:dir] autorelease] start];
}

- (id)initWithDIR:(DIR*)dir {
    if ((self = [super init])) {
        _dir = dir;
    }
    
    return self;
}

- (void)main {
    @autoreleasepool {
        closedir(_dir);
    }
}

@end

