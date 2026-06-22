// App State
import 'package:equatable/equatable.dart';

enum AppStatus { initial, ready, locked, onboarding }

class AppState extends Equatable {
  const AppState({
    this.status = AppStatus.initial,
    this.hasOnboarded = false,
    this.biolockEnabled = false,
  });

  const AppState.initial() : this();

  final AppStatus status;
  final bool hasOnboarded;
  final bool biolockEnabled;

  AppState copyWith({
    AppStatus? status,
    bool? hasOnboarded,
    bool? biolockEnabled,
  }) {
    return AppState(
      status: status ?? this.status,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      biolockEnabled: biolockEnabled ?? this.biolockEnabled,
    );
  }

  @override
  List<Object?> get props => [status, hasOnboarded, biolockEnabled];
}
