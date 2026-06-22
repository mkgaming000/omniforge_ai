// Audit Logs Page - view security event history
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/services/audit/audit_log_entity.dart';
import '../../../data/services/audit/audit_log_service.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  AuditLogService? _service;
  List<AuditLogEntry> _entries = [];
  AuditLogAction? _filter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _service = await AuditLogService.create();
    _load();
  }

  void _load() {
    setState(() => _isLoading = true);
    final result = _service!.getAll();
    result.fold(
      (_) => setState(() {
        _entries = [];
        _isLoading = false;
      }),
      (entries) {
        final filtered = _filter == null
            ? entries
            : entries.where((e) => e.action == _filter).toList();
        setState(() {
          _entries = filtered;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<AuditLogAction?>(
            value: _filter,
            decoration: const InputDecoration(
              labelText: 'Filter by action',
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              const DropdownMenuItem<AuditLogAction?>(
                value: null,
                child: Text('All actions'),
              ),
              ...AuditLogAction.values.map(
                (a) => DropdownMenuItem(
                  value: a,
                  child: Text(_actionLabel(a)),
                ),
              ),
            ],
            onChanged: (v) {
              setState(() => _filter = v);
              _load();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? const Center(
                      child: Text('No audit log entries'),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _AuditLogTile(entry: entry)
                            .animate()
                            .fadeIn(delay: (index * 30).ms);
                      },
                    ),
        ),
      ],
    );
  }

  String _actionLabel(AuditLogAction a) {
    return a.name
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => ' ${m[0]}',
        )
        .trim()
        .capitalize;
  }
}

extension on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry});
  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(entry.level);
    final icon = _iconFor(entry.action);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title:
            Text(entry.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${entry.action.name} • ${entry.timestamp.toString().substring(0, 19)}'
          '${entry.userId != null ? ' • ${entry.userId}' : ''}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            entry.level.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFor(AuditLogLevel level) {
    switch (level) {
      case AuditLogLevel.debug:
        return Colors.grey;
      case AuditLogLevel.info:
        return Colors.blue;
      case AuditLogLevel.warning:
        return Colors.orange;
      case AuditLogLevel.error:
        return Colors.red;
      case AuditLogLevel.critical:
        return Colors.purple;
    }
  }

  IconData _iconFor(AuditLogAction action) {
    switch (action) {
      case AuditLogAction.login:
      case AuditLogAction.logout:
        return Icons.login;
      case AuditLogAction.apiKeySaved:
      case AuditLogAction.apiKeyDeleted:
      case AuditLogAction.apiKeyUsed:
        return Icons.key;
      case AuditLogAction.conversationCreated:
      case AuditLogAction.conversationDeleted:
        return Icons.chat;
      case AuditLogAction.messageSent:
        return Icons.send;
      case AuditLogAction.imageGenerated:
        return Icons.image;
      case AuditLogAction.videoGenerated:
        return Icons.videocam;
      case AuditLogAction.musicGenerated:
        return Icons.music_note;
      case AuditLogAction.documentProcessed:
        return Icons.description;
      case AuditLogAction.mcpToolExecuted:
        return Icons.extension;
      case AuditLogAction.agentRun:
        return Icons.smart_toy;
      case AuditLogAction.fileUploaded:
      case AuditLogAction.fileDownloaded:
      case AuditLogAction.fileDeleted:
        return Icons.folder;
      case AuditLogAction.permissionGranted:
      case AuditLogAction.permissionRevoked:
        return Icons.security;
      case AuditLogAction.securityBlocked:
        return Icons.block;
      case AuditLogAction.configChanged:
        return Icons.settings;
      case AuditLogAction.dataExported:
      case AuditLogAction.dataDeleted:
        return Icons.delete;
    }
  }
}
