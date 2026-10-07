// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _themeKey = 'pdf-magic-theme-mode';

  final SharedPreferencesAsync _preferences;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final stored = await _preferences.getString(_themeKey);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) {
      return;
    }

    _themeMode = value;
    notifyListeners();

    final stored = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _preferences.setString(_themeKey, stored);
  }

  Future<void> toggleTheme(Brightness visibleBrightness) {
    return setThemeMode(
      visibleBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
