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

// Curve fitting class based on the Simplex method described in the article "Fitting Curves to Data" in the May 1984 issue of Byte magazine, pages 340-362.

#import <Cocoa/Cocoa.h>

@interface CurveFitter : NSObject
{
    int fit;                // Number of curve type to fit
    double *xData, *yData;  // x,y data to fit
    int numPoints;          // number of data points
    int numParams;          // number of parametres
    int numVertices;        // numParams+1 (includes sumLocalResiduaalsSqrd)
    int worst;          // worst current parametre estimates
    int nextWorst;      // 2nd worst current parametre estimates
    int best;           // best current parametre estimates
    double	**simp;        // the simplex (the last element of the array at each vertice is the sum of the square of the residuals)
    double	*next;      // new vertex to be tested
    int numIter;        // number of iterations so far
    int maxIter;    // maximum number of iterations per restart
    int restarts;   // number of times to restart simplex after first soln.
    double maxError;     // maximum error tolerance
}

- (double) sqr:(double) d;
- (void) doFit: (int) fitType;
- (void) initialize;
- (void) restart: (int) n;
- (int) getNumParams;
- (double) f:(int) f :(double *)p :(double) x;
- (double*) getParams;
- (double*) getResiduals;
- (double) getSumResidualsSqr;
- (double) getSD;
- (double) getFitGoodness;
- (void) sumResiduals: (double*) x;
- (void) newVertex;
- (void) order;
- (int) getIterations;
- (int) getMaxIterations;
- (void) setMaxIterations:(int) x;
- (int) getRestarts;
- (void) setRestarts:(int) x;
- (int) getMax:(double*) array;

@end
