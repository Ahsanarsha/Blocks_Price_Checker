// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:blocks_guide/helpers/sql_server_connection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionHelper {
  Future<void> checkInitialConnection(
      ConnectionProvider connectionProvider) async {
    log('checkInitialConnection started');
    bool isConnected = false;

    // Add a small delay to ensure Flutter engine is ready in release mode
    await Future.delayed(const Duration(milliseconds: 500));

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      log('Error initializing SharedPreferences: $e');
      connectionProvider.updateConnectionStatus(false);
      return;
    }

    if (prefs.containsKey('serverIp') &&
        prefs.containsKey('database') &&
        prefs.containsKey('userName') &&
        prefs.containsKey('password')) {
      final serverIp = prefs.getString('serverIp')!;
      final database = prefs.getString('database')!;
      final username = prefs.getString('userName')!;
      final password = prefs.getString('password')!;

      try {
        final sqlConnection = SqlServerConnection();

        // First initialize connection
        bool connected = await sqlConnection.initializeConnection(
          serverIp,
          database,
          username,
          password,
        );

        if (connected) {
          // Test connection by querying the Products table
          var response = await sqlConnection.getRowsOfQueryResult(
            "SELECT TOP 1 * FROM Products",
          );

          isConnected = response != null && response is List && response.isNotEmpty;

          log('Database connection initialized: $isConnected');

          if (isConnected) {
            log('successfully connect to the database');
            connectionProvider.updateConnectionStatus(true);
          } else {
            log('Failed to connect to the database');
            connectionProvider.updateConnectionStatus(false);
          }
        } else {
          log('Failed to establish connection');
          connectionProvider.updateConnectionStatus(false);
        }
      } catch (e) {
        log('Database connection error: $e');
        connectionProvider.updateConnectionStatus(false);
      }
    } else {
      log('Missing database credentials in SharedPreferences');
      connectionProvider.updateConnectionStatus(false);
    }

    log('Final connection status: $isConnected');
  }

  // check internet connectivity
  Future<bool> checkConnectivity() async {
    // connectivity_plus 6+ reports a list of active transports.
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }
}
