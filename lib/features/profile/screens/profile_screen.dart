import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';
import '../../../main.dart' show appTextScale, appHighContrast, appReduceMotion;

const _orange = Color(0xFFF77F00);
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
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _objectives = [];
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _accessibilityExpanded = false;
  bool _showEmail = false;
  Future<void>? _loadDataFuture;
  static const _storage = FlutterSecureStorage();

  Widget _accessibilitySettings() {
    return ValueListenableBuilder<double>(
      valueListenable: appTextScale,
      builder: (context, scale, _) => ValueListenableBuilder<bool>(
        valueListenable: appHighContrast,
        builder: (context, contrast, _) => ValueListenableBuilder<bool>(
          valueListenable: appReduceMotion,
          builder: (context, reduceMotion, _) => Card(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: _accessibilityExpanded,
                onExpansionChanged: (expanded) =>
                    setState(() => _accessibilityExpanded = expanded),
                leading: const Icon(Icons.accessibility_new, color: _orange),
                title: Text('Accessibilité',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _textDark,
                    )),
                subtitle: const Text('Réglages d’affichage'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.text_fields),
                        Expanded(
                            child: Slider(
                          semanticFormatterCallback: (v) =>
                              'Taille du texte ${v.toStringAsFixed(1)}',
                          min: 1,
                          max: 1.4,
                          divisions: 4,
                          value: scale,
                          onChanged: (v) async {
                            appTextScale.value = v;
                            final p = await SharedPreferences.getInstance();
                            await p.setDouble('accessibility_text_scale', v);
                          },
                        )),
                      ]),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.contrast),
                        title: const Text('Contraste renforcé'),
                        value: contrast,
                        onChanged: (v) async {
                          appHighContrast.value = v;
                          final p = await SharedPreferences.getInstance();
                          await p.setBool('accessibility_high_contrast', v);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.motion_photos_off_outlined),
                        title: const Text('Réduire les animations'),
                        value: reduceMotion,
                        onChanged: (v) async {
                          appReduceMotion.value = v;
                          final p = await SharedPreferences.getInstance();
                          await p.setBool('accessibility_reduce_motion', v);
                        },
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _loadDataFuture = null;
    super.dispose();
  }

  Future<void> _loadData() {
    final Future<void>? runningLoad = _loadDataFuture;
    if (runningLoad != null) return runningLoad;

    final Future<void> load = _loadDataInternal();
    _loadDataFuture = load;
    return load;
  }

  Future<void> _loadDataInternal() async {
    if (mounted && _user == null) {
      setState(() => _isLoading = true);
    }
    try {
      final token = await _storage.read(key: 'auth_token');
      if (!mounted) return;

      if (token == null) {
        context.go('/auth');
        return;
      }

      final dio = ApiConfig.createDio(authToken: token);
      final userResponse = await dio.get<dynamic>('/v1/me');
      final dynamic userEnvelope = userResponse.data;
      final dynamic userData =
          userEnvelope is Map ? userEnvelope['data'] : null;

      if (!mounted) return;

      setState(() {
        if (userData is Map) {
          final dynamic rawUser =
              userData['user'] is Map ? userData['user'] : userData;
          _user = Map<String, dynamic>.from(rawUser as Map);
        }
        _isLoading = false;
        _loadDataFuture = null;
      });

      // Render the account as soon as /me responds. Each secondary section
      // updates the screen when its own request completes.
      _loadStats(dio);
      _loadRecentSessions(dio);
      _loadAchievements(dio);
    } on DioException catch (e) {
      debugPrint('ERREUR PROFIL: $e');
      if (e.response?.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        if (!mounted) return;
        context.go('/auth');
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadDataFuture = null;
      });
    } catch (e) {
      debugPrint('ERREUR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadDataFuture = null;
      });
    }
  }

  Future<void> _loadStats(Dio dio) async {
    final data = await _getOptionalProfileData(dio, '/profile/stats');
    if (!mounted || data is! Map) return;
    setState(() => _stats = Map<String, dynamic>.from(data));
  }

  Future<void> _loadRecentSessions(Dio dio) async {
    final data = await _getOptionalProfileData(dio, '/sessions');
    if (!mounted || data is! List) return;
    setState(() {
      _recentSessions = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    });
  }

  Future<void> _loadAchievements(Dio dio) async {
    final data = await _getOptionalProfileData(dio, '/achievements');
    if (!mounted || data is! Map) return;
    final badges = data['badges'];
    final objectives = data['objectives'];
    setState(() {
      if (badges is List) {
        _badges = badges
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      if (objectives is List) {
        _objectives = objectives
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    });
  }

  Future<dynamic> _getOptionalProfileData(Dio dio, String path) async {
    try {
      final response = await dio.get<dynamic>(path);
      final dynamic envelope = response.data;
      return envelope is Map ? envelope['data'] : null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        if (mounted) context.go('/auth');
        return null;
      }
      debugPrint('Section profil indisponible ($path): $error');
      return null;
    } catch (error) {
      debugPrint('Réponse profil invalide ($path): $error');
      return null;
    }
  }

  Future<void> _logout() async {
    if (mounted) {
      setState(() => _isLoggingOut = true);
    }
    try {
      final token = await _storage.read(key: 'auth_token');
      if (!mounted) return;

      final dio = ApiConfig.createDio(authToken: token);
      await dio.post('/auth/logout');
      if (!mounted) return;
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
    } finally {
      await _storage.deleteAll();
      if (mounted) context.go('/auth');
    }
  }

  Future<String> _getInviteMessage() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await ApiConfig.createDio(authToken: token)
          .get<dynamic>('/friends/invite');
      final dynamic envelope = response.data;
      final dynamic data = envelope is Map ? envelope['data'] : null;
      final dynamic message = data is Map ? data['message'] : null;
      if (message is String && message.trim().isNotEmpty) return message;
      debugPrint('Réponse /friends/invite sans message utilisable.');
    } catch (error) {
      debugPrint('Invitation API indisponible, partage de secours : $error');
    }

    final name = _user?['name']?.toString().trim();
    final friendCode = _user?['friend_code']?.toString().trim();
    final player = name == null || name.isEmpty ? 'Un joueur' : name;
    final code =
        friendCode == null || friendCode.isEmpty || friendCode == '------'
            ? ''
            : '\nMon code ami : $friendCode';
    return 'Rejoins-moi sur IvoireQuizz, le quiz de culture ivoirienne !'
        '\nJe suis $player.$code';
  }

  Future<void> _shareInviteMessage() async {
    String? message;
    try {
      message = await _getInviteMessage();
      await SharePlus.instance.share(
        ShareParams(text: message, title: 'Découvre IvoireQuizz'),
      );
    } catch (_) {
      if (!mounted) return;
      final text = message ??
          'Rejoins-moi sur IvoireQuizz, le quiz de culture ivoirienne !';
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Le menu de partage est indisponible. Message copié : colle-le dans WhatsApp.'),
        ),
      );
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'J';

    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.isEmpty) return email;
    final local = parts.first;
    final visibleLength = local.length < 2 ? 1 : 2;
    final hidden =
        List<String>.filled(local.length - visibleLength, '•').join();
    return '${local.substring(0, visibleLength)}$hidden@${parts.last}';
  }

  double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
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
    final email =
        (_user?['email'] ?? 'Adresse e-mail non renseignée').toString();
    final friendCode = (_user?['friend_code'] ?? '------').toString();
    final level = _number(_user?['level']).toInt();
    final gamesPlayed = _number(_user?['games_played']).toInt();
    final totalScore = _number(_user?['total_score']).toInt();

    final bestScore = _number(_stats?['best_score']).toInt();
    final successRate = _number(_stats?['success_rate']);
    final categoryStats = _stats?['by_category'] as List? ?? const [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: _orange,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeading(),
                _buildHeader(name, email, friendCode, level),
                _buildStatsSection(
                    gamesPlayed, bestScore, successRate, totalScore),
                const SizedBox(height: 12),
                _buildProfileActions(friendCode),
                _buildProgressSections(categoryStats),
                _accessibilitySettings(),
                const SizedBox(height: 10),
                _buildLogoutButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeading() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 18, 4),
        child: Row(
          children: [
            Expanded(
              child: Text('Mon profil',
                  style: GoogleFonts.nunito(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: _textDark)),
            ),
            IconButton(
              tooltip: 'Actualiser le profil',
              onPressed: _isLoading ? null : _loadData,
              icon: const Icon(Icons.refresh_rounded, color: _orange),
            ),
          ],
        ),
      );

  Widget _buildProfileActions(String friendCode) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _profileAction(
              icon: Icons.history_rounded,
              title: 'Historique des parties',
              subtitle: '${_recentSessions.length} parties récentes',
              onTap: () => context.push('/history', extra: _recentSessions),
            ),
            _profileAction(
              icon: Icons.emoji_events_outlined,
              title: 'Badges et objectifs',
              subtitle:
                  '${_badges.length} badges · ${_objectives.length} objectifs',
              onTap: () => _showProfileSection(
                'Badges et objectifs',
                _buildHistoryAndAchievements(),
              ),
            ),
            _profileAction(
              icon: Icons.share_rounded,
              title: 'Partager le jeu',
              subtitle: friendCode == '------'
                  ? 'Appuie ici puis choisis WhatsApp'
                  : 'WhatsApp · Code ami : $friendCode',
              onTap: _shareInviteMessage,
            ),
          ],
        ),
      );

  Widget _profileAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 9),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: _neutral),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFF3E8),
            child: Icon(icon, size: 19, color: _orange),
          ),
          title: Text(title,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, color: _textDark)),
          subtitle: Text(subtitle,
              style: GoogleFonts.nunito(fontSize: 12, color: _textGray)),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        ),
      );

  void _showProfileSection(String title, Widget content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _neutral,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _textDark)),
                const SizedBox(height: 12),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSections(List categoryStats) {
    if (categoryStats.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: _profileAction(
        icon: Icons.insights_rounded,
        title: 'Progression par catégorie',
        subtitle: '${categoryStats.length} catégories',
        onTap: () => _showProfileSection(
          'Progression par catégorie',
          _buildCategoryProgress(categoryStats),
        ),
      ),
    );
  }

  Future<void> _copyFriendCode(String friendCode) async {
    await Clipboard.setData(ClipboardData(text: friendCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code ami copié.')),
    );
  }

  Widget _buildHistoryAndAchievements() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_badges.isEmpty)
        const Text('Tes badges apparaîtront après tes premières parties.')
      else
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _badges.map((badge) {
              final unlocked = badge['unlocked'] == true;
              final progress = (badge['progress'] ?? 0).toString();
              final target = (badge['target'] ?? 1).toString();
              return Chip(
                avatar: Icon(unlocked ? Icons.emoji_events : Icons.lock_outline,
                    size: 18, color: unlocked ? _orange : _textGray),
                label: Text('${badge['name'] ?? 'Badge'} $progress/$target'),
                backgroundColor: unlocked ? const Color(0xFFFFF3E8) : _cardBg,
              );
            }).toList()),
      if (_objectives.isNotEmpty) ...[
        const SizedBox(height: 8),
        ..._objectives.map((item) {
          final progress = _number(item['progress']);
          final target = _number(item['target'], fallback: 1).clamp(1, 1000);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(item['name']?.toString() ?? 'Objectif'),
            subtitle: LinearProgressIndicator(
                value: (progress / target).clamp(0, 1),
                color: _orange,
                backgroundColor: _neutral),
            trailing: Text('${progress.toInt()}/${target.toInt()}'),
          );
        }),
      ],
    ]);
  }

  Widget _buildHeader(String name, String email, String friendCode, int level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 39,
            backgroundColor: const Color(0xFFFFF3E8),
            child: Text(
              _getInitials(name),
              style: GoogleFonts.nunito(
                  fontSize: 25, fontWeight: FontWeight.w900, color: _orange),
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 21, fontWeight: FontWeight.w900, color: _textDark)),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 72,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _showEmail ? email : _maskedEmail(email),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: _textGray.withValues(alpha: .75),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _showEmail
                      ? 'Masquer l’adresse e-mail'
                      : 'Afficher l’adresse e-mail',
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 30, height: 30),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _showEmail = !_showEmail),
                  icon: Icon(
                    _showEmail
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: _textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  size: 16, color: _orange),
              const SizedBox(width: 4),
              Text('Niveau $level',
                  style: GoogleFonts.nunito(
                      color: _orange, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _copyFriendCode(friendCode),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded,
                          size: 13, color: _textGray),
                      const SizedBox(width: 4),
                      Text('Code $friendCode',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: _textGray,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: .05);
  }

  Widget _buildStatsSection(
    int gamesPlayed,
    int bestScore,
    double successRate,
    int totalScore,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _neutral),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiques de jeu',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildCompactStat('Parties', '$gamesPlayed')),
                Expanded(
                    child: _buildCompactStat('Meilleur score', '$bestScore')),
                Expanded(
                    child: _buildCompactStat(
                        'Réussite', '${successRate.toStringAsFixed(0)}%')),
                Expanded(
                    child: _buildCompactStat('Score total', '$totalScore')),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 100.ms);
  }

  Widget _buildCompactStat(String label, String value) => Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _orange)),
            Text(label,
                maxLines: 2,
                style: GoogleFonts.nunito(fontSize: 10, color: _textGray)),
          ],
        ),
      );

  Widget _buildCategoryProgress(List categoryStats) {
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categoryStats.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value as Map<String, dynamic>;
          final categoryName =
              (stat['category_name'] ?? stat['name'] ?? '').toString();
          final rate = _number(stat['success_rate'] ?? stat['rate']);
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
                .fadeIn(
                    duration: 400.ms, delay: Duration(milliseconds: 100 * i))
                .slideX(begin: 0.1, delay: Duration(milliseconds: 100 * i)),
          );
        }),
      ],
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    const Icon(Icons.logout_rounded,
                        color: _incorrect, size: 20),
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
