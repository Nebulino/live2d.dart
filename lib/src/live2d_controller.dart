import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'live2d_asset_server.dart';

/// Strategy used to fit the Live2D model inside the available viewport.
enum Live2DFit {
  /// Scales the model uniformly so that it fits entirely within the view.
  contain,

  /// Scales the model uniformly so that it covers the entire view.
  cover,

  /// Scales the model so that its width matches the viewport width.
  fitWidth,

  /// Scales the model so that its height matches the viewport height.
  fitHeight,

  /// Leaves the model at its intrinsic pixel scale without auto-fitting.
  none;

  /// Returns the corresponding JavaScript fit string identifier.
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

/// Metadata and definition information for a loaded Live2D model.
class Live2DModelInfo {
  /// The resolved URL or asset path of the loaded model.
  final String modelUrl;

  /// The intrinsic width of the model canvas in pixels.
  final double width;

  /// The intrinsic height of the model canvas in pixels.
  final double height;

  /// List of available motion group names (e.g., `Idle`, `TapBody`).
  final List<String> motionGroups;

  /// List of available expression names or identifiers.
  final List<String> expressions;

  /// Creates a new instance of [Live2DModelInfo].
  const Live2DModelInfo({
    required this.modelUrl,
    required this.width,
    required this.height,
    required this.motionGroups,
    required this.expressions,
  });

  /// Constructs a [Live2DModelInfo] from raw JSON data sent by the WebGL player.
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

/// Snapshot of the current state of a [Live2DController].
class Live2DState {
  /// Whether the underlying WebGL environment and communication bridge are ready.
  final bool isReady;

  /// Whether a model load request is currently in progress.
  final bool isLoading;

  /// Whether a model has been successfully loaded into the viewer.
  final bool isLoaded;

  /// Details of the currently loaded model, or `null` if no model is loaded.
  final Live2DModelInfo? modelInfo;

  /// The last error message encountered, or `null` if healthy.
  final String? error;

  /// Creates a new [Live2DState].
  const Live2DState({
    this.isReady = false,
    this.isLoading = false,
    this.isLoaded = false,
    this.modelInfo,
    this.error,
  });

  /// Returns a copy of this state with the provided fields replaced.
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

/// Controller used to command, animate, and inspect a Live2D model.
///
/// Inherits from [ValueNotifier] to provide reactive state updates.
class Live2DController extends ValueNotifier<Live2DState> {
  WebViewController? _webViewController;
  Live2DAssetServer? _assetServer;

  final Completer<void> _readyCompleter = Completer<void>();

  final _onLoadedController = StreamController<Live2DModelInfo>.broadcast();
  final _onHitController = StreamController<List<String>>.broadcast();
  final _onMotionFinishedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onErrorController = StreamController<String>.broadcast();

  /// Callback invoked when a model successfully loads.
  void Function(Live2DModelInfo info)? onModelLoaded;

  /// Callback invoked when the user taps on one or more model hit areas.
  void Function(List<String> hitAreas)? onHit;

  /// Callback invoked when a motion animation finishes playing.
  void Function(String group, int index)? onMotionFinished;

  /// Callback invoked when an error occurs during loading or rendering.
  void Function(String error)? onError;

  /// Creates a new [Live2DController].
  Live2DController() : super(const Live2DState());

  /// A future that completes when the underlying WebGL environment is initialized.
  Future<void> get whenReady => _readyCompleter.future;

  /// A stream that emits whenever a model is successfully loaded.
  Stream<Live2DModelInfo> get onLoadedStream => _onLoadedController.stream;

  /// A stream that emits the list of tapped hit areas when user interacts.
  Stream<List<String>> get onHitStream => _onHitController.stream;

  /// A stream that emits when a motion completes with group name and index.
  Stream<Map<String, dynamic>> get onMotionFinishedStream =>
      _onMotionFinishedController.stream;

  /// A stream that emits error messages encountered during runtime.
  Stream<String> get onErrorStream => _onErrorController.stream;

  /// Attaches the controller to the given [WebViewController] and [Live2DAssetServer].
  ///
  /// This method is intended to be called internally by the viewer widget.
  void attach({
    required WebViewController webViewController,
    required Live2DAssetServer assetServer,
  }) {
    _webViewController = webViewController;
    _assetServer = assetServer;
  }

  /// Dispatches incoming JSON messages from the JavaScript WebGL player.
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

  /// Loads a Live2D model from an HTTP/HTTPS URL, a Flutter asset, or local file.
  ///
  /// The [source] can be:
  /// - A remote URL starting with `http://` or `https://`
  /// - A Flutter asset path such as `assets/models/hiyori/hiyori.model3.json`
  /// - A local filesystem path such as `/sdcard/model.model3.json`
  ///
  /// The [fit] parameter determines how the model adapts to the viewport.
  /// The [scale] specifies an additional zoom multiplier (default is 1.0).
  /// If [autoInteract] is `true`, the model tracks pointer and touch coordinates.
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
      // Remote URL
    } else if (resolvedUrl.startsWith('assets/') ||
        resolvedUrl.startsWith('packages/')) {
      // Asset served via embedded local server
      if (_assetServer != null) {
        resolvedUrl = _assetServer!.getAssetUrl(resolvedUrl);
      }
    } else {
      // Filesystem path
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

  /// Plays an animation motion from the specified [group].
  ///
  /// The [index] selects the specific motion index within the group.
  /// The [priority] defines the playback priority:
  /// - 0: None
  /// - 1: Idle
  /// - 2: Normal
  /// - 3: Force
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

  /// Switches the active facial expression by [expression] name or index.
  Future<void> setExpression(dynamic expression) async {
    await whenReady;
    final jsCode =
        'window.live2d.setExpression(${jsonEncode(expression.toString())});';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Sets a model parameter [id] directly to the specified [value].
  ///
  /// Example:
  /// ```dart
  /// await controller.setParameter('ParamAngleX', 30.0);
  /// ```
  Future<void> setParameter(String id, double value) async {
    await whenReady;
    final jsCode = 'window.live2d.setParameter(${jsonEncode(id)}, $value);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Focuses the model gaze on the specified normalized coordinates.
  ///
  /// The coordinate system ranges from -1.0 to 1.0, where (0, 0) is the center.
  Future<void> lookAt(double x, double y) async {
    await whenReady;
    final jsCode = 'window.live2d.lookAt($x, $y);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Sets the zoom / scale multiplier of the model.
  Future<void> setScale(double scale) async {
    await whenReady;
    final jsCode = 'window.live2d.setScale($scale);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Sets the positional offset in pixels of the model relative to the center.
  Future<void> setPosition(double x, double y) async {
    await whenReady;
    final jsCode = 'window.live2d.setPosition($x, $y);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Changes the [fit] strategy dynamically.
  Future<void> setFit(Live2DFit fit) async {
    await whenReady;
    final jsCode = 'window.live2d.setFit(${jsonEncode(fit.toJsString())});';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Enables or disables pointer tracking and hit detection.
  Future<void> setInteractive(bool enabled) async {
    await whenReady;
    final jsCode = 'window.live2d.setInteractive($enabled);';
    await _webViewController?.runJavaScript(jsCode);
  }

  /// Resets scale and position to default center.
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
