//
//  N2Stuff.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 16.02.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#ifndef OsiriX_Lion_N2Localization_h
#define OsiriX_Lion_N2Localization_h

#define N2SingularPlural(c, s, p) [NSString stringWithFormat:@"%d %@", (int)c, (c == 1? s : p)]
#define N2LocalizedSingularPlural(c, s, p) [NSString stringWithFormat:@"%d %@", (int)c, (c == 1? NSLocalizedString(s, @"Singular") : NSLocalizedString(p, @"Plural"))]

#endif
