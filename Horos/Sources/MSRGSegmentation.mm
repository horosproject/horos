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



#define id Id
#include "itkImage.h"
#include "MSRGImageHelper.h"
#include "MorphoHelper.h"
#include "itkMSRGFilter.h"
#undef id

#import "ViewerController.h"
#import "WaitRendering.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"

#import "MSRGSegmentation.h"

#define runMSRGWithNumberOfCriteria(numberOfCrit) 	NSLog(@"start 3D MSRG with %d criterion ....",numberOfCrit);\
typedef itk::MSRGFilter < OsiriXImageType, MarkerImageType, OsiriXImageType, numberOfCrit > MSRGFilterTypeOneCrit;	\
MSRGFilterTypeOneCrit::Pointer msrgOneCrit = MSRGFilterTypeOneCrit::New ();\
msrgOneCrit->SetInput (internalImage);\
msrgOneCrit->SetMarker(m_Marker);\
msrgOneCrit->SetCriteria(CriteriaImage);\
msrgOneCrit->Update();

@implementation MSRGSegmentation
-(void) dealloc
{
	[criteriaViewerList release];
	[super dealloc];
}

- (id) initWithViewerList:(NSMutableArray*)list currentViewer:(ViewerController*)srcViewer boundingBoxOn:(BOOL)boundOn GrowIn3D:(BOOL)growing3D boundingRect:(NSRect)rectBounding boundingBeginZ:(int)bZstart boundingEndZ:(int)bEndZ
{
	if (self = [super init])
	{
		isBounding=boundOn;
		boundingRegion=rectBounding;
		isGrow3D=growing3D;
		boundingZstart=bZstart;
		boundingZEnd=bEndZ;
		criteriaViewerList=[list retain];
		markerViewer=srcViewer;
		numberOfCriteria=[criteriaViewerList count];
		NSLog(@"Number of criteria =%d",numberOfCriteria);
		width=0;height=0;depth=0;
		//itkImage = [[ITK alloc] initWith: pix :volumeData :slice];
    }
    return self;
}
-(BOOL) build2DMarkerBuffer
{
int i,j,k,l;
	ROI* roi;
	unsigned char* texture;
	NSMutableDictionary *roiGlossary=[NSMutableDictionary dictionary];
	int textureHeight, textureWidth;
	int offset;
	int val,cpt=0;
	NSMutableArray* roiListForImage;
	sizeMarker[0] = width;
	sizeMarker[1] = height;
	
	// number / [[roi name] hash]
	markerBuffer=(unsigned char*)malloc(height*width*sizeof(unsigned char));
	if (markerBuffer)
	{
		// clear markerBuffer
		for(i=0;i<width*height;i++)
			markerBuffer[(long)i]=0;
			i=0;
			roiListForImage=[[markerViewer roiList] objectAtIndex: [[markerViewer imageView] curImage]];
			for (j=0;j<[roiListForImage count];j++)
			{
				roi=[roiListForImage objectAtIndex:j];
				if ([roi type]==tPlain)
				{
					texture=[roi textureBuffer];
					textureWidth=[roi textureWidth];
					textureHeight=[roi textureHeight];
					offset=[roi textureUpLeftCornerX]+[roi textureUpLeftCornerY]*width;
					//NSLog(@"textureWidth=%d, textureHeight=%d, textureUpLeftCornerX=%d, textureUpLeftCornerY=%d,textureDownRightCornerX=%d, textureDownRightCornerY=%d",[roi textureWidth],[roi textureHeight],[roi textureUpLeftCornerX],[roi textureUpLeftCornerY],[roi textureDownRightCornerX],[roi textureDownRightCornerY]);
					for (k=0;k<textureHeight; k++)
					{
						for (l=0;l<textureWidth; l++)
						{
							//NSNumber* p=[NSNumber numberWithUnsignedChar:texture[(long)(l+k*textureWidth)]];
							if (texture[(long)(l+k*textureWidth)]!=0)
							{
								NSString *key=[NSString stringWithFormat:@"%d",[[roi name] hash]];
								if (![roiGlossary objectForKey:key])
								{
									cpt++;
									[roiGlossary setObject:[[NSNumber numberWithInt:cpt] stringValue] forKey:key];
								}
								val=[[roiGlossary objectForKey:key] intValue];
								markerBuffer[(long)(offset+l+k*width)]=val;
							}/* no else because if rois are overlaped the else condition will erase them !
							else
								val=0;*/
							
						}
					}
				}
			}
		
		return YES;
	}
	
	NSLog(@"Memory problem in: MSRGSegmentation/buildMarkerWithStackHeigt !");
	NSRunAlertPanel( NSLocalizedString( @"Memory Error", nil), NSLocalizedString( @"Sorry, but there is not enough memory", 0), nil, nil, nil);
	return NO;
}
-(BOOL) buildMarkerBufferWithStackHeigth
{
	int i,j,k,l;
	ROI* roi;
	unsigned char* texture;
	NSMutableDictionary *roiGlossary=[NSMutableDictionary dictionary];
	int textureHeight, textureWidth;
	int offset;
	int val,cpt=0;
	NSMutableArray* roiListForImage;
	sizeMarker[0] = width;
	sizeMarker[1] = height;
	sizeMarker[2] = depth;	
	
	// number / [[roi name] hash]
	markerBuffer=(unsigned char*)malloc(height*width*depth*sizeof(unsigned char));
	if (markerBuffer)
	{
		// clear markerBuffer
		for(i=0;i<width*height*depth;i++)
			markerBuffer[(long)i]=0;
		for(i=0;i<depth;i++)
		{
			roiListForImage=[[markerViewer roiList] objectAtIndex:i];
			for (j=0;j<[roiListForImage count];j++)
			{
				roi=[roiListForImage objectAtIndex:j];
				if ([roi type]==tPlain)
				{
					texture=[roi textureBuffer];
					textureWidth=[roi textureWidth];
					textureHeight=[roi textureHeight];
					offset=[roi textureUpLeftCornerX]+[roi textureUpLeftCornerY]*width;
					//NSLog(@"textureWidth=%d, textureHeight=%d, textureUpLeftCornerX=%d, textureUpLeftCornerY=%d,textureDownRightCornerX=%d, textureDownRightCornerY=%d",[roi textureWidth],[roi textureHeight],[roi textureUpLeftCornerX],[roi textureUpLeftCornerY],[roi textureDownRightCornerX],[roi textureDownRightCornerY]);
					for (k=0;k<textureHeight; k++)
					{
						for (l=0;l<textureWidth; l++)
						{
							//NSNumber* p=[NSNumber numberWithUnsignedChar:texture[(long)(l+k*textureWidth)]];
							if (texture[(long)(l+k*textureWidth)]!=0)
							{
								NSString *key=[NSString stringWithFormat:@"%d",[[roi name] hash]];
								if (![roiGlossary objectForKey:key])
								{
									cpt++;
									[roiGlossary setObject:[[NSNumber numberWithInt:cpt] stringValue] forKey:key];
								}
								val=[[roiGlossary objectForKey:key] intValue];
								markerBuffer[(long)(offset+l+k*width+i*(width*height))]=val;
							}/* no else because if rois are overlaped the else condition will erase them !
							else
								val=0;*/
							
						}
					}
				}
			}
		}
		return YES;
	}
	
	NSLog(@"Memory problem in: MSRGSegmentation/buildMarkerWithStackHeigt !");
	NSRunAlertPanel( NSLocalizedString( @"Memory Error", nil), NSLocalizedString( @"Sorry, but there is not enough memory", 0), nil, nil, nil);
	return NO;
}

