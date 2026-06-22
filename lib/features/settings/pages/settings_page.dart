// Settings Page - main settings screen
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/theme_state.dart';
import '../../../injection/injection.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'AI Providers',
          children: [
            _SettingTile(
              icon: Icons.key,
              title: 'API Keys',
              subtitle: 'Manage provider credentials',
              onTap: () => context.push('/settings/api-keys'),
            ),
            _SettingTile(
              icon: Icons.tune,
              title: 'Model Defaults',
              subtitle: 'Default models per task',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.health_and_safety,
              title: 'Provider Health',
              subtitle: 'Monitor provider availability',
              onTap: () {},
            ),
          ],
        ),
        _Section(
          title: 'Usage & Billing',
          children: [
            _SettingTile(
              icon: Icons.analytics,
              title: 'Usage Statistics',
              subtitle: 'Tokens, costs, requests',
              onTap: () => context.push('/settings/usage'),
            ),
            _SettingTile(
              icon: Icons.attach_money,
              title: 'Budget Limits',
              subtitle: 'Set spending caps',
              onTap: () {},
            ),
          ],
        ),
        _Section(
          title: 'Appearance',
          children: [
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return _SettingTile(
                  icon: state.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'Theme',
                  subtitle: state.themeMode.name,
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_brightness),
                      ),
                    ],
                    selected: {state.themeMode},
                    onSelectionChanged: (modes) {
                      final mode = modes.first;
                      if (mode == ThemeMode.light) {
                        getIt<ThemeCubit>().setLightMode();
                      } else if (mode == ThemeMode.dark) {
                        getIt<ThemeCubit>().setDarkMode();
                      } else {
                        getIt<ThemeCubit>().setSystemMode();
                      }
                    },
                  ),
                );
              },
            ),
            _SettingTile(
              icon: Icons.palette,
              title: 'Accent Color',
              subtitle: 'Violet + Cyan (default)',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.font_download,
              title: 'Font',
              subtitle: 'Inter (default)',
              onTap: () {},
            ),
          ],
        ),
        _Section(
          title: 'Security & Privacy',
          children: [
            _SettingTile(
              icon: Icons.lock,
              title: 'App Lock',
              subtitle: 'Biometric authentication',
              onTap: () => context.push('/settings/security'),
            ),
            _SettingTile(
              icon: Icons.history,
              title: 'Audit Logs',
              subtitle: 'View activity history',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.delete_forever,
              title: 'Clear All Data',
              subtitle: 'Delete all conversations and cache',
              onTap: () => _showClearDataDialog(context),
            ),
          ],
        ),
        _Section(
          title: 'About',
          children: [
            _SettingTile(
              icon: Icons.info,
              title: 'About OmniForge AI',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.description,
              title: 'Terms of Service',
              subtitle: 'Legal terms',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete all conversations, generated content, '
          'and cached data. API keys will be preserved. This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(child: Column(children: children)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
