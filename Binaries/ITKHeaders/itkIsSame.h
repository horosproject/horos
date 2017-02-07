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
#ifndef __itkIsSame_h
#define __itkIsSame_h

namespace itk
{

  /** \cond HIDE_META_PROGRAMMING */
  /** borrowed from type_traits */
  struct TrueType
  {
    typedef bool     ValueType;
    typedef TrueType Type;

    static const ValueType Value = true;
    operator ValueType() { return Value; }
  };

  struct FalseType
  {
    typedef bool      ValueType;
    typedef FalseType Type;
    static const ValueType Value = false;
    operator ValueType() { return Value; }
  };

  template<typename, typename>
  struct IsSame
    : public FalseType
  {
  };

  template<typename T>
  struct IsSame<T, T>
    : public TrueType
  {
  };

  /** \endcond */

} // end namespace itk

#endif //__itkIsSame_h
