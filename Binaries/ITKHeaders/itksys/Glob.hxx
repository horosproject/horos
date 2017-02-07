/*============================================================================
  KWSys - Kitware System Library
  Copyright 2000-2009 Kitware, Inc., Insight Software Consortium

  Distributed under the OSI-approved BSD License (the "License");
  see accompanying file Copyright.txt for details.

  This software is distributed WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the License for more information.
============================================================================*/
#ifndef itksys_Glob_hxx
#define itksys_Glob_hxx

#include <itksys/Configure.h>
#include <itksys/Configure.hxx>

#include <itksys/stl/string>
#include <itksys/stl/vector>

/* Define this macro temporarily to keep the code readable.  */
#if !defined (KWSYS_NAMESPACE) && !itksys_NAME_IS_KWSYS
# define kwsys_stl itksys_stl
#endif

namespace itksys
{

class GlobInternals;

/** \class Glob
 * \brief Portable globbing searches.
 *
 * Globbing expressions are much simpler than regular
 * expressions. This class will search for files using
 * globbing expressions.
 *
 * Finds all files that match a given globbing expression.
 */
class itksys_EXPORT Glob
{
public:
  Glob();
  ~Glob();

  //! Find all files that match the pattern.
  bool FindFiles(const kwsys_stl::string& inexpr);

  //! Return the list of files that matched.
  kwsys_stl::vector<kwsys_stl::string>& GetFiles();

  //! Set recurse to true to match subdirectories.
  void RecurseOn() { this->SetRecurse(true); }
  void RecurseOff() { this->SetRecurse(false); }
  void SetRecurse(bool i) { this->Recurse = i; }
  bool GetRecurse() { return this->Recurse; }

  //! Set recurse through symlinks to true if recursion should traverse the
  // linked-to directories
  void RecurseThroughSymlinksOn() { this->SetRecurseThroughSymlinks(true); }
  void RecurseThroughSymlinksOff() { this->SetRecurseThroughSymlinks(false); }
  void SetRecurseThroughSymlinks(bool i) { this->RecurseThroughSymlinks = i; }
  bool GetRecurseThroughSymlinks() { return this->RecurseThroughSymlinks; }

  //! Get the number of symlinks followed through recursion
  unsigned int GetFollowedSymlinkCount() { return this->FollowedSymlinkCount; }

  //! Set relative to true to only show relative path to files.
  void SetRelative(const char* dir);
  const char* GetRelative();

  /** Convert the given globbing pattern to a regular expression.
      There is no way to quote meta-characters.  The
      require_whole_string argument specifies whether the regex is
      automatically surrounded by "^" and "$" to match the whole
      string.  This is on by default because patterns always match
      whole strings, but may be disabled to support concatenating
      expressions more easily (regex1|regex2|etc).  */
  static kwsys_stl::string PatternToRegex(const kwsys_stl::string& pattern,
                                          bool require_whole_string = true,
                                          bool preserve_case = false);

protected:
  //! Process directory
  void ProcessDirectory(kwsys_stl::string::size_type start,
    const kwsys_stl::string& dir);

  //! Process last directory, but only when recurse flags is on. That is
  // effectively like saying: /path/to/file/**/file
  void RecurseDirectory(kwsys_stl::string::size_type start,
    const kwsys_stl::string& dir);

  //! Add regular expression
  void AddExpression(const kwsys_stl::string& expr);

  //! Add a file to the list
  void AddFile(kwsys_stl::vector<kwsys_stl::string>& files, const kwsys_stl::string& file);

  GlobInternals* Internals;
  bool Recurse;
  kwsys_stl::string Relative;
  bool RecurseThroughSymlinks;
  unsigned int FollowedSymlinkCount;

private:
  Glob(const Glob&);  // Not implemented.
  void operator=(const Glob&);  // Not implemented.
};

} // namespace itksys

/* Undefine temporary macro.  */
#if !defined (KWSYS_NAMESPACE) && !itksys_NAME_IS_KWSYS
# undef kwsys_stl
#endif

#endif
