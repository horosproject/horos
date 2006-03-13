//===========================================================================
/*
    This file is part of the ATRACSYS OPEN SOURCE LIBRARY.
    Copyright (C) 2003-2004 by Atracsys sàrl. All rights reserved.

    This library is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License("GPL") version 2
    as published by the Free Software Foundation.

    For using the HornRegistration libraries with software that can not be combined
    with the GNU GPL, and for taking advantage of the additional benefits
    of our support services, please contact Atracsys about acquiring a
    Professional Edition License.

    \author:    <http://atracsys.com>
    \author:    Gaëtan Marti
    \version    1.0
    \date       08/2004
*/
//===========================================================================

/*! \file etkRegistration.cpp
    \brief 3D-3D point registration using the Horn method.
 */
 
#include <etkPlatform.hpp>

#ifdef VCC_COMPILER
 #include <memory.h>
#else
// #include <mem.h>
 #include <string.h>
#endif
#include <math.h>

#ifndef NULL
 #define NULL 0L
#endif

//#include <API/etkErrorAPI.hpp>
//#include <Maths/etkQuartic.hpp>
//#include <Maths/etkQuaternion.hpp>
#include "etkErrorAPI.hpp"
#include "etkQuartic.hpp"
#include "etkQuaternion.hpp"

#include "etkRegistration.hpp"

//---------------------------------------------------------------------------
// PRIVATE: determinant of a 3x3 matrix
// ----------------------------------------------------------------------------

static double etkDet33 (double a1, double b1, double c1,
                        double a2, double b2, double c2,
                        double a3, double b3, double c3)
{
  return a1*b2*c3 + b1*c2*a3 + c1*a2*b3 - a3*b2*c1 - b3*c2*a1 - c3*a2*b1;
}

//---------------------------------------------------------------------------
// PRIVATE: comatrix of a 4x4 matrix
// ----------------------------------------------------------------------------

static void etkComatrix44 (double &a1, double &b1, double &c1, double &d1,
                           double &a2, double &b2, double &c2, double &d2,
                           double &a3, double &b3, double &c3, double &d3,
                           double &a4, double &b4, double &c4, double &d4)
{
  double coffa1, coffa2, coffa3, coffa4,
         coffb1, coffb2, coffb3, coffb4,
         coffc1, coffc2, coffc3, coffc4,
         coffd1, coffd2, coffd3, coffd4;

  coffa1 = etkDet33 (b2, c2, d2,
                     b3, c3, d3,
                     b4, c4, d4);
  coffb1 = -etkDet33 (a2, c2, d2,
                      a3, c3, d3,
                      a4, c4, d4);
  coffc1 = etkDet33 (a2, b2, d2,
                     a3, b3, d3,
                     a4, b4, d4);
  coffd1 = -etkDet33 (a2, b2, c2,
                      a3, b3, c3,
                      a4, b4, c4);

  coffa2 = -etkDet33 (b1, c1, d1,
                      b3, c3, d3,
                      b4, c4, d4);
  coffb2 = etkDet33 (a1, c1, d1,
                     a3, c3, d3,
                     a4, c4, d4);
  coffc2 = -etkDet33 (a1, b1, d1,
                      a3, b3, d3,
                      a4, b4, d4);
  coffd2 = etkDet33 (a1, b1, c1,
                     a3, b3, c3,
                     a4, b4, c4);

  coffa3 = etkDet33 (b1, c1, d1,
                     b2, c2, d2,
                     b4, c4, d4);
  coffb3 = -etkDet33 (a1, c1, d1,
                      a2, c2, d2,
                      a4, c4, d4);
  coffc3 = etkDet33 (a1, b1, d1,
                     a2, b2, d2,
                     a4, b4, d4);
  coffd3 = -etkDet33 (a1, b1, c1,
                      a2, b2, c2,
                      a4, b4, c4);

  coffa4 = -etkDet33 (b1, c1, d1,
                      b2, c2, d2,
                      b3, c3, d3);
  coffb4 = etkDet33 (a1, c1, d1,
                     a2, c2, d2,
                     a3, c3, d3);
  coffc4 = -etkDet33 (a1, b1, d1,
                      a2, b2, d2,
                      a3, b3, d3);
  coffd4 = etkDet33 (a1, b1, c1,
                     a2, b2, c2,
                     a3, b3, c3);

  a1 = coffa1;  a2 = coffa2;  a3 = coffa3;  a4 = coffa4;
  b1 = coffb1;  b2 = coffb2;  b3 = coffb3;  b4 = coffb4;
  c1 = coffc1;  c2 = coffc2;  c3 = coffc3;  c4 = coffc4;
  d1 = coffd1;  d2 = coffd2;  d3 = coffd3;  d4 = coffd4;

}

