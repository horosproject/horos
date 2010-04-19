#include <Cocoa/Cocoa.h>

int main(int argc, char** argv) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	const NSString* const OsirixLiteLocation = @"/Library/Application Support/OsiriX";
	NSTask* task;
	
	// make directory to hold OsiriX Lite
	task = [NSTask launchedTaskWithLaunchPath:@"/bin/mkdir" arguments:[NSArray arrayWithObjects: @"-p", OsirixLiteLocation, NULL]];
	[task waitUntilExit];
	
	// unzip OsiriX Lite
	task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:[NSArray arrayWithObjects: @"-od", OsirixLiteLocation, [[NSBundle mainBundle] pathForResource:@"OsiriX Lite" ofType:@"zip"], NULL]];
	[task waitUntilExit];
	
	// launch OsiriX Lite
	[[NSWorkspace sharedWorkspace] launchApplication:[OsirixLiteLocation stringByAppendingPathComponent:@"OsiriX Lite.app"]];
	
	[pool release];
}
