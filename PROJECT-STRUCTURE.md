# LibRaw 跨平台构建项目结构

## 目录结构说明

```
LibRaw/
├── scripts/                          # 构建脚本目录
│   └── build-cross-platform-fixed.sh # 跨平台构建脚本
├── docs/                             # 文档目录
│   ├── BUILD-CROSS-PLATFORM.md      # 详细构建指南
│   └── BUILD-RESULTS.md             # 构建结果报告
├── cmake/                            # CMake配置文件目录
│   └── CMakeLists.txt               # 备用CMake配置
├── CMakeLists.txt                    # 主CMake配置文件
├── libraw.pc.in                      # pkg-config模板文件
├── README-CROSS-PLATFORM.md          # 跨平台构建说明
├── PROJECT-STRUCTURE.md              # 项目结构说明（本文件）
└── .gitignore                        # Git忽略文件配置
```

## 文件说明

### 构建脚本
- **`scripts/build-cross-platform-fixed.sh`**: 主要的跨平台构建脚本
  - 支持Windows (x86_64-w64-mingw32) 和 macOS (aarch64-apple-darwin)
  - 自动检测工具链
  - 生成静态库和示例程序

### 文档
- **`docs/BUILD-CROSS-PLATFORM.md`**: 详细的构建指南
  - 前置要求说明
  - 构建步骤详解
  - 故障排除指南
- **`docs/BUILD-RESULTS.md`**: 构建结果报告
  - 构建成功验证
  - 文件大小对比
  - 功能测试结果

### 配置文件
- **`CMakeLists.txt`**: 主CMake配置文件
  - 支持跨平台构建
  - 静态库生成
  - 示例程序编译
- **`cmake/CMakeLists.txt`**: 备用CMake配置
- **`libraw.pc.in`**: pkg-config模板文件

### 忽略文件
- **`.gitignore`**: Git忽略文件配置
  - 构建输出目录 (`build-*/`)
  - 编译中间文件 (`*.o`, `*.a`, `*.exe` 等)
  - 系统文件 (`.DS_Store`, `Thumbs.db`)
  - IDE文件 (`.vscode/`, `.idea/`)

## 构建输出目录

构建过程中会生成以下目录（被.gitignore忽略）：

```
build-x86_64-w64-mingw32/             # Windows构建输出
├── lib/
│   └── libraw.a                      # 静态库
├── bin/
│   ├── raw-identify.exe              # 示例程序
│   ├── simple_dcraw.exe
│   └── ...
└── object/                           # 编译中间文件

build-aarch64-apple-darwin/           # macOS构建输出
├── lib/
│   └── libraw.a                      # 静态库
├── bin/
│   ├── raw-identify                  # 示例程序
│   ├── simple_dcraw
│   └── ...
└── object/                           # 编译中间文件
```

## 开源项目规范

### 目录命名规范
- **`scripts/`**: 构建和工具脚本
- **`docs/`**: 项目文档
- **`cmake/`**: CMake相关配置文件
- **`build-*/`**: 构建输出目录（忽略）

### 文件命名规范
- **构建脚本**: `build-*.sh`
- **文档文件**: `*.md`
- **配置文件**: `CMakeLists.txt`, `*.pc.in`
- **忽略文件**: `.gitignore`

### Git管理规范
- 源代码文件：跟踪
- 构建输出：忽略
- 配置文件：跟踪
- 文档文件：跟踪
- 临时文件：忽略

## 使用建议

1. **开发时**: 使用 `scripts/build-cross-platform-fixed.sh` 进行构建
2. **CI/CD**: 使用 `CMakeLists.txt` 进行自动化构建
3. **文档**: 参考 `docs/` 目录下的详细说明
4. **分发**: 使用构建输出目录中的静态库和可执行文件

## 维护说明

- 构建脚本更新时，请同时更新相关文档
- 添加新平台支持时，请更新 `.gitignore` 和文档
- 修改CMake配置时，请测试所有目标平台
- 定期清理构建输出目录以节省空间
