/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Cocoa/Cocoa.h>

// We require that a valid plug-in implement this protocol.
//
//	Plug-ins are implemented as class clusters. There are two important phases:
//	1) Class initialization, when the plug-in is loaded
//	2) Class instantiation, when actual plug-in objects are generated.
//	In the second phase, any number of subclasses of the plug-in may be returned. However, the
//	calling program need not concern itself with subclass details.

@protocol PAPluginProtocol

//	initializeClass: is called once when the plug-in is loaded. The plug-in's bundle is passed
//	as argument; the plug-in could discover its own bundle again, but since we have it available
//	anyway when this is called, this saves some time and space.
//	This method should do all global plug-in initialization, such as loading preferences; if
//	initialization fails, it should return NO, and the plug-in won't be called again.

+ (BOOL)initializeClass:(NSBundle*)theBundle;

//	terminateClass is called once when the plug-in won't be used again.

+ (void)terminateClass;

//	pluginsFor: is called whenever the calling application wants to instantiate a plug-in class.
//	An object is passed in as argument; this object might be validated by the plug-in class to
//	decide which sort of instances, or how many instances to return. The object reference may also
//	be stored by the instances and thereafter be used as a bridge to the calling application.
//	This method returns an enumerator of an array of plug-in instances. This enumerator, the array
//	itself, and the plug-in instances are all autoreleased, so the calling application needs to retain
//	whatever it wants to keep. If no instances were generated, this returns nil.

+ (NSEnumerator*)pluginsFor:(id)anObject;

//	theView returns a plug-in instance's view. In the example, this is inserted into the main
//	window's tab view.

- (NSView*)theView;

//	theViewName returns the name associated with a plug-in instance's view. In the example, this
//	is the label given to the tab.

- (NSString*)theViewName;

@end

