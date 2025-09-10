# RAW文件解码器Demo

这是一个使用LibRaw和OpenCV的RAW文件解码器，可以将RAW文件（如ARW格式）解码为最高画质并输出为无损8位WebP格式。

## 功能特性

- 支持多种RAW格式（ARW、CR2、NEF等）
- 最高画质解码配置
- 16位转8位无损转换
- 输出为WebP格式（质量100%）
- 显示详细的图像信息（相机型号、ISO、曝光参数等）

## 编译

```bash
mkdir build
cd build
cmake ..
make
```

## 使用方法

```bash
# 基本用法
./build/bin/raw_processor <RAW文件路径> [输出WebP文件路径]

# 示例
./build/bin/raw_processor rawFiles/DSC02975.ARW
./build/bin/raw_processor rawFiles/DSC02975.ARW output/custom_name.webp
```

**注意**: 如果不指定输出路径，文件将自动保存到 `output/` 目录中。

## 输出示例

```
开始处理RAW文件: rawFiles/DSC02975.ARW
输出文件: DSC02975.webp
正在解码RAW文件...
图像信息:
  尺寸: 7028 x 4688
  通道数: 3
  数据类型: 16
  相机: Sony ILCE-7M4
  ISO: 200
  曝光时间: 0.008s
  光圈: f/3.2
正在保存为WebP格式...
成功保存WebP文件: DSC02975.webp
处理完成！
```

## 技术细节

- 使用LibRaw进行RAW文件解码
- 配置了最高画质参数（16位输出、sRGB色彩空间、相机白平衡等）
- 使用OpenCV进行图像格式转换和WebP编码
- 支持16位到8位的无损转换（除以256）

## 依赖

- LibRaw
- OpenCV 4.x
- CMake 3.16+
- C++17编译器
