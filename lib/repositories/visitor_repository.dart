import '../models/visitor.dart';

class VisitorException implements Exception {
  const VisitorException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class VisitorRepository {
  Future<List<Visitor>> list();
  Future<Visitor> get(String id);
  Future<Visitor> create(Map<String, dynamic> fields);
  Future<Visitor> update(String id, Map<String, dynamic> fields);
  Future<void> delete(String id);
  void dispose() {}
}
