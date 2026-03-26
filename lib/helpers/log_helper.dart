// log_helper.dart
import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    // ==============================
    // 1. FILTER ENV CONFIG
    // ==============================
    final int configLevel =
        int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      DateTime now = DateTime.now();

      // ==============================
      // 2. FORMAT TIME
      // ==============================
      String consoleTime = DateFormat('HH:mm:ss').format(now);
      String fileTime = DateFormat('HH:mm:ss').format(now);
      String fileDate = DateFormat('dd-MM-yyyy').format(now);

      String label = _getLabel(level);
      String color = _getColor(level);

      // ==============================
      // 3. DEBUG CONSOLE (VS CODE)
      // ==============================
      dev.log(
        message,
        name: source,
        time: now,
        level: level * 100,
      );

      // ==============================
      // 4. TERMINAL OUTPUT
      // ==============================
      print(
          '$color[$consoleTime][$label][$source] -> $message\x1B[0m');

      // ==============================
      // 5. FILE LOGGING
      // ==============================
      final dir = await getApplicationDocumentsDirectory();

      final logDir = Directory('${dir.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final file = File('${logDir.path}/$fileDate.log');

      final logLine =
          '[$fileTime][$label][$source] -> $message\n';

      await file.writeAsString(
        logLine,
        mode: FileMode.append,
      );
    } catch (e) {
      dev.log("Logging failed: $e",
          name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}