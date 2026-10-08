import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'live2d_asset_server.dart';
import 'live2d_controller.dart';

/// Flutter widget that renders Live2D Cubism models via WebGL and PixiJS.
class Live2DViewer extends StatefulWidget {
  /// The controller to command and inspect the Live2D model.
  final Live2DController controller;

  /// Optional initial model to load automatically once the viewer is initialized.
  /// Can be:
  /// - A remote HTTP/HTTPS URL (`https://.../model3.json`)
  /// - A Flutter asset key (`assets/models/hiyori/hiyori.model3.json`)
  /// - A local file path (`/path/to/model.model3.json`)
  final String? initialModelUrl;

  /// How the model should fit within the viewer area. Defaults to [Live2DFit.contain].
  final Live2DFit fit;

  /// Initial zoom / scale multiplier (default: 1.0).
  final double scale;

  /// Whether the model should automatically follow pointer/touch events. Defaults to true.
  final bool autoInteract;

  /// Background color of the viewer. Transparent by default so it blends into Flutter UI.
  final Color backgroundColor;

  /// Optional custom widget to show while a model is loading.
  final WidgetBuilder? loadingBuilder;

  /// Optional custom widget to show when an error occurs.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Optional custom CDN / URL for Cubism 4/5 Core JavaScript runtime.
  final String? cubismCoreJsUrl;

  /// Optional custom CDN / URL for Cubism 2.1 Core JavaScript runtime.
  final String? cubism2CoreJsUrl;

  /// Optional custom CDN / URL for Pixi.js runtime.
  final String? pixiJsUrl;

  /// Optional custom CDN / URL for pixi-live2d-display runtime.
  final String? pixiLive2dJsUrl;

  const Live2DViewer({
    super.key,
    required this.controller,
    this.initialModelUrl,
    this.fit = Live2DFit.contain,
    this.scale = 1.0,
    this.autoInteract = true,
    this.backgroundColor = Colors.transparent,
    this.loadingBuilder,
    this.errorBuilder,
    this.cubismCoreJsUrl,
    this.cubism2CoreJsUrl,
    this.pixiJsUrl,
    this.pixiLive2dJsUrl,
  });

  @override
  State<Live2DViewer> createState() => _Live2DViewerState();
}

class _Live2DViewerState extends State<Live2DViewer> {
  late final Live2DAssetServer _assetServer;
  late final WebViewController _webViewController;
  bool _serverStarted = false;

  @override
  void initState() {
    super.initState();
    _initViewer();
  }

  Future<void> _initViewer() async {
    _assetServer = Live2DAssetServer(
      cubismCoreJsUrl: widget.cubismCoreJsUrl,
      cubism2CoreJsUrl: widget.cubism2CoreJsUrl,
      pixiJsUrl: widget.pixiJsUrl,
      pixiLive2dJsUrl: widget.pixiLive2dJsUrl,
    );

    await _assetServer.start();
    _serverStarted = true;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..addJavaScriptChannel(
        'Live2DChannel',
        onMessageReceived: (JavaScriptMessage message) {
          widget.controller.handleJsMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(_assetServer.playerUrl));

    widget.controller.attach(
      webViewController: _webViewController,
      assetServer: _assetServer,
    );

    if (widget.initialModelUrl != null) {
      widget.controller.whenReady.then((_) {
        if (!mounted) return;
        widget.controller.loadModel(
          widget.initialModelUrl!,
          fit: widget.fit,
          scale: widget.scale,
          autoInteract: widget.autoInteract,
        );
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant Live2DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _webViewController.setBackgroundColor(widget.backgroundColor);
    }
  }

  @override
  void dispose() {
    _assetServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_serverStarted) {
      return widget.loadingBuilder != null
          ? widget.loadingBuilder!(context)
          : const SizedBox.shrink();
    }

    return ValueListenableBuilder<Live2DState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _webViewController),
            if (state.isLoading && widget.loadingBuilder != null)
              widget.loadingBuilder!(context),
            if (state.error != null && widget.errorBuilder != null)
              widget.errorBuilder!(context, state.error!),
          ],
        );
      },
    );
  }
}
