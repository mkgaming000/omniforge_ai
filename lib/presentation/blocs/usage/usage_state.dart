import 'package:equatable/equatable.dart';

import '../../../domain/entities/usage_entity.dart';

enum UsageStatus { initial, loading, ready, error }

class UsageState extends Equatable {
  const UsageState({
    this.status = UsageStatus.initial,
    this.stats,
  });

  const UsageState.initial() : this();

  final UsageStatus status;
  final UsageStats? stats;

  UsageState copyWith({
    UsageStatus? status,
    UsageStats? stats,
  }) {
    return UsageState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [status, stats];
}
