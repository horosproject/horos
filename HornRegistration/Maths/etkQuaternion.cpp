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

/*! \file etkQuaternion.cpp
    \brief  Quaternion basic operations.
 */

#include <math.h>

#include "etkQuaternion.hpp"

// !!! NO CHECKS (asserts, div0, ...) !!!

// ----------------------------------------------------------------------------
// Create and initialize a quaternion

etkQuaternion* etkCreateQuaternion (double dW, double dX, double dY, double dZ)
{
  etkQuaternion* pQuat = new etkQuaternion;

  pQuat->dW = dW;
  pQuat->dX = dX;
  pQuat->dY = dY;
  pQuat->dZ = dZ;

  return pQuat;
}

// ----------------------------------------------------------------------------
// Normalize a quaternion

void etkNormalizeQuaterion (etkQuaternion* pQuat)
{
  double dNorm = sqrt (pQuat->dW * pQuat->dW + pQuat->dX * pQuat->dX +
                       pQuat->dY * pQuat->dY + pQuat->dZ * pQuat->dZ);
  pQuat->dW /= dNorm;
  pQuat->dX /= dNorm;
  pQuat->dY /= dNorm;
  pQuat->dZ /= dNorm;

}

// ----------------------------------------------------------------------------
// Transform a quaternion to a 3x3 (rotation) matrix

void etkQuaterionToMatrix33 (etkQuaternion* pQuat, matrix* pMat33)
{
  // calculate coefficients
  double dX2 = pQuat->dX + pQuat->dX,
         dY2 = pQuat->dY + pQuat->dY,
         dZ2 = pQuat->dZ + pQuat->dZ,
         dXX = pQuat->dX * dX2,
         dXY = pQuat->dX * dY2,
         dXZ = pQuat->dX * dZ2,
         dYY = pQuat->dY * dY2,
         dYZ = pQuat->dY * dZ2,
         dZZ = pQuat->dZ * dZ2,
         dWX = pQuat->dW * dX2,
         dWY = pQuat->dW * dY2,
         dWZ = pQuat->dW * dZ2;

  pMat33->block [0] = 1.0f - (dYY + dZZ);
  pMat33->block [1] = dXY + dWZ;
  pMat33->block [2] = dXZ - dWY;
  pMat33->block [3] = dXY - dWZ;
  pMat33->block [4] = 1.0f - (dXX + dZZ);
  pMat33->block [5] = dYZ + dWX;
  pMat33->block [6] = dXZ + dWY;
  pMat33->block [7] = dYZ - dWX;
  pMat33->block [8] = 1.0f - (dXX + dYY);
}
