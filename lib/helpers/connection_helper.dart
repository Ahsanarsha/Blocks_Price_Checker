// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'dart:convert';

import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionHelper {
  Future<void> checkInitialConnection(
      ConnectionProvider connectionProvider) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    log('checkInitialConnection started');
    bool isConnected = false;

    if (prefs.containsKey('serverIp') &&
        prefs.containsKey('database') &&
        prefs.containsKey('userName') &&
        prefs.containsKey('password')) {
      final serverIp = prefs.getString('serverIp')!;
      final database = prefs.getString('database')!;
      final username = prefs.getString('userName')!;
      final password = prefs.getString('password')!;

      try {
        final mssqlConnection = MssqlConnection.getInstance();

        // First connect to the database
        bool connected = await mssqlConnection.connect(
          ip: serverIp,
          port: '1433',
          databaseName: database,
          username: username,
          password: password,
          timeoutInSeconds: 15,
        );

        if (connected) {
          // Test connection by querying the Products table
          // mssql_connection v2.0.0 returns a JSON array directly, not a Map with 'rows' key
          final response = await mssqlConnection.getData("SELECT TOP 1 * FROM Products;");
          final decodedResponse = jsonDecode(response);
          isConnected = decodedResponse is List && decodedResponse.isNotEmpty;

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
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet) {
      return true;
    } else {
      return false;
    }
  }
}
