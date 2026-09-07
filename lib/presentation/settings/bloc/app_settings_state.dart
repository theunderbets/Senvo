import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    required this.themeMode,
    required this.locale,
    this.isDisasterMode = false,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool isDisasterMode;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isDisasterMode,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isDisasterMode: isDisasterMode ?? this.isDisasterMode,
    );
  }

  @override
  List<Object> get props => [themeMode, locale, isDisasterMode];
}
