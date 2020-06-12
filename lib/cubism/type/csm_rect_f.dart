import 'package:flutter/foundation.dart';

class CsmRect {
  double x;
  double y;
  double width;
  double height;

  CsmRect({
    @required this.x,
    @required this.y,
    @required this.width,
    @required this.height,
  });

  double getCenterX() => x + 0.5 * width;

  double getCenterY() => y + 0.5 * height;

  double getRight() => x + width;

  double getBottom() => y + height;

  CsmRect setRect({CsmRect csmRect}) {
    return CsmRect(
      x: csmRect.x,
      y: csmRect.y,
      width: csmRect.width,
      height: csmRect.height,
    );
  }
}
