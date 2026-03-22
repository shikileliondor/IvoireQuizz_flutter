import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedMode = 'category';
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  Map<String, dynamic>? _lastSession;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _loadingCategories = true;
  bool _loadingSession = true;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // ÉTAPE 1 : Afficher le cache immédiatement
    await _loadFromCache();

    // ÉTAPE 2 : Charger depuis l'API en arrière-plan
    await _loadFromApi();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('home_cache');
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        setState(() {
          _categories = <Map<String, dynamic>>[];
          _lastSession = null;
          _user = null;

          final rawCategories = data['categories'];
          if (rawCategories is List) {
            _categories = rawCategories
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }

          final rawSession = data['last_session'];
          if (rawSession != null && rawSession is Map) {
            _lastSession = Map<String, dynamic>.from(rawSession);
          }

          final rawUser = data['user'];
          if (rawUser != null && rawUser is Map) {
            _user = Map<String, dynamic>.from(rawUser);
          }

          _loadingCategories = false;
          _loadingSession = false;
          _isLoading = _user == null;
        });
      }
    } catch (e) {
      debugPrint('CACHE ERROR: $e');
    }
  }

  Future<void> _loadFromApi() async {
    try {
      final token = await const FlutterSecureStorage()
          .read(key: 'auth_token');

      if (token == null) {
        if (mounted) context.go('/auth');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: 'http://10.0.2.2:8000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final results = await Future.wait([
        dio.get('/auth/me'),
        dio.get('/categories'),
        dio.get('/sessions'),
      ]);

      final userData = results[0].data['data'];
      final categoriesData = results[1].data['data'];
      final sessionsData = results[2].data['data'];

      final prefs = await SharedPreferences
          .getInstance();

      if (!mounted) return;

      setState(() {
        final rawCategories = categoriesData;
        if (rawCategories is List) {
          _categories = rawCategories
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        final rawSession = sessionsData is List && sessionsData.isNotEmpty
            ? sessionsData.first
            : null;
        if (rawSession != null && rawSession is Map) {
          _lastSession = Map<String, dynamic>.from(rawSession);
        }

        final rawUser = userData is Map && userData['user'] is Map
            ? userData['user']
            : userData;
        if (rawUser != null && rawUser is Map) {
          _user = Map<String, dynamic>.from(rawUser);
        }

        _isLoading = false;
      });

      await prefs.setString('home_cache',
          jsonEncode({
            'user': _user,
            'categories': _categories,
            'last_session': _lastSession,
          }));
    } on DioException catch (e) {
      debugPrint('API ERROR: $e');
      if (e.response?.statusCode == 401) {
        await const FlutterSecureStorage()
            .delete(key: 'auth_token');
        if (mounted) context.go('/auth');
        return;
      }
      if (mounted) setState(() =>
          _isLoading = false);
    } catch (e) {
      debugPrint('ERROR: $e');
      if (mounted) setState(() =>
          _isLoading = false);
    }
  }

  String _getInitials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String _getTimeAgo(String completedAt) {
    final DateTime date = DateTime.parse(completedAt);
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    }
    return 'Il y a ${diff.inDays}j';
  }

  ({Color bgColor, Color iconColor, IconData icon}) _getCategoryStyle(int index) {
    switch (index % 3) {
      case 0:
        return (
          bgColor: const Color(0xFFFFF3E8),
          iconColor: const Color(0xFFF77F00),
          icon: Icons.menu_book_rounded,
        );
      case 1:
        return (
          bgColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF22C55E),
          icon: Icons.location_on_rounded,
        );
      case 2:
      default:
        return (
          bgColor: const Color(0xFFFFFDE8),
          iconColor: const Color(0xFFFFB300),
          icon: Icons.restaurant_rounded,
        );
    }
  }

  Widget _buildSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 16),

          // Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _SkeletonBox(width: 46, height: 46, radius: 23),
                  SizedBox(width: 12),
                  _SkeletonBox(width: 120, height: 18),
                ],
              ),
              _SkeletonBox(width: 90, height: 36, radius: 20),
            ],
          ),

          SizedBox(height: 24),

          // Mode picker skeleton
          Row(
            children: <Widget>[
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 80,
                  radius: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 80,
                  radius: 16,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Title skeleton
          _SkeletonBox(width: 160, height: 20),
          SizedBox(height: 12),

          // Category cards skeleton
          _SkeletonBox(width: double.infinity, height: 72, radius: 16),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 72, radius: 16),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 72, radius: 16),

          SizedBox(height: 24),

          // Last session skeleton
          _SkeletonBox(width: double.infinity, height: 100, radius: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _buildSkeleton(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFF77F00),
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildModePicker(),
                const SizedBox(height: 24),
                _buildCategoriesSection(),
                const SizedBox(height: 24),
                _buildLastSession(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String fullName = (_user?['name'] as String?)?.trim().isNotEmpty == true
        ? (_user?['name'] as String)
        : 'Kouassi Yao';
    final String firstName = fullName.split(RegExp(r'\s+')).first;
    final int score = (_user?['total_score'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFF77F00),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(fullName),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Bonjour, $firstName !',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  '⭐',
                  style: GoogleFonts.nunito(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '$score pts',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _buildModeButton(
                  label: 'Par catégorie',
                  icon: Icons.grid_view_rounded,
                  mode: 'category',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton(
                  label: 'Mode mixte',
                  icon: Icons.shuffle_rounded,
                  mode: 'mixed',
                ),
              ),
            ],
          ),
          if (_selectedMode == 'mixed') ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/quiz/null/mixed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF77F00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.shuffle_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Lancer le mode mixte',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required String mode,
  }) {
    final bool isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF77F00) : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: isSelected ? null : Border.all(color: AppColors.neutral, width: 1.5),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFF77F00).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFFF77F00),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Choisir une catégorie',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingCategories)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF77F00),
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> category = _categories[index];
              final ({Color bgColor, Color iconColor, IconData icon}) style = _getCategoryStyle(index);

              return GestureDetector(
                onTap: () {
                  if (_selectedMode == 'mixed') {
                    context.push('/quiz/null/mixed');
                    return;
                  }
                  context.push('/quiz/${category['id']}/$_selectedMode');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Icon(
                          style.icon,
                          size: 24,
                          color: style.iconColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              (category['name'] ?? '') as String,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${category['questions_count']} questions disponibles',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textGray,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLastSession() {
    if (_loadingSession) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF77F00),
        ),
      );
    }

    if (_lastSession == null) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> session = _lastSession!;
    final String categoryName = (session['category'] as Map<String, dynamic>?)?['name'] as String? ?? 'Catégorie';
    final String scoreText = '${session['correct_answers'] ?? 0}/10 · ${session['total_score'] ?? 0} pts';
    final String completedAt = (session['completed_at'] as String?) ?? DateTime.now().toIso8601String();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: AppColors.neutral),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Dernière partie',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/result', extra: session),
                child: Text(
                  'Voir le détail →',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF77F00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFF77F00),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      categoryName,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scoreText,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getTimeAgo(completedAt),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
