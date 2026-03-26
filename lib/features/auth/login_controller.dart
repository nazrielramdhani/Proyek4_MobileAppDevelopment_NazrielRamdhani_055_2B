// login_controller.dart 
import 'dart:async';

class LoginController {
  final Map<String, String> _users = {
    "admin": "12345",
    "user": "password",
    "nazriel": "flutter123",
  };

  int _attempts = 0;
  bool _isLocked = false;

  int get attempts => _attempts;
  bool get isLocked => _isLocked;

  String? login(String username, String password, Function onUnlock) {
    if (username.isEmpty || password.isEmpty) {
      return "Username dan Password tidak boleh kosong!";
    }

    if (_isLocked) {
      return "Terlalu banyak percobaan. Tunggu 10 detik.";
    }

    if (_users.containsKey(username) && _users[username] == password) {
      _attempts = 0;
      return null;
    } else {
      _attempts++;

      if (_attempts >= 3) {
        _isLocked = true;

        Timer(const Duration(seconds: 10), () {
          resetLock();
          onUnlock(); // beri tahu view untuk refresh
        });
      }

      return "Username atau Password salah! Percobaan ke-$_attempts";
    }
  }

  void resetLock() {
    _attempts = 0;
    _isLocked = false;
  }
}
