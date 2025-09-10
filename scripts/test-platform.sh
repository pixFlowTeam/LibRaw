#!/bin/bash

# LibRaw 分平台测试脚本
# 用法: ./test-platform.sh [macos|windows|all]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 打印函数
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 运行测试并记录结果
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
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

# 测试 macOS 平台
test_macos() {
    print_header "测试 macOS ARM64 平台"
    
    local bin_dir="/Users/fuguoqiang/Desktop/bridge/LibRaw/build/macos-arm64/bin"
    local lib_dir="/Users/fuguoqiang/Desktop/bridge/LibRaw/build/macos-arm64/lib"
    
    # 检查目录
    if [ ! -d "$bin_dir" ]; then
        print_error "macOS 二进制目录不存在: $bin_dir"
        return 1
    fi
    
    if [ ! -d "$lib_dir" ]; then
        print_error "macOS 库目录不存在: $lib_dir"
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
        local binary_path="$bin_dir/$binary"
        
        # 检查文件是否存在
        if ! check_file_exists "$binary_path" "$binary"; then
            continue
        fi
        
        # 检查文件格式
        check_file_format "$binary_path" "Mach-O.*arm64" "$binary"
        
        # 测试程序运行
        case "$binary" in
            "raw-identify")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary --help" 1
                ;;
            "dcraw_emu")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 1
                ;;
            "dcraw_half")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 0
                ;;
            "simple_dcraw")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary --help" 0
                ;;
            "4channels")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 0
                ;;
            "rawtextdump")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 1
                ;;
            "unprocessed_raw")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 0
                ;;
            "multirender_test")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 0
                ;;
            "postprocessing_benchmark")
                run_test "$binary 帮助命令" "cd '$bin_dir' && ./$binary" 0
                ;;
        esac
        
        # 检查文件大小
        local file_size=$(ls -lh "$binary_path" | awk '{print $5}')
        print_info "$binary 文件大小: $file_size"
    done
}

# 测试 Windows 平台
test_windows() {
    print_header "测试 Windows x86_64 平台"
    
    local bin_dir="/Users/fuguoqiang/Desktop/bridge/LibRaw/build/windows-x86_64/bin"
    local lib_dir="/Users/fuguoqiang/Desktop/bridge/LibRaw/build/windows-x86_64/lib"
    
    # 检查目录
    if [ ! -d "$bin_dir" ]; then
        print_error "Windows 二进制目录不存在: $bin_dir"
        return 1
    fi
    
    if [ ! -d "$lib_dir" ]; then
        print_error "Windows 库目录不存在: $lib_dir"
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
        local binary_path="$bin_dir/${binary}.exe"
        
        # 检查文件是否存在
        if ! check_file_exists "$binary_path" "$binary"; then
            continue
        fi
        
        # 检查文件格式
        check_file_format "$binary_path" "PE32+.*x86-64" "$binary"
        
        # Windows 二进制文件无法在 macOS 上运行，只检查文件存在性和格式
        print_info "$binary 跳过运行测试（Windows 二进制文件无法在 macOS 上运行）"
        
        # 检查文件大小
        local file_size=$(ls -lh "$binary_path" | awk '{print $5}')
        print_info "$binary 文件大小: $file_size"
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
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "所有测试通过！"
        return 0
    else
        print_error "有 $FAILED_TESTS 个测试失败"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "LibRaw 分平台测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项] [平台]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -v, --verbose  详细输出"
    echo ""
    echo "平台:"
    echo "  macos          只测试 macOS ARM64 平台"
    echo "  windows        只测试 Windows x86_64 平台"
    echo "  all            测试所有平台（默认）"
    echo ""
    echo "示例:"
    echo "  $0 macos       # 只测试 macOS"
    echo "  $0 windows     # 只测试 Windows"
    echo "  $0 all         # 测试所有平台"
    echo "  $0             # 测试所有平台（默认）"
}

# 主函数
main() {
    local platform="all"
    local verbose=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            macos|windows|all)
                platform="$1"
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header "LibRaw 分平台测试"
    print_info "测试平台: $platform"
    print_info "详细输出: $verbose"
    echo ""
    
    # 重置计数器
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    
    # 根据平台参数执行测试
    case "$platform" in
        "macos")
            test_macos
            ;;
        "windows")
            test_windows
            ;;
        "all")
            test_macos
            echo ""
            test_windows
            ;;
        *)
            print_error "不支持的平台: $platform"
            exit 1
            ;;
    esac
    
    echo ""
    generate_report
}

# 运行主函数
main "$@"
