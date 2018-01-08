/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#ifndef OSIRIX_LIGHT
#include "FVTiff.h"
#endif

#import "XMLController.h"
#import "XMLControllerDCMTKCategory.h"
#import "WaitRendering.h"
#import "DicomFile.h"
#import "DicomFileDCMTKCategory.h"
#import "BrowserController.h"
#import "ViewerController.h"
#import "AppController.h"
#import "DCMPix.h"
#import "MutableArrayCategory.h"
#import "Notifications.h"
#import "DICOMToNSString.h"
#import "N2Debug.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DCMObject.h"
#import "DCMAttribute.h"
#import "DCMAttributeTag.h"
#import "DicomDatabase.h"
#import "PluginManager.h"

static NSString* 	XMLToolbarIdentifier					= @"XML Toolbar Identifier";
static NSString*	ExportToolbarItemIdentifier				= @"Export.icns";
static NSString*	ExportTextToolbarItemIdentifier			= @"ExportText";
static NSString*	ExpandAllItemsToolbarItemIdentifier		= @"add-large";
static NSString*	CollapseAllItemsToolbarItemIdentifier	= @"minus-large";
static NSString*	SearchToolbarItemIdentifier				= @"Search";
static NSString*	EditingToolbarItemIdentifier			= @"Editing";
static NSString*	SortSeriesToolbarItemIdentifier			= @"SortSeries";
static NSString*	VerifyToolbarItemIdentifier				= @"Validator";

static BOOL showWarning = YES;

extern int delayedTileWindows;


@implementation XMLController

@synthesize imObj, editingActivated;
@synthesize viewer;

// To be 'compatible' with TileWindows in AppController
/////////////////////////////////////////////////
- (void)setWindowFrame:(NSRect)rect showWindow:(BOOL) showWindow animate: (BOOL) animate
{
	[AppController resizeWindowWithAnimation: [self window] newSize: rect];
    
    BOOL wasAlreadyVisible = [[self window] isVisible];
    
    if( showWindow && wasAlreadyVisible)
        [[self window] orderFront:self];
}

- (NSArray*) fileList
{
	return [NSArray arrayWithObject: imObj];
}

/////////////////////////////////////////////////

- (NSString*) getPath:(NSXMLElement*) node
{
	NSMutableString	*result = [NSMutableString string];
	
	id parent = node;
	id child = nil;
	BOOL first = TRUE;
	
	do
	{
		if( [[[parent parent] className] isEqualToString:@"NSXMLElement"])
		{
			if( [[parent attributeForName:@"group"] stringValue] && [[parent attributeForName:@"element"] stringValue])
			{
				NSString *subString = [NSString stringWithFormat:@"(%@,%@)", [[parent attributeForName:@"group"] stringValue], [[parent attributeForName:@"element"] stringValue]];
				
				if( first == NO && [[child attributeForName:@"group"] stringValue] && [[child attributeForName:@"element"] stringValue])
					subString = [subString stringByAppendingString:@"."];
					
				[result insertString: subString atIndex: 0];
			}
			else
			{
				NSString *subString =  [NSString stringWithFormat:@"[%d]", (int) [[[parent parent] children] indexOfObject: parent]];
				
				if( first == NO)
					subString = [subString stringByAppendingString:@"."];
				
				[result insertString: subString atIndex: 0];
			}
		}
		
		child = parent;
		first = NO;
	}
	while( (parent = [parent parent]));
	
	// NSLog( result);
	// Example (0008,1111)[0].(0010,0010)
	
	return result;
}

-(NSArray*) arrayOfFiles
{
	int result;
	
	result = editingLevel;
	
	[[NSUserDefaults standardUserDefaults] setInteger: editingLevel forKey: @"editingLevel"];
	
	switch ( result) 
	{
		case 0:
			NSLog( @"image level");
			return [NSArray arrayWithObject: imObj];
		break;
		
		case 1:
			NSLog( @"series level");
			
			NSManagedObject	*series = [imObj valueForKey:@"series"];
			
			NSArray	*images = [[BrowserController currentBrowser] childrenArray: series];
			
			return images;
		break;
		
		case 2:
			{
			NSLog( @"study level");
			
			NSArray	*allSeries =  [[BrowserController currentBrowser] childrenArray: [imObj valueForKeyPath:@"series.study"]];
			NSMutableArray *result = [NSMutableArray array];
			
			for(id loopItem in allSeries)
			{
				[result addObjectsFromArray: [[BrowserController currentBrowser] childrenArray: loopItem]];
			}
			
			return result;
			}
		break;
			
		case 3:
			{
			NSLog( @"patient level");
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientID == %@)", [imObj valueForKeyPath:@"series.study.patientID"]];
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[BrowserController.currentBrowser.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
			[dbRequest setPredicate: predicate];
			
			[BrowserController.currentBrowser.database.managedObjectContext lock];
			
			NSError	*error = nil;
			NSMutableArray *result = [NSMutableArray array];
			NSArray *studiesArray = nil;
			
			@try 
			{
				studiesArray = [BrowserController.currentBrowser.database.managedObjectContext executeFetchRequest:dbRequest error:&error];
			}
			@catch (NSException * e) 
			{
                N2LogExceptionWithStackTrace(e);
			}
			
			[BrowserController.currentBrowser.database.managedObjectContext unlock];
			
			if ([studiesArray count] > 0)
			{
				for( NSManagedObject *s in studiesArray)
				{
					NSArray	*allSeries =  [[BrowserController currentBrowser] childrenArray: s];
					
					for( NSManagedObject *w in allSeries)
					{
						[result addObjectsFromArray: [[BrowserController currentBrowser] childrenArray: w]];
					}
				}
			}
			
			return result;
			}
		break;
	}
	
	return nil;
}

