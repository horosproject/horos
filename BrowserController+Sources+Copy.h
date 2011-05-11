//
//  BrowserController+Sources+Copy.h
//  OsiriX
//
//  Created by Alessandro Volz on 11.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "BrowserController+Sources.h"


@interface BrowserController (SourcesCopy) 

-(BOOL)initiateCopyImages:(NSArray*)dicomImages toSource:(BrowserSource*)destination;

@end
