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

#ifndef __itk_hdf5_h
#define __itk_hdf5_h

/* Use the hdf5 library configured for ITK.  */
/* #undef ITK_USE_SYSTEM_HDF5 */
#ifdef ITK_USE_SYSTEM_HDF5
# include <hdf5.h>
#else
# include "itkhdf5/hdf5.h"
#endif

#endif
