# LibRaw 跨平台构建

本项目为LibRaw提供了跨平台构建支持，支持Windows x64、macOS ARM64、macOS x64和Linux x64平台，实现独立发布（不依赖系统库）。

## 项目结构

```
LibRaw/
├── scripts/                          # 构建脚本
│   └── build-unified.sh             # 统一跨平台构建脚本
├── docs/                             # 文档
│   ├── BUILD-CROSS-PLATFORM.md      # 详细构建指南
│   └── BUILD-RESULTS.md             # 构建结果报告
├── cmake/                            # CMake配置文件
│   ├── toolchains/                  # 交叉编译工具链
│   ├── build-type.cmake             # 构建类型配置
│   ├── compiler-flags.cmake         # 编译器标志
│   └── compiler-warnings.cmake      # 编译器警告
├── CMakeLists.txt                    # 主CMake配置文件
├── libraw.pc.in                      # 原始pkg-config模板
├── README-CROSS-PLATFORM.md          # 本文件
├── PROJECT-STRUCTURE.md              # 项目结构说明
└── .gitignore                        # Git忽略文件
```

## 支持的平台

- **Windows x64**: 使用MinGW-w64工具链
- **macOS ARM64**: 使用Clang工具链
- **macOS x64**: 使用Clang工具链
- **Linux x64**: 使用GCC工具链

## 快速开始

### 1. 构建所有平台
```bash
./scripts/build-unified.sh all
```

### 2. 构建特定平台
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

### 3. 清理构建目录
```bash
./scripts/build-unified.sh --clean all
```

## 构建输出

构建完成后，会在以下标准目录生成输出：

```
build/
├── macos-arm64/                     # macOS ARM64构建输出
│   ├── lib/libraw.a                # 静态库 (1.5MB)
│   └── bin/                        # 可执行程序
│       ├── raw-identify            # 770KB
│       ├── simple_dcraw           # 1.1MB
│       └── ...                     # 其他示例程序
└── windows-x64/                    # Windows x64构建输出
    ├── lib/libraw.a                # 静态库 (1.7MB)
    └── bin/                        # 可执行程序
        ├── raw-identify.exe        # 3.8MB
        ├── simple_dcraw.exe        # 4.3MB
        └── ...                     # 其他示例程序
```

## 依赖要求

### Windows构建 (MinGW-w64)
```bash
# 在macOS上安装MinGW-w64
brew install mingw-w64

# 验证安装
x86_64-w64-mingw32-gcc --version
```

### macOS构建 (Clang)
```bash
# 安装Xcode Command Line Tools
xcode-select --install

# 验证安装
clang --version
```

## 使用静态库

### 编译你的程序

**Windows (MinGW-w64)**:
```bash
x86_64-w64-mingw32-g++ -I./libraw -L./build/windows-x64/lib -lraw your_program.cpp -o your_program.exe
```

**macOS (Clang)**:
```bash
clang++ -I./libraw -L./build/macos-arm64/lib -lraw your_program.cpp -o your_program
```

### 链接选项

- **Windows**: `-lws2_32 -lm` (网络和数学库)
- **macOS**: `-lm` (数学库)

## 独立发布特性

✅ **静态链接**: 所有程序都使用静态链接，不依赖外部库  
✅ **无系统依赖**: 除了基本系统库外，无其他依赖  
✅ **跨平台**: 支持Windows和macOS平台  
✅ **独立分发**: 生成的程序可以直接分发和运行  

## 使用CMake构建

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

## 示例程序

构建完成后，可以使用以下示例程序：

```bash
# macOS
./build/macos-arm64/bin/raw-identify --help

# Windows (在Windows系统上)
./build/windows-x64/bin/raw-identify.exe --help
```

## 故障排除

### 常见问题

1. **工具链未找到**: 确保已正确安装相应的编译器工具链
2. **链接错误**: 检查是否包含了必要的系统库
3. **架构不匹配**: 确保编译器目标架构与预期一致

### 调试选项

```bash
# 检查生成的二进制文件架构
file build/macos-arm64/bin/raw-identify
file build/windows-x64/bin/raw-identify.exe

# 检查库依赖 (macOS)
otool -L build/macos-arm64/bin/raw-identify
```

## 更多信息

详细的构建说明请参考：
- [详细构建指南](docs/BUILD-CROSS-PLATFORM.md)
- [构建结果报告](docs/BUILD-RESULTS.md)
- [项目结构说明](PROJECT-STRUCTURE.md)

## 许可证

本项目遵循LibRaw的原始许可证。
