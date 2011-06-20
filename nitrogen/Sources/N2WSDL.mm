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

#import "N2WSDL.h"


@implementation N2WSDL

-(id)init {
	self = [super init];
	_types = [[NSMutableArray alloc] initWithCapacity:64];
	_messages = [[NSMutableArray alloc] initWithCapacity:64];
	_operations = [[NSMutableArray alloc] initWithCapacity:64];
	_portTypes = [[NSMutableArray alloc] initWithCapacity:64];
	_bindings = [[NSMutableArray alloc] initWithCapacity:64];
	_ports = [[NSMutableArray alloc] initWithCapacity:64];
	_services = [[NSMutableArray alloc] initWithCapacity:64];
	return self;
}

-(void)dealloc {
	[_types release];
	[_messages release];
	[_operations release];
	[_portTypes release];
	[_bindings release];
	[_ports release];
	[_services release];
	[super dealloc];
}

-(id)initWithContentsOfURL:(NSURL*)url {
	self = [self init];
	
	NSError* error = NULL;
	NSXMLDocument* wsdl = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
	if (error)
		[NSException raise:NSGenericException format:@"[NSXMLDocument initWithContentsOfURL:] error: %@", [error description]];
	
	for (NSXMLElement* type in [wsdl objectsForXQuery:@"/wsdl:definitions/wsdl:types/*" error:&error])
		NSLog(@"%@", [type XMLString]);
	
	[wsdl release];
	
	return self;
}

@end
