#include "raw_processor.h"
#include <iostream>
#include <filesystem>
#include <chrono>

int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    std::cout << "用法: " << argv[0] << " <RAW文件路径> [输出WebP文件路径]" << std::endl;
    std::cout << "示例: " << argv[0] << " DSC02975.ARW output.webp" << std::endl;
    return 1;
  }

  std::string inputFile = argv[1];
  std::string outputFile;

  if (argc >= 3)
  {
    outputFile = argv[2];
  }
  else
  {
    // 自动生成输出文件名，保存到output目录
    std::filesystem::path inputPath(inputFile);
    outputFile = "output/" + inputPath.stem().string() + ".webp";
  }

  std::cout << "开始处理RAW文件: " << inputFile << std::endl;
  std::cout << "输出文件: " << outputFile << std::endl;
  std::cout << "===========================================" << std::endl;

  auto total_start = std::chrono::high_resolution_clock::now();

  try
  {
    RawProcessor processor;

    // 打印处理参数
    processor.printProcessingParams();
    std::cout << "===========================================" << std::endl;

    // 打开RAW文件
    if (!processor.openFile(inputFile))
    {
      std::cerr << "无法打开RAW文件" << std::endl;
      return 1;
    }

    // 解码RAW文件
    std::cout << "正在解码RAW文件..." << std::endl;
    if (!processor.decodeRaw())
    {
      std::cerr << "RAW文件解码失败" << std::endl;
      return 1;
    }

    // 打印图像信息
    processor.printImageInfo();

    // 保存为WebP格式
    std::cout << "正在保存为WebP格式..." << std::endl;
    if (!processor.saveAsWebP(outputFile, 100))
    {
      std::cerr << "保存WebP文件失败" << std::endl;
      return 1;
    }

    auto total_end = std::chrono::high_resolution_clock::now();
    auto total_duration = std::chrono::duration_cast<std::chrono::milliseconds>(total_end - total_start);

    std::cout << "===========================================" << std::endl;
    std::cout << "✓ 总处理时间: " << total_duration.count() << "ms" << std::endl;
    std::cout << "处理完成！" << std::endl;
    return 0;
  }
  catch (const std::exception &e)
  {
    std::cerr << "程序异常: " << e.what() << std::endl;
    return 1;
  }
}
