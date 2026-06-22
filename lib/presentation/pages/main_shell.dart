// Main Shell - bottom navigation + drawer for all features
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);

    return Scaffold(
      body: child,
      drawer: const _AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _titleForLocation(location),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.push('/settings');
                  break;
                case 'usage':
                  context.push('/settings/usage');
                  break;
                case 'security':
                  context.push('/settings/security');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'usage',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Usage & Costs'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'security',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Security'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_locationForIndex(i)),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Image',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Video',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Music',
          ),
          NavigationDestination(
            icon: Icon(Icons.code),
            selectedIcon: Icon(Icons.code),
            label: 'Code',
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/chat') || location == '/') return 0;
    if (location.startsWith('/image')) return 1;
    if (location.startsWith('/video')) return 2;
    if (location.startsWith('/music')) return 3;
    if (location.startsWith('/code')) return 4;
    return 0;
  }

  String _locationForIndex(int i) {
    switch (i) {
      case 0:
        return '/';
      case 1:
        return '/image';
      case 2:
        return '/video';
      case 3:
        return '/music';
      case 4:
        return '/code';
      default:
        return '/';
    }
  }

  String _titleForLocation(String location) {
    if (location.startsWith('/chat')) return 'Chat AI';
    if (location.startsWith('/image')) return 'Image Studio';
    if (location.startsWith('/video')) return 'Video Studio';
    if (location.startsWith('/music')) return 'Music Studio';
    if (location.startsWith('/code')) return 'Code AI';
    if (location.startsWith('/terminal')) return 'Terminal';
    if (location.startsWith('/runtime')) return 'Runtime';
    if (location.startsWith('/files')) return 'Files';
    if (location.startsWith('/mcp')) return 'MCP Marketplace';
    if (location.startsWith('/agents')) return 'AI Agents';
    if (location.startsWith('/documents')) return 'Document AI';
    if (location.startsWith('/voice')) return 'Voice Assistant';
    if (location.startsWith('/search')) return 'Research';
    return AppConstants.appName;
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
                const Spacer(),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  AppConstants.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          _DrawerItem(
            icon: Icons.chat_bubble_outline,
            title: 'Chat AI',
            subtitle: 'Multi-model conversations',
            onTap: () => _go(context, '/'),
          ),
          _DrawerItem(
            icon: Icons.image_outlined,
            title: 'Image Studio',
            subtitle: 'Generate, edit, upscale',
            onTap: () => _go(context, '/image'),
          ),
          _DrawerItem(
            icon: Icons.videocam_outlined,
            title: 'Video Studio',
            subtitle: 'Text-to-video, image-to-video',
            onTap: () => _go(context, '/video'),
          ),
          _DrawerItem(
            icon: Icons.music_note_outlined,
            title: 'Music Studio',
            subtitle: 'Suno, Udio, MusicGen',
            onTap: () => _go(context, '/music'),
          ),
          _DrawerItem(
            icon: Icons.code,
            title: 'Code AI',
            subtitle: 'IDE with AI assistant',
            onTap: () => _go(context, '/code'),
          ),
          _DrawerItem(
            icon: Icons.terminal,
            title: 'Terminal',
            subtitle: 'Termux-style shell',
            onTap: () => _go(context, '/terminal'),
          ),
          _DrawerItem(
            icon: Icons.play_circle_outline,
            title: 'Runtime',
            subtitle: 'Run code in 15+ languages',
            onTap: () => _go(context, '/runtime'),
          ),
          _DrawerItem(
            icon: Icons.folder_outlined,
            title: 'Files',
            subtitle: 'Cloud sync, GitHub, Drive',
            onTap: () => _go(context, '/files'),
          ),
          _DrawerItem(
            icon: Icons.extension,
            title: 'MCP Marketplace',
            subtitle: 'Tool registry & discovery',
            onTap: () => _go(context, '/mcp'),
          ),
          _DrawerItem(
            icon: Icons.smart_toy_outlined,
            title: 'AI Agents',
            subtitle: 'Multi-agent teams, RAG',
            onTap: () => _go(context, '/agents'),
          ),
          _DrawerItem(
            icon: Icons.hub,
            title: 'Master Orchestrator',
            subtitle: '15-agent pipeline · Live AI thinking',
            onTap: () => _go(context, '/orchestrator'),
          ),
          _DrawerItem(
            icon: Icons.description_outlined,
            title: 'Document AI',
            subtitle: 'PDF, Word, Excel, PPT',
            onTap: () => _go(context, '/documents'),
          ),
          _DrawerItem(
            icon: Icons.mic_outlined,
            title: 'Voice Assistant',
            subtitle: 'Live voice chat, translation',
            onTap: () => _go(context, '/voice'),
          ),
          _DrawerItem(
            icon: Icons.search,
            title: 'Research',
            subtitle: 'Deep research, citations',
            onTap: () => _go(context, '/search'),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'API keys, theme, security',
            onTap: () => _go(context, '/settings'),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.push(route);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}
