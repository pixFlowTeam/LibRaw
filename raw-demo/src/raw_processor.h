#pragma once

#include <string>
#include <memory>
#include <opencv2/opencv.hpp>
#include <libraw/libraw.h>

class RawProcessor
{
public:
  RawProcessor();
  ~RawProcessor();

  // 打开RAW文件
  bool openFile(const std::string &filepath);

  // 解码RAW文件为最高画质
  bool decodeRaw();

  // 获取解码后的图像数据
  cv::Mat getImage() const;

  // 转换为WebP格式
  bool saveAsWebP(const std::string &outputPath, int quality = 100);

  // 获取图像信息
  void printImageInfo() const;

  // 打印处理参数
  void printProcessingParams() const;

  // 清理资源
  void cleanup();

private:
  std::unique_ptr<LibRaw> processor_;
  cv::Mat image_;
  bool isLoaded_;

  // 配置最高画质参数
  void configureHighQuality();

  // 将LibRaw数据转换为OpenCV Mat
  cv::Mat convertToOpenCV(const libraw_processed_image_t *processed);
};
