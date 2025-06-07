import 'package:flutter/material.dart';
import 'package:product_list_app/services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final AuthService authService = AuthService();

  String error = '';
  bool loading = false;

  Future<void> loginWithCredentials() async {
    setState(() {
      error = '';
      loading = true;
    });

    final token = await authService.signInWithFakeStore(
      userController.text.trim(),
      passController.text.trim(),
    );

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userData: {'token': token}),
        ),
      );
    } else {
      setState(() => error = 'Credenciales inválidas o error en el servidor');
    }

    setState(() => loading = false);
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      error = '';
      loading = true;
    });

    try {
      final firebaseUser = await authService.signInWithGoogle();
      if (firebaseUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(firebaseUser: firebaseUser),
          ),
        );
      } else {
        setState(() => error = 'Inicio de sesión cancelado');
      }
    } catch (e) {
      setState(() => error = 'Error al iniciar sesión con Google: $e');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.lock_outline, size: 50, color: Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Bienvenido',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: 'Usuario',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loading ? null : loginWithCredentials,
                icon: Icon(Icons.login),
                label: Text('Ingresar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Divider(height: 20),
              Text('O inicia sesión con'),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: loading ? null : loginWithGoogle,
                icon: Icon(
                  Icons.g_mobiledata, 
                  size: 28,
                  color: Colors.red,
                ),
                label: Text('Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: Size(double.infinity, 50),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(error, style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
