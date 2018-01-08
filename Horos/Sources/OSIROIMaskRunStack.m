/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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
//
//  OISROIMaskStack.m
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 9/25/12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "OSIROIMaskRunStack.h"

@implementation OSIROIMaskRunStack

- (id)initWithMaskRunData:(NSData *)maskRunData
{
    if ( (self = [super init])) {
        _maskRunData = [maskRunData retain];
        maskRunCount = [maskRunData length] / sizeof(OSIROIMaskRun);
        _maskRunArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_maskRunData release];
    [_maskRunArray release];
    
    [super dealloc];
}

- (OSIROIMaskRun)currentMaskRun
{
    if ([_maskRunArray count]) {
        return [[_maskRunArray lastObject] OSIROIMaskRunValue];
    } else if (_maskRunIndex < maskRunCount) {
        return ((OSIROIMaskRun *)[_maskRunData bytes])[_maskRunIndex];
    } else {
        assert(0);
        return OSIROIMaskRunZero;
    }
}

- (void)pushMaskRun:(OSIROIMaskRun)maskRun
{
    [_maskRunArray addObject:[NSValue valueWithOSIROIMaskRun:maskRun]];
}

- (OSIROIMaskRun)popMaskRun
{
    OSIROIMaskRun maskRun;
    
    if ([_maskRunArray count]) {
        maskRun = [[_maskRunArray lastObject] OSIROIMaskRunValue];
        [_maskRunArray removeLastObject];
    } else if (_maskRunIndex < maskRunCount) {
        maskRun = ((OSIROIMaskRun *)[_maskRunData bytes])[_maskRunIndex];
        _maskRunIndex++;
    } else {
        assert(0);
        maskRun = OSIROIMaskRunZero;
    }
    
    return maskRun;
}

- (NSUInteger)count
{
    return [_maskRunArray count] + (maskRunCount - _maskRunIndex);
}


@end
