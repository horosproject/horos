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

#ifndef __itkFEMObjectSpatialObject_h
#define __itkFEMObjectSpatialObject_h

#include "itkFEMObject.h"
#include "itkExceptionObject.h"
#include "itkSpatialObject.h"

namespace itk
{

/** \class FEMObjectSpatialObject
 * \brief Implementation spatial object that can hold a FEMObject.
 *
 * This class was created to hold a FEMObject as a SpatialObject.
 * This was originally done to provide an I/O mechanism for FE
 * problems. However, other SpatialObject functionality should be
 * supported by this class.
 *
 * \sa SpatialObject CompositeSpatialObject FEMObject
 * \ingroup ITKFEM
 */

template < unsigned int TDimension = 3>
class FEMObjectSpatialObject : public SpatialObject< TDimension >
{
public:

  typedef FEMObjectSpatialObject< TDimension > Self;
  typedef SpatialObject< TDimension >          Superclass;
  typedef SmartPointer< Self >                 Pointer;
  typedef SmartPointer< const Self >           ConstPointer;

  typedef itk::fem::FEMObject< TDimension >    FEMObjectType;
  typedef typename FEMObjectType::Pointer      FEMObjectPointer;

  /** Method for creation through the object factory. */
  itkNewMacro( Self );

  /** Run-time type information (and related methods). */
  itkTypeMacro( FEMObjectSpatialObject, SpatialObject );

  /** Set the femobject. */
  void SetFEMObject( FEMObjectType * femobject );

  /** Get a pointer to the femobject currently attached to the object. */
  FEMObjectType * GetFEMObject( void )
  {
    return m_FEMObject.GetPointer();
  }
  const FEMObjectType * GetFEMObject( void ) const
  {
    return m_FEMObject.GetPointer();
  }


  /** Returns the latest modified time of the object and its component. */
  ModifiedTimeType GetMTime( void ) const;

protected:
  FEMObjectSpatialObject(const Self&); //purposely not implemented
  void operator=(const Self&); //purposely not implemented

  FEMObjectPointer m_FEMObject;

  FEMObjectSpatialObject();
  virtual ~FEMObjectSpatialObject();

  void PrintSelf( std::ostream& os, Indent indent ) const;

};

} // end of namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkFEMObjectSpatialObject.hxx"
#endif

#endif //__itkFEMObjectSpatialObject_h
