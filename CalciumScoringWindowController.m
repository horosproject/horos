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

/*************************************************************
Manages the Window for creating Calcium Scoring ROIs
***************************************************************/

#import "ITKSegmentation3D.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#import "browserController.h"
#import <OsiriX/DCM.h>
#import "CalciumScoringWindowController.h"
#import "Notifications.h"

enum ctTypes {ElectronCTType, MultiSliceCTType};
@implementation CalciumScoringWindowController

- (id)initWithViewer:(ViewerController *)viewer
{
	if (self = [super initWithWindowNibName:@"CalciumScoring"])
	{
		_viewer = viewer;
		[self setUpperThreshold:1500];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[self setCtType:[[userDefaults objectForKey:@"CalciumScoreCTType"] intValue]];
	
		_rois = [[NSMutableSet alloc] init];
		_vesselNames = [[NSArray arrayWithObjects:NSLocalizedString(@"Left Coronary Artery", nil),
														NSLocalizedString(@"Left Anterior Descending Artery", nil),
														NSLocalizedString(@"Left Circumflex Artery", nil),
														NSLocalizedString(@"Right Coronary Artery", nil),
														nil] retain];
		
		_vessels = [[NSMutableArray alloc] init];
		NSString *name;
		for (name in _vesselNames)
		{
			[(NSMutableArray *)_vessels addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: name, @"vesselName",
															[NSNumber numberWithFloat:0.0], @"score",
															[NSNumber numberWithFloat:0.0], @"mass",
															[NSNumber numberWithFloat:0.0], @"volume",
															nil]];
				// get exisiting ROIs
				NSArray *roiList = [_viewer roisWithName:name];
				[_rois addObjectsFromArray:roiList];
		}
		
		[(NSMutableArray *)_vessels addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"Total", nil), @"vesselName",
															[NSNumber numberWithFloat:0.0], @"score",
															[NSNumber numberWithFloat:0.0], @"mass",
															[NSNumber numberWithFloat:0.0], @"volume",
															nil]];
		
		[self setRoiName:NSLocalizedString(@"Left Coronary Artery", nil)];
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(mouseViewerDown:)
				   name: OsirixMouseDownNotification
				 object: nil];
				 
		
		[nc addObserver: self
				selector: @selector(drawStartingPoint:)
				   name: OsirixDrawObjectsNotification
				 object: nil];
				 
		[nc addObserver: self
				selector: @selector(removeROI:)
				   name:  OsirixRemoveROINotification
				 object: nil];
	}
	return self;
}

- (void)windowDidLoad
{
	[self updateTotals];
	
	
	[[self window] setDelegate: self];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
				selector: @selector(windowDidBeomeKey:)
				   name:  NSWindowDidBecomeMainNotification
				 object: [self window]];

	[[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];
	
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self autorelease];
}

-(void) CloseViewerNotification:(NSNotification*) note
{
	if( [note object] == _viewer) [[self window] close];
}

- (void)dealloc{
	[_rois release];
	[_roiName release];
	[_vessels release];
	[_vesselNames release];
	[_startingPointPixelPosition release];
	[_startingPointWorldPosition release];
	[_startingPointValue release];
	[super dealloc];
}


- (int)ctType{
	return _ctType;
}

- (void)setCtType:(int)ctType{
	_ctType = ctType;
	if (_ctType == ElectronCTType)
		[self setLowerThreshold:90];
	if (_ctType == MultiSliceCTType) 
		[self setLowerThreshold:130];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_ctType] forKey:@"CalciumScoreCTType"];
	[self updateTotals];
}

- (int)lowerThreshold{
	return _lowerThreshold;
}
- (void)setLowerThreshold:(int)lowerThreshold{
	NSLog(@"set Lower Threshold: %d", lowerThreshold);
	_lowerThreshold = lowerThreshold;
}
- (int)upperThreshold{
	return _upperThreshold;
}

- (void)setUpperThreshold:(int)upperThreshold{
	_upperThreshold = upperThreshold;
}
- (NSMutableSet *)rois{
	return _rois;
}
- (void)setRois:(NSMutableSet *)rois{
	[_rois release];
	_rois = [rois retain];
}

- (NSString *)roiName{
	return _roiName;
}

