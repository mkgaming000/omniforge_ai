import 'package:equatable/equatable.dart';

import '../../../domain/entities/usage_entity.dart';

abstract class UsageEvent extends Equatable {
  const UsageEvent();
}

class LoadUsageStats extends UsageEvent {
  const LoadUsageStats({this.since});
  final DateTime? since;
  @override
  List<Object?> get props => [since];
}

class TrackUsage extends UsageEvent {
  const TrackUsage(this.usage);
  final UsageEntity usage;
  @override
  List<Object?> get props => [usage];
}
