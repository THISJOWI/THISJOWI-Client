import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  final Connectivity _connectivity = Connectivity();
  final _connectionStatusController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Couldn\'t check connectivity status: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final isOnline = result.any((r) => r != ConnectivityResult.none);
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionStatusController.add(_isOnline);
    }
  }
}
