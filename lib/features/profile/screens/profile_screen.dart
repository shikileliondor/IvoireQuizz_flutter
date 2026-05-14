import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';

const _orange = Color(0xFFF77F00);
const _gold = Color(0xFFFFD700);
const _textDark = Color(0xFF1A1A2E);
const _textGray = Color(0xFF6B7280);
const _cardBg = Color(0xFFF8F9FA);
const _neutral = Color(0xFFE5E7EB);
const _incorrect = Color(0xFFEF4444);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  Future<void>? _loadDataFuture;
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() {
    final Future<void>? runningLoad = _loadDataFuture;
    if (runningLoad != null) return runningLoad;

    final Future<void> load = _loadDataInternal();
    _loadDataFuture = load;
    load.whenComplete(() => _loadDataFuture = null);
    return load;
  }

  Future<void> _loadDataInternal() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        if (mounted) context.go('/auth');
        return;
      }

      final dio = ApiConfig.createDio(authToken: token);

      final results = await Future.wait([
        dio.get('/auth/me'),
        dio.get('/profile/stats'),
      ]);

      final userData = (results[0].data as Map<String, dynamic>)['data'];
      final statsData = (results[1].data as Map<String, dynamic>)['data'];

      if (!mounted) return;

      setState(() {
        if (userData is Map) {
          if (userData.containsKey('user')) {
            _user = Map<String, dynamic>.from(userData['user'] as Map);
          } else {
            _user = Map<String, dynamic>.from(userData);
          }
        }
        if (statsData is Map) {
          _stats = Map<String, dynamic>.from(statsData);
        }
        _isLoading = false;
      });
    } on DioException catch (e) {
      debugPrint('ERREUR PROFIL: $e');
      if (e.response?.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        if (mounted) context.go('/auth');
        return;
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('ERREUR: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    if (mounted) {
      setState(() => _isLoggingOut = true);
    }
    try {
      final token = await _storage.read(key: 'auth_token');
      final dio = ApiConfig.createDio(authToken: token);
      await dio.post('/auth/logout');
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
    } finally {
      await _storage.deleteAll();
      if (mounted) context.go('/auth');
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'J';

    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: _orange),
        ),
      );
    }

    final name = (_user?['name'] ?? 'Joueur').toString();
    final friendCode = (_user?['friend_code'] ?? '------').toString();
    final gamesPlayed = (_user?['games_played'] as num?)?.toInt() ?? 0;
    final totalScore = (_user?['total_score'] as num?)?.toInt() ?? 0;

    final bestScore = (_stats?['best_score'] as num?)?.toInt() ?? 0;
    final successRate = (_stats?['success_rate'] as num?)?.toDouble() ?? 0.0;
    final categoryStats = _stats?['by_category'] as List? ?? const [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _orange,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name, friendCode),
              const SizedBox(height: 24),
              _buildStatsSection(gamesPlayed, bestScore, successRate, totalScore),
              const SizedBox(height: 24),
              _buildCategoryProgress(categoryStats),
              const SizedBox(height: 24),
              _buildLogoutButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String friendCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: friendCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Code copié !',
                    style: GoogleFonts.nunito(),
                  ),
                  backgroundColor: _textDark,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Code : ',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    friendCode,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildStatsSection(
    int gamesPlayed,
    int bestScore,
    double successRate,
    int totalScore,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Parties jouées',
                  value: '$gamesPlayed',
                  isGold: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Meilleur score',
                  value: '$bestScore',
                  isGold: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Taux de réussite',
                  value: '${successRate.toStringAsFixed(0)}%',
                  isGold: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Score total',
                  value: '$totalScore',
                  isGold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, delay: 200.ms);
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required bool isGold,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFFFFDE8) : _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGold ? const Color(0xFFFFE082) : _neutral,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isGold ? _gold : _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: _textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgress(List categoryStats) {
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression par catégorie',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryStats.asMap().entries.map((entry) {
            final i = entry.key;
            final stat = entry.value as Map<String, dynamic>;
            final categoryName = (stat['category_name'] ?? stat['name'] ?? '').toString();
            final rawRate = (stat['success_rate'] ?? stat['rate'] ?? 0.0) as num;
            final rate = rawRate.toDouble();
            final normalizedRate = (rate > 1 ? rate / 100 : rate).clamp(0.0, 1.0);
            final percent = (normalizedRate * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: normalizedRate,
                      backgroundColor: _neutral,
                      valueColor: const AlwaysStoppedAnimation(_orange),
                      minHeight: 8,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * i))
                  .slideX(begin: 0.1, delay: Duration(milliseconds: 100 * i)),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: _isLoggingOut ? null : _logout,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _incorrect, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoggingOut
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: _incorrect,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: _incorrect, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Se déconnecter',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _incorrect,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }
}
