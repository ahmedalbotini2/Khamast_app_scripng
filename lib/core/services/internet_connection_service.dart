import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetConnectivityService {
  static const String noInternetMessage = 'لايوجد اتصال انترنت';

  static final InternetConnection _connection = InternetConnection();

  /// Verifies whether the device currently has internet access.
  static Future<bool> get hasInternet async {
    try {
      return await _connection.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  /// Emits the real-time internet status.
  static Stream<bool> get statusStream => _connection.onStatusChange.map(
        (status) => status == InternetStatus.connected,
      );

  /// Checks the connection and shows a SnackBar if offline.
  /// Returns true when internet is available.
  static Future<bool> checkAndNotify(BuildContext context) async {
    final connected = await hasInternet;
    if (!connected && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(noInternetMessage)));
    }
    return connected;
  }
}