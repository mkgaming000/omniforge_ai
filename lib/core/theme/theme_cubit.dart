// Theme Cubit - Manages light/dark/system theme mode with persistence
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'theme_state.dart';

class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  void loadTheme() {
    // State is already hydrated from storage
    emit(state);
  }

  void setLightMode() => emit(const ThemeState(themeMode: ThemeMode.light));

  void setDarkMode() => emit(const ThemeState(themeMode: ThemeMode.dark));

  void setSystemMode() => emit(const ThemeState(themeMode: ThemeMode.system));

  void toggleTheme() {
    final newMode =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(ThemeState(themeMode: newMode));
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) => ThemeState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ThemeState state) => state.toJson();
}
