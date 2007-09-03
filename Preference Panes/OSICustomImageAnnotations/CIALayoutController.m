//
//  CIALayoutController.m
//  ImageAnnotations
//
//  Created by joris on 25/06/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "CIALayoutControllerDCMTK.h"
#import "CIALayoutController.h"
#import "CIADICOMField.h"

#import "OSICustomImageAnnotations.h"

@implementation CIALayoutController

- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self != nil)
	{
		annotationsArray = [[NSMutableArray array] retain];
		DICOMFieldsArray = [[NSMutableArray array] retain];
		DICOMFieldsTitlesArray = [[NSMutableArray array] retain];
		databaseStudyFieldsArray = [[NSMutableArray array] retain];
		databaseSeriesFieldsArray = [[NSMutableArray array] retain];
		databaseImageFieldsArray = [[NSMutableArray array] retain];
		selectedAnnotation = nil;
		
		annotationNumber = 1;
		
		if([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CUSTOM_IMAGE_ANNOTATIONS"])
			annotationsLayoutDictionary = [[NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CUSTOM_IMAGE_ANNOTATIONS"]] retain];
		else
			annotationsLayoutDictionary = [[NSMutableDictionary dictionary] retain];
			
		currentModality = NSLocalizedString(@"Default", @"");
		
		skipTextViewDidChangeSelectionNotification = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationMouseDragged:) name:@"CIAAnnotationMouseDraggedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationMouseDown:) name:@"CIAAnnotationMouseDownNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationMouseUp:) name:@"CIAAnnotationMouseUpNotification" object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
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
	[[prefPane dicomNameTokenField] setTokenStyle:NSPlainTextTokenStyle];

	[[prefPane contentTokenField] setDelegate:self];

	// DICOM popup button
	[self prepareDICOMFieldsArrays];

	NSMenu *DICOMFieldsMenu = [[prefPane DICOMFieldsPopUpButton] menu];
	[DICOMFieldsMenu setAutoenablesItems:NO];
	
	for (i=0; i<[[DICOMFieldsMenu itemArray] count]; i++)
		[DICOMFieldsMenu removeItemAtIndex:i];
	
	NSMenuItem *item;
	item = [[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"DICOM Fields", @"")];
	[item setEnabled:NO];
	[DICOMFieldsMenu addItem:item];
	for (i=0; i<[DICOMFieldsArray count]; i++)
	{
		item = [[NSMenuItem alloc] init];
		[item setTitle:[[DICOMFieldsArray objectAtIndex:i] title]];
		[item setRepresentedObject:[DICOMFieldsArray objectAtIndex:i]];
		[DICOMFieldsMenu addItem:item];
		[item release];
	}
	
	[[prefPane DICOMFieldsPopUpButton] setMenu:DICOMFieldsMenu];
	
	// Database popup button
	[self prepareDatabaseFields];
	
	NSMenu *databaseFieldsMenu = [[prefPane databaseFieldsPopUpButton] menu];
	[databaseFieldsMenu setAutoenablesItems:NO];

	for (i=0; i<[[databaseFieldsMenu itemArray] count]; i++)
		[databaseFieldsMenu removeItemAtIndex:i];
	
	item = [[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"Study level", @"")];
	[item setEnabled:NO];
	[databaseFieldsMenu addItem:item];
	for (i=0; i<[databaseStudyFieldsArray count]; i++)
	{
		item = [[NSMenuItem alloc] init];
		[item setTitle:[NSString stringWithFormat:@"\t%@",[databaseStudyFieldsArray objectAtIndex:i]]];
		[item setRepresentedObject:[NSString stringWithFormat:@"study.%@",[databaseStudyFieldsArray objectAtIndex:i]]];
		[databaseFieldsMenu addItem:item];
		[item release];
	}

	[databaseFieldsMenu addItem:[NSMenuItem separatorItem]];	
	item = [[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"Series level", @"")];
	[item setEnabled:NO];
	[databaseFieldsMenu addItem:item];
	for (i=0; i<[databaseSeriesFieldsArray count]; i++)
	{
		item = [[NSMenuItem alloc] init];
		[item setTitle:[NSString stringWithFormat:@"\t%@",[databaseSeriesFieldsArray objectAtIndex:i]]];
		[item setRepresentedObject:[NSString stringWithFormat:@"series.%@",[databaseSeriesFieldsArray objectAtIndex:i]]];
		[databaseFieldsMenu addItem:item];
		[item release];
	}
	
	[databaseFieldsMenu addItem:[NSMenuItem separatorItem]];
	item = [[NSMenuItem alloc] init];
	[item setTitle:NSLocalizedString(@"Image level", @"")];
	[item setEnabled:NO];
	[databaseFieldsMenu addItem:item];
	for (i=0; i<[databaseImageFieldsArray count]; i++)
	{
		item = [[NSMenuItem alloc] init];
		[item setTitle:[NSString stringWithFormat:@"\t%@",[databaseImageFieldsArray objectAtIndex:i]]];
		[item setRepresentedObject:[NSString stringWithFormat:@"image.%@",[databaseImageFieldsArray objectAtIndex:i]]];
		[databaseFieldsMenu addItem:item];
		[item release];
	}
	
	// Specials popup button
	NSMenu *specialFieldsMenu = [[prefPane specialFieldsPopUpButton] menu];

	for (i=0; i<[[specialFieldsMenu itemArray] count]; i++)
		[specialFieldsMenu removeItemAtIndex:i];

	NSMutableArray *fields = [self specialFieldsTitles];

	for (i=0; i<[fields count]; i++)
	{
		item = [[NSMenuItem alloc] init];
		[item setTitle:[fields objectAtIndex:i]];
		[item setRepresentedObject:[fields objectAtIndex:i]];
		[specialFieldsMenu addItem:item];
		[item release];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[annotationsArray release];
	[DICOMFieldsArray release];
	[DICOMFieldsTitlesArray release];
	[databaseStudyFieldsArray release];
	[databaseSeriesFieldsArray release];
	[databaseImageFieldsArray release];
	[annotationsLayoutDictionary release];
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

		[self selectAnnotation:anAnnotation];
		[annotationsArray addObject:anAnnotation];
		[layoutView addSubview:anAnnotation];
		[layoutView setNeedsDisplay:YES];
		[anAnnotation release];
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
				for (j=0; j<[[currentPlaceHolder annotationsArray] count]-1; j++)
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
	selectedAnnotation = anAnnotation;
	[self didChangeValueForKey:@"selectedAnnotation"];

	[[prefPane titleTextField] setEnabled: YES];
	[[prefPane contentTokenField] setEnabled: YES];
	[self setCustomDICOMFieldEditingEnable: YES];
	
	[[prefPane titleTextField] setStringValue:[anAnnotation title]];
	[[prefPane contentTokenField] setObjectValue:[anAnnotation content]];
	
	[layoutView addSubview:anAnnotation]; // in order to bring the Annotation to front
	[layoutView setNeedsDisplay:YES];
	[self resizeTokenField];
	
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
	
	[[prefPane contentTokenField] sendAction:[[prefPane contentTokenField] action] to:[[prefPane contentTokenField] target]];

	// see if there is a selected Token in the NSTokenField
	BOOL aTokenIsSelected = NO;
	int tokenIndexInContent;
	NSRange range = [[[prefPane contentTokenField] currentEditor] selectedRange];

	if(range.length==1) // one and only one is selected
	{
		aTokenIsSelected = YES;
		tokenIndexInContent = range.location;
	}

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
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString,[selectedItem title]] inContentAtIndex:[selectedAnnotation countOfContent]];
		else
		{
			[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
			[selectedAnnotation insertObject:[NSString stringWithFormat:formatString,[selectedItem title]] inContentAtIndex:tokenIndexInContent];
		}
	}
	else if([sender isEqualTo:[prefPane addCustomDICOMFieldButton]])
	{
		if([[[prefPane dicomGroupTextField] stringValue] isEqualToString:@""] || [[[prefPane dicomElementTextField] stringValue] isEqualToString:@""])
		{
			NSRunAlertPanel(NSLocalizedString(@"Custom DICOM Field", @""), NSLocalizedString(@"Please provide a value for both \"Group\" and \"Element\" fields.", @""), NSLocalizedString(@"OK", @""), nil, nil);
			return;
		}
		
		if([[prefPane DICOMFieldsPopUpButton] indexOfSelectedItem]==0)
		{
			// custom field
			if([[[prefPane dicomNameTokenField] stringValue] isEqualToString:@""])
			{
				formatString = @"DICOM_%@_%@";
				if(!aTokenIsSelected)
					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue]] inContentAtIndex:[selectedAnnotation countOfContent]];
				else
				{
					[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue]] inContentAtIndex:tokenIndexInContent];
				}
			}
			else
			{
				formatString = @"DICOM_%@_%@_%@";
				if(!aTokenIsSelected)
					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue], [[prefPane dicomNameTokenField] stringValue]] inContentAtIndex:[selectedAnnotation countOfContent]];
				else
				{
					[selectedAnnotation removeObjectFromContentAtIndex:tokenIndexInContent];
					[selectedAnnotation insertObject:[NSString stringWithFormat:formatString, [[prefPane dicomGroupTextField] stringValue], [[prefPane dicomElementTextField] stringValue], [[prefPane dicomNameTokenField] stringValue]] inContentAtIndex:tokenIndexInContent];
				}
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

	[self resizeTokenField];
	
	if(!aTokenIsSelected)
	{
		// select added token
		[[self window] makeFirstResponder:[prefPane contentTokenField]];
		[[[prefPane contentTokenField] currentEditor] setSelectedRange:NSMakeRange([[selectedAnnotation content] count]-1, 1)];
	}
	
	[[prefPane contentTokenField] setNeedsDisplay:YES];
}

