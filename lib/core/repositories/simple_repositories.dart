import '../db/base_repository.dart';

/// Thin, near-identical wrappers for the entities that are plain CRUD with
/// no special business logic - Categories, Suppliers, Customers, Expenses.
/// Kept as separate small classes (rather than one generic<T>) so each
/// screen's imports stay obvious and each can grow its own logic later
/// without disturbing the others.

class CategoriesRepository {
  final _repo = BaseRepository('categories');
  Future<List<Map<String, dynamic>>> getAll() => _repo.getAll(orderBy: 'name COLLATE NOCASE ASC');
  Future<Map<String, dynamic>?> getById(String id) => _repo.getById(id);
  Future<String> create(Map<String, dynamic> data) => _repo.insert(data);
  Future<void> update(String id, Map<String, dynamic> data) => _repo.update(id, data);
  Future<void> delete(String id) => _repo.softDelete(id);
}

class SuppliersRepository {
  final _repo = BaseRepository('suppliers');
  Future<List<Map<String, dynamic>>> getAll() => _repo.getAll(orderBy: 'name COLLATE NOCASE ASC');
  Future<Map<String, dynamic>?> getById(String id) => _repo.getById(id);
  Future<String> create(Map<String, dynamic> data) => _repo.insert(data);
  Future<void> update(String id, Map<String, dynamic> data) => _repo.update(id, data);
  Future<void> delete(String id) => _repo.softDelete(id);
}

class CustomersRepository {
  final _repo = BaseRepository('customers');
  Future<List<Map<String, dynamic>>> getAll() => _repo.getAll(orderBy: 'name COLLATE NOCASE ASC');
  Future<Map<String, dynamic>?> getById(String id) => _repo.getById(id);
  Future<String> create(Map<String, dynamic> data) => _repo.insert(data);
  Future<void> update(String id, Map<String, dynamic> data) => _repo.update(id, data);
  Future<void> delete(String id) => _repo.softDelete(id);
}

class ExpensesRepository {
  final _repo = BaseRepository('expenses');
  Future<List<Map<String, dynamic>>> getAll() => _repo.getAll(orderBy: 'created_at DESC');
  Future<String> create(Map<String, dynamic> data) => _repo.insert(data);
  Future<void> update(String id, Map<String, dynamic> data) => _repo.update(id, data);
  Future<void> delete(String id) => _repo.softDelete(id);
}