- (NSArray*) updateDB:(NSArray*) files objects: (NSArray*) objects
{
	[DCMPix purgeCachedDictionaries];
	
	dontClose = YES;
	
	NSArray *addedObjects = [BrowserController.currentBrowser.database addFilesAtPaths:files postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:NO importedFiles:NO returnArray:YES];
   
    addedObjects = [BrowserController.currentBrowser.database objectsWithIDs: addedObjects];
    
	if( objects)
	{
		NSMutableArray *previousSeries = [NSMutableArray array];
		NSMutableArray *newSeries = [NSMutableArray array];
		
		for( NSManagedObject *image in objects)
		{
			if( [previousSeries containsObject: [image valueForKey: @"series"]] == NO)
				[previousSeries addObject: [image valueForKey: @"series"]];
		}
		
		for( NSManagedObject *image in addedObjects)
		{
			if( [newSeries containsObject: [image valueForKey: @"series"]] == NO)
				[newSeries addObject: [image valueForKey: @"series"]];
		}
		
		for( NSManagedObject *series in newSeries)
		{
			if( [previousSeries containsObject: series] == NO)
			{
				[previousSeries removeAllObjects];
				break;
			}
		}
		
		if( [previousSeries count] != [newSeries count])
		{
			// The database structure changed because of these modifications -> Delete the previous objects WITHOUT deleting the files : we have the SAME original files
			
			for( NSManagedObject *image in objects)
				[image setValue: [NSNumber numberWithBool: NO] forKey: @"inDatabaseFolder"];
			
			[[BrowserController currentBrowser] proceedDeleteObjects: objects];
			
			[self updateDB: files objects: nil];
			
			[[self window] close];
		}
	}
	
	dontClose = NO;
	
	return addedObjects;
}

- (IBAction) executeAdd:(id) sender
{
	if( [sender tag])
    {
		NSScanner	*hexscanner;
	
		unsigned group = 0, element = 0;
	
		hexscanner = [NSScanner scannerWithString:[addGroup stringValue]];
		[hexscanner scanHexInt:&group];

		hexscanner = [NSScanner scannerWithString:[addElement stringValue]];
		[hexscanner scanHexInt:&element];
		
		if( group > 0)
		{
			NSMutableArray *groupsAndElements = [NSMutableArray array];
			
			NSString *path = [NSString stringWithFormat:@"(%@,%@)", [NSString stringWithFormat:@"%04x", group], [NSString stringWithFormat:@"%04x", element]];
			
			NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: srcFile] objectAtIndex: 0]];
			
			[groupsAndElements addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", path, [[[NSString alloc] initWithData: [[addValue stringValue] dataUsingEncoding: encoding allowLossyConversion: YES] encoding: encoding] autorelease]], nil]];
			
			NSMutableArray	*params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--verbose", @"--ignore-errors", nil];
			[params addObjectsFromArray:  groupsAndElements];
			
            if( modificationsToApplyArray == nil)
                modificationsToApplyArray = [[NSMutableArray alloc] init];
            
            if( modifiedFields == nil)
                modifiedFields = [[NSMutableArray alloc] init];
            
            if( modifiedValues == nil)
                modifiedValues = [[NSMutableArray alloc] init];
            
            [self willChangeValueForKey: @"modificationsToApply"];
            [modificationsToApplyArray addObjectsFromArray: groupsAndElements];
            
            DCMAttributeTag *tag = [DCMAttributeTag tagWithGroup: group element: element];
            DCMAttribute *attribute = [DCMAttribute attributeWithAttributeTag: tag];
            [attribute setValues: [NSMutableArray arrayWithObject: [addValue stringValue]]];
            
            [dcmDocument setAttribute: attribute];
            [self didChangeValueForKey: @"modificationsToApply"];
            
            [self reloadFromDCMDocument];
            
            NSString *searchGpEl = [NSString stringWithFormat:@"%@,%@", [NSString stringWithFormat:@"%04x", group], [NSString stringWithFormat:@"%04x", element]];
            
            for( int i = 0 ; i < [table numberOfRows]; i++)
            {
                if( [[[[table itemAtRow: i] attributeForName:@"attributeTag"] stringValue] isEqualToString: searchGpEl])
                {
                    [table selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
                    
                    if( [modifiedFields containsObject: [self getPath: [table itemAtRow: i]]])
                    {
                        NSUInteger index = [modifiedFields indexOfObject: [self getPath: [table itemAtRow: i]]];
                        
                        [modifiedFields removeObjectAtIndex: index];
                        [modifiedValues removeObjectAtIndex: index];
                    }
                    
                    [modifiedFields addObject: [self getPath: [table itemAtRow: i]]];
                    [modifiedValues addObject: [addValue stringValue]];
                }
            }
            
            [table reloadData];
		}
		else
		{
			NSRunAlertPanel( NSLocalizedString( @"Add DICOM Field", nil), NSLocalizedString( @"Illegal group / element values", nil), NSLocalizedString( @"OK", nil), nil, nil);
			return;
		}
	}
	
	[NSApp endSheet: addWindow returnCode:[sender tag]];
	[addWindow orderOut:sender];

}

- (IBAction) addDICOMField:(id) sender
{
	[self setGroupElement: self];
	[NSApp beginSheet: addWindow modalForWindow:[self window] modalDelegate:self didEndSelector: nil contextInfo:nil];
}

- (void) reloadFromDCMDocument
{
	NSMutableDictionary	*previousOutline = [NSMutableDictionary dictionary];
	
	for( int i = 1; i < [table numberOfRows]; i++)
	{
		id item = [table itemAtRow: i];
		
		if( [table isExpandable: item])
		{
			[previousOutline setValue: [NSNumber numberWithBool: [table isItemExpanded: item]] forKey: [self getPath: item]];
		}
	}
    
    [xmlDocument release];
    xmlDocument = [[dcmDocument xmlDocument] retain];
    
    int selectedRow = [table selectedRow];
	
	NSPoint origin = [[table superview] bounds].origin;
	
	[table reloadData];
	[table expandItem:[table itemAtRow:0] expandChildren:NO];
	
	for( int i = 1; i < [table numberOfRows]; i++)
	{
		id item = [table itemAtRow: i];
		
		if( [table isExpandable: item])
		{
			NSNumber *num = [previousOutline valueForKey: [self getPath: item]];
			
			if( [num boolValue]) [table expandItem: item];
		}
	}
	
	[table selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow] byExtendingSelection: NO];
	[[tableScrollView contentView] scrollToPoint: origin];
	[tableScrollView reflectScrolledClipView: [tableScrollView contentView]];
	[table setNeedsDisplay];
	[[self window] makeFirstResponder: table];
}