// ----------------------------------------------------------------------------
// PRIVATE: eigen value decomposition of a 4x4 matrix
// ----------------------------------------------------------------------------

static etkQuaternion* etkRegisterMatrix (double dN11, double dN12, double dN13, double dN14,
                                         double dN21, double dN22, double dN23, double dN24,
                                         double dN31, double dN32, double dN33, double dN34,
                                         double dN41, double dN42, double dN43, double dN44)
{
  // Determinant of N - y*I
  double dByyy, dCyy, dDy, dE;

  int i;

  // Ay^4 + By^3 + Cy^2 + Dy + E = 0;

  // ---- First row of the determinant ----

  // 1.1
  dByyy = - dN11 - dN22 - dN33 - dN44;
  dCyy = dN11*dN22 + dN11*dN33 + dN11*dN44 + dN22*dN33 + dN22*dN44 + dN33*dN44;
  dDy = - dN11*dN22*dN33 - dN11*dN22*dN44 - dN11*dN33*dN44 - dN22*dN33*dN44;
  dE = dN11*dN22*dN33*dN44;
  // 1.2
  dDy -= dN23*dN34*dN42;
  dE += dN11*dN23*dN34*dN42;
  // 1.3
  dDy -= dN24*dN32*dN43;
  dE += dN11*dN24*dN32*dN43;
  // 1.4
  dCyy -= dN34*dN43;
  dDy += (dN11 + dN22)*dN34*dN43;
  dE -= dN11*dN22*dN34*dN43;
  // 1.5
  dCyy -= dN23*dN32;
  dDy += (dN11 + dN44)*dN23*dN32;
  dE -= dN11*dN23*dN32*dN44;
  // 1.6
  dCyy -= dN24*dN42;
  dDy += (dN11 + dN33)*dN24*dN42;
  dE -= dN11*dN24*dN33*dN42;

  // ---- Second row of the determinant ----

  // 2.1
  dCyy -= dN21*dN12;
  dDy += dN21*dN12*(dN33 + dN44);
  dE -= dN21*dN12*dN33*dN44;
  // 2.2
  dE -= dN21*dN13*dN34*dN42;
  // 2.3
  dE -= dN21*dN14*dN32*dN43;
  // 2.4
  dE += dN21*dN12*dN34*dN43;
  // 2.5
  dDy -= dN21*dN13*dN32;
  dE += dN21*dN13*dN32*dN44;
  // 2.6
  dDy -= dN21*dN14*dN42;
  dE += dN21*dN14*dN33*dN42;

  // ---- Third row of the determinant ----

  // 3.1
  dDy -= dN31*dN12*dN23;
  dE += dN31*dN12*dN23*dN44;
  // 3.2
  dE += dN31*dN13*dN24*dN42;
  // 3.3
  dDy -= dN31*dN14*dN43;
  dE += dN31*dN14*dN22*dN43;
  // 3.4
  dE -= dN31*dN12*dN24*dN43;
  // 3.5
  dCyy -= dN31*dN13;
  dDy += dN31*dN13*(dN22 + dN44);
  dE -= dN31*dN13*dN22*dN44;
  // 3.6
  dE -= dN31*dN14*dN23*dN42;

  // ---- Forth row of the determinant ----

  // 4.1
  dE -= dN41*dN12*dN23*dN34;
  // 4.2
  dE -= dN41*dN13*dN24*dN32;
  // 4.3
  dCyy -= dN41*dN14;
  dDy += dN41*dN14*(dN22 + dN33);
  dE -= dN41*dN14*dN22*dN33;
  // 4.4
  dDy -= dN41*dN12*dN24;
  dE += dN41*dN12*dN24*dN33;
  // 4.5
  dDy -= dN41*dN13*dN34;
  dE += dN41*dN13*dN34*dN22;
  // 4.6
  dE += dN41*dN14*dN23*dN32;

  double adRoots [4];

  for (i = 0; i < 4; i++)
    adRoots[i] = 0.0;

  // Solving the quartic equation to obtain the eigenvalues
  int iNbRoots = etkQuartic (dByyy, dCyy, dDy, dE, adRoots);

  double dMaxEigenValue = adRoots[0];

  // Finding the  argest eigenvalue
  for (i = 1; i<iNbRoots; i++)
    if (adRoots[i] > dMaxEigenValue)
      dMaxEigenValue = adRoots[i];

  double dN11bis = dN11 - dMaxEigenValue;
  double dN22bis = dN22 - dMaxEigenValue;
  double dN33bis = dN33 - dMaxEigenValue;
  double dN44bis = dN44 - dMaxEigenValue;

  etkComatrix44 (dN11bis, dN12, dN13, dN14,
                 dN21, dN22bis, dN23, dN24,
                 dN31, dN32, dN33bis, dN34,
                 dN41, dN42, dN43, dN44bis);

  etkQuaternion* pQuat = etkCreateQuaternion (dN11bis+dN21+dN31+dN41,
                                              dN12+dN22bis+dN32+dN42,
                                              dN13+dN23+dN33bis+dN43,
                                              dN14+dN24+dN34+dN44bis);
  etkNormalizeQuaterion (pQuat);

  return pQuat;
}

