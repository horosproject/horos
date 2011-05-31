//
//  N2DirectoryEnumerator.h
//  OsiriX
//
//  Created by Alessandro Volz on 21.03.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface N2DirectoryEnumerator : NSDirectoryEnumerator {
@private
	NSString* basepath;
	NSString* currpath;
	NSMutableArray* DIRs;
	NSUInteger counter, max;
	BOOL _filesOnly;
}

@property BOOL filesOnly;

-(id)initWithPath:(NSString*)path maxNumberOfFiles:(NSInteger)n;

@end