-(BOOL) buildCriteriaBufferFor2DColorImageWithStackHeigt
{
	/*
	 int i,j,numberOfCriteria=3;
	 long stackSize=height*width*3;
	 ViewerController* v;
	 //numberOfCriteria=[criteriaViewerList count];
	 sizeCriteria[0] = width;
	 sizeCriteria[1] = height;
	 sizeCriteria[2] = 3;	
	 
	 DCMPix	*curPix = [[markerViewer pixList] objectAtIndex: [[markerViewer imageView] curImage]];
	 unsigned char*  srcPtr = (unsigned char*) [curPix fImage];
	 
	 long layerSize=height*width;
	 criteriaBufferChar=(unsigned char*)malloc(width*height*3);
	 if (criteriaBufferChar)
	 {
		 
		 for(j=0;j<height;j++)
			 for (i=0;i<width;i++)
				 criteriaBufferChar[(long)(width*j+i)]=srcPtr[(j*width+i)*4+0]; // RED
		 
		 for(j=0;j<height;j++)
			 for (i=0;i<width;i++)
				 criteriaBufferChar[(long)(width*j+i+layerSize)]=srcPtr[(j*width+i)*4+1]; // GREEN 
		 
		 for(j=0;j<height;j++)
			 for (i=0;i<width;i++)
				 criteriaBufferChar[(long)(width*j+i+layerSize*2)]=srcPtr[(j*width+i)*4+2]; // BLUE
		 
		 return YES;
		 
	 }
	 
	 NSLog(@"Memory problem in : MSRGSegmentation/buildCriteriaBufferFor2DColorImageWithStackHeigt !");
	 NSRunAlertPanel( NSLocalizedString( @"Memory Error", nil), NSLocalizedString( @"Sorry, but there is not enough memory", 0), nil, nil, nil);
	 */
	return NO;
	
}
-(BOOL) buildCriteriaBufferWithStackHeigth:(long)height stackWidth:(long)width stackDepth:(long)depth
{
	/*
	 int i,j,numberOfCriteria=0;
	 long stackSize=height*width*depth;
	 ViewerController* v;
	 numberOfCriteria=[criteriaViewerList count];
	 sizeCriteria[0] = width;
	 sizeCriteria[1] = height;
	 if (numberOfCriteria>0)
	 sizeCriteria[2]=numberOfCriteria+1;
	 else
	 sizeCriteria[2]=1; // just the original image 
	 if (numberOfCriteria>4)
	 {
		 NSLog(@"ERROR in MSRGSegmentation/buildCriteriaBufferWithStackHeigt, no more than 4 criteria !!!");
		 return NO;
	 }
	 criteriaBuffer=(float*)malloc(width*height*depth*sizeCriteria[2]*sizeof(float));
	 
	 if (criteriaBuffer)
	 {
		 // first criterion -> current Image volumePtr	
		 memcpy(criteriaBuffer,[markerViewer volumePtr],stackSize*sizeof(float)); 
		 if (numberOfCriteria>0)
		 {
			 for(i=0;i<numberOfCriteria;i++)
			 {
				 v=[criteriaViewerList objectAtIndex:i];		
				 memcpy((criteriaBuffer+stackSize*i),[v volumePtr],stackSize*sizeof(float)); 
			 }
		 }
		 return YES;
	 }
	 
	 NSLog(@"Memory problem in : MSRGSegmentation/buildCriteriaBufferWithStackHeigt !");
	 NSRunAlertPanel( NSLocalizedString( @"Memory Error", nil), NSLocalizedString( @"Sorry, but there is not enough memory", 0), nil, nil, nil);
	 
	 */
	return NO;
}

