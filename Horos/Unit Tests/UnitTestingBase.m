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


/*
The idea is that as bugs are fixed the unit tests should be updated to exercise the fixed routine(s)
to prove that they stay fixed with future modifications.

Testable units are within OsiriX rather than its frameworks, eg DCMFramework.  This testing framework is linked with
the Development product.

This list of common macros is from the file:///System/Library/Frameworks/SenTestingKit.framework/Headers/SenTestCase.h


	STAssertNil(a1, description, ...)
	STAssertNotNil(a1, description, ...)
	STAssertTrue(expression, description, ...)
	STAssertFalse(expression, description, ...)
	STAssertEqualObjects(a1, a2, description, ...)
	STAssertEquals(a1, a2, description, ...)
	STAssertEqualsWithAccuracy(left, right, accuracy, description, ...)
	STAssertThrows(expression, description, ...)
	STAssertThrowsSpecific(expression, specificException, description, ...)
	STAssertThrowsSpecificNamed(expr, specificException, aName, description, ...)
	STAssertNoThrow(expression, description, ...)
	STAssertNoThrowSpecific(expression, specificException, description, ...)
	STAssertNoThrowSpecificNamed(expr, specificException, aName, description, ...)
	STFail(description, ...)
	STAssertTrueNoThrow(expression, description, ...)
	STAssertFalseNoThrow(expression, description, ...)
*/


#import "UnitTestingBase.h"

#import "Point3D.h"
#import "dicomData.h"
#import "DicomStudy.h"
#import "AppController.h"
#import "BrowserController.h"


@implementation UnitTestingBase

- (void) testExample
{
	int a = 3;
	BOOL trueValue = YES;
	
	STAssertEquals(a, 3, @"a3");
	STAssertTrue(trueValue, @"trueValue should be true at this point");
	
	Point3D *a3DPoint;
	
	a3DPoint=[Point3D alloc];STAssertNotNil(a3DPoint,Nil);
	
	[a3DPoint initWithValues: 10.2 : 10.3 : 10.4];
	STAssertEquals((float) 10.2, [a3DPoint x], @"3d x");
	STAssertEquals((float) 10.3, [a3DPoint y], @"3d y");
	STAssertEquals((float) 10.4, [a3DPoint z], @"3d z");
	
	[a3DPoint multiply: 201.5];
	STAssertEquals((float) 2055.3, [a3DPoint x], @"3d x");
	STAssertEquals((float) 2075.45, [a3DPoint y], @"3d y");
	STAssertEqualsWithAccuracy((float) 2095.6, [a3DPoint z], 0.01, @"3d z");
	
	if (![[a3DPoint description] isEqualToString: @"Point3D ( 2055.300049, 2075.449951, 2095.599854 )"])
		STFail([a3DPoint description]);
	
	[a3DPoint release];
}


//===========================================================================================================================================================================================
#pragma mark•

- (void) testDicomData
{
	dicomData *aDicomData, *aParentData;
	NSMutableArray *aParentArray, *aChildArray;
	
// Test initialisation of dicomData.
	
	aDicomData=[[[dicomData alloc] init] autorelease];STAssertNotNil(aDicomData, Nil);
	STAssertNil([aDicomData group], Nil);
	STAssertNil([aDicomData tagName], Nil);
	STAssertNil([aDicomData name], Nil);
	STAssertNil([aDicomData content], Nil);
	STAssertNil([aDicomData parent], Nil);
	STAssertNil([aDicomData child], Nil);
	STAssertNil([aDicomData parentData], Nil);

// Test setters and getters.
	
	[aDicomData setGroup: @"Test Group Name"];STAssertEquals([aDicomData group], @"Test Group Name", Nil);
	[aDicomData setTagName: @"Test Tag Name"];STAssertEquals([aDicomData tagName], @"Test Tag Name", Nil);
	[aDicomData setName: @"Test Name"];STAssertEquals([aDicomData name], @"Test Name", Nil);
	[aDicomData setContent: @"Test Content"];STAssertEquals([aDicomData content], @"Test Content", Nil);
	
	aParentArray=[NSMutableArray array];STAssertNotNil(aParentArray, Nil);
	[aDicomData setParent: aParentArray];STAssertEqualObjects([aDicomData parent], aParentArray, Nil);
	aChildArray=[NSMutableArray array];STAssertNotNil(aChildArray, Nil);
	[aDicomData setChild: aChildArray];STAssertEqualObjects([aDicomData child], aChildArray, Nil);
	
	aParentData=[[[dicomData alloc] init] autorelease];
	[aDicomData setParentData: aParentData];
	STAssertEqualObjects([aDicomData parentData], aParentData, Nil);
}

//===========================================================================================================================================================================================
#pragma mark•

- (void) testEndoscopyViewerInitialisation
{
	AppController *ac;
	BrowserController *bc;

// Check the app controller is valid.

	ac=[AppController sharedAppController];
	STAssertNotNil(ac, Nil);

// Get the current browser and check it's valid.

	bc=[BrowserController currentBrowser];
	STAssertNotNil([BrowserController currentBrowser], Nil);

// Open selected series.

	[bc newViewerDICOM: Nil];
	
// Open the endoscopy viewer.

	[self performSelector: @selector(openAViewer:) withObject: Nil afterDelay: 4];

// Close all viewers.

	[ac closeAllViewers: Nil];
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) openAViewer: (id) i
{
	NSWindow *win;

// Open the endoscopy viewer.

	win=[NSApp mainWindow];
	STAssertNotNil(win, Nil);
//	[NSApp sendAction: @selector(MPR2DViewer:) to: [win windowController] from: self];
	[NSApp sendAction: @selector(endoscopyViewer:) to: [win windowController] from: self];
}


//===========================================================================================================================================================================================
#pragma mark•

- (void) testCLUTMenuLoaded
{
	NSMenu *mainMenu, *viewerMenu, *clutMenu;
	
    mainMenu=[NSApp mainMenu];STAssertNotNil(mainMenu,Nil);
    viewerMenu=[[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];STAssertNotNil(viewerMenu,Nil);
    clutMenu=[[viewerMenu itemWithTitle:NSLocalizedString(@"Color Look Up Table", nil)] submenu];STAssertNotNil(clutMenu,@"Check localized strings for 'color look up table' are correct");
}

@end
