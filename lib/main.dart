import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:product_list_app/presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'package:no_screenshot/no_screenshot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _noScreenshot = NoScreenshot.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _disableScreenshots();
  }

  @override
  void dispose() {
    _enableScreenshots();
    super.dispose();
  }

  Future<void> _disableScreenshots() async {
    try {
      await _noScreenshot.screenshotOff();
      print('Capturas de pantalla deshabilitadas');
    } catch (e) {
      print('Error al deshabilitar capturas de pantalla: $e');
    }
  }

  Future<void> _enableScreenshots() async {
    try {
      await _noScreenshot.screenshotOn();
      print('Capturas de pantalla habilitadas');
    } catch (e) {
      print('Error al habilitar capturas de pantalla: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product List App',
      debugShowCheckedModeBanner: false,
      home:
          _currentUser == null
              ? LoginScreen()
              : HomeScreen(firebaseUser: _currentUser, userData: null),
    );
  }
}
