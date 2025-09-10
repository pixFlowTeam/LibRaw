# CheckCXXCompilerFlagAndEnableIt.cmake
# 检查C++编译器标志并启用它

include(CheckCXXCompilerFlag)

function(CHECK_CXX_COMPILER_FLAG_AND_ENABLE_IT flag)
    string(TOUPPER "HAVE_${flag}" var)
    string(REGEX REPLACE "^-" "" var "${var}")
    string(REGEX REPLACE "^-" "" var "${var}")
    string(REGEX REPLACE "[^A-Za-z0-9_]" "_" var "${var}")
    
    CHECK_CXX_COMPILER_FLAG("${flag}" ${var})
    if(${var})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}" PARENT_SCOPE)
    endif()
endfunction()

