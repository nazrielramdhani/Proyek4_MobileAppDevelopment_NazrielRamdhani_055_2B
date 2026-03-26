// login_view.dart
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscurePassword = true;

  /// =========================
  /// LOGIN PROCESS
  /// =========================
  void _handleLogin() {
    String user = _userController.text.trim();
    String pass = _passController.text.trim();

    String? result = _controller.login(user, pass, () {
      setState(() {});
    });

    if (result == null) {
      /// ROLE LOGIC (RBAC)
      String role;

      if (user == "admin") {
        role = "Ketua";
      } else if (user == "nazriel") {
        role = "Asisten";
      } else {
        role = "Anggota";
      }

      /// OBJECT USER
      final currentUser = {
        "username": user,
        "uid": user,
        "teamId": "MEKTRA_KLP_01",
        "role": role,
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(currentUser: currentUser),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _controller.isLocked ? null : _handleLogin,
              child: Text(
                _controller.isLocked
                    ? "Tunggu 10 detik..."
                    : "Masuk",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
