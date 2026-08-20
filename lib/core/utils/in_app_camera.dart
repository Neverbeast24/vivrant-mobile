import 'package:camera/camera.dart';

enum PhotoPickSource { camera, gallery }

class PickedPhoto {
  const PickedPhoto({required this.path, required this.name});

  final String path;
  final String name;

  factory PickedPhoto.fromPath(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    return PickedPhoto(path: path, name: name.isEmpty ? 'photo.jpg' : name);
  }
}

CameraDescription? selectPreferredCamera(
  List<CameraDescription> cameras, {
  CameraLensDirection preferred = CameraLensDirection.back,
}) {
  if (cameras.isEmpty) return null;
  for (final camera in cameras) {
    if (camera.lensDirection == preferred) return camera;
  }
  return cameras.first;
}

FlashMode nextFlashMode(FlashMode current) {
  return current == FlashMode.off ? FlashMode.auto : FlashMode.off;
}

String cameraErrorMessage(Object error) {
  if (error is CameraException) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera access is needed to take a photo. Enable it in Settings, then try again.';
    }
    final description = error.description?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }
    return 'Could not open the camera.';
  }

  final text = error.toString();
  if (text.contains('MissingPluginException') ||
      text.toLowerCase().contains('not implemented')) {
    return 'Camera is available on a phone. This device does not have an in-app camera.';
  }
  return 'Could not open the camera.';
}
