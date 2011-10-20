/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>

@class N2Step; //, N2StepsView;

extern NSString* N2StepsDidAddStepNotification;
extern NSString* N2StepsWillRemoveStepNotification;
extern NSString* N2StepsNotificationStep;

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

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step;
-(void)steps:(N2Steps*)steps valueChanged:(id)sender;
-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step;
-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step;

@end