- (void)setRoiName:(NSString *)roiName{
	[_roiName release];
	_roiName = [roiName retain];
	if (![_vesselNames containsObject:roiName])
	{
		NSArray *vesselNames = [_vesselNames arrayByAddingObject:roiName];
		[self setVesselNames:vesselNames];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"vesselName like %@", roiName];
		NSArray *filteredVessels = [_vessels filteredArrayUsingPredicate:predicate];
		if ([filteredVessels count] == 0)
		{
			NSMutableArray *vessels = [NSMutableArray arrayWithArray:_vessels];
			[vessels insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: roiName, @"vesselName",
															[NSNumber numberWithFloat:0.0], @"score",
															[NSNumber numberWithFloat:0.0], @"mass",
															[NSNumber numberWithFloat:0.0], @"volume",
															nil]
			atIndex:[vessels count] - 1];
			[self setVessels:vessels];
		}
		
	}
}

- (void)removeROI:(NSNotification*) note{
	[_rois removeObject:[note object]];
	[self updateTotals];
}

- (void)windowDidBeomeKey:(NSNotification*) note {
	[self updateTotals];
}

- (void) mouseViewerDown:(NSNotification*) note
{
	if([note object] == _viewer)
	{
		int xpx, ypx, zpx; // coordinate in pixels
		float xmm, ymm, zmm; // coordinate in millimeters
		
		xpx = [[[note userInfo] objectForKey:@"X"] intValue];
		ypx = [[[note userInfo] objectForKey:@"Y"] intValue];
		zpx = [[_viewer imageView] curImage];
		
		float location[3];
		[[[_viewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location pixelCenter: YES];
		xmm = location[0];
		ymm = location[1];
		zmm = location[2];
		
		[self setStartingPointPixelPosition:[NSString stringWithFormat:NSLocalizedString(@"px:\t\tx:%d y:%d", nil), xpx, ypx]];
		[self setStartingPointWorldPosition:[NSString stringWithFormat:NSLocalizedString(@"mm:\t\tx:%2.2f y:%2.2f z:%2.2f", nil), xmm, ymm, zmm]];
		[self setStartingPointValue:[NSString stringWithFormat:NSLocalizedString(@"value:\t%2.2f", nil), [[[_viewer imageView] curDCM] getPixelValueX: xpx Y:ypx]]];
		_startingPoint = NSMakePoint(xpx, ypx);
		
		[self compute: self];
		
	}
}

- (void) drawStartingPoint:(NSNotification*) note
{
	if([note object] == [_viewer imageView])
	{
		if( _startingPoint.x != 0 && _startingPoint.y != 0)
		{
			NSDictionary	*userInfo = [note userInfo];
			
			CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
            if( cgl_ctx == nil)
                return;
            
			glColor3f (0.0f, 1.0f, 0.5f);
			glLineWidth(2.0 * self.window.backingScaleFactor);
			glBegin(GL_LINES);
			
			float crossx, crossy, scaleValue = [[userInfo valueForKey:@"scaleValue"] floatValue];
			
			crossx = _startingPoint.x - [[userInfo valueForKey:@"offsetx"] floatValue];
			crossy = _startingPoint.y - [[userInfo valueForKey:@"offsety"] floatValue];
			
			glVertex2f( scaleValue * (crossx - 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx - 5), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 5), scaleValue*(crossy));
			
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-40));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+40));
			glEnd();
		}
	}
}

-(NSString *)startingPointPixelPosition{
	return _startingPointPixelPosition;
}

- (void)setStartingPointPixelPosition:(NSString *)position{
	[_startingPointPixelPosition release];
	_startingPointPixelPosition  = [position retain];
}

-(NSString *)startingPointWorldPosition{
	return _startingPointWorldPosition;
}

- (void)setStartingPointWorldPosition:(NSString *)position{
	[_startingPointWorldPosition release];
	_startingPointWorldPosition = [position retain];
}

-(NSString *)startingPointValue{
	return _startingPointValue;
}

- (void)setStartingPointValue:(NSString *)value{
	[_startingPointValue release];
	_startingPointValue = [value retain];
}

-(IBAction) preview:(id) sender {
	[self computeROIsWithName:NSLocalizedString( @"Segmentation Preview", nil) addROIs:NO];
}

