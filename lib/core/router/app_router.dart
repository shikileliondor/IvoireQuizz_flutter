import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/home/screens/all_categories_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/onboarding/screens/ivoire_quiz_splash_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'categories',
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
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/leaderboard',
                builder: (BuildContext context, GoRouterState state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/friends',
                builder: (BuildContext context, GoRouterState state) => const FriendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
              ),
            ],
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

// ══════════════════════════════════════════════
//  SPLASH SCREEN
// ══════════════════════════════════════════════
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> _navigateAfterSplash(BuildContext context) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'auth_token');
    final String? onboardingDone = await storage.read(key: 'onboarding_done');

    if (!context.mounted) return;

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
    return IvoireQuizSplashScreen(
      autoNavigate: true,
      onAnimationComplete: () => _navigateAfterSplash(context),
    );
  }
}

// ══════════════════════════════════════════════
//  MAIN SCREEN  (structure identique)
// ══════════════════════════════════════════════
class MainScreen extends StatelessWidget {
  const MainScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _AnimatedNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTap: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

// ── NavigationBar avec bounce sur l'icône active ─
class _AnimatedNavBar extends StatelessWidget {
  const _AnimatedNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const List<({IconData icon, String label})> _destinations = [
    (icon: Icons.home_outlined, label: 'Accueil'),
    (icon: Icons.emoji_events_outlined, label: 'Classement'),
    (icon: Icons.group_outlined, label: 'Amis'),
    (icon: Icons.person_outline, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      // Garde le style Material 3 existant, juste une couleur d'indication
      indicatorColor: AppColors.orange.withOpacity(0.18),
      destinations: List.generate(_destinations.length, (i) {
        final bool active = i == selectedIndex;
        return NavigationDestination(
          icon: _BounceIcon(
            icon: _destinations[i].icon,
            active: active,
          ),
          label: _destinations[i].label,
        );
      }),
    );
  }
}

// ── Icône qui rebondit à la sélection ───────────
class _BounceIcon extends StatefulWidget {
  const _BounceIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  State<_BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<_BounceIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween<double>(begin: 1.0, end: 1.3));
  }

  @override
  void didUpdateWidget(_BounceIcon old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: widget.active ? _scale.value : 1.0,
        child: Icon(
          widget.icon,
          color: widget.active ? AppColors.orange : null,
        ),
      ),
    );
  }
}