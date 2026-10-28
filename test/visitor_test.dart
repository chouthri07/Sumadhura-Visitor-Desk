import 'package:sumadhura_project/repositories/local_visitor_repository.dart';
import 'package:sumadhura_project/repositories/api_visitor_repository.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumadhura_project/repositories/visitor_repository.dart';
import 'package:sumadhura_project/models/visitor.dart';
import 'package:sumadhura_project/providers/visitor_store.dart';

Map<String, dynamic> fields() => {
  'name': 'Rahul Sharma',
  'mobile': '9876543210',
  'email': null,
  'visitor_type': 'Customer',
  'project': 'Project A',
  'purpose': 'Site visit',
};
Map<String, dynamic> record() => {
  ...fields(),
  'id': '42',
  'status': 'Registered',
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'check_in_time': null,
  'check_out_time': null,
};
void main() {
  test(
    'complete lifecycle persists, synchronizes counts and rejects repeat transitions',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = VisitorStore(LocalVisitorRepository(prefs));
      final v = await store.save(fields());
      expect(v.status, VisitStatus.registered);
      expect(store.registeredToday(DateTime.now()), 1);
      await expectLater(
        store.changeStatus(v.id, VisitStatus.checkedOut),
        throwsStateError,
      );
      await store.changeStatus(v.id, VisitStatus.checkedIn);
      expect(store.checkedIn, 1);
      await expectLater(
        store.changeStatus(v.id, VisitStatus.checkedIn),
        throwsStateError,
      );
      await store.changeStatus(v.id, VisitStatus.checkedOut);
      expect(store.checkedIn, 0);
      expect(store.checkedOutToday(DateTime.now()), 1);
      await expectLater(
        store.changeStatus(v.id, VisitStatus.checkedIn),
        throwsStateError,
      );
      final restarted = VisitorStore(LocalVisitorRepository(prefs));
      await restarted.load();
      expect(restarted.find(v.id)!.status, VisitStatus.checkedOut);
      expect(restarted.find(v.id)!.checkInTime, isNotNull);
      expect(restarted.find(v.id)!.checkOutTime, isNotNull);
      await restarted.save({...fields(), 'name': 'Updated'}, id: v.id);
      expect(restarted.find(v.id)!.status, VisitStatus.checkedOut);
      expect(restarted.find(v.id)!.name, 'Updated');
      restarted.filter(search: '9876');
      expect(restarted.filtered, hasLength(1));
      restarted.filter(setFilters: true, project: 'Project B');
      expect(restarted.filtered, isEmpty);
      await restarted.delete(v.id);
      expect(await LocalVisitorRepository(prefs).list(), isEmpty);
      store.dispose();
      restarted.dispose();
    },
  );
  test('local day metrics compare device-local dates and null values', () {
    final today = DateTime(2026, 10, 28, 15);
    expect(sameLocalDay(DateTime(2026, 10, 28).toUtc(), today), isTrue);
    expect(sameLocalDay(DateTime(2026, 10, 27, 23, 59), today), isFalse);
    expect(sameLocalDay(null, today), isFalse);
  });
  test('QR payload accepts raw API ID and rejects URLs or malformed input', () {
    expect(parseVisitorQr(' VIS001 '), 'VIS001');
    expect(parseVisitorQr('42'), '42');
    for (final value in [
      '',
      'https://evil.example/42',
      '{"id":42}',
      '../42',
      'a b',
    ]) {
      expect(() => parseVisitorQr(value), throwsFormatException);
    }
  });
  test('REST sends CRUD requests and uses server-issued IDs', () async {
    final methods = <String>[];
    final repo = ApiVisitorRepository(
      'https://example.test/visitors',
      client: MockClient((request) async {
        methods.add(request.method);
        if (request.method == 'DELETE') return http.Response('', 204);
        if (request.method == 'GET' && request.url.path == '/visitors') {
          return http.Response(jsonEncode([record()]), 200);
        }
        if (request.method == 'POST') {
          expect(jsonDecode(request.body).containsKey('id'), isFalse);
        }
        if (request.url.path != '/visitors') {
          expect(request.url.path, '/visitors/42');
        }
        return http.Response(jsonEncode(record()), 200);
      }),
    );
    expect(await repo.list(), hasLength(1));
    expect((await repo.create(fields())).id, '42');
    await repo.get('42');
    await repo.update('42', {'name': 'Updated'});
    await repo.delete('42');
    expect(methods, ['GET', 'POST', 'GET', 'PUT', 'DELETE']);
    repo.dispose();
  });
  test(
    'REST surfaces server, missing visitor and invalid response failures',
    () async {
      for (final response in [
        http.Response('no', 500),
        http.Response('missing', 404),
        http.Response('not json', 200),
        http.Response('{}', 200),
        http.Response('[{}]', 200),
      ]) {
        final repo = ApiVisitorRepository(
          'https://example.test/visitors',
          client: MockClient((_) async => response),
        );
        await expectLater(repo.list(), throwsA(isA<VisitorException>()));
        repo.dispose();
      }
    },
  );
}
