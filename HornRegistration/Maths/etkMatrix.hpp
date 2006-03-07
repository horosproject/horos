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

/*! \file etkMatrix.hpp
    \brief Matrix structure and operations.
    (Original author:  Nigel Salt)
 */

#ifndef etkMatrix_hpp
#define etkMatrix_hpp 1

  /*!  
   *  \brief General matrix structure
   *  
   *  E.G.
   *  double b4x4A[4][4]=
   *  {
   *    6,1,6,6,
   *    1,6,6,0,
   *    0,3,2,1,
   *    8,6,1,9
   *   };
   * matrix m4x4A={4,4,&b4x4A[0][0]};
   */
  typedef struct
  {
    /// Number of rows
    int rows;
    /// Number of columns
    int cols;
    /// Data (line1, line2, ...)
    double *block;
  } matrix,*matrixptr;


  /// Print out a matrix
  void mprint (matrixptr);

  /// Scalar multiply a matrix by a value
  void smmult (matrixptr, double);

  /// Add matrix m1 to m2 giving dm
  int madd (matrixptr m1, matrixptr m2, matrixptr dm);

  /// Multiply matrix m1 by m2 giving dm
  int mmult (matrixptr m1, matrixptr m2, matrixptr dm);

  /// Copy matrix sm to dm
  int mcopy(matrixptr sm,matrixptr dm);

  /// Transpose matrix sm and put result in dm
  int mtrans(matrixptr sm,matrixptr dm);

  /// Find determinant of matrix m
  double det(matrixptr m);

  /// Invert matrix sm and put result in dm
  int minv(matrixptr sm,matrixptr dm);

  /// Solve equation in N unknowns
  int nsolve(int rows,double *data);

  /// Set matrix to the identity matrix
  int mid(matrixptr);

  /// Set all cells of matrix to Zero
  void mzero(matrixptr);

#endif
