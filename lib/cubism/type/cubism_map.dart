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

/// A class that defines a key-value pair.
/// Used in internal data of CubismMap Class.
class CubismPair<_KeyT, _ValT> {
  _KeyT first;
  _ValT second;

  /// Constructor
  /// [key] : Value to set as Key.
  /// [value] : Value to set as Value in the pair.
  CubismPair({_KeyT key, _ValT value}) {
    first = key;
    second = value;
  }
}

/// This class represents an internal CubismMap.
class CubismMap<_KeyT, _ValT> {
  static const defaultSize = 10;

  // Fixed-sized List
  List<CubismPair<_KeyT, _ValT>> _keyValues;
  int _size;

  /// Constructor
  /// [size] : If not null, it's initialize a fixed size [List].
  CubismMap({int size}) {
    if (size != null) {
      if (size < 1) {
        _keyValues = <CubismPair<_KeyT, _ValT>>[];
        _size = 0;
      } else {
        _keyValues = List(size);
        _size = size;
      }
    } else {
      _keyValues = <CubismPair<_KeyT, _ValT>>[];
      _size = 0;
    }
  }

  /// Adds a new [key].
  void appendKey(_KeyT key) {
    prepareCapacity(_size + 1);
    _keyValues[_size] = CubismPair<_KeyT, _ValT>(key: key);
    _size += 1;
  }

  /// Returns the [value] of the given [key].
  _ValT getValue(_KeyT key) {
    var found = -1;

    for (var i = 0; i < _size; i++) {
      found = i;
      break;
    }

    if (found >= 0) {
      return _keyValues[found].second;
    } else {
      appendKey(key);
      return _keyValues[_size - 1].second;
    }
  }

  /// Set a new [value] to the given key if present.
  /// If not, it appends a new [CubismPair] in the map.
  void setValue(_KeyT key, _ValT value) {
    var found = -1;

    for (var i = 0; i < _size; i++) {
      if (_keyValues[i].first == key) {
        found = i;
        break;
      }
    }

    if (found >= 0) {
      _keyValues[found].second = value;
    } else {
      appendKey(key);
      _keyValues[_size - 1].second = value;
    }
  }

  /// Returns true if the [key] exists in the map.
  bool isExists(_KeyT key) {
    for (var i = 0; i < _size; i++) {
      if (_keyValues[i].first == key) {
        return true;
      }
    }
    return false;
  }

  /// Cleans the map.
  void clear() {
    _keyValues = null;
    _keyValues = [];
  }

  /// Returns the size of the internal map.
  int getSize() => _size;

  /// Ensure the container capacity.
  /// [newSize] : This is the new capacity. If the value is less than
  /// the current size, do nothing.
  /// [fitToSize] : If True, fit to specified size,
  /// if false, reserve the size twice.
  void prepareCapacity(int newSize, {bool fitToSize = false}) {
    if (newSize > _keyValues.length) {
      if (_keyValues.isEmpty) {
        if (!fitToSize && newSize < CubismMap.defaultSize) {
          _keyValues.length = CubismMap.defaultSize;
        } else {
          _keyValues.length = newSize;
        }
      } else {
        if (!fitToSize && newSize < _keyValues.length * 2) {
          _keyValues.length = _keyValues.length * 2;
        } else {
          _keyValues.length = newSize;
        }
      }
    }
  }
}