-(void) reload:(id) sender // reloadFromFile
{
	NSMutableDictionary	*previousOutline = [NSMutableDictionary dictionary];
	int i;
	
	for( i = 1; i < [table numberOfRows]; i++)
	{
		id item = [table itemAtRow: i];
		
		if( [table isExpandable: item])
		{
			[previousOutline setValue: [NSNumber numberWithBool: [table isItemExpanded: item]] forKey: [self getPath: item]];
		}
	}

	[xmlDocument release];
    [dcmDocument release];
    
    dcmDocument = [[DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO] retain];
    xmlDocument = [[dcmDocument xmlDocument] retain];
	
	int selectedRow = [table selectedRow];
	
	NSPoint origin = [[table superview] bounds].origin;
	
	[table reloadData];
	[table expandItem:[table itemAtRow:0] expandChildren:NO];
	
	for( i = 1; i < [table numberOfRows]; i++)
	{
		id item = [table itemAtRow: i];
		
		if( [table isExpandable: item])
		{
			NSNumber *num = [previousOutline valueForKey: [self getPath: item]];
			
			if( [num boolValue]) [table expandItem: item];
		}
	}
	
	[table selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow] byExtendingSelection: NO];
	[[tableScrollView contentView] scrollToPoint: origin];
	[tableScrollView reflectScrolledClipView: [tableScrollView contentView]];
	[table setNeedsDisplay];
	[[self window] makeFirstResponder: table];
	
	[viewer checkEverythingLoaded];
	
	int fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath: srcFile error: nil] valueForKey: NSFileSize] longLongValue] / 1024L;
	
	if( viewer)
		[[self window] setTitle: [NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@ (%d KB)", nil), [[viewer window] title], fileSize]];
	else
		[[self window] setTitle: [NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@ (%d KB)", nil), srcFile, fileSize]];
		
	dontClose = NO;
}

-(void) exportXML:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
	
    [panel setCanSelectHiddenExtension:NO];
    [panel setAllowedFileTypes:@[@"xml"]];
    
    panel.nameFieldStringValue = [NSString stringWithFormat: @"%@ - %@", imObj.series.study.name, imObj.series.study.studyName];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [[xmlDocument XMLString] writeToFile:panel.URL.path atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    }];
}

-(void) exportText:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
	
    [panel setCanSelectHiddenExtension:NO];
    [panel setAllowedFileTypes:@[@"txt"]];
    
    panel.nameFieldStringValue = [NSString stringWithFormat: @"%@ - %@", imObj.series.study.name, imObj.series.study.studyName];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [[dcmDocument description] writeToFile:panel.URL.path atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    }];
}

+ (XMLController*) windowForViewer: (ViewerController*) v
{
	// Check if we have already a window displaying this ManagedObject
	
	NSArray				*winList = [NSApp windows];
	
	for( NSWindow *w in winList)
	{
		if( [[w windowController] isKindOfClass:[XMLController class]])
		{
			if( [[w windowController] viewer] == v)
				return [w windowController];
		}
	}
	
	return nil;
}

- (void) changeImageObject:(DicomImage*) image
{
	if( image == imObj) return;
	
    int selectedRow = [table selectedRow];
	NSPoint origin = [[table superview] bounds].origin;
    
	[table deselectAll: self];
	
	[imObj release];
	imObj = [image retain];
	
	[srcFile release];
	srcFile = [[image valueForKey:@"completePath"] retain];
	
	[xmlDocument release];
	xmlDocument = nil;
    [dcmDocument release];
    dcmDocument = nil;
	
	if([DicomFile isDICOMFile:srcFile])
	{
//        NSTask *theTask = [[[NSTask alloc] init] autorelease];
//        
//        NSPipe *thePipe = [NSPipe pipe];
//        
//        [theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcm2xml"]];
//        [theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
//        [theTask setArguments: [NSMutableArray arrayWithObject: srcFile]];
//        [theTask setStandardOutput: thePipe];
//        [theTask launch];
//        
//        NSData *resData = [[thePipe fileHandleForReading] readDataToEndOfFile];
//        
//        while( [theTask isRunning])
//            [NSThread sleepForTimeInterval: 0.1];
//        
//        NSString *resString = [[[NSString alloc] initWithData:resData encoding: NSUTF8StringEncoding] autorelease];
//        
//        NSLog( @"%@", resString);
//
//        xmlDocument = [[NSXMLDocument alloc] initWithData:resData  options: 0 error: nil];
        
        dcmDocument = [[DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO] retain];
        xmlDocument = [[dcmDocument xmlDocument] retain];
        
		isDICOM = YES;
	}
	#ifndef OSIRIX_LIGHT
	else if([DicomFile isFVTiffFile:srcFile])
	{
		xmlDocument = XML_from_FVTiff(srcFile);
	}
	else if([DicomFile isNIfTIFile:srcFile])
	{
		xmlDocument = [[DicomFile getNIfTIXML:srcFile] retain];
	}
	#endif
	else
	{
		dcmDocument = [[DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO] retain];
		
		if( dcmDocument)
		{
			xmlDocument = [[dcmDocument xmlDocument] retain];
			isDICOM = YES;
		}
		else
		{
			NSXMLElement *rootElement = [[NSXMLElement alloc] initWithName:@"Unsupported Meta-Data"];
			xmlDocument = [[NSXMLDocument alloc] initWithRootElement:rootElement];
			[rootElement release];
		}
	}
	
	[table reloadData];
	[table expandItem:[table itemAtRow:0] expandChildren:NO];
	
    [table selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow] byExtendingSelection: NO];
	[[tableScrollView contentView] scrollToPoint: origin];
	[tableScrollView reflectScrolledClipView: [tableScrollView contentView]];
	[table setNeedsDisplay];
	[[self window] makeFirstResponder: table];
    
	if( [validatorWindow isVisible])
	{
		[self verify: self];
	}
}

- (void)refresh:(NSNotification*) notif;
{
	DCMView *view = [notif object];
	
	if( dontListenToIndexChange) return;
	
	if( [view is2DViewer] && [view windowController] == viewer)
		[self changeImageObject: [viewer currentImage]];
}