-(IBAction) compute:(id) sender {
	[self computeROIsWithName:_roiName addROIs:YES];
	
}

- (IBAction)saveDocument: (id)sender{
	// save ROI as DICOM PDF
	NSLog(@"Save Calcium Score");
	NSMutableData *pdf = [NSMutableData dataWithData:[_printView dataWithPDFInsideRect:[_printView frame]]];
		//if we have an image  get the info we need from the imageRep.
	if (pdf ){	
		id study = [_viewer currentStudy]; 
		// pad data
		if ([pdf length] % 2 != 0)
			[pdf increaseLengthBy:1];
		// create DICOM OBJECT
		DCMObject *dcmObject = [DCMObject encapsulatedPDF:pdf];
		
		[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[study valueForKey:@"studyInstanceUID"]] forName:@"StudyInstanceUID"];
		//[dcmObject setAttributeValues:[NSArray arrayWithObject:_seriesInstanceUID] forName:@"SeriesInstanceUID"];
		[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"PDF"] forName:@"SeriesDescription"];
		//Add name
		if ([self patientsName])
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[self patientsName]] forName:@"PatientsName"];
		else
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@""] forName:@"PatientsName"];
		//add ID	
		if ([self patientID])
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[self patientID]] forName:@"PatientID"];
		else
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"0"] forName:@"PatientID"];
		// Add sex
		if ([self patientsSex])
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[self patientsSex]] forName:@"PatientsSex"];
		else
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@""] forName:@"PatientsSex"];
		// add DOB	
		if ([self patientsDOB])
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate:[study valueForKey:@"dateOfBirth"]]] forName:@"PatientsBirthDate"];
		
		// set Title
		[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"Calcium Score "] forName:@"DocumentTitle"];
		// Instance Number
		[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", 1]] forName:@"InstanceNumber"];
		// add Study ID	
		if ([study valueForKey:@"id"])
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[study valueForKey:@"id"]] forName:@"StudyID"];
		else
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", 0001]] forName:@"StudyID"];
	
		
		// Add Dates
		DCMCalendarDate *date = [DCMCalendarDate dicomDateWithDate:[study valueForKey:@"date"]];
		if (date)
		{
			NSLog(@"Date: %@", [study valueForKey:@"date"]);
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate:[study valueForKey:@"date"]]] forName:@"StudyDate"];
		}
		else
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate:[NSDate date]]] forName:@"StudyDate"];
			
	
		DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[study valueForKey:@"date"]];
		if (time)	
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:time] forName:@"StudyTime"];
		else
			[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]] forName:@"StudyTime"];
	


		[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate:[NSDate date]]] forName:@"SeriesDate"];			
		[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]] forName:@"SeriesTime"];
			
		//NSLog(@"pdf: %@", [dcmObject description]);
		//get Incoming Folder Path;
		NSString *destination = [NSString stringWithFormat: @"%@/CalciumScore%d%d.dcm", [[BrowserController currentBrowser] INCOMINGPATH], 1, 1]; 
	
		if ([dcmObject writeToFile:destination withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES])
			NSLog(@"Wrote Calcium Score to %@", destination);
	}
}


