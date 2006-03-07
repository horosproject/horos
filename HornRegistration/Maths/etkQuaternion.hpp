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

/*! \file etkQuaternion.hpp
    \brief  Quaternion basic operations.
    (Original author: Nicolas Chauvin)
 */

#ifndef etkQuaternion_hpp
#define etkQuaternion_hpp 1

  #include "etkMatrix.hpp"

  /// Quaternion structure
  struct etkQuaternion {double dW, dX, dY, dZ;};

  /// Create and initialize a quaternion
  etkQuaternion* etkCreateQuaternion (double dW, double dX, double dY, double dZ);

  /// Normalize a quaternion
  void etkNormalizeQuaterion (etkQuaternion* pQuat);

  /// Transform a quaternion to a 3x3 (rotation) matrix
  void etkQuaterionToMatrix33 (etkQuaternion* pQuat, matrix* pMat33);

#endif
