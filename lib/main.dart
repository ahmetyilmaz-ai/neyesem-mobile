import 'package:flutter/material.dart';
import 'package:neyesem_mobile/features/auth/screens/login_screen.dart';
// Yeni yazdığımız iskeleti import ediyoruz

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeYesem Mobil',
      home: const LoginScreen(), // Uygulama artık buradan başlayacak
    );
  }
}
