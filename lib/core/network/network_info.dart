// Network connectivity monitoring service
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionStatus { online, offline }

class NetworkInfo {
  NetworkInfo._(this._connectivity);

  final Connectivity _connectivity;

  static NetworkInfo create() => NetworkInfo._(Connectivity());

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<ConnectionStatus> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none)
            ? ConnectionStatus.online
            : ConnectionStatus.offline,
      );
}
