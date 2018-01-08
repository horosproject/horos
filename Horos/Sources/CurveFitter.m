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

#import "CurveFitter.h"

	enum { STRAIGHT_LINE=0,POLY2=1,POLY3=2,POLY4=3, EXPONENTIAL=4,POWER=5,LOG=6,RODBARD=7,GAMMA_VARIATE=8,T1_SAT_RELAX = 9,T2_DEPHASE = 10,DIFFUSION = 11};
    static int IterFactor = 500;

//    static char* fitList[] = {"Straight Line","2nd Degree Polynomial", "3rd Degree Polynomial", "4th Degree Polynomial","Exponential","Power",  "log","Rodbard", "Gamma Variate"};

//    static char* fList[] = {"y = a+bx","y = a+bx+cx^2", "y = a+bx+cx^2+dx^3", "y = a+bx+cx^2+dx^3+ex^4","y = a*exp(bx)","y = ax^b", "y = a*ln(bx)","y = c*((a-x)/(x-d))^(1/b)", "y = a*(x-b)^c*exp(-(x-b)/d)", "y=a*(1-exp(-x/b))"};

    static double alpha = -1.0;     // reflection coefficient
    static double beta = 0.5;   // contraction coefficient
    static double gammaCoefficient = 2.0;      // expansion coefficient
    static double root2 = 1.414214; // square root of 2


@implementation CurveFitter

- (id) initCurveFitterWithXData: (double*) xD andYData: (double*) yD length: (int) l
{
	self = [super init];
	
	numPoints = l;
	
	xData = malloc( numPoints * sizeof( double));
	yData = malloc( numPoints * sizeof( double));
	
	for( int i = 0; i < numPoints ; i++)
	{
		xData[ i] = xD[ i];
		yData[ i] = yD[ i];
	}
	
	return self;
}

- (void) doFit: (int) fitType
{
	if (fitType < STRAIGHT_LINE || fitType > DIFFUSION)
		[NSException raise: @"CurveFitterException" format: @"Invalid fit type"];
		
	fit = fitType;
	
	[self initialize];
	
	[self restart: 0];
	
	numIter = 0;
	BOOL done = false;
	
	double *center = malloc( sizeof( double) * numParams);  // mean of simplex vertices
	
	while (!done)
	{
		numIter++;
		for (int i = 0; i < numParams; i++) center[i] = 0.0;
		// get mean "center" of vertices, excluding worst
		for (int i = 0; i < numVertices; i++)
			if (i != worst)
				for (int j = 0; j < numParams; j++)
					center[j] += simp[i][j];
		// Reflect worst vertex through centre
		for (int i = 0; i < numParams; i++) {
			center[i] /= numParams;
			next[i] = center[i] + alpha*(simp[worst][i] - center[i]);
		}
		[self sumResiduals: next];
		// if it's better than the best...
		if (next[numParams] <= simp[best][numParams]) {
			[self newVertex];
			// try expanding it
			for (int i = 0; i < numParams; i++)
				next[i] = center[i] + gammaCoefficient * (simp[worst][i] - center[i]);
			[self sumResiduals: next];
			// if this is even better, keep it
			if (next[numParams] <= simp[worst][numParams])
				[self newVertex];
		}
		// else if better than the 2nd worst keep it...
		else if (next[numParams] <= simp[nextWorst][numParams]) {
			[self newVertex];
		}
		// else try to make positive contraction of the worst
		else {
			for (int i = 0; i < numParams; i++)
				next[i] = center[i] + beta*(simp[worst][i] - center[i]);
			[self sumResiduals: next];
			// if this is better than the second worst, keep it.
			if (next[numParams] <= simp[nextWorst][numParams]) {
				[self newVertex];
			}
			// if all else fails, contract simplex in on best
			else {
				for (int i = 0; i < numVertices; i++) {
					if (i != best) {
						for (int j = 0; j < numVertices; j++)
							simp[i][j] = beta*(simp[i][j]+simp[best][j]);
						[self sumResiduals: simp[i]];
					}
				}
			}
		}
		
		[self order];

		double rtol = 2 * fabs(simp[best][numParams] - simp[worst][numParams]) / (fabs(simp[best][numParams]) + fabs(simp[worst][numParams]) + 0.0000000001);

		if (numIter >= maxIter) done = true;
		else if (rtol < maxError) {
			//System.out.print(getResultString());
			restarts--;
			if (restarts < 0) {
				done = true;
			}
			else {
				[self restart: best];
			}
		}
	}
	
	free( center);
	center = nil;
}

    /** Initialise the simplex
     */
