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

/*! \file Main.cpp
    \brief Test horn registration.
 */

#include <stdio.h>
#include "etkRegistration.hpp"

// ----------------------------------------------------------------------------

#define NB_PTS 4

double adModelPoints  [][3] = {{0, 0, 0}, {10, 0, 0}, {10, 10, 0}, {0, 10, 0}};
double adSensorPoints [][3] = {{5, 0, 0}, {5, 10, 0}, {5, 10, 11}, {5, 0, 10}};

// ----------------------------------------------------------------------------

int main(int argc, char* argv[])
{
  printf ("Horn Registration Test\n\n");

  unsigned u, v;

  // Create the registration structure
  etkRegistration* pReg = etkCreateRegistration ();

  // Set the number of points to register
  pReg->uNbPoints = NB_PTS;

  // Copy the model points in the etkRegistration structure
  for (u = 0; u < NB_PTS; u++)
  {
    printf ("Model point (#%d): ", u);
    for (v = 0; v < 3; v++)
    {
      pReg->adModelPoints [u][v] = adModelPoints [u][v];
      printf ("\t%3.2f", pReg->adModelPoints [u][v]);
    }
    printf ("\n");
  }
  printf ("\n");

  // Copy the sensor points in the etkRegistration structure
  for (u = 0; u < NB_PTS; u++)
  {
    printf ("Sensor point (#%d): ", u);
    for (v = 0; v < 3; v++)
    {
      pReg->adSensorPoints [u][v] = adSensorPoints [u][v];
      printf ("\t%3.2f", pReg->adSensorPoints [u][v]);
    }
    printf ("\n");
  }

  double* adRot = NULL;
  double* adTrans = NULL;

  double dError = etkRegister (pReg, &adRot, &adTrans);

  if (dError < 0.0)
  {
    printf ("Error in etkRegister");
    return -1;
  }

  // Display translation
  printf ("\nTranslation:\n");
  for (u = 0; u < 3; u++)
    printf ("\t%3.2f", adTrans [u]);
  printf ("\n\n");

  // Display rotation
  printf ("Rotation:\n");
  for (u = 0; u < 3; u++)
  {
    for (v = 0; v < 3; v++)
      printf ("\t%3.2f", adRot [u*3+v]);
    printf ("\n");
  }
  printf ("\n\n");

  printf ("Error (RMS):\n\t%lf\n\n", dError);

  printf ("**** PRESS ENTER TO EXIT ****");
  getchar ();

  delete pReg;
  return 0;
}

//---------------------------------------------------------------------------
