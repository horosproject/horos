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
#ifndef __itkScaleLogarithmicTransform_h
#define __itkScaleLogarithmicTransform_h

#include "itkScaleTransform.h"

namespace itk
{
/** \class ScaleLogarithmicTransform
 * \brief Logarithmic Scale transformation of a vector space (e.g. space coordinates)
 *
 * The only difference between this class and its superclass the ScaleTransform
 * is that here the parameters of the transformation are the logarithms of the
 * scales. This facilitates to linearize the expressions used for optimization.
 *
 * \ingroup ITKTransform
 */
template <
  typename TScalar = float, // Type for cordinate representation type (float or
                             // double)
  unsigned int NDimensions = 3>
// Number of dimensions
class ScaleLogarithmicTransform :
  public ScaleTransform< TScalar,
                         NDimensions >
{
public:
  /** Standard class typedefs.   */
  typedef ScaleLogarithmicTransform              Self;
  typedef ScaleTransform< TScalar, NDimensions > Superclass;
  typedef SmartPointer< Self >                   Pointer;
  typedef SmartPointer< const Self >             ConstPointer;

  /** New macro for creation of through a smart pointer. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(ScaleLogarithmicTransform, ScaleTransform);

  /** Dimension of the domain space. */
  itkStaticConstMacro(SpaceDimension, unsigned int, NDimensions);
  itkStaticConstMacro(ParametersDimension, unsigned int, NDimensions);

  /** Scalar type. */
  typedef typename Superclass::ScalarType ScalarType;

  /** Parameters type. */
  typedef typename Superclass::ParametersType ParametersType;
  typedef typename ParametersType::ValueType  ParametersValueType;

  /** Jacobian type. */
  typedef typename Superclass::JacobianType JacobianType;

  /** Standard vector type for this class. */
  typedef typename Superclass::ScaleType ScaleType;
  typedef typename ScaleType::ValueType  ScalesValueType;

  /** Standard vector type for this class. */
  typedef typename Superclass::InputVectorType  InputVectorType;
  typedef typename Superclass::OutputVectorType OutputVectorType;

  /** Standard covariant vector type for this class. */
  typedef typename Superclass::InputCovariantVectorType  InputCovariantVectorType;
  typedef typename Superclass::OutputCovariantVectorType OutputCovariantVectorType;

  /** Standard vnl_vector type for this class. */
  typedef typename Superclass::InputVnlVectorType  InputVnlVectorType;
  typedef typename Superclass::OutputVnlVectorType OutputVnlVectorType;

  /** Standard coordinate point type for this class. */
  typedef typename Superclass::InputPointType  InputPointType;
  typedef typename Superclass::OutputPointType OutputPointType;

  /** Set parameters.
   * This method sets the parameters for the transform
   * value specified by the user. */
  void SetParameters(const ParametersType & parameters);

  /** Get the parameters that uniquely define the transform
   * This is typically used by optimizers.
   * There are 4 parameters. The first one represents the
   * rotation, the second one the scale and the last
   * two represent the offset. */
  const ParametersType & GetParameters(void) const;

  /** Compute the Jacobian Matrix of the transformation at one point,
   *  allowing for thread-safety. */
  virtual void ComputeJacobianWithRespectToParameters( const InputPointType  & p, JacobianType & jacobian) const;

protected:
  /** Construct an ScaleLogarithmicTransform object. */
  ScaleLogarithmicTransform();

  /** Destroy an ScaleLogarithmicTransform object. */
  ~ScaleLogarithmicTransform();

  /** Print contents of an ScaleLogarithmicTransform */
  void PrintSelf(std::ostream & os, Indent indent) const;

private:
  ScaleLogarithmicTransform(const Self & other); // purposely not implemented
  const Self & operator=(const Self &);          // purposely not implemented

};                                               // class
                                                 // ScaleLogarithmicTransform
}  // namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkScaleLogarithmicTransform.hxx"
#endif

#endif /* __itkScaleLogarithmicTransform_h */
