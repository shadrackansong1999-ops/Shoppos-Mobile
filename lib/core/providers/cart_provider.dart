import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String name;
  final num unitPrice;
  final num availableStock;
  num quantity;
  num discount;

  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.availableStock,
    this.quantity = 1,
    this.discount = 0,
  });

  num get total => (unitPrice * quantity) - discount;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? customerId;
  num taxRate = 0; // percentage, set from Settings

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  num get subtotal => _items.fold(0, (sum, i) => sum + (i.unitPrice * i.quantity));
  num get discountTotal => _items.fold(0, (sum, i) => sum + i.discount);
  num get taxableAmount => subtotal - discountTotal;
  num get tax => taxableAmount * (taxRate / 100);
  num get total => taxableAmount + tax;

  void addProduct({required String productId, required String name, required num unitPrice, required num stock}) {
    final existing = _items.where((i) => i.productId == productId).toList();
    if (existing.isNotEmpty) {
      if (existing.first.quantity < existing.first.availableStock) {
        existing.first.quantity += 1;
      }
    } else {
      _items.add(CartItem(productId: productId, name: name, unitPrice: unitPrice, availableStock: stock));
    }
    notifyListeners();
  }

  void setQuantity(String productId, num qty) {
    final item = _items.firstWhere((i) => i.productId == productId);
    item.quantity = qty.clamp(0, item.availableStock == 0 ? qty : item.availableStock);
    if (item.quantity <= 0) _items.remove(item);
    notifyListeners();
  }

  void setDiscount(String productId, num discount) {
    final item = _items.firstWhere((i) => i.productId == productId);
    item.discount = discount.clamp(0, item.unitPrice * item.quantity);
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void setCustomer(String? id) {
    customerId = id;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    customerId = null;
    notifyListeners();
  }
}
