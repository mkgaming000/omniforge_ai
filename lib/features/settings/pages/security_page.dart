// Security Page - biometric lock, audit logs, permissions
import 'package:flutter/material.dart';

import '../../../core/security/biometric_service.dart';
import '../../../injection/injection.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _biolockEnabled = false;
  bool _auditLogsEnabled = true;
  bool _pinEnabled = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Biometric Lock'),
                subtitle: const Text('Require fingerprint/face to unlock'),
                value: _biolockEnabled,
                onChanged: (v) async {
                  if (v) {
                    final ok = await getIt<BiometricService>().authenticate(
                      reason: 'Enable biometric lock',
                    );
                    if (!ok) return;
                  }
                  setState(() => _biolockEnabled = v);
                },
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: const Text('PIN Lock'),
                subtitle: const Text('Backup PIN if biometric fails'),
                value: _pinEnabled,
                onChanged: (v) => setState(() => _pinEnabled = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.history),
                title: const Text('Audit Logs'),
                subtitle: const Text('Track all API calls and access'),
                value: _auditLogsEnabled,
                onChanged: (v) => setState(() => _auditLogsEnabled = v),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Audit Logs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Permissions'),
                subtitle: const Text('Camera, microphone, storage'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('RBAC Roles'),
                subtitle: const Text('User roles and access control'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text('OAuth Tokens'),
                subtitle: const Text('Manage authorized sessions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Revoke All Sessions'),
                subtitle: const Text('Sign out everywhere'),
                onTap: () => _showRevokeDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRevokeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke all sessions?'),
        content: const Text(
          'This will sign you out of OmniForge AI on all devices and revoke all OAuth tokens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
