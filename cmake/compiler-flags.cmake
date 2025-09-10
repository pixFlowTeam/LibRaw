# LibRaw 编译器标志配置
# 基于 RawSpeed 的先进编译器配置

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 禁用模块扫描以避免 cmake-3.28 的问题
set(CMAKE_CXX_SCAN_FOR_MODULES NO)
set(CMAKE_CXX_MODULE_MAP_FORMAT "")

# 包含调试信息配置
include(debug-info)

# 根据构建类型设置宏定义
if(LIBRAW_RELEASE_BUILD)
  # Release 构建中不包含断言
  add_definitions(-DNDEBUG)
elseif(LIBRAW_RELEASEWITHASSERTS_BUILD)
  # ReleaseWithAsserts 构建中包含断言
  add_definitions(-UNDEBUG)
elseif(NOT (LIBRAW_FUZZ_BUILD))
  # 非 Release/ReleaseWithAsserts/Fuzz 构建，启用额外调试模式
  add_definitions(-UNDEBUG)
  add_definitions(-DDEBUG)
  add_definitions(-D_GLIBCXX_SANITIZE_VECTOR)
endif()

# 设置符号可见性
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)

# 设置链接器标志
IF(NOT APPLE AND NOT WIN32)
  set(linkerflags "-Wl,--as-needed")
ELSE()
  set(linkerflags "")
ENDIF()

SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${linkerflags}")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${linkerflags}")
SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${linkerflags}")

# LTO 支持
if(LIBRAW_ENABLE_LTO)
  if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    include(llvm-toolchain)
    set(lto_compile "-flto=thin -fforce-emit-vtables -fwhole-program-vtables -fstrict-vtable-pointers")
    set(lto_link "-flto=thin -fuse-ld=\"${LLVMLLD_EXECUTABLE}\" ${LLVMLLD_INCREMENTAL_LDFLAGS}")
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    include(gcc-toolchain)
    set(lto_compile "-flto")
    set(lto_link "-flto")
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    set(lto_compile "-flto=thin -fstrict-vtable-pointers")
    set(lto_link "-flto=thin")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${lto_compile}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${lto_compile}")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${lto_link}")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${lto_link}")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${lto_link}")
endif()

# 调试构建标志
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0")

# 代码覆盖率支持
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(coverage_compilation "-fprofile-instr-generate=\"default-%m-%p.profraw\" -fcoverage-mapping")
  set(coverage_link "")
elseif(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  set(coverage_compilation "-fprofile-arcs -ftest-coverage")
  if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    set(coverage_link "--coverage")
  endif()
endif()

SET(CMAKE_CXX_FLAGS_COVERAGE "${coverage_compilation}" CACHE STRING "Flags used by the C++ compiler during coverage builds." FORCE)
SET(CMAKE_C_FLAGS_COVERAGE "${coverage_compilation}" CACHE STRING "Flags used by the C compiler during coverage builds." FORCE)
SET(CMAKE_EXE_LINKER_FLAGS_COVERAGE "${coverage_compilation} ${coverage_link}" CACHE STRING "Flags used for linking binaries during coverage builds." FORCE)
SET(CMAKE_SHARED_LINKER_FLAGS_COVERAGE "${coverage_compilation} ${coverage_link}" CACHE STRING "Flags used by the shared libraries linker during coverage builds." FORCE)
SET(CMAKE_MODULE_LINKER_FLAGS_COVERAGE "${coverage_compilation} ${coverage_link}" CACHE STRING "Flags used by the module linker during coverage builds." FORCE)

# 内存安全工具支持
set(SANITIZATION_DEFAULTS "-O3 -fno-optimize-sibling-calls")

set(asan "-fsanitize=address -fno-omit-frame-pointer -fno-common -U_FORTIFY_SOURCE")
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(asan "${asan} -fsanitize-address-use-after-scope")
endif()

set(ubsan "-fsanitize=undefined -fno-sanitize-recover=undefined")
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(ubsan "${ubsan} -fsanitize=integer -fno-sanitize-recover=integer -fno-sanitize=unsigned-shift-base")
endif()

SET(CMAKE_CXX_FLAGS_SANITIZE "${SANITIZATION_DEFAULTS} ${asan} ${ubsan}" CACHE STRING "Flags used by the C++ compiler during sanitized (ASAN+UBSAN) builds." FORCE)
SET(CMAKE_C_FLAGS_SANITIZE "${SANITIZATION_DEFAULTS} ${asan} ${ubsan}" CACHE STRING "Flags used by the C compiler during sanitized (ASAN+UBSAN) builds." FORCE)

# Fuzzing 支持
set(fuzz "-O3 -ffast-math")
if(NOT LIB_FUZZING_ENGINE)
  set(fuzz "${fuzz} ${asan} ${ubsan}")
  set(fuzz "${fuzz} -fsanitize=fuzzer-no-link")
else()
  message(STATUS "LIB_FUZZING_ENGINE override option is passed, not setting special compiler flags.")
endif()

set(fuzz "${fuzz} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION")
set(fuzz "${fuzz} -ffunction-sections -fdata-sections")
set(fuzz_link "-Wl,--gc-sections")

SET(CMAKE_CXX_FLAGS_FUZZ "${fuzz}" CACHE STRING "Flags used by the C++ compiler during FUZZ builds." FORCE)
SET(CMAKE_C_FLAGS_FUZZ "${fuzz}" CACHE STRING "Flags used by the C compiler during FUZZ builds." FORCE)
SET(CMAKE_EXE_LINKER_FLAGS_FUZZ "${fuzz} ${fuzz_link}" CACHE STRING "Flags used for linking binaries during FUZZ builds." FORCE)
SET(CMAKE_SHARED_LINKER_FLAGS_FUZZ "${fuzz} ${fuzz_link}" CACHE STRING "Flags used by the shared libraries linker during FUZZ builds." FORCE)
SET(CMAKE_MODULE_LINKER_FLAGS_FUZZ "${fuzz} ${fuzz_link}" CACHE STRING "Flags used by the module linker during FUZZ builds." FORCE)

# ThreadSanitizer 支持
set(tsan "${SANITIZATION_DEFAULTS} -fsanitize=thread")
SET(CMAKE_CXX_FLAGS_TSAN "${tsan}" CACHE STRING "Flags used by the C++ compiler during TSAN builds." FORCE)
SET(CMAKE_C_FLAGS_TSAN "${tsan}" CACHE STRING "Flags used by the C compiler during TSAN builds." FORCE)

# Release 构建优化
set(CMAKE_C_FLAGS_RELEASEWITHASSERTS "${CMAKE_C_FLAGS_RELEASEWITHASSERTS} -O3")
set(CMAKE_CXX_FLAGS_RELEASEWITHASSERTS "${CMAKE_CXX_FLAGS_RELEASEWITHASSERTS} -O3")

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

