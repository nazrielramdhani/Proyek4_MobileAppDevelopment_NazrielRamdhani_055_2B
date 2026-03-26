// main.dart 
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    /// =========================
    /// ENV
    /// =========================
    await dotenv.load(fileName: ".env");
    print("ENV OK");

    /// =========================
    /// DATE FORMAT
    /// =========================
    await initializeDateFormatting('id_ID', null);
    print("DATE OK");

    /// =========================
    /// HIVE INIT
    /// =========================
    await Hive.initFlutter();
    print("HIVE INIT OK");

    /// REGISTER ADAPTER (SAFE)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter());
      print("ADAPTER REGISTERED");
    }

    /// =========================
    /// SAFE OPEN BOX
    /// =========================
    try {
      await Hive.openBox<LogModel>('offline_logs');
      print("BOX OPEN OK");
    } catch (e) {
      print("BOX ERROR: $e → CLEARING...");

      await Hive.deleteBoxFromDisk('offline_logs');
      await Hive.openBox<LogModel>('offline_logs');

      print("BOX RECOVERED");
    }

  } catch (e) {
    print("INIT ERROR: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const OnboardingView(),
    );
  }
}
