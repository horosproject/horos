/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

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


  template < class TInputImage, class TOutputImage, class TCriteriaImage, unsigned int NbCriteria=1>
  class ITK_EXPORT MSRGFilter: public ImageToImageFilter < TInputImage, TOutputImage >
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
	  typedef TOutputImage OutputImageType;
      typedef TCriteriaImage CriteriaImageType;
      typedef Image<unsigned short, itkGetStaticConstMacro(ImageDimension)> StatusImageType;
	
      // Pointers
      typedef typename InputImageType::Pointer InputImagePointer;
      typedef typename InputImageType::ConstPointer InputImageConstPointer;
      typedef typename CriteriaImageType::Pointer CriteriaImagePointer;
      typedef typename OutputImageType::Pointer OutputImagePointer;
	  typedef typename StatusImageType::Pointer StatusImagePointer;

      // Regions
      typedef typename InputImageType::RegionType InputImageRegionType;
      typedef typename OutputImageType::RegionType OutputImageRegionType;

      // PixelType
      typedef typename InputImageType::PixelType InputImagePixelType;
      typedef typename OutputImageType::PixelType OutputImagePixelType;
      typedef typename StatusImageType::PixelType StatusImagePixelType;
      typedef typename CriteriaImageType::PixelType CriteriaImagePixelType;

      // size index
      typedef typename InputImageType::IndexType IndexType;
      typedef typename CriteriaImageType::IndexType IndexCriteriaType;
	  typedef typename OutputImageType::IndexType IndexOutputType;
	  typedef typename StatusImageType::IndexType IndexStatusType;
      
      // size
      typedef typename InputImageType::SizeType SizeType;
      typedef typename CriteriaImageType::SizeType CriteriaSizeType;


      typedef ImageToImageFilter< InputImageType, OutputImageType > Superclass;

      void PrintSelf (std::ostream & os, Indent indent) const;

      void SetMarker(OutputImageType* _marker)
      {
        m_Marker=_marker;
      };
      void SetCriteria(CriteriaImageType* _criteria)
      {
        m_Criteria=_criteria;
      };
    protected:
      MSRGFilter ();
      ~MSRGFilter ()
      {}
      ;
      OutputImageType* m_Marker;
      CriteriaImageType* m_Criteria;


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
