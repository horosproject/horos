/*
 *  CPRBezierCoreAdditions.c
 *  OsiriX
 *
 *  Created by Joël Spaltenstein on 11/6/10.
 *  Copyright 2010 OsiriX Team. All rights reserved.
 *
 */

#import "CPRBezierCoreAdditions.h"


CPRBezierCoreRef CPRBezierCoreCreateCurveWithNodes(CPRVectorArray vectors, CFIndex numVectors)
{
    return CPRBezierCoreCreateMutableCurveWithNodes(vectors, numVectors);
}

CPRMutableBezierCoreRef CPRBezierCoreCreateMutableCurveWithNodes(CPRVectorArray vectors, CFIndex numVectors)
{
	CPRVector p1, p2;
	long long  i, j;
	double xi, yi, zi;
	long long nb;
	double *px, *py, *pz;
	int ok;
    
	double *a, b, *c, *cx, *cy, *cz, *d, *g, *h;
	double bet, *gam;
	double aax, bbx, ccx, ddx, aay, bby, ccy, ddy, aaz, bbz, ccz, ddz; // coef of spline
    
    // get the new beziercore ready 
    CPRMutableBezierCoreRef newBezierCore;
    CPRVector control1;
    CPRVector control2;
    CPRVector lastEndpoint;
    CPRVector endpoint;
    newBezierCore = CPRBezierCoreCreateMutable();
    
    assert (numVectors >= 2);
    
    if (numVectors == 2) {
        CPRBezierCoreAddSegment(newBezierCore, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, vectors[0]);
        CPRBezierCoreAddSegment(newBezierCore, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, vectors[1]);
        return newBezierCore;
    }
    
	// function spline S(x) = a x3 + bx2 + cx + d
	// with S continue, S1 continue, S2 continue.
	// smoothing of a closed polygon given by a list of points (x,y)
	// we compute a spline for x and a spline for y
	// where x and y are function of d where t is the distance between points
    
	// compute tridiag matrix
	//   | b1 c1 0 ...                   |   |  u1 |   |  r1 |
	//   | a2 b2 c2 0 ...                |   |  u2 |   |  r2 |
	//   |  0 a3 b3 c3 0 ...             | * | ... | = | ... |
	//   |                  ...          |   | ... |   | ... |
	//   |                an-1 bn-1 cn-1 |   | ... |   | ... |
	//   |                 0    an   bn  |   |  un |   |  rn |
	// bi = 4
	// resolution algorithm is taken from the book : Numerical recipes in C
    
	// initialization of different vectors
	// element number 0 is not used (except h[0])
	nb  = numVectors + 2;
	a   = malloc(nb*sizeof(double));	
	c   = malloc(nb*sizeof(double));	
	cx  = malloc(nb*sizeof(double));	
	cy  = malloc(nb*sizeof(double));	
	cz  = malloc(nb*sizeof(double));	
	d   = malloc(nb*sizeof(double));	
	g   = malloc(nb*sizeof(double));	
	gam = malloc(nb*sizeof(double));	
	h   = malloc(nb*sizeof(double));	
	px  = malloc(nb*sizeof(double));	
	py  = malloc(nb*sizeof(double));	
	pz  = malloc(nb*sizeof(double));	
    
	
	BOOL failed = NO;
	
	if( !a) failed = YES;
	if( !c) failed = YES;
	if( !cx) failed = YES;
	if( !cy) failed = YES;
	if( !cz) failed = YES;
	if( !d) failed = YES;
	if( !g) failed = YES;
	if( !gam) failed = YES;
	if( !h) failed = YES;
	if( !px) failed = YES;
	if( !py) failed = YES;
	if( !pz) failed = YES;
	
	if( failed)
	{
		free(a);
		free(c);
		free(cx);
		free(cy);
		free(cz);
		free(d);
		free(g);
		free(gam);
		free(h);
		free(px);
		free(py);
		free(pz);
		
        fprintf(stderr, "CPRBezierCoreCreateMutableCurveWithNodes failed because it could not allocate enough memory\n");
		return NULL;
	}
	
	//initialisation
	for (i=0; i<nb; i++)
		h[i] = a[i] = cx[i] = d[i] = c[i] = cy[i] = cz[i] = g[i] = gam[i] = 0.0;
    
	// as a spline starts and ends with a line one adds two points
	// in order to have continuity in starting point
	for (i=0; i<numVectors; i++)
	{
		px[i+1] = vectors[i].x;// * fZoom / 100;
		py[i+1] = vectors[i].y;// * fZoom / 100;
		pz[i+1] = vectors[i].z;// * fZoom / 100;
	}
	px[0] = 2.0*px[1] - px[2]; px[nb-1] = 2.0*px[nb-2] - px[nb-3];
	py[0] = 2.0*py[1] - py[2]; py[nb-1] = 2.0*py[nb-2] - py[nb-3];
	pz[0] = 2.0*pz[1] - pz[2]; pz[nb-1] = 2.0*pz[nb-2] - pz[nb-3];
    
	// check all points are separate, if not do not smooth
	// this happens when the zoom factor is too small
	// so in this case the smooth is not useful
    
	ok=TRUE;
	if(nb<3) ok=FALSE;
    
//	for (i=1; i<nb; i++) 
//        if (px[i] == px[i-1] && py[i] == py[i-1] && pz[i] == pz[i-1]) {ok = FALSE; break;}
	if (ok == FALSE)
		failed = YES;
    
	if( failed)
	{
		free(a);
		free(c);
		free(cx);
		free(cy);
		free(cz);
		free(d);
		free(g);
		free(gam);
		free(h);
		free(px);
		free(py);
		free(pz);
		
        fprintf(stderr, "CPRBezierCoreCreateMutableCurveWithNodes failed because some points overlapped\n");
		return NULL;
	}
    
	// define hi (distance between points) h0 distance between 0 and 1.
	// di distance of point i from start point
	for (i = 0; i<nb-1; i++)
	{
		xi = px[i+1] - px[i];
		yi = py[i+1] - py[i];
		zi = pz[i+1] - pz[i];
		h[i] = (double) sqrt(xi*xi + yi*yi + zi*zi);
		d[i+1] = d[i] + h[i];
	}
	
	// define ai and ci
	for (i=2; i<nb-1; i++) a[i] = 2.0 * h[i-1] / (h[i] + h[i-1]);
	for (i=1; i<nb-2; i++) c[i] = 2.0 * h[i] / (h[i] + h[i-1]);
    
	// define gi in function of x
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(di - di+1) - (yi+1 - yi+2)/(di+1 - di+2)]
	//                      / (di - di+2)
	for (i=1; i<nb-1; i++) 
		g[i] = 6.0 * ( ((px[i-1] - px[i]) / (d[i-1] - d[i])) - ((px[i] - px[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);
    
	// compute cx vector
	b=4; bet=4;
	cx[1] = g[1]/b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cx[j] = (g[j] - a[j] * cx[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cx[j] -= gam[j+1] * cx[j+1];
    
	// define gi in function of y
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(hi - hi+1) - (yi+1 - yi+2)/(hi+1 - hi+2)]
	//                      / (hi - hi+2)
	for (i=1; i<nb-1; i++)
		g[i] = 6.0 * ( ((py[i-1] - py[i]) / (d[i-1] - d[i])) - ((py[i] - py[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);
    
	// compute cy vector
	b = 4.0; bet = 4.0;
	cy[1] = g[1] / b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cy[j] = (g[j] - a[j] * cy[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cy[j] -= gam[j+1] * cy[j+1];
    
	// define gi in function of z
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(hi - hi+1) - (yi+1 - yi+2)/(hi+1 - hi+2)]
	//                      / (hi - hi+2)
	for (i=1; i<nb-1; i++)
		g[i] = 6.0 * ( ((pz[i-1] - pz[i]) / (d[i-1] - d[i])) - ((pz[i] - pz[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);
    
	// compute cz vector
	b = 4.0; bet = 4.0;
	cz[1] = g[1] / b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cz[j] = (g[j] - a[j] * cz[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cz[j] -= gam[j+1] * cz[j+1];
    
	// OK we have the cx and cy and cz vectors, from that we can compute the
	// coeff of the polynoms for x and y and z andfor each interval
	// S(x) (xi, xi+1)  = ai + bi (x-xi) + ci (x-xi)2 + di (x-xi)3
	// di = (ci+1 - ci) / 3 hi
	// ai = yi
	// bi = ((ai+1 - ai) / hi) - (hi/3) (ci+1 + 2 ci)
    
    lastEndpoint = CPRVectorMake(px[1], py[1], pz[1]);
    CPRBezierCoreAddSegment(newBezierCore, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, lastEndpoint);
    
	// for each interval
	for (i=1; i<nb-2; i++)
	{
		// compute coef for x polynom
		ccx = cx[i];
		aax = px[i];
		ddx = (cx[i+1] - cx[i]) / (3.0 * h[i]);
		bbx = ((px[i+1] - px[i]) / h[i]) - (h[i] / 3.0) * (cx[i+1] + 2.0 * cx[i]);
        
		// compute coef for y polynom
		ccy = cy[i];
		aay = py[i];
		ddy = (cy[i+1] - cy[i]) / (3.0 * h[i]);
		bby = ((py[i+1] - py[i]) / h[i]) - (h[i] / 3.0) * (cy[i+1] + 2.0 * cy[i]);
        
		// compute coef for z polynom
		ccz = cz[i];
		aaz = pz[i];
		ddz = (cz[i+1] - cz[i]) / (3.0 * h[i]);
		bbz = ((pz[i+1] - pz[i]) / h[i]) - (h[i] / 3.0) * (cz[i+1] + 2.0 * cz[i]);
        
        //p.x = (aax + bbx * (double)j + ccx * (double)(j * j) + ddx * (double)(j * j * j));
        
        endpoint.x = aax + bbx*h[i] + ccx*h[i]*h[i] + ddx*h[i]*h[i]*h[i];
        control1.x = lastEndpoint.x + ((bbx*h[i]) / 3.0);
        control2.x = endpoint.x - (((bbx + 2.0*ccx*h[i] + 3.0*ddx*h[i]*h[i]) * h[i]) / 3.0);
        
        endpoint.y = aay + bby*h[i] + ccy*h[i]*h[i] + ddy*h[i]*h[i]*h[i];
        control1.y = lastEndpoint.y + ((bby*h[i]) / 3.0);
        control2.y = endpoint.y - (((bby + 2.0*ccy*h[i] + 3.0*ddy*h[i]*h[i]) * h[i]) / 3.0);
        
        endpoint.z = aaz + bbz*h[i] + ccz*h[i]*h[i] + ddz*h[i]*h[i]*h[i];
        control1.z = lastEndpoint.z + ((bbz*h[i]) / 3.0);
        control2.z = endpoint.z - (((bbz + 2.0*ccz*h[i] + 3.0*ddz*h[i]*h[i]) * h[i]) / 3.0);
        
        CPRBezierCoreAddSegment(newBezierCore, CPRCurveToBezierCoreSegmentType, control1, control2, endpoint);
        lastEndpoint = endpoint;
    }//endfor each interval
    
	// delete dynamic structures
	free(a);
	free(c);
	free(cx);
    free(cy);
    free(cz);
	free(d);
	free(g);
	free(gam);
	free(h);
	free(px);
	free(py);
	free(pz);
    
	return newBezierCore;
}

CPRVector CPRBezierCoreVectorAtStart(CPRBezierCoreRef bezierCore)
{
    CPRVector moveTo;
    
    if (CPRBezierCoreSegmentCount(bezierCore) == 0) {
        return CPRVectorZero;
    }
    
    CPRBezierCoreGetSegmentAtIndex(bezierCore, 0, NULL, NULL, &moveTo);
    return moveTo;
}

CPRVector CPRBezierCoreVectorAtEnd(CPRBezierCoreRef bezierCore)
{
    CPRVector endPoint;
    
    if (CPRBezierCoreSegmentCount(bezierCore) == 0) {
        return CPRVectorZero;
    }
    
    CPRBezierCoreGetSegmentAtIndex(bezierCore, CPRBezierCoreSegmentCount(bezierCore) - 1, NULL, NULL, &endPoint);
    return endPoint;
}


CPRVector CPRBezierCoreTangentAtStart(CPRBezierCoreRef bezierCore)
{
    CPRVector moveTo;
    CPRVector endPoint;
    CPRVector control1;
    
    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return CPRVectorZero;
    }
    
    CPRBezierCoreGetSegmentAtIndex(bezierCore, 0, NULL, NULL, &moveTo);
    
    if (CPRBezierCoreGetSegmentAtIndex(bezierCore, 1, &control1, NULL, &endPoint) == CPRCurveToBezierCoreSegmentType) {
        return CPRVectorNormalize(CPRVectorSubtract(endPoint, control1));
    } else {
        return CPRVectorNormalize(CPRVectorSubtract(endPoint, moveTo));
    }
}

CPRVector CPRBezierCoreTangentAtEnd(CPRBezierCoreRef bezierCore)
{
    CPRVector prevEndPoint;
    CPRVector endPoint;
    CPRVector control2;
    CFIndex segmentCount;
    
    segmentCount = CPRBezierCoreSegmentCount(bezierCore);
    if (segmentCount < 2) {
        return CPRVectorZero;
    }    
    
    if (CPRBezierCoreGetSegmentAtIndex(bezierCore, segmentCount - 1, NULL, &control2, &endPoint) == CPRCurveToBezierCoreSegmentType) {
        return CPRVectorNormalize(CPRVectorSubtract(endPoint, control2));
    } else {
        CPRBezierCoreGetSegmentAtIndex(bezierCore, segmentCount - 2, NULL, NULL, &prevEndPoint);
        return CPRVectorNormalize(CPRVectorSubtract(endPoint, prevEndPoint));
    }    
}

CGFloat CPRBezierCoreRelativePositionClosestToVector(CPRBezierCoreRef bezierCore, CPRVector vector, CPRVectorPointer closestVector, CGFloat *distance)
{
    CPRBezierCoreIteratorRef bezierIterator;
    CPRBezierCoreRef flattenedBezier;
    CPRVector start;
    CPRVector end;
    CPRVector segment;
	CPRVector segmentDirection;
    CPRVector translatedVector;
	CPRVector bestVector;
	CPRBezierCoreSegmentType segmentType;
    CGFloat tempDistance;
    CGFloat bestRelativePosition;
    CGFloat bestDistance;
    CGFloat projectedDistance;
    CGFloat segmentLength;
    CGFloat traveledDistance;
    
    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return 0.0;
    }
    
    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezier = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezier, CPRBezierDefaultFlatness);
    } else {
        flattenedBezier = CPRBezierCoreRetain(bezierCore);
    }

    bezierIterator = CPRBezierCoreIteratorCreateWithBezierCore(flattenedBezier);
    
    bestDistance = CGFLOAT_MAX;
    bestRelativePosition = 0.0;
    traveledDistance = 0.0;
    
    CPRBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
    
    while (!CPRBezierCoreIteratorIsAtEnd(bezierIterator)) {
        start = end;
        segmentType = CPRBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
        
        segment = CPRVectorSubtract(end, start);
        translatedVector = CPRVectorSubtract(vector, start);
        segmentLength = CPRVectorLength(segment);
		segmentDirection = CPRVectorScalarMultiply(segment, 1.0/segmentLength);
        
        projectedDistance = CPRVectorDotProduct(translatedVector, segmentDirection);
        
		if (segmentType != CPRMoveToBezierCoreSegmentType) {
			if (projectedDistance >= 0 && projectedDistance <= segmentLength) {
				tempDistance = CPRVectorLength(CPRVectorSubtract(translatedVector, CPRVectorScalarMultiply(segmentDirection, projectedDistance)));
				if (tempDistance < bestDistance) {
					bestDistance = tempDistance;
					bestRelativePosition = traveledDistance + projectedDistance;
					bestVector = CPRVectorAdd(start, CPRVectorScalarMultiply(segmentDirection, projectedDistance));
				}
			} else if (projectedDistance < 0) {
				tempDistance = CPRVectorDistance(start, vector);
				if (tempDistance < bestDistance) {
					bestDistance = tempDistance;
					bestRelativePosition = traveledDistance;
					bestVector = start;
				} 
			} else {
				tempDistance = CPRVectorDistance(end, vector);
				if (tempDistance < bestDistance) {
					bestDistance = tempDistance;
					bestRelativePosition = traveledDistance + segmentLength;
					bestVector = end;
				} 
			}
		
			traveledDistance += segmentLength;
		}
    }
    
    bestRelativePosition /= CPRBezierCoreLength(flattenedBezier);    
    
    CPRBezierCoreRelease(flattenedBezier);
    CPRBezierCoreIteratorRelease(bezierIterator);
    
    if (distance) {
        *distance = bestDistance;
    }
	if (closestVector) {
		*closestVector = bestVector;
	}
    
    return bestRelativePosition;
}

CGFloat CPRBezierCoreRelativePositionClosestToLine(CPRBezierCoreRef bezierCore, CPRLine line, CPRVectorPointer closestVector, CGFloat *distance)
{
    CPRBezierCoreIteratorRef bezierIterator;
    CPRBezierCoreRef flattenedBezier;
    CPRVector start;
    CPRVector end;
    CPRLine segment;
    CPRVector translatedVector;
    CPRVector closestPoint;
    CPRVector bestVector;
	CPRBezierCoreSegmentType segmentType;
    CGFloat mu;
    CGFloat tempDistance;
    CGFloat bestRelativePosition;
    CGFloat bestDistance;
    CGFloat traveledDistance;
    CGFloat segmentLength;

    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return 0.0;
    }
    
    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezier = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezier, CPRBezierDefaultFlatness);
    } else {
        flattenedBezier = CPRBezierCoreRetain(bezierCore);
    }

    bezierIterator = CPRBezierCoreIteratorCreateWithBezierCore(flattenedBezier);
    
    bestDistance = CGFLOAT_MAX;
    bestRelativePosition = 0.0;
    traveledDistance = 0.0;
    CPRBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
    bestVector = end;

    while (!CPRBezierCoreIteratorIsAtEnd(bezierIterator)) {
        start = end;
        segmentType = CPRBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
        
        segmentLength = CPRVectorDistance(start, end);
        
        if (segmentLength > 0.0 && segmentType != CPRMoveToBezierCoreSegmentType) {
            segment = CPRLineMakeFromPoints(start, end);
            tempDistance = CPRLineClosestPoints(segment, line, &closestPoint, NULL);
            
            if (tempDistance < bestDistance) {
                mu = CPRVectorDotProduct(CPRVectorSubtract(end, start), CPRVectorSubtract(closestPoint, start)) / (segmentLength*segmentLength);
                
                if (mu < 0.0) {
                    tempDistance = CPRVectorDistanceToLine(start, line);
                    if (tempDistance < bestDistance) {
                        bestDistance = tempDistance;
                        bestRelativePosition = traveledDistance;
                        bestVector = start;
                    }
                } else if (mu > 1.0) {
                    tempDistance = CPRVectorDistanceToLine(end, line);
                    if (tempDistance < bestDistance) {
                        bestDistance = tempDistance;
                        bestRelativePosition = traveledDistance + segmentLength;
                        bestVector = end;
                    }
                } else {
                    bestDistance = tempDistance;
                    bestRelativePosition = traveledDistance + (segmentLength * mu);
                    bestVector = closestPoint;
                }
            }
            traveledDistance += segmentLength;
        }
    }
    
    bestRelativePosition /= CPRBezierCoreLength(flattenedBezier);    

    CPRBezierCoreRelease(flattenedBezier);
    CPRBezierCoreIteratorRelease(bezierIterator);
    
    if (closestVector) {
        *closestVector = bestVector;
    }
    if (distance) {
        *distance = bestDistance;
    }
    
    return bestRelativePosition;
}

CFIndex CPRBezierCoreGetVectorInfo(CPRBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, CPRVector initialNormal,
                                               CPRVectorArray vectors, CPRVectorArray tangents, CPRVectorArray normals, CFIndex numVectors)
{
    CPRBezierCoreRef flattenedBezierCore;
    CPRBezierCoreIteratorRef bezierCoreIterator;
    CPRVector nextVector;
    CPRVector startVector;
    CPRVector endVector;
    CPRVector previousTangentVector;
    CPRVector nextTangentVector;
    CPRVector tangentVector;
    CPRVector startTangentVector;
    CPRVector endTangentVector;
    CPRVector previousNormalVector;
    CPRVector nextNormalVector;
    CPRVector normalVector;
    CPRVector startNormalVector;
    CPRVector endNormalVector;
    CPRVector segmentDirection;
    CPRVector nextSegmentDirection;
    CGFloat segmentLength;
    CGFloat distanceTraveled;
    CGFloat totalDistanceTraveled;
    CGFloat extraDistance;
    CFIndex i;
    bool done;
	
    if (numVectors == 0 || CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
	assert(normals == NULL || CPRBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
	assert(CPRBezierCoreSubpathCount(bezierCore) == 1); // TODO! I should fix this to be able to handle moveTo as long as normals don't matter

    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreSubdivide((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultSubdivideSegmentLength);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultFlatness);
    } else {
        flattenedBezierCore = CPRBezierCoreRetain(bezierCore);
    }    
    
    bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    CPRBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    extraDistance = startingDistance; // distance that was traveled past the last point
    totalDistanceTraveled = 0.0;
    done = false;
	i = 0;
    startVector = CPRVectorZero;
    endVector = CPRVectorZero;
    
    CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &startVector);
	CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endVector);
    segmentDirection = CPRVectorNormalize(CPRVectorSubtract(endVector, startVector));
    segmentLength = CPRVectorDistance(endVector, startVector);
    
    normalVector = CPRVectorNormalize(CPRVectorSubtract(initialNormal, CPRVectorProject(initialNormal, segmentDirection)));
    if(CPRVectorEqualToVector(normalVector, CPRVectorZero)) {
        normalVector = CPRVectorNormalize(CPRVectorCrossProduct(CPRVectorMake(-1.0, 0.0, 0.0), segmentDirection));
        if(CPRVectorEqualToVector(normalVector, CPRVectorZero)) {
            normalVector = CPRVectorNormalize(CPRVectorCrossProduct(CPRVectorMake(0.0, 1.0, 0.0), segmentDirection));
        }
    }
    
    previousNormalVector = normalVector;
    tangentVector = segmentDirection;
    previousTangentVector = tangentVector;
    
	while (done == false) {
		distanceTraveled = extraDistance;
        
        if (CPRBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
            nextNormalVector = normalVector;
            nextTangentVector = tangentVector;
            nextVector = endVector;
            done = true;
        } else {
            CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &nextVector);
            nextSegmentDirection = CPRVectorNormalize(CPRVectorSubtract(nextVector, endVector));
            nextNormalVector = CPRVectorBend(normalVector, segmentDirection, nextSegmentDirection);
            nextNormalVector = CPRVectorSubtract(nextNormalVector, CPRVectorProject(nextNormalVector, nextSegmentDirection)); // make sure the new vector is really normal
            nextNormalVector = CPRVectorNormalize(nextNormalVector);

            nextTangentVector = nextSegmentDirection;
        }
        startNormalVector = CPRVectorNormalize(CPRVectorScalarMultiply(CPRVectorAdd(previousNormalVector, normalVector), 0.5)); 
        endNormalVector = CPRVectorNormalize(CPRVectorScalarMultiply(CPRVectorAdd(nextNormalVector, normalVector), 0.5)); 
        
        startTangentVector = CPRVectorNormalize(CPRVectorScalarMultiply(CPRVectorAdd(previousTangentVector, tangentVector), 0.5)); 
        endTangentVector = CPRVectorNormalize(CPRVectorScalarMultiply(CPRVectorAdd(nextTangentVector, tangentVector), 0.5)); 
        
		while(distanceTraveled < segmentLength)
		{
            if (vectors) {
                vectors[i] = CPRVectorAdd(startVector, CPRVectorScalarMultiply(segmentDirection, distanceTraveled));
            }
            if (tangents) {
                tangents[i] = segmentDirection;
                tangents[i] = CPRVectorNormalize(CPRVectorAdd(CPRVectorScalarMultiply(startTangentVector, 1.0-distanceTraveled/segmentLength), CPRVectorScalarMultiply(endTangentVector, distanceTraveled/segmentLength)));
                
            }
            if (normals) {
                normals[i] = CPRVectorNormalize(CPRVectorAdd(CPRVectorScalarMultiply(startNormalVector, 1.0-distanceTraveled/segmentLength), CPRVectorScalarMultiply(endNormalVector, distanceTraveled/segmentLength)));
            }
            i++;
            if (i >= numVectors) {
                CPRBezierCoreIteratorRelease(bezierCoreIterator);
                return i;
            }
            
            distanceTraveled += spacing;
            totalDistanceTraveled += spacing;
		}
		
		extraDistance = distanceTraveled - segmentLength;
        
        previousNormalVector = normalVector;
        normalVector = nextNormalVector;
        previousTangentVector = tangentVector;
        tangentVector = nextTangentVector;
        segmentDirection = nextSegmentDirection;
        startVector = endVector;
        endVector = nextVector;
        segmentLength = CPRVectorDistance(startVector, endVector);
        
	}
	
    CPRBezierCoreIteratorRelease(bezierCoreIterator);
	return i;
}

CPRVector CPRBezierCoreNormalAtEndWithInitialNormal(CPRBezierCoreRef bezierCore, CPRVector initialNormal)
{
    CPRBezierCoreRef flattenedBezierCore;
    CPRBezierCoreIteratorRef bezierCoreIterator;
    CPRVector normalVector;
    CPRVector segment;
    CPRVector prevSegment;
    CPRVector start;
    CPRVector end;
    
	assert(CPRBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath

    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return initialNormal;
    }
    
    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultFlatness);
    } else {
        flattenedBezierCore = CPRBezierCoreRetain(bezierCore);
    }
    bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    CPRBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    
    CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &start);
    CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
    prevSegment = CPRVectorSubtract(end, start);
    
    normalVector = CPRVectorNormalize(CPRVectorSubtract(initialNormal, CPRVectorProject(initialNormal, prevSegment)));
    if(CPRVectorEqualToVector(normalVector, CPRVectorZero)) {
        normalVector = CPRVectorNormalize(CPRVectorCrossProduct(CPRVectorMake(-1.0, 0.0, 0.0), prevSegment));
        if(CPRVectorEqualToVector(normalVector, CPRVectorZero)) {
            normalVector = CPRVectorNormalize(CPRVectorCrossProduct(CPRVectorMake(0.0, 1.0, 0.0), prevSegment));
        }
    }
    
    while (!CPRBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        start = end;
        CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
        
        segment = CPRVectorSubtract(end, start);
        normalVector = CPRVectorBend(normalVector, prevSegment, segment);
        normalVector = CPRVectorSubtract(normalVector, CPRVectorProject(normalVector, segment)); // make sure the new vector is really normal
        normalVector = CPRVectorNormalize(normalVector);

        prevSegment = segment;
    }
    
    CPRBezierCoreIteratorRelease(bezierCoreIterator);
    return normalVector;
}

