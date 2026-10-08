# Live2D Flutter Developer Guide

This guide provides an in-depth walkthrough on integrating and customizing Live2D Cubism models in your Flutter applications using **`live2d`**.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Supported Model Formats](#2-supported-model-formats)
3. [Loading Models](#3-loading-models)
   - [Remote HTTP/HTTPS URLs](#a-remote-urls)
   - [Bundled Flutter Assets](#b-bundled-flutter-assets)
   - [Local Device Storage](#c-local-device-storage)
4. [Controlling the Model](#4-controlling-the-model)
   - [Playing Motions](#playing-motions)
   - [Changing Facial Expressions](#changing-facial-expressions)
   - [Manipulating Parameters Manually](#manipulating-parameters-manually)
   - [Gaze & Focus (`lookAt`)](#gaze--focus-lookat)
   - [Tapping Hit Areas](#tapping-hit-areas)
   - [Scaling, Positioning, and Fitting](#scaling-positioning-and-fitting)
5. [Reactive State & Streams](#5-reactive-state--streams)
6. [Offline Setup & Custom CDNs](#6-offline-setup--custom-cdns)
7. [Best Practices & Performance](#7-best-practices--performance)

---

## 1. Architecture Overview

Live2D models require specialized deformation algorithms provided by Live2D Inc.'s proprietary `CubismCore` library. 

This package bridges Flutter and the WebGL-based **PixiJS** runtime:

```
┌────────────────────────────────────────────────────────┐
│                   Flutter Application                  │
│                                                        │
│   ┌─────────────────────┐   ┌──────────────────────┐   │
│   │    Live2DViewer     │   │   Live2DController   │   │
│   └──────────┬──────────┘   └──────────▲───────────┘   │
│              │                         │               │
│              ▼                         │ Events/State  │
│   ┌────────────────────────────────────┴───────────┐   │
│   │               WebView (Transparent)            │   │
│   │                                                │   │
│   │   ┌──────────────┐       ┌─────────────────┐   │   │
│   │   │ Pixi.js 7.x  │ <───> │ pixi-live2d-    │   │   │
│   │   │ (WebGL 2)    │       │ display         │   │   │
│   │   └──────────────┘       └────────┬────────┘   │   │
│   │                                   │            │   │
│   │                          ┌────────▼────────┐   │   │
│   │                          │ Live2DCubismCore│   │   │
│   │                          └─────────────────┘   │   │
│   └────────────────────────────────────────────────┘   │
│                          ▲                             │
│                          │ Local HTTP Fetch            │
│   ┌──────────────────────┴─────────────────────────┐   │
│   │        Live2DAssetServer (127.0.0.1:port)      │   │
│   │   (Serves rootBundle assets & local files)     │   │
│   └────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────┘
```

- **Transparent Canvas**: The WebGL canvas automatically clears to `rgba(0,0,0,0)`, allowing the viewer to be placed on top of any Flutter gradient, image, or UI widget.
- **Embedded Asset Server**: Standard WebViews enforce strict CORS and file-scheme restrictions. The built-in `Live2DAssetServer` runs locally on loopback IPv4 (`127.0.0.1`), ensuring relative texture and `.moc3` file requests succeed effortlessly across Android, iOS, and macOS.

---

## 2. Supported Model Formats

`live2d` supports both major Live2D Cubism generations:

| Generation | Descriptor File | Model Binary | Notes |
| :--- | :--- | :--- | :--- |
| **Cubism 4 / 5** | `*.model3.json` | `*.moc3` | Modern format created with Cubism Editor 3.0–5.x. |
| **Cubism 2.1** | `*.model.json` | `*.moc` | Legacy format. Fully supported out of the box. |

---

## 3. Loading Models

### A. Remote URLs

Provide any valid public URL pointing to the JSON descriptor:

```dart
await controller.loadModel(
  'https://cdn.jsdelivr.net/gh/guansss/pixi-live2d-display/test/assets/haru/haru_greeter_t03.model3.json',
  fit: Live2DFit.contain,
  scale: 1.0,
);
```

> **CORS Tip**: Ensure your remote server or CDN emits `Access-Control-Allow-Origin: *` headers for all model files and textures.

---

### B. Bundled Flutter Assets

1. Organize your model folder in your Flutter project:
   ```
   assets/
     models/
       hiyori/
         hiyori.model3.json
         hiyori.moc3
         hiyori.physics3.json
         hiyori.pose3.json
         textures/
           texture_00.png
         motions/
           idle.motion3.json
           tap.motion3.json
   ```

2. Declare the folder in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/models/hiyori/
       - assets/models/hiyori/textures/
       - assets/models/hiyori/motions/
   ```

3. Load using the asset key:
   ```dart
   await controller.loadModel('assets/models/hiyori/hiyori.model3.json');
   ```

The local `Live2DAssetServer` will automatically serve all referenced textures and motions directly from Flutter's `rootBundle`.

---

### C. Local Device Storage

To load models downloaded to the device's storage (e.g. via `path_provider`):

```dart
final Directory docDir = await getApplicationDocumentsDirectory();
final String modelPath = '${docDir.path}/downloaded_model/character.model3.json';

await controller.loadModel(modelPath);
```

---

## 4. Controlling the Model

### Playing Motions

Play an animation from a named group:

```dart
// Normal motion
await controller.startMotion('TapBody');

// Motion with index and force priority (3)
await controller.startMotion('Special', index: 1, priority: 3);
```

Listen for motion completion:

```dart
controller.onMotionFinished = (String group, int index) {
  print('Motion $group ($index) finished playing');
};
```

---

### Changing Facial Expressions

```dart
// By expression name
await controller.setExpression('f01');

// Or by index
await controller.setExpression(0);
```

---

### Manipulating Parameters Manually

You can programmatically adjust individual parameters in real-time (e.g., in response to sensor input or sliders) using standard constants from `DefaultParameterID`:

```dart
// Turn head horizontally (-30.0 to 30.0)
await controller.setParameter(DefaultParameterID.paramAngleX, 25.0);

// Open mouth (0.0 to 1.0)
await controller.setParameter(DefaultParameterID.paramMouthOpenY, 0.8);

// Eye smile
await controller.setParameter(DefaultParameterID.paramEyeLSmile, 1.0);
await controller.setParameter(DefaultParameterID.paramEyeRSmile, 1.0);
```

---

### Gaze & Focus (`lookAt`)

Direct the character's focus to specific coordinates:

```dart
// (0.0, 0.0) is dead center
// (-1.0, -1.0) is bottom-left
// (1.0, 1.0) is top-right
await controller.lookAt(0.5, 0.5);
```

By default, `autoInteract: true` enables the model to automatically track touch and pointer movements across the screen.

---

### Tapping Hit Areas

When an author designs a model in Live2D Cubism Editor, they can configure hit areas (e.g., `Head`, `Body`):

```dart
controller.onHit = (List<String> hitAreas) {
  if (hitAreas.contains('Head')) {
    controller.startMotion('TapHead');
    controller.setExpression('f02');
  } else if (hitAreas.contains('Body')) {
    controller.startMotion('TapBody');
  }
};
```

---

### Scaling, Positioning, and Fitting

```dart
// Change fit strategy
await controller.setFit(Live2DFit.contain);

// Zoom in / out
await controller.setScale(1.5);

// Move position in pixels from center
await controller.setPosition(0, -50);

// Reset back to defaults
await controller.reset();
```

---

## 5. Reactive State & Streams

`Live2DController` is a `ValueNotifier<Live2DState>`, so you can rebuild widgets reactively without calling `setState`:

```dart
ValueListenableBuilder<Live2DState>(
  valueListenable: controller,
  builder: (context, state, child) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }
    if (state.error != null) {
      return Text('Error: ${state.error}');
    }
    if (state.isLoaded) {
      return Text('Motions: ${state.modelInfo?.motionGroups.join(', ')}');
    }
    return const SizedBox.shrink();
  },
)
```

---

## 6. Offline Setup & Custom CDNs

By default, the WebGL player downloads the necessary runtimes (Cubism Core, PixiJS, `pixi-live2d-display`) from official, high-speed CDNs.

If your application needs to work 100% offline in isolated environments:
1. Place the 4 required JavaScript runtime files inside your `assets/` folder.
2. Provide the local asset URLs to `Live2DViewer`:

```dart
Live2DViewer(
  controller: controller,
  cubismCoreJsUrl: 'assets/js/live2dcubismcore.min.js',
  pixiJsUrl: 'assets/js/pixi.min.js',
  pixiLive2dJsUrl: 'assets/js/index.min.js',
)
```

---

## 7. Best Practices & Performance

1. **Always dispose controllers**: Call `controller.dispose()` in your widget's `dispose()` method to free streams and event listeners.
2. **Stack layer ordering**: Keep heavy UI widgets underneath the transparent `Live2DViewer` and only place minimal control buttons on top.
3. **Texture Atlas sizes**: On mobile devices, 2048×2048 texture atlases provide the best balance between crisp visuals and low GPU memory footprint.
