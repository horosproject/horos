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


#import "N2MinMax.h"
#include <algorithm>

const CGFloat N2NoMin = CGFLOAT_MIN, N2NoMax = CGFLOAT_MAX;

N2MinMax N2MakeMinMax(CGFloat min, CGFloat max) {
	N2MinMax mm = {min, max};
	return mm;
}

N2MinMax N2MakeMinMax(CGFloat val) {
	return N2MakeMinMax(val, val);
}

N2MinMax N2MakeMinMax() {
	return N2MakeMinMax(N2NoMin, N2NoMax);
}

N2MinMax N2MakeMin(CGFloat min) {
	return N2MakeMinMax(min, N2NoMax);
}

N2MinMax N2MakeMax(CGFloat max) {
	return N2MakeMinMax(N2NoMin, max);
}

CGFloat N2MinMaxConstrainedValue(const N2MinMax& mm, CGFloat val) {
	if (val < mm.min) val = mm.min;
	if (val > mm.max) val = mm.max;
	return val;
}

void N2ExtendMinMax(N2MinMax& n2minmax, CGFloat value) {
	n2minmax.min = std::min(n2minmax.min, value);
	n2minmax.max = std::max(n2minmax.max, value);
}

N2MinMax N2ComposeMinMax(const N2MinMax& mm1, const N2MinMax& mm2) {
	return N2MakeMinMax(std::max(mm1.min, mm2.min), std::min(mm1.max, mm2.max));
}

CGFloat N2InfinityAwareSum(CGFloat f1, CGFloat f2) {
	if (f1 == CGFLOAT_MAX || f2 == CGFLOAT_MAX) return CGFLOAT_MAX;
	if (f1 == CGFLOAT_MIN || f2 == CGFLOAT_MIN) return CGFLOAT_MIN;
	return f1+f2;
}

N2MinMax operator+(const N2MinMax& mm1, const N2MinMax& mm2) {
	return N2MakeMinMax(N2InfinityAwareSum(mm1.min, mm2.min), N2InfinityAwareSum(mm1.max, mm2.max));
}

N2MinMax operator+(const N2MinMax& mm, const CGFloat& f) {
	return N2MakeMinMax(N2InfinityAwareSum(mm.min, f), N2InfinityAwareSum(mm.max, f));
}
