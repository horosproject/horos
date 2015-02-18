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
