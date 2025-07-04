import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inisialisasi Firebase
  runApp(const ManajemenStokApp());
} 

class ManajemenStokApp extends StatelessWidget {
  const ManajemenStokApp({super.key});

  @override
  Widget build(BuildContext context) {d
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manajemen Stok Barang',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const LoginScreen(),
    );
  }
}