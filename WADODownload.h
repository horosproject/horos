/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


#import <Foundation/Foundation.h>


@interface WADODownload : NSObject
{
	volatile int32_t WADOThreads __attribute__ ((aligned (4)));
    int WADOTotal, countOfSuccesses;
    int WADOGrandTotal, WADOBaseTotal;
    unsigned long totalData, receivedData;
	NSMutableDictionary *WADODownloadDictionary, *logEntry;
	BOOL showErrorMessage, firstWadoErrorDisplayed, _abortAssociation;
    NSTimeInterval firstReceivedTime, lastStatusUpdate;
    NSString *baseStatus;
}

@property BOOL _abortAssociation, showErrorMessage;
@property int countOfSuccesses, WADOGrandTotal, WADOBaseTotal;
@property unsigned long totalData, receivedData;
@property (retain) NSString *baseStatus;

- (void) WADODownload: (NSArray*) urlToDownload;

@end