CPRBezierCoreRef CPRBezierCoreCreateOutline(CPRBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, CPRVector initialNormal)
{
    return CPRBezierCoreCreateMutableOutline(bezierCore, distance, spacing, initialNormal);
}

CPRMutableBezierCoreRef CPRBezierCoreCreateMutableOutline(CPRBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, CPRVector initialNormal)
{
    CPRBezierCoreRef flattenedBezierCore;
    CPRMutableBezierCoreRef outlineBezier;
    CPRVector endpoint;
    CPRVector endpointNormal;
    CGFloat length;
    NSInteger i;
    NSUInteger numVectors;
    CPRVectorArray vectors;
    CPRVectorArray normals;
    CPRVectorArray scaledNormals;
    CPRVectorArray side;
    
	assert(CPRBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath

    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return NULL;
    }
    
    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreSubdivide((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultSubdivideSegmentLength);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultFlatness);
    } else {
        flattenedBezierCore = CPRBezierCoreRetain(bezierCore); 
    }
        
    length = CPRBezierCoreLength(flattenedBezierCore);
    
    if (spacing * 2 >= length) {
        CPRBezierCoreRelease(flattenedBezierCore);
        return NULL;
    }
    
    numVectors = length/spacing + 1.0;
    
    vectors = malloc(numVectors * sizeof(CPRVector));
    normals = malloc(numVectors * sizeof(CPRVector));
    scaledNormals = malloc(numVectors * sizeof(CPRVector));
    side = malloc(numVectors * sizeof(CPRVector));
    outlineBezier = CPRBezierCoreCreateMutable();
    
    numVectors = CPRBezierCoreGetVectorInfo(flattenedBezierCore, spacing, 0, initialNormal, vectors, NULL, normals, numVectors);
    CPRBezierCoreGetSegmentAtIndex(flattenedBezierCore, CPRBezierCoreSegmentCount(flattenedBezierCore) - 1, NULL, NULL, &endpoint);
    endpointNormal = CPRVectorNormalize(CPRVectorSubtract(normals[numVectors-1], CPRVectorProject(normals[numVectors-1], CPRBezierCoreTangentAtEnd(flattenedBezierCore))));
    endpointNormal = CPRVectorScalarMultiply(endpointNormal, distance);
    
    memcpy(scaledNormals, normals, numVectors * sizeof(CPRVector));
    CPRVectorScalarMultiplyVectors(distance, scaledNormals, numVectors);

    memcpy(side, vectors, numVectors * sizeof(CPRVector));
    CPRVectorAddVectors(side, scaledNormals, numVectors);
    
    CPRBezierCoreAddSegment(outlineBezier, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        CPRBezierCoreAddSegment(outlineBezier, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, side[i]);
    }
    CPRBezierCoreAddSegment(outlineBezier, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, CPRVectorAdd(endpoint, endpointNormal));
                                                
    memcpy(scaledNormals, normals, numVectors * sizeof(CPRVector));
    CPRVectorScalarMultiplyVectors(-distance, scaledNormals, numVectors);

    memcpy(side, vectors, numVectors * sizeof(CPRVector));
    CPRVectorAddVectors(side, scaledNormals, numVectors);

    CPRBezierCoreAddSegment(outlineBezier, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        CPRBezierCoreAddSegment(outlineBezier, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, side[i]);
    }
    CPRBezierCoreAddSegment(outlineBezier, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, CPRVectorAdd(endpoint, CPRVectorInvert(endpointNormal)));
    
    free(vectors);
    free(normals);
    free(scaledNormals);
    free(side);
    
    CPRBezierCoreRelease(flattenedBezierCore);
    
    return outlineBezier;
}

