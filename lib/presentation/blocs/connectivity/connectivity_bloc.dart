// Connectivity Bloc - fixed imports
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/network_info.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<_ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc({required NetworkInfo networkInfo})
      : super(const ConnectivityState.initial()) {
    _networkInfo = networkInfo;
    on<_StatusChanged>(_onStatusChanged);

    _subscription = _networkInfo.onStatusChange.listen(
      (status) => add(_StatusChanged(mapConnectionStatus(status))),
    );
  }

  late final NetworkInfo _networkInfo;
  late final StreamSubscription<dynamic> _subscription;

  void _onStatusChanged(
    _StatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(ConnectivityState(status: event.status));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}

abstract class _ConnectivityEvent extends Equatable {
  const _ConnectivityEvent();
}

class _StatusChanged extends _ConnectivityEvent {
  const _StatusChanged(this.status);
  final ConnectivityStatus status;
  @override
  List<Object?> get props => [status];
}
