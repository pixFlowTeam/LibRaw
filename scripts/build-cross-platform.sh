#!/bin/bash

# LibRaw 跨平台构建脚本 (标准命名版)
# 支持 x86_64-w64-mingw32 和 aarch64-apple-darwin

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查工具链
check_toolchain() {
    local target=$1
    case $target in
        "windows-x86_64")
            if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
                log_error "x86_64-w64-mingw32-gcc not found. Please install MinGW-w64"
                exit 1
            fi
            if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
                log_error "x86_64-w64-mingw32-g++ not found. Please install MinGW-w64"
                exit 1
            fi
            ;;
        "macos-arm64")
            if ! command -v clang &> /dev/null; then
                log_error "clang not found. Please install Xcode Command Line Tools"
                exit 1
            fi
            ;;
    esac
}

# 构建函数
build_for_target() {
    local target=$1
    local build_dir="build/${target}"
    
    log_info "Building for target: $target"
    
    # 检查工具链
    check_toolchain $target
    
    # 创建构建目录
    mkdir -p $build_dir
    cd $build_dir
    
    case $target in
        "windows-x86_64")
            build_windows
            ;;
        "macos-arm64")
            build_macos_arm64
            ;;
        *)
            log_error "Unsupported target: $target"
            exit 1
            ;;
    esac
    
    cd ../..
    log_info "Build completed for $target"
}

# Windows MinGW构建
build_windows() {
    log_info "Building for Windows (MinGW)"
    
    # 设置环境变量
    export CC=x86_64-w64-mingw32-gcc
    export CXX=x86_64-w64-mingw32-g++
    export AR=x86_64-w64-mingw32-ar
    export RANLIB=x86_64-w64-mingw32-ranlib
    export STRIP=x86_64-w64-mingw32-strip
    
    # 配置编译选项
    CFLAGS="-O3 -I. -w -static-libgcc -static-libstdc++"
    CXXFLAGS="-O3 -I. -w -static-libgcc -static-libstdc++"
    LDFLAGS="-static-libgcc -static-libstdc++ -lws2_32 -lm"
    
    # 复制源文件
    cp -r ../../src .
    cp -r ../../libraw .
    cp -r ../../internal .
    cp -r ../../samples .
    mkdir -p lib bin object
    
    # 编译静态库
    log_info "Compiling static library..."
    
    # 编译所有源文件（排除占位符文件）
    for src_file in src/*.cpp src/decoders/*.cpp src/decompressors/*.cpp src/demosaic/*.cpp \
                   src/integration/*.cpp src/metadata/*.cpp src/postprocessing/*.cpp \
                   src/preprocessing/*.cpp src/tables/*.cpp src/utils/*.cpp src/write/*.cpp \
                   src/x3f/*.cpp; do
        if [ -f "$src_file" ] && [[ ! "$src_file" =~ _ph\.cpp$ ]]; then
            obj_file="object/$(basename ${src_file%.cpp}).o"
            $CXX -c -DLIBRAW_NOTHREADS $CXXFLAGS -o "$obj_file" "$src_file"
        fi
    done
    
    # 创建静态库
    $AR crv lib/libraw.a object/*.o
    $RANLIB lib/libraw.a
    
    # 编译示例程序
    log_info "Compiling sample programs..."
    for sample in raw-identify unprocessed_raw 4channels rawtextdump simple_dcraw \
                  multirender_test postprocessing_benchmark mem_image dcraw_emu; do
        if [ -f "samples/${sample}.cpp" ]; then
            $CXX -DLIBRAW_NOTHREADS $CXXFLAGS -o "bin/${sample}.exe" \
                 "samples/${sample}.cpp" -L./lib -lraw $LDFLAGS
        fi
    done
    
    # 编译C示例
    if [ -f "samples/dcraw_half.c" ]; then
        $CC -c -DLIBRAW_NOTHREADS $CFLAGS -o object/dcraw_half.o samples/dcraw_half.c
        $CC -DLIBRAW_NOTHREADS $CFLAGS -o bin/dcraw_half.exe object/dcraw_half.o \
            -L./lib -lraw $LDFLAGS -lstdc++
    fi
    
    log_info "Windows build completed"
}

# macOS ARM64构建
build_macos_arm64() {
    log_info "Building for macOS ARM64"
    
    # 设置环境变量
    export CC=clang
    export CXX=clang++
    export AR=ar
    export RANLIB=ranlib
    export STRIP=strip
    
    # 配置编译选项
    CFLAGS="-O3 -I. -w -arch arm64 -mmacosx-version-min=11.0"
    CXXFLAGS="-O3 -I. -w -arch arm64 -mmacosx-version-min=11.0"
    LDFLAGS="-arch arm64 -mmacosx-version-min=11.0 -lm"
    
    # 复制源文件
    cp -r ../../src .
    cp -r ../../libraw .
    cp -r ../../internal .
    cp -r ../../samples .
    mkdir -p lib bin object
    
    # 编译静态库
    log_info "Compiling static library..."
    
    # 编译所有源文件（排除占位符文件）
    for src_file in src/*.cpp src/decoders/*.cpp src/decompressors/*.cpp src/demosaic/*.cpp \
                   src/integration/*.cpp src/metadata/*.cpp src/postprocessing/*.cpp \
                   src/preprocessing/*.cpp src/tables/*.cpp src/utils/*.cpp src/write/*.cpp \
                   src/x3f/*.cpp; do
        if [ -f "$src_file" ] && [[ ! "$src_file" =~ _ph\.cpp$ ]]; then
            obj_file="object/$(basename ${src_file%.cpp}).o"
            $CXX -c -DLIBRAW_NOTHREADS $CXXFLAGS -o "$obj_file" "$src_file"
        fi
    done
    
    # 创建静态库
    $AR crv lib/libraw.a object/*.o
    $RANLIB lib/libraw.a
    
    # 编译示例程序
    log_info "Compiling sample programs..."
    for sample in raw-identify unprocessed_raw 4channels rawtextdump simple_dcraw \
                  multirender_test postprocessing_benchmark mem_image dcraw_emu; do
        if [ -f "samples/${sample}.cpp" ]; then
            $CXX -DLIBRAW_NOTHREADS $CXXFLAGS -o "bin/${sample}" \
                 "samples/${sample}.cpp" -L./lib -lraw $LDFLAGS
        fi
    done
    
    # 编译C示例
    if [ -f "samples/dcraw_half.c" ]; then
        $CC -c -DLIBRAW_NOTHREADS $CFLAGS -o object/dcraw_half.o samples/dcraw_half.c
        $CC -DLIBRAW_NOTHREADS $CFLAGS -o bin/dcraw_half object/dcraw_half.o \
            -L./lib -lraw $LDFLAGS -lstdc++
    fi
    
    log_info "macOS ARM64 build completed"
}

# 清理函数
clean() {
    log_info "Cleaning build directories..."
    rm -rf build/
    log_info "Clean completed"
}

# 主函数
main() {
    case "${1:-all}" in
        "windows"|"windows-x86_64")
            build_for_target "windows-x86_64"
            ;;
        "macos"|"macos-arm64")
            build_for_target "macos-arm64"
            ;;
        "all")
            build_for_target "windows-x86_64"
            build_for_target "macos-arm64"
            ;;
        "clean")
            clean
            ;;
        *)
            echo "Usage: $0 {windows|macos|all|clean}"
            echo "  windows: Build for Windows x86_64"
            echo "  macos:   Build for macOS ARM64"
            echo "  all:     Build for both platforms"
            echo "  clean:   Clean build directories"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
