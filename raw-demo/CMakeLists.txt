cmake_minimum_required(VERSION 3.16)
project(raw_processor)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 查找OpenCV
find_package(OpenCV REQUIRED)
if(OpenCV_FOUND)
    message(STATUS "OpenCV version: ${OpenCV_VERSION}")
    message(STATUS "OpenCV include dirs: ${OpenCV_INCLUDE_DIRS}")
    message(STATUS "OpenCV libraries: ${OpenCV_LIBS}")
else()
    message(FATAL_ERROR "OpenCV not found")
endif()

# 设置LibRaw路径
set(LIBRAW_ROOT_DIR "/Users/fuguoqiang/Desktop/bridge/构建/LibRaw")
set(LIBRAW_INCLUDE_DIR "${LIBRAW_ROOT_DIR}/libraw")
set(LIBRAW_LIBRARY_DIR "${LIBRAW_ROOT_DIR}/build/macos-arm64/lib")

# 包含目录
include_directories(${LIBRAW_ROOT_DIR})
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

# 源文件
set(SOURCES
    src/raw_processor.cpp
    src/main.cpp
)

# 创建可执行文件
add_executable(raw_processor ${SOURCES})

# 链接库
target_link_libraries(raw_processor 
    ${LIBRAW_LIBRARY_DIR}/liblibraw.a
    ${OpenCV_LIBS}
)

# 编译选项
target_compile_options(raw_processor PRIVATE
    -O3
    -Wall
    -Wextra
)

# 设置RPATH
set_target_properties(raw_processor PROPERTIES
    INSTALL_RPATH_USE_LINK_PATH TRUE
    INSTALL_RPATH "${LIBRAW_LIBRARY_DIR}"
)
