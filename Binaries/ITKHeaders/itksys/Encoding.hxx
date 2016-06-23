/*============================================================================
  KWSys - Kitware System Library
  Copyright 2000-2009 Kitware, Inc., Insight Software Consortium

  Distributed under the OSI-approved BSD License (the "License");
  see accompanying file Copyright.txt for details.

  This software is distributed WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the License for more information.
============================================================================*/
#ifndef itksys_Encoding_hxx
#define itksys_Encoding_hxx

#include <itksys/Configure.hxx>
#include <itksys/stl/string>
#include <itksys/stl/vector>

/* Define these macros temporarily to keep the code readable.  */
#if !defined (KWSYS_NAMESPACE) && !itksys_NAME_IS_KWSYS
# define kwsys_stl itksys_stl
#endif

namespace itksys
{
class itksys_EXPORT Encoding
{
public:

  // Container class for argc/argv.
  class CommandLineArguments
  {
    public:
      // On Windows, get the program command line arguments
      // in this Encoding module's 8 bit encoding.
      // On other platforms the given argc/argv is used, and
      // to be consistent, should be the argc/argv from main().
      static CommandLineArguments Main(int argc, char const* const* argv);

      // Construct CommandLineArguments with the given
      // argc/argv.  It is assumed that the string is already
      // in the encoding used by this module.
      CommandLineArguments(int argc, char const* const* argv);

      // Construct CommandLineArguments with the given
      // argc and wide argv.  This is useful if wmain() is used.
      CommandLineArguments(int argc, wchar_t const* const* argv);
      ~CommandLineArguments();
      CommandLineArguments(const CommandLineArguments&);
      CommandLineArguments& operator=(const CommandLineArguments&);

      int argc() const;
      char const* const* argv() const;

    protected:
      std::vector<char*> argv_;
  };

  /**
   * Convert between char and wchar_t
   */

#if itksys_STL_HAS_WSTRING

  // Convert a narrow string to a wide string.
  // On Windows, UTF-8 is assumed, and on other platforms,
  // the current locale is assumed.
  static kwsys_stl::wstring ToWide(const kwsys_stl::string& str);
  static kwsys_stl::wstring ToWide(const char* str);

  // Convert a wide string to a narrow string.
  // On Windows, UTF-8 is assumed, and on other platforms,
  // the current locale is assumed.
  static kwsys_stl::string ToNarrow(const kwsys_stl::wstring& str);
  static kwsys_stl::string ToNarrow(const wchar_t* str);

#endif // itksys_STL_HAS_WSTRING

}; // class Encoding
} // namespace itksys

/* Undefine temporary macros.  */
#if !defined (KWSYS_NAMESPACE) && !itksys_NAME_IS_KWSYS
# undef kwsys_stl
#endif

#endif
