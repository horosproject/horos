/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import "LogArrayController.h"
#import "browserController.h"

extern BrowserController *browserWindow;


@implementation LogArrayController


- (void)awakeFromNib{
	[self setManagedObjectContext:[browserWindow managedObjectContext]];
	//NSLog(@"query ManagedObjectContext: %@", [[self managedObjectContext] description]);
	[self fetch:nil];
	//NSLog(@"filter Predicate: %@", [[self filterPredicate] description]);
	//NSLog(@"Content: %@", [[self content] description]);
	
}

-(NSManagedObjectContext *)managedObjectContext{
	return [browserWindow managedObjectContext];
}
/*
- (void)removeObjectAtArrangedObjectIndex:(unsigned int)index{
	id object = nil;
	if (index < [[self arrangedObjects] count])
		object = [[self arrangedObjects] objectAtIndex:index];
	[super removeObjectAtArrangedObjectIndex:(unsigned int)index];	
	[[browserWindow managedObjectContext] deleteObject:(NSManagedObject *)object];
	[self save: self];
}

- (void)remove:(id)sender{
	NSLog(@"remove");
	[super remove:sender];
	[self performSelectorOnMainThread:@selector(save:) withObject:nil waitUntilDone:YES];
}

- (void)save:(id)sender{
	NSError *error = 0L;
	if (![[browserWindow managedObjectContext]  save: &error])
	{
		NSString *localizedDescription = [error localizedDescription];
		error = [NSError errorWithDomain:@"OsiriXDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, NSUnderlyingErrorKey, [NSString stringWithFormat:@"Error saving: %@", ((localizedDescription != nil) ? localizedDescription : @"Unknown Error")], NSLocalizedDescriptionKey, nil]];
		[[NSApplication sharedApplication] presentError:error];
	}
}
*/
- (IBAction)nothing:(id)sender{
}

@end
