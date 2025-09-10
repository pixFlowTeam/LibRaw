# LibRaw 跨平台构建

## 概述

LibRaw 是一个用于处理 RAW 图像文件的 C++ 库。本项目提供了跨平台构建支持，可以在 macOS 主机上为多个目标平台进行交叉编译。

## 支持平台

| 平台 | 状态 | 库文件大小 | 编译器 |
|------|------|------------|--------|
| Windows x64 | ✅ | 100MB | MinGW-w64 |
| macOS ARM64 | ✅ | 11MB | AppleClang |
| macOS x64 | ✅ | 11MB | AppleClang |
| Linux x64 | ✅ | 11MB | GCC |

## 快速开始

### 构建所有平台
```bash
cd LibRaw
./scripts/build-unified.sh all
```

### 构建特定平台
```bash
# Windows x64
./scripts/build-unified.sh windows-x64

# macOS ARM64
./scripts/build-unified.sh macos-arm64

# macOS x64
./scripts/build-unified.sh macos-x64

# Linux x64
./scripts/build-unified.sh linux-x64
```

### 清理构建
```bash
# 清理特定平台
./scripts/build-unified.sh windows-x64 --clean

# 清理所有平台
./scripts/build-unified.sh all --clean
```

## 构建配置

### 已禁用功能
- ❌ **LCMS 支持**: 完全禁用，使用内置颜色转换
- ❌ **OpenMP 支持**: 完全禁用，避免多线程依赖
- ❌ **示例程序**: 仅 Windows 平台禁用

### 编译器标志

#### Windows x64
```bash
CMAKE_CXX_FLAGS="-w -O2 -D_GNU_SOURCE -D_USE_MATH_DEFINES -DWIN32 -DNO_LCMS"
CMAKE_C_FLAGS="-w -O2 -D_GNU_SOURCE -D_USE_MATH_DEFINES -DWIN32 -DNO_LCMS"
CMAKE_EXE_LINKER_FLAGS="-lws2_32 -lwsock32 -lmswsock"
```

#### macOS/Linux
```bash
CMAKE_CXX_FLAGS="-DNO_LCMS"
CMAKE_C_FLAGS="-DNO_LCMS"
```

## 构建结果

### 库文件位置
```
build/{platform}/lib/liblibraw.a
```

### 示例程序 (非 Windows)
```
build/{platform}/bin/
├── 4channels
├── dcraw_emu
├── dcraw_half
├── mem_image_sample
├── multirender_test
├── postprocessing_benchmark
├── raw-identify
├── rawtextdump
└── unprocessed_raw
```

## 依赖要求

### 系统依赖
- **macOS**: Xcode Command Line Tools
- **Windows**: MinGW-w64 (通过 Homebrew 安装)
- **Linux**: 标准开发工具链

### 安装依赖
```bash
# 安装 MinGW-w64 (Windows 交叉编译)
brew install mingw-w64

# 安装 CMake
brew install cmake
```

## 使用方法

### 链接库文件
```cpp
#include <libraw/libraw.h>

// 链接 liblibraw.a
// 无需额外依赖
```

### 基本用法
```cpp
LibRaw processor;
processor.open_file("image.raw");
processor.unpack();
processor.dcraw_process();
```

## 故障排除

### 常见问题

1. **Windows 构建失败**
   - 确保安装了 MinGW-w64
   - 检查工具链文件路径

2. **macOS x64 构建失败**
   - 确保创建了正确的工具链文件
   - 检查 Xcode 安装

3. **链接错误**
   - 检查链接器标志设置
   - 确保所有必要库已链接

### 调试命令
```bash
# 查看详细构建日志
make VERBOSE=1

# 检查库文件内容
nm lib/liblibraw.a | grep -i lcms
```

## 技术细节

### 禁用 LCMS 的原因
1. **减少依赖**: 避免外部库依赖
2. **跨平台一致性**: 所有平台使用相同功能集
3. **简化部署**: 库文件完全自包含
4. **性能优化**: 使用 LibRaw 内置算法

### 编译器标志说明
- `-w`: 禁用所有警告
- `-O2`: 优化级别 2
- `-D_GNU_SOURCE`: 启用 GNU 扩展
- `-D_USE_MATH_DEFINES`: 启用数学常量定义
- `-DWIN32`: Windows 平台标识
- `-DNO_LCMS`: 禁用 LCMS 支持

## 版本信息

- **LibRaw**: 最新稳定版
- **CMake**: 3.30.6
- **构建日期**: 2024年12月19日

## 许可证

请参考 LibRaw 项目的原始许可证文件。

---

**注意**: 本文档记录了在 macOS 15.6.0 系统上的构建过程。在其他系统上可能需要调整路径和配置。