#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "Notifications.h"
#import "PluginManager.h"

//#ifdef NDEBUG
//#else

@implementation NSNotificationCenter (AllObservers)

const static void *namesKey = &namesKey;

+ (void) load
{
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(addObserver:selector:name:object:)),
	                               class_getInstanceMethod(self, @selector(my_addObserver:selector:name:object:)));
    
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(postNotificationName:object:userInfo:)),
	                               class_getInstanceMethod(self, @selector(my_postNotificationName:object:userInfo:)));
    
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(postNotification:)),
	                               class_getInstanceMethod(self, @selector(my_postNotification:)));
    
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(removeObserver:name:object:)),
	                               class_getInstanceMethod(self, @selector(my_removeObserver:name:object:)));
}

- (void) my_addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(id)notificationSender
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSString *bundleIdentifier = [[NSBundle bundleForClass: [notificationObserver class]] bundleIdentifier];
    
    if( [bundleIdentifier hasPrefix: @"com.rossetantoine"] == NO && [bundleIdentifier hasPrefix: @"com.apple"] == NO && [bundleIdentifier hasPrefix: @"dk.infinite-loop.crashreporter"] == NO)
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
        
        NSLog( @"---- catch notifications: %@ - %@", [notificationObserver class], bundleIdentifier);
    }
    else
        [self my_addObserver:notificationObserver selector:notificationSelector name:notificationName object:notificationSender];
   
    
    [pool release];
}

- (void) my_removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(id)notificationSender
{
    @synchronized (self)
    {
        NSMutableDictionary *names = objc_getAssociatedObject(self, (void*) namesKey);
        if (names)
        {
            NSAutoreleasePool *pool = [NSAutoreleasePool new];
            
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
            
            [pool release];
        }
    }
    
    [self my_removeObserver: notificationObserver name: notificationName object: notificationSender];
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
    for( NSDictionary *observerDictionary in [self my_observersForNotificationName: notification.name])
    {
        SEL selector = [[observerDictionary objectForKey: @"selector"] pointerValue];
        id observer = [[observerDictionary objectForKey: @"observer"] pointerValue];
        
        [PluginManager startProtectForCrashWithPath: [[NSBundle bundleForClass: [observer class]] bundlePath]];
        
        if( [observerDictionary objectForKey: @"sender"])
        {
            if( [observerDictionary objectForKey: @"sender"] == notification.object)
                [observer performSelector: selector withObject: notification];
        }
        else
            [observer performSelector: selector withObject: notification];
        
        [PluginManager endProtectForCrash];
    }
}

- (void) my_postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @synchronized (self)
    {
        [self postExtraNotification: [NSNotification notificationWithName: aName object: anObject userInfo: aUserInfo]];
    }
    
    [self my_postNotificationName: aName object: anObject userInfo: aUserInfo];
        
    [pool release];
}

- (void) my_postNotification:(NSNotification *)notification
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @synchronized (self)
    {
        [self postExtraNotification: notification];
    }
    
    [self my_postNotification: notification];
        
    [pool release];
}
@end

//#endif
