import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/chat_service.dart';

import '../../features/agent/agent_screen.dart';
import '../../features/ai_setup/ai_setup_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/conversation_history_screen.dart';
import '../../features/document_gen/document_gen_screen.dart';
import '../../features/document_gen/generated_files_screen.dart';
import '../../features/general_chat/general_chat_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/image_gen/image_gen_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/quick_guide_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/programmer/programmer_screen.dart';
import '../../features/roles/commander/commander_screen.dart' show AgentDrivenEnvironmentScreen;
import '../../features/roles/roles_browser_screen.dart';
import '../../features/settings/models_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/voice_gen/voice_gen_screen.dart';
import '../config/api_keys.dart';
import '../providers/app_providers.dart';
import '../roles/role.dart';

GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onboardingDone = ref.read(onboardingCompleteProvider);
      final aiSetupDone = ref.read(aiSetupCompleteProvider);
      final location = state.uri.toString();

      if (!onboardingDone) {
        if (location == '/welcome') return null;
        return '/welcome';
      }

      if (!aiSetupDone && !ApiKeys.hasAnyCloudKey) {
        if (location == '/ai-setup') return null;
        return '/ai-setup';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', name: 'home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/general-chat', name: 'generalChat', builder: (_, _) => const GeneralChatScreen()),
      GoRoute(path: '/welcome', name: 'welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/quick-guide', name: 'quickGuide', builder: (_, _) => const QuickGuideScreen()),
      GoRoute(path: '/ai-setup', name: 'aiSetup', builder: (_, _) => const AISetupScreen()),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is (Role, Conversation?)) {
            return ChatScreen(role: extra.$1, initialConversation: extra.$2);
          }
          if (extra is Role) {
            return ChatScreen(role: extra);
          }
          return const SizedBox.shrink();
        },
      ),
      GoRoute(
        path: '/chat/history',
        name: 'chatHistory',
        builder: (_, state) {
          final extra = state.extra;
          return ConversationHistoryScreen(
            roleId: extra is String ? extra : '',
          );
        },
      ),
      GoRoute(
        path: '/agent-driven-environment',
        name: 'agentDrivenEnvironment',
        builder: (_, _) => const AgentDrivenEnvironmentScreen(),
      ),
      GoRoute(
        path: '/programmer',
        name: 'programmer',
        builder: (_, _) => const ProgrammerScreen(),
      ),
      GoRoute(
        path: '/image-gen',
        name: 'imageGen',
        builder: (_, _) => const ImageGenScreen(),
      ),
      GoRoute(
        path: '/voice-gen',
        name: 'voiceGen',
        builder: (_, _) => const VoiceGenScreen(),
      ),
      GoRoute(
        path: '/document-gen',
        name: 'documentGen',
        builder: (_, _) => const DocumentGenScreen(),
      ),
      GoRoute(
        path: '/documents',
        name: 'generatedFiles',
        builder: (_, _) => const GeneratedFilesScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/models',
        name: 'models',
        builder: (_, _) => const ModelsScreen(),
      ),
      GoRoute(
        path: '/memory',
        name: 'memory',
        builder: (_, _) => const MemoryScreen(),
      ),
      GoRoute(
        path: '/agent',
        name: 'agent',
        builder: (_, state) => AgentScreen(role: state.extra as Role),
      ),
      GoRoute(
        path: '/roles',
        name: 'roles',
        builder: (_, _) => const RolesBrowserScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (_, _) => const AboutScreen(),
      ),
    ],
  );
}
