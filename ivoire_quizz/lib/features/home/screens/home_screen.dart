import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingCategories = true;
      _loadingSession = true;
    });

    final Dio dio = Dio();
    dio.options.baseUrl = 'http://127.0.0.1:8000/api';

    try {
      final String? token = await _storage.read(key: 'auth_token');
      dio.options.headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      await Future.wait<void>(<Future<void>>[
        _loadCategories(dio),
        _loadSessions(dio),
        _loadUserProfile(dio),
      ]);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = <Map<String, dynamic>>[];
        _lastSession = null;
        _user = null;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories(Dio dio) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>('/categories');
      final List<dynamic> data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? <dynamic>[];
      final List<Map<String, dynamic>> categories = List<Map<String, dynamic>>.from(data);

      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = <Map<String, dynamic>>[];
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadSessions(Dio dio) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>('/sessions');
      final List<dynamic> sessions = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? <dynamic>[];

      if (!mounted) {
        return;
      }
      setState(() {
        _lastSession = sessions.isNotEmpty ? Map<String, dynamic>.from(sessions.first as Map) : null;
        _loadingSession = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSession = null;
        _loadingSession = false;
      });
    }
  }

  Future<void> _loadUserProfile(Dio dio) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>('/auth/me');
      if (!mounted) {
        return;
      }
      setState(() {
        _user = Map<String, dynamic>.from((response.data as Map<String, dynamic>)['data'] as Map);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _user = null;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF77F00),
                ),
              )
            : RefreshIndicator(
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
              borderRadius: BorderRadius.circular(20),
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
      child: Row(
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
          borderRadius: BorderRadius.circular(16),
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
                onTap: () => context.push('/quiz/${category['id']}/$_selectedMode'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(8),
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
