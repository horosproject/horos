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

#import <Cocoa/Cocoa.h>

extern const CGFloat N2NoMin, N2NoMax;

typedef struct N2MinMax {
	CGFloat min, max;
} N2MinMax;

N2MinMax N2MakeMinMax(CGFloat min, CGFloat max);
N2MinMax N2MakeMinMax(CGFloat val);
N2MinMax N2MakeMinMax();
N2MinMax N2MakeMin(CGFloat min);
N2MinMax N2MakeMax(CGFloat max);
CGFloat N2MinMaxConstrainedValue(const N2MinMax& mm, CGFloat val);
void N2ExtendMinMax(N2MinMax& n2minmax, CGFloat value);
N2MinMax N2ComposeMinMax(const N2MinMax& mm1, const N2MinMax& mm2);
N2MinMax operator+(const N2MinMax& mm1, const N2MinMax& mm2);
N2MinMax operator+(const N2MinMax& mm, const CGFloat& f);
