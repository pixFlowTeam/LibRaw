cmake_minimum_required(VERSION 3.16)
project(LibRaw VERSION 0.21.4 LANGUAGES C CXX)

# 设置C++标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -w")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -w")

# 平台特定设置
if(WIN32)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libgcc -static-libstdc++")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++ -lws2_32 -lm")
elseif(APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -arch arm64 -mmacosx-version-min=11.0")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -arch arm64 -mmacosx-version-min=11.0")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -arch arm64 -mmacosx-version-min=11.0 -lm")
endif()

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
add_library(libraw STATIC ${LIBRAW_SOURCES} ${LIBRAW_HEADERS})

# 设置编译定义
target_compile_definitions(libraw PRIVATE LIBRAW_NOTHREADS)

# 安装头文件
install(FILES ${LIBRAW_HEADERS} DESTINATION include/libraw)

# 安装库文件
install(TARGETS libraw DESTINATION lib)

# 示例程序
option(BUILD_EXAMPLES "Build example programs" ON)

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
        mem_image
        dcraw_emu
    )
    
    foreach(sample ${CPP_SAMPLES})
        add_executable(${sample} samples/${sample}.cpp)
        target_link_libraries(${sample} libraw)
        target_compile_definitions(${sample} PRIVATE LIBRAW_NOTHREADS)
        install(TARGETS ${sample} DESTINATION bin)
    endforeach()
    
    # C示例程序
    add_executable(dcraw_half samples/dcraw_half.c)
    target_link_libraries(dcraw_half libraw)
    target_compile_definitions(dcraw_half PRIVATE LIBRAW_NOTHREADS)
    install(TARGETS dcraw_half DESTINATION bin)
endif()

# 创建pkg-config文件
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/libraw.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/libraw.pc
    @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libraw.pc DESTINATION lib/pkgconfig)
