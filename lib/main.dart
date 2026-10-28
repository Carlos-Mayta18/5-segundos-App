import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/monetization_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización no bloqueante para que la interfaz cargue al instante en Web y Android
  if (!kIsWeb) {
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
  }
  unawaited(SoundService.instance.init());
  unawaited(MonetizationService.instance.init());

  runApp(const Reto5SegundosApp());
}

class Reto5SegundosApp extends StatelessWidget {
  const Reto5SegundosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reto 5 Segundos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
