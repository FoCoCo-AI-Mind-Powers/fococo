import 'package:flutter/material.dart';
import '/ai_integration/services/mind_coach_migration_service.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Helper widget/utility for running MindCoach session migrations
/// Can be called from admin settings or as a one-time migration
class MindCoachMigrationHelper {
  /// Run migration for current user
  static Future<MigrationResult> migrateCurrentUser(BuildContext context) async {
    final userId = currentUserUid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    return await MindCoachMigrationService.instance.migrateUserSessions(userId);
  }

  /// Run migration for all users (admin only)
  /// Shows progress dialog
  static Future<MigrationResult> migrateAllUsersWithProgress(
    BuildContext context, {
    Function(int current, int total)? onProgress,
  }) async {
    return await showDialog<MigrationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MigrationProgressDialog(
        onProgress: onProgress,
      ),
    ) ?? MigrationResult(successCount: 0, failureCount: 0, failures: []);
  }
}

/// Progress dialog for migration
class _MigrationProgressDialog extends StatefulWidget {
  final Function(int current, int total)? onProgress;

  const _MigrationProgressDialog({this.onProgress});

  @override
  State<_MigrationProgressDialog> createState() => _MigrationProgressDialogState();
}

class _MigrationProgressDialogState extends State<_MigrationProgressDialog> {
  int _current = 0;
  int _total = 0;
  bool _isComplete = false;
  MigrationResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runMigration();
  }

  Future<void> _runMigration() async {
    try {
      final result = await MindCoachMigrationService.instance.migrateAllSessions(
        batchSize: 50,
        onProgress: (current, total) {
          setState(() {
            _current = current;
            _total = total;
          });
          widget.onProgress?.call(current, total);
        },
      );

      setState(() {
        _result = result;
        _isComplete = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Migrating Sessions'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isComplete) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Migrating sessions: $_current / $_total'),
          ] else if (_error != null) ...[
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          ] else if (_result != null) ...[
            Icon(
              _result!.isSuccess ? Icons.check_circle : Icons.warning,
              color: _result!.isSuccess ? Colors.green : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Migration Complete'),
            const SizedBox(height: 8),
            Text('Success: ${_result!.successCount}'),
            Text('Failures: ${_result!.failureCount}'),
            if (_result!.failures.isNotEmpty)
              Text(
                'Failed IDs: ${_result!.failures.take(5).join(", ")}${_result!.failures.length > 5 ? "..." : ""}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ],
      ),
      actions: [
        if (_isComplete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_result),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

/// Command-line style migration utility
/// Can be called from Flutter CLI or admin panel
class MindCoachMigrationCommand {
  /// Run migration and print results
  static Future<void> runMigration({
    String? userId,
    bool allUsers = false,
  }) async {
    print('🔄 Starting MindCoach session migration...');

    final migrationService = MindCoachMigrationService.instance;
    MigrationResult result;

    if (allUsers) {
      print('📊 Migrating all users...');
      result = await migrationService.migrateAllSessions(
        batchSize: 50,
        onProgress: (current, total) {
          print('Progress: $current / $total');
        },
      );
    } else if (userId != null) {
      print('👤 Migrating user: $userId');
      result = await migrationService.migrateUserSessions(userId);
    } else {
      throw Exception('Must provide userId or set allUsers=true');
    }

    print('\n✅ Migration Complete!');
    print('Success: ${result.successCount}');
    print('Failures: ${result.failureCount}');
    if (result.failures.isNotEmpty) {
      print('Failed session IDs:');
      for (final failure in result.failures.take(10)) {
        print('  - $failure');
      }
      if (result.failures.length > 10) {
        print('  ... and ${result.failures.length - 10} more');
      }
    }
    if (result.error != null) {
      print('Error: ${result.error}');
    }
  }
}
