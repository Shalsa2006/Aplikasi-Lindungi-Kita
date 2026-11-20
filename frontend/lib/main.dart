import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  ErrorWidget.builder = (details) => Material(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text('Terjadi kesalahan tampilan:\n${details.exceptionAsString()}', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      );
  runApp(const LindungiKitaApp());
}

class LindungiKitaApp extends StatelessWidget {
  const LindungiKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LindungiKita',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
