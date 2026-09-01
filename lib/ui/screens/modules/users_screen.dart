import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/repositories/misc_repositories.dart';
import '../../../core/services/auth_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _repo = UsersRepository();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await _repo.getAll();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final user = existing != null ? AppUser.fromRow(existing) : null;
    final usernameCtrl = TextEditingController(text: existing?['username'] ?? '');
    final fullNameCtrl = TextEditingController(text: existing?['full_name'] ?? '');
    final passwordCtrl = TextEditingController();
    String role = existing?['role'] as String? ?? 'cashier';
    bool active = (existing?['is_active'] as int? ?? 1) == 1;
    bool handPick = user?.customPermissions != null;
    final Set<String> picked = {...(user?.permissions ?? RoleDefaults.sets[role]!)};
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(existing == null ? 'Add User' : 'Edit User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameCtrl,
                    enabled: existing == null,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  TextFormField(controller: passwordCtrl, obscureText: true,
                      decoration: InputDecoration(labelText: existing == null ? 'Password' : 'New Password (leave blank to keep)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setSheetState(() {
                      role = v!;
                      if (!handPick) {
                        picked
                          ..clear()
                          ..addAll(RoleDefaults.sets[role]!);
                      }
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setSheetState(() => active = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hand-pick this user\'s access'),
                    subtitle: const Text('Overrides the role\'s default pages'),
                    value: handPick,
                    onChanged: (v) => setSheetState(() => handPick = v),
                  ),
                  if (handPick)
                    Wrap(
                      spacing: 6,
                      children: Perm.all.map((p) {
                        final selected = picked.contains(p);
                        return FilterChip(
                          label: Text(Perm.labels[p]!, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (v) => setSheetState(() => v ? picked.add(p) : picked.remove(p)),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (existing == null) {
                        if (passwordCtrl.text.length < 4) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password must be at least 4 characters')));
                          return;
                        }
                        await _repo.create(
                          username: usernameCtrl.text,
                          fullName: fullNameCtrl.text,
                          password: passwordCtrl.text,
                          role: role,
                          permissions: handPick ? picked.toList() : null,
                        );
                      } else {
                        await _repo.update(
                          existing['id'] as String,
                          fullName: fullNameCtrl.text,
                          role: role,
                          isActive: active,
                          newPassword: passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
                          permissions: handPick ? picked.toList() : null,
                          useRoleDefaults: !handPick,
                        );
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (ctx, i) {
                  final u = _users[i];
                  final active = (u['is_active'] as int) == 1;
                  return ListTile(
                    title: Text(u['full_name'] as String),
                    subtitle: Text('${u['username']} - ${u['role']}${active ? '' : ' - inactive'}'),
                    onTap: () => _openForm(existing: u),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}
