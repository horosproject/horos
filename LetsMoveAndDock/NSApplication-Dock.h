
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

@interface NSApplication (Dock)

- (BOOL)addApplicationToDock;
- (BOOL)applicationExistsInDock;

- (BOOL)addApplicationToDock:(NSString*)path;
- (BOOL)applicationExistsInDock:(NSString*)path;

@end