-(id) initWithImage:(DicomImage*) image windowName:(NSString*) name viewer:(ViewerController*) v
{
    if( image == nil)
        return nil;
    
	if (self = [super initWithWindowNibName: @"XMLViewer"])
	{
		[self setMagnetic: YES];
		
		allowSelectionChange = YES;
		editingLevel = [[NSUserDefaults standardUserDefaults] integerForKey: @"editingLevel"];
		
		viewer = [v retain];
		
		[self changeImageObject: image];
		
		int fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath: srcFile error: nil] valueForKey: NSFileSize] longLongValue] / 1024L;
		
		if( viewer)
			[[self window] setTitle: [NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@ (%d KB)", nil), [[viewer window] title], fileSize]];
		else
			[[self window] setTitle: [NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@ (%d KB)", nil), srcFile, fileSize]];
		
		[[self window] setFrameAutosaveName:@"XMLWindow"];
		[[self window] setDelegate:self];
		
		[table expandItem:[table itemAtRow:0] expandChildren:NO];
		
		[search setRecentsAutosaveName:@"xml meta data search"];
		
		[[self window] setRepresentedFilename: srcFile];
		
		dictionaryArray = [[NSMutableArray array] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(CloseViewerNotification:) name: OsirixCloseViewerNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(refresh:) name:OsirixDCMViewIndexChangedNotification object:nil];
        
        [self setupToolbar];
	}
	return self;
}

-(void) CloseViewerNotification:(NSNotification*) note
{
	if( dontClose) return;
	
	if( [note object] == viewer)
	{
		[viewer release];
        viewer = nil;
	}
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[viewer release];
	[dictionaryArray release];
	[imObj release];
	[srcFile release];
	
    [xmlDcmData release];
    
    [xmlData release];
	
	[xmlDocument release];
    [dcmDocument release];
	[toolbar setDelegate: nil];
	[toolbar release];
	
    [modificationsToApplyArray release];
    [modifiedFields release];
    [modifiedValues release];
    
    [super dealloc];
}

- (BOOL)windowShouldClose:(id)sender
{
    if( editingActivated == YES && modifiedValues.count > 0)
    {
        if( NSRunInformationalAlertPanel( NSLocalizedString( @"Cancel modifications", nil), NSLocalizedString(@"Are you sure you want to close the window? The modifications to DICOM fields have not been applied. The DICOM files will NOT be modified.", nil), NSLocalizedString(@"Close Window", nil), NSLocalizedString(@"Continue Editing", nil), nil) == NSAlertDefaultReturn)
        {
            return YES;
        }
        else
            return NO;
    }
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    table.dataSource = nil;
    table.delegate = nil;
    
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[self autorelease];
}

- (id) scanThrough: (id) main forString: (NSString*) s
{
	for( int i = 0; i < [main childCount] ; i++)
	{
		id item = [main childAtIndex: i];
		
		if( [item childCount] > 0)
		{
			id subItem = [self scanThrough: item forString: s];
			if( subItem)
			{
				[tree addObject: item];
				return subItem;
			}
		}
		
        if( [self item: item containsString: s])
            return item;
	}
    
	return nil;
}

- (IBAction) setSearchString:(id) sender
{
	[table reloadData];
	
	if( [[search stringValue] length] > 0)
	{
		tree = [NSMutableArray array];
		 
		id item = [self scanThrough: xmlDocument forString: [search stringValue]];
		
        if( item)
        {
            if( [tree count] > 0)
            {
                for( long i = (long)[tree count]-1; i >= 0; i--)
                    [table expandItem: [tree objectAtIndex: i]];
            }
            
            if( [table rowForItem: item] >= 0)
                [table scrollRowToVisible: [table rowForItem: item]];
            else if( [table rowForItem: [item parent]] >= 0)
                [table scrollRowToVisible: [table rowForItem: [item parent]]];
            else
                for( id item in tree)
                {
                    if( [table rowForItem: [item parent]] >= 0)
                    {
                        [table scrollRowToVisible: [table rowForItem: [item parent]]];
                        break;
                    }
                }
        }
        tree = nil;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{

        if( item == nil)
        {
            return [xmlDocument childCount];
        }
        else
        {
            return [item childCount];
        }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if( [[item valueForKey: @"name"] isEqualToString: @"value"])
		return NO;
	else
	{
		if([item childCount] == 1 && [[[[item children] objectAtIndex:0] valueForKey:@"name"] isEqualToString:@"value"])
			return NO;
		else if([item childCount] == 1 && [[[item children] objectAtIndex:0] kind] == NSXMLTextKind)
			return NO;
		else if([item childCount] == 0)
			return NO;
		else
			return YES;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
        if( item == nil)
        {
            return [xmlDocument childAtIndex:index];
        }
        else
        {
			return [item childAtIndex:index];
        }
}

- (BOOL) item: (id) item containsString: (NSString*) s
{
	NSRange range;
	BOOL found = NO;
	
	if( found == NO)
	{
		@try
		{
            if( [item valueForKey:@"name"])
            {
                range = [[item valueForKey:@"name"] rangeOfString: s options: NSCaseInsensitiveSearch];
                if( range.location != NSNotFound)
                    found = YES;
            }
		}
		@catch (NSException *e)
		{
		}
	}
	
	if( found == NO)
	{
		@try
		{
            if( [item valueForKey:@"attributeTag"])
            {
                range = [[item valueForKey:@"attributeTag"] rangeOfString: s options: NSCaseInsensitiveSearch];
                if( range.location != NSNotFound)
                    found = YES;
            }
		}
		@catch (NSException *e)
		{
		}
	}
	
	if( found == NO)
	{
		@try
		{
            if( [item valueForKey:@"stringValue"])
            {
                range = [[item valueForKey:@"stringValue"] rangeOfString: s options: NSCaseInsensitiveSearch];
                if( range.location != NSNotFound)
                    found = YES;
            }
		}
		@catch (NSException *e)
		{
		}
	}
    
    if( found == NO)
	{
		@try
		{
            if( [item valueForKey:@"objectValue"])
            {
                range = [[item valueForKey:@"objectValue"] rangeOfString: s options: NSCaseInsensitiveSearch];
                if( range.location != NSNotFound)
                    found = YES;
            }
		}
		@catch (NSException *e)
		{
		}
	}
    
	return found;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	BOOL found = NO;
	
	if( [[search stringValue] isEqualToString:@""] == NO)
	{
		found = [self item: item containsString: [search stringValue]];
		
		if( found)
		{
			[cell setTextColor: [NSColor blackColor]];
			[cell setFont:[NSFont boldSystemFontOfSize:12]];
		}
		else
		{
			[cell setTextColor: [NSColor grayColor]];
			[cell setFont:[NSFont systemFontOfSize:12]];
		}
	}
	else
	{
		[cell setTextColor: [NSColor blackColor]];
		[cell setFont:[NSFont systemFontOfSize:12]];
	}
	[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
    
     if( [modifiedFields containsObject: [self getPath: item]])
         [cell setTextColor: [NSColor redColor]];
}

- (void) traverse: (NSXMLNode*) node string:(NSMutableString*) string
{
	int i;
	
	for( i = 0; i < [node childCount]; i++)
	{
		if( [[node childAtIndex: i] stringValue] && [[node childAtIndex: i] childCount] == 0)
		{
			if( [string length]) [string appendFormat:@"\\%@", [[node childAtIndex: i] stringValue]];
			else [string appendString: [[node childAtIndex: i] stringValue]];
		}
		
		if( [[node childAtIndex: i] childCount])
			[self traverse: [node childAtIndex: i] string: string];
	}
}

- (NSString*) stringsSeparatedForNode:(NSXMLNode*) node
{
	if( [node childCount] == 0) return [node valueForKey:@"stringValue"];
	
	NSMutableString	*string = [NSMutableString string];
	
	[self traverse: node string: string];
	
	return string;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *identifier = [tableColumn identifier];
    
	if ([identifier isEqualToString:@"attributeTag"])
	{
		if( [item attributeForName:@"group"] && [item attributeForName:@"element"])
			return [NSString stringWithFormat:@"%@,%@", [[item attributeForName:@"group"] stringValue], [[item attributeForName:@"element"] stringValue]];
	}
	else if( [identifier isEqualToString:@"stringValue"])
	{
		if( [outlineView rowForItem: item] != 0)
        {
            if( [modifiedFields containsObject: [self getPath: item]])
                return [modifiedValues objectAtIndex: [modifiedFields indexOfObject: [self getPath: item]]];
			else
                return [self stringsSeparatedForNode: item];
        }
	}
    else
    {
        if( [modifiedFields containsObject: [self getPath: item]])
        {
            if( [modifiedValues objectAtIndex: [modifiedFields indexOfObject: [self getPath: item]]] == [NSNull null])
                return [NSString stringWithFormat: NSLocalizedString( @"%@ (to be deleted)", nil), [item valueForKey:identifier]];
        }
        
        return [item valueForKey:identifier];
	}	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return YES;
	/*
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ALLOWDICOMEDITING"] == NO) return NO;
	
	if( isDICOM == NO) return NO;
	
	if( [[NSFileManager defaultManager] isWritableFileAtPath: [imObj valueForKey:@"completePath"]] == NO) return NO;
	
	if( self.editingActivated == NO) return NO;
	
	if( [[tableColumn identifier] isEqualToString: @"stringValue"])
	{
        if( [xmlDocument rootElement] == [item parent]) // Only elements at root level
        {
            if( [item attributeForName:@"group"] && [item attributeForName:@"element"])
            {
                if( [[[item attributeForName:@"group"] stringValue] intValue] != 0)	//[[[item attributeForName:@"group"] stringValue] intValue] != 2 && 
                {
                    return YES;
                }
            }
            else if( [[[[item children] objectAtIndex: 0] children] count] == 0)	// A multiple value
            {
                return YES;
            }
            else NSLog( @"Sequence");
		}
        
		return NO;
	}
	else
		return NO;
     */
}

- (IBAction) switchEditing: (id) sender
{
    if( self.editingActivated == NO)
    {
        if( [[NSFileManager defaultManager] isWritableFileAtPath: [imObj valueForKey:@"completePath"]] == NO)
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Editing", nil), NSLocalizedString(@"This file is not editable. It is a read-only file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            editingActivated = NO;
        }
        else if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ALLOWDICOMEDITING"] == NO)
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Editing", nil), NSLocalizedString(@"DICOM editing is deactivated.\r\rSee General - Preferences to activate it.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            editingActivated = NO;
        }
        else if( isDICOM == NO)
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Editing", nil), NSLocalizedString(@"DICOM editing is allowed only on DICOM files.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            
            editingActivated = NO;
        }
        else
        {
            if( showWarning)
            {
                NSString *exampleAlertSuppress = @"DICOM Editing Warning";
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if ([defaults boolForKey:exampleAlertSuppress])
                {
                }
                else
                {
                    NSAlert* alert = [[NSAlert new] autorelease];
                    [alert setMessageText: NSLocalizedString(@"DICOM Editing", nil)];
                    [alert setInformativeText: NSLocalizedString(@"DICOM editing is now activated. You can edit any DICOM fields.\r\rSelect at which level you want to apply the changes (this image only, this series or the entire study.\r\rWarning !\rModifying DICOM fields can corrupt the DICOM files!\r\"With Great Power, Comes Great Responsibility\"", nil)];
                    [alert setShowsSuppressionButton:YES];
                    [alert runModal];
                    if ([[alert suppressionButton] state] == NSOnState)
                    {
                        [defaults setBool:YES forKey:exampleAlertSuppress];
                    }
                }
                
                showWarning = NO;
            }
            
            editingActivated = !editingActivated;
        }
    }
    else if( editingActivated == YES && modifiedValues.count > 0)
    {
        if( NSRunInformationalAlertPanel( NSLocalizedString( @"Cancel modifications", nil), NSLocalizedString(@"Are you sure you want to stop editing the fields? The modifications have not been applied. The DICOM files will NOT be modified.", nil), NSLocalizedString(@"Cancel Modifications", nil), NSLocalizedString(@"Continue Editing", nil), nil) == NSAlertDefaultReturn)
		{
            [modificationsToApplyArray removeAllObjects];
            [modifiedValues removeAllObjects];
            [modifiedFields removeAllObjects];
            
            [self reload: self];
            
            editingActivated = !editingActivated;
        }
        else
            editingActivated = YES;
    }
    else
        editingActivated = !editingActivated;
    
    [sender setState: editingActivated];
    
    [self willChangeValueForKey: @"editingActivated"];
    [self didChangeValueForKey: @"editingActivated"];
}

- (void) setObject:(NSArray*) array
{
	NSMutableArray *groupsAndElements = [NSMutableArray array];
	
	id item = [array objectAtIndex: 0];
	id object = [array objectAtIndex: 1];
	
	NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: srcFile] objectAtIndex: 0]];
	
	object = [[[NSString alloc] initWithData: [object dataUsingEncoding: encoding allowLossyConversion: YES] encoding: encoding] autorelease];
	
	if( [table rowForItem: item] > 0)
	{
		NSString *path = [self getPath: item];
		
		if( [[item attributeForName:@"group"] stringValue] && [[item attributeForName:@"element"] stringValue])
		{
			[groupsAndElements addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", path, object], nil]];
		}
		else // A multiple value or a sequence, not an element
		{
			if( [[[[item children] objectAtIndex: 0] children] count] == 0)
			{
				int index = [[path substringWithRange: NSMakeRange( [path length]-2, 1)] intValue];
				
				path = [path substringToIndex: [path length]-3];
				
				NSLog( @"%@", path);
				NSLog( @"%d", index);
				
				NSMutableArray	*values = [NSMutableArray arrayWithArray: [[self stringsSeparatedForNode: [item parent]] componentsSeparatedByString:@"\\"]];
				
				[values replaceObjectAtIndex: index withObject: object];
				
				[groupsAndElements addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", path, [values componentsJoinedByString:@"\\"]], nil]];
			}
			else
			{
				NSLog( @"A sequence: not editable");
			}
		}
	}
	
	if( [groupsAndElements count])
	{
		if( modificationsToApplyArray == nil)
            modificationsToApplyArray = [[NSMutableArray alloc] init];
        
        if( modifiedFields == nil)
            modifiedFields = [[NSMutableArray alloc] init];
        
        if( modifiedValues == nil)
            modifiedValues = [[NSMutableArray alloc] init];
        
        [self willChangeValueForKey: @"modificationsToApply"];
        [modificationsToApplyArray addObjectsFromArray: groupsAndElements];
        
        if( [modifiedFields containsObject: [self getPath: item]])
        {
            NSUInteger index = [modifiedFields indexOfObject: [self getPath: item]];
            
            [modifiedFields removeObjectAtIndex: index];
            [modifiedValues removeObjectAtIndex: index];
        }
        
        [modifiedFields addObject: [self getPath: item]];
        [modifiedValues addObject: object];
        [self didChangeValueForKey: @"modificationsToApply"];
        
        [table reloadData];
	}
	
	allowSelectionChange = YES;
}

- (BOOL) modificationsToApply
{
    if( modificationsToApplyArray.count)
        return YES;
    else
        return NO;
}

- (IBAction) applyModifications:(id)sender
{
    if( modificationsToApplyArray.count)
    {
        /*
        NSMutableArray	*params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--verbose", @"--ignore-errors", nil];
		[params addObjectsFromArray: modificationsToApplyArray];
		*/
         
		NSArray *objects = [self arrayOfFiles];
		NSMutableArray *files = [NSMutableArray arrayWithArray: [objects valueForKey:@"completePath"]];
		
		if( files)
		{
			[files removeDuplicatedStrings];
            
			//[params addObjectsFromArray: files];
			
			WaitRendering *wait = nil;
			if( [files count] > 1)
			{
				wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating Files...", nil)];
				[wait showWindow:self];
			}
			
            [self retain];
            
			@try
			{
                //NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: srcFile] objectAtIndex: 0]];
				//[XMLController modifyDicom: params encoding: encoding];
                
                
                
                NSMutableArray* tagAndValues = [NSMutableArray array];
				
                for (int i = 0; i < [modifiedFields count]; i++)
                {
                    NSString* field = [modifiedFields objectAtIndex:i];
                    NSString* value = [modifiedValues objectAtIndex:i];
                    
                    [tagAndValues addObject:[NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:field],(value?value:@""),nil]];
                }
                
                [XMLController modifyDicom:tagAndValues dicomFiles:files];
                
                
                
				for( id loopItem in files)
					[[NSFileManager defaultManager] removeItemAtPath:[loopItem stringByAppendingString:@".bak"] error:NULL];
				
				[self updateDB: files objects: objects];
			}
			@catch (NSException * e)
			{
				NSLog(@"xml setObject: %@", e);
			}
			[wait close];
			[wait autorelease];
			wait = nil;
			
            if( [self.window isVisible]) // If DB fields were modified : the database window will close the XML editor
                [self reload: self];
            
            [self autorelease];
		}
        
        [modificationsToApplyArray removeAllObjects];
        [modifiedFields removeAllObjects];
        [modifiedValues removeAllObjects];
    }
}

- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView
{
	return allowSelectionChange;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id previousValue = [self outlineView: outlineView objectValueForTableColumn: tableColumn byItem: item];
	
	if( [[tableColumn identifier] isEqualToString: @"stringValue"] == NO)
	{
		if( [previousValue isEqual: object] == NO)
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Editing", nil), NSLocalizedString(@"You can only edit the 'Content' column.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return;
	}
	
	if( [previousValue isEqual: object] == NO)
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ALLOWDICOMEDITING"] && isDICOM && self.editingActivated && [[NSFileManager defaultManager] isWritableFileAtPath: [imObj valueForKey:@"completePath"]])
		{
			allowSelectionChange = NO;
			[self performSelector:@selector(setObject:) withObject: [NSArray arrayWithObjects: item, object, nil] afterDelay: 0];
		}
		else
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ALLOWDICOMEDITING"] == NO || self.editingActivated == NO)
				NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Editing", nil), NSLocalizedString(@"Activate DICOM editing to change the values.", nil), NSLocalizedString(@"OK", nil), nil, nil);
			else
				NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Editing", nil), NSLocalizedString(@"DICOM editing not possible for this file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
	}
}