- (id) start3DMSRGSegmentationWithOneCriterion {
	NSLog(@"-*- start3DMSRGSegmentation -*-");
	// One criterion
	
	typedef itk::Vector< float, 1 >   CriteriaPixelType;
	typedef itk::Image < CriteriaPixelType, 3 > CriteriaImageType;
	typedef CriteriaImageType::IndexType CriteriaIndexType;
	CriteriaImageType::Pointer criteriaImage = CriteriaImageType::New();
	CriteriaImageType::RegionType critRegion;
	CriteriaImageType::SizeType  critSize;
	
	typedef itk::Image < unsigned char, 3 > MarkerImageType;
	typedef MarkerImageType::Pointer MarkerImagePointer;
	typedef MarkerImageType::SizeType MarkerSizeType;
	typedef MarkerImageType::RegionType MarkerRegionType;
	typedef MarkerImageType::IndexType MarkerIndexType;
	MarkerSizeType size,sizeRequested;
	MarkerRegionType markerRegion;
	MarkerIndexType startRequested;
	
	size[0]=width;size[1]=height;size[2]=depth;
	
	// II -  find tPlain ROI => fill the markerBuffer with the texture 
	if ([self buildMarkerBufferWithStackHeigth])
	{
		MarkerImagePointer m_Marker = MSRGImageHelper < MarkerImageType >::BuildImageWithArray (markerBuffer, sizeMarker);
		// create the criteria image
		critSize=size;
		critRegion.SetSize( critSize );
		criteriaImage->SetRegions( critRegion );
		criteriaImage->Allocate();
		
		//recopy current stack as a vectorial image
		long i,j,k;
		CriteriaIndexType index;
		CriteriaPixelType v;
		float* imagePtr=[markerViewer volumePtr];
		for (k=0;k<depth;k++)
		{
			for(j=0;j<height;j++)
			{
				for(i=0;i<width;i++)
				{
					index[0]=i;index[1]=j;index[2]=k;
					v[0]=imagePtr[i+j*width+k*(width*height)];
					criteriaImage->SetPixel(index,v);
				}
			}
		}
		
		// create the msrg filter
		typedef itk::MSRGFilter<CriteriaImageType> MsrgFilterType;
		MsrgFilterType::Pointer msrg=MsrgFilterType::New();
		msrg->SetInput(criteriaImage);
		// Add bounding box
		if (isBounding)
		{
			//size
			sizeRequested[0]=(int)boundingRegion.size.width;
			sizeRequested[1]=(int)boundingRegion.size.height;
			sizeRequested[2]=boundingZEnd-boundingZstart;
			
			//start
			startRequested[0]=(int)boundingRegion.origin.x;
			startRequested[1]=(int)boundingRegion.origin.y;
			startRequested[2]=boundingZstart;
			
			
			markerRegion.SetSize(sizeRequested);
			markerRegion.SetIndex(startRequested);
			m_Marker->SetRequestedRegion(markerRegion);
			// you have to relabel the image because it is possible to have others tPlain region outside the bounding box;
			msrg->LabelMarkerImage(true);
		}

		msrg->SetMarker(m_Marker);
		msrg->Update();
		
		// create ROIs from msrg output
		[markerViewer addRoiFromFullStackBuffer:msrg->GetOutput()->GetBufferPointer()];
		free(markerBuffer);
	}
	return nil;
}

