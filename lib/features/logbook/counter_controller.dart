// counter_controller.dart
import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  final String username;

  int _counter = 0;
  final int _step = 1;
  final List<String> _history = [];

  CounterController(this.username);

  int get value => _counter;
  List<String> get history => List.unmodifiable(_history);

  // =========================
  // LOAD DATA PER USER
  // =========================
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _counter = prefs.getInt('counter_$username') ?? 0;

    final savedHistory =
        prefs.getStringList('history_$username');

    if (savedHistory != null) {
      _history
        ..clear()
        ..addAll(savedHistory);
    }
  }

  // =========================
  // SAVE DATA PER USER
  // =========================
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('counter_$username', _counter);
    await prefs.setStringList(
        'history_$username', _history);
  }

  Future<void> increment() async {
    _counter += _step;
    _addHistory("Menambah +$_step");
    await _saveData();
  }

  Future<void> decrement() async {
    if (_counter - _step >= 0) {
      _counter -= _step;
      _addHistory("Mengurangi -$_step");
      await _saveData();
    }
  }

  Future<void> reset() async {
    _counter = 0;
    _addHistory("Melakukan reset");
    await _saveData();
  }

  void _addHistory(String action) {
    final time =
        DateTime.now().toLocal().toString().substring(11, 19);

    _history.add("$action pada jam $time");

    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }
}