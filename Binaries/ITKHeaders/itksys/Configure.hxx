/*============================================================================
  KWSys - Kitware System Library
  Copyright 2000-2009 Kitware, Inc., Insight Software Consortium

  Distributed under the OSI-approved BSD License (the "License");
  see accompanying file Copyright.txt for details.

  This software is distributed WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the License for more information.
============================================================================*/
#ifndef itksys_Configure_hxx
#define itksys_Configure_hxx

/* Include C configuration.  */
#include <itksys/Configure.h>

/* Whether ANSI C++ stream headers are to be used.  */
#define itksys_IOS_USE_ANSI 1

/* Whether ANSI C++ streams are in std namespace.  */
#define itksys_IOS_HAVE_STD 1

/* Whether ANSI C++ <sstream> header is to be used.  */
#define itksys_IOS_USE_SSTREAM 1

/* Whether old C++ <strstream.h> header is to be used.  */
#define itksys_IOS_USE_STRSTREAM_H 0

/* Whether old C++ <strstrea.h> header is to be used.  */
#define itksys_IOS_USE_STRSTREA_H 0

/* Whether C++ streams support the ios::binary openmode.  */
#define itksys_IOS_HAVE_BINARY 1

/* Whether STL is in std namespace.  */
#define itksys_STL_HAVE_STD 1

/* Whether wstring is available.  */
#define itksys_STL_HAS_WSTRING 1

/* Whether the STL string has operator<< for ostream.  */
#define itksys_STL_STRING_HAVE_OSTREAM 1

/* Whether the STL string has operator>> for istream.  */
#define itksys_STL_STRING_HAVE_ISTREAM 1

/* Whether the STL string has operator!= for char*.  */
#define itksys_STL_STRING_HAVE_NEQ_CHAR 1

/* Define the stl namespace macro.  */
#if itksys_STL_HAVE_STD
# define itksys_stl std
#else
# define itksys_stl
#endif

/* Define the ios namespace macro.  */
#if itksys_IOS_HAVE_STD
# define itksys_ios_namespace std
#else
# define itksys_ios_namespace
#endif
#if itksys_IOS_USE_SSTREAM
# define itksys_ios itksys_ios_namespace
#else
# define itksys_ios itksys_ios
#endif

/* Define the ios::binary openmode macro.  */
#if itksys_IOS_HAVE_BINARY
# define itksys_ios_binary itksys_ios::ios::binary
#else
# define itksys_ios_binary 0
#endif

/* Whether the cstddef header is available.  */
#define itksys_CXX_HAS_CSTDDEF 1

/* Whether the compiler supports null template arguments.  */
#define itksys_CXX_HAS_NULL_TEMPLATE_ARGS 1

/* Define the null template arguments macro.  */
#if itksys_CXX_HAS_NULL_TEMPLATE_ARGS
# define itksys_CXX_NULL_TEMPLATE_ARGS <>
#else
# define itksys_CXX_NULL_TEMPLATE_ARGS
#endif

/* Whether the compiler supports member templates.  */
#define itksys_CXX_HAS_MEMBER_TEMPLATES 1

/* Whether the compiler supports argument dependent lookup.  */
#define itksys_CXX_HAS_ARGUMENT_DEPENDENT_LOOKUP 1

/* Whether the compiler supports standard full specialization syntax.  */
#define itksys_CXX_HAS_FULL_SPECIALIZATION 1

/* Define the specialization definition macro.  */
#if itksys_CXX_HAS_FULL_SPECIALIZATION
# define itksys_CXX_DEFINE_SPECIALIZATION template <>
#else
# define itksys_CXX_DEFINE_SPECIALIZATION
#endif

/* Define typename keyword macro for use in declarations.  */
#if defined(_MSC_VER) && _MSC_VER < 1300
# define itksys_CXX_DECL_TYPENAME
#else
# define itksys_CXX_DECL_TYPENAME typename
#endif

/* Whether the stl has iterator_traits.  */
#define itksys_STL_HAS_ITERATOR_TRAITS 1

/* Whether the stl has iterator_category.  */
#define itksys_STL_HAS_ITERATOR_CATEGORY 0

/* Whether the stl has __iterator_category.  */
#define itksys_STL_HAS___ITERATOR_CATEGORY 0

/* Whether the stl allocator is the standard template.  */
#define itksys_STL_HAS_ALLOCATOR_TEMPLATE 1

/* Whether the stl allocator is not a template.  */
#define itksys_STL_HAS_ALLOCATOR_NONTEMPLATE 0

