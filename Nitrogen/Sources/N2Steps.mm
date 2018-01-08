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

#import <N2Steps.h>
#import <N2Step.h>
#import <N2StepView.h>

NSString * const N2StepsDidAddStepNotification = @"N2StepsDidAddStepNotification";
NSString * const N2StepsWillRemoveStepNotification = @"N2StepsWillRemoveStepNotification";
NSString * const N2StepsNotificationStep = @"N2StepsNotificationStep";

@implementation N2Steps
@synthesize delegate = _delegate, currentStep = _currentStep;//, view = _view;

-(id)init {
	self = [super init];
	
	return self;
}

-(void)addObject:(id)obj {
	NSAssert([obj isKindOfClass:[N2Step class]], @"[N2Steps addObject:] only accepts objects inheriting from class N2Step");
	[super addObject:obj];
	[[NSNotificationCenter defaultCenter] postNotificationName:N2StepsDidAddStepNotification object:self userInfo:[NSDictionary dictionaryWithObject:obj forKey:N2StepsNotificationStep]];
	if (!_currentStep) [self setCurrentStep:obj];
}

-(void)removeObject:(id)obj {
	[[NSNotificationCenter defaultCenter] postNotificationName:N2StepsWillRemoveStepNotification object:self userInfo:[NSDictionary dictionaryWithObject:obj forKey:N2StepsNotificationStep]];
	[super removeObject:obj];
}

// enables the steps until a necessary and non done step is encountered
-(void)enableDisableSteps {
	BOOL enable = YES;
	for (unsigned i = [[self content] indexOfObject:_currentStep]; i < [[self content] count]; ++i) {
		N2Step* step = [[self content] objectAtIndex:i];
		[step setEnabled:enable];
		if ([step isNecessary] && ![step isDone])
			enable = NO;
	}
}

-(void)setCurrentStep:(N2Step*)step {
//	if (step == _currentStep)
//		return;
	
	if (![[self content] containsObject:step])
		return;
	
	if (_currentStep != step)
		[_currentStep setActive:NO];
	
	_currentStep = step;
	
	[_currentStep setActive:YES];
	[self enableDisableSteps];
	
	if (_delegate && [_delegate respondsToSelector:@selector(steps:willBeginStep:)])
		[_delegate steps:self willBeginStep:[self currentStep]];
}

-(BOOL)hasNextStep {
	return [[self content] indexOfObject:_currentStep] < (long)[[self content] count]-1;
}

-(BOOL)hasPreviousStep {
	return [[self content] indexOfObject:_currentStep] > 0;
}

-(IBAction)stepDone:(id)sender {
	N2Step* step = NULL;
	if ([sender isKindOfClass:[N2Step class]])
		step = (id)sender;
	if ([sender isKindOfClass:[NSView class]]) {
		N2StepView* view = (id)sender;
		while (view && ![view isKindOfClass:[N2StepView class]])
			view = (id)view.superview;
		step = view.step;
	}
	
	if (!step) {
		NSLog(@"Warning: unidentified step done");
		return;
	}
	
	if ([_delegate respondsToSelector:@selector(steps:shouldValidateStep:)] && ![_delegate steps:self shouldValidateStep:step])
		return;
	
	if ([_delegate respondsToSelector:@selector(steps:validateStep:)])
		[_delegate steps:self validateStep:step];
	[step setDone:YES];
	
	if (_currentStep == step && [self hasNextStep])
		[self setCurrentStep:[[self content] objectAtIndex:[[self content] indexOfObject:step]+1]];
}

-(IBAction)nextStep:(id)sender {
	[self stepDone:sender];
}

-(IBAction)previousStep:(id)sender {
	if (![self hasPreviousStep])
		return;
	
	[self setCurrentStep:[[self content] objectAtIndex:[[self content] indexOfObject:_currentStep]-1]];
}

-(IBAction)skipStep:(id)sender {
	if ([[self currentStep] isNecessary])
		return;
	
	if (![self hasNextStep])
		return;
	
	[self setCurrentStep:[[self content] objectAtIndex:[[self content] indexOfObject:_currentStep]+1]];
}

-(IBAction)stepValueChanged:(id)sender {
	if (_delegate && [_delegate respondsToSelector:@selector(steps:valueChanged:)])
		[_delegate steps:self valueChanged:sender];
}

-(IBAction)reset:(id)sender; {
	for (unsigned i = 0; i < [[self content] count]; ++i)
		[[[self content] objectAtIndex:i] setDone:NO];
	
	[self setCurrentStep:[[self content] objectAtIndex:0]];
}

@end
