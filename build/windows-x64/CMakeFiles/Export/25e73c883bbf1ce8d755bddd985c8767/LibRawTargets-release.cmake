#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "LibRaw::libraw" for configuration "Release"
set_property(TARGET LibRaw::libraw APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(LibRaw::libraw PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/liblibraw.a"
  )

list(APPEND _cmake_import_check_targets LibRaw::libraw )
list(APPEND _cmake_import_check_files_for_LibRaw::libraw "${_IMPORT_PREFIX}/lib/liblibraw.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
