
////////////////////////////////////////////
//
//	Matt Brewer
//	December 1, 2009
//
//	matt@matt-brewer.com
//	http://www.matt-brewer.com
//
//
//	This code is released as is
//	with NO warranty, implied or otherwise.
//
////////////////////////////////////////////

#import "NSApplication-Dock.h"
@implementation NSApplication (Dock)


#pragma mark Application Assumed

////////////////////////////////////////////
//
//	Adds the currently running application
//	to the user's Dock
//
////////////////////////////////////////////

- (BOOL) addApplicationToDock {
	
	if ( ![self applicationExistsInDock] ) {
		return [self addApplicationToDock:[[NSBundle mainBundle] bundlePath]];
	} else return NO;
	
}


////////////////////////////////////////////
//
//	YES/NO if current application is in Dock
//
////////////////////////////////////////////

- (BOOL) applicationExistsInDock {
	return [self applicationExistsInDock:[[NSBundle mainBundle] bundlePath]];
}





#pragma mark Application Specified

////////////////////////////////////////////
//
//	Adds the specified path to the Dock
//	Doesn't check to see if is app or if
//	file even exists
//
////////////////////////////////////////////

- (BOOL) addApplicationToDock:(NSString*)path {
	
	BOOL success = YES;
	
	// Add the application to the Dock
	NSArray* args = [NSArray arrayWithObjects:@"write", @"com.apple.Dock",@"persistent-apps",@"-array-add",[NSString stringWithFormat:@"<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%@</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>", path], nil];
	NSTask* t = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/defaults" arguments:args];
	[t waitUntilExit];
	if ( ![t isRunning] && [t terminationStatus] > 0 ) {
		NSLog(@"%d - %d", [t terminationStatus], (int) [t terminationReason]);
		success = NO;
	}
	
	// Now restart the Dock
	t = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObjects:@"-HUP", @"Dock", nil]];
	[t waitUntilExit];
	if ( ![t isRunning] && [t terminationStatus] > 0 ) {
		NSLog(@"%d - %d", [t terminationStatus], (int) [t terminationReason]);
		success = NO;
	}
	
	return success;
}


////////////////////////////////////////////
//
//	YES/NO if application is in Dock
//
////////////////////////////////////////////

- (BOOL) applicationExistsInDock:(NSString*)path
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.apple.Dock"];

	NSArray* apps = [defaults objectForKey:@"persistent-apps"];
	NSDictionary* d = nil;
	NSEnumerator* e = [apps objectEnumerator];
	NSString* app = nil;
    
	while ( d = [e nextObject])
    {
		app = [[[d objectForKey:@"tile-data"] objectForKey:@"file-data"] objectForKey:@"_CFURLString"];
        
		if( app.length > 0 && [app rangeOfString: path].location != NSNotFound)
        {
            NSLog( @"Already in Dock: %@", app);
			return YES;
		}
	} 

    return NO;
}

@end