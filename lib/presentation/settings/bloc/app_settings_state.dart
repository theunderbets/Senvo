import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    required this.themeMode,
    required this.locale,
  });

  final ThemeMode themeMode;
  final Locale locale;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props => [themeMode, locale];
}
