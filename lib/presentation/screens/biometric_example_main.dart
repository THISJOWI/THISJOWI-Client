import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/presentation/screens/biometric_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BiometricNotifier(),
      child: MaterialApp(
        title: 'THISECURE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: _isAuthenticated
            ? const HomeScreen()
            : BiometricGate(
                onAuthenticated: () {
                  setState(() => _isAuthenticated = true);
                },
                child: const SizedBox(), // No se muestra cuando auth exitoso
              ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Welcome!'),
      ),
    );
  }
}