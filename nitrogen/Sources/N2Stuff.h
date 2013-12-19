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

#ifndef OsiriX_Lion_N2Localization_h
#define OsiriX_Lion_N2Localization_h

#define N2SingularPlural(c, s, p) (c == 1? s : p)
#define N2LocalizedSingularPlural(c, s, p) (c == 1? NSLocalizedString(s, @"Singular") : NSLocalizedString(p, @"Plural")

#define N2SingularPluralCount(c, s, p) [NSString stringWithFormat:@"%d %@", (int)c, (c == 1? s : p)]
#define N2LocalizedSingularPluralCount(c, s, p) [NSString stringWithFormat:@"%@ %@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger)c] numberStyle:NSNumberFormatterDecimalStyle], (c == 1? s : p)]

#define N2LocalizedDecimal(c) [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger)c] numberStyle:NSNumberFormatterDecimalStyle]

#endif
