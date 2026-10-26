import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:antika_stok/tema.dart';
import 'package:antika_stok/tema_tercihleri.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('missing preferences use the application defaults', () async {
    final preferences = await ThemePreferences.load();

    expect(preferences.theme, AppTheme.dark);
    expect(preferences.accent, AppAccent.gold);
  });

  test('saved appearance is restored', () async {
    await ThemePreferences.save(theme: AppTheme.light, accent: AppAccent.jade);

    final preferences = await ThemePreferences.load();

    expect(preferences.theme, AppTheme.light);
    expect(preferences.accent, AppAccent.jade);
  });

  test('unknown stored values are surfaced', () async {
    SharedPreferences.setMockInitialValues({'appearance.theme': 'sepia'});

    await expectLater(ThemePreferences.load(), throwsFormatException);
  });
}
