import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _connectivityStreamController = StreamController<bool>.broadcast();
  bool _isOnline = false;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isConnected = _hasConnection(results);
      if (isConnected) {
        _isOnline = await _pingCloudinary();
      } else {
        _isOnline = false;
      }
      _connectivityStreamController.add(_isOnline);
    });
    
    // Initial check
    checkConnectivity();
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    if (results.contains(ConnectivityResult.none)) return false;
    return results.any((r) => 
        r == ConnectivityResult.mobile || 
        r == ConnectivityResult.wifi || 
        r == ConnectivityResult.ethernet);
  }

  Future<bool> _pingCloudinary() async {
    try {
      final response = await http.head(Uri.parse('https://api.cloudinary.com')).timeout(const Duration(seconds: 3));
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  bool get isOnline => _isOnline;

  Stream<bool> get connectivityStream => _connectivityStreamController.stream;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    if (_hasConnection(results)) {
      _isOnline = await _pingCloudinary();
    } else {
      _isOnline = false;
    }
    _connectivityStreamController.add(_isOnline);
    return _isOnline;
  }

  void dispose() {
    _connectivityStreamController.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});
