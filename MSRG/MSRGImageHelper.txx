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


#ifndef _MSRGImageHelper_txx
#define _MSRGImageHelper_txx
#include "MSRGImageHelper.h"
 


template < class TImage> int MSRGImageHelper<TImage>::Dimension=TImage::ImageDimension;

// STATIC METHOD !
template < class TImage> void MSRGImageHelper<TImage>::Display (const ImageType* inputImage, char* title)
{  	  
  	printf("\n - %s - \n",title);	
	typedef itk::ImageLinearConstIteratorWithIndex < ImageType > ConstIteratorType;
	ConstIteratorType inputIt (inputImage, inputImage->GetRequestedRegion ());
	inputIt.SetDirection (0);
	for (inputIt.GoToBegin (); !inputIt.IsAtEnd (); inputIt.NextLine ())
	{
		inputIt.GoToBeginOfLine ();
		while (!inputIt.IsAtEndOfLine ())
	  	{	   		
	   		std::cout << inputIt.Get () << " ";
	   		++inputIt;
	  	}
		printf ("\n");
	}      	
}

// STATIC METHOD !  
template <class TImage>  typename MSRGImageHelper<TImage>::InputImagePointer MSRGImageHelper<TImage>::BuildImageWithArray(PixelType* v, int* imageSize){  		
  	/* About last parameter for importFilter ... from itk Software guide
	
	 "A false value indicates that the ImportImageFilter will not try to 
	 delete the buffer when its destructor is called. A true value, on the other hand, will allow the 
	 filter to delete the memory block upon destruction of the import filter. 
	 For the ImportImageFilter to appropriately delete the memory block, the memory must be al- 
	 located with the C++ new() operator. Memory allocated with other memory allocation mecha- 
	 nisms, such as C malloc or calloc, will not be deleted properly by the ImportImageFilter"
	
	*/
	
	typedef itk::ImportImageFilter< PixelType, TImage::ImageDimension>   ImportFilterType;
  	typename ImportFilterType::Pointer importFilter = ImportFilterType::New();  
  	typename ImportFilterType::SizeType  size;  	
  	int numberOfPixels=1;
	for (int i=0;i<Dimension;i++)
	{		
  		size[i] = imageSize[i];		
  		numberOfPixels=numberOfPixels*imageSize[i];
  	}
	typename ImportFilterType::IndexType start;
  	start.Fill( 0 );
  	typename ImportFilterType::RegionType region;
  	region.SetIndex( start );
  	region.SetSize(  size  );	
  	importFilter->SetRegion( region ); 
	const bool importImageFilterWillOwnTheBuffer = false; 
	importFilter->SetImportPointer( v, numberOfPixels, importImageFilterWillOwnTheBuffer );
	importFilter->Update();
	return importFilter->GetOutput();		
}

template <class TImage>  typename MSRGImageHelper<TImage>::InputImagePointer MSRGImageHelper<TImage>::GaussianImageFilter(const ImageType* inputImage, double variance=0.7, unsigned int kernelSize=3){  		
	typedef itk::DiscreteGaussianImageFilter<ImageType, ImageType >  FilterType;
	typename FilterType::Pointer filter = FilterType::New();
	double gaussianVariance = variance;
	unsigned int maxKernelWidth = kernelSize;
	filter->SetVariance( gaussianVariance );
	filter->SetMaximumKernelWidth( maxKernelWidth );
	filter->SetInput(inputImage);
	filter->Update();
	return filter->GetOutput();		
}

template <class TImage> typename MSRGImageHelper<TImage>::PixelType MSRGImageHelper<TImage>::GetImageMax(const ImageType* inputImage){
 	typedef itk::MinimumMaximumImageCalculator < ImageType> MinimumMaximumImageCalculatorType;
	typename MinimumMaximumImageCalculatorType::Pointer MinMaxCalculator = MinimumMaximumImageCalculatorType::New ();
	MinMaxCalculator->SetImage(inputImage);
	MinMaxCalculator->SetRegion(inputImage->GetRequestedRegion());
	MinMaxCalculator->Compute();
	return MinMaxCalculator->GetMaximum();
}