- (IBAction)validateTokenTextField:(id)sender;
{
	[[selectedAnnotation content] setArray:[[prefPane contentTokenField] objectValue]];
}

- (void)resizeTokenField;
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
		if(![[[prefPane dicomGroupTextField] stringValue] hasPrefix:@"0x"])
			[[prefPane dicomGroupTextField] setStringValue:[NSString stringWithFormat:@"0x%04d", [[prefPane dicomGroupTextField] intValue]]];
	}
	else if([[aNotification object] isEqualTo:[prefPane dicomElementTextField]])
	{
		if(![[[prefPane dicomElementTextField] stringValue] hasPrefix:@"0x"])
			[[prefPane dicomElementTextField] setStringValue:[NSString stringWithFormat:@"0x%04d", [[prefPane dicomElementTextField] intValue]]];
		
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
	else
		[self resizeTokenField];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard
{
	// handles drag & drop of several tokens
	return [[pboard stringForType:NSStringPboardType] componentsSeparatedByString:@", "];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index
{
	[self performSelector:@selector(resizeTokenField) withObject:nil afterDelay:0.1];
	return tokens;
}

- (void)prepareDatabaseFields;
{
	NSManagedObjectModel *currentModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"OsiriXDB_DataModel.mom"]]];
	
	NSArray *studies = [[[[currentModel entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
	NSArray *series = [[[[currentModel entitiesByName] objectForKey:@"Series"] attributesByName] allKeys];
	NSArray *images = [[[[currentModel entitiesByName] objectForKey:@"Image"] attributesByName] allKeys];

	[databaseStudyFieldsArray addObjectsFromArray:studies];
	[databaseSeriesFieldsArray addObjectsFromArray:series];
	[databaseImageFieldsArray addObjectsFromArray:images];
}

- (NSMutableArray*)specialFieldsTitles;
{
	NSMutableArray *specialFieldsTitles = [NSMutableArray array];
	[specialFieldsTitles addObject:NSLocalizedString(@"Image Size", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"View Size", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Window Level / Window Width", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Image Position", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Zoom", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Rotation Angle", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Mouse Position (px)", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Mouse Position (mm)", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Thickness / Location / Position", @"")];
	[specialFieldsTitles addObject:NSLocalizedString(@"Patient's Actual Age", @"")];
	return specialFieldsTitles;
}

// auto completion
- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex
{
	int i;
	NSMutableArray *resultArray = [NSMutableArray array];
	NSRange comparisonRange = NSMakeRange(0, [substring length]);
	
	if([tokenField isEqualTo:[prefPane contentTokenField]])
	{
		[resultArray addObject:substring];
		
		NSArray *titles = DICOMFieldsArray;
		NSString *currentTitle;

		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [[titles objectAtIndex:i] name];
			if([currentTitle compare:substring options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
				[resultArray addObject:[NSString stringWithFormat:@"DICOM_%@", currentTitle]];
		}
		
		titles = databaseStudyFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle compare:substring options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
				[resultArray addObject:[NSString stringWithFormat:@"DB_study.%@", currentTitle]];
		}
		titles = databaseSeriesFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle compare:substring options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
				[resultArray addObject:[NSString stringWithFormat:@"DB_series.%@", currentTitle]];
		}
		titles = databaseImageFieldsArray;
		for (i=0; i<[titles count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle compare:substring options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
				[resultArray addObject:[NSString stringWithFormat:@"DB_image.%@", currentTitle]];
		}
		
		titles = [[prefPane specialFieldsPopUpButton] itemTitles];
		for (i=0; i<[[[prefPane specialFieldsPopUpButton] itemTitles] count]; i++)
		{
			currentTitle = [titles objectAtIndex:i];
			if([currentTitle compare:substring options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
				[resultArray addObject:[NSString stringWithFormat:@"Special_%@", currentTitle]];
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
								[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:i+1];
								[[prefPane DICOMFieldsPopUpButton] setEnabled:YES];
								found = YES;
								break;
							}
						}
						
						if(!found)
						{
							// this is a custom DICOM field, with this format : DICOM_0x0001_0x0001 or DICOM_0x0001_0x0001_name
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
							
							[[prefPane DICOMFieldsPopUpButton] setEnabled:NO];
							[[prefPane DICOMFieldsPopUpButton] selectItemAtIndex:0];
						}
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
						[[prefPane specialFieldsPopUpButton] selectItemAtIndex:[[[prefPane specialFieldsPopUpButton] menu] indexOfItemWithRepresentedObject:selectedString]];
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
			int r = NSRunAlertPanel(NSLocalizedString(@"Saving Annotations", nil), NSLocalizedString(@"Any Annotation left outside the place holders will be lost.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil);
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
	int i, a;
	
	BOOL check = YES;
	
	CIAAnnotation *unfinishedAnnotation;
	
	NSArray *content;
	for (a=0; a<[annotationsArray count]; a++)
	{
		CIAAnnotation *annotation = [annotationsArray objectAtIndex:a];
		content = [annotation content];
		
		for (i=0; i<[content count]; i++)
		{
			NSString *token = [content objectAtIndex:i];
			if([token isEqualToString:@"DICOM_"] || [token isEqualToString:@"DB_"] || [token isEqualToString:@"Special_"])
			{
				check = NO;
				unfinishedAnnotation = annotation;
			}
		}
	}

	if(!check || [annotationsArray count]==0)
	{
		int r = NSRunAlertPanel(NSLocalizedString(@"Annotation Content", nil), NSLocalizedString(@"Some token have no content. Token such as 'DICOM_', 'DB_', 'Special_' will not be displayed.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil);
		if(r==NSAlertDefaultReturn)
			return YES;
		else
		{
			[self selectAnnotation:unfinishedAnnotation];
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)checkAnnotationContent:(CIAAnnotation*)annotation;
{
	NSArray *content = [annotation content];
	
	BOOL check = YES;
	
	int i;
	for (i=0; i<[content count]; i++)
	{
		NSString *token = [content objectAtIndex:i];
		if([token isEqualToString:@"DICOM_"] || [token isEqualToString:@"DB_"] || [token isEqualToString:@"Special_"])
		{
			check = NO;
//			int r = NSRunAlertPanel(NSLocalizedString(@"Annotation Content", nil), NSLocalizedString(@"Some token have no content. These token (such as 'DICOM_', 'DB_', 'Special_') will not be displayed.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil);
//			if(r==NSAlertDefaultReturn)
//				return YES;
//			else
//				return NO;
		}
	}

	if(!check || [content count]==0)
	{
		int r = NSRunAlertPanel(NSLocalizedString(@"Annotation Content", nil), NSLocalizedString(@"Some token have no content. Token such as 'DICOM_', 'DB_', 'Special_' will not be displayed.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil);
		if(r==NSAlertDefaultReturn)
			return YES;
		else
			return NO;
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
						if([currentField length]>6)
						{
							[fieldDict setObject:@"DICOM" forKey:@"type"];
							
							comparisonRange = NSMakeRange(6, [currentField length]-6);
							NSString *currentTitle;
							for (k=0; k<[DICOMFieldsArray count]; k++)
							{
								currentTitle = [[DICOMFieldsArray objectAtIndex:k] name];
								if([currentField compare:currentTitle options:NSCaseInsensitiveSearch range:comparisonRange]==NSOrderedSame)
								{
									[fieldDict setObject:[NSNumber numberWithInt:[[DICOMFieldsArray objectAtIndex:k] group]] forKey:@"group"];
									[fieldDict setObject:[NSNumber numberWithInt:[[DICOMFieldsArray objectAtIndex:k] element]] forKey:@"element"];
									[fieldDict setObject:[[DICOMFieldsArray objectAtIndex:k] name] forKey:@"name"];
									[fieldDict setObject:currentField forKey:@"tokenTitle"];
									[contentToSave addObject:fieldDict];
									break;
								}
							}
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
	if(![self checkAnnotations] || ![self checkAnnotationsContent])
	{
		[[prefPane modalitiesPopUpButton] setTitle:currentModality];//currentModality
		return;
	}
		
	[self validateTokenTextField:self];
	selectedAnnotation = nil;
	
	[[prefPane titleTextField] setEnabled: NO];
	[[prefPane contentTokenField] setEnabled: NO];
	[self setCustomDICOMFieldEditingEnable:NO];
	
	[self saveAnnotationLayoutForModality:currentModality];
	currentModality = [[sender selectedItem] title];
	[[prefPane sameAsDefaultButton] setHidden:[currentModality isEqualToString:@"Default"]];
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
	[layoutView setEnabled:YES];
	[[prefPane orientationWidgetButton] setEnabled:YES];
	
	if(n==0 && ![modality isEqualTo:@"Default"])
	{
		[self loadAnnotationLayoutForModality:@"Default"];
		[[prefPane sameAsDefaultButton] setState:NSOnState];
		[layoutView setEnabled:NO];
		[[prefPane orientationWidgetButton] setEnabled:NO];
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
