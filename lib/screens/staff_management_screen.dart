import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import 'add_staff_screen.dart';
import 'edit_staff_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (!UserService.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin access is required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStaffScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Search staff by name or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: UserService.watchStaff(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Unable to load staff: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query = _query.toLowerCase();
                final staff = snapshot.data!.where((user) {
                  if (query.isEmpty) return true;
                  return user.name.toLowerCase().contains(query) ||
                      user.email.toLowerCase().contains(query) ||
                      user.phone.toLowerCase().contains(query);
                }).toList();

                if (staff.isEmpty) {
                  return const Center(
                    child: Text('No staff accounts found.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _staffCard(staff[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffCard(AppUser staff) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              child: Text(
                staff.name.trim().isEmpty
                    ? 'S'
                    : staff.name.trim()[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(staff.email),
                  if (staff.phone.isNotEmpty) Text(staff.phone),
                  const SizedBox(height: 6),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      staff.active ? Icons.check_circle : Icons.block,
                      size: 17,
                    ),
                    label: Text(staff.active ? 'Active' : 'Inactive'),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditStaffScreen(staff: staff),
                    ),
                  );
                } else if (value == 'toggle') {
                  await _toggleStatus(staff);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(staff.active ? Icons.block : Icons.check),
                    title: Text(staff.active ? 'Disable' : 'Enable'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(AppUser staff) async {
    final action = staff.active ? 'disable' : 'enable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${staff.active ? 'Disable' : 'Enable'} staff?'),
        content: Text(
          'Are you sure you want to $action ${staff.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(staff.active ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await UserService.setStaffActive(uid: staff.uid, active: !staff.active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${staff.name} is now ${staff.active ? 'inactive' : 'active'}.',
          ),
        ),
      );
    } on UserServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    }
  }
}
