import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp() and Crashlytics hooks go here (see README).
  runApp(const ProviderScope(child: ConsumerApp()));
}
