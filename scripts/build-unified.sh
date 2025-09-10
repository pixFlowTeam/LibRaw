#!/bin/bash

# LibRaw 统一构建脚本
# 基于 RawSpeed 的先进构建系统

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "LibRaw 统一构建脚本"
    echo ""
    echo "用法: $0 [选项] <平台>"
    echo ""
    echo "平台:"
    echo "  windows-x64            Windows x64 (x86_64-w64-mingw32)"
    echo "  macos-arm64            macOS ARM64 (aarch64-apple-darwin)"
    echo "  macos-x64              macOS x64 (x86_64-apple-darwin)"
    echo "  linux-x64              Linux x64 (native)"
    echo "  all                    构建所有平台"
    echo ""
    echo "选项:"
    echo "  -h, --help             显示此帮助信息"
    echo "  -c, --clean            清理构建目录"
    echo "  -j, --jobs N           并行编译任务数 (默认: 4)"
    echo "  -v, --verbose          详细输出"
    echo "  --release              发布构建 (默认)"
    echo "  --debug                调试构建"
    echo "  --coverage             代码覆盖率构建"
    echo "  --sanitize             内存安全工具构建"
    echo "  --fuzz                 模糊测试构建"
    echo ""
    echo "示例:"
    echo "  $0 windows-x64"
    echo "  $0 macos-arm64 --clean"
    echo "  $0 linux-x64 --jobs 8 --debug"
    echo "  $0 windows-x64 --verbose --coverage"
}

# 默认参数
TARGET_PLATFORM=""
CLEAN_BUILD=false
JOBS=4
VERBOSE=false
BUILD_TYPE="Release"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --coverage)
            BUILD_TYPE="Coverage"
            shift
            ;;
        --sanitize)
            BUILD_TYPE="Sanitize"
            shift
            ;;
        --fuzz)
            BUILD_TYPE="Fuzz"
            shift
            ;;
        windows-x64|macos-arm64|macos-x64|linux-x64|all)
            TARGET_PLATFORM="$1"
            shift
            ;;
        *)
            print_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查目标平台
if [[ -z "$TARGET_PLATFORM" ]]; then
    print_error "请指定目标平台"
    show_help
    exit 1
fi

