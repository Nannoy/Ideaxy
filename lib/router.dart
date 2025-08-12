import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/sign_in_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/generator_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/onboarding/select_niche_screen.dart';
import 'screens/onboarding/select_platforms_screen.dart';
import 'services/profile_service.dart';
import 'widgets/full_screen_loader.dart';
import 'screens/content_details_screen.dart';
import 'models/content_models.dart';

final supabase = Supabase.instance.client;

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    _sub = supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter() {
  final authNotifier = AuthStateNotifier();
  return GoRouter(
    initialLocation: '/generate',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) return '/route-after-auth';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const SignInScreen()),
      GoRoute(
        path: '/route-after-auth',
        builder: (context, state) => const _RouteAfterAuth(),
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(path: '/generate', builder: (context, state) => const GeneratorScreen()),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
      GoRoute(
        path: '/onboarding/niche',
        builder: (context, state) => SelectNicheScreen(
          isEdit: state.uri.queryParameters['edit'] == '1',
        ),
      ),
      GoRoute(
        path: '/onboarding/platforms',
        builder: (context, state) => SelectPlatformsScreen(
          isEdit: state.uri.queryParameters['edit'] == '1',
        ),
      ),
      GoRoute(
        path: '/content/details',
        builder: (context, state) {
          final item = state.extra is ContentItem ? state.extra as ContentItem : null;
          if (item == null) return const Scaffold(body: Center(child: Text('No item')));
          return ContentDetailsScreen(item: item);
        },
      ),
    ],
  );
}

class _RouteAfterAuth extends StatefulWidget {
  const _RouteAfterAuth();
  @override
  State<_RouteAfterAuth> createState() => _RouteAfterAuthState();
}

class _RouteAfterAuthState extends State<_RouteAfterAuth> {
  final _service = ProfileService();
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final user = supabase.auth.currentUser;
      if (!mounted) return;
      if (user == null) {
        context.go('/auth');
        return;
      }
      final profile = await _service.fetchProfile(user.id);
      if (!mounted) return;
      final niches = (profile?['niches'] as List?)?.cast<dynamic>() ?? const [];
      final platforms = (profile?['platforms'] as List?)?.cast<dynamic>() ?? const [];
      if (niches.isEmpty) {
        context.go('/onboarding/niche');
      } else if (platforms.isEmpty) {
        context.go('/onboarding/platforms');
      } else {
        context.go('/generate');
      }
    });
  }

  @override
  Widget build(BuildContext context) => const FullScreenLoader();
}

