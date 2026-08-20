import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/vivrant_colors.dart';
import '../utils/in_app_camera.dart';

export '../utils/in_app_camera.dart';

Future<PickedPhoto?> openInAppCamera(
  BuildContext context, {
  bool selfie = false,
}) {
  return Navigator.of(context, rootNavigator: true).push<PickedPhoto>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => InAppCameraScreen(
        preferredLens: selfie
            ? CameraLensDirection.front
            : CameraLensDirection.back,
      ),
    ),
  );
}

Future<PickedPhoto?> pickPhoto(
  BuildContext context, {
  required PhotoPickSource source,
  bool selfie = false,
  double? maxWidth,
  double? maxHeight,
  int? imageQuality,
}) async {
  if (source == PhotoPickSource.gallery) {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (file == null) return null;
    return PickedPhoto(path: file.path, name: file.name);
  }
  if (!context.mounted) return null;
  return openInAppCamera(context, selfie: selfie);
}

Future<PhotoPickSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<PhotoPickSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, PhotoPickSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, PhotoPickSource.camera),
            ),
          ],
        ),
      );
    },
  );
}

class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({
    super.key,
    this.preferredLens = CameraLensDirection.back,
    this.listCameras,
  });

  final CameraLensDirection preferredLens;
  final Future<List<CameraDescription>> Function()? listCameras;

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  List<CameraDescription> _cameras = const [];
  String? _error;
  String? _capturedPath;
  Uint8List? _capturedBytes;
  bool _starting = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_capturedPath != null) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      final description = _description;
      if (description != null) {
        _open(description);
      }
    }
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final cameras = await (widget.listCameras ?? availableCameras)();
      if (!mounted) return;
      _cameras = cameras;
      final selected = selectPreferredCamera(
        cameras,
        preferred: widget.preferredLens,
      );
      if (selected == null) {
        setState(() {
          _starting = false;
          _error = 'none';
        });
        return;
      }
      await _open(selected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = cameraErrorMessage(e);
      });
    }
  }

  Future<void> _open(CameraDescription description) async {
    final previous = _controller;
    final next = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = next;
    _description = description;
    try {
      await next.initialize();
      if (!mounted || _controller != next) {
        await next.dispose();
        return;
      }
      await previous?.dispose();
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = null;
        _busy = false;
      });
    } catch (e) {
      await next.dispose();
      if (_controller == next) _controller = previous;
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = cameraErrorMessage(e);
      });
    }
  }

  Future<void> _flip() async {
    if (_cameras.length < 2 || _busy) return;
    final current = _description?.lensDirection;
    final next = _cameras.firstWhere(
      (camera) => camera.lensDirection != current,
      orElse: () => _cameras.first,
    );
    if (next.name == _description?.name) return;
    setState(() => _busy = true);
    await _open(next);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(nextFlashMode(controller.value.flashMode));
      if (mounted) setState(() {});
    } on CameraException {
      // Front cameras and some devices do not support flash.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      HapticFeedback.mediumImpact();
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedPath = file.path;
        _capturedBytes = bytes;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cameraErrorMessage(e))));
    }
  }

  void _retake() {
    setState(() {
      _capturedPath = null;
      _capturedBytes = null;
    });
  }

  void _usePhoto() {
    final path = _capturedPath;
    if (path == null) return;
    Navigator.pop(context, PickedPhoto.fromPath(path));
  }

  void _close() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _stage()),
            SafeArea(child: _chrome()),
          ],
        ),
      ),
    );
  }

  Widget _stage() {
    if (_capturedBytes != null) {
      return Image.memory(_capturedBytes!, fit: BoxFit.cover);
    }
    final controller = _controller;
    if (controller != null &&
        controller.value.isInitialized &&
        _error == null) {
      final size = controller.value.previewSize;
      if (size != null) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        );
      }
      return CameraPreview(controller);
    }
    if (_starting) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return _status();
  }

  Widget _status() {
    final unavailable = _error == 'none';
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 88, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unavailable
                ? Icons.no_photography_outlined
                : Icons.photo_camera_outlined,
            color: Colors.white70,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            unavailable ? 'Camera unavailable' : 'Camera needs a moment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            unavailable
                ? 'VIVRΛNT keeps the camera inside the app so you never leave to a third-party camera. No camera was found on this device.'
                : (_error ?? 'Could not open the camera.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          if (!unavailable)
            FilledButton(onPressed: _start, child: const Text('Try again')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _close,
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _chrome() {
    final reviewing = _capturedPath != null;
    final controller = _controller;
    final ready =
        !reviewing &&
        controller != null &&
        controller.value.isInitialized &&
        _error == null;
    final flashOn = controller?.value.flashMode != FlashMode.off;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              _roundButton(Icons.close_rounded, _close),
              const Spacer(),
              if (ready)
                _roundButton(
                  flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  _toggleFlash,
                ),
            ],
          ),
        ),
        const Expanded(child: IgnorePointer(child: SizedBox.expand())),
        if (reviewing)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _usePhoto,
                    style: FilledButton.styleFrom(
                      backgroundColor: VivrantColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Use photo'),
                  ),
                ),
              ],
            ),
          )
        else if (ready)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _roundButton(
                  Icons.cameraswitch_rounded,
                  _cameras.length > 1 ? _flip : null,
                ),
                Semantics(
                  button: true,
                  label: 'Take photo',
                  child: GestureDetector(
                    onTap: _busy ? null : _capture,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _busy ? Colors.white38 : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback? onPressed) {
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.38),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white24,
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}
