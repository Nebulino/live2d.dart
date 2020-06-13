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

@immutable
class CubismString {
  // Make it immutable
  final String string;

  const CubismString(this.string);

  CubismString append(String stringToAppend, {int length}) {
    if (length != null) {
      return CubismString(string + stringToAppend.substring(0, length));
    }
    return CubismString(string + stringToAppend);
  }

  CubismString expansion(int length, String newString) {
    for (var i = 0; i < length; i++) {
      append(newString);
    }
    return this;
  }

  // TODO: need to check this...
  int getBytes() {
    return Uri.encodeComponent(string).replaceAllMapped(RegExp('/%../g'),
        (match) {
      return 'x';
    }).length;
  }
}