# 构建单个平台的函数
build_platform() {
    local platform="$1"
    local original_platform="$TARGET_PLATFORM"
    
    print_info "=========================================="
    print_info "开始构建平台: $platform"
    print_info "=========================================="
    
    # 临时设置目标平台
    TARGET_PLATFORM="$platform"
    
    # 获取构建目录
    BUILD_DIR="$PROJECT_ROOT/$(get_build_dir "$platform")"
    
    # 清理构建目录
    if [[ "$CLEAN_BUILD" == true ]]; then
        print_info "清理构建目录: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi
    
    # 创建构建目录
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # 根据平台设置 CMake 参数
    case "$platform" in
        windows-x64)
            print_info "配置 Windows x64 构建..."
            
            # 检查 MinGW-w64
            if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
                print_error "未找到 x86_64-w64-mingw32-gcc，请安装 MinGW-w64"
                print_info "在 macOS 上: brew install mingw-w64"
                print_info "在 Ubuntu 上: sudo apt-get install gcc-mingw-w64-x86-64"
                return 1
            fi
            
            CMAKE_ARGS=(
                -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/x86_64-w64-mingw32.cmake"
                -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
                -DBINARY_PACKAGE_BUILD=ON
                -DLIBRAW_ENABLE_WERROR=OFF
                -DCMAKE_CXX_FLAGS="-w -O2 -D_GNU_SOURCE -D_USE_MATH_DEFINES -DWIN32"
                -DCMAKE_C_FLAGS="-w -O2 -D_GNU_SOURCE -D_USE_MATH_DEFINES -DWIN32"
                -DCMAKE_EXE_LINKER_FLAGS="-lws2_32 -lwsock32 -lmswsock"
                -DBUILD_EXAMPLES=OFF
                -DBUILD_TESTING=OFF
                -DBUILD_DOCS=OFF
            )
            ;;
            
        macos-arm64)
            print_info "配置 macOS ARM64 构建..."
            
            # 检查 Xcode
            if ! command -v clang &> /dev/null; then
                print_error "未找到 clang，请安装 Xcode Command Line Tools"
                print_info "运行: xcode-select --install"
                return 1
            fi
            
            CMAKE_ARGS=(
                -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/aarch64-apple-darwin.cmake"
                -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
                -DBINARY_PACKAGE_BUILD=ON
                -DLIBRAW_ENABLE_WERROR=OFF
                -DBUILD_EXAMPLES=ON
                -DBUILD_TESTING=OFF
                -DBUILD_DOCS=OFF
            )
            ;;
            
        macos-x64)
            print_info "配置 macOS x64 构建..."
            
            # 检查 Xcode
            if ! command -v clang &> /dev/null; then
                print_error "未找到 clang，请安装 Xcode Command Line Tools"
                print_info "运行: xcode-select --install"
                return 1
            fi
            
            CMAKE_ARGS=(
                -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/x86_64-apple-darwin.cmake"
                -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
                -DBINARY_PACKAGE_BUILD=ON
                -DLIBRAW_ENABLE_WERROR=OFF
                -DBUILD_EXAMPLES=ON
                -DBUILD_TESTING=OFF
                -DBUILD_DOCS=OFF
            )
            ;;
            
        linux-x64)
            print_info "配置 Linux x64 构建..."
            
            # 检查 GCC
            if ! command -v gcc &> /dev/null; then
                print_error "未找到 gcc，请安装 GCC"
                print_info "在 Ubuntu 上: sudo apt-get install build-essential"
                return 1
            fi
            
            CMAKE_ARGS=(
                -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
                -DBINARY_PACKAGE_BUILD=ON
                -DLIBRAW_ENABLE_WERROR=OFF
                -DBUILD_EXAMPLES=ON
                -DBUILD_TESTING=OFF
                -DBUILD_DOCS=OFF
            )
            ;;
    esac
    
    # 添加详细输出选项
    if [[ "$VERBOSE" == true ]]; then
        CMAKE_ARGS+=(-DCMAKE_VERBOSE_MAKEFILE=ON)
    fi
    
    print_info "CMake 配置参数:"
    for arg in "${CMAKE_ARGS[@]}"; do
        echo "  $arg"
    done
    
    # 运行 CMake 配置
    print_info "运行 CMake 配置..."
    if ! cmake "${CMAKE_ARGS[@]}" "$PROJECT_ROOT"; then
        print_error "CMake 配置失败: $platform"
        return 1
    fi
    
    # 编译
    print_info "开始编译 (使用 $JOBS 个并行任务)..."
    if ! make -j"$JOBS"; then
        print_error "编译失败: $platform"
        return 1
    fi
    
    print_success "编译完成: $platform"
    print_info "构建目录: $BUILD_DIR"
    print_info "库文件位置: $BUILD_DIR/lib/"
    print_info "可执行文件位置: $BUILD_DIR/bin/"
    
    # 显示生成的文件
    print_info "生成的文件:"
    find "$BUILD_DIR" -name "*.a" -o -name "*.dll" -o -name "*.exe" -o -name "*.dylib" | while read -r file; do
        echo "  $file"
    done
    
    # 显示文件大小
    if [[ -d "$BUILD_DIR/lib" ]]; then
        print_info "库文件大小:"
        du -sh "$BUILD_DIR/lib"/* 2>/dev/null || true
    fi
    
    # 恢复原始平台设置
    TARGET_PLATFORM="$original_platform"
    
    return 0
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_info "项目根目录: $PROJECT_ROOT"

# 获取构建目录名称
get_build_dir() {
    local platform="$1"
    case "$platform" in
        windows-x64)
            echo "build/windows-x64"
            ;;
        macos-arm64)
            echo "build/macos-arm64"
            ;;
        macos-x64)
            echo "build/macos-x64"
            ;;
        linux-x64)
            echo "build/linux-x64"
            ;;
        *)
            echo "build/$platform"
            ;;
    esac
}

# 处理 all 平台
if [[ "$TARGET_PLATFORM" == "all" ]]; then
    print_info "=========================================="
    print_info "开始构建所有平台"
    print_info "=========================================="
    
    PLATFORMS=("windows-x64" "macos-arm64" "macos-x64" "linux-x64")
    SUCCESS_COUNT=0
    FAILED_PLATFORMS=()
    
    for platform in "${PLATFORMS[@]}"; do
        if build_platform "$platform"; then
            ((SUCCESS_COUNT++))
        else
            FAILED_PLATFORMS+=("$platform")
        fi
    done
    
    print_info "=========================================="
    print_info "所有平台构建完成"
    print_info "成功: $SUCCESS_COUNT/${#PLATFORMS[@]}"
    
    if [[ ${#FAILED_PLATFORMS[@]} -gt 0 ]]; then
        print_error "失败的平台: ${FAILED_PLATFORMS[*]}"
        exit 1
    else
        print_success "所有平台构建成功！"
    fi
    
    exit 0
fi

# 单个平台构建
build_platform "$TARGET_PLATFORM"