- (id) start2DMSRGSegmentationWithOneCriterion {
	NSLog(@"start start2DMSRGSegmentationWithOneCriterion ...");
	typedef itk::Vector< float, 1 >   CriteriaPixelType;
	typedef itk::Image < CriteriaPixelType, 2 > CriteriaImageType;
	typedef CriteriaImageType::IndexType CriteriaIndexType;
	CriteriaImageType::Pointer criteriaImage = CriteriaImageType::New();
	CriteriaImageType::RegionType critRegion;
	CriteriaImageType::SizeType  critSize;
	
	// Marker Image
	typedef itk::Image < unsigned char, 2 > MarkerImageType;
	typedef MarkerImageType::Pointer MarkerImagePointer;
	typedef MarkerImageType::SizeType MarkerSizeType;
	typedef MarkerImageType::RegionType MarkerRegionType;
	typedef MarkerImageType::IndexType MarkerIndexType;
	MarkerSizeType size,sizeRequested;
	MarkerRegionType markerRegion;
	MarkerIndexType startRequested;
	
	size[0]=width;size[1]=height;
	
	// II -  find tPlain ROI => fill the markerBuffer with the texture 
	if ([self build2DMarkerBuffer])
	{
		MarkerImagePointer m_Marker = MSRGImageHelper < MarkerImageType >::BuildImageWithArray (markerBuffer, sizeMarker);
		// create the criteria image
		critSize=size;
		critRegion.SetSize( critSize );
		criteriaImage->SetRegions( critRegion );
		criteriaImage->Allocate();
		
		//recopy current stack as a vectorial image
		long i,j;
		CriteriaIndexType index;
		CriteriaPixelType v;
		float* imagePtr=[markerViewer volumePtr];
		
		for(j=0;j<height;j++)
		{
			for(i=0;i<width;i++)
			{
				index[0]=i;index[1]=j;
				v[0]=imagePtr[i+j*width];
				criteriaImage->SetPixel(index,v);
			}
		}
		
		
		// create the msrg filter
		typedef itk::MSRGFilter<CriteriaImageType> MsrgFilterType;
		MsrgFilterType::Pointer msrg=MsrgFilterType::New();
		msrg->SetInput(criteriaImage);
		
		// Add bounding box
		if (isBounding)
		{
			//size
			sizeRequested[0]=(int)boundingRegion.size.width;
			sizeRequested[1]=(int)boundingRegion.size.height;
			//start
			startRequested[0]=(int)boundingRegion.origin.x;
			startRequested[1]=(int)boundingRegion.origin.y;
			
			markerRegion.SetSize(sizeRequested);
			markerRegion.SetIndex(startRequested);
			m_Marker->SetRequestedRegion(markerRegion);
			
			// you have to relabel the image because it is possible to have others tPlain region outside the bounding box;
			msrg->LabelMarkerImage(true);
		}

		msrg->SetMarker(m_Marker);
		msrg->Update();
		
		// create ROIs from msrg output
		//TODO change this to addRoiToCurrentSlice !!
		[markerViewer addPlainRoiToCurrentSliceFromBuffer:msrg->GetOutput()->GetBufferPointer()];
		free(markerBuffer);
	}
	return nil;
}
- (id) start2DMSRGSegmentationWithTwoCriteria {
	NSLog(@"start start2DMSRGSegmentationWithTwoCriteria ...");
	typedef itk::Vector< float, 2 >   CriteriaPixelType;
	typedef itk::Image < CriteriaPixelType, 2 > CriteriaImageType;
	typedef CriteriaImageType::IndexType CriteriaIndexType;
	CriteriaImageType::Pointer criteriaImage = CriteriaImageType::New();
	CriteriaImageType::RegionType critRegion;
	CriteriaImageType::SizeType  critSize;
	
	// Marker Image
	typedef itk::Image < unsigned char, 2 > MarkerImageType;
	typedef MarkerImageType::Pointer MarkerImagePointer;
	typedef MarkerImageType::SizeType MarkerSizeType;
	typedef MarkerImageType::RegionType MarkerRegionType;
	typedef MarkerImageType::IndexType MarkerIndexType;
	MarkerSizeType size,sizeRequested;
	MarkerRegionType markerRegion;
	MarkerIndexType startRequested;
	
	size[0]=width;size[1]=height;
	
	// II -  find tPlain ROI => fill the markerBuffer with the texture 
	if ([self build2DMarkerBuffer])
	{
		MarkerImagePointer m_Marker = MSRGImageHelper < MarkerImageType >::BuildImageWithArray (markerBuffer, sizeMarker);
		// create the criteria image
		critSize=size;
		critRegion.SetSize( critSize );
		criteriaImage->SetRegions( critRegion );
		criteriaImage->Allocate();
		
		//recopy current stack as a vectorial image
		long i,j;
		CriteriaIndexType index;
		CriteriaPixelType v;
		
		float* imagePtr=[markerViewer volumePtr];
		float* imageSecondPtr=[[criteriaViewerList objectAtIndex:0] volumePtr];
		for(j=0;j<height;j++)
		{
			for(i=0;i<width;i++)
			{
				index[0]=i;index[1]=j;
				v[0]=imagePtr[i+j*width];
				v[1]=imageSecondPtr[i+j*width];
				criteriaImage->SetPixel(index,v);
			}
		}
		
		
		// create the msrg filter
		typedef itk::MSRGFilter<CriteriaImageType> MsrgFilterType;
		MsrgFilterType::Pointer msrg=MsrgFilterType::New();
		msrg->SetInput(criteriaImage);
		
		// Add bounding box
		if (isBounding)
		{
			//size
			sizeRequested[0]=(int)boundingRegion.size.width;
			sizeRequested[1]=(int)boundingRegion.size.height;
			//start
			startRequested[0]=(int)boundingRegion.origin.x;
			startRequested[1]=(int)boundingRegion.origin.y;
			
			markerRegion.SetSize(sizeRequested);
			markerRegion.SetIndex(startRequested);
			m_Marker->SetRequestedRegion(markerRegion);
			// you have to relabel the image because it is possible to have others tPlain region outside the bounding box;
			msrg->LabelMarkerImage(true);
		}
		
		msrg->SetMarker(m_Marker);
		msrg->Update();
		
		// create ROIs from msrg output
		[markerViewer addPlainRoiToCurrentSliceFromBuffer:msrg->GetOutput()->GetBufferPointer()];
		free(markerBuffer);
	}
	return nil;
}