- (void) initialize
{
	// Calculate some things that might be useful for predicting parametres
	numParams = [self getNumParams];
	numVertices = numParams + 1;      // need 1 more vertice than parametres,
	simp = malloc( numVertices * sizeof( double*));
	for( int i = 0 ; i < numVertices; i++)
		simp[ i] = malloc( numVertices * sizeof(double));
	next = malloc( numVertices * sizeof( double));

	double firstx = xData[0];
	double firsty = yData[0];
	double lastx = xData[numPoints-1];
	double lasty = yData[numPoints-1];
	double xmean = (firstx+lastx)/2.0;
//	double ymean = (firsty+lasty)/2.0;
	double slope;
	if ((lastx - firstx) != 0.0)
		slope = (lasty - firsty)/(lastx - firstx);
	else
		slope = 1.0;
	double yintercept = firsty - slope * firstx;
	maxIter = IterFactor * numParams * numParams;  // Where does this estimate come from?
	restarts = 1;
	maxError = 1e-9;
	switch (fit) {
		case STRAIGHT_LINE:
			simp[0][0] = yintercept;
			simp[0][1] = slope;
			break;
		case POLY2:
			simp[0][0] = yintercept;
			simp[0][1] = slope;
			simp[0][2] = 0.0;
			break;
		case POLY3:
			simp[0][0] = yintercept;
			simp[0][1] = slope;
			simp[0][2] = 0.0;
			simp[0][3] = 0.0;
			break;
		case POLY4:
			simp[0][0] = yintercept;
			simp[0][1] = slope;
			simp[0][2] = 0.0;
			simp[0][3] = 0.0;
			simp[0][4] = 0.0;
			break;
		case EXPONENTIAL:
			simp[0][0] = 0.1;
			simp[0][1] = 0.01;
			break;
		case POWER:
			simp[0][0] = 0.0;
			simp[0][1] = 1.0;
			break;
		case LOG:
			simp[0][0] = 0.5;
			simp[0][1] = 0.05;
			break;
		case RODBARD:
			simp[0][0] = firsty;
			simp[0][1] = 1.0;
			simp[0][2] = xmean;
			simp[0][3] = lasty;
			break;
		case T1_SAT_RELAX:
			simp[0][0] = firsty;
			simp[0][1] = 1.0;
			break;
		case T2_DEPHASE:
			simp[0][0] = firsty;
			simp[0][1] = 1.0;
			break;
		case DIFFUSION:
			simp[0][0] = firsty;
			simp[0][1] = 0.0005;
			break;
		case GAMMA_VARIATE:
			//  First guesses based on following observations:
			//  t0 [b] = time of first rise in gamma curve - so use the user specified first limit
			//  tm = t0 + a*B [c*d] where tm is the time of the peak of the curve
			//  therefore an estimate for a and B is sqrt(tm-t0)
			//  K [a] can now be calculated from these estimates
			simp[0][0] = firstx;
			double ab = xData[ [self getMax: yData]] - firstx;
			simp[0][2] = sqrt(ab);
			simp[0][3] = sqrt(ab);
			simp[0][1] = yData[ [self getMax:yData]] / ( pow(ab, simp[0][2]) * exp(-ab/simp[0][3]));
			break;
	}
}
//
//    /** Pop up a dialog allowing control over simplex starting parameters */
//    private void settingsDialog() {
//        GenericDialog gd = new GenericDialog("Simplex Fitting Options", IJ.getInstance());
//        gd.addMessage("Function name: " + fitList[fit] + "\n" +
//        "Formula: " + fList[fit]);
//        char pChar = 'a';
//        for (int i = 0; i < numParams; i++) {
//            gd.addNumericField("Initial "+(new Character(pChar)).toString()+":", simp[0][i], 2);
//            pChar++;
//        }
//        gd.addNumericField("Maximum iterations:", maxIter, 0);
//        gd.addNumericField("Number of restarts:", restarts, 0);
//        gd.addNumericField("Error tolerance [1*10^(-x)]:", -(flog(maxError)/flog(10)), 0);
//        gd.showDialog();
//        if (gd.wasCanceled() || gd.invalidNumber()) {
//            IJ.error("Parameter setting canceled.\nUsing default parameters.");
//        }
//        // Parametres:
//        for (int i = 0; i < numParams; i++) {
//            simp[0][i] = gd.getNextNumber();
//        }
//        maxIter = (int) gd.getNextNumber();
//        restarts = (int) gd.getNextNumber();
//        maxError = pow(10.0, -gd.getNextNumber());
//    }
//
//    /** Restart the simplex at the nth vertex */
- (void) restart: (int) n
{
	// Copy nth vertice of simplex to first vertice
	for (int i = 0; i < numParams; i++) {
		simp[0][i] = simp[n][i];
	}
	[self sumResiduals: simp[0]];          // Get sum of residuals^2 for first vertex
	double *step = malloc( sizeof( double) * numParams);
	for (int i = 0; i < numParams; i++) {
		step[i] = simp[0][i] / 2.0;     // Step half the parametre value
		if (step[i] == 0.0)             // We can't have them all the same or we're going nowhere
			step[i] = 0.01;
	}
	// Some kind of factor for generating new vertices
	double *p = malloc( sizeof( double) * numParams);
	double *q = malloc( sizeof( double) * numParams);
	for (int i = 0; i < numParams; i++)
	{
		p[i] = step[i] * (sqrt(numVertices) + numParams - 1.0)/(numParams * root2);
		q[i] = step[i] * (sqrt(numVertices) - 1.0)/(numParams * root2);
	}
	// Create the other simplex vertices by modifing previous one.
	for (int i = 1; i < numVertices; i++)
	{
		for (int j = 0; j < numParams; j++) {
			simp[i][j] = simp[i-1][j] + q[j];
		}
		simp[i][i-1] = simp[i][i-1] + p[i-1];
		[self sumResiduals: simp[i]];
	}
	// Initialise current lowest/highest parametre estimates to simplex 1
	best = 0;
	worst = 0;
	nextWorst = 0;
	[self order];
	
	free( p);
	free( q);
	free( step);
}
//
//    // Display simplex [Iteration: s0(p1, p2....), s1(),....] in ImageJ window
//    void showSimplex(int iter) {
//        ij.IJ.write("" + iter);
//        for (int i = 0; i < numVertices; i++) {
//            String s = "";
//            for (int j=0; j < numVertices; j++)
//                s += "  "+ ij.IJ.d2s(simp[i][j], 6);
//            ij.IJ.write(s);
//        }
//    }
//
//    /** Get number of parameters for current fit function */
- (int) getNumParams
{
	switch (fit)
	{
	case STRAIGHT_LINE: return 2;
	case POLY2: return 3;
	case POLY3: return 4;
	case POLY4: return 5;
	case EXPONENTIAL: return 2;
	case POWER: return 2;
	case LOG: return 2;
	case T1_SAT_RELAX: return 2;
	case T2_DEPHASE: return 2;
	case DIFFUSION: return 2;
	case RODBARD: return 4;
	case GAMMA_VARIATE: return 4;
	}
	return 0;
}


    /** Returns "fit" function value for parametres "p" at "x" */
