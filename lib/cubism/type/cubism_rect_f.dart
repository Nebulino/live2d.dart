/*
 * Copyright (c) 2020.
 * Author: Nebulino
 * Site: https://nebulino.cloud/blog
 * General Copyright: https://github.com/CloudNebby/THE-LICENSE/blob/master/LICENSE.md/LICENSE.md
 *
 * Any component, part, etcetera are under the Live2D Inc.
 * https://www.live2d.com/eula/live2d-open-software-license-agreement_en.html.
 * Those components are under Their License Agreement.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

import 'package:flutter/foundation.dart';

/// Class that defines a rectangular shape.
/// Coordinates and length are [double] values.
class CubismRect {
  double x;
  double y;
  double width;
  double height;

  /// Constructor
  /// [x] : Leftmost X coordinate.
  /// [y] : Top Y coordinate.
  /// [width] : The width of the rectangle.
  /// [height] : The height of the rectangle.
  CubismRect({
    @required this.x,
    @required this.y,
    @required this.width,
    @required this.height,
  });

  /// Get the X coordinate of the center of the rectangle.
  double getCenterX() => x + 0.5 * width;

  /// Get the Y coordinate of the center of the rectangle
  double getCenterY() => y + 0.5 * height;

  /// Get the right X coordinate.
  double getRight() => x + width;

  /// Get the bottom Y coordinate.
  double getBottom() => y + height;

  /// Set a new Rect from a given [CubismRect].
  CubismRect setRect({CubismRect cubismRect}) {
    return CubismRect(
      x: cubismRect.x,
      y: cubismRect.y,
      width: cubismRect.width,
      height: cubismRect.height,
    );
  }
}
