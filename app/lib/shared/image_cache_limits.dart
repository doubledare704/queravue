import 'package:flutter/painting.dart';

const maxCachedImageBytes = 32 * 1024 * 1024;
const maxCachedImages = 20;

void limitImageCache() {
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = maxCachedImageBytes
    ..maximumSize = maxCachedImages;
}
