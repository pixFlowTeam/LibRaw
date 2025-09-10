#include "raw_processor.h"
#include <iostream>
#include <stdexcept>
#include <chrono>

RawProcessor::RawProcessor() : processor_(std::make_unique<LibRaw>()), isLoaded_(false) { configureHighQuality(); }

RawProcessor::~RawProcessor() { cleanup(); }

bool RawProcessor::openFile(const std::string &filepath)
{
  try
  {
    auto start = std::chrono::high_resolution_clock::now();

    int ret = processor_->open_file(filepath.c_str());
    if (ret != LIBRAW_SUCCESS)
    {
      std::cerr << "无法打开文件 " << filepath << ": " << libraw_strerror(ret) << std::endl;
      return false;
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    std::cout << "  ✓ 文件打开耗时: " << duration.count() << "ms" << std::endl;

    return true;
  }
  catch (const std::exception &e)
  {
    std::cerr << "打开文件时发生异常: " << e.what() << std::endl;
    return false;
  }
}

bool RawProcessor::decodeRaw()
{
  try
  {
    // 解包RAW数据
    auto unpack_start = std::chrono::high_resolution_clock::now();
    int ret = processor_->unpack();
    if (ret != LIBRAW_SUCCESS)
    {
      std::cerr << "解包失败: " << libraw_strerror(ret) << std::endl;
      return false;
    }
    auto unpack_end = std::chrono::high_resolution_clock::now();
    auto unpack_duration = std::chrono::duration_cast<std::chrono::milliseconds>(unpack_end - unpack_start);
    std::cout << "  ✓ RAW解包耗时: " << unpack_duration.count() << "ms" << std::endl;

    // 处理图像
    auto process_start = std::chrono::high_resolution_clock::now();
    ret = processor_->dcraw_process();
    if (ret != LIBRAW_SUCCESS)
    {
      std::cerr << "图像处理失败: " << libraw_strerror(ret) << std::endl;
      return false;
    }
    auto process_end = std::chrono::high_resolution_clock::now();
    auto process_duration = std::chrono::duration_cast<std::chrono::milliseconds>(process_end - process_start);
    std::cout << "  ✓ 图像处理耗时: " << process_duration.count() << "ms" << std::endl;

    // 获取处理后的图像
    auto mem_start = std::chrono::high_resolution_clock::now();
    libraw_processed_image_t *processed = processor_->dcraw_make_mem_image(&ret);
    if (ret != LIBRAW_SUCCESS || !processed)
    {
      std::cerr << "创建内存图像失败: " << libraw_strerror(ret) << std::endl;
      return false;
    }
    auto mem_end = std::chrono::high_resolution_clock::now();
    auto mem_duration = std::chrono::duration_cast<std::chrono::milliseconds>(mem_end - mem_start);
    std::cout << "  ✓ 内存图像创建耗时: " << mem_duration.count() << "ms" << std::endl;

    // 转换为OpenCV Mat
    auto convert_start = std::chrono::high_resolution_clock::now();
    image_ = convertToOpenCV(processed);
    auto convert_end = std::chrono::high_resolution_clock::now();
    auto convert_duration = std::chrono::duration_cast<std::chrono::milliseconds>(convert_end - convert_start);
    std::cout << "  ✓ OpenCV转换耗时: " << convert_duration.count() << "ms" << std::endl;

    // 释放LibRaw内存
    LibRaw::dcraw_clear_mem(processed);

    isLoaded_ = true;
    return true;
  }
  catch (const std::exception &e)
  {
    std::cerr << "解码时发生异常: " << e.what() << std::endl;
    return false;
  }
}

cv::Mat RawProcessor::getImage() const { return image_.clone(); }

bool RawProcessor::saveAsWebP(const std::string &outputPath, int quality)
{
  if (image_.empty())
  {
    std::cerr << "没有可保存的图像数据" << std::endl;
    return false;
  }

  try
  {
    auto save_start = std::chrono::high_resolution_clock::now();

    std::vector<int> compression_params;
    compression_params.push_back(cv::IMWRITE_WEBP_QUALITY);
    compression_params.push_back(quality);

    bool success = cv::imwrite(outputPath, image_, compression_params);
    if (!success)
    {
      std::cerr << "保存WebP文件失败: " << outputPath << std::endl;
      return false;
    }

    auto save_end = std::chrono::high_resolution_clock::now();
    auto save_duration = std::chrono::duration_cast<std::chrono::milliseconds>(save_end - save_start);
    std::cout << "  ✓ WebP保存耗时: " << save_duration.count() << "ms" << std::endl;

    std::cout << "成功保存WebP文件: " << outputPath << std::endl;
    return true;
  }
  catch (const std::exception &e)
  {
    std::cerr << "保存WebP时发生异常: " << e.what() << std::endl;
    return false;
  }
}

void RawProcessor::printImageInfo() const
{
  if (!isLoaded_)
  {
    std::cout << "没有加载的图像" << std::endl;
    return;
  }

  std::cout << "图像信息:" << std::endl;
  std::cout << "  尺寸: " << image_.cols << " x " << image_.rows << std::endl;
  std::cout << "  通道数: " << image_.channels() << std::endl;
  std::cout << "  数据类型: " << image_.type() << std::endl;

  if (processor_)
  {
    std::cout << "  相机: " << processor_->imgdata.idata.make << " " << processor_->imgdata.idata.model << std::endl;
    std::cout << "  ISO: " << processor_->imgdata.other.iso_speed << std::endl;
    std::cout << "  曝光时间: " << processor_->imgdata.other.shutter << "s" << std::endl;
    std::cout << "  光圈: f/" << processor_->imgdata.other.aperture << std::endl;
  }
}

void RawProcessor::printProcessingParams() const
{
  if (!processor_)
  {
    std::cout << "处理器未初始化" << std::endl;
    return;
  }

  const auto &params = processor_->imgdata.params;

  std::cout << "处理参数设置:" << std::endl;
  std::cout << "  输出位深: " << params.output_bps << "位" << std::endl;
  std::cout << "  色彩空间: "
            << (params.output_color == 1   ? "sRGB"
                : params.output_color == 2 ? "Adobe RGB"
                : params.output_color == 3 ? "Wide Gamut RGB"
                : params.output_color == 4 ? "ProPhoto RGB"
                : params.output_color == 5 ? "Rec2020"
                : params.output_color == 6 ? "XYZ"
                : params.output_color == 7 ? "ACES2065-1"
                : params.output_color == 8 ? "ACEScct"
                : params.output_color == 9 ? "ACEScct"
                                           : "Unknown")
            << std::endl;
  std::cout << "  使用相机白平衡: " << (params.use_camera_wb ? "是" : "否") << std::endl;
  std::cout << "  使用自动白平衡: " << (params.use_auto_wb ? "是" : "否") << std::endl;
  std::cout << "  高光恢复: "
            << (params.highlight == 0   ? "关闭"
                : params.highlight == 1 ? "正常"
                : params.highlight == 2 ? "高"
                                        : "最高")
            << std::endl;
  std::cout << "  亮度调整: " << params.bright << std::endl;
  std::cout << "  伽马值: [" << params.gamm[0] << ", " << params.gamm[1] << "]" << std::endl;
  std::cout << "  自动亮度: " << (params.no_auto_bright ? "关闭" : "开启") << std::endl;
  std::cout << "  最大调整阈值: " << params.adjust_maximum_thr << std::endl;
  std::cout << "  四色RGB: " << (params.four_color_rgb ? "开启" : "关闭") << std::endl;
  std::cout << "  DCB迭代次数: " << params.dcb_iterations << std::endl;
  std::cout << "  DCB增强: " << (params.dcb_enhance_fl ? "开启" : "关闭") << std::endl;
  std::cout << "  FBDD降噪: "
            << (params.fbdd_noiserd == 0   ? "关闭"
                : params.fbdd_noiserd == 1 ? "轻微"
                : params.fbdd_noiserd == 2 ? "中等"
                                           : "强烈")
            << std::endl;
  std::cout << "  中值滤波: "
            << (params.med_passes == 0   ? "关闭"
                : params.med_passes == 1 ? "轻微"
                : params.med_passes == 2 ? "中等"
                                         : "强烈")
            << std::endl;
  std::cout << "  自动亮度阈值: " << params.auto_bright_thr << std::endl;
  std::cout << "  色差校正: [" << params.aber[0] << ", " << params.aber[1] << ", " << params.aber[2] << ", "
            << params.aber[3] << "]" << std::endl;
  std::cout << "  绿色匹配: " << (params.green_matching ? "开启" : "关闭") << std::endl;
}

void RawProcessor::cleanup()
{
  if (processor_)
  {
    processor_->recycle();
  }
  image_.release();
  isLoaded_ = false;
}

void RawProcessor::configureHighQuality()
{
  if (!processor_)
    return;

  auto &params = processor_->imgdata.params;

  // 设置最高画质参数
  params.output_bps = 16;   // 16位输出
  params.output_color = 0;  // 原始色彩空间
  params.use_camera_wb = 1; // 使用相机白平衡
  params.use_auto_wb = 0;   // 禁用自动白平衡
  params.highlight = 0;     // 禁用高光恢复
  params.bright = 1.0;      // 亮度
  params.gamm[0] = 2.222;   // 伽马值
  params.gamm[1] = 4.5;
  params.no_auto_bright = 1;        // 禁用自动亮度
  params.adjust_maximum_thr = 0.75; // 最大调整阈值
  params.four_color_rgb = 0;        // 禁用四色RGB
  params.dcb_iterations = 0;        // DCB迭代次数
  params.dcb_enhance_fl = 0;        // DCB增强
  params.fbdd_noiserd = 0;          // FBDD降噪
  params.med_passes = 0;            // 中值滤波
  params.auto_bright_thr = 0.01;    // 自动亮度阈值
  params.aber[0] = 0;               // 色差校正参数
  params.aber[1] = 0;
  params.aber[2] = 0;
  params.aber[3] = 0;
  params.green_matching = 0; // 绿色匹配
}

cv::Mat RawProcessor::convertToOpenCV(const libraw_processed_image_t *processed)
{
  if (!processed)
  {
    return cv::Mat();
  }

  int width = processed->width;
  int height = processed->height;
  int channels = processed->colors;
  int bps = processed->bits;

  cv::Mat image;

  if (bps == 8)
  {
    if (channels == 1)
    {
      image = cv::Mat(height, width, CV_8UC1, (void *)processed->data);
    }
    else if (channels == 3)
    {
      image = cv::Mat(height, width, CV_8UC3, (void *)processed->data);
    }
    else if (channels == 4)
    {
      image = cv::Mat(height, width, CV_8UC4, (void *)processed->data);
    }
  }
  else if (bps == 16)
  {
    if (channels == 1)
    {
      image = cv::Mat(height, width, CV_16UC1, (void *)processed->data);
    }
    else if (channels == 3)
    {
      image = cv::Mat(height, width, CV_16UC3, (void *)processed->data);
    }
    else if (channels == 4)
    {
      image = cv::Mat(height, width, CV_16UC4, (void *)processed->data);
    }
  }

  // 如果是16位，转换为8位用于WebP
  if (bps == 16)
  {
    cv::Mat image8;
    // 使用更精确的转换：16位范围是0-65535，8位范围是0-255
    // 使用255.0/65535.0 ≈ 0.00389 作为缩放因子
    image.convertTo(image8, CV_8U, 255.0 / 65535.0);
    return image8;
  }

  return image.clone();
}
