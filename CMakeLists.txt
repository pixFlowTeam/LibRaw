cmake_minimum_required(VERSION 3.22)

cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0025 NEW)
cmake_policy(SET CMP0067 NEW)

# 避免源码树污染
set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not permitted. Make a separate folder for building:\nmkdir build; cd build; cmake ..\nBefore that, remove the files already created:\nrm -rf CMakeCache.txt CMakeFiles")
endif()

project(LibRaw VERSION 0.21.4 LANGUAGES C CXX)

include(FeatureSummary)
include(GNUInstallDirs)

# 设置模块路径
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/" ${CMAKE_MODULE_PATH})

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# 构建选项
option(BINARY_PACKAGE_BUILD "Sets march optimization to generic" OFF)
option(LIBRAW_ENABLE_DEBUG_INFO "Whether to generate debug info or not." ON)
option(LIBRAW_ENABLE_WERROR "Stop and fail the build, if a compiler warning is triggered." ON)
option(LIBRAW_ENABLE_LTO "Add appropriate flag to the compile and link command lines, enabling link-time optimization." OFF)
option(BUILD_EXAMPLES "Build example programs" ON)
option(BUILD_TESTING "Build the testing tree." OFF)
option(BUILD_DOCS "Build the documentation." OFF)

# 包含构建配置
include(build-type)
include(compiler-flags)
include(compiler-warnings)

# 包含目录
include_directories(.)
include_directories(libraw)
include_directories(internal)

# 源文件列表
set(LIBRAW_SOURCES
    src/libraw_c_api.cpp
    src/libraw_datastream.cpp
    src/decoders/canon_600.cpp
    src/decoders/crx.cpp
    src/decoders/pana8.cpp
    src/decoders/decoders_dcraw.cpp
    src/decoders/sonycc.cpp
    src/decompressors/losslessjpeg.cpp
    src/decoders/decoders_libraw_dcrdefs.cpp
    src/decoders/olympus14.cpp
    src/decoders/decoders_libraw.cpp
    src/decoders/dng.cpp
    src/decoders/fp_dng.cpp
    src/decoders/fuji_compressed.cpp
    src/decoders/generic.cpp
    src/decoders/kodak_decoders.cpp
    src/decoders/load_mfbacks.cpp
    src/decoders/smal.cpp
    src/decoders/unpack_thumb.cpp
    src/decoders/unpack.cpp
    src/demosaic/aahd_demosaic.cpp
    src/demosaic/ahd_demosaic.cpp
    src/demosaic/dcb_demosaic.cpp
    src/demosaic/dht_demosaic.cpp
    src/demosaic/misc_demosaic.cpp
    src/demosaic/xtrans_demosaic.cpp
    src/integration/dngsdk_glue.cpp
    src/integration/rawspeed_glue.cpp
    src/metadata/adobepano.cpp
    src/metadata/canon.cpp
    src/metadata/ciff.cpp
    src/metadata/cr3_parser.cpp
    src/metadata/epson.cpp
    src/metadata/exif_gps.cpp
    src/metadata/fuji.cpp
    src/metadata/identify_tools.cpp
    src/metadata/identify.cpp
    src/metadata/kodak.cpp
    src/metadata/leica.cpp
    src/metadata/makernotes.cpp
    src/metadata/mediumformat.cpp
    src/metadata/minolta.cpp
    src/metadata/misc_parsers.cpp
    src/metadata/nikon.cpp
    src/metadata/normalize_model.cpp
    src/metadata/olympus.cpp
    src/metadata/hasselblad_model.cpp
    src/metadata/p1.cpp
    src/metadata/pentax.cpp
    src/metadata/samsung.cpp
    src/metadata/sony.cpp
    src/metadata/tiff.cpp
    src/postprocessing/aspect_ratio.cpp
    src/postprocessing/dcraw_process.cpp
    src/postprocessing/mem_image.cpp
    src/postprocessing/postprocessing_aux.cpp
    src/postprocessing/postprocessing_utils_dcrdefs.cpp
    src/postprocessing/postprocessing_utils.cpp
    src/preprocessing/ext_preprocess.cpp
    src/preprocessing/raw2image.cpp
    src/preprocessing/subtract_black.cpp
    src/tables/cameralist.cpp
    src/tables/colorconst.cpp
    src/tables/colordata.cpp
    src/tables/wblists.cpp
    src/utils/curves.cpp
    src/utils/decoder_info.cpp
    src/utils/init_close_utils.cpp
    src/utils/open.cpp
    src/utils/phaseone_processing.cpp
    src/utils/read_utils.cpp
    src/utils/thumb_utils.cpp
    src/utils/utils_dcraw.cpp
    src/utils/utils_libraw.cpp
    src/write/apply_profile.cpp
    src/write/file_write.cpp
    src/write/tiff_writer.cpp
    src/x3f/x3f_parse_process.cpp
    src/x3f/x3f_utils_patched.cpp
)

# 头文件
set(LIBRAW_HEADERS
    libraw/libraw.h
    libraw/libraw_alloc.h
    libraw/libraw_const.h
    libraw/libraw_datastream.h
    libraw/libraw_internal.h
    libraw/libraw_types.h
    libraw/libraw_version.h
)

# 创建静态库
add_library(libraw STATIC ${LIBRAW_SOURCES})

# 设置目标属性
target_include_directories(libraw PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libraw>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/internal>
    $<INSTALL_INTERFACE:include/libraw>
)

target_compile_definitions(libraw PRIVATE LIBRAW_NOTHREADS)

# 设置输出目录
set_target_properties(libraw PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# 安装头文件
install(FILES ${LIBRAW_HEADERS} DESTINATION include/libraw)

# 安装库文件
install(TARGETS libraw
    EXPORT LibRawTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# 创建导出文件
install(EXPORT LibRawTargets
    FILE LibRawTargets.cmake
    NAMESPACE LibRaw::
    DESTINATION lib/cmake/LibRaw
)

# 示例程序
if(BUILD_EXAMPLES)
    # C++示例程序
    set(CPP_SAMPLES
        raw-identify
        unprocessed_raw
        4channels
        rawtextdump
        simple_dcraw
        multirender_test
        postprocessing_benchmark
        mem_image_sample
        dcraw_emu
    )
    
    foreach(sample ${CPP_SAMPLES})
        add_executable(${sample} samples/${sample}.cpp)
        target_link_libraries(${sample} libraw)
        target_compile_definitions(${sample} PRIVATE LIBRAW_NOTHREADS)
        
        # 设置输出目录
        set_target_properties(${sample} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
        )
        
        install(TARGETS ${sample} DESTINATION bin)
    endforeach()
    
    # C示例程序
    add_executable(dcraw_half samples/dcraw_half.c)
    target_link_libraries(dcraw_half libraw)
    target_compile_definitions(dcraw_half PRIVATE LIBRAW_NOTHREADS)
    
    # 设置输出目录
    set_target_properties(dcraw_half PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    )
    
    install(TARGETS dcraw_half DESTINATION bin)
endif()

# 创建pkg-config文件
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/libraw.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/libraw.pc
    @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libraw.pc DESTINATION lib/pkgconfig)