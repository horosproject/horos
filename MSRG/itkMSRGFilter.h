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
