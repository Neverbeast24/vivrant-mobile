import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/core/utils/in_app_camera.dart';
import 'package:vivrant_mobile/core/widgets/in_app_camera_screen.dart';

CameraDescription _cam(String name, CameraLensDirection lens) {
  return CameraDescription(
    name: name,
    lensDirection: lens,
    sensorOrientation: 90,
  );
}

void main() {
  group('selectPreferredCamera', () {
    test('returns null when no cameras are available', () {
      expect(selectPreferredCamera(const []), isNull);
    });

    test('prefers the matching lens and falls back to the first camera', () {
      final back = _cam('0', CameraLensDirection.back);
      final front = _cam('1', CameraLensDirection.front);

      expect(selectPreferredCamera([back, front])?.name, '0');
      expect(
        selectPreferredCamera([
          back,
          front,
        ], preferred: CameraLensDirection.front)?.name,
        '1',
      );
      expect(
        selectPreferredCamera([
          front,
        ], preferred: CameraLensDirection.back)?.name,
        '1',
      );
    });
  });

  group('cameraErrorMessage', () {
    test('explains permission denial in plain language', () {
      expect(
        cameraErrorMessage(CameraException('CameraAccessDenied', 'denied')),
        contains('Settings'),
      );
      expect(
        cameraErrorMessage(
          CameraException('CameraAccessDeniedWithoutPrompt', 'denied'),
        ),
        contains('Settings'),
      );
    });

    test('explains missing plugin on desktop without a native camera', () {
      expect(
        cameraErrorMessage(
          Exception(
            'MissingPluginException(No implementation found for method availableCameras)',
          ),
        ),
        contains('phone'),
      );
    });

    test('uses a generic fallback for other failures', () {
      expect(
        cameraErrorMessage(CameraException('CameraError', '')),
        'Could not open the camera.',
      );
    });
  });

  group('PickedPhoto', () {
    test('reads the file name from unix and windows paths', () {
      expect(PickedPhoto.fromPath('/tmp/meal.jpg').name, 'meal.jpg');
      expect(
        PickedPhoto.fromPath(r'C:\Users\PC\AppData\meal.jpg').name,
        'meal.jpg',
      );
    });
  });

  group('nextFlashMode', () {
    test('toggles off and auto', () {
      expect(nextFlashMode(FlashMode.off), FlashMode.auto);
      expect(nextFlashMode(FlashMode.auto), FlashMode.off);
      expect(nextFlashMode(FlashMode.always), FlashMode.off);
      expect(nextFlashMode(FlashMode.torch), FlashMode.off);
    });
  });

  group('InAppCameraScreen', () {
    testWidgets('shows a stay-in-app message when no camera is found', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InAppCameraScreen(
            listCameras: () async => const <CameraDescription>[],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Camera unavailable'), findsOneWidget);
      expect(
        find.textContaining('VIVRΛNT keeps the camera inside the app'),
        findsOneWidget,
      );
    });

    testWidgets('explains permission denial without leaving the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InAppCameraScreen(
            listCameras: () async {
              throw CameraException('CameraAccessDenied', 'denied');
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Settings'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
