import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visitor.dart';
import 'visitor_repository.dart';

/// Explicit offline demo; never a silent fallback for failed REST calls.
class LocalVisitorRepository extends VisitorRepository {
  LocalVisitorRepository(this.preferences);
  final SharedPreferences preferences;
  static const _key = 'demo_visitors_v1';
  @override
  Future<List<Visitor>> list() async {
    final raw = preferences.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Visitor.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(List<Visitor> visitors) async {
    if (!await preferences.setString(
      _key,
      jsonEncode(visitors.map((v) => v.toJson()).toList()),
    )) {
      throw const VisitorException('Unable to save visitors on this device.');
    }
  }

  @override
  Future<Visitor> get(String id) async => (await list()).firstWhere(
    (v) => v.id == id,
    orElse: () => throw const VisitorException(
      'Visitor not found. It may have been deleted.',
    ),
  );
  @override
  Future<Visitor> create(Map<String, dynamic> fields) async {
    final visitors = await list();
    final visitor = Visitor.fromJson({
      ...fields,
      'id': 'VIS${DateTime.now().microsecondsSinceEpoch}',
    });
    await _save([...visitors, visitor]);
    return visitor;
  }

  @override
  Future<Visitor> update(String id, Map<String, dynamic> fields) async {
    final visitors = await list();
    final index = visitors.indexWhere((v) => v.id == id);
    if (index < 0) throw const VisitorException('Visitor not found.');
    visitors[index] = Visitor.fromJson({
      ...visitors[index].toJson(),
      ...fields,
      'id': id,
    });
    await _save(visitors);
    return visitors[index];
  }

  @override
  Future<void> delete(String id) async {
    final visitors = await list();
    visitors.removeWhere((v) => v.id == id);
    await _save(visitors);
  }
}
