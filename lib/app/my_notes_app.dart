import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../features/auth/welcome_screen.dart';
import 'session_gate.dart';

class MyNotesApp extends StatefulWidget {
  const MyNotesApp({
    required this.client,
    this.initializationError,
    super.key,
  });

  final SupabaseClient? client;
  final String? initializationError;

  @override
  State<MyNotesApp> createState() => _MyNotesAppState();
}

class _MyNotesAppState extends State<MyNotesApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _setDarkMode(bool dark) {
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Notes',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(dark: false),
      darkTheme: buildAppTheme(dark: true),
      themeMode: _themeMode,
      home: widget.client == null
          ? WelcomeScreen(
              client: null,
              initializationError: widget.initializationError,
            )
          : SessionGate(
              client: widget.client!,
              onThemeChanged: _setDarkMode,
            ),
    );
  }
}
