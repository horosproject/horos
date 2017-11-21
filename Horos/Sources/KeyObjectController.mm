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

#import "KeyObjectController.h"
#import "KeyObjectReport.h"
#import "browserController.h"
#import "DicomStudy.h"

@implementation KeyObjectController

- (id)initWithStudy:(id)study
{
	if (self = [super initWithWindowNibName:@"KeyObjectReport"])
	{
		_study = [study retain];
		_title = 113000; // Of Interest
		NSLog(@"init Key Object controller");
		NSArray *series = [study keyObjectSeries];
		
		if([series count] > 0)
			_seriesUID = [[[series objectAtIndex: 0] valueForKey:@"seriesDICOMUID"] retain];
	}
	return self;
}

- (void)dealloc{
	[_study release];
	[_keyDescription release];
	[_seriesUID release];
	[super dealloc];
}

- (int) intTitle{
	return _title;
}

- (void)setIntTitle:(int)title{
	_title = title;
}

- (NSString *) keyDescription{
	return _keyDescription;
}

- (void)setKeyDescription:(NSString *)keyDescription{
	[_keyDescription release];
	_keyDescription = [keyDescription retain];
	NSLog(@"set description: %@",keyDescription);
}

- (IBAction)closeWindow:(id)sender{
	if ([sender tag] == 0){
		NS_DURING
		NSLog(@"close Window");
		NSString *path;

		//Save to INCOMING		
		NSString *rootFolder = [[BrowserController currentBrowser] documentsDirectory];
		//path = [[rootFolder stringByAppendingPathComponent:@"REPORTS"] stringByAppendingPathComponent:studyInstanceUID];
		path = [rootFolder stringByAppendingPathComponent:@"INCOMING.noindex"];

		KeyObjectReport *ko = [[KeyObjectReport alloc] initWithStudy:_study title:_title description:_keyDescription seriesUID:_seriesUID];
		NSString *sopInstanceUID = [ko sopInstanceUID];
	
		path = [path stringByAppendingPathComponent:sopInstanceUID];
		NSLog(@"Write file: %@", path);
		if (ko) {
			NSLog(@"ko: %@", [ko description]);
			[ko writeFileAtPath:path];
			[ko release];
		}

		NS_HANDLER
			NSLog(@"Close Window exception: %@", [localException description]);
		NS_ENDHANDLER
	}
	[NSApp endSheet:[self window] returnCode:0];
	[[self window] close];
	
}

@end
