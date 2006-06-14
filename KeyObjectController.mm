//
//  KeyObjectController.mm
//  OsiriX
//
//  Created by Lance Pysher on 6/13/06.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "KeyObjectController.h"
#import "KeyObjectReport.h"
#import "browserController.h"


@implementation KeyObjectController

- (id)initWithStudy:(id)study{
	if (self = [super initWithWindowNibName:@"KeyObjectReport"])
		_study = [study retain];
	
	return self;
}

- (void)dealloc{
	[_study release];
	[_keyDescription release];
	[super dealloc];
}

- (int) title{
	return _title;
}
- (void)setTitle:(int)title{
	_title = title;
}
- (NSString *) keyDescription{
	return _keyDescription;
}
- (void)setKeyDescription:(NSString *)keyDescription{
	[_keyDescription release];
	_keyDescription = [keyDescription retain];
}

- (IBAction)closeWindow:(id)sender{
	if ([sender tag] == 0){
		NSString *studyInstanceUID = [_study valueForKey:@"studyInstanceUID"];
		NSString *path;
		KeyObjectReport *ko = [[KeyObjectReport alloc] initWithStudy:_study  title:_title   description:_keyDescription];
		NSString *sopInstanceUID = [ko sopInstanceUID];
		NSString *rootFolder = [[BrowserController currentBrowser] documentsDirectory];
		path = [[rootFolder stringByAppendingPathComponent:@"REPORTS"] stringByAppendingPathComponent:studyInstanceUID];
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		BOOL isDir;
		if (!([defaultManager fileExistsAtPath:path isDirectory:&isDir] && &isDir))
			[defaultManager createDirectoryAtPath:path attributes:nil];
		path = [rootFolder stringByAppendingPathComponent:@"KEYOBJECTS"];
		if (!([defaultManager fileExistsAtPath:path isDirectory:&isDir] && &isDir))
			[defaultManager createDirectoryAtPath:(NSString *)path attributes:nil];
		path = [rootFolder stringByAppendingPathComponent:sopInstanceUID];
		[ko writeFileAtPath:path];
		[ko release];
	}
	[NSApp endSheet:[self window]];
	[[self window] close];
	
}

@end
