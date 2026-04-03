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

// ══════════════════════════════════════════════
//  SPLASH SCREEN
// ══════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;

  // Title : scale + fade
  late final Animation<double> _titleScale;
  late final Animation<double> _titleFade;

  // Subtitle + loader : fade + slide
  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;

  // Image : fade
  late final Animation<double> _imgFade;

  // Pulse continu sur le titre
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _titleScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ).drive(Tween<double>(begin: 0.5, end: 1.0));

    _titleFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _subFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _subSlide = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
    ).drive(Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero));

    _imgFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)
        .drive(Tween<double>(begin: 0.97, end: 1.03));

    _entryCtrl.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    const FlutterSecureStorage storage = FlutterSecureStorage();
    final String? token          = await storage.read(key: 'auth_token');
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

              // ── Image centrée ───────────────────────────
              FadeTransition(
                opacity: _imgFade,
                child: Image.asset(
                  'assets/avecfodn.jpeg',
                  height: 100,
                  errorBuilder: (ctx, err, st) => Text(
                    'Image non trouvée: $err',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Titre animé ─────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_entryCtrl, _pulseCtrl]),
                builder: (_, __) {
                  return FadeTransition(
                    opacity: _titleFade,
                    child: Transform.scale(
                      scale: _titleScale.value * _pulse.value,
                      child: Text(
                        'IvoireQuiz',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: const Color.fromARGB(255, 195, 33, 33),
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              color: Color(0x55000000),
                              offset: Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // ── Sous-titre slide-up ─────────────────────
              FadeTransition(
                opacity: _subFade,
                child: SlideTransition(
                  position: _subSlide,
                  child: Text(
                    'Connais-tu vraiment\nla Côte d\'Ivoire ?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Loader ──────────────────────────────────
              FadeTransition(
                opacity: _subFade,
                child: const _ThreeDots(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3 dots qui pulsent en décalé ────────────────
class _ThreeDots extends StatefulWidget {
  const _ThreeDots();

  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
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
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // chaque dot est décalé d'1/3 de cycle
            final double t = (_ctrl.value + i / 3) % 1.0;
            // monte et descend en douceur
            final double offset = -8 * (1 - (t * 2 - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
//  MAIN SCREEN  (structure identique)
// ══════════════════════════════════════════════
class MainScreen extends StatelessWidget {
  const MainScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: _AnimatedNavBar(
        selectedIndex: _selectedIndex(location),
        onTap: (int index) {
          switch (index) {
            case 0: context.go('/home');        return;
            case 1: context.go('/leaderboard'); return;
            case 2: context.go('/friends');     return;
            case 3: context.go('/profile');     return;
          }
        },
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/leaderboard')) return 1;
    if (location.startsWith('/friends'))     return 2;
    if (location.startsWith('/profile'))     return 3;
    return 0;
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

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined),        label: 'Accueil'),
    NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Classement'),
    NavigationDestination(icon: Icon(Icons.group_outlined),       label: 'Amis'),
    NavigationDestination(icon: Icon(Icons.person_outline),       label: 'Profil'),
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
            icon: _destinations[i].icon as Icon,
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

  final Icon icon;
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
          widget.icon.icon,
          color: widget.active ? AppColors.orange : null,
        ),
      ),
    );
  }
}