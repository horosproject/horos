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

@end
