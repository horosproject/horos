//:
// \file
// \author Tim Cootes/Bill Hoffman
// \brief Allows cmake to set up macro giving name of VXL source root directory

// Note: The make system (eg cmake) should generate a file, vcl_where_root_dir.h, from
// this, in which the macro is set correctly.
// For non-cmake systems this might cause a problem.  In particular if there is
// no vcl_where_root_dir.h, some other stuff might not compile.
// If we supply a default vcl_where_root_dir.h, it would be changed by cmake, and
// may get checked back into the repository by accident.

#ifndef __vcl_where_root_dir_h_
#define __vcl_where_root_dir_h_
#ifndef VCL_SOURCE_ROOT_DIR // file guard
#define VCL_SOURCE_ROOT_DIR "/Users/lxiv/Downloads/source/ITK/Modules/ThirdParty/VNL/src/vxl"
#endif
#endif // __vcl_where_root_dir_h_
