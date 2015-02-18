/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "PluginFileFormatDecoder.h"


@implementation PluginFileFormatDecoder

//returns values:

+ (float *)decodedDataAtPath:(NSString *)path{
	return nil;
}

- (float *)checkLoadAtPath:(NSString *)path{
	return nil;
}

- (id) init {
	if (self = [super init]) {
		NSLog(@"Plugin fileFormat Init");
		_patientName = nil;
		_patientID = nil;
		_studyID =  nil;
		_seriesID =  nil;
		_imageID =  nil;
		_studyDescription = nil;
		_seriesDescription = nil;
		
		_height = nil;
		_width = nil;
		_fImage = nil;
		_rowBytes = nil;
		_windowWidth = nil;
		_windowLevel = nil;
		
		_isRGB = YES;
	
	}
	return self;
}

- (void)dealloc{
	[_patientName release];
	[_patientID release];
	[_studyID release];
	[_seriesID release];
	[_imageID release];
	[_studyDescription release];
	[_seriesDescription release];
	[_height release];
	[_width release];
	[_rowBytes release];
	[_windowWidth release];
	[_windowLevel release];
	[super dealloc];	
}

- (NSNumber *)height{
	return _height;
}

- (NSNumber *)width{
	return _width;
}

- (NSNumber *)rowBytes{
	return _rowBytes;
}

- (NSNumber *)windowWidth{
	return _windowWidth;
}
- (NSNumber *)windowLevel{
	return _windowLevel;
}

- (BOOL)isRGB{
	return _isRGB;
}


- (NSString *)patientName{
	return _patientName;
}
- (NSString *)patientID{
	return _patientID;
}

- (NSString *)studyID{
	return _studyID;
}

- (NSString *)seriesID{
	return _seriesID;
}

- (NSString *)imageID{
	return _imageID;
}

- (NSString *)studyDescription{
	return _studyDescription;
}

- (NSString *)seriesDescription{
	return _seriesDescription;
}

@end
