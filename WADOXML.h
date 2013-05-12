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

#import <Foundation/Foundation.h>

@interface WADOXML : NSObject <NSXMLParserDelegate>
{
    NSMutableDictionary *studies;
    
    NSString *studyInstanceUID, *seriesInstanceUID, *SOPInstanceUID;
    NSString *wadoURL;
}
@property (readonly) NSMutableDictionary *studies;
@property (retain) NSString *studyInstanceUID, *seriesInstanceUID, *SOPInstanceUID, *wadoURL;

- (void) parseURL: (NSURL*) url;
- (NSArray*) getWADOUrls;

@end
