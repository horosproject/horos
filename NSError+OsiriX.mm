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

#import "NSError+OsiriX.h"


@implementation NSError (OsiriX)

NSString* const OsirixErrorDomain = @"OsiriXDomain";

+(NSError*)osirixErrorWithCode:(NSInteger)code underlyingError:(NSError*)underlyingError localizedDescription:(NSString*)desc {
	return [NSError errorWithDomain:OsirixErrorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys: desc, NSLocalizedDescriptionKey, underlyingError, NSUnderlyingErrorKey, NULL]];
}

+(NSError*)osirixErrorWithCode:(NSInteger)code underlyingError:(NSError*)underlyingError localizedDescriptionFormat:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString* desc = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	return [self osirixErrorWithCode:code underlyingError:underlyingError localizedDescription:desc];
}

+(NSError*)osirixErrorWithCode:(NSInteger)code localizedDescription:(NSString*)desc {
	return [NSError errorWithDomain:OsirixErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)osirixErrorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	NSString* desc = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	return [self osirixErrorWithCode:code localizedDescription:desc];
}

@end
