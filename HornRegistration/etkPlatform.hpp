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
    \date       09/2004
*/
//===========================================================================

/*! \file etkPlatform.hpp
    \brief Detect compiler and platform
 */

#ifndef etkPlatform_hpp
#define etkPlatform_hpp

  // Define compiler
  // ---------------

  // VCC_COMPILER = Microsoft Visual C++
  // BCC_COMPILER = Borland C++ Builder 
  // GCC_COMPILER = GCC or generic compiler

  #ifdef __WIN32__
    #define BCC_COMPILER
    #define ETK_WIN
  #else
    #ifdef WIN32
      #define VCC_COMPILER
      #define ETK_WIN
    #else
      #define GCC_COMPILER
      #define ETK_UNIX
    #endif
  #endif
#endif
