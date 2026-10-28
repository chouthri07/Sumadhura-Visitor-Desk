import 'package:flutter/foundation.dart';
import '../repositories/visitor_repository.dart';
import '../models/visitor.dart';

class VisitorStore extends ChangeNotifier {
  VisitorStore(this.repository);
  final VisitorRepository repository;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  List<Visitor> _visitors = [];
  List<Visitor> get visitors => List.unmodifiable(_visitors);
  bool loading = false, saving = false;
  String? error;
  String query = '';
  String? projectFilter;
  VisitStatus? statusFilter;
  int _revision = 0;
  List<Visitor> get filtered => _visitors
      .where(
        (v) =>
            (v.name.toLowerCase().contains(query.toLowerCase()) ||
                v.mobile.contains(query)) &&
            (projectFilter == null || projectFilter == v.project) &&
            (statusFilter == null || statusFilter == v.status),
      )
      .toList();
  int registeredToday(DateTime now) =>
      _visitors.where((v) => sameLocalDay(v.createdAt, now)).length;
  int get checkedIn =>
      _visitors.where((v) => v.status == VisitStatus.checkedIn).length;
  int checkedOutToday(DateTime now) =>
      _visitors.where((v) => sameLocalDay(v.checkOutTime, now)).length;
  Visitor? find(String id) {
    for (final v in _visitors) {
      if (v.id == id) return v;
    }
    return null;
  }

  void filter({
    String? search,
    String? project,
    VisitStatus? status,
    bool setFilters = false,
  }) {
    if (search != null) query = search;
    if (setFilters) {
      projectFilter = project;
      statusFilter = status;
    }
    notifyListeners();
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    final revision = _revision;
    notifyListeners();
    try {
      final result = await repository.list();
      if (revision == _revision) {
        _visitors = result..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      error = message(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _upsert(Visitor visitor) {
    _revision++;
    _visitors.removeWhere((v) => v.id == visitor.id);
    _visitors.add(visitor);
    _visitors.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<Visitor> lookup(String id) async {
    final visitor = await repository.get(parseVisitorQr(id));
    _upsert(visitor);
    return visitor;
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    if (saving) {
      throw const VisitorException(
        'Another change is being saved. Please wait.',
      );
    }
    saving = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<Visitor> save(Map<String, dynamic> fields, {String? id}) =>
      _mutate(() async {
        final Visitor visitor;
        if (id == null) {
          visitor = await repository.create({
            ...fields,
            'status': 'Registered',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'check_in_time': null,
            'check_out_time': null,
          });
        } else {
          final latest = await repository.get(id);
          visitor = await repository.update(id, {
            ...latest.toJson()..remove('id'),
            ...fields,
          });
        }
        _upsert(visitor);
        return visitor;
      });
  Future<void> changeStatus(String id, VisitStatus target) => _mutate(() async {
    final current = await repository.get(id);
    final changes = current.transition(target, DateTime.now());
    final updated = await repository.update(id, {
      ...current.toJson()..remove('id'),
      ...changes,
    });
    _upsert(updated);
  });
  Future<void> delete(String id) => _mutate(() async {
    await repository.delete(id);
    _revision++;
    _visitors.removeWhere((v) => v.id == id);
    notifyListeners();
  });
  static String message(Object e) => e is VisitorException
      ? e.message
      : e is StateError
      ? e.message.toString()
      : e is FormatException
      ? e.message
      : 'Something went wrong. Please try again.';
  @override
  void dispose() {
    _disposed = true;
    repository.dispose();
    super.dispose();
  }
}
