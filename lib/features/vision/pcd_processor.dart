// pcd_processor.dart
import 'dart:typed_data';
import 'dart:math';

class PcdProcessor {
  // =============================================
  // ENTRY POINT — pilih filter berdasarkan index
  // =============================================
  static Uint8List applyFilter(
    Uint8List rgba,
    int width,
    int height,
    int filterIndex,
  ) {
    switch (filterIndex) {
      case 0:
        return rgba; // Original
      case 1:
        return grayscale(rgba); // Grayscale
      case 2:
        return brightnessContrast(rgba, 30, 1.4); // Brightness & Contrast
      case 3:
        return negative(rgba); // Negative
      case 4:
        return histogramEqualization(rgba); // Histogram Equalization
      case 5:
        return threshold(rgba, 128); // Thresholding
      case 6:
        return gaussianBlur(rgba, width, height); // Gaussian Blur
      case 7:
        return edgeDetectionSobel(rgba, width, height); // Edge Detection
      case 8:
        return sharpen(rgba, width, height); // Sharpening
      default:
        return rgba;
    }
  }

  static const List<String> filterNames = [
    "Original",
    "Grayscale",
    "Brightness & Contrast",
    "Negative / Invert",
    "Histogram Equalization",
    "Thresholding (Binary)",
    "Gaussian Blur",
    "Edge Detection (Sobel)",
    "Sharpening",
  ];

  // =============================================
  // 1. GRAYSCALE
  // Rumus: Y = 0.299R + 0.587G + 0.114B
  // =============================================
  static Uint8List grayscale(Uint8List rgba) {
    final out = Uint8List.fromList(rgba);
    for (int i = 0; i < rgba.length; i += 4) {
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final y = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
      out[i] = y;
      out[i + 1] = y;
      out[i + 2] = y;
      out[i + 3] = rgba[i + 3]; // alpha tetap
    }
    return out;
  }

  // =============================================
  // 2. BRIGHTNESS & CONTRAST
  // Rumus: out = alpha * in + beta
  // alpha = faktor kontras, beta = nilai brightness
  // =============================================
  static Uint8List brightnessContrast(Uint8List rgba, int beta, double alpha) {
    final out = Uint8List.fromList(rgba);
    for (int i = 0; i < rgba.length; i += 4) {
      out[i] = (alpha * rgba[i] + beta).round().clamp(0, 255);
      out[i + 1] = (alpha * rgba[i + 1] + beta).round().clamp(0, 255);
      out[i + 2] = (alpha * rgba[i + 2] + beta).round().clamp(0, 255);
    }
    return out;
  }

  // =============================================
  // 3. NEGATIVE / INVERT
  // Rumus: out = 255 - in
  // =============================================
  static Uint8List negative(Uint8List rgba) {
    final out = Uint8List.fromList(rgba);
    for (int i = 0; i < rgba.length; i += 4) {
      out[i] = 255 - rgba[i];
      out[i + 1] = 255 - rgba[i + 1];
      out[i + 2] = 255 - rgba[i + 2];
    }
    return out;
  }

  // =============================================
  // 4. HISTOGRAM EQUALIZATION
  // Hanya pada channel luminance (Y), konversi via YUV
  // =============================================
  static Uint8List histogramEqualization(Uint8List rgba) {
    final int pixelCount = rgba.length ~/ 4;

    // Hitung histogram grayscale
    final hist = List<int>.filled(256, 0);
    for (int i = 0; i < rgba.length; i += 4) {
      final y = (0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2])
          .round()
          .clamp(0, 255);
      hist[y]++;
    }

