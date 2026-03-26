// log_controller.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart' as hive;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {

  /// ===============================
  /// STATE
  /// ===============================
  
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  late final hive.Box<LogModel> _myBox;

  LogController() {
    if (!hive.Hive.isBoxOpen('offline_logs')) {
      throw Exception("Hive box belum dibuka!");
    }

    _myBox = hive.Hive.box<LogModel>('offline_logs');
  }

  final MongoService _mongoService = MongoService();

  final Connectivity _connectivity = Connectivity();

  late StreamSubscription _connectionSub;

  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier(false);
  bool _isSyncing = false;

  /// ===============================
  /// AUTO SYNC LISTENER
  /// ===============================

  void startAutoSync(String teamId) {

    _connectionSub = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (hasConnection) {
        await Future.delayed(const Duration(seconds: 2));

        await syncPendingLogs();
        await loadLogs(teamId);
      } else {
        isOfflineNotifier.value = true;
      }
    });

  }

  /// ===============================
  /// LOAD LOGS (OFFLINE FIRST)
  /// ===============================

  Future<void> loadLogs(String teamId) async {

    /// tampilkan data lokal dulu
    logsNotifier.value = _myBox.values.toList();

    try {

      final cloudData = await _mongoService.getLogs(teamId);

      for (var cloudLog in cloudData) {

        final index = _myBox.values
            .toList()
            .indexWhere((e) => e.id == cloudLog.id);

        if (index == -1) {

          /// data baru dari cloud
          await _myBox.add(cloudLog);

        } else {

          final localLog = _myBox.getAt(index);

          /// hanya overwrite jika local sudah synced
          if (localLog != null && localLog.isSynced) {

            await _myBox.putAt(index, cloudLog);

          }

        }

      }

      logsNotifier.value = _myBox.values.toList();

      isOfflineNotifier.value = false;

    } catch (e) {

      isOfflineNotifier.value = true;

      await LogHelper.writeLog(
        "OFFLINE MODE: menggunakan cache lokal",
        source: "log_controller.dart",
        level: 2,
      );

    }

  }

  /// ===============================
  /// CREATE LOG
  /// ===============================

  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId,
  ) async {

    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      isSynced: false,
      syncAction: "create",
    );

    await _myBox.add(newLog);

    logsNotifier.value = [...logsNotifier.value, newLog];

    /// coba sync langsung
    try {

      await _mongoService.insertLog(newLog);

      final syncedLog = LogModel(
        id: newLog.id,
        title: newLog.title,
        description: newLog.description,
        date: newLog.date,
        authorId: newLog.authorId,
        teamId: newLog.teamId,
        isSynced: true,
        syncAction: "none",
      );

      await _myBox.putAt(_myBox.length - 1, syncedLog);
      logsNotifier.value = _myBox.values.toList();

    } catch (e) {

      await LogHelper.writeLog(
        "CREATE OFFLINE",
        source: "log_controller.dart",
        level: 1,
      );

    }

  }

  /// ===============================
  /// UPDATE LOG
  /// ===============================
  Future<void> updateLog(
    int index,
    String title,
    String desc,
    String authorId, 
    String teamId, 
  ) async {
    final oldLog = logsNotifier.value[index];

    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,

      isSynced: false,
      syncAction: "update",
    );

    await _myBox.putAt(index, updatedLog);

    final newList = [...logsNotifier.value];
    newList[index] = updatedLog;
    logsNotifier.value = newList;
  }

  /// ===============================
  /// DELETE LOG
  /// ===============================

  Future<void> removeLog(int index) async {

    final log = logsNotifier.value[index];

    final deletedLog = LogModel(
      id: log.id,
      title: log.title,
      description: log.description,
      date: log.date,
      authorId: log.authorId,
      teamId: log.teamId,
      isSynced: false,
      syncAction: "delete",
    );

    await _myBox.putAt(index, deletedLog);

    logsNotifier.value = _myBox.values
      .where((e) => e.syncAction != "delete")
      .toList();

    try {
      await _mongoService.deleteLog(log.id!);
      
      await _myBox.deleteAt(index);
    } catch (e) {
      await LogHelper.writeLog(
        "DELETE OFFLINE",
        source:"log_controller.dart",
        level: 1,
      );
    }
  }

  /// ===============================
  /// SYNC PENDING LOGS
  /// ===============================

  Future<void> syncPendingLogs() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final logs = _myBox.values.toList();

      /// LOOP DARI BELAKANG (ANTI BUG)
      for (int i = logs.length - 1; i >= 0; i--) {
        final log = logs[i];

        if (!log.isSynced) {
          try {
            /// =========================
            /// CREATE
            /// =========================
            if (log.syncAction == "create") {
              await _mongoService.insertLog(log);
            }
            /// =========================
            /// UPDATE
            /// =========================
            else if (log.syncAction == "update") {
              await _mongoService.updateLog(log);
            }
            /// =========================
            /// DELETE
            /// =========================
            else if (log.syncAction == "delete") {
              await _mongoService.deleteLog(log.id!);

              /// HAPUS DARI HIVE
              await _myBox.deleteAt(i);

              continue;
            }

            /// =========================
            /// MARK AS SYNCED
            /// =========================
            final syncedLog = LogModel(
              id: log.id,
              title: log.title,
              description: log.description,
              date: log.date,
              authorId: log.authorId,
              teamId: log.teamId,
              isSynced: true,
              syncAction: "none",
            );

            await _myBox.putAt(i, syncedLog);

            await LogHelper.writeLog(
              "SYNC SUCCESS: ${log.syncAction}",
              source: "log_controller.dart",
              level: 2,
            );
          } catch (e) {
            /// JIKA GAGAL → MASIH OFFLINE
            isOfflineNotifier.value = true;

            await LogHelper.writeLog(
              "SYNC FAILED: ${log.syncAction}",
              source: "log_controller.dart",
              level: 1,
            );
          }
        }
      }

      /// JIKA SEMUA BERHASIL → ONLINE
      isOfflineNotifier.value = false;

      /// UPDATE UI
      logsNotifier.value = _myBox.values.toList();
    } finally {
      _isSyncing = false;
    }
  }

  /// ===============================
  /// DISPOSE 
  /// ===============================
  void dispose() {
    _connectionSub.cancel();
    logsNotifier.dispose();
    isOfflineNotifier.dispose(); 
  }
}
