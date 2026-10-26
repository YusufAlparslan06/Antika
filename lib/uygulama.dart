import 'package:flutter/material.dart';

import 'giris.dart';
import 'tema.dart';
import 'tema_tercihleri.dart';

class AntiqueAdminApp extends StatefulWidget {
  const AntiqueAdminApp({super.key});

  @override
  State<AntiqueAdminApp> createState() => _AntiqueAdminAppState();
}

class _AntiqueAdminAppState extends State<AntiqueAdminApp> {
  AppTheme _selectedTheme = AppTheme.dark;
  AppAccent _selectedAccent = AppAccent.gold;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  Future<void> _appearanceSaveQueue = Future<void>.value();
  bool _appearanceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAppearance();
  }

  Future<void> _loadAppearance() async {
    String? errorMessage;
    try {
      final preferences = await ThemePreferences.load();
      if (!mounted) return;
      _selectedTheme = preferences.theme;
      _selectedAccent = preferences.accent;
    } catch (error) {
      errorMessage = 'Görünüm tercihleri yüklenemedi: $error';
      debugPrint(errorMessage);
    } finally {
      if (mounted) setState(() => _appearanceLoaded = true);
    }
    if (errorMessage != null) _showAppearanceError(errorMessage);
  }

  void _changeTheme(AppTheme theme) {
    setState(() => _selectedTheme = theme);
    _saveAppearance();
  }

  void _changeAccent(AppAccent accent) {
    setState(() => _selectedAccent = accent);
    _saveAppearance();
  }

  void _saveAppearance() {
    final theme = _selectedTheme;
    final accent = _selectedAccent;
    _appearanceSaveQueue = _appearanceSaveQueue.then((_) async {
      try {
        await ThemePreferences.save(theme: theme, accent: accent);
      } catch (error) {
        _showAppearanceError('Görünüm tercihleri kaydedilemedi: $error');
      }
    });
  }

  void _showAppearanceError(String message) {
    debugPrint(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: 'Eskilerden',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(_selectedTheme, accent: _selectedAccent),
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: _appearanceLoaded
          ? AppThemeScope(
              selectedTheme: _selectedTheme,
              onThemeChanged: _changeTheme,
              selectedAccent: _selectedAccent,
              onAccentChanged: _changeAccent,
              child: const AuthGate(),
            )
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
