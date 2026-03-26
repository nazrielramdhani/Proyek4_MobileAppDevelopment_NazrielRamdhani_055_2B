// mongo_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;

  MongoService._internal();

  Future<DbCollection> _getSafeCollection() async {

    if (_db == null || _db!.state != State.open) {
      await connect();
    }

    return _collection!;
  }

  Future<void> connect() async {
    try {

      if (_db != null && _db!.isConnected) {
        return;
      }

      final dbUri = dotenv.env['MONGODB_URI'];

      if (dbUri == null) {
        throw Exception("MONGODB_URI tidak ditemukan");
      }

      _db = await Db.create(dbUri);

      if (_db!.state != State.open) {
        await _db!.open();
      }

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung",
        source: _source,
        level: 2,
      );

    } catch (e) {

      await LogHelper.writeLog(
        "DATABASE ERROR: $e",
        source: _source,
        level: 1,
      );

      rethrow;

    }
  }

  /// ===============================
  /// FETCH LOG BERDASARKAN TEAM
  /// ===============================
  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog("FETCH ERROR: $e", source: _source, level: 1);

      return [];
    }
  }

  /// ===============================
  /// INSERT
  /// ===============================
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      await collection.replaceOne(
        where.id(ObjectId.fromHexString(log.id!)),
        log.toMap(),
        upsert: true,
      );

      await LogHelper.writeLog(
        "INSERT SUCCESS: ${log.title}",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog("INSERT ERROR: $e", source: _source, level: 1);

      rethrow;
    }
  }

  /// ===============================
  /// UPDATE
  /// ===============================
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      if (log.id == null) return;

      await collection.replaceOne(
        where.id(ObjectId.fromHexString(log.id!)),
        log.toMap(),
      );

      await LogHelper.writeLog(
        "UPDATE SUCCESS: ${log.title}",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog("UPDATE ERROR: $e", source: _source, level: 1);

      rethrow;
    }
  }

  /// ===============================
  /// DELETE
  /// ===============================
  Future<void> deleteLog(String id) async {
    try {
      final collection = await _getSafeCollection();

      await collection.remove(where.id(ObjectId.fromHexString(id)));

      await LogHelper.writeLog(
        "DELETE SUCCESS: $id",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog("DELETE ERROR: $e", source: _source, level: 1);

      rethrow;
    }
  }
}
