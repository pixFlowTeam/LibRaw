# LibRaw 跨平台构建指南

本文档详细说明如何为Windows x86_64和macOS ARM64平台构建LibRaw，实现独立发布（不依赖系统库）。

## 支持的平台

- **Windows x86_64**: 使用MinGW-w64工具链
- **macOS ARM64**: 使用Clang工具链

## 前置要求

### Windows构建 (MinGW-w64)

#### 在macOS上安装MinGW-w64
```bash
# 使用Homebrew安装
brew install mingw-w64

# 或使用MacPorts
sudo port install mingw-w64

# 验证安装
x86_64-w64-mingw32-gcc --version
x86_64-w64-mingw32-g++ --version
```

#### 在Windows上安装MinGW-w64
1. 下载MinGW-w64安装包
2. 安装到系统路径
3. 验证环境变量设置

### macOS构建 (Clang)

```bash
# 安装Xcode Command Line Tools
xcode-select --install

# 验证安装
clang --version
clang++ --version
```

## 构建方法

### 方法1: 使用构建脚本 (推荐)

```bash
# 构建所有平台
./scripts/build-cross-platform.sh all

# 构建特定平台
./scripts/build-cross-platform.sh windows    # Windows x86_64
./scripts/build-cross-platform.sh macos      # macOS ARM64

# 清理构建目录
./scripts/build-cross-platform.sh clean
```

### 方法2: 使用CMake

```bash
# 创建构建目录
mkdir build-cmake && cd build-cmake

# 配置CMake
cmake ..

# 编译
make -j$(nproc)

# 安装
make install
```

### 方法3: 使用原始Makefile

```bash
# Windows (MinGW-w64)
make -f Makefile.mingw

# macOS ARM64
./configure --disable-lcms --disable-jpeg --disable-zlib --disable-openmp
make
```

## 独立发布配置

为了实现独立发布（不依赖系统库），构建时使用以下配置：

### 禁用可选依赖
- `--disable-lcms`: 禁用LCMS颜色管理
- `--disable-jpeg`: 禁用JPEG支持
- `--disable-zlib`: 禁用zlib压缩支持
- `--disable-openmp`: 禁用OpenMP多线程支持

### 静态链接选项
- **Windows**: `-static-libgcc -static-libstdc++`
- **macOS**: 使用系统默认链接器

## 构建输出

构建完成后，会在标准目录生成输出：

```
build/
├── macos-arm64/                     # macOS ARM64构建输出
│   ├── lib/
│   │   └── libraw.a                # 静态库 (1.5MB)
│   └── bin/                        # 可执行程序
│       ├── raw-identify            # 770KB
│       ├── simple_dcraw           # 1.1MB
│       ├── dcraw_emu              # 1.1MB
│       ├── dcraw_half             # 1.1MB
│       ├── multirender_test       # 1.1MB
│       ├── postprocessing_benchmark # 1.1MB
│       ├── 4channels              # 785KB
│       ├── rawtextdump            # 752KB
│       └── unprocessed_raw        # 769KB
└── windows-x86_64/                 # Windows x86_64构建输出
    ├── lib/
    │   └── libraw.a                # 静态库 (1.7MB)
    └── bin/                        # 可执行程序
        ├── raw-identify.exe        # 3.8MB
        ├── simple_dcraw.exe        # 4.3MB
        ├── dcraw_emu.exe           # 4.3MB
        ├── dcraw_half.exe          # 1.8MB
        ├── multirender_test.exe    # 4.3MB
        ├── postprocessing_benchmark.exe # 4.3MB
        ├── 4channels.exe           # 3.8MB
        ├── rawtextdump.exe         # 3.8MB
        └── unprocessed_raw.exe     # 3.8MB
```

## 使用静态库

### 编译你的程序

**Windows (MinGW-w64)**:
```bash
x86_64-w64-mingw32-g++ -I./libraw -L./build/windows-x86_64/lib -lraw your_program.cpp -o your_program.exe
```

**macOS (Clang)**:
```bash
clang++ -I./libraw -L./build/macos-arm64/lib -lraw your_program.cpp -o your_program
```

### 链接选项

- **Windows**: `-lws2_32 -lm` (网络和数学库)
- **macOS**: `-lm` (数学库)

### 示例代码

```cpp
#include <libraw/libraw.h>
#include <iostream>

int main() {
    LibRaw processor;
    int ret = processor.open_file("image.raw");
    if (ret != LIBRAW_SUCCESS) {
        std::cerr << "Cannot open file" << std::endl;
        return 1;
    }
    
    ret = processor.unpack();
    if (ret != LIBRAW_SUCCESS) {
        std::cerr << "Cannot unpack" << std::endl;
        return 1;
    }
    
    ret = processor.dcraw_process();
    if (ret != LIBRAW_SUCCESS) {
        std::cerr << "Cannot process" << std::endl;
        return 1;
    }
    
    std::cout << "Image processed successfully" << std::endl;
    return 0;
}
```

## 独立发布特性

✅ **静态链接**: 所有程序都使用静态链接，不依赖外部库  
✅ **无系统依赖**: 除了基本系统库外，无其他依赖  
✅ **跨平台**: 支持Windows和macOS平台  
✅ **独立分发**: 生成的程序可以直接分发和运行  

## 示例程序使用

构建完成后，可以使用以下示例程序：

```bash
# macOS
./build/macos-arm64/bin/raw-identify --help
./build/macos-arm64/bin/simple_dcraw image.raw

# Windows (在Windows系统上)
./build/windows-x86_64/bin/raw-identify.exe --help
./build/windows-x86_64/bin/simple_dcraw.exe image.raw
```

## 故障排除

### 常见问题

1. **工具链未找到**: 确保已正确安装相应的编译器工具链
2. **链接错误**: 检查是否包含了必要的系统库
3. **架构不匹配**: 确保编译器目标架构与预期一致
4. **重复符号错误**: 确保排除了占位符文件（_ph.cpp）

### 调试选项

```bash
# 检查生成的二进制文件架构
file build/macos-arm64/bin/raw-identify
file build/windows-x86_64/bin/raw-identify.exe

# 检查库依赖 (macOS)
otool -L build/macos-arm64/bin/raw-identify

# 检查库依赖 (Windows)
ldd build/windows-x86_64/bin/raw-identify.exe

# 启用详细输出
make VERBOSE=1
```

### 性能优化

```bash
# 启用优化编译
export CFLAGS="-O3 -march=native"
export CXXFLAGS="-O3 -march=native"

# 启用OpenMP (如果需要)
export CFLAGS="$CFLAGS -fopenmp"
export CXXFLAGS="$CXXFLAGS -fopenmp"
```

## 参考

- [LibRaw官方文档](https://www.libraw.org/docs/Install-LibRaw-eng.html)
- [MinGW-w64文档](https://www.mingw-w64.org/)
- [Apple开发者文档](https://developer.apple.com/documentation/)
- [CMake文档](https://cmake.org/documentation/)