- (double) f:(int) f :(double *)p :(double) x
 {
        switch (f) {
            case STRAIGHT_LINE:
                return p[0] + p[1]*x;
            case POLY2:
                return p[0] + p[1]*x + p[2]* x*x;
            case POLY3:
                return p[0] + p[1]*x + p[2]*x*x + p[3]*x*x*x;
            case POLY4:
                return p[0] + p[1]*x + p[2]*x*x + p[3]*x*x*x + p[4]*x*x*x*x;
            case EXPONENTIAL:
                return p[0]*exp(p[1]*x);
            case T1_SAT_RELAX:
                return p[0]*(1 - exp(-(x / p[1])));
            case T2_DEPHASE:
                return p[0]*exp(-(x / p[1]));
            case DIFFUSION:
                return p[0]*exp(-x * p[1]);
            case POWER:
                if (x == 0.0)
                    return 0.0;
                else
                    return p[0]*exp(p[1]*log(x)); //y=ax^b
            case LOG:
                if (x == 0.0)
                    x = 0.5;
                return p[0]*log(p[1]*x);
            case RODBARD:
			{
                double ex;
                if (x == 0.0)
                    ex = 0.0;
                else
                    ex = exp( log(x/p[2])*p[1]);
                double y = p[0]-p[3];
                y = y/(1.0+ex);
                return y+p[3];
			}
            case GAMMA_VARIATE:
                if (p[0] >= x) return 0.0;
                if (p[1] <= 0) return -100000.0;
                if (p[2] <= 0) return -100000.0;
                if (p[3] <= 0) return -100000.0;

                double pw = pow((x - p[0]), p[2]);
                double e = exp((-(x - p[0]))/p[3]);
                return p[1]*pw*e;
            default:
                return 0.0;
        }
    }

    /** Get the set of parameter values from the best corner of the simplex */
- (double*) getParams
{
	[self order];
	return simp[best];
}

    /** Returns residuals array ie. differences between data and curve */
