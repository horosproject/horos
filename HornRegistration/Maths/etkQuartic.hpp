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

/*! \file etkQuartic.hpp
    \brief  Various quartic routines.
    (Original author: Don Herbison-Evans)
 */

#ifndef etkQuadric_hpp
#define etkQuadric_hpp 1

/// Solve quartic equation of form x**4 + a*x**3 + b*x**2 + c*x + d = 0 
int etkQuartic (double a, double b, double c, double d, double rts[4]);

#endif
