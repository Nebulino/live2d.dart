import 'package:flutter/foundation.dart';

class CubismRect {
  double x;
  double y;
  double width;
  double height;

  CubismRect({
    @required this.x,
    @required this.y,
    @required this.width,
    @required this.height,
  });

  double getCenterX() => x + 0.5 * width;

  double getCenterY() => y + 0.5 * height;

  double getRight() => x + width;

  double getBottom() => y + height;

  CubismRect setRect({CubismRect cubismRect}) {
    return CubismRect(
      x: cubismRect.x,
      y: cubismRect.y,
      width: cubismRect.width,
      height: cubismRect.height,
    );
  }
}
