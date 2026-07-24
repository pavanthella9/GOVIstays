import 'package:flutter/material.dart';

import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _working = false;

  Future<void> _run(Future<BackupResult> Function() action) async {
    setState(() => _working = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _working = false);
    if (result.cancelled) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? Colors.green : Colors.red,
          size: 42,
        ),
        title: Text(result.success ? 'Completed' : 'Failed'),
        content: SelectableText(result.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore cloud data?'),
        content: const Text(
          'This will replace all bookings currently stored in Firestore. '
          'All connected devices will receive the restored data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _run(BackupService.restoreBackup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: const Icon(Icons.save_alt, size: 38),
                  title: const Text(
                    'Create JSON Backup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Export the latest Firestore bookings to a file.',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _working
                      ? null
                      : () => _run(BackupService.createBackup),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: const Icon(Icons.restore, size: 38),
                  title: const Text(
                    'Restore JSON Backup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Replace Firestore data after validating a backup file.',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _working ? null : _confirmRestore,
                ),
              ),
            ],
          ),
          if (_working)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
