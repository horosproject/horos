/*=========================================================================
 *
 *  Copyright Insight Software Consortium
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0.txt
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *=========================================================================*/
#ifndef __itkShapeDetectionLevelSetFunction_h
#define __itkShapeDetectionLevelSetFunction_h

#include "itkSegmentationLevelSetFunction.h"

namespace itk
{
/** \class ShapeDetectionLevelSetFunction
 *
 * \brief This function is used in the ShapeDetectionLevelSetImageFilter to
 * segment structures in an image based on a user supplied edge potential map.
 *
 * \par IMPORTANT
 * The LevelSetFunction class contain additional information necessary
 * to gain full understanding of how to use this function.
 *
 * ShapeDetectionLevelSetFunction is a subclass of the generic LevelSetFunction.
 * It is used to segment structures in an image based on a user supplied
 * edge potential map \f$ g(I) \f$, which
 * has values close to zero in regions near edges (or high image gradient) and values
 * close to one in regions with relatively constant intensity. Typically, the edge
 * potential map is a function of the image gradient, for example:
 *
 * \f[ g(I) = 1 / ( 1 + | (\nabla * G)(I)| ) \f]
 * \f[ g(I) = \exp^{-|(\nabla * G)(I)|} \f]
 *
 * where \f$ I \f$ is image intensity and
 * \f$ (\nabla * G) \f$ is the derivative of Gaussian operator.
 *
 * The edge potential image is set via the SetFeatureImage() method.
 *
 * In this function both the propagation term \f$ P(\mathbf{x}) \f$
 * and the curvature spatial modifier term \f$ Z(\mathbf{x}) \f$ are taken directly
 * from the edge potential image such that:
 *
 * \f[ P(\mathbf{x}) = g(\mathbf{x}) \f]
 * \f[ Z(\mathbf{x}) = g(\mathbf{x}) \f]
 *
 * Note that there is no advection term in this function.
 *
 * This implementation is based on:
 * "Shape Modeling with Front Propagation: A Level Set Approach",
 * R. Malladi, J. A. Sethian and B. C. Vermuri.
 * IEEE Trans. on Pattern Analysis and Machine Intelligence,
 * Vol 17, No. 2, pp 158-174, February 1995
 *
 * \sa LevelSetFunction
 * \sa SegmentationLevelSetImageFunction
 * \sa ShapeDetectionLevelSetImageFilter
 *
 * \ingroup FiniteDifferenceFunctions
 * \ingroup ITKLevelSets
 */
template< typename TImageType, typename TFeatureImageType = TImageType >
class ShapeDetectionLevelSetFunction:
  public SegmentationLevelSetFunction< TImageType, TFeatureImageType >
{
public:
  /** Standard class typedefs. */
  typedef ShapeDetectionLevelSetFunction                                Self;
  typedef SegmentationLevelSetFunction< TImageType, TFeatureImageType > Superclass;
  typedef SmartPointer< Self >                                          Pointer;
  typedef SmartPointer< const Self >                                    ConstPointer;
  typedef TFeatureImageType                                             FeatureImageType;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods) */
  itkTypeMacro(ShapeDetectionLevelSetFunction, SegmentationLevelSetFunction);

  /** Extract some parameters from the superclass. */
  typedef typename Superclass::ImageType         ImageType;
  typedef typename Superclass::NeighborhoodType  NeighborhoodType;
  typedef typename Superclass::ScalarValueType   ScalarValueType;
  typedef typename Superclass::FeatureScalarType FeatureScalarType;
  typedef typename Superclass::RadiusType        RadiusType;
  typedef typename Superclass::FloatOffsetType   FloatOffsetType;
  typedef typename Superclass::GlobalDataStruct  GlobalDataStruct;

  /** Extract some parameters from the superclass. */
  itkStaticConstMacro(ImageDimension, unsigned int,
                      Superclass::ImageDimension);

  virtual void CalculateSpeedImage();

  /** The curvature speed is same as the propagation speed. */
  virtual ScalarValueType CurvatureSpeed(const NeighborhoodType & neighborhood,
                                         const FloatOffsetType & offset, GlobalDataStruct *gd) const
  { return this->PropagationSpeed(neighborhood, offset, gd); }

  virtual void Initialize(const RadiusType & r)
  {
    Superclass::Initialize(r);

    this->SetAdvectionWeight(NumericTraits< ScalarValueType >::Zero);
    this->SetPropagationWeight(NumericTraits< ScalarValueType >::One);
    this->SetCurvatureWeight(NumericTraits< ScalarValueType >::One);
  }

protected:
  ShapeDetectionLevelSetFunction()
  {
    this->SetAdvectionWeight(NumericTraits< ScalarValueType >::Zero);
    this->SetPropagationWeight(NumericTraits< ScalarValueType >::One);
    this->SetCurvatureWeight(NumericTraits< ScalarValueType >::One);
  }

  virtual ~ShapeDetectionLevelSetFunction() {}

  ShapeDetectionLevelSetFunction(const Self &); //purposely not implemented
  void operator=(const Self &);                 //purposely not implemented
};
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkShapeDetectionLevelSetFunction.hxx"
#endif

#endif
