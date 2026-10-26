import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';

class ThemePreferences {
  const ThemePreferences({required this.theme, required this.accent});

  final AppTheme theme;
  final AppAccent accent;

  static const _themeKey = 'appearance.theme';
  static const _accentKey = 'appearance.accent';

  static Future<ThemePreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ThemePreferences(
      theme: _parseValue(
        preferences.getString(_themeKey),
        AppTheme.values,
        AppTheme.dark,
      ),
      accent: _parseValue(
        preferences.getString(_accentKey),
        AppAccent.values,
        AppAccent.gold,
      ),
    );
  }

  static Future<void> save({
    required AppTheme theme,
    required AppAccent accent,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final results = await Future.wait([
      preferences.setString(_themeKey, theme.name),
      preferences.setString(_accentKey, accent.name),
    ]);
    if (results.any((saved) => !saved)) {
      throw StateError('Görünüm tercihleri cihaza kaydedilemedi.');
    }
  }

  static T _parseValue<T extends Enum>(
    String? storedValue,
    List<T> values,
    T defaultValue,
  ) {
    if (storedValue == null) return defaultValue;
    for (final value in values) {
      if (value.name == storedValue) return value;
    }
    throw FormatException('Kaydedilmiş görünüm tercihi tanınmıyor.');
  }
}
