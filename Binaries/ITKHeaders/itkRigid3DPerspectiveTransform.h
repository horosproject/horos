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
#ifndef __itkRigid3DPerspectiveTransform_h
#define __itkRigid3DPerspectiveTransform_h

#include "itkMacro.h"
#include "vnl/vnl_quaternion.h"
#include <iostream>
#include "itkTransform.h"
#include "itkVersor.h"

namespace itk
{
/** \brief Rigid3DTramsform of a vector space (e.g. space coordinates)
 *
 * This transform applies a rotation and translation to the 3D space
 * followed by a projection to 2D space along the Z axis.
 *
 * \ingroup ITKTransform
 */

template< typename TScalar = double >
// Data type for scalars (float or double)
class Rigid3DPerspectiveTransform :
  public Transform< TScalar, 3, 2 >
{
public:
  /** Dimension of the domain space. */
  itkStaticConstMacro(InputSpaceDimension, unsigned int, 3);
  itkStaticConstMacro(OutputSpaceDimension, unsigned int, 2);

  /** Dimension of parameters. */
  itkStaticConstMacro(SpaceDimension, unsigned int, 3);
  itkStaticConstMacro(ParametersDimension, unsigned int, 6);

  /** Standard class typedefs. */
  typedef Rigid3DPerspectiveTransform Self;
  typedef Transform<TScalar,
                    itkGetStaticConstMacro(InputSpaceDimension),
                    itkGetStaticConstMacro(OutputSpaceDimension)> Superclass;

  typedef SmartPointer<Self>       Pointer;
  typedef SmartPointer<const Self> ConstPointer;

  /** Run-time type information (and related methods). */
  itkTypeMacro(Rigid3DPerspectiveTransform, Transform);

  /** New macro for creation of through a Smart Pointer. */
  itkNewMacro(Self);

  /** Scalar type. */
  typedef typename Superclass::ScalarType ScalarType;

  /** Parameters type. */
  typedef typename Superclass::ParametersType ParametersType;
  typedef typename ParametersType::ValueType  ParameterValueType;

  /** Jacobian type. */
  typedef typename Superclass::JacobianType JacobianType;

  /** Standard matrix type for this class. */
  typedef Matrix<TScalar, itkGetStaticConstMacro(InputSpaceDimension),
                 itkGetStaticConstMacro(InputSpaceDimension)> MatrixType;

  /** Standard vector type for this class. */
  typedef Vector<TScalar, itkGetStaticConstMacro(InputSpaceDimension)> OffsetType;
  typedef typename OffsetType::ValueType                                   OffsetValueType;

  /** Standard vector type for this class. */
  typedef Vector<TScalar, itkGetStaticConstMacro(InputSpaceDimension)>  InputVectorType;
  typedef Vector<TScalar, itkGetStaticConstMacro(OutputSpaceDimension)> OutputVectorType;

  /** Standard covariant vector type for this class */
  typedef typename Superclass::InputCovariantVectorType  InputCovariantVectorType;
  typedef typename Superclass::OutputCovariantVectorType OutputCovariantVectorType;

  /** Standard coordinate point type for this class. */
  typedef Point<TScalar, itkGetStaticConstMacro(InputSpaceDimension)>  InputPointType;
  typedef Point<TScalar, itkGetStaticConstMacro(OutputSpaceDimension)> OutputPointType;

  /** Standard vnl_quaternion type. */
  typedef vnl_quaternion<TScalar> VnlQuaternionType;

  /** Standard vnl_vector type for this class. */
  typedef typename Superclass::InputVnlVectorType  InputVnlVectorType;
  typedef typename Superclass::OutputVnlVectorType OutputVnlVectorType;

  /** Versor type. */
  typedef Versor< TScalar >               VersorType;
  typedef typename VersorType::VectorType AxisType;
  typedef typename VersorType::ValueType  AngleType;
  typedef typename AxisType::ValueType    AxisValueType;

  /** Get offset of an Rigid3DPerspectiveTransform
   * This method returns the value of the offset of the
   * Rigid3DPerspectiveTransform. */
  const OffsetType & GetOffset() const
  {
    return m_Offset;
  }

  /** Get rotation from an Rigid3DPerspectiveTransform.
   * This method returns the value of the rotation of the
   * Rigid3DPerspectiveTransform. */
  const VersorType & GetRotation() const
  {
    return m_Versor;
  }

  /** Set/Get the transformation from a container of parameters.
   * This is typically used by optimizers.
   * There are 6 parameters. The first three represent the
   * versor and the last three represents the offset. */
  void SetParameters(const ParametersType & parameters);

  const ParametersType & GetParameters() const;

  /** Set the fixed parameters and update internal
   * transformation. This transform has no fixed paramaters
   */
  virtual void SetFixedParameters(const ParametersType &)
  {
  }

  /** This method sets the offset of an Rigid3DPerspectiveTransform to a
   * value specified by the user. */
  void SetOffset(const OffsetType & offset)
  {
    m_Offset = offset; return;
  }

  /** This method sets the rotation of an Rigid3DPerspectiveTransform to a
   * value specified by the user.  */
  void SetRotation(const VersorType & rotation);

  /** Set Rotation of the Rigid transform.
   * This method sets the rotation of an Rigid3DTransform to a
   * value specified by the user using the axis of rotation an
   * the angle. */
  void SetRotation(const Vector<TScalar, 3> & axis, double angle);

  /** Set the Focal Distance of the projection
   * This method sets the focal distance for the perspective
   * projection to a value specified by the user. */
  void SetFocalDistance(TScalar focalDistance)
  {
    m_FocalDistance = focalDistance;
  }

  /** Return the Focal Distance */
  double GetFocalDistance(void) const
  {
    return m_FocalDistance;
  }

  /** Transform by a Rigid3DPerspectiveTransform. This method
   *  applies the transform given by self to a
   *  given point, returning the transformed point. */
  OutputPointType  TransformPoint(const InputPointType  & point) const;

  /** These vector transforms are not implemented for this transform */
  using Superclass::TransformVector;

  virtual OutputVectorType TransformVector(const InputVectorType &) const
  {
    itkExceptionMacro(
      << "TransformVector(const InputVectorType &) is not implemented for Rigid3DPerspectiveTransform");
  }

  virtual OutputVnlVectorType TransformVector(const InputVnlVectorType &) const
  {
    itkExceptionMacro(
      << "TransformVector(const InputVnlVectorType &) is not implemented for Rigid3DPerspectiveTransform");
  }

  using Superclass::TransformCovariantVector;

  virtual OutputCovariantVectorType TransformCovariantVector(const InputCovariantVectorType &) const
  {
    itkExceptionMacro(
      <<
      "TransformCovariantVector(const InputCovariantVectorType &) is not implemented for Rigid3DPerspectiveTransform");
  }

  /** Return the rotation matrix */
  const MatrixType & GetRotationMatrix() const
  {
    return m_RotationMatrix;
  }

  /** Compute the matrix. */
  void ComputeMatrix(void);

  /** Compute the Jacobian Matrix of the transformation at one point,
   *  allowing for thread-safety. */
  virtual void ComputeJacobianWithRespectToParameters( const InputPointType  & p, JacobianType & jacobian) const;

  virtual void ComputeJacobianWithRespectToPosition(const InputPointType &,
                                                    JacobianType &) const
  {
    itkExceptionMacro( "ComputeJacobianWithRespectToPosition not yet implemented "
                       "for " << this->GetNameOfClass() );
  }

  /** Set a fixed offset: this allow to center the object to be transformed */
  itkGetConstReferenceMacro(FixedOffset, OffsetType);
  itkSetMacro(FixedOffset, OffsetType);

  /** Set the center of Rotation */
  itkSetMacro(CenterOfRotation, InputPointType);
  itkGetConstReferenceMacro(CenterOfRotation, InputPointType);

protected:
  Rigid3DPerspectiveTransform();
  ~Rigid3DPerspectiveTransform();
  void PrintSelf(std::ostream & os, Indent indent) const;

private:
  Rigid3DPerspectiveTransform(const Self &); // purposely not implemented
  void operator=(const Self &);              // purposely not implemented

  /** Offset of the transformation. */
  OffsetType m_Offset;

  /** Rotation of the transformation. */
  VersorType m_Versor;

  /** Set Focal distance of the projection. */
  TScalar m_FocalDistance;

  /** Matrix representation of the rotation. */
  MatrixType m_RotationMatrix;

  /** Fixed offset */
  OffsetType m_FixedOffset;

  /** Center of rotation */
  InputPointType m_CenterOfRotation;
}; // class Rigid3DPerspectiveTransform:
}  // namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkRigid3DPerspectiveTransform.hxx"
#endif

#endif /* __itkRigid3DPerspectiveTransform_h */
