import 'dart:ui' as ui show Image;
import 'dart:ui';

class ImageNode {
  int curIndex;
  int index;
  Path path;
  Rect rect;
  // ignore: undefined_class
  ui.Image image;

  int getXIndex(int level) {
    return index % level;
  }

  int getYIndex(int level) {
    return (index / level).floor();
  }
}