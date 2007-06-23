//
//  ViewerControllerWindow.m
//  OsiriX
//
//  Created by Antoine Rosset on 23.06.07.
//  Copyright 2007 OsiriX. All rights reserved.
//

#import "ViewerControllerWindow.h"
#import "ViewerController.h"

@implementation ViewerControllerWindow

- (NSString *) representedFilename
{
	[[self windowController] updateRepresentedFileName];
	return [super representedFilename];
}
@end
