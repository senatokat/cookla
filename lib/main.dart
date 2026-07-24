import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter engine hazır
  await Firebase.initializeApp(); // firebase başlatılır
  runApp(const MyApp()); // uygulama başlatılır
}
