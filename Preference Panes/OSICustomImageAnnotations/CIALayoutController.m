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

#import "CIALayoutController.h"
#import "CIADICOMField.h"
#import "NSPreferencePane+OsiriX.h"
#import "OSICustomImageAnnotations.h"

@implementation CIALayoutController

- (NSString*) currentModality
{
	return currentModality;
}

- (NSMutableDictionary*) annotationsLayoutDictionary
{
	return annotationsLayoutDictionary;
}

- (NSDictionary*) curDictionary
{
	return [annotationsLayoutDictionary objectForKey: currentModality];
}

- (void) reloadLayoutDictionary
{
	[annotationsLayoutDictionary release];

	if([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CUSTOM_IMAGE_ANNOTATIONS"])
		annotationsLayoutDictionary = [[NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CUSTOM_IMAGE_ANNOTATIONS"]] retain];
	else
		annotationsLayoutDictionary = [[NSMutableDictionary dictionary] retain];	
}

- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self != nil)
	{
		annotationsArray = [[NSMutableArray array] retain];
		databaseStudyFieldsArray = [[NSMutableArray array] retain];
		databaseSeriesFieldsArray = [[NSMutableArray array] retain];
		databaseImageFieldsArray = [[NSMutableArray array] retain];
		[selectedAnnotation release];
		selectedAnnotation = nil;
		
		annotationNumber = 1;
		
		[self reloadLayoutDictionary];
			
		currentModality = @"Default";
		[currentModality retain];
		
		skipTextViewDidChangeSelectionNotification = NO;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationMouseDragged:) name:@"CIAAnnotationMouseDraggedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationMouseDown:) name:@"CIAAnnotationMouseDownNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationMouseUp:) name:@"CIAAnnotationMouseUpNotification" object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:@"NSTextViewDidChangeTypingAttributesNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:@"NSTextViewDidChangeSelectionNotification" object:nil];
	}
	return self;
}

