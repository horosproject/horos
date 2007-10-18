/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "xNSImage.h"

@implementation xNSImage

- (void) dealloc
{
	if( data == 0L)
	{
		NSLog(@"data == 0L ????");
    }
	else free( data);
    data = 0L;
	
    [super dealloc];
}

-(void) SetxNSImage:(unsigned char*)b
{
	if( data != b)
	{
		if( data) free( data);
		data = b;
	}
}
@end
