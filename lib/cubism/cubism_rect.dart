/// Class representing a 2D bounding rectangle with floating point coordinates.
class CubismRect {
  double x;
  double y;
  double width;
  double height;

  CubismRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Center X coordinate.
  double get centerX => x + 0.5 * width;

  /// Center Y coordinate.
  double get centerY => y + 0.5 * height;

  /// Right boundary X coordinate.
  double get right => x + width;

  /// Bottom boundary Y coordinate.
  double get bottom => y + height;

  /// Clones or updates the rectangle from another [CubismRect].
  CubismRect copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return CubismRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() => 'CubismRect(x: $x, y: $y, w: $width, h: $height)';
}
