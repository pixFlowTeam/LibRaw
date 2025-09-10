# LibRaw 测试说明

本目录包含了用于测试 LibRaw 构建结果的说明。

## 测试方法

### 1. 构建测试

使用统一构建脚本进行构建测试：

```bash
# 构建所有平台
./scripts/build-unified.sh all

# 构建特定平台
./scripts/build-unified.sh macos-arm64
./scripts/build-unified.sh windows-x64
./scripts/build-unified.sh macos-x64
./scripts/build-unified.sh linux-x64
```

### 2. 构建验证

构建完成后，检查生成的文件：

```bash
# 检查库文件
ls -la build/macos-arm64/lib/
ls -la build/windows-x64/lib/
ls -la build/macos-x64/lib/
ls -la build/linux-x64/lib/

# 检查可执行文件
ls -la build/macos-arm64/bin/
ls -la build/windows-x64/bin/
ls -la build/macos-x64/bin/
ls -la build/linux-x64/bin/
```

### 3. 功能测试

运行示例程序进行功能测试：

```bash
# macOS ARM64
cd build/macos-arm64
./bin/raw-identify --help
./bin/dcraw_emu --help

# macOS x64
cd build/macos-x64
./bin/raw-identify --help
./bin/dcraw_emu --help

# Linux x64
cd build/linux-x64
./bin/raw-identify --help
./bin/dcraw_emu --help
```

## 测试平台

### 支持的平台
- **macos-arm64**: macOS Apple Silicon
- **macos-x64**: macOS Intel
- **windows-x64**: Windows 64位 (MinGW-w64)
- **linux-x64**: Linux 64位

### 平台特定测试

#### macOS 平台
```bash
# 构建 macOS 平台
./scripts/build-unified.sh macos-arm64
./scripts/build-unified.sh macos-x64

# 检查架构
file build/macos-arm64/lib/liblibraw.a
file build/macos-x64/lib/liblibraw.a

# 运行测试
cd build/macos-arm64 && ./bin/raw-identify --help
cd build/macos-x64 && ./bin/raw-identify --help
```

#### Windows 平台
```bash
# 构建 Windows 平台
./scripts/build-unified.sh windows-x64

# 检查文件
ls -la build/windows-x64/lib/
ls -la build/windows-x64/bin/

# 在 Windows 环境中运行
# build/windows-x64/bin/raw-identify.exe --help
```

#### Linux 平台
```bash
# 构建 Linux 平台
./scripts/build-unified.sh linux-x64

# 检查文件
ls -la build/linux-x64/lib/
ls -la build/linux-x64/bin/

# 运行测试
cd build/linux-x64 && ./bin/raw-identify --help
```

## 测试选项

### 构建选项
```bash
# 清理构建
./scripts/build-unified.sh all --clean

# 调试构建
./scripts/build-unified.sh macos-arm64 --debug

# 详细输出
./scripts/build-unified.sh windows-x64 --verbose

# 更多并行任务
./scripts/build-unified.sh all --jobs 8
```

### 验证选项
```bash
# 检查文件大小
du -sh build/*/lib/*.a

# 检查文件类型
file build/*/lib/*.a

# 检查依赖
otool -L build/macos-arm64/bin/raw-identify  # macOS
ldd build/linux-x64/bin/raw-identify         # Linux
```

## 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 查看详细输出
   ./scripts/build-unified.sh macos-arm64 --verbose
   
   # 清理后重新构建
   ./scripts/build-unified.sh macos-arm64 --clean
   ```

2. **文件不存在**
   ```bash
   # 检查构建目录
   ls -la build/
   
   # 检查特定平台
   ls -la build/macos-arm64/
   ```

3. **权限问题**
   ```bash
   # 给脚本添加执行权限
   chmod +x scripts/build-unified.sh
   ```

4. **依赖缺失**
   ```bash
   # macOS
   xcode-select --install
   
   # Ubuntu/Debian
   sudo apt-get install build-essential
   
   # MinGW-w64 (macOS)
   brew install mingw-w64
   ```

## 持续集成

### GitHub Actions 示例

```yaml
name: Build Test
on: [push, pull_request]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [macos-latest, ubuntu-latest, windows-latest]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build LibRaw
      run: |
        cd LibRaw
        ./scripts/build-unified.sh all
```

### 本地测试脚本

```bash
#!/bin/bash
# test-all-platforms.sh

set -e

echo "开始测试所有平台..."

# 构建所有平台
cd LibRaw
./scripts/build-unified.sh all

# 检查构建结果
for platform in macos-arm64 macos-x64 windows-x64 linux-x64; do
    echo "检查平台: $platform"
    if [ -f "build/$platform/lib/liblibraw.a" ]; then
        echo "✅ $platform 构建成功"
    else
        echo "❌ $platform 构建失败"
        exit 1
    fi
done

echo "✅ 所有平台测试通过"
```

## 性能测试

### 构建时间测试

```bash
# 记录构建时间
time ./scripts/build-unified.sh all

# 单平台构建时间
time ./scripts/build-unified.sh macos-arm64
time ./scripts/build-unified.sh windows-x64
time ./scripts/build-unified.sh macos-x64
time ./scripts/build-unified.sh linux-x64
```

### 文件大小测试

```bash
# 检查库文件大小
du -sh build/*/lib/*.a

# 检查可执行文件大小
du -sh build/*/bin/*
```

## 总结

LibRaw 的统一构建系统提供了简单易用的测试方法：

1. **统一接口**: 使用 `build-unified.sh` 脚本
2. **多平台支持**: 支持 4 个主要平台
3. **灵活选项**: 支持清理、调试、详细输出等选项
4. **易于集成**: 适合 CI/CD 和自动化测试

通过遵循本指南，您可以有效地测试 LibRaw 在不同平台上的构建和功能。