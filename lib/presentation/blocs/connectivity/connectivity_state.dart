// Connectivity State
import 'package:equatable/equatable.dart';

import '../../../core/network/network_info.dart';

enum ConnectivityStatus { online, offline, unknown }

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.status = ConnectivityStatus.unknown,
  });

  const ConnectivityState.initial() : this();

  final ConnectivityStatus status;

  bool get isOnline => status == ConnectivityStatus.online;

  ConnectivityState copyWith({ConnectivityStatus? status}) {
    return ConnectivityState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}

// Helper to map ConnectionStatus -> ConnectivityStatus
ConnectivityStatus mapConnectionStatus(ConnectionStatus s) {
  switch (s) {
    case ConnectionStatus.online:
      return ConnectivityStatus.online;
    case ConnectionStatus.offline:
      return ConnectivityStatus.offline;
  }
}
