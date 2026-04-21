import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.pin, this.pinEnabled = false});
  final ThemeMode themeMode;
  final String? pin;
  final bool pinEnabled;

  AppSettings copyWith({ThemeMode? themeMode, String? pin, bool? pinEnabled}) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    pin: pin ?? this.pin,
    pinEnabled: pinEnabled ?? this.pinEnabled,
  );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _pinKey = 'pin';
  static const _pinEnabledKey = 'pin_enabled';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final pin = prefs.getString(_pinKey);
    final pinEnabled = prefs.getBool(_pinEnabledKey) ?? false;
    return AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      pin: pin,
      pinEnabled: pinEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    state = AsyncData(state.requireValue.copyWith(themeMode: mode));
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
    state = AsyncData(state.requireValue.copyWith(pin: pin, pinEnabled: true));
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
    state = AsyncData(AppSettings(themeMode: state.requireValue.themeMode));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
