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
#ifndef __itkTxtTransformIO_h
#define __itkTxtTransformIO_h
#include "itkTransformIOBase.h"

namespace itk
{
/** \class TxtTransformIOTemplate
   * \brief Create instances of TxtTransformIOTemplate objects.
   * \ingroup ITKIOTransformInsightLegacy
   */
template<typename ParametersValueType>
class TxtTransformIOTemplate:public TransformIOBaseTemplate<ParametersValueType>
{
public:
  typedef TxtTransformIOTemplate                        Self;
  typedef TransformIOBaseTemplate<ParametersValueType>  Superclass;
  typedef SmartPointer< Self >                          Pointer;
  typedef typename Superclass::TransformType            TransformType;
  typedef typename Superclass::TransformPointer         TransformPointer;
  typedef typename Superclass::TransformListType        TransformListType;
  typedef typename TransformIOBaseTemplate
                      <ParametersValueType>::ConstTransformListType
                                                        ConstTransformListType;

  /** Run-time type information (and related methods). */
  itkTypeMacro(TxtTransformIOTemplate, Superclass);
  itkNewMacro(Self);

  /** Determine the file type. Returns true if this ImageIO can read the
   * file specified. */
  virtual bool CanReadFile(const char *);

  /** Determine the file type. Returns true if this ImageIO can read the
   * file specified. */
  virtual bool CanWriteFile(const char *);

  /** Reads the data from disk into the memory buffer provided. */
  virtual void Read();

  /** Writes the data to disk from the memory buffer provided. Make sure
   * that the IORegions has been set properly. The buffer is cast to a
   * pointer to the beginning of the image data. */
  virtual void Write();

  /* Helper function for Read method, used for CompositeTransform reading. */
  void ReadComponentFile( std::string Value );

protected:
  TxtTransformIOTemplate();
  virtual ~TxtTransformIOTemplate();

private:
  /** trim spaces and newlines from start and end of a string */
  std::string trim(std::string const & source, char const *delims = " \t\r\n");
};

/** This helps to meet backward compatibility */
typedef TxtTransformIOTemplate<double> TxtTransformIO;

}

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkTxtTransformIO.hxx"
#endif

#endif // __itkTxtTransformIO_h