- (void)awakeFromNib
{
	int i;

	[[prefPane titleTextField] setEnabled: NO];
	[[prefPane contentTokenField] setEnabled: NO];
	[self setCustomDICOMFieldEditingEnable:NO];
	
	[[[prefPane contentTokenField] cell] setWraps:YES];
	//[[prefPane dicomNameTokenField] setTokenStyle:NSPlainTextTokenStyle];

	[[prefPane contentTokenField] setDelegate:self];

	// DICOM popup button
	if(DICOMFieldsArray) [DICOMFieldsArray release];
	DICOMFieldsArray = [[prefPane prepareDICOMFieldsArrays] mutableCopy];

	NSMenu *DICOMFieldsMenu = [[prefPane DICOMFieldsPopUpButton] menu];
	[DICOMFieldsMenu setAutoenablesItems:NO];
	
//	for (i=0; i<[[DICOMFieldsMenu itemArray] count]; i++)
//		[DICOMFieldsMenu removeItemAtIndex:i];
	[[prefPane DICOMFieldsPopUpButton] removeAllItems];
	
	NSMenuItem *item;
	item = [[[NSMenuItem alloc] init] autorelease];
	[item setTitle:NSLocalizedString( @"DICOM Fields", nil)];
	[item setEnabled:NO];
	[DICOMFieldsMenu addItem:item];
	for (i=0; i<[DICOMFieldsArray count]; i++)
	{
		item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[[DICOMFieldsArray objectAtIndex:i] title]];
		[item setRepresentedObject:[DICOMFieldsArray objectAtIndex:i]];
		[DICOMFieldsMenu addItem:item];
	}
	
	[[prefPane DICOMFieldsPopUpButton] setMenu:DICOMFieldsMenu];
	
	// Database popup button
	[self prepareDatabaseFields];
	
	NSMenu *databaseFieldsMenu = [[prefPane databaseFieldsPopUpButton] menu];
	[databaseFieldsMenu setAutoenablesItems:NO];

    [databaseFieldsMenu removeAllItems];
	
	item = [[[NSMenuItem alloc] init] autorelease];
	[item setTitle:NSLocalizedString( @"Study level", nil)];
	[item setEnabled:NO];
	[databaseFieldsMenu addItem:item];
	for (i=0; i<[databaseStudyFieldsArray count]; i++)
	{
		item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[NSString stringWithFormat:@"\t%@",[databaseStudyFieldsArray objectAtIndex:i]]];
		[item setRepresentedObject:[NSString stringWithFormat:@"study.%@",[databaseStudyFieldsArray objectAtIndex:i]]];
		[databaseFieldsMenu addItem:item];
	}

	[databaseFieldsMenu addItem:[NSMenuItem separatorItem]];	
	item = [[[NSMenuItem alloc] init] autorelease];
	[item setTitle:NSLocalizedString( @"Series level", nil)];
	[item setEnabled:NO];
	[databaseFieldsMenu addItem:item];
	for (i=0; i<[databaseSeriesFieldsArray count]; i++)
	{
		item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[NSString stringWithFormat:@"\t%@",[databaseSeriesFieldsArray objectAtIndex:i]]];
		[item setRepresentedObject:[NSString stringWithFormat:@"series.%@",[databaseSeriesFieldsArray objectAtIndex:i]]];
		[databaseFieldsMenu addItem:item];
	}
	
	[databaseFieldsMenu addItem:[NSMenuItem separatorItem]];
	item = [[[NSMenuItem alloc] init] autorelease];
	[item setTitle:NSLocalizedString( @"Image level", nil)];
	[item setEnabled:NO];
	[databaseFieldsMenu addItem:item];
	for (i=0; i<[databaseImageFieldsArray count]; i++)
	{
		item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[NSString stringWithFormat:@"\t%@",[databaseImageFieldsArray objectAtIndex:i]]];
		[item setRepresentedObject:[NSString stringWithFormat:@"image.%@",[databaseImageFieldsArray objectAtIndex:i]]];
		[databaseFieldsMenu addItem:item];
	}
	
	// Specials popup button
	NSMenu *specialFieldsMenu = [[prefPane specialFieldsPopUpButton] menu];

    [specialFieldsMenu removeAllItems];

	NSMutableArray *fields = [self specialFieldsTitles];
	NSMutableArray *localizedFields = [self specialFieldsLocalizedTitles];
	
	for (i=0; i<[fields count]; i++)
	{
		item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[localizedFields objectAtIndex:i]];
		[item setRepresentedObject:[fields objectAtIndex:i]];
		[specialFieldsMenu addItem:item];
	}

	[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
	[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
	[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
	[[prefPane specialFieldsPopUpButton] setEnabled:NO];
	[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
	[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
	
	[[prefPane addCustomDICOMFieldButton] setEnabled:NO];
	[[prefPane addDICOMFieldButton] setEnabled:NO];
	[[prefPane addDatabaseFieldButton] setEnabled:NO];
	[[prefPane addSpecialFieldButton] setEnabled:NO];
	
	[self loadAnnotationLayoutForModality:currentModality];
	
	[[prefPane contentTokenField] setTokenizingCharacterSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
	[selectedAnnotation release];
	[currentModality release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[annotationsArray release];
	[databaseStudyFieldsArray release];
	[databaseSeriesFieldsArray release];
	[databaseImageFieldsArray release];
	[annotationsLayoutDictionary release];
	
	[DICOMFieldsArray release];
	
	[super dealloc];
}

- (IBAction)addAnnotation:(id)sender;
{
	BOOL check = YES;
	if(selectedAnnotation)
		check = [self checkAnnotationContent:selectedAnnotation];

	if(check)
	{
		NSPoint center = NSMakePoint(NSMidX([layoutView bounds]), NSMidY([layoutView bounds]));
		CIAAnnotation *anAnnotation = [[CIAAnnotation alloc] initWithFrame:NSMakeRect(center.x - 75.0/2.0, center.y - 11, 75, 22)];

		if([annotationsArray count]==0) annotationNumber = 1;
		[anAnnotation setTitle:[NSString stringWithFormat:@"%@ %d", [anAnnotation title], annotationNumber++]];
        
		[annotationsArray addObject:anAnnotation];
		[layoutView addSubview:anAnnotation];
		[layoutView setNeedsDisplay:YES];
		[anAnnotation release];
        
        [self selectAnnotation:anAnnotation];
	}
}

- (IBAction)removeAnnotation:(id)sender;
{
	if(selectedAnnotation)
	{
		CIAPlaceHolder *placeHolder = [selectedAnnotation placeHolder];
	
		[annotationsArray removeObject:selectedAnnotation];
		[selectedAnnotation removeFromSuperview];
		[layoutView setNeedsDisplay:YES];

		if([selectedAnnotation placeHolder])
		{
			[placeHolder setHasFocus:NO];
			[placeHolder removeAnnotation:selectedAnnotation];
			[placeHolder updateFrameAroundAnnotations];
			[placeHolder alignAnnotations];
			[layoutView setNeedsDisplay:YES];
		}
		
		[selectedAnnotation release];
		selectedAnnotation = nil;
		[[prefPane titleTextField] setStringValue:@""];
		[[prefPane contentTokenField] setStringValue:@""];
		
		[[prefPane titleTextField] setEnabled: NO];
		[[prefPane contentTokenField] setEnabled: NO];
		[self setCustomDICOMFieldEditingEnable:NO];
		
		[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
		[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
		[[prefPane specialFieldsPopUpButton] setEnabled:NO];
		[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
	unichar c = [[theEvent characters] characterAtIndex:0];
	if(c==NSDeleteCharacter)
	{
		[self removeAnnotation:self];
		return;
	}
	[super keyDown:theEvent];
}

- (IBAction)setTitle:(id)sender;
{
	if(selectedAnnotation)
	{
		[selectedAnnotation setTitle:[sender stringValue]];
		
		[[selectedAnnotation placeHolder] updateFrameAroundAnnotations];
		[layoutView updatePlaceHolderOrigins];
		[[selectedAnnotation placeHolder] alignAnnotations];
						
		[layoutView setNeedsDisplay:YES];
	}
}

- (void)annotationMouseDragged:(NSNotification *)aNotification;
{
	CIAAnnotation *annotation = (CIAAnnotation*)[aNotification object];
	if([annotation placeHolder])
	{
		CIAPlaceHolder *aPlaceHolder = [annotation placeHolder];
		[aPlaceHolder removeAnnotation:annotation];
		[aPlaceHolder alignAnnotations];
		[aPlaceHolder updateFrameAroundAnnotations];
	}

	NSArray *placeHolders = [layoutView placeHolderArray];	
	int i;
	for (i=0; i<[placeHolders count]; i++)
	{
		[[placeHolders objectAtIndex:i] updateFrameAroundAnnotations];
	}
	[layoutView updatePlaceHolderOrigins];
	
	[layoutView setNeedsDisplay:YES];
	
	[self highlightPlaceHolderForAnnotation:annotation];
}

- (void)annotationMouseDown:(NSNotification *)aNotification;
{
	CIAAnnotation *annotation = (CIAAnnotation*)[aNotification object];
	
	BOOL check = YES;
	if(selectedAnnotation && annotation != selectedAnnotation)
		check = [self checkAnnotationContent:selectedAnnotation];
	
	[self highlightPlaceHolderForAnnotation:annotation];
	if(check)
	{
		[self selectAnnotation:annotation];
	}
}

- (void)annotationMouseUp:(NSNotification *)aNotification;
{
	CIAAnnotation *annotation = (CIAAnnotation*)[aNotification object];

	BOOL annotationOutOfPlaceHolder = YES;
	
	NSArray *placeHolders = [layoutView placeHolderArray];
	CIAPlaceHolder *currentPlaceHolder;
	int i;
	for (i=0; i<[placeHolders count]; i++)
	{
		currentPlaceHolder = [placeHolders objectAtIndex:i];
		if([currentPlaceHolder hasFocus] && ![currentPlaceHolder containsAnnotation:annotation])
		{
			// if current place holder contains annotations, we are going to insert the new annotation inbetween the other
			int index=-1;

			if([[currentPlaceHolder annotationsArray] count])
			{
				CIAAnnotation *annotation1, *annotation2;
				
				if([[[currentPlaceHolder annotationsArray] objectAtIndex:0] frame].origin.y <= [annotation frame].origin.y)
					index = 0;
					
				int j;
				for (j=0; j<(long) [[currentPlaceHolder annotationsArray] count]-1; j++)
				{
					annotation1 = [[currentPlaceHolder annotationsArray] objectAtIndex:j];
					annotation2 = [[currentPlaceHolder annotationsArray] objectAtIndex:j+1];
					if([annotation1 frame].origin.y == [annotation frame].origin.y)
						index = j;
					else if([annotation1 frame].origin.y > [annotation frame].origin.y && [annotation2 frame].origin.y <= [annotation frame].origin.y)
						index = j+1;
				}
			}
			
			if(index>=0)
				[currentPlaceHolder insertAnnotation:annotation atIndex:index];
			else
				[currentPlaceHolder addAnnotation:annotation];
			annotationOutOfPlaceHolder = NO;
			break;
		}
		if([currentPlaceHolder containsAnnotation:annotation]) annotationOutOfPlaceHolder = NO;
	}
	
	if(annotationOutOfPlaceHolder)
	{
		[[annotation placeHolder] removeAnnotation:annotation];
		[[annotation placeHolder] alignAnnotations];
	}
	
	for (i=0; i<[placeHolders count]; i++)
	{
		[[placeHolders objectAtIndex:i] alignAnnotations];
		[[placeHolders objectAtIndex:i] updateFrameAroundAnnotations];
		
		[layoutView setNeedsDisplay:YES];
	}
	
	[self highlightPlaceHolderForAnnotation:selectedAnnotation];
}

- (void)highlightPlaceHolderForAnnotation:(CIAAnnotation*)anAnnotation;
{
	NSRect annotationFrame = [anAnnotation frame];
	float annotationFrameArea = annotationFrame.size.width * annotationFrame.size.height;
	
	NSArray *placeHolders = [layoutView placeHolderArray];
	NSMutableArray *highlightedPlaceHolders = [NSMutableArray arrayWithCapacity:0];
	int i;
	for (i=0; i<[placeHolders count]; i++)
	{
		NSRect interserctionRect = NSIntersectionRect(annotationFrame, [[placeHolders objectAtIndex:i] frame]);
		if(interserctionRect.size.width*interserctionRect.size.height >= 0.1*annotationFrameArea)
		{
			[[placeHolders objectAtIndex:i] setHasFocus:YES];
			[highlightedPlaceHolders addObject:[placeHolders objectAtIndex:i]];
		}
		else
			[[placeHolders objectAtIndex:i] setHasFocus:NO];
	}
	
	int numberOfHighlightedPlaceHolders = [highlightedPlaceHolders count];
	if(numberOfHighlightedPlaceHolders>1) // more than one place holder is highlighted
	{
		NSEvent *currentEvent = [[NSApplication sharedApplication] currentEvent];
		NSPoint mouseLocationInWindow = [currentEvent locationInWindow];
		NSPoint mouseLocationInView = [layoutView convertPoint:mouseLocationInWindow fromView:nil];
		
		float distanceToMouse[numberOfHighlightedPlaceHolders];
		float placeHolderCenter;
		for (i=0; i<numberOfHighlightedPlaceHolders; i++)
		{
			placeHolderCenter = [[highlightedPlaceHolders objectAtIndex:i] frame].origin.x + [[highlightedPlaceHolders objectAtIndex:i] frame].size.width/2.0;
			distanceToMouse[i] = fabsf(mouseLocationInView.x - placeHolderCenter);
		}

		float minDistance = MAXFLOAT;
		int index = -1;
		for (i=0; i<numberOfHighlightedPlaceHolders; i++)
		{
			if(distanceToMouse[i] < minDistance)
			{
				minDistance = distanceToMouse[i];
				index = i;
			}
		}
		
		for (i=0; i<numberOfHighlightedPlaceHolders; i++)
		{
			if(i!=index)
				[[highlightedPlaceHolders objectAtIndex:i] setHasFocus:NO];
		}
	}
}

- (void)selectAnnotation:(CIAAnnotation*)anAnnotation;
{
	if(anAnnotation==selectedAnnotation) return;

	[self validateTokenTextField:self];
	
	int i;
	for (i=0; i<[annotationsArray count]; i++)
	{
		[[annotationsArray objectAtIndex:i] setIsSelected:NO];
	}
	[anAnnotation setIsSelected:YES];

	[self willChangeValueForKey:@"selectedAnnotation"];
	if( selectedAnnotation != anAnnotation)
	{
		[selectedAnnotation release];
		selectedAnnotation = [anAnnotation retain];
	}
	[self didChangeValueForKey:@"selectedAnnotation"];

	[[prefPane titleTextField] setEnabled: YES];
	[[prefPane contentTokenField] setEnabled: YES];
	[self setCustomDICOMFieldEditingEnable: YES];
	
	[[prefPane titleTextField] setStringValue:[anAnnotation title]];
	[[prefPane contentTokenField] setObjectValue:[anAnnotation content]];
	
	[layoutView addSubview:anAnnotation]; // in order to bring the Annotation to front
	[layoutView setNeedsDisplay:YES];
	
	[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
	[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
	[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
	[[prefPane specialFieldsPopUpButton] setEnabled:NO];
	[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
	[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
	[[prefPane addCustomDICOMFieldButton] setEnabled:YES];
	[[prefPane addDICOMFieldButton] setEnabled:YES];
	[[prefPane addDatabaseFieldButton] setEnabled:YES];
	[[prefPane addSpecialFieldButton] setEnabled:YES];
}

- (CIAAnnotation*)selectedAnnotation;
{
	return selectedAnnotation;
}

- (IBAction)addFieldToken:(id)sender;
{
	NSMenuItem *selectedItem;
	if([sender isEqualTo:[prefPane DICOMFieldsPopUpButton]] || [sender isEqualTo:[prefPane databaseFieldsPopUpButton]] || [sender isEqualTo:[prefPane specialFieldsPopUpButton]])
	{
		selectedItem = [sender selectedItem];
	}
	
	// see if there is a selected Token in the NSTokenField
	BOOL aTokenIsSelected = NO;
	int tokenIndexInContent;
	NSRange range = [[[prefPane contentTokenField] currentEditor] selectedRange];

	if(range.length==1) // one and only one is selected
	{
		aTokenIsSelected = YES;
		tokenIndexInContent = range.location;
	}

	// next line validates the NSToken field content : same as if the user hit 'return'. we NEED that.
	[[prefPane contentTokenField] sendAction:[[prefPane contentTokenField] action] to:[[prefPane contentTokenField] target]];

	NSString *formatString;	
	if([sender isEqualTo:[prefPane DICOMFieldsPopUpButton]])
	{
		formatString = @"DICOM_%@";
		if(!aTokenIsSelected)
		{
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[[sender selectedItem] representedObject] name]] inContentAtIndex:[selectedAnnotation countOfContent]];
		}
		else
		{
			[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[selectedItem representedObject] name]] inContentAtIndex:tokenIndexInContent];
		}
	}
	else if([sender isEqualTo:[prefPane databaseFieldsPopUpButton]])
	{
		formatString = @"DB_%@";		
		if(!aTokenIsSelected)
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString,[selectedItem representedObject]] inContentAtIndex:[selectedAnnotation countOfContent]];
		else
		{
			[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString,[selectedItem representedObject]] inContentAtIndex:tokenIndexInContent];
		}
	}
	else if([sender isEqualTo:[prefPane specialFieldsPopUpButton]])
	{
		formatString = @"Special_%@";
		if(!aTokenIsSelected)
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString,[selectedItem representedObject]] inContentAtIndex:[selectedAnnotation countOfContent]];
		else
		{
			[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString,[selectedItem representedObject]] inContentAtIndex:tokenIndexInContent];
		}
	}
	else if([sender isEqualTo:[prefPane addCustomDICOMFieldButton]])
	{
		if([[[prefPane dicomGroupTextField] stringValue] isEqualToString:@""] || [[[prefPane dicomElementTextField] stringValue] isEqualToString:@""])
		{
			NSRunAlertPanel(NSLocalizedString( @"Custom DICOM Field", nil), NSLocalizedString( @"Please provide a value for both \"Group\" and \"Element\" fields.", nil), NSLocalizedString( @"OK", nil), nil, nil);
			return;
		}
		
		if([[prefPane DICOMFieldsPopUpButton] indexOfSelectedItem]==0)
		{
			// custom field
			if([[[prefPane dicomNameTokenField] stringValue] isEqualToString:@""])
			{
				formatString = @"DICOM_%@_%@";
//				if(!aTokenIsSelected)
					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue]] inContentAtIndex:[selectedAnnotation countOfContent]];
//				else
//				{
//					[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
//					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue]] inContentAtIndex:tokenIndexInContent];
//				}
			}
			else
			{
				formatString = @"DICOM_%@_%@_%@";
//				if(!aTokenIsSelected)
					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue], [[prefPane dicomNameTokenField] stringValue]] inContentAtIndex:[selectedAnnotation countOfContent]];
//				else
//				{
//					[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
//					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue], [[prefPane dicomNameTokenField] stringValue]] inContentAtIndex:tokenIndexInContent];
//				}
			}
		}
		else
		{
			// field in the list
			formatString = @"DICOM_%@";
			if(!aTokenIsSelected)
				[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[[[prefPane DICOMFieldsPopUpButton] selectedItem] representedObject] name]] inContentAtIndex:[selectedAnnotation countOfContent]];
			else
			{
				[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
				[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[[[prefPane DICOMFieldsPopUpButton] selectedItem] representedObject] name]] inContentAtIndex:tokenIndexInContent];
			}
		}
		[[prefPane dicomGroupTextField] setStringValue:@""];
		[[prefPane dicomElementTextField] setStringValue:@""];
		[[prefPane dicomNameTokenField] setStringValue:@""];
		[[prefPane dicomGroupTextField] setNeedsDisplay:YES];
		[[prefPane dicomElementTextField] setNeedsDisplay:YES];
		[[prefPane dicomNameTokenField] setNeedsDisplay:YES];
	}
	else if([sender isEqualTo:[prefPane addDICOMFieldButton]])
	{
		[selectedAnnotation insertObject:@"DICOM_" inContentAtIndex:[selectedAnnotation countOfContent]];
		[[prefPane DICOMFieldsPopUpButton] setEnabled:YES];
		[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
		[[prefPane specialFieldsPopUpButton] setEnabled:NO];
		[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
		aTokenIsSelected = NO;
	}
	else if([sender isEqualTo:[prefPane addDatabaseFieldButton]])
	{
		[selectedAnnotation insertObject:@"DB_" inContentAtIndex:[selectedAnnotation countOfContent]];
		[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
		[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane databaseFieldsPopUpButton] setEnabled:YES];
		[[prefPane specialFieldsPopUpButton] setEnabled:NO];
		[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
		aTokenIsSelected = NO;
	}
	else if([sender isEqualTo:[prefPane addSpecialFieldButton]])
	{
		[selectedAnnotation insertObject:@"Special_" inContentAtIndex:[selectedAnnotation countOfContent]];
		[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
		[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
		[[prefPane specialFieldsPopUpButton] setEnabled:YES];
		[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
		[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
		aTokenIsSelected = NO;
	}
	
	[[prefPane contentTokenField] setObjectValue:[selectedAnnotation content]];

	[selectedAnnotation didChangeValueForKey:@"content"];
	
	if(!aTokenIsSelected)
	{
		// select added token
		[[self window] makeFirstResponder:[prefPane contentTokenField]];
		[[[prefPane contentTokenField] currentEditor] setSelectedRange:NSMakeRange((long) [[selectedAnnotation content] count]-1, 1)];
	}
	
	[[prefPane contentTokenField] setNeedsDisplay:YES];
}

- (IBAction)validateTokenTextField:(id)sender;
{
	[[selectedAnnotation content] setArray:[[prefPane contentTokenField] objectValue]];
}

- (void)resizeTokenField; // not used
{
	return;
	int i;
	NSRect oldTokenFieldFrame = [[prefPane contentTokenField] frame];
	NSSize cellSize = [[[prefPane contentTokenField] cell] cellSizeForBounds:[[prefPane contentTokenField] bounds]];

	NSBox *globalPaneBox = [[[[self window] contentView] subviews] objectAtIndex:0];
	
	for (i=0; i<[[globalPaneBox subviews] count]; i++)
	{
		NSView *currentView = [[globalPaneBox subviews] objectAtIndex:i];

		if(currentView==[prefPane contentTokenField] || currentView==[prefPane contentBox])
		{
			[currentView setFrameOrigin:NSMakePoint([currentView frame].origin.x, [currentView frame].origin.y-oldTokenFieldFrame.size.height+cellSize.height)];
		}
	}

	[[[[[self window] contentView] subviews] objectAtIndex:0] display];

	[[prefPane contentTokenField] setFrame:NSMakeRect(oldTokenFieldFrame.origin.x, oldTokenFieldFrame.origin.y, oldTokenFieldFrame.size.width, cellSize.height)];
	
	NSPoint loc = [selectedAnnotation mouseDownLocation];
	loc.y -= oldTokenFieldFrame.size.height-cellSize.height;
	[selectedAnnotation setMouseDownLocation:loc];

	[[self window] setFrame:NSMakeRect([[self window] frame].origin.x, [[self window] frame].origin.y+oldTokenFieldFrame.size.height-cellSize.height, [[self window] frame].size.width, [[self window] frame].size.height-oldTokenFieldFrame.size.height+cellSize.height) display:YES];
	
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	if([[aNotification object] isEqualTo:[prefPane dicomGroupTextField]])
	{
		unsigned group = 0;
		[[NSScanner scannerWithString: [[prefPane dicomGroupTextField] stringValue]] scanHexInt:&group];
		if(group>0xffFF) group = 0xffFF;
		[[prefPane dicomGroupTextField] setStringValue:[NSString stringWithFormat:@"0x%04x", group]];
		
	}
	else if([[aNotification object] isEqualTo:[prefPane dicomElementTextField]])
	{
		unsigned element = 0;
		[[NSScanner scannerWithString: [[prefPane dicomElementTextField] stringValue]] scanHexInt:&element];
		if(element>0xffFF) element = 0xffFF;
		[[prefPane dicomElementTextField] setStringValue:[NSString stringWithFormat:@"0x%04x", element]];
		
		int i;
		for (i=0; i<[DICOMFieldsArray count]; i++)
		{
			if ([[NSString stringWithFormat:@"0x%04x", [[DICOMFieldsArray objectAtIndex:i] group]] isEqualToString:[[prefPane dicomGroupTextField] stringValue]] && [[NSString stringWithFormat:@"0x%04x", [[DICOMFieldsArray objectAtIndex:i] element]] isEqualToString:[[prefPane dicomElementTextField] stringValue]])
			{
				[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:i+1]; // +1 because item at index 0 contains no DICOM fields (it says "DICOM Fields")
				[[prefPane dicomNameTokenField] setStringValue:[[DICOMFieldsArray objectAtIndex:i] name]];
				break;
			}
			else
			{
				[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
				[[prefPane dicomNameTokenField] setStringValue:@""];
			}
		}
	}

}

- (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard
{
	// handles drag & drop of several tokens
	return [[pboard stringForType:NSStringPboardType] componentsSeparatedByString:@", "];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	[self performSelector:@selector(resizeTokenField) withObject:nil afterDelay:0.1];
	return tokens;
}

- (void)prepareDatabaseFields;
{
	NSManagedObjectModel *currentModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"OsiriXDB_DataModel.mom"]]] autorelease];
	
	NSMutableDictionary *studyAttributes = [NSMutableDictionary dictionaryWithDictionary:[[[currentModel entitiesByName] objectForKey:@"Study"] attributesByName]];
	[studyAttributes removeObjectForKey:@"windowsState"];	
	NSArray *studies = [studyAttributes allKeys];
	NSArray *sortedStudies = [studies sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableDictionary *seriesAttributes = [NSMutableDictionary dictionaryWithDictionary:[[[currentModel entitiesByName] objectForKey:@"Series"] attributesByName]];
	[seriesAttributes removeObjectForKey:@"thumbnail"];
	NSArray *series = [seriesAttributes allKeys];
	NSArray *sortedSeries = [series sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMutableDictionary *imageAttributes = [NSMutableDictionary dictionaryWithDictionary:[[[currentModel entitiesByName] objectForKey:@"Image"] attributesByName]];
	NSArray *images = [imageAttributes allKeys];
	NSArray *sortedImages = [images sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	[databaseStudyFieldsArray addObjectsFromArray:sortedStudies];
	[databaseSeriesFieldsArray addObjectsFromArray:sortedSeries];
	[databaseImageFieldsArray addObjectsFromArray:sortedImages];
}

- (NSMutableArray*)specialFieldsLocalizedTitles;
{
	NSMutableArray *specialFieldsTitles = [NSMutableArray array];
	[specialFieldsTitles addObject: NSLocalizedString( @"Image Size", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"View Size", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Window Level / Window Width", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Image Position", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Zoom", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Rotation Angle", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Mouse Position (px)", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Mouse Position (mm)", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Thickness / Location / Position", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Patient's Actual Age", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Patient's Age At Acquisition", 0L)];
	[specialFieldsTitles addObject: NSLocalizedString( @"Plugin", 0L)];
	return specialFieldsTitles;
}

- (NSMutableArray*)specialFieldsTitles;
{
	NSMutableArray *specialFieldsTitles = [NSMutableArray array];
	[specialFieldsTitles addObject:(@"Image Size")];
	[specialFieldsTitles addObject:(@"View Size")];
	[specialFieldsTitles addObject:(@"Window Level / Window Width")];
	[specialFieldsTitles addObject:(@"Image Position")];
	[specialFieldsTitles addObject:(@"Zoom")];
	[specialFieldsTitles addObject:(@"Rotation Angle")];
	[specialFieldsTitles addObject:(@"Mouse Position (px)")];
	[specialFieldsTitles addObject:(@"Mouse Position (mm)")];
	[specialFieldsTitles addObject:(@"Thickness / Location / Position")];
	[specialFieldsTitles addObject:(@"Patient's Actual Age")];
	[specialFieldsTitles addObject:(@"Patient's Age At Acquisition")];
	[specialFieldsTitles addObject:(@"Plugin")];
	return specialFieldsTitles;
}

// auto completion
- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
	int i, j;
	NSMutableArray *resultArray = [NSMutableArray array];
	int substringLength = [substring length];
	NSRange comparisonRange = NSMakeRange(0, substringLength);
	
	if([tokenField isEqualTo:[prefPane contentTokenField]])
	{
		[resultArray addObject:substring];
		
		NSArray *titles;
		NSString *currentTitle;	
		
		titles = databaseStudyFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle length]>=substringLength)
			{
				for (j=0; j<[currentTitle length]-substringLength+1; j++)
				{
					if([[substring lowercaseString] isEqualToString:[[currentTitle substringWithRange:NSMakeRange(j, substringLength)] lowercaseString]])
						[resultArray addObject:[NSString stringWithFormat:@"DB_study.%@", currentTitle]];
				}
			}
		}
		titles = databaseSeriesFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle length]>=substringLength)
			{
				for (j=0; j<[currentTitle length]-substringLength+1; j++)
				{
					if([[substring lowercaseString] isEqualToString:[[currentTitle substringWithRange:NSMakeRange(j, substringLength)] lowercaseString]])
						[resultArray addObject:[NSString stringWithFormat:@"DB_series.%@", currentTitle]];
				}
			}
		}
		titles = databaseImageFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle length]>=substringLength)
			{
				for (j=0; j<[currentTitle length]-substringLength+1; j++)
				{
					if([[substring lowercaseString] isEqualToString:[[currentTitle substringWithRange:NSMakeRange(j, substringLength)] lowercaseString]])
						[resultArray addObject:[NSString stringWithFormat:@"DB_image.%@", currentTitle]];
				}
			}
		}
		
		NSArray *localizedTitles = [self specialFieldsLocalizedTitles];
		titles = [self specialFieldsTitles];
		
		for (i=0; i<[localizedTitles count]; i++)
		{
			currentTitle = [localizedTitles objectAtIndex:i];
			if([currentTitle length]>=substringLength)
			{
				for (j=0; j<[currentTitle length]-substringLength+1; j++)
				{
					if([[substring lowercaseString] isEqualToString:[[currentTitle substringWithRange:NSMakeRange(j, substringLength)] lowercaseString]])
						[resultArray addObject:[NSString stringWithFormat:@"Special_%@", [titles objectAtIndex:i]]];
				}
			}

		}
		
		titles = DICOMFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [[titles objectAtIndex:i] name];
			if([currentTitle length]>=substringLength)
			{
				for (j=0; j<[currentTitle length]-substringLength+1; j++)
				{
					if([[substring lowercaseString] isEqualToString:[[currentTitle substringWithRange:NSMakeRange(j, substringLength)] lowercaseString]])
						[resultArray addObject:[NSString stringWithFormat:@"DICOM_%@", currentTitle]];
				}
			}
		}
	}
	else if([tokenField isEqualTo:[prefPane dicomNameTokenField]])
	{
		NSString *currentTitle;
		for (i=0; i<[DICOMFieldsArray count]; i++)
		{
			currentTitle = [[DICOMFieldsArray objectAtIndex:i] name];
			if([currentTitle compare:substring options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
				[resultArray addObject:[[DICOMFieldsArray objectAtIndex:i] name]];
		}
	}

	return resultArray;
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	if(skipTextViewDidChangeSelectionNotification) return;
	skipTextViewDidChangeSelectionNotification = YES;

	if([[prefPane contentTokenField] currentEditor]==[aNotification object])
	{
		NSArray *ranges = [[aNotification object] selectedRanges];
		
		if([ranges count]==1)
		{
			NSRange selectedRange = [[ranges objectAtIndex:0] rangeValue];

			if(selectedRange.length==1)
			{
				NSString *selectedString = [[[[prefPane contentTokenField] objectValue] subarrayWithRange:selectedRange] objectAtIndex:0];
				
				if([selectedString hasPrefix:@"DICOM_"])
				{
					[[prefPane DICOMFieldsPopUpButton] setEnabled:YES];
					[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
					
					[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
					[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
					
					[[prefPane specialFieldsPopUpButton] setEnabled:NO];
					[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
					
					if([selectedString length]>=7)
					{						
						BOOL found = NO;
						selectedString = [selectedString substringFromIndex:6];
						int i;
						for (i=0; i<[DICOMFieldsArray count]; i++)
						{
							if([[[DICOMFieldsArray objectAtIndex:i] name] isEqualToString:selectedString])
							{
//								[[prefPane dicomGroupTextField] setStringValue:[NSString stringWithFormat:@"0x%04x", [[DICOMFieldsArray objectAtIndex:i] group]]];
//								[[prefPane dicomElementTextField] setStringValue:[NSString stringWithFormat:@"0x%04x", [[DICOMFieldsArray objectAtIndex:i] element]]];
//								[[prefPane dicomNameTokenField] setStringValue:[[DICOMFieldsArray objectAtIndex:i] name]];
								[[prefPane dicomGroupTextField] setStringValue:@""];
								[[prefPane dicomElementTextField] setStringValue:@""];
								[[prefPane dicomNameTokenField] setStringValue:@""];


								[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:i+1];
								[[prefPane DICOMFieldsPopUpButton] setEnabled:YES];
								found = YES;
								break;
							}
						}
						
//						if(!found)
//						{
//							// this is a custom DICOM field, with this format : DICOM_0x0001_0x0001 or DICOM_0x0001_0x0001_name
//							NSString *groupString = [selectedString substringWithRange:NSMakeRange(0,6)];
//							NSString *elementString = [selectedString substringWithRange:NSMakeRange(7,6)];
//							[[prefPane dicomGroupTextField] setStringValue:groupString];
//							[[prefPane dicomElementTextField] setStringValue:elementString];
//
//							NSString *name;
//							if([selectedString length]==13)
//								name = @"";
//							else
//								name = [selectedString substringFromIndex:14];
//							[[prefPane dicomNameTokenField] setStringValue:name];
//							
//							[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
//							[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
//						}
					}
				}
				else if([selectedString hasPrefix:@"DB_"])
				{
					[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
					[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
					[[prefPane databaseFieldsPopUpButton] setEnabled:YES];
					[[prefPane specialFieldsPopUpButton] setEnabled:NO];
					[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];

					if([selectedString length]>=4)
					{
						selectedString = [selectedString substringFromIndex:3];
						[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:[[[prefPane databaseFieldsPopUpButton] menu] indexOfItemWithRepresentedObject:selectedString]];
					}
					else
					{
						[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
					}
				}
				else if([selectedString hasPrefix:@"Special_"])
				{
					[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
					[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
					[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
					[[prefPane specialFieldsPopUpButton] setEnabled:YES];
					[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];

					if([selectedString length]>=9)
					{
						selectedString = [selectedString substringFromIndex:8];
						
						int index = [[self specialFieldsTitles] indexOfObject: selectedString];
						[[prefPane specialFieldsPopUpButton] selectItemAtIndex: index];
					}
					else
					{
						[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
					}
				}
				else
				{
					[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
					[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
					[[prefPane databaseFieldsPopUpButton] setEnabled:NO];
					[[prefPane databaseFieldsPopUpButton] selectItemAtIndex:0];
					[[prefPane specialFieldsPopUpButton] setEnabled:NO];
					[[prefPane specialFieldsPopUpButton] selectItemAtIndex:0];
				}
			}
		}
	}
	skipTextViewDidChangeSelectionNotification = NO;
}

- (void)setCustomDICOMFieldEditingEnable:(BOOL)boo;
{
	[[prefPane dicomNameTokenField] setEnabled:boo];
	[[prefPane dicomGroupTextField] setEnabled:boo];
	[[prefPane dicomElementTextField] setEnabled:boo];
	
	[[prefPane dicomNameTokenField] setStringValue:@""];
	[[prefPane dicomGroupTextField] setStringValue:@""];
	[[prefPane dicomElementTextField] setStringValue:@""];

	NSColor *textColor;
	if(boo)
		textColor = [NSColor blackColor];
	else
		textColor = [NSColor grayColor];
		
	[[prefPane groupLabel] setTextColor:textColor];
	[[prefPane elementLabel] setTextColor:textColor];
	[[prefPane nameLabel] setTextColor:textColor];
}

- (BOOL)checkAnnotations;
{
	int a;
	for (a=0; a<[annotationsArray count]; a++)
	{
		if(![[annotationsArray objectAtIndex:a] placeHolder])
		{
			int r = NSRunAlertPanel(NSLocalizedString( @"Saving Annotations", nil), NSLocalizedString( @"Any Annotation left outside the place holders will be lost.", nil), NSLocalizedString( @"OK", nil), NSLocalizedString( @"Cancel", nil), nil);
			if(r==NSAlertDefaultReturn)
				return YES;
			else
				return NO;
		}
	}
	return YES;
}

- (BOOL)checkAnnotationsContent;
{
	BOOL check = YES;
	
	CIAAnnotation *unfinishedAnnotation;
	
	NSArray *content;
	for (int a=0; a<[annotationsArray count]; a++)
	{
		CIAAnnotation *annotation = [annotationsArray objectAtIndex:a];
		content = [annotation content];
		
		for( NSString *token in content)
		{
			if([token isEqualToString:@"DICOM_"] || [token isEqualToString:@"DB_"] || [token isEqualToString:@"Special_"])
			{
				check = NO;
				unfinishedAnnotation = annotation;
			}
		}
	}

	if(!check || [annotationsArray count]==0)
	{
//		int r = NSRunAlertPanel(NSLocalizedString( @"Annotation Content", nil), NSLocalizedString( @"Some token have no content. Token such as 'DICOM_', 'DB_', 'Special_' will not be displayed.", nil), NSLocalizedString( @"OK", nil), NSLocalizedString( @"Cancel", nil), nil);
//		if(r==NSAlertDefaultReturn)
//			return YES;
//		else
//		{
//			[self selectAnnotation:unfinishedAnnotation];
//			return NO;
//		}
	}
	
	return YES;
}

- (BOOL)checkAnnotationContent:(CIAAnnotation*)annotation;
{
	NSArray *content = [annotation content];
	
	BOOL check = YES;
	
	for( NSString *token in content)
	{
		if([token isEqualToString:@"DICOM_"] || [token isEqualToString:@"DB_"] || [token isEqualToString:@"Special_"])
		{
			check = NO;
		}
	}

	if(!check || [content count]==0)
	{
//		int r = NSRunAlertPanel(NSLocalizedString( @"Annotation Content", nil), NSLocalizedString( @"Some token have no content. Token such as 'DICOM_', 'DB_', 'Special_' will not be displayed.", nil), NSLocalizedString( @"OK", nil), NSLocalizedString( @"Cancel", nil), nil);
//		if(r==NSAlertDefaultReturn)
//			return YES;
//		else
//			return NO;
	}
	return YES;
}

- (void)saveAnnotationLayout;
{
	[self saveAnnotationLayoutForModality:currentModality];
}

- (void)saveAnnotationLayoutForModality:(NSString*)modality;
{
	NSArray *placeHolders = [layoutView placeHolderArray];
	NSArray *keys = [NSArray arrayWithObjects:@"LowerLeft", @"LowerMiddle", @"LowerRight", @"MiddleLeft", @"MiddleRight", @"TopLeft", @"TopMiddle", @"TopRight", nil];
	NSMutableDictionary *layoutViewDict = [NSMutableDictionary dictionary];
	
	if([[prefPane sameAsDefaultButton] state]==NSOnState)
	{
		[layoutViewDict setObject:@"1" forKey:@"sameAsDefault"];
	}
	else
	{
		[layoutViewDict setObject:@"0" forKey:@"sameAsDefault"];
	
		CIAPlaceHolder *placeHolder;
		NSMutableArray *annotations;
		int i, j, k, n;
		for (i=0; i<8; i++)
		{
			placeHolder = [placeHolders objectAtIndex:i];
			
			annotations = [NSMutableArray array];
			for (j=0; j<[[placeHolder annotationsArray] count]; j++)
			{
				NSMutableDictionary *annot = [NSMutableDictionary dictionary];
				[annot setObject:[[[placeHolder annotationsArray] objectAtIndex:j] title] forKey:@"title"];
				[annot setObject:[[[placeHolder annotationsArray] objectAtIndex:j] content] forKey:@"content"];
				
				NSMutableArray *contentToSave = [NSMutableArray array];
				
				NSArray* contentArray = [[[placeHolder annotationsArray] objectAtIndex:j] content];
				for (n=0; n<[contentArray count]; n++)
				{
					NSString *currentField = [contentArray objectAtIndex:n];
					NSRange comparisonRange;
					
					NSMutableDictionary *fieldDict = [NSMutableDictionary dictionary];
					
					if([currentField hasPrefix:@"DICOM_"])
					{
						unsigned group, element;
						NSString *name = @"";
						BOOL isCustomDICOMField = YES;
						if([currentField length]>6)
						{
							[fieldDict setObject:@"DICOM" forKey:@"type"];
							
							comparisonRange = NSMakeRange(6, [currentField length]-6);
							NSString *currentTitle;
							for (k=0; k<[DICOMFieldsArray count] && isCustomDICOMField; k++)
							{
								currentTitle = [[DICOMFieldsArray objectAtIndex:k] name];
								if([currentField compare:currentTitle options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
								{
									group = [[DICOMFieldsArray objectAtIndex:k] group];
									element = [[DICOMFieldsArray objectAtIndex:k] element];
									name = [[DICOMFieldsArray objectAtIndex:k] name];
									isCustomDICOMField = NO;
								}
							}
							if(isCustomDICOMField)
							{
								NSArray *components = [currentField componentsSeparatedByString:@"_"];
								if([components count]>=3)
								{
									[[NSScanner scannerWithString:[components objectAtIndex:1]] scanHexInt:&group];
									[[NSScanner scannerWithString:[components objectAtIndex:2]] scanHexInt:&element];
									if([components count]==4)
										name = [components objectAtIndex:3];
								}
							}
							[fieldDict setObject:[NSNumber numberWithInt:group] forKey:@"group"];
							[fieldDict setObject:[NSNumber numberWithInt:element] forKey:@"element"];
							[fieldDict setObject:name forKey:@"name"];
							[fieldDict setObject:currentField forKey:@"tokenTitle"];
							[contentToSave addObject:fieldDict];
						}
					}
					else if([currentField hasPrefix:@"DB_"])
					{
						if([currentField length]>3)
						{
							[fieldDict setObject:@"DB" forKey:@"type"];

							NSRange rangeOfDot = [currentField rangeOfString:@"."];
							[fieldDict setObject:[[currentField substringFromIndex:3] substringToIndex:rangeOfDot.location-3] forKey:@"level"];
							[fieldDict setObject:[currentField substringFromIndex:rangeOfDot.location+1] forKey:@"field"];

							[contentToSave addObject:fieldDict];
						}
					}
					else if([currentField hasPrefix:@"Special_"])
					{
						if([currentField length]>8)
						{
							[fieldDict setObject:@"Special" forKey:@"type"];
							[fieldDict setObject:[currentField substringFromIndex:8] forKey:@"field"];
							[contentToSave addObject:fieldDict];
						}
					}
					else
					{
						[fieldDict setObject:@"Manual" forKey:@"type"];
						[fieldDict setObject:currentField forKey:@"field"];
						[contentToSave addObject:fieldDict];
					}
				}
				[annot setObject:contentToSave forKey:@"fullContent"]; // fullContent contains more details than "content" -> use it for display in the DCM view
				[annotations addObject:annot];
			}
			
			[layoutViewDict setObject:annotations forKey:[keys objectAtIndex:i]];
		}
	}	
	[annotationsLayoutDictionary setObject:layoutViewDict forKey:modality];
	
	[[NSUserDefaults standardUserDefaults] setObject:annotationsLayoutDictionary forKey:@"CUSTOM_IMAGE_ANNOTATIONS"];
}

- (IBAction)switchModality:(id)sender;
{
	return [self switchModality: sender save: YES];
}

- (IBAction)switchModality:(id)sender save:(BOOL) save;
{
	if(![self checkAnnotations] || ![self checkAnnotationsContent])
	{
		[[prefPane modalitiesPopUpButton] setTitle:currentModality];//currentModality
		return;
	}
		
	[self validateTokenTextField:self];
	[selectedAnnotation release];
	selectedAnnotation = nil;
	
	[[prefPane titleTextField] setEnabled: NO];
	[[prefPane contentTokenField] setEnabled: NO];
	[self setCustomDICOMFieldEditingEnable:NO];
	
	if( save)
		[self saveAnnotationLayoutForModality:currentModality];
	
	[currentModality release];
	
	if( [sender indexOfSelectedItem] == 0) currentModality = @"Default";
	else currentModality = [[sender selectedItem] title];
	
	[currentModality retain];
	
	[[prefPane sameAsDefaultButton] setHidden:[currentModality isEqualToString:@"Default"]];
	[[prefPane resetDefaultButton] setHidden:![currentModality isEqualToString:@"Default"]];
	[self loadAnnotationLayoutForModality:currentModality];

	[[prefPane titleTextField] setStringValue:@""];
	[[prefPane contentTokenField] setStringValue:@""];
}

- (void)loadAnnotationLayoutForModality:(NSString*)modality;
{
	[self removeAllAnnotations];
	
	[[prefPane orientationWidgetButton] setState:NSOffState];
	
	NSDictionary *palceHoldersForModality = [annotationsLayoutDictionary objectForKey:modality];
	NSArray *keys = [NSArray arrayWithObjects:@"LowerLeft", @"LowerMiddle", @"LowerRight", @"MiddleLeft", @"MiddleRight", @"TopLeft", @"TopMiddle", @"TopRight", nil];
	NSArray *placeHolders = [layoutView placeHolderArray];
	
	CIAPlaceHolder *placeHolder;
	NSArray *annotations;
	CIAAnnotation *anAnnotation;
	int i, j, n=0;
	for (i=0; i<8; i++)
	{
		annotations = [palceHoldersForModality objectForKey:[keys objectAtIndex:i]];
		placeHolder = [placeHolders objectAtIndex:i];

		for (j=0; j<[annotations count]; j++)
		{
			n++;
			anAnnotation = [[CIAAnnotation alloc] initWithFrame:NSMakeRect(10.0, 10.0, 75, 22)];
			[anAnnotation setTitle:[[annotations objectAtIndex:j] objectForKey:@"title"]];
			[anAnnotation setContent:[[annotations objectAtIndex:j] objectForKey:@"content"]];
			
			if([[anAnnotation title] isEqualToString:@"Orientation"])
				if([[anAnnotation content] count]==1)
					if([[[anAnnotation content] objectAtIndex:0] isEqualToString:@"Special_Orientation"])
					{
						[anAnnotation setIsOrientationWidget:YES];
						[[prefPane orientationWidgetButton] setState:NSOnState];
					}
			
			[anAnnotation setPlaceHolder:placeHolder];
			//[placeHolder addAnnotation:anAnnotation];
			[placeHolder addAnnotation:anAnnotation animate:NO];
			[placeHolder updateFrameAroundAnnotationsWithAnimation:NO];
											
			[annotationsArray addObject:anAnnotation];
			[layoutView addSubview:anAnnotation];

			[anAnnotation release];
		}

		[placeHolder alignAnnotations];
		//[placeHolder updateFrameAroundAnnotations];
		[placeHolder updateFrameAroundAnnotationsWithAnimation:NO];
	}
	
	[[prefPane sameAsDefaultButton] setState:NSOffState];
	
	if(n==0 && ![modality isEqualTo:@"Default"])
	{
		[self loadAnnotationLayoutForModality:@"Default"];
		[[prefPane sameAsDefaultButton] setState:NSOnState];
		[layoutView setEnabled:NO];
		[[prefPane orientationWidgetButton] setEnabled:NO];
	}
	else
	{
		[layoutView setEnabled: [prefPane isUnlocked]];
		[[prefPane orientationWidgetButton] setEnabled:[prefPane isUnlocked]];
	}
	
	[layoutView setNeedsDisplay:YES];
}

- (void)removeAllAnnotations;
{
	NSArray *placeHolders = [layoutView placeHolderArray];
	int i;
	for (i=0; i<[placeHolders count]; i++)
	{
		[[[placeHolders objectAtIndex:i] annotationsArray] removeAllObjects];
		[[placeHolders objectAtIndex:i] setHasFocus:NO];
		[[placeHolders objectAtIndex:i] updateFrameAroundAnnotationsWithAnimation:NO];
	}

	for (i=0; i<[annotationsArray count]; i++)
	{
		[[annotationsArray objectAtIndex:i] removeFromSuperview];
	}
	
	[annotationsArray removeAllObjects];
	[layoutView setNeedsDisplay:YES];
}

- (void)setLayoutView:(CIALayoutView*)view;
{
	layoutView = view;
}

- (void)setPrefPane:(OSICustomImageAnnotations*)aPrefPane;
{
	prefPane = aPrefPane;
}

- (void)setOrientationWidgetEnabled:(BOOL)enabled;
{
	int i, j, index[] = {1, 3, 4, 6}; // index of the placeholders that can hold an orientation widget
	NSArray *placeHolders = [layoutView placeHolderArray];
	CIAPlaceHolder *placeHolder;
	CIAAnnotation *anAnnotation;

	if(enabled)
	{		
		for (i=0; i<4; i++)
		{
			placeHolder = [placeHolders objectAtIndex:index[i]];

			anAnnotation = [[CIAAnnotation alloc] initWithFrame:NSMakeRect(10.0, 10.0, 75, 22)];
			[anAnnotation setTitle:@"Orientation"];
			[anAnnotation setContent:[NSArray arrayWithObject:@"Special_Orientation"]];
			[anAnnotation setIsOrientationWidget:YES];
			[anAnnotation setPlaceHolder:placeHolder];
			[placeHolder insertAnnotation:anAnnotation atIndex:0];
				
			[annotationsArray addObject:anAnnotation];
			[layoutView addSubview:anAnnotation];

			[anAnnotation release];

			[placeHolder alignAnnotations];
			[placeHolder updateFrameAroundAnnotations];
			[placeHolder alignAnnotations];
		}
		[layoutView display];
	}
	else
	{
		for (i=0; i<4; i++)
		{
			placeHolder = [placeHolders objectAtIndex:index[i]];
			for (j=0; j<[[placeHolder annotationsArray] count]; j++)
			{
				anAnnotation = [[placeHolder annotationsArray] objectAtIndex:j];
				if([anAnnotation isOrientationWidget])
				{
					[annotationsArray removeObject:anAnnotation];
					[anAnnotation removeFromSuperview];
					[placeHolder removeAnnotation:anAnnotation];
					[placeHolder updateFrameAroundAnnotations];
					[placeHolder alignAnnotations];
					[layoutView setNeedsDisplay:YES];
				}
			}
		}
	}
}

@end