    // Hitung CDF (Cumulative Distribution Function)
    final cdf = List<int>.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }

    // Normalisasi CDF → lookup table
    final cdfMin = cdf.firstWhere((v) => v > 0);
    final lut = List<int>.generate(256, (i) {
      return (((cdf[i] - cdfMin) / (pixelCount - cdfMin)) * 255).round().clamp(
        0,
        255,
      );
    });

    // Apply LUT
    final out = Uint8List.fromList(rgba);
    for (int i = 0; i < rgba.length; i += 4) {
      final y = (0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2])
          .round()
          .clamp(0, 255);
      final eq = lut[y];
      out[i] = eq;
      out[i + 1] = eq;
      out[i + 2] = eq;
    }
    return out;
  }

  // =============================================
  // 5. THRESHOLDING (BINARY)
  // Rumus: if Y >= T → 255, else → 0
  // =============================================
  static Uint8List threshold(Uint8List rgba, int T) {
    final out = Uint8List.fromList(rgba);
    for (int i = 0; i < rgba.length; i += 4) {
      final y = (0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2])
          .round();
      final val = y >= T ? 255 : 0;
      out[i] = val;
      out[i + 1] = val;
      out[i + 2] = val;
    }
    return out;
  }

  // =============================================
  // 6. GAUSSIAN BLUR
  // Kernel 3x3: [1,2,1 / 2,4,2 / 1,2,1] / 16
  // =============================================
  static Uint8List gaussianBlur(Uint8List rgba, int width, int height) {
    final kernel = [
      [1, 2, 1],
      [2, 4, 2],
      [1, 2, 1],
    ];
    const kernelSum = 16;
    return _applyConvolution(rgba, width, height, kernel, kernelSum);
  }

  // =============================================
  // 7. EDGE DETECTION — SOBEL
  // Gx = [-1,0,1 / -2,0,2 / -1,0,1]
  // Gy = [-1,-2,-1 / 0,0,0 / 1,2,1]
  // magnitude = sqrt(Gx² + Gy²)
  // =============================================
  static Uint8List edgeDetectionSobel(Uint8List rgba, int width, int height) {
    // Grayscale dulu
    final gray = grayscale(rgba);
    final out = Uint8List.fromList(rgba);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        // Ambil 9 piksel sekitar (x,y)
        int p(int dx, int dy) {
          final idx = ((y + dy) * width + (x + dx)) * 4;
          return gray[idx]; // sudah grayscale, R=G=B
        }

        final gx =
            -p(-1, -1) +
            p(1, -1) -
            2 * p(-1, 0) +
            2 * p(1, 0) -
            p(-1, 1) +
            p(1, 1);

        final gy =
            -p(-1, -1) -
            2 * p(0, -1) -
            p(1, -1) +
            p(-1, 1) +
            2 * p(0, 1) +
            p(1, 1);

        final mag = sqrt(gx * gx + gy * gy).clamp(0, 255).toInt();

        final i = (y * width + x) * 4;
        out[i] = mag;
        out[i + 1] = mag;
        out[i + 2] = mag;
        out[i + 3] = 255;
      }
    }
    return out;
  }

  // =============================================
  // 8. SHARPENING
  // Kernel: [0,-1,0 / -1,5,-1 / 0,-1,0]
  // =============================================
  static Uint8List sharpen(Uint8List rgba, int width, int height) {
    final kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];
    return _applyConvolution(rgba, width, height, kernel, 1);
  }

  // =============================================
  // HELPER — Generic 3x3 Convolution
  // =============================================
  static Uint8List _applyConvolution(
    Uint8List rgba,
    int width,
    int height,
    List<List<int>> kernel,
    int kernelSum,
  ) {
    final out = Uint8List.fromList(rgba);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        int sumR = 0, sumG = 0, sumB = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final idx = ((y + ky) * width + (x + kx)) * 4;
            final w = kernel[ky + 1][kx + 1];
            sumR += rgba[idx] * w;
            sumG += rgba[idx + 1] * w;
            sumB += rgba[idx + 2] * w;
          }
        }

        final i = (y * width + x) * 4;
        out[i] = (sumR ~/ kernelSum).clamp(0, 255);
        out[i + 1] = (sumG ~/ kernelSum).clamp(0, 255);
        out[i + 2] = (sumB ~/ kernelSum).clamp(0, 255);
      }
    }
    return out;
  }
}
