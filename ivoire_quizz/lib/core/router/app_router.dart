import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
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
          final int? categoryId = categoryIdParam == null || categoryIdParam == 'null'
              ? null
              : int.tryParse(categoryIdParam);
          final String mode = state.pathParameters['mode'] ?? '';
          return QuizScreen(categoryId: categoryId, mode: mode);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, dynamic> resultData =
              (state.extra as Map<String, dynamic>?) ?? <String, dynamic>{};
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final String? token = await _storage.read(key: 'auth_token');

    if (!mounted) {
      return;
    }

    if (token != null && token.isNotEmpty) {
      context.go('/home');
      return;
    }

    final String? onboardingDone = await _storage.read(key: 'onboarding_done');

    if (!mounted) {
      return;
    }

    if (onboardingDone == null) {
      context.go('/onboarding');
      return;
    }

    context.go('/auth');
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
            case 1:
              context.go('/leaderboard');
            case 2:
              context.go('/friends');
            case 3:
              context.go('/profile');
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

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Auth')));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home')));
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Leaderboard')));
  }
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Friends')));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Profile')));
  }
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({required this.categoryId, required this.mode, super.key});

  final int? categoryId;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Center(
        child: Text('categoryId: $categoryId | mode: $mode'),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.resultData, super.key});

  final Map<String, dynamic> resultData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Center(
        child: Text('Résultat: $resultData'),
      ),
    );
  }
}
