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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "Notifications.h"
#import "PluginManager.h"

#import "url.h"

//#ifdef NDEBUG
//#else

@implementation NSNotificationCenter (AllObservers)

const static void *namesKey = &namesKey;

+ (void) load
{
//	method_exchangeImplementations(class_getInstanceMethod(self, @selector(addObserver:selector:name:object:)),
//	                               class_getInstanceMethod(self, @selector(my_addObserver:selector:name:object:)));
//    
//    method_exchangeImplementations(class_getInstanceMethod(self, @selector(postNotificationName:object:userInfo:)),
//	                               class_getInstanceMethod(self, @selector(my_postNotificationName:object:userInfo:)));
//    
//    method_exchangeImplementations(class_getInstanceMethod(self, @selector(postNotification:)),
//	                               class_getInstanceMethod(self, @selector(my_postNotification:)));
//    
//    method_exchangeImplementations(class_getInstanceMethod(self, @selector(removeObserver:name:object:)),
//	                               class_getInstanceMethod(self, @selector(my_removeObserver:name:object:)));
}

- (void) my_addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(id)notificationSender
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSString *bundleIdentifier = [[NSBundle bundleForClass: [notificationObserver class]] bundleIdentifier];
    
    if( [bundleIdentifier hasPrefix: @BUNDLE_IDENTIFIER_PREFIX] == NO &&
       [bundleIdentifier hasPrefix: @"com.apple"] == NO &&
       [bundleIdentifier hasPrefix: @"dk.infinite-loop.crashreporter"] == NO)
    {
        @synchronized (self)
        {
            NSMutableDictionary *names = objc_getAssociatedObject(self, (void*) namesKey);
            if (!names)
            {
                names = [NSMutableDictionary dictionary];
                objc_setAssociatedObject(self, (void*) namesKey, names, OBJC_ASSOCIATION_RETAIN);
            }
            
            NSDictionary *observerDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithPointer: notificationObserver] , @"observer", [NSValue valueWithPointer: notificationSelector], @"selector", notificationSender, @"sender", nil];
            
            NSMutableSet *observers = [names objectForKey:notificationName];
            if (!observers)
            {
                observers = [NSMutableSet setWithObject: observerDictionary];
                [names setObject:observers forKey: [NSString stringWithUTF8String: notificationName.UTF8String]];
            }
            else
            {
                [observers addObject: observerDictionary];
            }
        }
        
//        NSLog( @"---- catch notifications: %@ - %@", [notificationObserver class], bundleIdentifier);
    }
    else
        [self my_addObserver:notificationObserver selector:notificationSelector name:notificationName object:notificationSender];
   
    
    [pool release];
}

- (void) my_removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(id)notificationSender
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @synchronized (self)
    {
        NSMutableDictionary *names = objc_getAssociatedObject(self, (void*) namesKey);
        if (names)
        {
            if( notificationName)
            {
                NSMutableSet *set = [names objectForKey: notificationName];
                
                for( NSDictionary *observerNotification in [NSMutableSet setWithSet: set])
                {
                    if( [[observerNotification objectForKey: @"observer"] pointerValue] == notificationObserver)
                    {
                        if( notificationSender)
                        {
                            if( notificationSender == [observerNotification objectForKey: @"sender"])
                                [set removeObject: observerNotification];
                        }
                        else
                            [set removeObject: observerNotification];
                    }
                }
            }
            else
            {
                for( NSMutableSet *set in [names allValues])
                {
                    for( NSDictionary *observerNotification in [NSMutableSet setWithSet: set])
                    {
                        if( [[observerNotification objectForKey: @"observer"] pointerValue] == notificationObserver)
                            [set removeObject: observerNotification];
                    }
                }
            }
        }
    }
    
    [self my_removeObserver: notificationObserver name: notificationName object: notificationSender];
    
    [pool release];
}

- (NSSet *) my_observersForNotificationName:(NSString *)notificationName
{
    @synchronized (self)
    {
        NSMutableDictionary *names = objc_getAssociatedObject(self, (void*) namesKey);
        return [names objectForKey:notificationName] ?: [NSSet set];
    }
    
    return [NSSet set];
}

- (void) postExtraNotification:(NSNotification *)notification
{
    NSMutableArray *selectors = nil;
    
    @synchronized( self)
    {
        for( NSDictionary *observerDictionary in [self my_observersForNotificationName: notification.name])
        {
//            SEL selector = [[observerDictionary objectForKey: @"selector"] pointerValue];
//            id observer = [[observerDictionary objectForKey: @"observer"] pointerValue];
            
            if( selectors == nil)
                selectors = [NSMutableArray array];
            
            if( [observerDictionary objectForKey: @"sender"])
            {
                if( [observerDictionary objectForKey: @"sender"] == notification.object)
                    [selectors addObject: [[observerDictionary copy] autorelease]];
            }
            else
                [selectors addObject: [[observerDictionary copy] autorelease]];
        }
    }
    
    for( NSDictionary *observerDictionary in selectors)
    {
        SEL selector = [[observerDictionary objectForKey: @"selector"] pointerValue];
        id observer = [[observerDictionary objectForKey: @"observer"] pointerValue];
        
        [PluginManager startProtectForCrashWithPath: [[NSBundle bundleForClass: [observer class]] bundlePath]];
        
        [observer performSelector: selector withObject: notification];
        
        [PluginManager endProtectForCrash];
    }
}

- (void) my_postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [self postExtraNotification: [NSNotification notificationWithName: aName object: anObject userInfo: aUserInfo]];
    
    [self my_postNotificationName: aName object: anObject userInfo: aUserInfo];
        
    [pool release];
}

- (void) my_postNotification:(NSNotification *)notification
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [self postExtraNotification: notification];
    
    [self my_postNotification: notification];
        
    [pool release];
}
@end

//#endif
