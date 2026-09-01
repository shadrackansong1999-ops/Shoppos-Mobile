import 'package:flutter/material.dart';

import '../../../core/repositories/simple_repositories.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/generic_crud_screen.dart';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({super.key});
  final _repo = CategoriesRepository();

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Categories',
      fields: const [
        FieldSpec('name', 'Name', required: true),
        FieldSpec('description', 'Description'),
      ],
      fetchAll: _repo.getAll,
      onCreate: _repo.create,
      onUpdate: _repo.update,
      onDelete: _repo.delete,
      titleBuilder: (r) => r['name'] as String? ?? '',
      subtitleBuilder: (r) => r['description'] as String?,
    );
  }
}

class SuppliersScreen extends StatelessWidget {
  SuppliersScreen({super.key});
  final _repo = SuppliersRepository();

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Suppliers',
      fields: const [
        FieldSpec('name', 'Name', required: true),
        FieldSpec('contact_person', 'Contact Person'),
        FieldSpec('phone', 'Phone', keyboardType: TextInputType.phone),
        FieldSpec('email', 'Email', keyboardType: TextInputType.emailAddress),
        FieldSpec('address', 'Address'),
        FieldSpec('notes', 'Notes'),
      ],
      fetchAll: _repo.getAll,
      onCreate: _repo.create,
      onUpdate: _repo.update,
      onDelete: _repo.delete,
      titleBuilder: (r) => r['name'] as String? ?? '',
      subtitleBuilder: (r) => r['phone'] as String?,
    );
  }
}

class CustomersScreen extends StatelessWidget {
  CustomersScreen({super.key});
  final _repo = CustomersRepository();

  Map<String, dynamic> _coerce(Map<String, dynamic> d) =>
      {...d, 'discount_rate': num.tryParse('${d['discount_rate']}') ?? 0};

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Customers',
      fields: const [
        FieldSpec('name', 'Name', required: true),
        FieldSpec('phone', 'Phone', keyboardType: TextInputType.phone),
        FieldSpec('email', 'Email', keyboardType: TextInputType.emailAddress),
        FieldSpec('address', 'Address'),
        FieldSpec('discount_rate', 'Default Discount %', keyboardType: TextInputType.number),
      ],
      fetchAll: _repo.getAll,
      onCreate: (d) => _repo.create(_coerce(d)),
      onUpdate: (id, d) => _repo.update(id, _coerce(d)),
      onDelete: _repo.delete,
      titleBuilder: (r) => r['name'] as String? ?? '',
      subtitleBuilder: (r) => r['phone'] as String?,
    );
  }
}

class ExpensesScreen extends StatelessWidget {
  ExpensesScreen({super.key});
  final _repo = ExpensesRepository();

  Map<String, dynamic> _coerce(Map<String, dynamic> d) =>
      {...d, 'amount': num.tryParse('${d['amount']}') ?? 0};

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Expenses',
      fields: const [
        FieldSpec('category', 'Category', required: true),
        FieldSpec('description', 'Description', required: true),
        FieldSpec('amount', 'Amount', keyboardType: TextInputType.number, required: true),
      ],
      fetchAll: _repo.getAll,
      onCreate: (d) => _repo.create(_coerce(d)),
      onUpdate: (id, d) => _repo.update(id, _coerce(d)),
      onDelete: _repo.delete,
      titleBuilder: (r) => '${r['description']}',
      subtitleBuilder: (r) => '${r['category']} - ${Money.format(num.tryParse('${r['amount']}') ?? 0)}',
    );
  }
}