// ----------------------------------------------------------------------------

etkRegistration* etkCreateRegistration ()
{
  etkRegistration* pRet = new etkRegistration;
  memset (pRet, 0, sizeof (etkRegistration));
  return pRet; 
}

// ----------------------------------------------------------------------------
// Register the two point sets.
// - Rotation matrix is stored in p33Rot,
// - Translation vector is stored in pTrans
// - Return error matrix
// ----------------------------------------------------------------------------

#define ADD3D(d,s)         {d[0] += s [0]; d[1] += s [1]; d[2] += s [2];};
#define SUB3D(d,s)         {d[0] -= s [0]; d[1] -= s [1]; d[2] -= s [2];};
#define MULTSCAL3D(d,scal) {d[0] *= scal; d[1] *= scal; d[2] *= scal;};
#define MAT33(a,b)          matRot33.block [(a) + (b) * 3]

double etkRegister (etkRegistration* pRegistration,
                    double** radRot33, double** radTrans3)
{
  unsigned u;

  if (pRegistration->uNbPoints < 3)
  {
    *radRot33  = NULL;
    *radTrans3 = NULL;
    return -1;
  }

  *radRot33  = new double [3*3];
  *radTrans3 = new double [3];

  matrix matRot33  = {3, 3, *radRot33};
  matrix matTrans3 = {3, 1, *radTrans3};

  // 1. Find centroid

  double adModelCentroid  [3] = {0.0, 0.0, 0.0};
  double adSensorCentroid [3] = {0.0, 0.0, 0.0};

  for (u = 0; u < pRegistration->uNbPoints; u++)
  {
    ADD3D (adModelCentroid,  pRegistration->adModelPoints [u]);
    ADD3D (adSensorCentroid, pRegistration->adSensorPoints [u]);
  }

  double dFactor = 1.0 / (double) pRegistration->uNbPoints;

  MULTSCAL3D (adModelCentroid,  dFactor);
  MULTSCAL3D (adSensorCentroid, dFactor);

  // 2. Recenter points and compute momentum

  double dSxx = 0,
         dSxy = 0,
         dSxz = 0,
         dSyx = 0,
         dSyy = 0,
         dSyz = 0,
         dSzx = 0,
         dSzy = 0,
         dSzz = 0;

  for (u = 0; u < pRegistration->uNbPoints; u++)
  {
    SUB3D (pRegistration->adModelPoints [u],  adModelCentroid);
    SUB3D (pRegistration->adSensorPoints [u], adSensorCentroid);

    dSxx += pRegistration->adSensorPoints [u][0] *
            pRegistration->adModelPoints [u][0];
    dSxy += pRegistration->adSensorPoints [u][0] *
            pRegistration->adModelPoints [u][1];
    dSxz += pRegistration->adSensorPoints [u][0] *
            pRegistration->adModelPoints [u][2];
    dSyx += pRegistration->adSensorPoints [u][1] *
            pRegistration->adModelPoints [u][0];
    dSyy += pRegistration->adSensorPoints [u][1] *
            pRegistration->adModelPoints [u][1];
    dSyz += pRegistration->adSensorPoints [u][1] *
            pRegistration->adModelPoints [u][2];
    dSzx += pRegistration->adSensorPoints [u][2] *
            pRegistration->adModelPoints [u][0];
    dSzy += pRegistration->adSensorPoints [u][2] *
            pRegistration->adModelPoints [u][1];
    dSzz += pRegistration->adSensorPoints [u][2] *
            pRegistration->adModelPoints [u][2];
  }

  // N Symmetric Matrix

  double dN11, dN12, dN13, dN14, dN22, dN23, dN24, dN33, dN34, dN44;
  double dN21, dN31, dN41, dN32, dN42, dN43;

  dN11 = dSxx + dSyy + dSzz;
  dN12 = dSyz - dSzy;
  dN13 = dSzx - dSxz;
  dN14 = dSxy - dSyx;
  dN22 = dSxx - dSyy - dSzz;
  dN23 = dSxy + dSyx;
  dN24 = dSzx + dSxz;
  dN33 = -dSxx + dSyy - dSzz;
  dN34 = dSyz + dSzy;
  dN44 = -dSxx - dSyy + dSzz;
  dN21 = dN12;
  dN31 = dN13;
  dN41 = dN14;
  dN32 = dN23;
  dN42 = dN24;
  dN43 = dN34;

  etkQuaternion* pQuat = etkRegisterMatrix (dN11, dN12, dN13, dN14,
                                            dN21, dN22, dN23, dN24,
                                            dN31, dN32, dN33, dN34,
                                            dN41, dN42, dN43, dN44);

  etkNormalizeQuaterion (pQuat);

  etkQuaterionToMatrix33 (pQuat, &matRot33);

  matrix matModelCentroid = {3, 1, adModelCentroid};

  mmult (&matRot33, &matModelCentroid, &matTrans3);

  for (u = 0; u < 3; u++)
    matTrans3.block [u] =  adSensorCentroid [u] - matTrans3.block [u];	//

  /// Compute error

  double dError = 0.0;

  for (u = 0; u < pRegistration->uNbPoints; u++)
  {
    double dX = MAT33 (0,0) * pRegistration->adSensorPoints [u][0] +
                MAT33 (0,1) * pRegistration->adSensorPoints [u][1] +
                MAT33 (0,2) * pRegistration->adSensorPoints [u][2] -
                pRegistration->adModelPoints [u][0],
           dY = MAT33 (1,0) * pRegistration->adSensorPoints [u][0] +
                MAT33 (1,1) * pRegistration->adSensorPoints [u][1] +
                MAT33 (1,2) * pRegistration->adSensorPoints [u][2] -
                pRegistration->adModelPoints [u][1],
           dZ = MAT33 (2,0) * pRegistration->adSensorPoints [u][0] +
                MAT33 (2,1) * pRegistration->adSensorPoints [u][1] +
                MAT33 (2,2) * pRegistration->adSensorPoints [u][2] -
                pRegistration->adModelPoints [u][2];

    dError += sqrt (dX * dX + dY * dY + dZ * dZ);
  }

  return dError / (double) pRegistration->uNbPoints;
}

// ----------------------------------------------------------------------------

