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
