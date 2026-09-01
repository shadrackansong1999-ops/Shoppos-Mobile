import 'package:flutter/material.dart';

import '../../core/utils/search.dart';

/// Describes one text field in a generic entity form.
class FieldSpec {
  final String key;
  final String label;
  final TextInputType keyboardType;
  final bool required;
  const FieldSpec(this.key, this.label, {this.keyboardType = TextInputType.text, this.required = false});
}

/// A reusable list + add/edit form for simple CRUD entities (Categories,
/// Suppliers, Customers, Expenses). Each screen just supplies its field
/// list and repository callbacks - this widget handles the list UI, the
/// form dialog, validation, and save/delete wiring.
class GenericCrudScreen extends StatefulWidget {
  final String title;
  final List<FieldSpec> fields;
  final Future<List<Map<String, dynamic>>> Function() fetchAll;
  final Future<void> Function(Map<String, dynamic> data) onCreate;
  final Future<void> Function(String id, Map<String, dynamic> data) onUpdate;
  final Future<void> Function(String id)? onDelete;
  final String Function(Map<String, dynamic> row) titleBuilder;
  final String? Function(Map<String, dynamic> row)? subtitleBuilder;
  final bool canEdit;
  final bool canDelete;

  const GenericCrudScreen({
    super.key,
    required this.title,
    required this.fields,
    required this.fetchAll,
    required this.onCreate,
    required this.onUpdate,
    required this.titleBuilder,
    this.onDelete,
    this.subtitleBuilder,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  State<GenericCrudScreen> createState() => _GenericCrudScreenState();
}

class _GenericCrudScreenState extends State<GenericCrudScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await widget.fetchAll();
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _rows;
    return rankBySearch(
      _rows,
      _query,
      fields: (r) => [
        widget.titleBuilder(r),
        if (widget.subtitleBuilder != null) widget.subtitleBuilder!(r) ?? '',
      ],
    );
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final controllers = {
      for (final f in widget.fields) f.key: TextEditingController(text: existing?[f.key]?.toString() ?? '')
    };
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'Add ${widget.title}' : 'Edit ${widget.title}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                for (final f in widget.fields) ...[
                  TextFormField(
                    controller: controllers[f.key],
                    keyboardType: f.keyboardType,
                    decoration: InputDecoration(labelText: f.label),
                    validator: f.required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final data = {for (final f in widget.fields) f.key: controllers[f.key]!.text.trim()};
                    if (existing == null) {
                      await widget.onCreate(data);
                    } else {
                      await widget.onUpdate(existing['id'] as String, data);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this?'),
        content: Text(widget.titleBuilder(row)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && widget.onDelete != null) {
      await widget.onDelete!(row['id'] as String);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Nothing here yet')))])
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final row = _filtered[i];
                            return ListTile(
                              title: Text(widget.titleBuilder(row)),
                              subtitle: widget.subtitleBuilder != null ? Text(widget.subtitleBuilder!(row) ?? '') : null,
                              onTap: widget.canEdit ? () => _openForm(existing: row) : null,
                              trailing: widget.canDelete
                                  ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(row))
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.canEdit ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)) : null,
    );
  }
}
