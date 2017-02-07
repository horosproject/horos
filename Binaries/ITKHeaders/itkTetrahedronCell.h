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
#ifndef __itkTetrahedronCell_h
#define __itkTetrahedronCell_h

#include "itkTriangleCell.h"
#include "itkTetrahedronCellTopology.h"

namespace itk
{
/** \class TetrahedronCell
 *  \brief TetrahedronCell represents a tetrahedron for a Mesh.
 *
 * \tparam TPixelType The type associated with a point, cell, or boundary
 * for use in storing its data.
 *
 * \tparam TCellTraits Type information of mesh containing cell.
 * \ingroup MeshObjects
 * \ingroup ITKCommon
 */
template< typename TCellInterface >
class TetrahedronCell:public TCellInterface, private TetrahedronCellTopology
{
public:
  /** Standard class typedefa. */
  itkCellCommonTypedefs(TetrahedronCell);
  itkCellInheritedTypedefs(TCellInterface);

  /** Standard part of every itk Object. */
  itkTypeMacro(TetrahedronCell, CellInterface);

  /** The type of boundary for this triangle's vertices. */
  typedef VertexCell< TCellInterface >         VertexType;
  typedef typename VertexType::SelfAutoPointer VertexAutoPointer;

  /** The type of boundary for this triangle's edges. */
  typedef LineCell< TCellInterface >         EdgeType;
  typedef typename EdgeType::SelfAutoPointer EdgeAutoPointer;

  /** The type of boundary for this hexahedron's faces. */
  typedef TriangleCell< TCellInterface >     FaceType;
  typedef typename FaceType::SelfAutoPointer FaceAutoPointer;

  /** Tetrahedron-specific topology numbers. */
  itkStaticConstMacro(NumberOfPoints, unsigned int, 4);
  itkStaticConstMacro(NumberOfVertices, unsigned int, 4);
  itkStaticConstMacro(NumberOfEdges, unsigned int, 6);
  itkStaticConstMacro(NumberOfFaces, unsigned int, 4);
  itkStaticConstMacro(CellDimension, unsigned int, 3);

  /** Implement the standard CellInterface. */
  virtual CellGeometry GetType(void) const
  { return Superclass::TETRAHEDRON_CELL; }
  virtual void MakeCopy(CellAutoPointer &) const;

  virtual unsigned int GetDimension(void) const;

  virtual unsigned int GetNumberOfPoints(void) const;

  virtual CellFeatureCount GetNumberOfBoundaryFeatures(int dimension) const;

  virtual bool GetBoundaryFeature(int dimension, CellFeatureIdentifier,
                                  CellAutoPointer &);
  virtual void SetPointIds(PointIdConstIterator first);

  virtual void SetPointIds(PointIdConstIterator first,
                           PointIdConstIterator last);

  virtual void SetPointId(int localId, PointIdentifier);
  virtual PointIdIterator      PointIdsBegin(void);

  virtual PointIdConstIterator PointIdsBegin(void) const;

  virtual PointIdIterator      PointIdsEnd(void);

  virtual PointIdConstIterator PointIdsEnd(void) const;

  /** Tetrahedron-specific interface. */
  virtual CellFeatureCount GetNumberOfVertices(void) const;

  virtual CellFeatureCount GetNumberOfEdges(void) const;

  virtual CellFeatureCount GetNumberOfFaces(void) const;

  virtual bool GetVertex(CellFeatureIdentifier, VertexAutoPointer &);
  virtual bool GetEdge(CellFeatureIdentifier, EdgeAutoPointer &);
  virtual bool GetFace(CellFeatureIdentifier, FaceAutoPointer &);

  /** Visitor interface. */
  itkCellVisitMacro(Superclass::TETRAHEDRON_CELL);

  virtual bool EvaluatePosition(CoordRepType *,
                                PointsContainer *,
                                CoordRepType *,
                                CoordRepType[],
                                double *,
                                InterpolationWeightType *);

public:
  TetrahedronCell()
  {
    for ( PointIdentifier i = 0; i < itkGetStaticConstMacro(NumberOfPoints); i++ )
      {
      m_PointIds[i] = NumericTraits< PointIdentifier >::max();
      }
  }

  ~TetrahedronCell() {}

protected:
  /** Store the number of points needed for a tetrahedron. */
  PointIdentifier m_PointIds[NumberOfPoints];

private:
  TetrahedronCell(const Self &); //purposely not implemented
  void operator=(const Self &);  //purposely not implemented
};
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkTetrahedronCell.hxx"
#endif

#endif