template <class TImage> typename MSRGImageHelper<TImage>::PixelType MSRGImageHelper<TImage>::GetImageMin(const ImageType* inputImage){
 	typedef itk::MinimumMaximumImageCalculator < ImageType> MinimumMaximumImageCalculatorType;
	typename MinimumMaximumImageCalculatorType::Pointer MinMaxCalculator = MinimumMaximumImageCalculatorType::New ();
	MinMaxCalculator->SetImage(inputImage);
	MinMaxCalculator->Compute();
	return MinMaxCalculator->GetMinimum();
}	

template <class TImage> typename MSRGImageHelper<TImage>::PixelType* MSRGImageHelper<TImage>::ExtractCriteriaVector(const ImageType* inputImage,  IndexType& index, int nbCrit){
	PixelType* mv=new PixelType[nbCrit];
	for(int i=0;i<nbCrit;i++)
	{
		if (nbCrit>1)
			index[Dimension-1]=i;
		mv[i]=inputImage->GetPixel(index);
	}
	
	return mv;
}
template < class TImage> int MSRGImageHelper<TImage>::computeFreePointIn2DNeighborhood(const ImageType* inputImage,IndexType index, int connectivity){
	int cpt=0;
	// connectivity: 0 for knight, 4 for 4-conn, 8 for 8-conn
	switch(connectivity){
		case 4:
		{
			typedef typename itk::ConstShapedNeighborhoodIterator<ImageType> ShapedNeighborhoodIteratorTypeN4;
			typename ShapedNeighborhoodIteratorTypeN4::RadiusType radiusN4;
		  	radiusN4.Fill(1);
		  	ShapedNeighborhoodIteratorTypeN4 itN4(radiusN4, inputImage, inputImage->GetRequestedRegion ());
		  	typename ShapedNeighborhoodIteratorTypeN4::OffsetType off;
		        off[0] = -1; off[1] = 0; itN4.ActivateOffset(off);
		        off[0] = 0; off[1] = 1; itN4.ActivateOffset(off);
		        off[0] = 1; off[1] = 0; itN4.ActivateOffset(off);
		        off[0] = 0; off[1] = -1; itN4.ActivateOffset(off);
			typename ShapedNeighborhoodIteratorTypeN4::ConstIterator ciN4;
			itN4.SetLocation (index);
			for (ciN4 = itN4.Begin(); ciN4 != itN4.End(); ciN4++)
			 {
			 	if (ciN4.Get()==0)
			 	cpt++;
			 }
			 return cpt;
			 break;
		}
		case 8:
		{
			typedef typename itk::ConstShapedNeighborhoodIterator<ImageType> ShapedNeighborhoodIteratorTypeN8;
			typename ShapedNeighborhoodIteratorTypeN8::RadiusType radiusN8;
		  	radiusN8.Fill(1);
		  	ShapedNeighborhoodIteratorTypeN8 itN8(radiusN8, inputImage, inputImage->GetRequestedRegion ());
		  	typename ShapedNeighborhoodIteratorTypeN8::OffsetType offN8;
		        offN8[0] = -1; offN8[1] = 1; itN8.ActivateOffset(offN8);
		        offN8[0] = 1; offN8[1] = 1; itN8.ActivateOffset(offN8);
		        offN8[0] = -1; offN8[1] = -1; itN8.ActivateOffset(offN8);
		        offN8[0] = 1; offN8[1] = -1; itN8.ActivateOffset(offN8);
			typename ShapedNeighborhoodIteratorTypeN8::ConstIterator ciN8;
			itN8.SetLocation (index);
			for (ciN8 = itN8.Begin(); ciN8 != itN8.End(); ciN8++)
			 {
			 	if (ciN8.Get()==0)
			 	cpt++;
			 	
			 }
			 return cpt;
			break;
		}
		case 0:
		{
			typedef typename itk::ConstShapedNeighborhoodIterator<ImageType> ShapedNeighborhoodIteratorTypeNk;
			typename ShapedNeighborhoodIteratorTypeNk::RadiusType radiusNk;
		  	radiusNk.Fill(2);
		  	ShapedNeighborhoodIteratorTypeNk itNk(radiusNk, inputImage, inputImage->GetRequestedRegion ());
		  	typename ShapedNeighborhoodIteratorTypeNk::OffsetType offNk;
		  		// direction (-1,-1)
		  	offNk[0] = -2; offNk[1] = -1; itNk.ActivateOffset(offNk);
		        offNk[0] = -1; offNk[1] = -2; itNk.ActivateOffset(offNk);
		        	// direction (1,-1)
		        offNk[0] = 2; offNk[1] = -1; itNk.ActivateOffset(offNk);
		        offNk[0] = 1; offNk[1] = -2; itNk.ActivateOffset(offNk);
		        	// direction (1,1)
		        offNk[0] = 2; offNk[1] = 1; itNk.ActivateOffset(offNk);
		        offNk[0] = 1; offNk[1] = 2; itNk.ActivateOffset(offNk);
		        	// direction (-1,1)
		        offNk[0] = -2; offNk[1] = 1; itNk.ActivateOffset(offNk);
		        offNk[0] = -1; offNk[1] = 2; itNk.ActivateOffset(offNk);
		        
			typename ShapedNeighborhoodIteratorTypeNk::ConstIterator ciNk;
			itNk.SetLocation (index);
			for (ciNk = itNk.Begin(); ciNk != itNk.End(); ciNk++)
			 {
			 	if (ciNk.Get()==0)
			 	cpt++;
			 }
			 return cpt;
			break;
		}
		default:
		{
			return 0;
		}
	}
}
template < class TImage> int MSRGImageHelper<TImage>::computeFreePointIn3DNeighborhood(const ImageType* inputImage,IndexType index, int connectivity){
	int cpt=0;
	// connectivity: 0 for knight, 4 for 4-conn, 8 for 8-conn
	switch(connectivity){
		case 4: // 6 points
		{
			typedef typename itk::ConstShapedNeighborhoodIterator<ImageType> ShapedNeighborhoodIteratorTypeN4;
			typename ShapedNeighborhoodIteratorTypeN4::RadiusType radiusN4;
		  	radiusN4.Fill(1);
		  	ShapedNeighborhoodIteratorTypeN4 itN4(radiusN4, inputImage, inputImage->GetRequestedRegion ());
		  	typename ShapedNeighborhoodIteratorTypeN4::OffsetType off;
		  	// 2D slice
		        off[0] = -1; off[1] = 0; off[2] = 0;itN4.ActivateOffset(off);
		        off[0] = 0; off[1] = 1; off[2] = 0;itN4.ActivateOffset(off);
		        off[0] = 1; off[1] = 0; off[2] = 0;itN4.ActivateOffset(off);
		        off[0] = 0; off[1] = -1; off[2] = 0;itN4.ActivateOffset(off);
		        // extension to 3D
		        off[0] = 0; off[1] = 0; off[2] = 1;itN4.ActivateOffset(off);
		        off[0] = 0; off[1] = 0; off[2] = -1;itN4.ActivateOffset(off);
			typename ShapedNeighborhoodIteratorTypeN4::ConstIterator ciN4;
			itN4.SetLocation (index);
			for (ciN4 = itN4.Begin(); ciN4 != itN4.End(); ciN4++)
			 {
			 	if (ciN4.Get()==0)
			 	cpt++;
			 }
			 return cpt;
			 break;
		}
		case 8: // 6 points from N4, and 8 points from N
		{
			typedef typename itk::ConstShapedNeighborhoodIterator<ImageType> ShapedNeighborhoodIteratorTypeN8;
			typename ShapedNeighborhoodIteratorTypeN8::RadiusType radiusN8;
		  	radiusN8.Fill(1);
		  	ShapedNeighborhoodIteratorTypeN8 itN8(radiusN8, inputImage, inputImage->GetRequestedRegion ());
		  	typename ShapedNeighborhoodIteratorTypeN8::OffsetType offN8;
		  	// 2D slice
		        offN8[0] = -1; offN8[1] = 1; offN8[2] = 0;itN8.ActivateOffset(offN8);
		        offN8[0] = 1; offN8[1] = 1; offN8[2] = 0;itN8.ActivateOffset(offN8);
		        offN8[0] = -1; offN8[1] = -1; offN8[2] = 0;itN8.ActivateOffset(offN8);
		        offN8[0] = 1; offN8[1] = -1; offN8[2] = 0;itN8.ActivateOffset(offN8);
		        // extension to 3D
		        	// face avant
		        offN8[0] = 0; offN8[1] = -1; offN8[2] = -1;itN8.ActivateOffset(offN8);
		        offN8[0] = 0; offN8[1] = 1; offN8[2] = -1;itN8.ActivateOffset(offN8);
		        	// face arr
		        offN8[0] = 0; offN8[1] = -1; offN8[2] = 1;itN8.ActivateOffset(offN8);
		        offN8[0] = 0; offN8[1] = 1; offN8[2] = 1;itN8.ActivateOffset(offN8);
			typename ShapedNeighborhoodIteratorTypeN8::ConstIterator ciN8;
			itN8.SetLocation (index);
			for (ciN8 = itN8.Begin(); ciN8 != itN8.End(); ciN8++)
			 {
			 	if (ciN8.Get()==0)
			 	cpt++;
			 	
			 }
			
			 return cpt;
			break;
		}
		case 0:
		{
		typedef itk::ConstShapedNeighborhoodIterator<ImageType> ShapedNeighborhoodIteratorTypeNk;
			typename ShapedNeighborhoodIteratorTypeNk::RadiusType radiusNk;
		  	radiusNk.Fill(2);
		  	ShapedNeighborhoodIteratorTypeNk itNk(radiusNk, inputImage, inputImage->GetRequestedRegion ());
		  	typename ShapedNeighborhoodIteratorTypeNk::OffsetType offNk;
		      	// 2D slice
		     		// direction (-1,-1,0)
		  	offNk[0] = -2; offNk[1] = -1; offNk[2] =0; itNk.ActivateOffset(offNk);
		        offNk[0] = -1; offNk[1] = -2; offNk[2] =0; itNk.ActivateOffset(offNk);
		        	// direction (1,-1,0)
		        offNk[0] = 2; offNk[1] = -1; offNk[2] =0; itNk.ActivateOffset(offNk);
		        offNk[0] = 1; offNk[1] = -2; offNk[2] =0; itNk.ActivateOffset(offNk);
		        	// direction (1,-1,0)
		        offNk[0] = 2; offNk[1] = -1; offNk[2] =0; itNk.ActivateOffset(offNk);
		        offNk[0] = 1; offNk[1] = 2; offNk[2] =0; itNk.ActivateOffset(offNk);
		        	// direction (-1,1,0)
		        offNk[0] = -2; offNk[1] = 1; offNk[2] =0; itNk.ActivateOffset(offNk);
		        offNk[0] = -1; offNk[1] = 2; offNk[2] =0; itNk.ActivateOffset(offNk);
		        
		        // extension to 3D
		        	// face avant
		        	   // direction (0,-1,-1)
		        offNk[0] = 0; offNk[1] = -1; offNk[2] = -2;itNk.ActivateOffset(offNk);
		        offNk[0] = 0; offNk[1] = -2; offNk[2] = -1;itNk.ActivateOffset(offNk);
		        	   // direction (0,1,-1)			        	   
		        offNk[0] = 0; offNk[1] = 2; offNk[2] = -1;itNk.ActivateOffset(offNk);
		        offNk[0] = 0; offNk[1] = 1; offNk[2] = -2;itNk.ActivateOffset(offNk);
		        
		        	// face arr
		        		// direction (0,-1,1)
		        offNk[0] = 0; offNk[1] = -1; offNk[2] = 2;itNk.ActivateOffset(offNk);
		        offNk[0] = 0; offNk[1] = -2; offNk[2] = 1;itNk.ActivateOffset(offNk);
		        		// direction (0,1,1)
		        offNk[0] = 0; offNk[1] = 1; offNk[2] = 2;itNk.ActivateOffset(offNk);
		        offNk[0] = 0; offNk[1] = 2; offNk[2] = 1;itNk.ActivateOffset(offNk);
			typename ShapedNeighborhoodIteratorTypeNk::ConstIterator ciNk;
			itNk.SetLocation (index);
			for (ciNk = itNk.Begin(); ciNk != itNk.End(); ciNk++)
			 {
			 	if (ciNk.Get()==0)
			 	cpt++;
			 }
			 return cpt;
			break;
		}
		default:
		{
			return 0;
		}
	}	
}
#endif
