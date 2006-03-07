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

/*! \file Unix\etkError.cpp
    \brief Messages, warnings and errors for Unix platform.
 */
 
#include <stdio.h>
#include <stdlib.h>

//#include <API/etkErrorAPI.hpp>
#include "etkErrorAPI.hpp"

// ---------------------------------------------------------------------------------
// Diplay a message
// ---------------------------------------------------------------------------------

void etkMessage (char* pcText)
{
  fprintf (stderr, "Message: %s", pcText);
}

// ---------------------------------------------------------------------------------
// Warning message (display a message, continue execution)
// ---------------------------------------------------------------------------------

void etkWarning (char* pcText)
{
  fprintf (stderr, "Warning: %s", pcText);
}

// ---------------------------------------------------------------------------------
// Error message (display a message, stop execution)
// ---------------------------------------------------------------------------------

void etkError (char* pcText)
{
  fprintf (stderr, "Error: %s", pcText);
  exit (-1);
}

// ---------------------------------------------------------------------------------
// Assertions
// ---------------------------------------------------------------------------------

void etkAssert (long lCondition, char* pcText)
{
  if (!lCondition)
  {
    fprintf (stderr, "Assertion failed");
    exit (-1);
  }
}