/* Whether the stl allocator has rebind.  */
#define itksys_STL_HAS_ALLOCATOR_REBIND 1

/* Whether the stl allocator has a size argument for max_size.  */
#define itksys_STL_HAS_ALLOCATOR_MAX_SIZE_ARGUMENT 0

/* Whether the stl containers support allocator objects.  */
#define itksys_STL_HAS_ALLOCATOR_OBJECTS 1

/* Whether struct stat has the st_mtim member for high resolution times.  */
#define itksys_STAT_HAS_ST_MTIM 0

/* If building a C++ file in kwsys itself, give the source file
   access to the macros without a configured namespace.  */
#if defined(KWSYS_NAMESPACE)
# if !itksys_NAME_IS_KWSYS
#  define kwsys_stl itksys_stl
#  define kwsys_ios itksys_ios
#  define kwsys     itksys
#  define kwsys_ios_binary itksys_ios_binary
# endif
# define KWSYS_NAME_IS_KWSYS            itksys_NAME_IS_KWSYS
# define KWSYS_STL_HAVE_STD             itksys_STL_HAVE_STD
# define KWSYS_IOS_HAVE_STD             itksys_IOS_HAVE_STD
# define KWSYS_IOS_USE_ANSI             itksys_IOS_USE_ANSI
# define KWSYS_IOS_USE_SSTREAM          itksys_IOS_USE_SSTREAM
# define KWSYS_IOS_USE_STRSTREAM_H      itksys_IOS_USE_STRSTREAM_H
# define KWSYS_IOS_USE_STRSTREA_H       itksys_IOS_USE_STRSTREA_H
# define KWSYS_IOS_HAVE_BINARY          itksys_IOS_HAVE_BINARY
# define KWSYS_STAT_HAS_ST_MTIM         itksys_STAT_HAS_ST_MTIM
# define KWSYS_CXX_HAS_CSTDDEF          itksys_CXX_HAS_CSTDDEF
# define KWSYS_STL_STRING_HAVE_OSTREAM  itksys_STL_STRING_HAVE_OSTREAM
# define KWSYS_STL_STRING_HAVE_ISTREAM  itksys_STL_STRING_HAVE_ISTREAM
# define KWSYS_STL_STRING_HAVE_NEQ_CHAR itksys_STL_STRING_HAVE_NEQ_CHAR
# define KWSYS_CXX_NULL_TEMPLATE_ARGS   itksys_CXX_NULL_TEMPLATE_ARGS
# define KWSYS_CXX_HAS_MEMBER_TEMPLATES itksys_CXX_HAS_MEMBER_TEMPLATES
# define KWSYS_CXX_HAS_FULL_SPECIALIZATION itksys_CXX_HAS_FULL_SPECIALIZATION
# define KWSYS_CXX_DEFINE_SPECIALIZATION itksys_CXX_DEFINE_SPECIALIZATION
# define KWSYS_CXX_DECL_TYPENAME        itksys_CXX_DECL_TYPENAME
# define KWSYS_STL_HAS_ALLOCATOR_REBIND itksys_STL_HAS_ALLOCATOR_REBIND
# define KWSYS_STL_HAS_ALLOCATOR_MAX_SIZE_ARGUMENT itksys_STL_HAS_ALLOCATOR_MAX_SIZE_ARGUMENT
# define KWSYS_CXX_HAS_ARGUMENT_DEPENDENT_LOOKUP itksys_CXX_HAS_ARGUMENT_DEPENDENT_LOOKUP
# define KWSYS_STL_HAS_ITERATOR_TRAITS itksys_STL_HAS_ITERATOR_TRAITS
# define KWSYS_STL_HAS_ITERATOR_CATEGORY itksys_STL_HAS_ITERATOR_CATEGORY
# define KWSYS_STL_HAS___ITERATOR_CATEGORY itksys_STL_HAS___ITERATOR_CATEGORY
# define KWSYS_STL_HAS_ALLOCATOR_TEMPLATE itksys_STL_HAS_ALLOCATOR_TEMPLATE
# define KWSYS_STL_HAS_ALLOCATOR_NONTEMPLATE itksys_STL_HAS_ALLOCATOR_NONTEMPLATE
# define KWSYS_STL_HAS_ALLOCATOR_OBJECTS itksys_STL_HAS_ALLOCATOR_OBJECTS
# define KWSYS_STL_HAS_WSTRING          itksys_STL_HAS_WSTRING
#endif

#endif