- (void)computeROIsWithName:(NSString *)name addROIs:(BOOL)addROIs;
{
	[_viewer roiDeleteWithName: NSLocalizedString( @"Segmentation Preview", nil)];
	
	if ( _startingPoint.x == 0 && _startingPoint.y == 0)
	{
		return;
	}
	
	long slice = [[_viewer imageView] curImage];
	
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[_viewer pixList] :[_viewer volumePtr] :slice];
	if( itk)
	{
		NSLog(@"Lower Threshold: %d", _lowerThreshold);
		NSArray *parametersArray = [NSArray arrayWithObjects:
					[NSNumber numberWithInt:_lowerThreshold],
					[NSNumber numberWithInt:_upperThreshold],
					nil];
		
        NSString *temporaryName = [NSString stringWithFormat: @"%ld", (unsigned long) [NSDate timeIntervalSinceReferenceDate]];
        
		[itk regionGrowing3D	: _viewer
								: nil
								: slice
								: _startingPoint
								: 1  //threshold upper and lower limits type
								: parametersArray  // parameter values
								: 0 // next for are used for setting pixels
								: 0
								: 0
								: 0
								: 0 // Brush ROI
								: 1
								: temporaryName
								: NO];
		
        // Check that there are no overlaping ROIs
        
        ROI *newROI = nil;
        
        for( ROI *r in _viewer.imageView.curRoiList)
        {
            if( [r.name isEqualToString: temporaryName])
                newROI = r;
        }
        
        if( newROI)
        {
            NSRect newRoiRect = NSMakeRect( newROI.textureUpLeftCornerX, newROI.textureUpLeftCornerY, newROI.textureWidth, newROI.textureHeight);
            
            float *locations = nil;
            long numberOfValues = 0;
            float *newRoiValues = [_viewer.imageView.curDCM getROIValue: &numberOfValues : newROI : &locations];
            
            
            NSMutableArray *roisToDelete = [NSMutableArray array];
            
            for( ROI *r in _viewer.imageView.curRoiList)
            {
                if( r.type == tPlain && r != newROI)
                {
                    NSRect roiRect = NSMakeRect( r.textureUpLeftCornerX, r.textureUpLeftCornerY, r.textureWidth, r.textureHeight);
                    
                    if( NSIntersectsRect( roiRect, newRoiRect))
                    {
                        BOOL intersect = NO;
                        float *l = nil;
                        long n = 0;
                        float *nRV = [_viewer.imageView.curDCM getROIValue: &n : r : &l];
                        
                        for( long i = 0; i < n; i++)
                        {
                            if( nRV[ i] != 0)
                            {
                                int x = l[ i*2];
                                int y = l[ i*2 + 1];
                                
                                for( long j = 0; j < numberOfValues; j++)
                                {
                                    if( newRoiValues[ j] != 0)
                                    {
                                        int newX = locations[ j*2];
                                        int newY = locations[ j*2 + 1];
                                        
                                        if( newX == x && newY == y)
                                            intersect = YES;
                                    }
                                }
                            }
                        }
                            
                        if( l)
                            free( l);
                        
                        if( nRV)
                            free( nRV);
                        
                        if( intersect)
                        {
                            //Delete this ROI
                            [roisToDelete addObject: r];
                        }
                    }
                }
            }
            
            if( locations)
                free( locations);
            
            if( newRoiValues)
                free( newRoiValues);
            
            for( ROI *r in roisToDelete)
                [_viewer deleteROI: r];
        }
        
        newROI.name = name;
        
		[itk release];
	}
	
	NSArray *roiList = [_viewer roisWithName:name];
	for(ROI *roi in roiList)
	{
		[roi setDisplayCalciumScoring:YES];
		if (addROIs)
		{
			RGBColor aColor;
			[_rois addObject:roi];
			if ([[roi name] isEqualToString:NSLocalizedString(@"Left Coronary Artery", nil)])
			{
					aColor.red = 65535;
					aColor.green =0;
					aColor.blue = 0;
			}	
			else if ([[roi name] isEqualToString:NSLocalizedString(@"Left Anterior Descending Artery", nil)])
			{
					aColor.red = 0;
					aColor.green =0;
					aColor.blue = 65535;
			}
			else if ([[roi name] isEqualToString:NSLocalizedString(@"Left Circumflex Artery", nil)])
			{
					aColor.red = 65535;
					aColor.green =65535;
					aColor.blue = 0;
			}
			else if ([[roi name] isEqualToString:NSLocalizedString(@"Right Coronary Artery", nil)])
			{	
					aColor.red = 65535;
					aColor.green =0;
					aColor.blue = 65535;
			}
			else {
					aColor.red = 0;
					aColor.green =65535;
					aColor.blue = 0;
			}
			
			[roi setColor:aColor];
		}
	}
	
	if (addROIs)
		[self updateTotals];
}

