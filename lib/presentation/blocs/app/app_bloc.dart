// App Bloc - global app state, first-run, onboarding, lock state
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_state.dart';

class AppBloc extends Cubit<AppState> {
  AppBloc() : super(const AppState.initial());

  void start() {
    emit(state.copyWith(status: AppStatus.ready));
  }

  void lock() => emit(state.copyWith(status: AppStatus.locked));

  void unlock() => emit(state.copyWith(status: AppStatus.ready));

  void setOnboardingComplete() {
    emit(
      state.copyWith(
        status: AppStatus.ready,
        hasOnboarded: true,
      ),
    );
  }
}