- (IBAction) validatorWebSite:(id) sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.dclunie.com/dicom3tools/dciodvfy.html"]];
}

- (IBAction) verify:(id) sender
{
	if( isDICOM == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Validator", nil), NSLocalizedString(@"DICOM Validator requires a DICOM file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	NSTask *theTask = [[NSTask alloc] init];

	NSPipe *thePipe = [NSPipe pipe];
	
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dciodvfy"]];
	[theTask setArguments: [NSMutableArray arrayWithObject: srcFile]];
	[theTask setStandardError: thePipe];
	[theTask launch];
	
	NSData *resData = [[thePipe fileHandleForReading] readDataToEndOfFile];
	
    while( [theTask isRunning])
        [NSThread sleepForTimeInterval: 0.1];
	
	NSString *resString = nil;
    
    resString = [[[NSString alloc] initWithData:resData encoding: NSUTF8StringEncoding] autorelease];
    
    if( resString == nil)
        resString = [[[NSString alloc] initWithData:resData encoding: NSASCIIStringEncoding] autorelease];
	
	[validatorText setString: resString];
	
	[validatorWindow makeKeyAndOrderFront: self];
	[validatorWindow setTitle: srcFile];
	
	[theTask release];
}

- (IBAction) sortSeries: (id) sender
{
	NSIndexSet* selectedRowIndexes = [table selectedRowIndexes];
	
	if( [selectedRowIndexes count] != 1)
	{
		NSRunAlertPanel( NSLocalizedString( @"Sort Series Images", nil) , NSLocalizedString( @"Select an element to use to sort the images of the series.", nil), NSLocalizedString( @"OK", nil), nil, nil);
		return;
	}
	
	int index = [selectedRowIndexes firstIndex];
	id item = [table itemAtRow: index];
	
	if( index > 0 && item && [[item attributeForName:@"group"] objectValue] && [[item attributeForName:@"element"] objectValue])
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString( @"Sort Series Images", nil), NSLocalizedString(@"Are you sure you want to re-sort the series images according to this field?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
		{
			unsigned gr = 0, el = 0;
			
			dontListenToIndexChange = YES;
			
			@try
			{		
				[[NSScanner scannerWithString: [[item attributeForName:@"group"] objectValue]] scanHexInt:&gr];
				[[NSScanner scannerWithString: [[item attributeForName:@"element"] objectValue]] scanHexInt:&el];
				
				if( gr > 0)
				{
					NSLog( @"Sort by 0x%04X / 0x%04X", gr, el);
					[viewer sortSeriesByDICOMGroup: gr element: el];
				}
			}
			
			@catch( NSException *e)
			{
				NSLog( @"%@", e);
				NSRunAlertPanel( NSLocalizedString( @"Sort Series Images", nil) , NSLocalizedString( @"Select an element to use to sort the images of the series.", nil), NSLocalizedString( @"OK", nil), nil, nil);
			}
			
			dontListenToIndexChange = NO;
		}
	}
	else NSRunAlertPanel( NSLocalizedString( @"Sort Series Images", nil) , NSLocalizedString( @"Select an element to use to sort the images of the series.", nil), NSLocalizedString( @"OK", nil), nil, nil);
}

- (void)keyDown:(NSEvent *)event
{
	if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	
	if( self.editingActivated && [[NSFileManager defaultManager] isWritableFileAtPath: [imObj valueForKey:@"completePath"]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"ALLOWDICOMEDITING"] && isDICOM && (c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey))
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString( @"DICOM Editing", nil), NSLocalizedString(@"Are you sure you want to delete selected field(s)?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
		{
			NSIndexSet*			selectedRowIndexes = [table selectedRowIndexes];
			NSInteger			index;
			
			
			for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
			{
			   if ([selectedRowIndexes containsIndex:index])
			   {
					id	item = [table itemAtRow: index];
					
					if( index > 0)
					{
                        NSMutableArray *groupsAndElements = [NSMutableArray array];
						NSString *path = [self getPath: item];
						
						if( [[item attributeForName:@"group"] stringValue] && [[item attributeForName:@"element"] stringValue])
						{
							[groupsAndElements addObjectsFromArray: [NSArray arrayWithObjects: @"-e", path, nil]];
						}
						else // A multiple value or a sequence, not an element
						{
							if( [[[[item children] objectAtIndex: 0] children] count] == 0)
							{
								int index = [[path substringWithRange: NSMakeRange( [path length]-2, 1)] intValue];
								
								path = [path substringToIndex: [path length]-3];
								
								NSLog( @"%@",  path);
								NSLog( @"%d", index);
								
								NSMutableArray	*values = [NSMutableArray arrayWithArray: [[self stringsSeparatedForNode: [item parent]] componentsSeparatedByString:@"\\"]];
								
								[values removeObjectAtIndex: index];
								
								[groupsAndElements addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", path, [values componentsJoinedByString:@"\\"]], nil]];
							}
							else
							{
								NSLog( @"A sequence : not editable");
							}
						}
                        
                        if( [groupsAndElements count])
                        {
                            if( modificationsToApplyArray == nil)
                                modificationsToApplyArray = [[NSMutableArray alloc] init];
                            
                            if( modifiedFields == nil)
                                modifiedFields = [[NSMutableArray alloc] init];
                            
                            if( modifiedValues == nil)
                                modifiedValues = [[NSMutableArray alloc] init];
                            
                            [self willChangeValueForKey: @"modificationsToApply"];
                            [modificationsToApplyArray addObjectsFromArray: groupsAndElements];
                            
                            if( [modifiedFields containsObject: [self getPath: item]])
                            {
                                NSUInteger index = [modifiedFields indexOfObject: [self getPath: item]];
                                
                                [modifiedFields removeObjectAtIndex: index];
                                [modifiedValues removeObjectAtIndex: index];
                            }
                            
                            [modifiedFields addObject: [self getPath: item]];
                            [modifiedValues addObject: [NSNull null]];
                            [self didChangeValueForKey: @"modificationsToApply"];
                            
                            [table reloadData];
                        }
                    }
                }
			}
		}
	}
	else [super keyDown: event];
}

- (void)copy:(id)sender
{
	NSIndexSet*			selectedRowIndexes = [table selectedRowIndexes];
	NSMutableString*	copyString = [NSMutableString string];
	NSInteger			index;
	
	for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
       if ([selectedRowIndexes containsIndex:index])
	   {
			id	item = [table itemAtRow: index];
			
			if( [copyString length]) [copyString appendString:@"\r"];
			
			if( [[item attributeForName:@"group"] stringValue] && [[item attributeForName:@"element"] stringValue])
				[copyString appendFormat:@"%@ (%@,%@) %@", [item valueForKey: @"name"], [[item attributeForName:@"group"] stringValue], [[item attributeForName:@"element"] stringValue], [self stringsSeparatedForNode: item]];
			else
				[copyString appendFormat:@"%@ %@", [item valueForKey: @"name"], [self stringsSeparatedForNode: item]];
			
			NSLog( @"%@", [item description]);
			
			NSLog( @"---");
			
			NSLog( @"%@", [item valueForKey: @"name"]);
			
			NSLog( @"%@", [[item attributeForName:@"group"] stringValue]);
			NSLog( @"%@", [[item attributeForName:@"element"] stringValue]);
			
			NSLog( @"%@", [[item attributeForName:@"attributeTag"] stringValue]);
			
			NSLog( @"%@", [item valueForKey: @"stringValue"]);
			
			NSLog( @"---");
			
			NSLog( @"%@", [self stringsSeparatedForNode: item]);
	   }
	}
	
	NSPasteboard	*pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:self];
	[pb setString: copyString forType:NSPasteboardTypeString];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: XMLToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
    
//    [window makeKeyAndOrderFront:nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Export XML",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export XML",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Export these XML Data in a XML File",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportXML:)];
    }
	else if ([itemIdent isEqualToString: EditingToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"DICOM Editing", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"DICOM Editing", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"DICOM Editing", nil)];
		
		[toolbarItem setView: dicomEditingView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([dicomEditingView frame]), NSHeight([dicomEditingView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([dicomEditingView frame]), NSHeight([dicomEditingView frame]))];
    }
	else if ([itemIdent isEqualToString: SearchToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Search", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Search", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Search", nil)];
		
		[toolbarItem setView: searchView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([searchView frame]), NSHeight([searchView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([searchView frame]), NSHeight([searchView frame]))];
    }
	else if ([itemIdent isEqualToString: ExportTextToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Export Text", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export Text", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export these XML Data in a Text File", nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportText:)];
    }
	else if ([itemIdent isEqualToString: ExpandAllItemsToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Expand All", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Expand All Items", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Expand All Items", nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExpandAllItemsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(deepExpandAllItems:)];
    }
	else if ([itemIdent isEqualToString: CollapseAllItemsToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Collapse All", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Collapse All Items", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Collapse All Items", nil)];
		[toolbarItem setImage: [NSImage imageNamed: CollapseAllItemsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(deepCollapseAllItems:)];
    }
	else if ([itemIdent isEqualToString: SortSeriesToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Sort Images", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Sort Images", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Sort Series Images by selected element", nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"Revert.tif"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sortSeries:)];
    }
	else if ([itemIdent isEqualToString: VerifyToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Validator", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Validator", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Validate the DICOM format", nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"NSInfo"]];
		[toolbarItem setTarget: self];	
		[toolbarItem setAction: @selector(verify:)];
    }
    else 
	{
		toolbarItem = nil;
	}
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarItemForItemIdentifier:forViewer:)])
        {
            NSToolbarItem *item = [[[PluginManager plugins] objectForKey:key] toolbarItemForItemIdentifier: itemIdent forViewer: self];
            
            if( item)
                toolbarItem = item;
        }
    }
	
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	ExportToolbarItemIdentifier, 
										ExportTextToolbarItemIdentifier,
										ExpandAllItemsToolbarItemIdentifier,
										CollapseAllItemsToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										EditingToolbarItemIdentifier,
										SortSeriesToolbarItemIdentifier,
										VerifyToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										SearchToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    NSMutableArray *array = [NSMutableArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarSeparatorItemIdentifier,
										ExportToolbarItemIdentifier,
										ExportTextToolbarItemIdentifier, 
										ExpandAllItemsToolbarItemIdentifier,
										CollapseAllItemsToolbarItemIdentifier,
										EditingToolbarItemIdentifier,
										SortSeriesToolbarItemIdentifier,
										VerifyToolbarItemIdentifier,
										SearchToolbarItemIdentifier,
										nil];
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForViewer:)])
            [array addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForViewer: self]];
    }
    
    return array;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action)
	
    BOOL enable = YES;
	
	if ([[toolbarItem itemIdentifier] isEqualToString: SortSeriesToolbarItemIdentifier])
	{
		if( viewer)	enable = YES;
	}	
    
	return enable;
}

