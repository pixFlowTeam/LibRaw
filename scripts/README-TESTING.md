# LibRaw 测试脚本说明

本目录包含了用于测试 LibRaw 构建结果的自动化测试脚本。

## 测试脚本概览

### 1. `test-binaries.sh` - 完整测试脚本
**功能**: 全面测试所有平台的构建结果
**特点**: 
- 测试 macOS 和 Windows 两个平台
- 检查文件存在性、格式、运行功能
- 生成详细的测试报告和日志
- 适合 CI/CD 集成

**用法**:
```bash
./scripts/test-binaries.sh
```

### 2. `test-platform.sh` - 分平台测试脚本
**功能**: 可以单独测试指定平台或所有平台
**特点**:
- 支持单独测试 macOS 或 Windows 平台
- 支持命令行参数和帮助信息
- 适合开发过程中的快速测试

**用法**:
```bash
# 测试所有平台
./scripts/test-platform.sh

# 只测试 macOS
./scripts/test-platform.sh macos

# 只测试 Windows
./scripts/test-platform.sh windows

# 显示帮助
./scripts/test-platform.sh --help
```

### 3. `quick-test.sh` - 快速测试脚本
**功能**: 快速验证关键工具是否正常构建
**特点**:
- 只测试最重要的几个工具
- 运行速度快
- 适合构建后的快速验证

**用法**:
```bash
./scripts/quick-test.sh
```

## 测试内容

### 文件存在性检查
- 检查所有二进制文件是否存在
- 检查静态库文件是否存在
- 验证目录结构完整性

### 文件格式验证
- **macOS**: 验证 Mach-O 64-bit executable arm64 格式
- **Windows**: 验证 PE32+ executable (console) x86-64 格式
- **静态库**: 验证 ar archive 格式

### 功能测试
- **macOS**: 测试所有工具的命令行帮助功能
- **Windows**: 由于跨平台限制，只检查文件格式
- 验证程序能正常启动和显示帮助信息

### 静态库检查
- 验证库文件格式正确
- 统计包含的目标文件数量
- 检查库文件大小

## 测试工具列表

每个平台都会测试以下 9 个工具：

1. **raw-identify** - RAW 文件识别工具
2. **dcraw_emu** - 完整的 dcraw 模拟器
3. **dcraw_half** - 半尺寸处理工具
4. **simple_dcraw** - 简化版 dcraw
5. **4channels** - 四通道处理工具
6. **rawtextdump** - RAW 数据导出工具
7. **unprocessed_raw** - 未处理 RAW 工具
8. **multirender_test** - 多渲染测试工具
9. **postprocessing_benchmark** - 后处理性能测试工具

## 输出说明

### 成功标识
- ✅ 表示测试通过
- 绿色文字显示成功信息

### 错误标识
- ❌ 表示测试失败
- 红色文字显示错误信息

### 信息标识
- ℹ️ 表示一般信息
- 蓝色文字显示信息

### 警告标识
- ⚠️ 表示警告信息
- 黄色文字显示警告

## 测试报告

每个测试脚本都会生成测试报告，包含：
- 测试时间
- 总测试数量
- 通过测试数量
- 失败测试数量
- 成功率百分比

## 日志文件

`test-binaries.sh` 会生成带时间戳的日志文件：
- 格式: `test-results-YYYYMMDD-HHMMSS.log`
- 包含所有测试的详细输出
- 便于问题排查和记录

## 集成到构建流程

### 在构建脚本中添加测试
```bash
# 构建完成后自动运行测试
./scripts/build-cross-platform.sh
./scripts/test-binaries.sh
```

### 快速验证构建结果
```bash
# 构建完成后快速验证
./scripts/quick-test.sh
```

### 分平台验证
```bash
# 只验证 macOS 构建
./scripts/test-platform.sh macos

# 只验证 Windows 构建
./scripts/test-platform.sh windows
```

## 故障排除

### 常见问题

1. **权限错误**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **路径错误**
   - 确保在 LibRaw 项目根目录运行脚本
   - 检查构建目录是否存在

3. **测试失败**
   - 查看详细日志文件
   - 检查构建是否成功完成
   - 验证二进制文件权限

### 调试模式

使用详细输出模式获取更多信息：
```bash
./scripts/test-platform.sh --verbose macos
```

## 扩展测试

如需添加新的测试内容，可以修改相应的测试脚本：

1. **添加新工具测试**: 在 `binaries` 数组中添加新工具名称
2. **添加新检查项**: 在相应的测试函数中添加新的检查逻辑
3. **修改测试参数**: 调整期望的退出码或测试命令

## 注意事项

1. **跨平台限制**: Windows 二进制文件无法在 macOS 上直接运行
2. **依赖检查**: 确保测试环境有必要的工具（file, ar 等）
3. **权限要求**: 确保脚本有执行权限
4. **路径依赖**: 脚本假设在 LibRaw 项目根目录运行