- (void)updateTotals{
	float totalScore = 0.0;
	float totalMass = 0.0;
	float totalVolume = 0.0;
	NSMutableDictionary *vessel;
	for (vessel in _vessels)
	{
		NSString *vesselName = [vessel objectForKey:@"vesselName"];
		//NSLog(@"vessel: %@", vesselName);
		if ([vesselName isEqualToString:NSLocalizedString(@"Total", nil)])
		{
			[vessel setValue:[NSNumber numberWithFloat:totalScore] forKey:@"score"];
			[vessel setValue:[NSNumber numberWithFloat:totalMass] forKey:@"mass"];
			[vessel setValue:[NSNumber numberWithFloat:totalVolume] forKey:@"volume"];
			break;
		}
			
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like %@", vesselName];
		NSArray *filteredROIs = [[_rois allObjects] filteredArrayUsingPredicate:predicate];
		NSEnumerator *enumerator = [filteredROIs objectEnumerator];
		ROI *roi;
		float segmentScore = 0.0;
		float segmentMass = 0.0;
		float segmentVolume = 0.0;
		while (roi = [enumerator nextObject])
		{
			//NSLog(@"roi: %@", [roi name]);
			[roi setCalciumThreshold:_lowerThreshold];
			totalScore += [roi calciumScore];
			totalMass += [roi calciumMass];
			totalVolume += [roi calciumVolume];
			segmentScore += [roi calciumScore];
			segmentMass += [roi calciumMass];
			segmentVolume += [roi calciumVolume];
		}
		
		[vessel setValue:[NSNumber numberWithFloat:segmentScore] forKey:@"score"];
		[vessel setValue:[NSNumber numberWithFloat:segmentMass] forKey:@"mass"];
		[vessel setValue:[NSNumber numberWithFloat:segmentVolume] forKey:@"volume"];
		[self setTotalCalciumScore:totalScore];
		[self setTotalCalciumMass:totalMass];
		[self setTotalCalciumVolume:totalVolume];
	}
}

//Total Calcium.

- (float)totalCalciumScore{
	return _totalCalciumScore;
}
- (float)totalCalciumMass{
	return _totalCalciumMass;
}
- (float)totalCalciumVolume{
	return _totalCalciumVolume;
}

- (void)setTotalCalciumScore: (float)score{
	_totalCalciumScore = score;
}
- (void)setTotalCalciumMass: (float)mass{
	_totalCalciumMass = mass;
}
- (void)setTotalCalciumVolume: (float)volume{
	_totalCalciumVolume = volume;
}

- (NSArray *)vessels{
	return _vessels;
}
- (void)setVessels:(NSArray *)vessels{
	[_vessels release];
	_vessels = [vessels retain];
}

- (NSArray *)vesselNames{
	return _vesselNames;
}

- (void)setVesselNames:(NSArray *)names{
	[_vesselNames release];
	_vesselNames = [names retain];
}

// for printing and PDF creation
- (NSString *)institution{
	return [[_viewer currentStudy] valueForKey:@"institutionName"];
}
- (NSString *)patientID{
	return [[_viewer currentStudy] valueForKey:@"patientID"];
}
- (NSDate *)studyDate{
	return [[_viewer currentStudy] valueForKey:@"date"];
}
- (NSString *)patientsName{
	return [[_viewer currentStudy] valueForKey:@"name"];
}
- (NSString *)patientsSex{
	return [[_viewer currentStudy] valueForKey:@"patientSex"];
}
- (NSString *)patientsAge{
	NSCalendarDate *dob = [[[_viewer currentStudy] valueForKey:@"dateOfBirth"] dateWithCalendarFormat:nil timeZone:nil];
	NSCalendarDate *studyDate = [[[_viewer currentStudy] valueForKey:@"date"] dateWithCalendarFormat:nil timeZone:nil];
	NSInteger years;
	NSInteger days;
	NSInteger months;
	if (dob && studyDate)
	{
		[studyDate years:&years
		 months:&months
		 days:&days
		 hours:0
		 minutes:0
		 seconds:0
		 sinceDate:dob] ;
		 if (years > 0)
			return [NSString stringWithFormat:@"%d Y", (int) years];
		else if (months > 0)
			return [NSString stringWithFormat: @"%d M", (int) months];
		else
			return [NSString stringWithFormat: @"%d D", (int) days];
	}
	return nil;
}

- (NSDate *)patientsDOB{
	return [[_viewer currentStudy] valueForKey:@"dateOfBirth"];
}

- (void)print:(id)sender{
	[_printView print:sender];
}







@end
