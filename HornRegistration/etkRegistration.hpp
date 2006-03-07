//===========================================================================
/*! \mainpage
 
    \section Licence
    
    This file is part of the ATRACSYS OPEN SOURCE LIBRARY.
    Copyright (C) 2003-2004 by Atracsys sàrl. All rights reserved.

    This library is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License("GPL") version 2
    as published by the Free Software Foundation.

    For using the HornRegistration libraries with software that can not be combined
    with the GNU GPL, and for taking advantage of the additional benefits
    of our support services, please contact \htmlonly <a href="http://atractsys.com">
    Atracsys</a> \endhtmlonly about acquiring a Professional Edition License.
    
    \section Description
    
    The following code implements 3D-3D point registration using the Horn method
    as described in \htmlonly <a href="../Horn1987.pdf">"Closed-form solution of 
    absolute orientation using unit quaternions"</a> \endhtmlonly (1987).

    \section Installation
    
    The makefile is created using CMake <http://www.cmake.org/>, the cross-platform, 
    open-source make system. Follow this procedure for the installation:
    
    - Install CMake
    - Stat CMakeSetup.
    - Define the source code directory (<basedir>/Source/) 
    - Define the binary code directory (<basedir>/Bin/)
    - Specify your C++ Compiler
    - Under Windows, click on the 'Configure' 2 times
    - Open a console, go in the <basedir>/Bin/ directory
    - Use the make command to build the library and the example program  
    
     \htmlonly <img align="center" src="../cmake.jpg" alt="cmake picture" border="0"> \endhtmlonly
    
    \author     Gaëtan Marti
    \version    1.00 (08/2004)
*/
//===========================================================================

/*! \file etkRegistration.hpp
    \brief 3D-3D point registration using the Horn method.
    
    Click \htmlonly <a href="../Horn1987.pdf">here</a> \endhtmlonly
    to read the original Horn paper: "Closed-form solution of 
    absolute orientation using unit quaternions" (1987)
    
*/

#ifndef etkRegistration_hpp
#define etkRegistration_hpp

  /// Maximum number of points during the registration  
  #define REGISTRATION_MAX_POINTS 100

 
  /// Registration structure
  struct etkRegistration
  {
    /// Number of points to be registered (minimum 3)
    unsigned uNbPoints;

    /// Model points
    double adModelPoints  [REGISTRATION_MAX_POINTS][3];

    /// Sensor points
    double adSensorPoints [REGISTRATION_MAX_POINTS][3];
  };
  
  /// Create the registration structure
  etkRegistration* etkCreateRegistration ();
  
  /// Register two datasets using the Horn method. 
  /// Return Return mean error or < 0 in case of an error.
  /// - Rotation matrix is stored in p33Rot (NULL if error)
  ///
  ///   | a0 a1 a2 |
  ///   | a3 a4 a5 |
  ///   | a6 a7 a8 |
  ///
  /// - Translation vector is stored in pTrans (NULL if error)
  ///
  ///   | b0 |
  ///   | b1 |
  ///   | b2 |
  double etkRegister (etkRegistration* pRegistration,
                      double** radRot33, double** radTrans3);

#endif
