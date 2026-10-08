import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'live2d_asset_server.dart';
import 'live2d_controller.dart';

/// An interactive Flutter widget that renders Live2D Cubism models via WebGL and PixiJS.
///
/// Features a transparent background by default, allowing models to be easily placed
/// inside a [Stack] above other Flutter widgets, gradients, and images.
class Live2DViewer extends StatefulWidget {
  /// The controller used to inspect and command the Live2D model.
  final Live2DController controller;

  /// An optional model URL or asset key to load immediately once initialized.
  ///
  /// Can be:
  /// - A remote HTTP/HTTPS URL (`https://.../model.model3.json`)
  /// - A Flutter asset path (`assets/models/hiyori/hiyori.model3.json`)
  /// - A local file path (`/path/to/model.model3.json`)
  final String? initialModelUrl;

  /// How the model adapts to the dimensions of the view. Defaults to [Live2DFit.contain].
  final Live2DFit fit;

  /// The initial scale multiplier applied to the model. Defaults to 1.0.
  final double scale;

  /// Whether the model automatically turns its head and eyes to follow touch and cursor moves.
  /// Defaults to `true`.
  final bool autoInteract;

  /// The background color of the viewer surface. Defaults to [Colors.transparent].
  final Color backgroundColor;

  /// An optional builder for displaying a custom widget while a model is loading.
  final WidgetBuilder? loadingBuilder;

  /// An optional builder for rendering a custom error overlay when an error occurs.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// An optional custom CDN or local URL for the Cubism 4/5 Core JavaScript runtime.
  final String? cubismCoreJsUrl;

  /// An optional custom CDN or local URL for the Cubism 2.1 Core JavaScript runtime.
  final String? cubism2CoreJsUrl;

  /// An optional custom CDN or local URL for the Pixi.js runtime.
  final String? pixiJsUrl;

  /// An optional custom CDN or local URL for the pixi-live2d-display runtime.
  final String? pixiLive2dJsUrl;

  /// Creates an interactive [Live2DViewer] widget.
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
