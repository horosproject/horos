/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "xNSImage.h"


@implementation xNSImage

- (void) dealloc
{
//	NSLog(@"xNSImage killed");
	if( data == 0L)
	{
		NSLog(@"data == 0L ????");
    }
	free( data);
    data = 0L;
        
//    [bitmapRep release];
    
    [super dealloc];
}

-init
{
	self = [super init];
//	bitmapRep = 0L;
	data = 0L;
	
	return self;
}

-(void) SetxNSImage:(unsigned char*)b
{
//    if( a) bitmapRep = a;
	
	if( data != b)
	{
		if( data) free( data);
		data = b;
	}
}

@end
