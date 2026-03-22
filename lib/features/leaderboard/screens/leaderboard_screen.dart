import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _orange = Color(0xFFF77F00);
const _gold = Color(0xFFFFD700);
const _silver = Color(0xFFC0C0C0);
const _bronze = Color(0xFFCD7F32);
const _textDark = Color(0xFF1A1A2E);
const _textGray = Color(0xFF6B7280);
const _cardBg = Color(0xFFF8F9FA);
const _neutral = Color(0xFFE5E7EB);

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _globalList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _friendsList = <Map<String, dynamic>>[];
  int? _currentUserId;
  int? _currentUserRank;
  bool _isLoadingGlobal = true;
  bool _isLoadingFriends = true;
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadGlobal();
    _tabController.addListener(() {
      if (_tabController.index == 1 && _friendsList.isEmpty && !_isLoadingFriends) {
        _loadFriends();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Dio> _createDio() async {
    final token = await _storage.read(key: 'auth_token');

    return Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> _loadCurrentUser() async {
    try {
      final Dio dio = await _createDio();
      final Response<dynamic> response = await dio.get<dynamic>('/auth/me');
      final dynamic data = response.data;
      final dynamic userData = data is Map<String, dynamic> ? data['data'] : null;

      if (userData is Map) {
        final dynamic user = userData.containsKey('user') ? userData['user'] : userData;

        if (user is Map && user['id'] != null) {
          final int? id = int.tryParse(user['id'].toString());
          if (!mounted) return;
          setState(() => _currentUserId = id);
        }
      }
    } catch (e) {
      debugPrint('USER ERROR: $e');
    }
  }

  Future<void> _loadGlobal() async {
    if (mounted) {
      setState(() => _isLoadingGlobal = true);
    }

    try {
      final Dio dio = await _createDio();
      final Response<dynamic> response = await dio.get<dynamic>('/leaderboard/global');
      final dynamic payload = response.data;
      final dynamic data = payload is Map<String, dynamic> ? payload['data'] : null;

      List<dynamic> users = <dynamic>[];
      int? rank;

      if (data is Map) {
        users = (data['data'] ?? data['users'] ?? <dynamic>[]) as List<dynamic>;
        rank = int.tryParse((data['current_user_rank'] ?? '').toString());
      } else if (data is List) {
        users = data;
      }

      final List<Map<String, dynamic>> mapped = users
          .whereType<Map>()
          .map((Map<dynamic, dynamic> e) => e.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _globalList = mapped;
        _currentUserRank = rank;
        _isLoadingGlobal = false;
      });
    } catch (e) {
      debugPrint('GLOBAL ERROR: $e');
      if (!mounted) return;
      setState(() => _isLoadingGlobal = false);
    }
  }

  Future<void> _loadFriends() async {
    if (mounted) {
      setState(() => _isLoadingFriends = true);
    }

    try {
      final Dio dio = await _createDio();
      final Response<dynamic> response = await dio.get<dynamic>('/leaderboard/friends');
      final dynamic payload = response.data;
      final dynamic data = payload is Map<String, dynamic> ? payload['data'] : null;

      List<dynamic> users = <dynamic>[];
      if (data is List) {
        users = data;
      } else if (data is Map) {
        users = (data['data'] ?? data['users'] ?? <dynamic>[]) as List<dynamic>;
      }

      final List<Map<String, dynamic>> mapped = users
          .whereType<Map>()
          .map((Map<dynamic, dynamic> e) => e.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _friendsList = mapped;
        _isLoadingFriends = false;
      });
    } catch (e) {
      debugPrint('FRIENDS ERROR: $e');
      if (!mounted) return;
      setState(() => _isLoadingFriends = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildGlobalTab(),
                  _buildFriendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                tooltip: 'Retour',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Classement',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          if (_currentUserRank != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'Ton rang global: #$_currentUserRank',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: _textGray,
              labelStyle: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              tabs: const <Widget>[
                Tab(text: 'Global'),
                Tab(text: 'Amis'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGlobalTab() {
    if (_isLoadingGlobal) {
      return const Center(
        child: CircularProgressIndicator(color: _orange),
      );
    }

    if (_globalList.isEmpty) {
      return Center(
        child: Text(
          'Aucun joueur pour l\'instant',
          style: GoogleFonts.nunito(color: _textGray),
        ),
      );
    }

    return RefreshIndicator(
      color: _orange,
      onRefresh: _loadGlobal,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _globalList.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> user = _globalList[index];
          final int rank = index + 1;
          final bool isCurrentUser = user['id']?.toString() == _currentUserId?.toString();

          return _buildPlayerRow(
            user: user,
            rank: rank,
            isCurrentUser: isCurrentUser,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoadingFriends) {
      return const Center(
        child: CircularProgressIndicator(color: _orange),
      );
    }

    if (_friendsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.group_outlined, size: 64, color: _neutral),
            const SizedBox(height: 16),
            Text(
              'Pas encore d\'amis',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoute des amis depuis\nl\'onglet Amis',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: _textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _loadFriends,
              icon: const Icon(Icons.refresh_rounded, color: _orange),
              label: Text(
                'Actualiser',
                style: GoogleFonts.nunito(
                  color: _orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _orange,
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _friendsList.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> user = _friendsList[index];
          final int rank = index + 1;
          final bool isCurrentUser = user['id']?.toString() == _currentUserId?.toString();

          return _buildPlayerRow(
            user: user,
            rank: rank,
            isCurrentUser: isCurrentUser,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildPlayerRow({
    required Map<String, dynamic> user,
    required int rank,
    required bool isCurrentUser,
    required int index,
  }) {
    final String name = (user['name'] ?? user['username'] ?? 'Joueur').toString();
    final int score = int.tryParse((user['total_score'] ?? user['score'] ?? 0).toString()) ?? 0;
    final String initials = _getInitials(name);

    Widget rankWidget;

    if (rank == 1) {
      rankWidget = const Icon(Icons.emoji_events_rounded, color: _gold, size: 24);
    } else if (rank == 2) {
      rankWidget = const Icon(Icons.emoji_events_rounded, color: _silver, size: 24);
    } else if (rank == 3) {
      rankWidget = const Icon(Icons.emoji_events_rounded, color: _bronze, size: 24);
    } else {
      rankWidget = Text(
        '$rank',
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textGray,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFFFF3E8) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? _orange : _neutral,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentUser ? _orange : _cardBg,
              border: Border.all(color: isCurrentUser ? _orange : _neutral),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? Colors.white : _textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCurrentUser ? '$name (moi)' : name,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                color: _textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$score pts',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isCurrentUser ? _orange : _textGray,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 50 * index))
        .slideX(begin: 0.05, delay: Duration(milliseconds: 50 * index));
  }

  String _getInitials(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '??';
    }

    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    final String compact = parts.first;
    if (compact.length >= 2) {
      return compact.substring(0, 2).toUpperCase();
    }

    return compact.substring(0, 1).toUpperCase();
  }
}
