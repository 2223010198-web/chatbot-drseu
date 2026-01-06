import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await AuthService().signInWithGoogle();
    setState(() => _isLoading = false);

    // Si el login es exitoso, el StreamBuilder en main.dart nos redirigirá automáticamente
    if (user != null) {
      print("Logueado como: ${user.email}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text("Admin Panel DRSU", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
            SizedBox(height: 10),
            Text("Gestión de Cursos y Bot", style: TextStyle(color: Colors.grey.shade600)),
            SizedBox(height: 50),

            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 3,
              ),
              icon: FaIcon(FontAwesomeIcons.google, color: Colors.red),
              label: Text("Iniciar sesión con Google"),
              onPressed: _handleGoogleSignIn,
            ),
          ],
        ),
      ),
    );
  }
}