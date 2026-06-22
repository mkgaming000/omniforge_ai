// File Explorer Page - manage local files, cloud sync
import 'package:flutter/material.dart';

class FileExplorerPage extends StatelessWidget {
  const FileExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCloudSyncBar(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _FolderCard(name: 'Downloads', icon: Icons.download, count: 24),
              _FolderCard(name: 'Documents', icon: Icons.folder, count: 12),
              _FolderCard(name: 'Images', icon: Icons.image, count: 156),
              _FolderCard(name: 'Videos', icon: Icons.video_library, count: 8),
              _FolderCard(name: 'Music', icon: Icons.music_note, count: 42),
              _FolderCard(name: 'Projects', icon: Icons.code, count: 5),
              _FolderCard(name: 'Templates', icon: Icons.dashboard, count: 18),
              _FolderCard(name: 'Archives', icon: Icons.archive, count: 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudSyncBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Row(
        children: [
          Icon(Icons.cloud, color: Color(0xFF4285F4)),
          SizedBox(width: 8),
          Text('Cloud Sync'),
          SizedBox(width: 16),
          _CloudChip(name: 'Google Drive', icon: Icons.cloud_upload),
          _CloudChip(name: 'Dropbox', icon: Icons.cloud_upload),
          _CloudChip(name: 'GitHub', icon: Icons.code),
          _CloudChip(name: 'GitLab', icon: Icons.code),
          _CloudChip(name: 'OneDrive', icon: Icons.cloud_upload),
        ],
      ),
    );
  }
}

class _CloudChip extends StatelessWidget {
  const _CloudChip({required this.name, required this.icon});
  final String name;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14),
        label: Text(name),
        onPressed: () {},
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.icon,
    required this.count,
  });
  final String name;
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(name),
        subtitle: Text('$count items'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