CGFloat CPRBezierCoreLengthToSegmentAtIndex(CPRBezierCoreRef bezierCore, CFIndex index, CGFloat flatness) // the length up to and including the segment at index
{
    CPRMutableBezierCoreRef shortBezierCore;
    CPRBezierCoreIteratorRef bezierCoreIterator;
    CPRBezierCoreSegmentType segmentType;
	CPRBezierCoreRef flattenedShortBezierCore;
    CPRVector endpoint;
    CPRVector control1;
    CPRVector control2;
    CGFloat length;
    CFIndex i;
    
    assert(index < CPRBezierCoreSegmentCount(bezierCore));
    
    bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(bezierCore);
    shortBezierCore = CPRBezierCoreCreateMutable();
    
    for (i = 0; i <= index; i++) {
        segmentType = CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
        CPRBezierCoreAddSegment(shortBezierCore, segmentType, control1, control2, endpoint);
    }
    
	flattenedShortBezierCore = CPRBezierCoreCreateFlattenedMutableCopy(shortBezierCore, flatness);
    length = CPRBezierCoreLength(flattenedShortBezierCore);
	
    CPRBezierCoreRelease(shortBezierCore);
	CPRBezierCoreRelease(flattenedShortBezierCore);
    CPRBezierCoreIteratorRelease(bezierCoreIterator);
    
    return length;
}