- (void) expandAllItems: (id) sender
{
	[self expandAll:NO];
}

- (void) deepExpandAllItems: (id) sender
{
	[self expandAll:YES];
}

- (void) expandAll: (BOOL) deep
{
	int i;
	for(i=0 ; i<[table numberOfRows] ; i++)
	{
		[table expandItem:[table itemAtRow:i] expandChildren:deep];
	}
}

- (void) collapseAllItems: (id) sender
{
	[self collapseAll:NO];
}

- (void) deepCollapseAllItems: (id) sender
{
	[self collapseAll:YES];
}

- (void) collapseAll: (BOOL) deep
{
	int i;
	for(i=1 ; i<[table numberOfRows]; i++) // starting from 1, so the DICOMObject is not collapsed
	{
		[table collapseItem:[table itemAtRow:i] collapseChildren:deep];
	}
}

- (IBAction) setGroupElement: (id) sender
{
	if( [dictionaryArray count] == 0) [self prepareDictionaryArray];
	
	NSScanner	*hexscanner;
	
	unsigned group = 0, element = 0;
	
	hexscanner = [NSScanner scannerWithString:[addGroup stringValue]];
	[hexscanner scanHexInt:&group];

	hexscanner = [NSScanner scannerWithString:[addElement stringValue]];
	[hexscanner scanHexInt:&element];

	[addGroup setStringValue: [NSString stringWithFormat:@"0x%04x", group]];
	[addElement setStringValue: [NSString stringWithFormat:@"0x%04x", element]];
	
	NSString	*string = [NSString stringWithFormat:@"(0x%04x,0x%04x)", group, element];
	
	
	for( id loopItem in dictionaryArray)
	{
		if( [[loopItem substringToIndex: 15] isEqualToString: string])
		{
			NSLog( @"%@",  loopItem);
			[dicomFieldsCombo setStringValue: [loopItem substringFromIndex: 16]];
			
			return;
		}
	}
	
	[dicomFieldsCombo setStringValue: @""];
}

