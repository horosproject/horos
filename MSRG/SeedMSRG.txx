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



#ifndef _SeedMSRG_txx
#define _SeedMSRG_txx
#include "SeedMSRG.h"


template < class TImageIndex, class TPixel > SeedMSRG < TImageIndex, TPixel >::SeedMSRG ()
{
  distance=0;
  label=0;
}

template < class TImageIndex, class TPixel > SeedMSRG < TImageIndex, TPixel >::~SeedMSRG ()
{

}
template < class TImageIndex, class TPixel > int SeedMSRG < TImageIndex, TPixel >::operator () (SeedMSRG & x, SeedMSRG & y)
{
  return x.distance > y.distance;
}

#endif
