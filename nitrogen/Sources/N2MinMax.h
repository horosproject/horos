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
