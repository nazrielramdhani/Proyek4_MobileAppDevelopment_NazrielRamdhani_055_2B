// vision_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pcd_processor.dart';

class VisionController {
  CameraController? cameraController;

  final ValueNotifier<ui.Image?> processedFrame = ValueNotifier(null);
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<int> filterIndex = ValueNotifier(0);
  final ValueNotifier<bool> isTorchOn = ValueNotifier(false);

  bool _isProcessing = false;

  // =========================
  // PERMISSION
  // =========================
  Future<bool> _requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // =========================
  // INIT KAMERA
  // =========================
  Future<void> initCamera() async {
    isInitialized.value = false;
    errorMessage.value = null;
    isTorchOn.value = false;

    final granted = await _requestPermission();
    if (!granted) {
      errorMessage.value = "Izin kamera ditolak.";
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        back,
        ResolutionPreset.low, // LOW agar proses PCD tidak berat
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      isInitialized.value = true;

      // Mulai stream
      await cameraController!.startImageStream(_onFrame);
    } catch (e) {
      errorMessage.value = "Gagal inisialisasi kamera: $e";
    }
  }

  // =========================
  // PER-FRAME PROCESSING
  // =========================
  Future<void> _onFrame(CameraImage image) async {
    if (_isProcessing) return; // skip frame jika masih proses
    _isProcessing = true;

    try {
      // 1. Konversi YUV420 → RGBA
      final rgba = _yuv420ToRgba(image);

      // 2. Apply filter PCD
      final filtered = PcdProcessor.applyFilter(
        rgba,
        image.width,
        image.height,
        filterIndex.value,
      );

      // 3. Uint8List → ui.Image untuk ditampilkan
      final codec = await ui.ImmutableBuffer.fromUint8List(filtered)
          .then(
            (buf) => ui.ImageDescriptor.raw(
              buf,
              width: image.width,
              height: image.height,
              pixelFormat: ui.PixelFormat.rgba8888,
            ),
          )
          .then((desc) => desc.instantiateCodec(targetWidth: image.width))
          .then((codec) => codec.getNextFrame())
          .then((fi) => fi.image);

      processedFrame.value = codec;
    } catch (_) {
      // skip frame error
    } finally {
      _isProcessing = false;
    }
  }

  // =========================
  // YUV420 → RGBA
  // =========================
  Uint8List _yuv420ToRgba(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final out = Uint8List(width * height * 4);

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final Y = yPlane[yIndex];
        final U = uPlane[uvIndex] - 128;
        final V = vPlane[uvIndex] - 128;

        final r = (Y + 1.402 * V).round().clamp(0, 255);
        final g = (Y - 0.344136 * U - 0.714136 * V).round().clamp(0, 255);
        final b = (Y + 1.772 * U).round().clamp(0, 255);

        final i = yIndex * 4;
        out[i] = r;
        out[i + 1] = g;
        out[i + 2] = b;
        out[i + 3] = 255;
      }
    }
    return out;
  }

  // =========================
  // SWIPE — ganti filter
  // =========================
  void nextFilter() {
    filterIndex.value =
        (filterIndex.value + 1) % PcdProcessor.filterNames.length;
  }

  void prevFilter() {
    filterIndex.value =
        (filterIndex.value - 1 + PcdProcessor.filterNames.length) %
        PcdProcessor.filterNames.length;
  }

  // =========================
  // TORCH
  // =========================
  Future<void> toggleTorch() async {
    if (cameraController == null || !isInitialized.value) return;
    isTorchOn.value = !isTorchOn.value;
    await cameraController!.setFlashMode(
      isTorchOn.value ? FlashMode.torch : FlashMode.off,
    );
  }

  // =========================
  // DISPOSE
  // =========================
  void disposeCamera() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    cameraController = null;
    isInitialized.value = false;
    isTorchOn.value = false;
    processedFrame.value = null;
  }

  void dispose() {
    disposeCamera();
    isInitialized.dispose();
    errorMessage.dispose();
    processedFrame.dispose();
    filterIndex.dispose();
    isTorchOn.dispose();
  }
}
