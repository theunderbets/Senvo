import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._prefs)
      : super(const AppSettingsState(
          themeMode: ThemeMode.system,
          locale: Locale('en'),
        )) {
    _loadSettings();
  }

  final SharedPreferences _prefs;

  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale';
  static const _disasterModeKey = 'app_disaster_mode';

  void _loadSettings() {
    final themeStr = _prefs.getString(_themeKey);
    ThemeMode themeMode = ThemeMode.system;
    if (themeStr != null) {
      if (themeStr == 'light') themeMode = ThemeMode.light;
      if (themeStr == 'dark') themeMode = ThemeMode.dark;
    }

    final localeStr = _prefs.getString(_localeKey);
    Locale locale = const Locale('en');
    if (localeStr != null && localeStr.isNotEmpty) {
      locale = Locale(localeStr);
    }

    final isDisasterMode = _prefs.getBool(_disasterModeKey) ?? false;

    emit(state.copyWith(
      themeMode: themeMode, 
      locale: locale,
      isDisasterMode: isDisasterMode,
    ));
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    String themeStr = 'system';
    if (themeMode == ThemeMode.light) themeStr = 'light';
    if (themeMode == ThemeMode.dark) themeStr = 'dark';
    await _prefs.setString(_themeKey, themeStr);
    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> updateLocale(Locale locale) async {
    await _prefs.setString(_localeKey, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> updateDisasterMode(bool isDisasterMode) async {
    await _prefs.setBool(_disasterModeKey, isDisasterMode);
    emit(state.copyWith(isDisasterMode: isDisasterMode));
  }
}
