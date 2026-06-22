// RBAC Page - Role-Based Access Control management
import 'package:flutter/material.dart';

class RbacPage extends StatelessWidget {
  const RbacPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = [
      ('Owner', 'Full access to everything', Colors.purple, true),
      ('Admin', 'Manage users, keys, settings', Colors.red, true),
      ('Editor', 'Create, edit, delete content', Colors.blue, true),
      ('Contributor', 'Create and edit content', Colors.green, false),
      ('Viewer', 'Read-only access', Colors.grey, false),
      ('Guest', 'Limited public access', Colors.orange, false),
    ];

    final permissions = [
      ('chat.send', 'Send chat messages'),
      ('image.generate', 'Generate images'),
      ('video.generate', 'Generate videos'),
      ('music.generate', 'Generate music'),
      ('files.upload', 'Upload files'),
      ('files.delete', 'Delete files'),
      ('apikeys.manage', 'Manage API keys'),
      ('agents.create', 'Create AI agents'),
      ('mcp.install', 'Install MCP tools'),
      ('settings.modify', 'Modify app settings'),
      ('users.manage', 'Manage users and roles'),
      ('audit.view', 'View audit logs'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Roles', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...roles.map(
          (r) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: r.$3.withOpacity(0.15),
                child: Text(
                  r.$1[0],
                  style: TextStyle(color: r.$3, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Text(r.$1),
                  const SizedBox(width: 8),
                  if (r.$4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: r.$3.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          fontSize: 10,
                          color: r.$3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(r.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Permissions Matrix',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: permissions
                .map(
                  (p) => CheckboxListTile(
                    value:
                        roles.first.$4 && p.$1 != 'users.manage' ? true : false,
                    title: Text(
                      p.$1,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(p.$2),
                    onChanged: (_) {},
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
