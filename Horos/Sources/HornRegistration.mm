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

#import "HornRegistration.h"

#include <vtkLandmarkTransform.h>
#include <vtkPoints.h>
#include <vtkMatrix4x4.h>

#include <stdio.h>

//#include "etkRegistration.hpp"

@implementation HornRegistration

//+ (void) test
//{
//	double adModelPoints  [][3] = {{0, 0, 0}, {10, 0, 0}, {10, 10, 0}, {0, 10, 0}};
//	double adSensorPoints [][3] = {{5, 0, 0}, {5, 10, 0}, {5, 10, 11}, {5, 0, 10}};
//
//	printf ("Horn Registration Test\n\n");
//
//	unsigned u, v;
//
//	// Create the registration structure
//	etkRegistration* pReg = etkCreateRegistration ();
//
//	// Set the number of points to register
//	pReg->uNbPoints = 4;
//
//	// Copy the model points in the etkRegistration structure
//	for (u = 0; u < 4; u++)
//	{
//		printf ("Model point (#%d): ", u);
//		for (v = 0; v < 3; v++)
//		{
//			pReg->adModelPoints [u][v] = adModelPoints [u][v];
//			printf ("\t%3.2f", pReg->adModelPoints [u][v]);
//		}
//		printf ("\n");
//	}
//	printf ("\n");
//
//	// Copy the sensor points in the etkRegistration structure
//	for (u = 0; u < 4; u++)
//	{
//		printf ("Sensor point (#%d): ", u);
//		for (v = 0; v < 3; v++)
//		{
//			pReg->adSensorPoints [u][v] = adSensorPoints [u][v];
//			printf ("\t%3.2f", pReg->adSensorPoints [u][v]);
//		}
//		printf ("\n");
//	}
//
//	double* adRot = NULL;
//	double* adTrans = NULL;
//
//	double dError = etkRegister (pReg, &adRot, &adTrans);
//
//	if (dError < 0.0)
//	{
//		printf ("Error in etkRegister");
//	}
//	else
//	{
//		// Display translation
//		printf ("\nTranslation:\n");
//		for (u = 0; u < 3; u++)
//			printf ("\t%3.2f", adTrans [u]);
//		printf ("\n\n");
//
//		// Display rotation
//		printf ("Rotation:\n");
//		for (u = 0; u < 3; u++)
//		{
//			for (v = 0; v < 3; v++)
//				printf ("\t%3.2f", adRot [u*3+v]);
//			printf ("\n");
//		}
//		printf ("\n\n");
//
//		printf ("Error (RMS):\n\t%lf\n\n", dError);
//	}
//}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		modelPoints = [[NSMutableArray alloc] initWithCapacity:0];
		sensorPoints = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

- (void) dealloc
{
	[modelPoints release];
	[sensorPoints release];
	if(adRot) free(adRot);
	if(adTrans) free(adTrans);
	[super dealloc];
}


- (void) addModelPointX: (double) x Y: (double) y Z: (double) z 
{
	//double *modelPoint;
	double modelPoint[ 3];
	modelPoint[0]=x;
	modelPoint[1]=y;
	modelPoint[2]=z;
	[self addModelPoint: modelPoint];
}

- (void) addSensorPointX: (double) x Y: (double) y Z: (double) z 
{
	//double *sensorPoint;
	double sensorPoint[ 3];
	sensorPoint[0]=x;
	sensorPoint[1]=y;
	sensorPoint[2]=z;
	[self addSensorPoint: sensorPoint];
}

- (void) addModelPoint: (double*) point
{
	[modelPoints addObject:[NSValue valueWithBytes:point objCType:@encode(double[3])]];
}

- (void) addSensorPoint: (double*) point
{
	[sensorPoints addObject:[NSValue valueWithBytes:point objCType:@encode(double[3])]];
}

// You shouldn't call this function directly (or do it when all the points have been added)
- (short) numberOfPoint
{
	short modelCount = [modelPoints count];
	short sensorCount = [sensorPoints count];
	if(modelCount == sensorCount)
	{
		return modelCount;
	}
	else
	{
		return -1;
	}
}