- (IBAction) setTagName:(id) sender
{
	if( [dictionaryArray count] == 0) [self prepareDictionaryArray];
	
	NSString	*string = [sender stringValue];
	
	if( [string length] > 0)
	{
		if( [string characterAtIndex: 0] == '(')
		{
			string = [string substringFromIndex: 16];
		}
		
		[sender setStringValue: string];
		
		int gp, el;
		
		if( [self getGroupAndElementForName: string group: &gp element: &el] == 0)
		{
			[addGroup setStringValue: [NSString stringWithFormat:@"0x%04x", gp]];
			[addElement setStringValue: [NSString stringWithFormat:@"0x%04x", el]];
		}
		else
		{
			[addGroup setStringValue: @""];
			[addElement setStringValue: @""];
		}
	}
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString
{
	if( [dictionaryArray count] == 0) [self prepareDictionaryArray];
	
	if( [uncompletedString length] == 0) return nil;
	
	
	for( id loopItem in dictionaryArray)
	{
		if( [[[loopItem substringFromIndex: 16] uppercaseString] hasPrefix: [uncompletedString uppercaseString]])
		{
			return [loopItem substringFromIndex: 16];
		}
	}
	
	return nil;
}

- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if( [dictionaryArray count] == 0) [self prepareDictionaryArray];
	
	return [dictionaryArray count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	if( [dictionaryArray count] == 0) [self prepareDictionaryArray];
	
	return [dictionaryArray objectAtIndex: index];
}
@end
