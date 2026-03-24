import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/home/screens/all_categories_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/result/screens/result_screen.dart';
import '../theme/app_theme.dart';

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (BuildContext context, GoRouterState state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainScreen(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/home/categories',
            builder: (BuildContext context, GoRouterState state) {
              final dynamic extra = state.extra;
              final List<Map<String, dynamic>> categories;
              final String selectedMode;

              if (extra is Map) {
                final dynamic rawCategories = extra['categories'];
                categories = rawCategories is List
                    ? rawCategories
                        .whereType<Map>()
                        .map((dynamic e) => Map<String, dynamic>.from(e as Map))
                        .toList()
                    : <Map<String, dynamic>>[];
                final dynamic rawMode = extra['selected_mode'];
                selectedMode = rawMode is String ? rawMode : 'category';
              } else {
                categories = <Map<String, dynamic>>[];
                selectedMode = 'category';
              }

              return AllCategoriesScreen(
                categories: categories,
                selectedMode: selectedMode,
              );
            },
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (BuildContext context, GoRouterState state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/friends',
            builder: (BuildContext context, GoRouterState state) => const FriendsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/quiz/:categoryId/:mode',
        builder: (BuildContext context, GoRouterState state) {
          final String? categoryIdParam = state.pathParameters['categoryId'];
          final int? categoryId = categoryIdParam == 'null' || categoryIdParam == null
              ? null
              : int.tryParse(categoryIdParam);
          final String mode = state.pathParameters['mode'] ?? '';
          return QuizScreen(categoryId: categoryId, mode: mode);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (BuildContext context, GoRouterState state) {
          final dynamic extra = state.extra;
          final Map<String, dynamic> resultData;

          if (extra is Map<String, dynamic>) {
            resultData = extra;
          } else if (extra is Map) {
            resultData = Map<String, dynamic>.from(extra);
          } else if (extra is List && extra.isNotEmpty && extra.first is Map) {
            resultData = Map<String, dynamic>.from(extra.first as Map);
          } else {
            resultData = <String, dynamic>{};
          }

          return ResultScreen(resultData: resultData);
        },
      ),
    ],
  );
});

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    const FlutterSecureStorage storage = FlutterSecureStorage();

    // TEMP: décommenter pour reset les tests
    // await storage.deleteAll();

    final String? token = await storage.read(key: 'auth_token');
    final String? onboardingDone = await storage.read(key: 'onboarding_done');

    if (token != null) {
      context.go('/home');
    } else if (onboardingDone == null) {
      context.go('/onboarding');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              Text(
                'IvoireQuiz',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connais-tu vraiment\nla Côte d\'Ivoire ?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const CircularProgressIndicator(
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              context.go('/home');
              return;
            case 1:
              context.go('/leaderboard');
              return;
            case 2:
              context.go('/friends');
              return;
            case 3:
              context.go('/profile');
              return;
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Classement'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Amis'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/leaderboard')) {
      return 1;
    }
    if (location.startsWith('/friends')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }
}
