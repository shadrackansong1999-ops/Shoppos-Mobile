import '../db/base_repository.dart';

class ProductsRepository {
  final _repo = BaseRepository('products');

  Future<List<Map<String, dynamic>>> getAll({String? searchQuery, bool activeOnly = true}) async {
    final rows = await _repo.getAll(
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    if (searchQuery == null || searchQuery.trim().isEmpty) return rows;
    final q = searchQuery.trim().toLowerCase();
    return rows.where((r) {
      final name = (r['name'] as String? ?? '').toLowerCase();
      final sku = (r['sku'] as String? ?? '').toLowerCase();
      final barcode = (r['barcode'] as String? ?? '').toLowerCase();
      return name.contains(q) || sku.contains(q) || barcode.contains(q);
    }).toList();
  }

  Future<Map<String, dynamic>?> getById(String id) => _repo.getById(id);

  Future<Map<String, dynamic>?> findByBarcode(String barcode) async {
    final rows = await _repo.getAll(where: 'barcode = ?', whereArgs: [barcode]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> lowStock() async {
    final rows = await _repo.getAll(where: 'is_active = 1');
    return rows.where((r) => (r['quantity'] as num) <= (r['reorder_level'] as num)).toList();
  }

  Future<String> create(Map<String, dynamic> data) => _repo.insert(data);

  Future<void> update(String id, Map<String, dynamic> data) => _repo.update(id, data);

  Future<void> delete(String id) => _repo.softDelete(id);

  /// Adjusts stock by [delta] (negative for a sale, positive for a
  /// restock/return) and records the movement. Runs as part of the
  /// caller's transaction when one is provided (sales checkout), or
  /// standalone otherwise (manual stock adjustment screen).
  Future<void> adjustStock(String productId, num delta, String movementType, {String? reference, String? notes}) async {
    final product = await getById(productId);
    if (product == null) return;
    final newQty = (product['quantity'] as num) + delta;
    await update(productId, {'quantity': newQty});
    final stockRepo = BaseRepository('stock_movements');
    await stockRepo.insert({
      'product_id': productId,
      'movement_type': movementType,
      'quantity': delta,
      'reference': reference,
      'notes': notes,
    });
  }
}