- (id) start2DColorMSRGSegmentation {
	NSLog(@"start start2DColorMSRGSegmentation ... ");
	
	typedef itk::Vector< float, 3 >   CriteriaPixelType; //RGB
	typedef itk::Image < CriteriaPixelType, 2 > CriteriaImageType;
	typedef CriteriaImageType::IndexType CriteriaIndexType;
	CriteriaImageType::Pointer criteriaImage = CriteriaImageType::New();
	CriteriaImageType::RegionType critRegion;
	CriteriaImageType::SizeType  critSize;
	
	// Marker Image
	typedef itk::Image < unsigned char, 2 > MarkerImageType;
	typedef MarkerImageType::Pointer MarkerImagePointer;
	typedef MarkerImageType::SizeType MarkerSizeType;
	typedef MarkerImageType::RegionType MarkerRegionType;
	typedef MarkerImageType::IndexType MarkerIndexType;
	MarkerSizeType size,sizeRequested;
	MarkerRegionType markerRegion;
	MarkerIndexType startRequested;
	
	size[0]=width;size[1]=height;
	
	// II -  find tPlain ROI => fill the markerBuffer with the texture 
	if ([self build2DMarkerBuffer])
	{
		MarkerImagePointer m_Marker = MSRGImageHelper < MarkerImageType >::BuildImageWithArray (markerBuffer, sizeMarker);
		// create the criteria image
		critSize=size;
		critRegion.SetSize( critSize );
		criteriaImage->SetRegions( critRegion );
		criteriaImage->Allocate();
		
		//recopy current stack as a vectorial image
		long i,j;
		CriteriaIndexType index;
		CriteriaPixelType v;
		//float* imagePtr=[markerViewer volumePtr];
		
		 DCMPix	*curPix = [[markerViewer pixList] objectAtIndex: [[markerViewer imageView] curImage]];
	 unsigned char*  srcPtr = (unsigned char*) [curPix fImage];

		for(j=0;j<height;j++)
		{
			for (i=0;i<width;i++)
			{
				index[0]=i;index[1]=j;
				v[0]=srcPtr[(j*width+i)*4+0]; // RED
				v[1]=srcPtr[(j*width+i)*4+1]; // GREEN 
				v[2]=srcPtr[(j*width+i)*4+2]; // BLUE
				criteriaImage->SetPixel(index,v);
			}
		}
		
		
		// create the msrg filter
		typedef itk::MSRGFilter<CriteriaImageType> MsrgFilterType;
		MsrgFilterType::Pointer msrg=MsrgFilterType::New();
		msrg->SetInput(criteriaImage);
		
		// Add bounding box
		if (isBounding)
		{
			//size
			sizeRequested[0]=(int)boundingRegion.size.width;
			sizeRequested[1]=(int)boundingRegion.size.height;
			//start
			startRequested[0]=(int)boundingRegion.origin.x;
			startRequested[1]=(int)boundingRegion.origin.y;
			
			markerRegion.SetSize(sizeRequested);
			markerRegion.SetIndex(startRequested);
			m_Marker->SetRequestedRegion(markerRegion);
			// you have to relabel the image because it is possible to have others tPlain region outside the bounding box;
			msrg->LabelMarkerImage(true);	
		}
		msrg->SetMarker(m_Marker);
		msrg->Update();
		
		// create ROIs from msrg output
		[markerViewer addRoiFromFullStackBuffer:msrg->GetOutput()->GetBufferPointer()];
		free(markerBuffer);
	}
	return nil;
}

- (id) startMSRGSegmentation
{
	
	DCMPix	*curPix = [[markerViewer pixList] objectAtIndex: [[markerViewer imageView] curImage]];
	height=[curPix pheight];
	width=[curPix pwidth];
	depth=[[markerViewer pixList] count];
	
	
	if (isGrow3D)
	{
		if ((depth>1) && ![curPix isRGB])
			[self start3DMSRGSegmentationWithOneCriterion];
	} else {
		// --- 2D ---	
		if (![curPix isRGB] && numberOfCriteria==0)
			[self start2DMSRGSegmentationWithOneCriterion];
		if (![curPix isRGB] && numberOfCriteria==1)
			[self start2DMSRGSegmentationWithTwoCriteria];
		// 2D RGB image	
		if ((depth==1) && [curPix isRGB])
			[self start2DColorMSRGSegmentation];
	}
	
	return nil;
}
@end
