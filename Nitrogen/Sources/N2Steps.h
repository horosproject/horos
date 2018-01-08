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

#import <Cocoa/Cocoa.h>

@class N2Step; //, N2StepsView;

extern NSString * const __deprecated N2StepsDidAddStepNotification;
extern NSString * const __deprecated N2StepsWillRemoveStepNotification;
extern NSString * const __deprecated N2StepsNotificationStep;

__deprecated
@interface N2Steps : NSArrayController {
//	IBOutlet N2StepsView* _view;
	N2Step* _currentStep;
	IBOutlet id _delegate;
}

@property(retain) id delegate;
@property(nonatomic, assign) N2Step* currentStep;
//	@property(readonly) N2StepsView* view;

-(void)enableDisableSteps;

-(BOOL)hasNextStep;
-(BOOL)hasPreviousStep;

-(IBAction)stepDone:(id)sender;
-(IBAction)nextStep:(id)sender;
-(IBAction)previousStep:(id)sender;
-(IBAction)skipStep:(id)sender;
-(IBAction)stepValueChanged:(id)sender;
-(IBAction)reset:(id)sender;

-(void)setCurrentStep:(N2Step*)step;

@end

@interface NSObject (N2StepsDelegate)

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step __deprecated;
-(void)steps:(N2Steps*)steps valueChanged:(id)sender __deprecated;
-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step __deprecated;
-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step __deprecated;

@end
