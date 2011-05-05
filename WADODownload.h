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


@interface WADODownload : NSObject
{
	volatile int32_t WADOThreads __attribute__ ((aligned (4)));
	NSMutableDictionary *WADODownloadDictionary;
	BOOL showErrorMessage, firstWadoErrorDisplayed, _abortAssociation;
}

@property BOOL _abortAssociation, showErrorMessage;

- (void) WADODownload: (NSArray*) urlToDownload;

@end