CFIndex CPRBezierCoreSegmentLengths(CPRBezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness) // returns the number of lengths set
{
	CPRBezierCoreIteratorRef bezierCoreIterator;
	CPRMutableBezierCoreRef segmentBezierCore;
	CPRMutableBezierCoreRef flatenedSegmentBezierCore;
	CPRVector prevEndpoint;
	CPRVector control1;
	CPRVector control2;
	CPRVector endpoint;
	CPRBezierCoreSegmentType segmentType;
	CFIndex i;

	bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(bezierCore);
	
	if (numLengths > 0 && CPRBezierCoreSegmentCount(bezierCore) > 0) {
		lengths[0] = 0.0;
	} else {
		return 0;
	}

	
	CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
	
	for (i = 1; i < MIN(numLengths, CPRBezierCoreSegmentCount(bezierCore)); i++) {
		segmentType = CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
		
		segmentBezierCore = CPRBezierCoreCreateMutable();
		CPRBezierCoreAddSegment(segmentBezierCore, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, prevEndpoint);
		CPRBezierCoreAddSegment(segmentBezierCore, segmentType, control1, control2, endpoint);
		
		flatenedSegmentBezierCore = CPRBezierCoreCreateFlattenedMutableCopy(segmentBezierCore, flatness);
		lengths[i] = CPRBezierCoreLength(flatenedSegmentBezierCore);
		
		CPRBezierCoreRelease(segmentBezierCore);
		CPRBezierCoreRelease(flatenedSegmentBezierCore);
	}
	
	CPRBezierCoreIteratorRelease(bezierCoreIterator);

	return i;
}