- (double*) getResiduals
{
	double *params = [self getParams];
	double *residuals = malloc( sizeof( double) * numPoints);
	
    for (int i = 0; i < numPoints; i++)
		residuals[i] = yData[i] - [self f: fit :params :xData[i]];
			
	return residuals;
}

    /* Last "parametre" at each vertex of simplex is sum of residuals
     * for the curve described by that vertex
     */
- (double) getSumResidualsSqr {
        double sumResidualsSqr = ([self getParams])[[self getNumParams]];
        return sumResidualsSqr;
    }

    /**  SD = sqrt(sum of residuals squared / number of params+1)
     */
- (double) getSD {
        double sd = sqrt([self getSumResidualsSqr] / numVertices);
        return sd;
    }

    /**  Get a measure of "goodness of fit" where 1.0 is best.
     *
     */
- (double) getFitGoodness {
        double sumY = 0.0;
        for (int i = 0; i < numPoints; i++) sumY += yData[i];
        double mean = sumY / numVertices;
        double sumMeanDiffSqr = 0.0;
        int degreesOfFreedom = numPoints - [self getNumParams];
        double fitGoodness = 0.0;
        for (int i = 0; i < numPoints; i++) {
            sumMeanDiffSqr += [self sqr: yData[i] - mean];
        }
        if (sumMeanDiffSqr > 0.0 && degreesOfFreedom != 0)
            fitGoodness = 1.0 - ([self getSumResidualsSqr] / degreesOfFreedom) * ((numParams) / sumMeanDiffSqr);

        return fitGoodness;
    }

//    /** Get a string description of the curve fitting results
//     * for easy output.
//     */
//    public String getResultString() {
//        StringBuffer results = new StringBuffer("\nNumber of iterations: " + getIterations() +
//        "\nMaximum number of iterations: " + getMaxIterations() +
//        "\nSum of residuals squared: " + [self getSumResidualsSqr] +
//        "\nStandard deviation: " + getSD() +
//        "\nGoodness of fit: " + getFitGoodness() +
//        "\nParameters:");
//        char pChar = 'a';
//        double[] pVal = [self getParams];
//        for (int i = 0; i < numParams; i++) {
//            results.append("\n" + pChar + " = " + pVal[i]);
//            pChar++;
//        }
//        return results.toString();
//    }

- (double) sqr:(double) d { return d * d; }

    /** Adds sum of square of residuals to end of array of parameters */
- (void) sumResiduals: (double*) x {
        x[numParams] = 0.0;
        for (int i = 0; i < numPoints; i++) {
            x[numParams] = x[numParams] + [self sqr: [self f: fit :x :xData[i]]-yData[i]];
            //        if (IJ.debugMode) ij.IJ.log(i+" "+x[n-1]+" "+f(fit,x,xData[i])+" "+yData[i]);
        }
    }

    /** Keep the "next" vertex */
- (void) newVertex {
        for (int i = 0; i < numVertices; i++)
            simp[worst][i] = next[i];
    }

    /** Find the worst, nextWorst and best current set of parameter estimates */
- (void) order {
        for (int i = 0; i < numVertices; i++) {
            if (simp[i][numParams] < simp[best][numParams]) best = i;
            if (simp[i][numParams] > simp[worst][numParams]) worst = i;
        }
        nextWorst = best;
        for (int i = 0; i < numVertices; i++) {
            if (i != worst) {
                if (simp[i][numParams] > simp[nextWorst][numParams]) nextWorst = i;
            }
        }
        //        IJ.write("B: " + simp[best][numParams] + " 2ndW: " + simp[nextWorst][numParams] + " W: " + simp[worst][numParams]);
    }

    /** Get number of iterations performed */
- (int) getIterations {
        return numIter;
    }

    /** Get maximum number of iterations allowed */
- (int) getMaxIterations {
        return maxIter;
    }

    /** Set maximum number of iterations allowed */
- (void) setMaxIterations:(int) x {
        maxIter = x;
    }

    /** Get number of simplex restarts to do */
- (int) getRestarts {
        return restarts;
    }

    /** Set number of simplex restarts to do */
- (void) setRestarts:(int) x {
        restarts = x;
    }

    /**
     * Gets index of highest value in an array.
     *
     * @param              Double array.
     * @return             Index of highest value.
     */
- (int) getMax:(double*) array
{
        double max = array[0];
        int index = 0;
        for(int i = 1; i < numPoints; i++) {
            if(max < array[i]) {
                max = array[i];
                index = i;
            }
        }
        return index;
    }

- (void) dealloc
{
	if( xData)
		free( xData);
	
	if( yData)
		free( yData);
	
	if( simp)
	{
		for( int i = 0 ; i < numVertices; i++)
			free( simp[ i]);
		free( simp);
	}
	
	if( next)
		free( next);
	
	[super dealloc];
}

@end