- (void) computeVTK:(double*) matrixResult
{
	short numberOfPoint = [self numberOfPoint];
	
	if (numberOfPoint>0)
	{
		vtkLandmarkTransform	*trans = vtkLandmarkTransform::New();
		
		vtkPoints	*modelPts = vtkPoints::New();
		vtkPoints	*sensorPts = vtkPoints::New();
		
		modelPts->SetNumberOfPoints( numberOfPoint);
		sensorPts->SetNumberOfPoints( numberOfPoint);
		
		double pt3D[ 3];
		int u;
		
		for (u = 0; u < numberOfPoint; u++)
		{
			[[modelPoints objectAtIndex:u] getValue: pt3D];
			modelPts->SetPoint( u, pt3D);
			
			[[sensorPoints objectAtIndex:u] getValue: pt3D];
			sensorPts->SetPoint( u, pt3D);
		}
		
		trans->SetSourceLandmarks( modelPts);
		trans->SetTargetLandmarks( sensorPts);
		trans->Update();
		
		vtkMatrix4x4 *matrix = trans->GetMatrix();
		
		int x, y;
		
		u = 0;
		
		for( x = 0 ; x < 3; x++)
		{
			for( y = 0; y < 3; y++)
			{
				matrixResult[ u] = matrix->Element[ x][ y];
				
				u++;
			}
			
			NSLog( @"%f %f %f", matrixResult[ u-3], matrixResult[ u-2], matrixResult[ u-1]);
		}
		
		matrixResult[ u] = matrix->Element[ 0][ 3];
		u++;
		matrixResult[ u] = matrix->Element[ 1][ 3];
		u++;
		matrixResult[ u] = matrix->Element[ 2][ 3];
		u++;
		
		modelPts->Delete();
		sensorPts->Delete();
		
		trans->Delete();
	}
}

// Call this function when all the points have been added
//- (void) compute
//{
//	short numberOfPoint = [self numberOfPoint];
//	
//	if (numberOfPoint>0)
//	{
//		// Create the registration structure
//		etkRegistration* pReg = etkCreateRegistration ();
//
//		// Set the number of points to register
//		pReg->uNbPoints = numberOfPoint;
//		
//		unsigned u, v;
//		
//		// Copy the model points in the etkRegistration structure
//		double *modelPoint = (double*) malloc(3*sizeof(double));
//		for (u = 0; u < numberOfPoint; u++)
//		{
//			printf ("Model point (#%d): ", u);
//			[[modelPoints objectAtIndex:u] getValue:modelPoint];
//			
//			for (v = 0; v < 3; v++)
//			{
//				pReg->adModelPoints[u][v] = modelPoint[v];
//				printf ("\t%3.2f", pReg->adModelPoints[u][v]);
//			}
//			printf ("\n");
//		}
//		printf ("\n");
//		
//		// Copy the sensor points in the etkRegistration structure
//		double *sensorPoint = (double*) malloc(3*sizeof(double));
//		for (u = 0; u < numberOfPoint; u++)
//		{
//			printf ("Sensor point (#%d): ", u);
//			[[sensorPoints objectAtIndex:u] getValue:sensorPoint];
//			
//			for (v = 0; v < 3; v++)
//			{
//				pReg->adSensorPoints[u][v] = sensorPoint[v];
//				printf ("\t%3.2f", pReg->adSensorPoints[u][v]);
//			}
//			printf ("\n");
//		}
//
//		double dError = etkRegister (pReg, &adRot, &adTrans);
//
//		if (dError < 0.0)
//		{
//			printf ("Error in etkRegister");
//		}
//		else
//		{
//			// Display translation
//			printf ("\nTranslation:\n");
//			for (u = 0; u < 3; u++)
//				printf ("\t%3.2f", adTrans [u]);
//			printf ("\n\n");
//
//			// Display rotation
//			printf ("Rotation:\n");
//			for (u = 0; u < 3; u++)
//			{
//				for (v = 0; v < 3; v++)
//					printf ("\t%3.2f", adRot [u*3+v]);
//				printf ("\n");
//			}
//			printf ("\n\n");
//
//			printf ("Error (RMS):\n\t%lf\n\n", dError);
//		}
//	}
//}

- (double*) rotation
{
	return adRot;
}

- (double*) translation
{
	return adTrans;
}

@end
