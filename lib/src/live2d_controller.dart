import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'live2d_asset_server.dart';

/// Fitting strategy for the Live2D model inside the viewport.
enum Live2DFit {
  contain,
  cover,
  fitWidth,
  fitHeight,
  none;

  String toJsString() {
    switch (this) {
      case Live2DFit.contain:
        return 'contain';
      case Live2DFit.cover:
        return 'cover';
      case Live2DFit.fitWidth:
        return 'fitWidth';
      case Live2DFit.fitHeight:
        return 'fitHeight';
      case Live2DFit.none:
        return 'none';
    }
  }
}

/// Metadata about the currently loaded Live2D model.
class Live2DModelInfo {
  final String modelUrl;
  final double width;
  final double height;
  final List<String> motionGroups;
  final List<String> expressions;

  const Live2DModelInfo({
    required this.modelUrl,
    required this.width,
    required this.height,
    required this.motionGroups,
    required this.expressions,
  });

  factory Live2DModelInfo.fromJson(Map<String, dynamic> json) {
    return Live2DModelInfo(
      modelUrl: (json['modelUrl'] as String?) ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      motionGroups: (json['motionGroups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      expressions: (json['expressions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// State representation of the Live2D viewer.
class Live2DState {
  final bool isReady;
  final bool isLoading;
  final bool isLoaded;
  final Live2DModelInfo? modelInfo;
  final String? error;

  const Live2DState({
    this.isReady = false,
    this.isLoading = false,
    this.isLoaded = false,
    this.modelInfo,
    this.error,
  });

  Live2DState copyWith({
    bool? isReady,
    bool? isLoading,
    bool? isLoaded,
    Live2DModelInfo? modelInfo,
    String? error,
    bool clearError = false,
    bool clearModel = false,
  }) {
    return Live2DState(
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: clearModel ? false : (isLoaded ?? this.isLoaded),
      modelInfo: clearModel ? null : (modelInfo ?? this.modelInfo),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller for interacting with and controlling Live2D models.
class Live2DController extends ValueNotifier<Live2DState> {
  WebViewController? _webViewController;
  Live2DAssetServer? _assetServer;

  final Completer<void> _readyCompleter = Completer<void>();

  // Event stream controllers
  final _onLoadedController = StreamController<Live2DModelInfo>.broadcast();
  final _onHitController = StreamController<List<String>>.broadcast();
  final _onMotionFinishedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onErrorController = StreamController<String>.broadcast();

  // Callbacks
  void Function(Live2DModelInfo info)? onModelLoaded;
  void Function(List<String> hitAreas)? onHit;
  void Function(String group, int index)? onMotionFinished;
  void Function(String error)? onError;

  Live2DController() : super(const Live2DState());

  /// Future that completes when the underlying WebGL environment is ready.
  Future<void> get whenReady => _readyCompleter.future;

  /// Stream emitted when a model is successfully loaded.
  Stream<Live2DModelInfo> get onLoadedStream => _onLoadedController.stream;

  /// Stream emitted when user taps/clicks a model hit area.
  Stream<List<String>> get onHitStream => _onHitController.stream;

  /// Stream emitted when a motion animation finishes playing.
  Stream<Map<String, dynamic>> get onMotionFinishedStream =>
      _onMotionFinishedController.stream;

  /// Stream emitted on model loading or playback errors.
  Stream<String> get onErrorStream => _onErrorController.stream;

  /// Internal attachment of WebViewController and AssetServer by the Live2DViewer widget.
  void attach({
    required WebViewController webViewController,
    required Live2DAssetServer assetServer,
  }) {
    _webViewController = webViewController;
    _assetServer = assetServer;
  }

  /// Handles incoming messages sent from the JavaScript WebGL player.
  void handleJsMessage(String jsonStr) {
    try {
      final Map<String, dynamic> msg =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final String action = msg['action'] as String? ?? '';
      final Map<String, dynamic> data =
          (msg['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      switch (action) {
        case 'onReady':
          value = value.copyWith(isReady: true);
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }
          break;

        case 'onModelLoaded':
          final info = Live2DModelInfo.fromJson(data);
          value = value.copyWith(
            isLoading: false,
            isLoaded: true,
            modelInfo: info,
            clearError: true,
          );
          _onLoadedController.add(info);
          onModelLoaded?.call(info);
          break;

        case 'onHit':
          final hitAreas = (data['hitAreas'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          _onHitController.add(hitAreas);
          onHit?.call(hitAreas);
          break;

        case 'onMotionFinished':
          final group = (data['group'] as String?) ?? '';
          final index = (data['index'] as num?)?.toInt() ?? 0;
          _onMotionFinishedController.add({'group': group, 'index': index});
          onMotionFinished?.call(group, index);
          break;

        case 'onError':
          final errorMsg = (data['message'] as String?) ?? 'Live2D Error';
          value = value.copyWith(
            isLoading: false,
            error: errorMsg,
          );
          _onErrorController.add(errorMsg);
          onError?.call(errorMsg);
          break;
      }
    } catch (e) {
      debugPrint('Live2DController message parse error: $e');
    }
  }

  /// Loads a Live2D model from an HTTP/HTTPS URL, a Flutter asset, or local file path.
  ///
  /// Examples:
  /// - Network URL: `loadModel('https://cdn.jsdelivr.net/.../model.model3.json')`
  /// - Asset: `loadModel('assets/models/hiyori/hiyori.model3.json')`
  /// - Local File: `loadModel('/sdcard/models/hiyori.model3.json')`
  Future<void> loadModel(
    String source, {
    Live2DFit fit = Live2DFit.contain,
    double scale = 1.0,
    bool autoInteract = true,
  }) async {
    await whenReady;

    value = value.copyWith(isLoading: true, clearError: true);

    String resolvedUrl = source.trim();

    if (resolvedUrl.startsWith('http://') ||
        resolvedUrl.startsWith('https://')) {
      // Direct remote URL
    } else if (resolvedUrl.startsWith('assets/') ||
        resolvedUrl.startsWith('packages/')) {
      // Local Flutter asset served via local server
      if (_assetServer != null) {
        resolvedUrl = _assetServer!.getAssetUrl(resolvedUrl);
      }
    } else {
      // Local file path
      if (_assetServer != null) {
        var path = resolvedUrl;
        if (path.startsWith('file://')) {
          path = path.replaceFirst('file://', '');
        }
        resolvedUrl = _assetServer!.getFileUrl(path);
      }
    }

    final jsCode = '''
      window.live2d.loadModel(${jsonEncode(resolvedUrl)}, {
        fit: ${jsonEncode(fit.toJsString())},
        scale: $scale,
        autoInteract: $autoInteract
      });
    ''';

    await _webViewController?.runJavaScript(jsCode);
  }

  /// Plays a motion from a group with priority (0: none, 1: idle, 2: normal, 3: force).
  Future<void> startMotion(
    String group, {
    int index = 0,
    int priority = 2,
  }) async {
    await whenReady;
    final jsCode =
        'window.live2d.startMotion(${jsonEncode(group)}, $index, $priority);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Switches the expression by name or index.
  Future<void> setExpression(dynamic expression) async {
    await whenReady;
    final jsCode =
        'window.live2d.setExpression(${jsonEncode(expression.toString())});';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Sets a model parameter value directly (e.g. `ParamAngleX`, `ParamMouthOpenY`).
  Future<void> setParameter(String id, double value) async {
    await whenReady;
    final jsCode = 'window.live2d.setParameter(${jsonEncode(id)}, $value);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Makes the model focus / gaze at the specified target coordinates.
  /// Standard coordinate system: (0, 0) is center, (-1, -1) bottom-left, (1, 1) top-right.
  Future<void> lookAt(double x, double y) async {
    await whenReady;
    final jsCode = 'window.live2d.lookAt($x, $y);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Sets the display scale multiplier of the model.
  Future<void> setScale(double scale) async {
    await whenReady;
    final jsCode = 'window.live2d.setScale($scale);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Adjusts the offset position (in pixels) of the model relative to the center.
  Future<void> setPosition(double x, double y) async {
    await whenReady;
    final jsCode = 'window.live2d.setPosition($x, $y);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Changes the fitting strategy dynamically.
  Future<void> setFit(Live2DFit fit) async {
    await whenReady;
    final jsCode = 'window.live2d.setFit(${jsonEncode(fit.toJsString())});';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Enables or disables interactive tracking and hit events.
  Future<void> setInteractive(bool enabled) async {
    await whenReady;
    final jsCode = 'window.live2d.setInteractive($enabled);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Resets scale and position to defaults.
  Future<void> reset() async {
    await whenReady;
    await _webViewController?.runJavaScript('window.live2d.reset();');
  }

  @override
  void dispose() {
    _onLoadedController.close();
    _onHitController.close();
    _onMotionFinishedController.close();
    _onErrorController.close();
    super.dispose();
  }
}
