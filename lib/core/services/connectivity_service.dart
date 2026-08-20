import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus {
  online,
  offline,
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<ConnectionStatus> connectionStatusController = StreamController<ConnectionStatus>();

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        connectionStatusController.add(ConnectionStatus.offline);
      } else {
        connectionStatusController.add(ConnectionStatus.online);
      }
    });
  }

  Future<ConnectionStatus> checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      return ConnectionStatus.offline;
    } else {
      return ConnectionStatus.online;
    }
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectionStatusController.stream;
});