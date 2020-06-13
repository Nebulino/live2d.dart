class CubismPair<_KeyT, _ValT> {
  _KeyT first;
  _ValT second;

  CubismPair({_KeyT key, _ValT value}) {
    first = key;
    second = value;
  }
}

class CubismMap<_KeyT, _ValT> {
  static const defaultSize = 10;

  // Fixed-sized List
  List<CubismPair<_KeyT, _ValT>> _keyValues;
  int _size;

  CubismMap(int size) {
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

  void appendKey(_KeyT key) {
    prepareCapacity(_size + 1);
    _keyValues[_size] = CubismPair<_KeyT, _ValT>(key: key);
    _size += 1;
  }

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

  bool isExists(_KeyT key) {
    for (var i = 0; i < _size; i++) {
      if (_keyValues[i].first == key) {
        return true;
      }
    }
    return false;
  }

  void clear() {
    _keyValues = null;
    _keyValues = [];
  }

  int getSize() => _size;

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
