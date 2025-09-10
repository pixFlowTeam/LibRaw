# LibRaw 编译器警告配置
# 基于 RawSpeed 的先进警告系统

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/CheckCXXCompilerFlagAndEnableIt.cmake)

# 根据编译器类型包含特定的警告配置
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  include(compiler-warnings-gcc)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  include(compiler-warnings-clang)
endif()

# Windows 平台特殊处理
if(NOT (UNIX OR APPLE))
  # 在 Windows 上禁用格式警告，避免误报
  CHECK_CXX_COMPILER_FLAG_AND_ENABLE_IT(-Wno-format)
endif()

# 非特殊构建的栈使用限制
if(NOT LIBRAW_SPECIAL_BUILD)
  # 栈使用应该小于 64KB
  math(EXPR MAX_MEANINGFUL_SIZE 4*1024)
  CHECK_CXX_COMPILER_FLAG_AND_ENABLE_IT(-Wstack-usage=${MAX_MEANINGFUL_SIZE})
  CHECK_CXX_COMPILER_FLAG_AND_ENABLE_IT(-Wframe-larger-than=${MAX_MEANINGFUL_SIZE})

  # 函数大小限制，1MB+ 是可以接受的
  math(EXPR MAX_MEANINGFUL_SIZE 32*1024)
  CHECK_CXX_COMPILER_FLAG_AND_ENABLE_IT(-Wlarger-than=${MAX_MEANINGFUL_SIZE})
endif()
