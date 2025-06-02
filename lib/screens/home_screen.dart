import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/auth_service.dart';
import 'login_screen.dart';
import 'product_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final User? firebaseUser; 
  final Map<String, dynamic>? userData; 
  final AuthService authService = AuthService();

  HomeScreen({this.firebaseUser, this.userData});

  @override
  Widget build(BuildContext context) {
    String displayName = '';

    if (firebaseUser != null) {
      displayName =
          firebaseUser!.displayName ?? firebaseUser!.email ?? 'Usuario';
    } else if (userData != null) {
      displayName = userData!['username'] ?? 'Usuario';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola $displayName'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ProductListScreen(),
    );
  }
}
