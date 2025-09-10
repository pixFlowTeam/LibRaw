#!/bin/bash

# LibRaw 二进制文件测试脚本
# 用于验证跨平台构建的二进制文件是否正常工作

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 日志文件
LOG_FILE="test-results-$(date +%Y%m%d-%H%M%S).log"

# 打印函数
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PASS: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

# 运行测试并记录结果
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    print_info "运行测试: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        actual_exit_code=$?
        if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
            print_success "$test_name"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            print_error "$test_name (退出码: $actual_exit_code, 期望: $expected_exit_code)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        actual_exit_code=$?
        if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
            print_success "$test_name"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            print_error "$test_name (退出码: $actual_exit_code, 期望: $expected_exit_code)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    fi
}

# 检查文件是否存在
check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ]; then
        print_success "$description 存在: $file_path"
        return 0
    else
        print_error "$description 不存在: $file_path"
        return 1
    fi
}

# 检查文件格式
check_file_format() {
    local file_path="$1"
    local expected_format="$2"
    local description="$3"
    
    if [ ! -f "$file_path" ]; then
        print_error "$description 文件不存在: $file_path"
        return 1
    fi
    
    local actual_format=$(file "$file_path" | cut -d: -f2 | xargs)
    if echo "$actual_format" | grep -q "$expected_format"; then
        print_success "$description 格式正确: $actual_format"
        return 0
    else
        print_error "$description 格式错误: 期望包含 '$expected_format', 实际: '$actual_format'"
        return 1
    fi
}

# 测试单个平台
test_platform() {
    local platform="$1"
    local bin_dir="$2"
    local lib_dir="$3"
    local platform_name="$4"
    
    print_header "测试 $platform_name 平台"
    
    # 检查目录是否存在
    if [ ! -d "$bin_dir" ]; then
        print_error "$platform_name 二进制目录不存在: $bin_dir"
        return 1
    fi
    
    if [ ! -d "$lib_dir" ]; then
        print_error "$platform_name 库目录不存在: $lib_dir"
        return 1
    fi
    
    # 测试静态库
    print_info "测试静态库..."
    check_file_exists "$lib_dir/libraw.a" "静态库"
    run_test "静态库格式检查" "file '$lib_dir/libraw.a' | grep -q 'ar archive'"
    
    # 统计库中的目标文件数量
    local obj_count=$(ar -t "$lib_dir/libraw.a" 2>/dev/null | wc -l)
    print_info "静态库包含 $obj_count 个目标文件"
    
    # 测试所有二进制文件
    local binaries=("raw-identify" "dcraw_emu" "dcraw_half" "simple_dcraw" "4channels" "rawtextdump" "unprocessed_raw" "multirender_test" "postprocessing_benchmark")
    
    for binary in "${binaries[@]}"; do
        local binary_name="$binary"
        local binary_path="$bin_dir/$binary"
        
        # Windows 平台需要添加 .exe 扩展名
        if [ "$platform" = "windows" ]; then
            binary_path="$bin_dir/${binary}.exe"
        fi
        
        # 检查文件是否存在
        if ! check_file_exists "$binary_path" "$binary_name"; then
            continue
        fi
        
        # 检查文件格式
        if [ "$platform" = "macos" ]; then
            check_file_format "$binary_path" "Mach-O.*arm64" "$binary_name"
        elif [ "$platform" = "windows" ]; then
            check_file_format "$binary_path" "PE32+.*x86-64" "$binary_name"
        fi
        
        # 测试程序运行（帮助命令）
        # 注意：Windows 二进制文件在 macOS 上无法直接运行，只检查文件存在性和格式
        if [ "$platform" = "macos" ]; then
            case "$binary" in
                "raw-identify")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary --help" 1
                    ;;
                "dcraw_emu")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 1
                    ;;
                "dcraw_half")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 0
                    ;;
                "simple_dcraw")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary --help" 0
                    ;;
                "4channels")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 0
                    ;;
                "rawtextdump")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 1
                    ;;
                "unprocessed_raw")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 0
                    ;;
                "multirender_test")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 0
                    ;;
                "postprocessing_benchmark")
                    run_test "$binary_name 帮助命令" "cd '$bin_dir' && ./$binary" 0
                    ;;
            esac
        else
            # Windows 平台只检查文件存在性和格式，不尝试运行
            print_info "$binary_name 跳过运行测试（Windows 二进制文件无法在 macOS 上运行）"
        fi
        
        # 检查文件大小
        local file_size=$(ls -lh "$binary_path" | awk '{print $5}')
        print_info "$binary_name 文件大小: $file_size"
    done
}

# 生成测试报告
generate_report() {
    print_header "测试报告"
    
    echo "测试时间: $(date)"
    echo "总测试数: $TOTAL_TESTS"
    echo "通过测试: $PASSED_TESTS"
    echo "失败测试: $FAILED_TESTS"
    echo "成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo ""
    echo "详细日志: $LOG_FILE"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "所有测试通过！"
        return 0
    else
        print_error "有 $FAILED_TESTS 个测试失败"
        return 1
    fi
}

# 主函数
main() {
    print_header "LibRaw 二进制文件测试"
    print_info "开始测试构建的二进制文件..."
    print_info "日志文件: $LOG_FILE"
    echo ""
    
    # 检查构建目录
    local build_dir="/Users/fuguoqiang/Desktop/bridge/LibRaw/build"
    if [ ! -d "$build_dir" ]; then
        print_error "构建目录不存在: $build_dir"
        exit 1
    fi
    
    # 测试 macOS 平台
    local macos_bin_dir="$build_dir/macos-arm64/bin"
    local macos_lib_dir="$build_dir/macos-arm64/lib"
    test_platform "macos" "$macos_bin_dir" "$macos_lib_dir" "macOS ARM64"
    
    echo ""
    
    # 测试 Windows 平台
    local windows_bin_dir="$build_dir/windows-x86_64/bin"
    local windows_lib_dir="$build_dir/windows-x86_64/lib"
    test_platform "windows" "$windows_bin_dir" "$windows_lib_dir" "Windows x86_64"
    
    echo ""
    
    # 生成报告
    generate_report
}

# 运行主函数
main "$@"
