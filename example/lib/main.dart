import 'package:flutter/material.dart';
import 'package:live2d/live2d.dart';

void main() {
  runApp(const Live2DExampleApp());
}

class Live2DExampleApp extends StatelessWidget {
  const Live2DExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live2D Viewer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const Live2DViewerScreen(),
    );
  }
}

class Live2DViewerScreen extends StatefulWidget {
  const Live2DViewerScreen({super.key});

  @override
  State<Live2DViewerScreen> createState() => _Live2DViewerScreenState();
}

class _Live2DViewerScreenState extends State<Live2DViewerScreen> {
  final Live2DController _controller = Live2DController();

  static const String _haruModelUrl =
      'https://cdn.jsdelivr.net/gh/guansss/pixi-live2d-display/test/assets/haru/haru_greeter_t03.model3.json';
  static const String _shizukuModelUrl =
      'https://cdn.jsdelivr.net/gh/guansss/pixi-live2d-display/test/assets/shizuku/shizuku.model.json';

  String _currentModelUrl = _haruModelUrl;
  double _scale = 1.0;
  String _statusText = 'Initializing Live2D...';

  @override
  void initState() {
    super.initState();

    _controller.onModelLoaded = (info) {
      if (mounted) {
        setState(() {
          _statusText =
              'Model Loaded: ${info.motionGroups.length} motions, ${info.expressions.length} expressions';
        });
      }
    };

    _controller.onHit = (hitAreas) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tapped Hit Area: ${hitAreas.join(', ')}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    };

    _controller.onError = (error) {
      if (mounted) {
        setState(() {
          _statusText = 'Error: $error';
        });
      }
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchModel(String url) {
    setState(() {
      _currentModelUrl = url;
      _statusText = 'Loading model...';
    });
    _controller.loadModel(url, scale: _scale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live2D Flutter Viewer'),
        backgroundColor: Colors.black.withAlpha(128),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Model',
            onSelected: _switchModel,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _haruModelUrl,
                child: Text('Haru (Cubism 4 - .model3.json)'),
              ),
              const PopupMenuItem(
                value: _shizukuModelUrl,
                child: Text('Shizuku (Cubism 2 - .model.json)'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Beautiful Flutter background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),

          // 2. Live2D WebGL Viewer (renders on transparent background)
          Live2DViewer(
            controller: _controller,
            initialModelUrl: _currentModelUrl,
            fit: Live2DFit.contain,
            scale: _scale,
            autoInteract: true,
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorBuilder: (context, error) => Center(
              child: Card(
                color: Colors.red.withAlpha(200),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Failed to load: $error'),
                ),
              ),
            ),
          ),

          // 3. Floating Control Bar at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.black.withAlpha(180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Motion Buttons
                    ValueListenableBuilder<Live2DState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        final motions = state.modelInfo?.motionGroups ?? [];
                        if (motions.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: motions.map((group) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ActionChip(
                                  label: Text(group),
                                  onPressed: () {
                                    _controller.startMotion(group);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // Zoom / Scale Slider
                    Row(
                      children: [
                        const Icon(Icons.zoom_in, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _scale,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: '${_scale.toStringAsFixed(1)}x',
                            onChanged: (val) {
                              setState(() => _scale = val);
                              _controller.setScale(val);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Reset View',
                          onPressed: () {
                            setState(() => _scale = 1.0);
                            _controller.reset();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
