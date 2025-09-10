#!/bin/bash

# LibRaw 快速测试脚本
# 用于快速验证构建的二进制文件

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 快速测试函数
quick_test() {
    local platform="$1"
    local bin_dir="$2"
    local platform_name="$3"
    
    print_info "快速测试 $platform_name..."
    
    # 检查目录
    if [ ! -d "$bin_dir" ]; then
        print_error "$platform_name 目录不存在: $bin_dir"
        return 1
    fi
    
    # 测试几个关键工具
    local test_tools=("raw-identify" "dcraw_emu" "4channels")
    local success_count=0
    local total_count=${#test_tools[@]}
    
    for tool in "${test_tools[@]}"; do
        local tool_path="$bin_dir/$tool"
        if [ "$platform" = "windows" ]; then
            tool_path="$bin_dir/${tool}.exe"
        fi
        
        if [ -f "$tool_path" ]; then
            print_success "$tool 存在"
            success_count=$((success_count + 1))
        else
            print_error "$tool 不存在"
        fi
    done
    
    # 测试 macOS 工具运行
    if [ "$platform" = "macos" ]; then
        print_info "测试 macOS 工具运行..."
        if cd "$bin_dir" && ./raw-identify --help >/dev/null 2>&1; then
            print_success "raw-identify 可以运行"
        else
            print_error "raw-identify 无法运行"
        fi
    fi
    
    echo "通过测试: $success_count/$total_count"
    return $((total_count - success_count))
}

# 主函数
main() {
    echo "LibRaw 快速测试"
    echo "================"
    
    local build_dir="/Users/fuguoqiang/Desktop/bridge/LibRaw/build"
    local macos_bin="$build_dir/macos-arm64/bin"
    local windows_bin="$build_dir/windows-x86_64/bin"
    
    local total_failed=0
    
    # 测试 macOS
    if ! quick_test "macos" "$macos_bin" "macOS ARM64"; then
        total_failed=$((total_failed + $?))
    fi
    
    echo ""
    
    # 测试 Windows
    if ! quick_test "windows" "$windows_bin" "Windows x86_64"; then
        total_failed=$((total_failed + $?))
    fi
    
    echo ""
    if [ $total_failed -eq 0 ]; then
        print_success "所有快速测试通过！"
        exit 0
    else
        print_error "有 $total_failed 个测试失败"
        exit 1
    fi
}

main "$@"