CFIndex CPRBezierCoreCountIntersectionsWithPlane(CPRBezierCoreRef bezierCore, CPRPlane plane)
{
	CPRBezierCoreRef flattenedBezierCore;
	CPRBezierCoreIteratorRef bezierCoreIterator;
    CPRVector endpoint;
    CPRVector prevEndpoint;
	CPRBezierCoreSegmentType segmentType;
    NSInteger count;
    NSUInteger numVectors;
    
    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreSubdivide((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultSubdivideSegmentLength);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultFlatness);
    } else {
        flattenedBezierCore = CPRBezierCoreRetain(bezierCore); 
    }
	bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    CPRBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
	count = 0;
	
	CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
	
	while (!CPRBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
		segmentType = CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
		if (segmentType != CPRMoveToBezierCoreSegmentType && CPRPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
			count++;
		}
		prevEndpoint = endpoint;
	}
	CPRBezierCoreIteratorRelease(bezierCoreIterator);
	return count;
}


CFIndex CPRBezierCoreIntersectionsWithPlane(CPRBezierCoreRef bezierCore, CPRPlane plane, CPRVectorArray intersections, CGFloat *relativePositions, CFIndex numVectors)
{
	CPRBezierCoreRef flattenedBezierCore;
	CPRBezierCoreIteratorRef bezierCoreIterator;
    CPRVector endpoint;
    CPRVector prevEndpoint;
	CPRVector segment;
	CPRVector intersection;
	CPRBezierCoreSegmentType segmentType;
    CGFloat length;
	CGFloat distance;
    NSInteger count;
    
    if (CPRBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    if (CPRBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
        CPRBezierCoreSubdivide((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultSubdivideSegmentLength);
        CPRBezierCoreFlatten((CPRMutableBezierCoreRef)flattenedBezierCore, CPRBezierDefaultFlatness);
    } else {
        flattenedBezierCore = CPRBezierCoreRetain(bezierCore); 
    }
    length = CPRBezierCoreLength(flattenedBezierCore);
	bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    CPRBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
	distance = 0.0; 
	count = 0;
	
	CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
	
	while (!CPRBezierCoreIteratorIsAtEnd(bezierCoreIterator) && count < numVectors) {
		segmentType = CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
		if (CPRPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
			if (segmentType != CPRMoveToBezierCoreSegmentType) {
				intersection = CPRLineIntersectionWithPlane(CPRLineMakeFromPoints(prevEndpoint, endpoint), plane);
				if (intersections) {
					intersections[count] = intersection;
				}
				if (relativePositions) {
					relativePositions[count] = (distance + CPRVectorDistance(prevEndpoint, intersection))/length;
				}
				count++;
			}
		}
		distance += CPRVectorDistance(prevEndpoint, endpoint);
		prevEndpoint = endpoint;
	}
	CPRBezierCoreIteratorRelease(bezierCoreIterator);
	return count;	
}

CFDictionaryRef CPRBezierCoreCreateDictionaryRepresentation(CPRBezierCoreRef bezierCore)
{
	NSMutableArray *segments;
	NSDictionary *segmentDictionary;
	CPRVector control1;
	CPRVector control2;
	CPRVector endpoint;
	CFDictionaryRef control1Dict;
	CFDictionaryRef control2Dict;
	CFDictionaryRef endpointDict;
	CPRBezierCoreSegmentType segmentType;
	CPRBezierCoreIteratorRef bezierCoreIterator;
	
	segments = [NSMutableArray array];
	bezierCoreIterator = CPRBezierCoreIteratorCreateWithBezierCore(bezierCore);
	
	while (CPRBezierCoreIteratorIsAtEnd(bezierCoreIterator) == NO) {
		segmentType = CPRBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
		control1Dict = CPRVectorCreateDictionaryRepresentation(control1);
		control2Dict = CPRVectorCreateDictionaryRepresentation(control2);
		endpointDict = CPRVectorCreateDictionaryRepresentation(endpoint);
		switch (segmentType) {
			case CPRMoveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"moveTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case CPRLineToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"lineTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case CPRCloseBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"close", @"segmentType", (id)endpointDict, @"endpoint", nil];
			case CPRCurveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"curveTo", @"segmentType", (id)control1Dict, @"control1",
									 (id)control2Dict, @"control2", (id)endpointDict, @"endpoint", nil];
				break;
			default:
				assert(0);
				break;
		}
		CFRelease(control1Dict);
		CFRelease(control2Dict);
		CFRelease(endpointDict);
		[segments addObject:segmentDictionary];
	}
	CPRBezierCoreIteratorRelease(bezierCoreIterator);
	return (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:segments, @"segments", nil];
}

