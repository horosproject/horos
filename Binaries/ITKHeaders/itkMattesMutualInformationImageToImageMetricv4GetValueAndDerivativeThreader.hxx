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
#ifndef __itkMattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader_hxx
#define __itkMattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader_hxx

#include "itkMattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader.h"

namespace itk
{

template< typename TDomainPartitioner, typename TImageToImageMetric, typename TMattesMutualInformationMetric >
void
MattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader< TDomainPartitioner, TImageToImageMetric,
                                                                          TMattesMutualInformationMetric >
::BeforeThreadedExecution()
{
  /* Most of this code needs to be here because we need to know the number
   * of threads the threader will use, which isn't known for sure until this
   * method is called. */

  /* Allocates and inits per-thread members.
   * We need a couple of these and the rest will be ignored. */
  Superclass::BeforeThreadedExecution();

  /* Store the casted pointer to avoid dynamic casting in tight loops. */
  this->m_MattesAssociate = dynamic_cast<TMattesMutualInformationMetric *>(this->m_Associate);
  if( this->m_MattesAssociate == ITK_NULLPTR )
    {
    itkExceptionMacro("Dynamic casting of associate pointer failed.");
    }

  /* Porting: these next blocks of code are from MattesMutualImageToImageMetric::Initialize */

  /*
   * Allocate memory for the marginal PDF and initialize values
   * to zero. The marginal PDFs are stored as std::vector.
   */
  if( this->m_MattesAssociate->m_MovingImageMarginalPDF.size() != this->m_MattesAssociate->m_NumberOfHistogramBins )
    {
    this->m_MattesAssociate->m_MovingImageMarginalPDF.resize(this->m_MattesAssociate->m_NumberOfHistogramBins, 0.0F);
    }
  else
    {
    std::fill(
      this->m_MattesAssociate->m_MovingImageMarginalPDF.begin(),
      this->m_MattesAssociate->m_MovingImageMarginalPDF.end(), 0.0);
    }

    {
    JointPDFRegionType jointPDFRegion;
      {
      // For the joint PDF define a region starting from {0,0}
      // with size {m_NumberOfHistogramBins, this->m_NumberOfHistogramBins}.
      // The dimension represents fixed image bin size
      // and moving image bin size , respectively.
      JointPDFIndexType jointPDFIndex;
      jointPDFIndex.Fill(0);
      JointPDFSizeType jointPDFSize;
      jointPDFSize.Fill(this->m_MattesAssociate->m_NumberOfHistogramBins);

      jointPDFRegion.SetIndex(jointPDFIndex);
      jointPDFRegion.SetSize(jointPDFSize);
      }
    if( this->m_MattesAssociate->m_AccumulatorJointPDF.IsNull()
      || jointPDFRegion != this->m_MattesAssociate->m_AccumulatorJointPDF->GetBufferedRegion() )
      {
      // By setting these values, the joint histogram physical locations will
      // correspond to intensity values.
      typename JointPDFType::PointType origin;
      origin[0] = this->m_MattesAssociate->m_FixedImageTrueMin;
      origin[1] = this->m_MattesAssociate->m_MovingImageTrueMin;
      typename JointPDFType::SpacingType spacing;
      spacing[0] = this->m_MattesAssociate->m_FixedImageBinSize;
      spacing[1] = this->m_MattesAssociate->m_MovingImageBinSize;

        {
        this->m_MattesAssociate->m_AccumulatorJointPDF = JointPDFType::New();
        this->m_MattesAssociate->m_AccumulatorJointPDF->SetRegions(jointPDFRegion);
        this->m_MattesAssociate->m_AccumulatorJointPDF->SetOrigin(origin);
        this->m_MattesAssociate->m_AccumulatorJointPDF->SetSpacing(spacing);
        // NOTE: true = initizize to zero
        this->m_MattesAssociate->m_AccumulatorJointPDF->Allocate(true);
        }
      }
    else
      {
      // Still need to reset to zero for subsequent runs
      this->m_MattesAssociate->m_AccumulatorJointPDF->FillBuffer(0.0);
      }
    }
    {
    JointPDFDerivativesRegionType jointPDFDerivativesRegion;
      {
      // For the derivatives of the joint PDF define a region starting from
      // {0,0,0}
      // with size {m_NumberOfParameters,m_NumberOfHistogramBins,
      // this->m_NumberOfHistogramBins}. The dimension represents transform
      // parameters,
      // fixed image parzen window index and moving image parzen window index,
      // respectively.
      JointPDFDerivativesIndexType jointPDFDerivativesIndex;
      jointPDFDerivativesIndex.Fill(0);
      JointPDFDerivativesSizeType jointPDFDerivativesSize;
      jointPDFDerivativesSize[0] = this->m_MattesAssociate->GetNumberOfLocalParameters();
      jointPDFDerivativesSize[1] = this->m_MattesAssociate->m_NumberOfHistogramBins;
      jointPDFDerivativesSize[2] = this->m_MattesAssociate->m_NumberOfHistogramBins;

      jointPDFDerivativesRegion.SetIndex(jointPDFDerivativesIndex);
      jointPDFDerivativesRegion.SetSize(jointPDFDerivativesSize);
      }
    if( this->m_MattesAssociate->m_AccumulatorJointPDFDerivatives.IsNull() ||
      jointPDFDerivativesRegion != this->m_MattesAssociate->m_AccumulatorJointPDFDerivatives->GetBufferedRegion() )
      {
      // Set the regions and allocate
      this->m_MattesAssociate->m_AccumulatorJointPDFDerivatives = JointPDFDerivativesType::New();
      this->m_MattesAssociate->m_AccumulatorJointPDFDerivatives->SetRegions( jointPDFDerivativesRegion);
      this->m_MattesAssociate->m_AccumulatorJointPDFDerivatives->Allocate(true);
      }
    else
      {
      // Still need to reset to zero for subsequent runs
      this->m_MattesAssociate->m_AccumulatorJointPDFDerivatives->FillBuffer(0.0);
      }
    }

  const ThreadIdType mattesAssociateNumThreadsUsed = this->m_MattesAssociate->GetNumberOfThreadsUsed();
  const bool reinitializeThreaderFixedImageMarginalPDF = ( this->m_MattesAssociate->m_ThreaderFixedImageMarginalPDF.size() != mattesAssociateNumThreadsUsed );

  if( reinitializeThreaderFixedImageMarginalPDF )
    {
    this->m_MattesAssociate->m_ThreaderFixedImageMarginalPDF.resize(mattesAssociateNumThreadsUsed,
                                                                    std::vector<PDFValueType>(this->m_MattesAssociate->
                                                                                              m_NumberOfHistogramBins,
                                                                                              0.0F) );
    }

  this->m_MattesAssociate->m_JointPDFSum = 0;

  //NOTE: If container is the correct size, then no acion is taken.
  this->m_MattesAssociate->m_ThreaderJointPDF.resize(mattesAssociateNumThreadsUsed);

  //Resize the sub-sections locks array!
  if( this->m_MattesAssociate->m_JointPDFSubsectionLocks.size() != mattesAssociateNumThreadsUsed )
    {
    this->m_MattesAssociate->m_JointPDFSubsectionLocks.resize(mattesAssociateNumThreadsUsed);
    this->m_MattesAssociate->m_JointPDFDerivativeSubsectionLocks.resize(mattesAssociateNumThreadsUsed);
    for( ThreadIdType threadId = 0; threadId < mattesAssociateNumThreadsUsed; ++threadId )
      {
      this->m_MattesAssociate->m_JointPDFSubsectionLocks[threadId] = MutexLock::New();
      this->m_MattesAssociate->m_JointPDFDerivativeSubsectionLocks[threadId] = MutexLock::New();
      }
    }

  //
  // Now allocate memory according to transform type
  //
  if( ! this->m_MattesAssociate->GetComputeDerivative() )
    {
    // We only need these if we're computing derivatives.
    this->m_MattesAssociate->m_PRatioArray.resize(0);
    this->m_MattesAssociate->m_JointPdfIndex1DArray.resize(0);
    this->m_MattesAssociate->m_LocalDerivativeByParzenBin.resize(0);
    this->m_MattesAssociate->m_ThreaderJointPDFDerivatives.resize(0);
    }

  if(  this->m_MattesAssociate->GetComputeDerivative() && this->m_MattesAssociate->HasLocalSupport() )
    {
    this->m_MattesAssociate->m_PRatioArray.assign( this->m_MattesAssociate->m_NumberOfHistogramBins * this->m_MattesAssociate->m_NumberOfHistogramBins, 0.0);
    this->m_MattesAssociate->m_JointPdfIndex1DArray.assign( this->m_MattesAssociate->GetNumberOfParameters(), 0 );
    // Don't need this with local-support
    this->m_MattesAssociate->m_ThreaderJointPDFDerivatives.resize(0);
    // This always has four entries because the parzen window size is fixed.
    this->m_MattesAssociate->m_LocalDerivativeByParzenBin.resize(4);
    // The first container cannot point to the existing derivative result
    // object
    // for efficiency, because of multi-variate metric.
    for( SizeValueType n = 0; n < 4; ++n )
      {
      this->m_MattesAssociate->m_LocalDerivativeByParzenBin[n].SetSize(
        this->m_MattesAssociate->GetNumberOfParameters() );
      // Initialize to zero because we accumulate, and so skipped points will
      // behave properly
      this->m_MattesAssociate->m_LocalDerivativeByParzenBin[n].Fill( NumericTraits< DerivativeValueType >::ZeroValue() );
      }
    }
  if(  this->m_MattesAssociate->GetComputeDerivative() && ! this->m_MattesAssociate->HasLocalSupport() )
    {
    // Don't need this with global transforms
    this->m_MattesAssociate->m_PRatioArray.resize(0);
    this->m_MattesAssociate->m_JointPdfIndex1DArray.resize(0);
    this->m_MattesAssociate->m_LocalDerivativeByParzenBin.resize(0);
    }

  if( this->m_MattesAssociate->GetComputeDerivative()  &&  ! this->m_MattesAssociate->HasLocalSupport() )
    {
    this->m_MattesAssociate->m_ThreaderJointPDFDerivatives.resize(mattesAssociateNumThreadsUsed);
    }
}

template< typename TDomainPartitioner, typename TImageToImageMetric, typename TMattesMutualInformationMetric >
bool
MattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader< TDomainPartitioner, TImageToImageMetric, TMattesMutualInformationMetric >
::ProcessPoint( const VirtualIndexType &           virtualIndex,
                const VirtualPointType &           virtualPoint,
                const FixedImagePointType &,
                const FixedImagePixelType &        fixedImageValue,
                const FixedImageGradientType &,
                const MovingImagePointType &,
                const MovingImagePixelType &       movingImageValue,
                const MovingImageGradientType &    movingImageGradient,
                MeasureType &,
                DerivativeType &,
                const ThreadIdType                 threadId) const
{
  const bool doComputeDerivative = this->m_MattesAssociate->GetComputeDerivative();
  /**
   * Compute this sample's contribution to the marginal
   *   and joint distributions.
   *
   */
  if( movingImageValue < this->m_MattesAssociate->m_MovingImageTrueMin )
    {
    return false;
    }
  else if( movingImageValue > this->m_MattesAssociate->m_MovingImageTrueMax )
    {
    return false;
    }

  // Determine parzen window arguments (see eqn 6 of Mattes paper [2]).
  const PDFValueType movingImageParzenWindowTerm = movingImageValue / this->m_MattesAssociate->m_MovingImageBinSize - this->m_MattesAssociate->m_MovingImageNormalizedMin;
  OffsetValueType movingImageParzenWindowIndex = static_cast<OffsetValueType>( movingImageParzenWindowTerm );

  // Make sure the extreme values are in valid bins
  if( movingImageParzenWindowIndex < 2 )
    {
    movingImageParzenWindowIndex = 2;
    }
  else
    {
    const OffsetValueType nindex = static_cast<OffsetValueType>( this->m_MattesAssociate->m_NumberOfHistogramBins ) - 3;
    if( movingImageParzenWindowIndex > nindex )
      {
      movingImageParzenWindowIndex = nindex;
      }
    }
  // Move the pointer to the first affected bin
  OffsetValueType pdfMovingIndex = static_cast<OffsetValueType>( movingImageParzenWindowIndex ) - 1;
  const OffsetValueType pdfMovingIndexMax = static_cast<OffsetValueType>( movingImageParzenWindowIndex ) + 2;

  const OffsetValueType fixedImageParzenWindowIndex = this->m_MattesAssociate->ComputeSingleFixedImageParzenWindowIndex( fixedImageValue );

  // Since a zero-order BSpline (box car) kernel is used for
  // the fixed image marginal pdf, we need only increment the
  // fixedImageParzenWindowIndex by value of 1.0.
  this->m_MattesAssociate->m_ThreaderFixedImageMarginalPDF[threadId][fixedImageParzenWindowIndex] += 1;

  /**
    * The region of support of the parzen window determines which bins
    * of the joint PDF are effected by the pair of image values.
    * Since we are using a cubic spline for the moving image parzen
    * window, four bins are effected.  The fixed image parzen window is
    * a zero-order spline (box car) and thus effects only one bin.
    *
    *  The PDF is arranged so that moving image bins corresponds to the
    * zero-th (column) dimension and the fixed image bins corresponds
    * to the first (row) dimension.
    */
  PDFValueType movingImageParzenWindowArg = static_cast<PDFValueType>( pdfMovingIndex ) - static_cast<PDFValueType>( movingImageParzenWindowTerm );

  // Pointer to affected bin to be updated
  JointPDFValueType *pdfPtr = this->m_MattesAssociate->m_ThreaderJointPDF[threadId]->GetBufferPointer()
                              + ( fixedImageParzenWindowIndex * this->m_MattesAssociate->m_NumberOfHistogramBins ) + pdfMovingIndex;

  OffsetValueType localDerivativeOffset = 0;
  // Store the pdf indecies for this point.
  // Just store the starting pdfMovingIndex and we'll iterate later
  // over the next four to collect results.
  if( doComputeDerivative && ( this->m_MattesAssociate->HasLocalSupport() ) )
    {
    const OffsetValueType jointPdfIndex1D = pdfMovingIndex + (fixedImageParzenWindowIndex * this->m_MattesAssociate->m_NumberOfHistogramBins);
    localDerivativeOffset = this->m_MattesAssociate->ComputeParameterOffsetFromVirtualIndex( virtualIndex, this->GetCachedNumberOfLocalParameters() );
    for (NumberOfParametersType i=0, numLocalParameters = this->GetCachedNumberOfLocalParameters();
      i < numLocalParameters; ++i)
      {
      this->m_MattesAssociate->m_JointPdfIndex1DArray[localDerivativeOffset + i] = jointPdfIndex1D;
      }
    }

  // Compute the transform Jacobian.
  typedef JacobianType & JacobianReferenceType;
  JacobianReferenceType jacobian = this->m_GetValueAndDerivativePerThreadVariables[threadId].MovingTransformJacobian;
  if( doComputeDerivative )
    {
    JacobianReferenceType jacobianPositional = this->m_GetValueAndDerivativePerThreadVariables[threadId].MovingTransformJacobianPositional;
    this->m_MattesAssociate->GetMovingTransform()->
      ComputeJacobianWithRespectToParametersCachedTemporaries(virtualPoint,
                                                              jacobian,
                                                              jacobianPositional);
    }

  SizeValueType movingParzenBin = 0;

  const bool transformIsDisplacement = this->m_MattesAssociate->m_MovingTransform->GetTransformCategory() == MovingTransformType::DisplacementField;
  while( pdfMovingIndex <= pdfMovingIndexMax )
    {
    const PDFValueType val = static_cast<PDFValueType>( this->m_MattesAssociate->m_CubicBSplineKernel ->Evaluate( movingImageParzenWindowArg) );
    *( pdfPtr++ ) += val;

    if( doComputeDerivative )
      {
      // Compute the cubicBSplineDerivative for later repeated use.
      const PDFValueType cubicBSplineDerivativeValue = this->m_MattesAssociate->m_CubicBSplineDerivativeKernel->Evaluate(movingImageParzenWindowArg);


      if( transformIsDisplacement )
        {
        // Pointer to local derivative partial result container.
        // Not used with global support transforms.
        // ptr to where the derivative result should go, for efficiency
        DerivativeValueType * localSupportDerivativeResultPtr =
          &( this->m_MattesAssociate->m_LocalDerivativeByParzenBin[movingParzenBin][localDerivativeOffset] );
        // Compute PDF derivative contribution.

        this->ComputePDFDerivativesLocalSupportTransform(
          jacobian,
          movingImageGradient,
          cubicBSplineDerivativeValue,
          localSupportDerivativeResultPtr);
        }
      else
        {
        // Compute PDF derivative contribution.
        this->ComputePDFDerivativesGlobalSupportTransform(threadId,
          fixedImageParzenWindowIndex,
          jacobian,
          pdfMovingIndex,
          movingImageGradient,
          cubicBSplineDerivativeValue);
        }
      }

    movingImageParzenWindowArg += 1.0;
    ++pdfMovingIndex;
    ++movingParzenBin;
    }

  // have to do this here since we're returning false
  this->m_GetValueAndDerivativePerThreadVariables[threadId].NumberOfValidPoints++;

  // Return false to avoid the storage of results in parent class.
  return false;
}

template< typename TDomainPartitioner, typename TImageToImageMetric, typename TMattesMutualInformationMetric >
void
MattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader< TDomainPartitioner, TImageToImageMetric, TMattesMutualInformationMetric >
::ComputePDFDerivativesGlobalSupportTransform(const ThreadIdType &            threadId,
                        const OffsetValueType &         fixedImageParzenWindowIndex,
                        const JacobianType &            jacobian,
                        const OffsetValueType &         pdfMovingIndex,
                        const MovingImageGradientType & movingImageGradient,
                        const PDFValueType &            cubicBSplineDerivativeValue) const
{
  // Update bins in the PDF derivatives for the current intensity pair
  const OffsetValueType pdfFixedIndex = fixedImageParzenWindowIndex;

  JointPDFDerivativesValueType *derivPtr = this->m_MattesAssociate->m_ThreaderJointPDFDerivatives[threadId]->GetBufferPointer()
      + ( pdfFixedIndex  * this->m_MattesAssociate->m_ThreaderJointPDFDerivatives[threadId]->GetOffsetTable()[2] )
      + ( pdfMovingIndex * this->m_MattesAssociate->m_ThreaderJointPDFDerivatives[threadId]->GetOffsetTable()[1] );

  for( NumberOfParametersType mu = 0, maxElement=this->GetCachedNumberOfLocalParameters(); mu < maxElement; ++mu )
    {
    PDFValueType innerProduct = 0.0;
    for( SizeValueType dim = 0, lastDim = this->m_MattesAssociate->MovingImageDimension; dim < lastDim; ++dim )
      {
      innerProduct += jacobian[dim][mu] * movingImageGradient[dim];
      }

    const PDFValueType derivativeContribution = innerProduct * cubicBSplineDerivativeValue;
    *( derivPtr ) -= derivativeContribution;
    ++derivPtr;
    }
}

template< typename TDomainPartitioner, typename TImageToImageMetric, typename TMattesMutualInformationMetric >
void
MattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader< TDomainPartitioner, TImageToImageMetric, TMattesMutualInformationMetric >
::ComputePDFDerivativesLocalSupportTransform(
                        const JacobianType &            jacobian,
                        const MovingImageGradientType & movingImageGradient,
                        const PDFValueType &            cubicBSplineDerivativeValue,
                        DerivativeValueType *           localSupportDerivativeResultPtr) const
{
  for( NumberOfParametersType mu = 0, maxElement=this->GetCachedNumberOfLocalParameters(); mu < maxElement; ++mu )
    {
    PDFValueType innerProduct = 0.0;
    for( SizeValueType dim = 0, lastDim = this->m_MattesAssociate->MovingImageDimension; dim < lastDim; ++dim )
      {
      innerProduct += jacobian[dim][mu] * movingImageGradient[dim];
      }

    const PDFValueType derivativeContribution = innerProduct * cubicBSplineDerivativeValue;
    *( localSupportDerivativeResultPtr ) += derivativeContribution;
    localSupportDerivativeResultPtr++;
    }
}

template< typename TDomainPartitioner, typename TImageToImageMetric, typename TMattesMutualInformationMetric >
void
MattesMutualInformationImageToImageMetricv4GetValueAndDerivativeThreader< TDomainPartitioner, TImageToImageMetric, TMattesMutualInformationMetric >
::AfterThreadedExecution()
{
  const ThreadIdType localNumberOfThreadsUsed = this->GetNumberOfThreadsUsed();
  /* Store the number of valid points in the enclosing class
   * m_NumberOfValidPoints by collecting the valid points per thread.
   * We do this here because we're skipping Superclass::AfterThreadedExecution*/
  this->m_MattesAssociate->m_NumberOfValidPoints = NumericTraits< SizeValueType >::ZeroValue();
  for (ThreadIdType threadId = 0; threadId < localNumberOfThreadsUsed; ++threadId)
    {
    this->m_MattesAssociate->m_NumberOfValidPoints += this->m_GetValueAndDerivativePerThreadVariables[threadId].NumberOfValidPoints;
    }

  /* Porting: This code is from
   * MattesMutualInformationImageToImageMetric::GetValueAndDerivativeThreadPostProcess */
  /* Post-processing that is common the GetValue and GetValueAndDerivative */
  this->m_MattesAssociate->GetValueCommonAfterThreadedExecution();

  // Collect and compute results.
  // Value and derivative are stored in member vars.
  this->m_MattesAssociate->ComputeResults();
}

} // end namespace itk

#endif
