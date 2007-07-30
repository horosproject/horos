/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/



#ifndef SeedMSRG_H
#define SeedMSRG_H

template < class TImageIndex, class TPixel > class SeedMSRG
{

public:

  // SeedMSRG position
  TImageIndex index;
  TPixel distance;
  unsigned char label;

public:
  SeedMSRG ();
  ~SeedMSRG ();
  int operator () (SeedMSRG & x, SeedMSRG & y);
};

#ifndef ITK_MANUAL_INSTANTIATION
#include "SeedMSRG.txx"
#endif
#endif