CPRBezierCoreRef CPRBezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict)
{
	return CPRBezierCoreCreateMutableWithDictionaryRepresentation(dict);
}

// we could make this a bit more robust against passing in junk
CPRMutableBezierCoreRef CPRBezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict)
{
	NSArray *segments;
	NSDictionary *segmentDictionary;
	CPRMutableBezierCoreRef mutableBezierCore;
	CPRVector control1;
	CPRVector control2;
	CPRVector endpoint;
	
	segments = [(NSDictionary*)dict objectForKey:@"segments"];
	if (segments == nil) {
		return NULL;
	}
	
	mutableBezierCore = CPRBezierCoreCreateMutable();
	
	for (segmentDictionary in segments) {
		if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"moveTo"]) {
			endpoint = CPRVectorZero;
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			CPRBezierCoreAddSegment(mutableBezierCore, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"lineTo"]) {
			endpoint = CPRVectorZero;
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			CPRBezierCoreAddSegment(mutableBezierCore, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"close"]) {
			endpoint = CPRVectorZero;
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			CPRBezierCoreAddSegment(mutableBezierCore, CPRCloseBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"curveTo"]) {
			control1 = CPRVectorZero;
			control2 = CPRVectorZero;
			endpoint = CPRVectorZero;
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control1"], &control1);
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control2"], &control2);
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			CPRBezierCoreAddSegment(mutableBezierCore, CPRCurveToBezierCoreSegmentType, control1, control2, endpoint);
		} else {
			assert(0);
		}
	}
	
	return mutableBezierCore;
}





















