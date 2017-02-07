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
#ifndef __itkSurfaceSpatialObject_h
#define __itkSurfaceSpatialObject_h

#include <list>

#include "itkPointBasedSpatialObject.h"
#include "itkSurfaceSpatialObjectPoint.h"

namespace itk
{
/**
 * \class SurfaceSpatialObject
 * \brief Representation of a Surface based on the spatial object classes.
 *
 * The Surface is basically defined by a set of points.
 *
 * \sa SurfaceSpatialObjectPoint
 * \ingroup ITKSpatialObjects
 */

template< unsigned int TDimension = 3 >
class SurfaceSpatialObject:
  public PointBasedSpatialObject<  TDimension >
{
public:

  typedef SurfaceSpatialObject                         Self;
  typedef PointBasedSpatialObject< TDimension >        Superclass;
  typedef SmartPointer< Self >                         Pointer;
  typedef SmartPointer< const Self >                   ConstPointer;
  typedef double                                       ScalarType;
  typedef SurfaceSpatialObjectPoint< TDimension >      SurfacePointType;
  typedef std::vector< SurfacePointType >              PointListType;
  typedef typename Superclass::SpatialObjectPointType  SpatialObjectPointType;
  typedef typename Superclass::PointType               PointType;
  typedef typename Superclass::TransformType           TransformType;
  typedef VectorContainer< IdentifierType, PointType > PointContainerType;
  typedef SmartPointer< PointContainerType >           PointContainerPointer;
  typedef typename Superclass::BoundingBoxType         BoundingBoxType;
  typedef typename Superclass::CovariantVectorType     CovariantVectorType;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Method for creation through the object factory. */
  itkTypeMacro(SurfaceSpatialObject, PointBasedSpatialObject);

  /** Returns a reference to the list of the Surface points. */
  PointListType & GetPoints(void);
  const PointListType & GetPoints(void) const;

  /** Return a point in the list given the index */
  const SpatialObjectPointType * GetPoint(IdentifierType id) const
  {
    return &( m_Points[id] );
  }

  /** Return a point in the list given the index */
  SpatialObjectPointType * GetPoint(IdentifierType id) { return &( m_Points[id] ); }

  /** Return the number of points in the list */
  SizeValueType GetNumberOfPoints(void) const { return m_Points.size(); }

  /** Set the list of Surface points. */
  void SetPoints(PointListType & newPoints);

  /** Returns true if the Surface is evaluable at the requested point,
   * false otherwise. */
  bool IsEvaluableAt(const PointType & point,
                     unsigned int depth = 0, char *name = ITK_NULLPTR) const;

  /** Returns the value of the Surface at that point.
   *  Currently this function returns a binary value,
   *  but it might want to return a degree of membership
   *  in case of fuzzy Surfaces. */
  bool ValueAt(const PointType & point, double & value,
               unsigned int depth = 0, char *name = ITK_NULLPTR) const;

  /** Returns true if the point is inside the Surface, false otherwise. */
  bool IsInside(const PointType & point,
                unsigned int depth, char *name) const;

  /** Test whether a point is inside or outside the object
   *  For computational speed purposes, it is faster if the method does not
   *  check the name of the class and the current depth */
  virtual bool IsInside(const PointType & point) const;

  /** Compute the boundaries of the Surface. */
  bool ComputeLocalBoundingBox() const;

  /** Compute the normals to the surface from neighboring points */
  bool Approximate3DNormals();

protected:
  SurfaceSpatialObject(const Self &); //purposely not implemented
  void operator=(const Self &);       //purposely not implemented

  PointListType m_Points;

  SurfaceSpatialObject();
  virtual ~SurfaceSpatialObject();

  /** Method to print the object.*/
  virtual void PrintSelf(std::ostream & os, Indent indent) const;
};
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkSurfaceSpatialObject.hxx"
#endif

#endif // __itkSurfaceSpatialObject_h
