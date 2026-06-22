// App Router - GoRouter configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/pages/chat_page.dart';
import '../../features/chat/pages/conversation_list_page.dart';
import '../../features/image/pages/image_studio_page.dart';
import '../../features/image/pages/image_gallery_page.dart';
import '../../features/video/pages/video_studio_page.dart';
import '../../features/music/pages/music_studio_page.dart';
import '../../features/code/pages/code_editor_page.dart';
import '../../features/terminal/pages/terminal_page.dart';
import '../../features/runtime/pages/runtime_page.dart';
import '../../features/files/pages/file_explorer_page.dart';
import '../../features/mcp/pages/mcp_marketplace_page.dart';
import '../../features/agents/pages/agent_builder_page.dart';
import '../../features/orchestrator/pages/orchestrator_page.dart';
import '../../features/documents/pages/document_ai_page.dart';
import '../../features/voice/pages/voice_assistant_page.dart';
import '../../features/search/pages/research_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/settings/pages/api_keys_page.dart';
import '../../features/settings/pages/usage_page.dart';
import '../../features/settings/pages/security_page.dart';
import '../pages/splash_page.dart';
import '../pages/main_shell.dart';

class AppRouter {
  AppRouter._();

  // ignore: unused_field
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const ConversationListPage(),
          ),
          GoRoute(
            path: '/chat/:id',
            name: 'chat',
            builder: (context, state) => ChatPage(
              conversationId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/image',
            name: 'image-studio',
            builder: (context, state) => const ImageStudioPage(),
          ),
          GoRoute(
            path: '/image/gallery',
            name: 'image-gallery',
            builder: (context, state) => const ImageGalleryPage(),
          ),
          GoRoute(
            path: '/video',
            name: 'video-studio',
            builder: (context, state) => const VideoStudioPage(),
          ),
          GoRoute(
            path: '/music',
            name: 'music-studio',
            builder: (context, state) => const MusicStudioPage(),
          ),
          GoRoute(
            path: '/code',
            name: 'code-editor',
            builder: (context, state) => const CodeEditorPage(),
          ),
          GoRoute(
            path: '/terminal',
            name: 'terminal',
            builder: (context, state) => const TerminalPage(),
          ),
          GoRoute(
            path: '/runtime',
            name: 'runtime',
            builder: (context, state) => const RuntimePage(),
          ),
          GoRoute(
            path: '/files',
            name: 'files',
            builder: (context, state) => const FileExplorerPage(),
          ),
          GoRoute(
            path: '/mcp',
            name: 'mcp',
            builder: (context, state) => const McpMarketplacePage(),
          ),
          GoRoute(
            path: '/agents',
            name: 'agents',
            builder: (context, state) => const AgentBuilderPage(),
          ),
          GoRoute(
            path: '/orchestrator',
            name: 'orchestrator',
            builder: (context, state) => const OrchestratorPage(),
          ),
          GoRoute(
            path: '/documents',
            name: 'documents',
            builder: (context, state) => const DocumentAIPage(),
          ),
          GoRoute(
            path: '/voice',
            name: 'voice',
            builder: (context, state) => const VoiceAssistantPage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const ResearchPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/api-keys',
        name: 'api-keys',
        builder: (context, state) => const ApiKeysPage(),
      ),
      GoRoute(
        path: '/settings/usage',
        name: 'usage',
        builder: (context, state) => const UsagePage(),
      ),
      GoRoute(
        path: '/settings/security',
        name: 'security',
        builder: (context, state) => const SecurityPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
