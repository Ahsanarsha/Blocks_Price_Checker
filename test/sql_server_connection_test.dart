import 'package:blocks_guide/helpers/sql_server_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SqlServerConnection.parseEndpoint', () {
    test('plain host defaults to port 1433', () {
      expect(
        SqlServerConnection.parseEndpoint('192.168.1.10'),
        equals((host: '192.168.1.10', port: '1433')),
      );
    });

    test('hostname defaults to port 1433', () {
      expect(
        SqlServerConnection.parseEndpoint('sqlserver.local'),
        equals((host: 'sqlserver.local', port: '1433')),
      );
    });

    test('host:port (jTDS style) is split', () {
      expect(
        SqlServerConnection.parseEndpoint('192.168.1.10:1434'),
        equals((host: '192.168.1.10', port: '1434')),
      );
    });

    test('host,port (SQL Server style) is split', () {
      expect(
        SqlServerConnection.parseEndpoint('192.168.1.10,49242'),
        equals((host: '192.168.1.10', port: '49242')),
      );
    });

    test('surrounding whitespace is ignored', () {
      expect(
        SqlServerConnection.parseEndpoint('  192.168.1.10 : 1433  '),
        equals((host: '192.168.1.10', port: '1433')),
      );
    });
  });

  group('SqlServerConnection.parseRows', () {
    test('returns rows and preserves value types', () {
      final result = SqlServerConnection.parseRows(
        '{"columns":["keycode","ProductName","RetailPrice","OnSpecial","SpecialPrice"],'
        '"rows":[{"keycode":12345,"ProductName":"Milk 2L","RetailPrice":12.99,'
        '"OnSpecial":true,"SpecialPrice":null}],"affected":0}',
      );

      expect(result, isA<List<Map<String, dynamic>>>());
      final rows = result as List<Map<String, dynamic>>;
      expect(rows, hasLength(1));
      expect(rows.first['keycode'], 12345);
      expect(rows.first['keycode'], isA<int>());
      expect(rows.first['ProductName'], 'Milk 2L');
      expect(rows.first['RetailPrice'], 12.99);
      expect(rows.first['OnSpecial'], isTrue);
      expect(rows.first['SpecialPrice'], isNull);
    });

    test('empty result set returns an empty list', () {
      final result = SqlServerConnection.parseRows(
        '{"columns":["keycode"],"rows":[],"affected":0}',
      );
      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result, isEmpty);
    });

    test('missing rows key returns an empty list', () {
      final result = SqlServerConnection.parseRows('{"affected":1}');
      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result, isEmpty);
    });

    test('error payload returns an error string', () {
      final result = SqlServerConnection.parseRows(
        '{"columns":[],"rows":[],"affected":0,"error":"Invalid object name"}',
      );
      expect(result, isA<String>());
      expect(result, contains('Invalid object name'));
    });

    test('non-object payload returns an error string', () {
      expect(SqlServerConnection.parseRows('[1,2,3]'), isA<String>());
    });
  });

  group('SqlServerConnection API contract', () {
    test('query before initializeConnection returns an error string', () async {
      final result =
          await SqlServerConnection().getRowsOfQueryResult('SELECT 1');
      expect(result, isA<String>());
      expect(result, startsWith('Error:'));
    });

    test('initializeConnection rejects a blank server', () async {
      expect(
        await SqlServerConnection().initializeConnection('  ', 'db', 'u', 'p'),
        isFalse,
      );
    });

    test('initializeConnection rejects a blank database', () async {
      expect(
        await SqlServerConnection().initializeConnection('host', '', 'u', 'p'),
        isFalse,
      );
    });

    test('initializeConnection accepts complete credentials', () async {
      expect(
        await SqlServerConnection()
            .initializeConnection('127.0.0.1:1', 'db', 'u', 'p'),
        isTrue,
      );
    });

    test('unreachable host yields a String, not an exception', () async {
      // Port 1 on loopback is closed, so the TCP probe fails immediately.
      final result =
          await SqlServerConnection().getRowsOfQueryResult('SELECT 1');
      expect(result, isA<String>());
      expect(result, contains('Host unreachable'));
    });
  });
}
