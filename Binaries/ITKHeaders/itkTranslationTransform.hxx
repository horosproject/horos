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
#ifndef __itkTranslationTransform_hxx
#define __itkTranslationTransform_hxx

#include "itkTranslationTransform.h"
#include "itkMath.h"

namespace itk
{

template <typename TScalar, unsigned int NDimensions>
TranslationTransform<TScalar, NDimensions>
::TranslationTransform() : Superclass(ParametersDimension),
  m_IdentityJacobian(NDimensions, NDimensions)
{
  m_Offset.Fill(0);

  // The Jacobian of this transform is constant.
  // Therefore the m_IdentityJacobian variable can be
  // initialized here and be shared among all the threads.
  this->m_IdentityJacobian.Fill(0.0);
  for( unsigned int i = 0; i < NDimensions; i++ )
    {
    this->m_IdentityJacobian(i, i) = 1.0;
    }
}


template <typename TScalar, unsigned int NDimensions>
TranslationTransform<TScalar, NDimensions>
::~TranslationTransform()
{
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>
::SetParameters(const ParametersType & parameters)
{
  // Save parameters. Needed for proper operation of TransformUpdateParameters.
  if( &parameters != &(this->m_Parameters) )
    {
    this->m_Parameters = parameters;
    }

  bool modified = false;
  for( unsigned int i = 0; i < SpaceDimension; i++ )
    {
    if( m_Offset[i] != parameters[i] )
      {
      m_Offset[i] = parameters[i];
      modified = true;
      }
    }
  if( modified )
    {
    this->Modified();
    }
}


template <typename TScalar, unsigned int NDimensions>
const typename TranslationTransform<TScalar, NDimensions>::ParametersType &
TranslationTransform<TScalar, NDimensions>
::GetParameters() const
{
  for( unsigned int i = 0; i < SpaceDimension; i++ )
    {
    this->m_Parameters[i] = this->m_Offset[i];
    }
  return this->m_Parameters;
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>
::PrintSelf(std::ostream & os, Indent indent) const
{
  Superclass::PrintSelf(os, indent);

  os << indent << "Offset: " << m_Offset << std::endl;
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>
::Compose(const Self *other, bool)
{
  this->Translate(other->m_Offset);
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>
::Translate(const OutputVectorType & offset, bool)
{
  ParametersType newOffset(SpaceDimension);

  for( unsigned int i = 0; i < SpaceDimension; i++ )
    {
    newOffset[i] = m_Offset[i] + offset[i];
    }
  this->SetParameters(newOffset);
}


template <typename TScalar, unsigned int NDimensions>
typename TranslationTransform<TScalar, NDimensions>::OutputPointType
TranslationTransform<TScalar, NDimensions>
::TransformPoint(const InputPointType & point) const
{
  return point + m_Offset;
}


template <typename TScalar, unsigned int NDimensions>
typename TranslationTransform<TScalar, NDimensions>::OutputVectorType
TranslationTransform<TScalar, NDimensions>
::TransformVector(const InputVectorType & vect) const
{
  return vect;
}


template <typename TScalar, unsigned int NDimensions>
typename TranslationTransform<TScalar, NDimensions>::OutputVnlVectorType
TranslationTransform<TScalar, NDimensions>
::TransformVector(const InputVnlVectorType & vect) const
{
  return vect;
}


template <typename TScalar, unsigned int NDimensions>
typename TranslationTransform<TScalar, NDimensions>::OutputCovariantVectorType
TranslationTransform<TScalar, NDimensions>
::TransformCovariantVector(const InputCovariantVectorType & vect) const
{
  return vect;
}


template <typename TScalar, unsigned int NDimensions>
bool
TranslationTransform<TScalar, NDimensions>
::GetInverse(Self *inverse) const
{
  if( !inverse )
    {
    return false;
    }

  inverse->SetFixedParameters(this->GetFixedParameters());
  inverse->m_Offset   = -m_Offset;
  return true;
}


template <typename TScalar, unsigned int NDimensions>
typename TranslationTransform<TScalar, NDimensions>::InverseTransformBasePointer
TranslationTransform<TScalar, NDimensions>
::GetInverseTransform() const
{
  Pointer inv = New();

  return GetInverse(inv) ? inv.GetPointer() : ITK_NULLPTR;
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>::ComputeJacobianWithRespectToParameters(
  const InputPointType &,
  JacobianType & jacobian) const
{
  // the Jacobian is constant for this transform, and it has already been
  // initialized in the constructor, so we just need to return it here.
  jacobian = this->m_IdentityJacobian;
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>
::ComputeJacobianWithRespectToPosition(const InputPointType &,
                                       JacobianType & jac) const
{
  jac.SetSize( NDimensions, NDimensions );
  jac.Fill(0.0);
  for( unsigned int dim = 0; dim < NDimensions; dim++ )
    {
    jac[dim][dim] = 1.0;
    }
}


template <typename TScalar, unsigned int NDimensions>
void
TranslationTransform<TScalar, NDimensions>::SetIdentity()
{
  m_Offset.Fill(0.0);
}

} // end namespace itk

#endif
