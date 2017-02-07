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
#ifndef __itkQuadraticTriangleCell_h
#define __itkQuadraticTriangleCell_h

#include "itkQuadraticEdgeCell.h"
#include "itkQuadraticTriangleCellTopology.h"

namespace itk
{
/** \class QuadraticTriangleCell
 *  \brief Represents a second order triangular patch for a Mesh.
 *
 * \tparam TPixelType The type associated with a point, cell, or boundary
 * for use in storing its data.
 *
 * \tparam TCellTraits Type information of mesh containing cell.
 *
 * \ingroup MeshObjects
 * \ingroup ITKCommon
 */
template< typename TCellInterface >
class QuadraticTriangleCell:public TCellInterface, private QuadraticTriangleCellTopology
{
public:
  /** Standard class typedefs. */
  itkCellCommonTypedefs(QuadraticTriangleCell);
  itkCellInheritedTypedefs(TCellInterface);

  /** Standard part of every itk Object. */
  itkTypeMacro(QuadraticTriangleCell, CellInterface);

  /** The type of boundary for this triangle's vertices. */
  typedef VertexCell< TCellInterface >         VertexType;
  typedef typename VertexType::SelfAutoPointer VertexAutoPointer;

  /** The type of boundary for this triangle's edges. */
  typedef QuadraticEdgeCell< TCellInterface > EdgeType;
  typedef typename EdgeType::SelfAutoPointer  EdgeAutoPointer;

  /** Triangle-specific topology numbers. */
  itkStaticConstMacro(NumberOfPoints, unsigned int, 6);
  itkStaticConstMacro(NumberOfVertices, unsigned int, 3);
  itkStaticConstMacro(NumberOfEdges, unsigned int, 3);
  itkStaticConstMacro(CellDimension, unsigned int, 2);

  /** Implement the standard CellInterface. */
  virtual CellGeometry GetType(void) const
  { return Superclass::QUADRATIC_TRIANGLE_CELL; }
  virtual void MakeCopy(CellAutoPointer &) const;

  virtual unsigned int GetDimension(void) const;

  virtual unsigned int GetNumberOfPoints(void) const;

  virtual CellFeatureCount GetNumberOfBoundaryFeatures(int dimension) const;

  virtual bool GetBoundaryFeature(int dimension, CellFeatureIdentifier, CellAutoPointer &);
  virtual void SetPointIds(PointIdConstIterator first);

  virtual void SetPointIds(PointIdConstIterator first,
                           PointIdConstIterator last);

  virtual void SetPointId(int localId, PointIdentifier);
  virtual PointIdIterator      PointIdsBegin(void);

  virtual PointIdConstIterator PointIdsBegin(void) const;

  virtual PointIdIterator      PointIdsEnd(void);

  virtual PointIdConstIterator PointIdsEnd(void) const;

  /** Triangle-specific interface. */
  virtual CellFeatureCount GetNumberOfVertices(void) const;

  virtual CellFeatureCount GetNumberOfEdges(void) const;

  virtual bool GetVertex(CellFeatureIdentifier, VertexAutoPointer &);
  virtual bool GetEdge(CellFeatureIdentifier, EdgeAutoPointer &);

  /** Cell visitor interface. */
  itkCellVisitMacro(Superclass::QUADRATIC_TRIANGLE_CELL);

  /** Given the parametric coordinates of a point in the cell
   *  determine the value of its Shape Functions
   *  returned through an itkArray<InterpolationWeightType>).  */
  virtual void EvaluateShapeFunctions(
    const ParametricCoordArrayType & parametricCoordinates,
    ShapeFunctionsArrayType  & weights) const;

public:
  QuadraticTriangleCell()
  {
    for ( PointIdentifier i = 0; i < itkGetStaticConstMacro(NumberOfPoints); i++ )
      {
      m_PointIds[i] = NumericTraits< PointIdentifier >::max();
      }
  }

  ~QuadraticTriangleCell() {}

protected:
  /** Store the number of points needed for a triangle. */
  PointIdentifier m_PointIds[NumberOfPoints];

private:
  QuadraticTriangleCell(const Self &); //purposely not implemented
  void operator=(const Self &);        //purposely not implemented
};
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkQuadraticTriangleCell.hxx"
#endif

#endif
