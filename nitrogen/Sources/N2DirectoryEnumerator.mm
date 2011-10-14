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
	[NSException raise:NSGenericException format:@"N2DirectoryEnumerator doesn't provide -allObjects"];
	return nil;
}

-(id)nextObject {
	if (counter >= max)
		return nil;
	++counter;
	
	NSFileManager* fm = NSFileManager.defaultManager;
	
	NSString* subpath;
	DIR* dir;
	while((dir = [self DIRAndSubpath:&subpath]))
    {
		struct dirent* dirp = readdir(dir);
		if (dirp) {
			NSString* subsubpath = [fm stringWithFileSystemRepresentation:dirp->d_name length:strlen(dirp->d_name)];
			if ([subsubpath isEqualToString:@"."] || [subsubpath isEqualToString:@".."])
				continue;
			
			[currpath release];
			currpath = [(subpath? [subpath stringByAppendingPathComponent:subsubpath] : subsubpath) retain];

			if (dirp->d_type == DT_DIR) {
				DIR* sdir = opendir([[basepath stringByAppendingPathComponent:currpath] fileSystemRepresentation]);
				if (sdir) [self pushDIR:sdir subpath:currpath];
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
