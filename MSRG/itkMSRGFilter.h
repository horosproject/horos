/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/



#ifndef __itkMSRGFilter_h
#define __itkMSRGFilter_h

#include "itkImage.h"
#include "itkImageToImageFilter.h"

namespace itk
  {
  template < class TInputImage >
  class ITK_EXPORT MSRGFilter: public ImageToImageFilter < TInputImage, Image<unsigned char,::itk::GetImageDimension<TInputImage>::ImageDimension> >
    {

    public:

      typedef MSRGFilter Self;
      typedef SmartPointer < Self > Pointer;
      typedef SmartPointer < const Self > ConstPointer;

      /** Method for creation through the object factory. */
      itkNewMacro (Self);

      /** Run-time type information (and related methods).  */
      itkTypeMacro (MSRGFilter, ImageToImageFilter);
      itkStaticConstMacro(ImageDimension, unsigned int,
                          TInputImage::ImageDimension);

      // Images
      typedef TInputImage InputImageType;
      typedef Image<unsigned char, itkGetStaticConstMacro(ImageDimension)> OutputImageType;

      // Pointers
      typedef typename InputImageType::Pointer InputImagePointer;
      typedef typename InputImageType::ConstPointer InputImageConstPointer;
      
      typedef typename OutputImageType::Pointer OutputImagePointer;
	
      // Regions
      typedef typename InputImageType::RegionType InputImageRegionType;
      typedef typename OutputImageType::RegionType OutputImageRegionType;

      // PixelType
      typedef typename OutputImageType::PixelType OutputImagePixelType;
      typedef typename InputImageType::PixelType CriteriaImagePixelType;

      // size index
      typedef typename InputImageType::IndexType IndexCriteriaType;
      typedef typename OutputImageType::IndexType IndexOutputType;

      // size
      typedef typename InputImageType::SizeType CriteriaSizeType;
      typedef ImageToImageFilter< InputImageType, OutputImageType > Superclass;

      void PrintSelf (std::ostream & os, Indent indent) const;

      void SetMarker(OutputImageType* _marker)
      {
        m_Marker=_marker;
      };
      
      void LabelMarkerImage(bool operation)
      {
	 labelMarker=operation;
      }
    protected:
      MSRGFilter ();
      ~MSRGFilter ()
      {}
      ;
      OutputImageType* m_Marker;
      bool labelMarker;

      // Override since the filter needs all the data for the algorithm
      void GenerateInputRequestedRegion ();

      // Override since the filter produces the entire dataset
      void EnlargeOutputRequestedRegion (DataObject * output);

      void GenerateData ();


    private:
      MSRGFilter (const Self &);
      //purposely not implemented
      void operator= (const Self &);	//purposely not implemented

    };


}				// end namespace itk


#ifndef ITK_MANUAL_INSTANTIATION
#include "itkMSRGFilter.txx"
#endif

#endif
