import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Keep the splash screen up until the app is ready
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  
  // Load dotenv but prefer dart-define if provided
  await dotenv.load(fileName: '.env', isOptional: false);
  const defineUrl = String.fromEnvironment('SUPABASE_URL');
  const defineAnon = String.fromEnvironment('SUPABASE_ANON_KEY');
  final url = (defineUrl.isNotEmpty ? defineUrl : (dotenv.env['SUPABASE_URL'] ?? ''));
  final anon = (defineAnon.isNotEmpty ? defineAnon : (dotenv.env['SUPABASE_ANON_KEY'] ?? ''));
  if (url.isEmpty || anon.isEmpty) {
    throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY. Set them via --dart-define or .env');
  }
  await Supabase.initialize(url: url, anonKey: anon);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _router = createRouter();
    
    // Remove the splash screen after the app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ideaxy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
