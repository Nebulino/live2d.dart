# live2d.dart

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Custom-green.svg)](LICENSE)

A high-performance, cross-platform **Live2D Cubism** viewer and controller for Flutter, powered by WebGL, PixiJS, and WebView.

Brings anime avatars and interactive Live2D characters directly into your Flutter UI with transparent backgrounds, full touch interaction, motion/expression playback, and zero native NDK/C++ compilation headache.

---

## ✨ Features

- 🎭 **Cubism 2.1 & 4/5 Support**: Render both `.model3.json` (`.moc3`) and legacy `.model.json` (`.moc`) models out of the box.
- 🪟 **Transparent Background by Default**: Place your Live2D models on top of any Flutter widget (gradients, custom backgrounds, overlays) using a simple `Stack`.
- 📁 **Universal Model Loading**: Load models from:
  - **Remote URLs** (`https://.../model.model3.json`)
  - **Flutter Assets** (`assets/models/hiyori/hiyori.model3.json`) via built-in zero-config asset server.
  - **Local Filesystem** (`/sdcard/...` or app document directories).
- 🎮 **Reactive Controller (`Live2DController`)**:
  - Play motion groups (`startMotion('TapBody')`) with priority and completion callbacks.
  - Switch expressions (`setExpression('f01')`).
  - Read & set individual parameters (`setParameter(DefaultParameterID.paramAngleX, 30.0)`).
  - Touch tracking / gaze control (`lookAt(x, y)`).
  - Zoom & pan offset controls (`setScale`, `setPosition`).
- 🎯 **Hit Area Detection**: Listen for taps on model hit areas (e.g., `Head`, `Body`) via `onHit` callback or reactive stream.
- ⚡ **Zero Native C++ Build Setup**: No need for Android NDK, CMake, or complex iOS CocoaPods compilation—runs smoothly on top of standard WebView and WebGL.

---

## 🚀 Getting Started

### 1. Add dependency

Add `live2d` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  live2d:
    git:
      url: https://github.com/Nebulino/live2d.dart.git
```

### 2. (Optional) Configure Local Assets

If loading models from local assets, declare the model folder in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/hiyori/
```

> **Note**: The folder must contain your `*.model3.json` along with its referenced `.moc3`, textures (`.png`), and motions.

---

## 💡 Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:live2d/live2d.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Live2DController _controller = Live2DController();

  @override
  void initState() {
    super.initState();

    _controller.onHit = (hitAreas) {
      debugPrint('Hit detected on: $hitAreas');
      if (hitAreas.contains('Head')) {
        _controller.startMotion('Tap');
      }
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Flutter Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E2E), Color(0xFF2A2B3D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 2. Transparent Live2D Viewer
            Live2DViewer(
              controller: _controller,
              initialModelUrl:
                  'https://cdn.jsdelivr.net/gh/guansss/pixi-live2d-display/test/assets/haru/haru_greeter_t03.model3.json',
              fit: Live2DFit.contain,
              scale: 1.0,
              autoInteract: true,
              loadingBuilder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),

            // 3. Floating Action Controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () => _controller.startMotion('TapBody'),
                child: const Text('Play Animation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🕹️ Live2DController API

| Method | Description |
| :--- | :--- |
| `loadModel(source, {fit, scale, autoInteract})` | Loads a model from network URL, asset, or local file. |
| `startMotion(group, {index, priority})` | Plays an animation from a motion group. |
| `setExpression(id)` | Switches the model's facial expression. |
| `setParameter(id, value)` | Overrides a specific parameter value (e.g. `ParamAngleX`). |
| `lookAt(x, y)` | Centers the model's focus on normalized coordinates `(-1.0 .. 1.0)`. |
| `setScale(scale)` | Adjusts the model zoom scale multiplier. |
| `setPosition(x, y)` | Translates model offset in pixels from the center. |
| `setFit(fit)` | Changes fitting mode (`contain`, `cover`, `fitWidth`, `fitHeight`, `none`). |
| `setInteractive(enabled)` | Enables or disables mouse/touch tracking and hit testing. |
| `reset()` | Restores scale and position to defaults. |

### Event Callbacks & Streams

```dart
// Callbacks
controller.onModelLoaded = (Live2DModelInfo info) {
  print('Loaded model with motions: ${info.motionGroups}');
};

controller.onHit = (List<String> hitAreas) {
  print('User tapped: $hitAreas');
};

controller.onMotionFinished = (String group, int index) {
  print('Motion $group finished');
};

controller.onError = (String error) {
  print('Error: $error');
};

// Or use reactive streams:
controller.onLoadedStream.listen((info) => ...);
controller.onHitStream.listen((hitAreas) => ...);
```

---

## 📱 Platform Support

| Platform | Support | Note |
| :---: | :---: | :--- |
| **Android** | ✅ | Minimum API 21+ |
| **iOS** | ✅ | Minimum iOS 12+ (WKWebView) |
| **macOS** | ✅ | Supported via `webview_flutter_wkwebview` |
| **Web** | ✅ | Supported via `webview_flutter_web` |
| **Windows / Linux** | ⚠️ | Requires standard desktop webview integration |

---

## ⚖️ License & Notice

- This package is released under the [Nebulino Public License](LICENSE).
- **Live2D Cubism Notice**: The Live2D Cubism Core and Web SDK are proprietary technologies owned by [Live2D Inc.](https://www.live2d.com/) Please verify and comply with the [Live2D Software License Agreement](https://www.live2d.com/eula/live2d-open-software-license-agreement_en.html) when using Live2D models in commercial projects.
