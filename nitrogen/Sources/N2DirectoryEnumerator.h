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


@interface N2DirectoryEnumerator : NSDirectoryEnumerator {
@private
	NSString* basepath;
	NSString* currpath;
	NSMutableArray* DIRs;
	NSUInteger counter, max;
	BOOL _filesOnly;
	BOOL _recursive;
}

@property BOOL filesOnly;
@property BOOL recursive;

-(id)initWithPath:(NSString*)path maxNumberOfFiles:(NSInteger)n;

@end
