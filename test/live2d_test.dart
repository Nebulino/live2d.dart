import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:live2d/live2d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CubismRect Tests', () {
    test('Calculates center and boundaries correctly', () {
      final rect = CubismRect(x: 10, y: 20, width: 100, height: 200);

      expect(rect.centerX, 60);
      expect(rect.centerY, 120);
      expect(rect.right, 110);
      expect(rect.bottom, 220);
    });

    test('copyWith creates modified copy', () {
      final rect = CubismRect(x: 0, y: 0, width: 50, height: 50);
      final copy = rect.copyWith(width: 80);

      expect(copy.x, 0);
      expect(copy.width, 80);
      expect(copy.height, 50);
    });
  });

  group('DefaultParameterID Tests', () {
    test('Contains standard Cubism IDs', () {
      expect(DefaultParameterID.paramAngleX, 'ParamAngleX');
      expect(DefaultParameterID.paramEyeLOpen, 'ParamEyeLOpen');
      expect(DefaultParameterID.hitAreaHead, 'Head');
      expect(DefaultParameterID.hitAreaBody, 'Body');
    });
  });

  group('Live2DController Tests', () {
    test('Initial state is not ready and not loaded', () {
      final controller = Live2DController();
      expect(controller.value.isReady, false);
      expect(controller.value.isLoading, false);
      expect(controller.value.isLoaded, false);
      expect(controller.value.modelInfo, isNull);
      controller.dispose();
    });

    test('Handles onReady message', () async {
      final controller = Live2DController();

      controller.handleJsMessage(jsonEncode({
        'action': 'onReady',
        'data': {'version': '1.0.0'},
      }));

      expect(controller.value.isReady, true);
      await expectLater(controller.whenReady, completes);
      controller.dispose();
    });

    test('Handles onModelLoaded message', () {
      final controller = Live2DController();
      Live2DModelInfo? receivedInfo;
      controller.onModelLoaded = (info) => receivedInfo = info;

      controller.handleJsMessage(jsonEncode({
        'action': 'onModelLoaded',
        'data': {
          'modelUrl': 'https://example.com/model.model3.json',
          'width': 800,
          'height': 1200,
          'motionGroups': ['Idle', 'TapBody'],
          'expressions': ['f01', 'f02'],
        },
      }));

      expect(controller.value.isLoaded, true);
      expect(controller.value.isLoading, false);
      expect(controller.value.modelInfo?.modelUrl,
          'https://example.com/model.model3.json');
      expect(controller.value.modelInfo?.motionGroups, ['Idle', 'TapBody']);
      expect(receivedInfo?.expressions, ['f01', 'f02']);

      controller.dispose();
    });

    test('Handles onHit message', () {
      final controller = Live2DController();
      List<String>? hits;
      controller.onHit = (hitAreas) => hits = hitAreas;

      controller.handleJsMessage(jsonEncode({
        'action': 'onHit',
        'data': {
          'hitAreas': ['Head'],
        },
      }));

      expect(hits, ['Head']);
      controller.dispose();
    });

    test('Handles onError message', () {
      final controller = Live2DController();
      String? caughtError;
      controller.onError = (err) => caughtError = err;

      controller.handleJsMessage(jsonEncode({
        'action': 'onError',
        'data': {'message': 'Failed to fetch moc3 file'},
      }));

      expect(controller.value.error, 'Failed to fetch moc3 file');
      expect(caughtError, 'Failed to fetch moc3 file');
      controller.dispose();
    });
  });

  group('Live2DAssetServer Tests', () {
    test('Starts on loopback and serves HTML with CORS headers', () async {
      HttpOverrides.global = null;
      final server = Live2DAssetServer();
      await server.start();

      expect(server.port, greaterThan(0));
      expect(server.baseUrl, startsWith('http://127.0.0.1:'));

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(server.playerUrl));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.value('Access-Control-Allow-Origin'), '*');

      final body = await response.transform(utf8.decoder).join();
      expect(body, contains('Live2D Viewer'));
      expect(body, contains('pixi-live2d-display'));

      client.close();
      await server.stop();
    });
  });

}
