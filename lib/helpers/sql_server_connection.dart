import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mssql_connection/mssql_connection.dart';

/// SQL Server access for the app, backed by the `mssql_connection` package
/// (Dart FFI + FreeTDS).
///
/// This class keeps the same contract the old `connect_to_sql_server_directly`
/// plugin had, so the rest of the app behaves exactly as before:
///
/// * [initializeConnection] validates and stores the credentials process-wide.
///   It does not open a socket. It returns `false` only when the server or
///   database name is blank.
/// * [getRowsOfQueryResult] opens a fresh connection for every query, runs it,
///   and closes the connection again. On success it returns the rows as a
///   `List<Map<String, dynamic>>`; on any connection or SQL failure it returns
///   a `String` error message instead of throwing.
///
/// Each query runs in a short-lived background isolate so the synchronous
/// FreeTDS calls never block the UI, and queries are serialised so only one
/// connection is in flight at a time.
class SqlServerConnection {
  static _SqlCredentials? _credentials;
  static Future<void> _queue = Future.value();

  /// Port used when the server field does not include one.
  static const String defaultPort = '1433';

  /// Time allowed for the TCP connect and TDS login.
  static const int loginTimeoutSeconds = 15;

  /// Upper bound for one full round trip (connect, execute, disconnect).
  static const Duration queryTimeout = Duration(seconds: 45);

  /// TLS settings passed straight through to `mssql_connection`.
  ///
  /// `encrypt == null` keeps the FreeTDS default. Set `encrypt = true` if the
  /// server forces encryption, and `trustServerCertificate = true` if it uses a
  /// self-signed certificate.
  static const bool? encrypt = null;
  static const bool trustServerCertificate = false;

  /// Session options applied right after every connect.
  ///
  /// JDBC/ODBC drivers (including the old jTDS plugin) turn these on at login,
  /// but FreeTDS DB-Library leaves them off. Queries that use XML data type
  /// methods, indexed views or computed columns fail with SQL Server error
  /// 1934 unless they are on, so this keeps the session identical to before.
  static const String sessionOptions = 'SET ANSI_NULLS ON; '
      'SET ANSI_PADDING ON; '
      'SET ANSI_WARNINGS ON; '
      'SET ANSI_NULL_DFLT_ON ON; '
      'SET QUOTED_IDENTIFIER ON; '
      'SET CONCAT_NULL_YIELDS_NULL ON; '
      'SET ARITHABORT ON; '
      'SET NUMERIC_ROUNDABORT OFF;';

  /// Stores the connection details for later queries.
  ///
  /// [serverIp] may be `host`, `host:port` or `host,port`. [instance] is kept
  /// for API compatibility only; FreeTDS cannot resolve named instances, so use
  /// the instance's static TCP port instead.
  Future<bool> initializeConnection(
    String serverIp,
    String database,
    String userName,
    String password, {
    String instance = '',
  }) async {
    if (serverIp.trim().isEmpty || database.trim().isEmpty) {
      log('SqlServerConnection: server or database name is empty');
      return false;
    }

    final endpoint = parseEndpoint(serverIp);
    _credentials = _SqlCredentials(
      host: endpoint.host,
      port: endpoint.port,
      database: database.trim(),
      userName: userName,
      password: password,
    );
    return true;
  }

  /// Runs a SELECT and returns its rows, or a `String` describing the failure.
  Future<dynamic> getRowsOfQueryResult(String queryString) async {
    final credentials = _credentials;
    if (credentials == null) {
      return 'Error: connection not initialized. '
          'Call initializeConnection first.';
    }
    return _synchronized(() => _runQuery(credentials, queryString));
  }

  /// Serialises work so two queries never share FreeTDS at the same time.
  static Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  static Future<dynamic> _runQuery(
    _SqlCredentials credentials,
    String query,
  ) async {
    try {
      final raw = await Isolate.run(
        () => _executeInIsolate(credentials, query),
      ).timeout(queryTimeout);
      return parseRows(raw);
    } on TimeoutException {
      final message =
          'Error: query timed out after ${queryTimeout.inSeconds} seconds';
      log('SqlServerConnection: $message');
      return message;
    } catch (e) {
      log('SqlServerConnection: query failed: $e');
      return 'Error: $e';
    }
  }

  /// Connects, executes [query] and disconnects. Runs inside a worker isolate.
  static Future<String> _executeInIsolate(
    _SqlCredentials credentials,
    String query,
  ) async {
    final host = credentials.host;
    final port = credentials.port;

    // Fail fast with a clear message when the host cannot be reached at all.
    try {
      final socket = await Socket.connect(
        host,
        int.parse(port),
        timeout: const Duration(seconds: loginTimeoutSeconds),
      );
      socket.destroy();
    } catch (e) {
      throw SQLException('Host unreachable ($host:$port): $e');
    }

    final connection = MssqlConnection.getInstance();
    final connected = await connection.connect(
      ip: host,
      port: port,
      databaseName: credentials.database,
      username: credentials.userName,
      password: credentials.password,
      timeoutInSeconds: loginTimeoutSeconds,
      encrypt: encrypt,
      trustServerCertificate: trustServerCertificate,
    );
    if (!connected) {
      throw SQLException(
        'Unable to connect to $host:$port/${credentials.database}. '
        'Check the credentials and database name.',
      );
    }

    try {
      await connection.writeData(sessionOptions);
      return await connection.getData(query);
    } finally {
      await connection.disconnect();
    }
  }

  /// Converts the package's `{columns, rows, affected, error?}` JSON into the
  /// row list the app expects, or an error `String`.
  @visibleForTesting
  static dynamic parseRows(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return 'Error: unexpected response from SQL Server: $raw';
    }

    final error = decoded['error'];
    if (error != null) {
      return 'Error: $error';
    }

    final rows = decoded['rows'];
    if (rows is! List) {
      return <Map<String, dynamic>>[];
    }
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  /// Splits `host`, `host:port` or `host,port` into its parts.
  @visibleForTesting
  static ({String host, String port}) parseEndpoint(String server) {
    final trimmed = server.trim();
    final match = RegExp(r'^(.+?)\s*[:,]\s*(\d{1,5})$').firstMatch(trimmed);
    if (match != null) {
      return (host: match.group(1)!.trim(), port: match.group(2)!);
    }
    return (host: trimmed, port: defaultPort);
  }
}

/// Plain data holder so the credentials can be sent to the worker isolate.
class _SqlCredentials {
  final String host;
  final String port;
  final String database;
  final String userName;
  final String password;

  const _SqlCredentials({
    required this.host,
    required this.port,
    required this.database,
    required this.userName,
    required this.password,
  });
}
