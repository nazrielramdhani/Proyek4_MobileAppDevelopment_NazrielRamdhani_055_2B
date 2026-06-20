// vision_view.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vision_controller.dart';
import 'pcd_processor.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> with WidgetsBindingObserver {
  final VisionController _vc = VisionController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vc.initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _vc.disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _vc.initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vc.dispose();
    super.dispose();
  }

  // =========================
  // LOADING
  // =========================
  Widget _buildLoading() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF00E5FF)),
            SizedBox(height: 24),
            Text(
              "Menghubungkan ke Sensor Visual...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              "Mohon tunggu sebentar",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // ERROR
  // =========================
  Widget _buildError(String msg) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 72,
              color: Colors.white30,
            ),
            const SizedBox(height: 24),
            const Text(
              "No Camera Access",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.settings),
              label: const Text("Open Settings"),
              onPressed: () => openAppSettings(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _vc.initCamera(),
              child: const Text(
                "Coba Lagi",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _vc.disposeCamera();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text("PCD Vision", style: TextStyle(fontSize: 16)),
          actions: [
            // Torch toggle
            ValueListenableBuilder<bool>(
              valueListenable: _vc.isTorchOn,
              builder: (_, isOn, __) => IconButton(
                icon: Icon(
                  isOn ? Icons.flashlight_on : Icons.flashlight_off,
                  color: isOn ? const Color(0xFFFFD600) : Colors.white54,
                ),
                onPressed: _vc.toggleTorch,
              ),
            ),
          ],
        ),
        body: ValueListenableBuilder<bool>(
          valueListenable: _vc.isInitialized,
          builder: (_, isReady, __) {
            if (_vc.errorMessage.value != null) {
              return _buildError(_vc.errorMessage.value!);
            }
            if (!isReady) return _buildLoading();

            return GestureDetector(
              // Swipe kiri → filter berikutnya
              // Swipe kanan → filter sebelumnya
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) {
                  _vc.nextFilter();
                } else if (details.primaryVelocity! > 200) {
                  _vc.prevFilter();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ===== PROCESSED FRAME =====
                  // ===== PROCESSED FRAME =====
                  ValueListenableBuilder<ui.Image?>(
                    valueListenable: _vc.processedFrame,
                    builder: (_, img, __) {
                      if (img == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                          ),
                        );
                      }

                      // Ambil sensorOrientation dari kamera
                      final sensorOrientation =
                          _vc.cameraController?.description.sensorOrientation ??
                          90;

                      // Konversi derajat → quarterTurns (RotatedBox pakai 90° per step)
                      final quarterTurns = sensorOrientation ~/ 90;

                      return RotatedBox(
                        quarterTurns: quarterTurns,
                        child: RawImage(image: img, fit: BoxFit.contain),
                      );
                    },
                  ),

                  // ===== FILTER NAME LABEL (atas tengah) =====
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _vc.filterIndex,
                      builder: (_, idx, __) => Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            PcdProcessor.filterNames[idx],
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ===== SWIPE HINT (bawah) =====
                  const Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "← Swipe untuk ganti filter →",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ),

                  // ===== FILTER INDEX DOTS =====
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _vc.filterIndex,
                      builder: (_, idx, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          PcdProcessor.filterNames.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == idx ? 12 : 6,
                            height: i == idx ? 12 : 6,
                            decoration: BoxDecoration(
                              color: i == idx
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white30,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
