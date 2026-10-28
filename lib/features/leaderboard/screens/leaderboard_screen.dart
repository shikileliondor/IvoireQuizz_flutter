import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';

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

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _globalList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _weeklyList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _friendsList = <Map<String, dynamic>>[];
  int? _currentUserId;
  int? _currentUserRank;
  int? _weeklyUserRank;
  int? _currentScore;
  int? _weeklyPoints;
  String? _weekStart;
  String? _weekEnd;
  String? _globalError;
  String? _weeklyError;
  int _globalPage = 1;
  int _globalLastPage = 1;
  int _weeklyPage = 1;
  int _weeklyLastPage = 1;
  bool _isLoadingGlobal = true;
  bool _isLoadingWeekly = false;
  bool _isLoadingMoreGlobal = false;
  bool _isLoadingMoreWeekly = false;
  bool _isLoadingFriends = false;
  Future<void>? _currentUserLoadFuture;
  Future<void>? _globalLoadFuture;
  Future<void>? _weeklyLoadFuture;
  Future<void>? _globalMoreLoadFuture;
  Future<void>? _weeklyMoreLoadFuture;
  Future<void>? _friendsLoadFuture;
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadGlobal();
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _currentUserLoadFuture = null;
    _globalLoadFuture = null;
    _weeklyLoadFuture = null;
    _globalMoreLoadFuture = null;
    _weeklyMoreLoadFuture = null;
    _friendsLoadFuture = null;
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted) return;
    setState(() {});
    if (_tabController.index == 1 &&
        _weeklyList.isEmpty &&
        !_isLoadingWeekly &&
        _weeklyError == null) {
      _loadWeekly();
    } else if (_tabController.index == 2 &&
        _friendsList.isEmpty &&
        !_isLoadingFriends) {
      _loadFriends();
    }
  }

  Future<Dio> _createDio() async {
    final token = await _storage.read(key: 'auth_token');
    return ApiConfig.createDio(authToken: token);
  }

  Future<void> _loadCurrentUser() {
    final Future<void>? runningLoad = _currentUserLoadFuture;
    if (runningLoad != null) return runningLoad;

    final Future<void> load = _loadCurrentUserInternal();
    _currentUserLoadFuture = load;
    return load;
  }

  Future<void> _loadCurrentUserInternal() async {
    try {
      final Dio dio = await _createDio();
      if (!mounted) return;

      final Response<dynamic> response = await dio.get<dynamic>('/auth/me');
      if (!mounted) return;
      final dynamic data = response.data;
      final dynamic userData =
          data is Map<String, dynamic> ? data['data'] : null;

      if (userData is Map) {
        final dynamic user =
            userData.containsKey('user') ? userData['user'] : userData;

        if (user is Map && user['id'] != null) {
          final int? id = int.tryParse(user['id'].toString());
          if (!mounted) return;
          setState(() {
            _currentUserId = id;
            _currentUserLoadFuture = null;
          });
        }
      }
    } catch (e) {
      debugPrint('USER ERROR: $e');
      if (!mounted) return;
      _currentUserLoadFuture = null;
    }
  }

  Future<void> _loadGlobal() {
    final Future<void>? runningLoad = _globalLoadFuture;
    if (runningLoad != null) return runningLoad;

    final Future<void> load = _loadGlobalPage(page: 1, append: false);
    _globalLoadFuture = load;
    return load;
  }

  Future<void> _loadGlobalPage(
      {required int page, required bool append}) async {
    if (mounted) {
      setState(() {
        if (append) {
          _isLoadingMoreGlobal = true;
        } else {
          _isLoadingGlobal = true;
          _globalError = null;
          if (!append) _globalPage = 1;
        }
      });
    }
    try {
      final Dio dio = await _createDio();
      if (!mounted) return;

      final Response<dynamic> response = await dio.get<dynamic>(
        '/leaderboard/global',
        queryParameters: <String, dynamic>{'page': page},
      );
      if (!mounted) return;
      final parsed = _parseLeaderboardPage(response.data, requestedPage: page);
      final Map<String, dynamic> data = parsed['data'] as Map<String, dynamic>;

      setState(() {
        _globalList = append
            ? <Map<String, dynamic>>[
                ..._globalList,
                ...parsed['users'] as List<Map<String, dynamic>>
              ]
            : parsed['users'] as List<Map<String, dynamic>>;
        _globalPage = parsed['current_page'] as int;
        _globalLastPage = parsed['last_page'] as int;
        _currentUserRank = _readInt(data['current_user_rank']);
        _currentScore = _readInt(data['current_score']);
        _globalError = null;
        _isLoadingGlobal = false;
        _isLoadingMoreGlobal = false;
        _globalLoadFuture = null;
        _globalMoreLoadFuture = null;
      });
    } catch (e) {
      debugPrint('GLOBAL ERROR: $e');
      if (!mounted) return;
      setState(() {
        _globalError = 'Impossible de charger le classement général.';
        _isLoadingGlobal = false;
        _isLoadingMoreGlobal = false;
        _globalLoadFuture = null;
        _globalMoreLoadFuture = null;
      });
    }
  }

  Future<void> _loadGlobalMore() {
    final Future<void>? runningLoad = _globalMoreLoadFuture;
    if (runningLoad != null) return runningLoad;
    final Future<void> load =
        _loadGlobalPage(page: _globalPage + 1, append: true);
    _globalMoreLoadFuture = load;
    return load;
  }

  Future<void> _loadWeekly() {
    final Future<void>? runningLoad = _weeklyLoadFuture;
    if (runningLoad != null) return runningLoad;
    final Future<void> load = _loadWeeklyPage(page: 1, append: false);
    _weeklyLoadFuture = load;
    return load;
  }

  Future<void> _loadWeeklyPage(
      {required int page, required bool append}) async {
    if (mounted) {
      setState(() {
        if (append) {
          _isLoadingMoreWeekly = true;
        } else {
          _isLoadingWeekly = true;
          _weeklyError = null;
          _weeklyPage = 1;
          _weeklyUserRank = null;
        }
      });
    }
    try {
      final Dio dio = await _createDio();
      if (!mounted) return;
      final Response<dynamic> response = await dio.get<dynamic>(
        '/leaderboard/weekly',
        queryParameters: <String, dynamic>{'page': page},
      );
      if (!mounted) return;
      final parsed = _parseLeaderboardPage(response.data, requestedPage: page);
      final Map<String, dynamic> data = parsed['data'] as Map<String, dynamic>;
      setState(() {
        _weeklyList = append
            ? <Map<String, dynamic>>[
                ..._weeklyList,
                ...parsed['users'] as List<Map<String, dynamic>>
              ]
            : parsed['users'] as List<Map<String, dynamic>>;
        _weeklyPage = parsed['current_page'] as int;
        _weeklyLastPage = parsed['last_page'] as int;
        _weeklyUserRank = _readInt(data['current_user_rank']);
        _weeklyPoints = _readInt(data['weekly_points']);
        _weekStart = data['week_start']?.toString();
        _weekEnd = data['week_end']?.toString();
        _weeklyError = null;
        _isLoadingWeekly = false;
        _isLoadingMoreWeekly = false;
        _weeklyLoadFuture = null;
        _weeklyMoreLoadFuture = null;
      });
    } catch (e) {
      debugPrint('WEEKLY LEADERBOARD ERROR: $e');
      if (!mounted) return;
      setState(() {
        _weeklyError = 'Impossible de charger le classement hebdomadaire.';
        _isLoadingWeekly = false;
        _isLoadingMoreWeekly = false;
        _weeklyLoadFuture = null;
        _weeklyMoreLoadFuture = null;
      });
    }
  }

  Future<void> _loadWeeklyMore() {
    final Future<void>? runningLoad = _weeklyMoreLoadFuture;
    if (runningLoad != null) return runningLoad;
    final Future<void> load =
        _loadWeeklyPage(page: _weeklyPage + 1, append: true);
    _weeklyMoreLoadFuture = load;
    return load;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> _parseLeaderboardPage(
    dynamic response, {
    required int requestedPage,
  }) {
    if (response is! Map) {
      throw const FormatException('Réponse de classement invalide.');
    }
    final Map<String, dynamic> envelope = _normalizeMap(response);
    final dynamic rawData = envelope['data'];
    if (rawData is! Map) {
      throw const FormatException('Données de classement absentes.');
    }
    final Map<String, dynamic> data = _normalizeMap(rawData);
    final dynamic rawLeaderboard = data['leaderboard'];
    dynamic rawRows;
    Map<String, dynamic> pagination = <String, dynamic>{};
    if (rawLeaderboard is Map) {
      final Map<String, dynamic> leaderboard = _normalizeMap(rawLeaderboard);
      rawRows = leaderboard['data'];
      final dynamic meta = leaderboard['meta'];
      pagination = meta is Map ? _normalizeMap(meta) : leaderboard;
    } else if (rawLeaderboard is List) {
      rawRows = rawLeaderboard;
    }
    if (rawRows is! List) {
      throw const FormatException('Liste de classement absente.');
    }

    final users = rawRows
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => _normalizeLeaderboardUser(item))
        .where((Map<String, dynamic> user) => user.isNotEmpty)
        .toList();
    return <String, dynamic>{
      'data': data,
      'users': users,
      'current_page': _readInt(pagination['current_page']) ?? requestedPage,
      'last_page': _readInt(pagination['last_page']) ?? requestedPage,
    };
  }

  Future<void> _loadFriends() {
    final Future<void>? runningLoad = _friendsLoadFuture;
    if (runningLoad != null) return runningLoad;

    final Future<void> load = _loadFriendsInternal();
    _friendsLoadFuture = load;
    return load;
  }

  Future<void> _loadFriendsInternal() async {
    if (mounted) {
      setState(() => _isLoadingFriends = true);
    }

    try {
      final Dio dio = await _createDio();
      if (!mounted) return;

      final List<Map<String, dynamic>> friends =
          await _fetchFriendsRanking(dio);
      if (!mounted) return;
      setState(() {
        _friendsList = _sortByScore(friends);
        _isLoadingFriends = false;
        _friendsLoadFuture = null;
      });
    } catch (e) {
      debugPrint('FRIENDS ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingFriends = false;
        _friendsLoadFuture = null;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFriendsRanking(Dio dio) async {
    try {
      final Response<dynamic> leaderboardResponse =
          await dio.get<dynamic>('/leaderboard/friends');
      final List<Map<String, dynamic>> leaderboardUsers =
          _extractLeaderboardUsers(
        leaderboardResponse.data,
        preferredKeys: const <String>[
          'leaderboard',
          'rankings',
          'friends',
          'users',
          'players',
        ],
      );

      if (leaderboardUsers.isNotEmpty) {
        return leaderboardUsers;
      }
    } catch (e) {
      debugPrint('FRIENDS LEADERBOARD ERROR: $e');
    }

    final Response<dynamic> friendsResponse =
        await dio.get<dynamic>('/friends');
    return _extractLeaderboardUsers(
      friendsResponse.data,
      preferredKeys: const <String>['friends'],
    );
  }

  List<Map<String, dynamic>> _extractLeaderboardUsers(
    dynamic responseData, {
    List<String> preferredKeys = const <String>[],
  }) {
    final dynamic listData = _findListPayload(responseData, preferredKeys);
    if (listData is! List) {
      return <Map<String, dynamic>>[];
    }

    return listData
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => _normalizeLeaderboardUser(item))
        .where((Map<String, dynamic> user) => user.isNotEmpty)
        .toList();
  }

  dynamic _findListPayload(dynamic payload, List<String> preferredKeys) {
    if (payload is List) return payload;
    if (payload is! Map) return null;

    final Map<String, dynamic> normalized = _normalizeMap(payload);
    for (final String key in <String>[
      ...preferredKeys,
      'data',
      'items',
      'results',
      'leaderboard',
      'rankings',
      'users',
      'players',
      'friends',
    ]) {
      final dynamic value = normalized[key];
      if (value is List) return value;
      if (value is Map) {
        final dynamic nested = _findListPayload(value, preferredKeys);
        if (nested is List) return nested;
      }
    }

    return null;
  }

  Map<String, dynamic> _normalizeLeaderboardUser(
      Map<dynamic, dynamic> rawItem) {
    final Map<String, dynamic> item = _normalizeMap(rawItem);
    final Map<String, dynamic> nestedUser = _extractNestedUser(item);
    final Map<String, dynamic> user = <String, dynamic>{
      ...nestedUser,
      if (nestedUser.isEmpty) ...item,
    };

    final int score = _extractScore(user, fallback: _extractScore(item));
    if (score > 0) {
      user['total_score'] = score;
    } else {
      user['total_score'] = user['total_score'] ??
          user['score'] ??
          item['total_score'] ??
          item['score'] ??
          0;
    }

    user['id'] =
        user['id'] ?? item['user_id'] ?? item['friend_id'] ?? item['id'];
    user['name'] = _extractName(user, fallback: _extractName(item));
    user['rank'] = user['rank'] ?? item['rank'] ?? item['position'];
    return user;
  }

  Map<String, dynamic> _extractNestedUser(Map<String, dynamic> item) {
    for (final String key in const <String>[
      'user',
      'player',
      'friend',
      'recipient',
      'requester',
      'profile',
    ]) {
      final dynamic value = item[key];
      if (value is Map) {
        return _normalizeMap(value);
      }
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> map) {
    return map.map(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        key.toString(),
        value,
      ),
    );
  }

  List<Map<String, dynamic>> _sortByScore(List<Map<String, dynamic>> users) {
    final List<Map<String, dynamic>> sorted = users
        .map((Map<String, dynamic> user) => Map<String, dynamic>.from(user))
        .toList();

    sorted.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final int scoreCompare = _extractScore(b).compareTo(_extractScore(a));
      if (scoreCompare != 0) return scoreCompare;

      return _extractName(a)
          .toLowerCase()
          .compareTo(_extractName(b).toLowerCase());
    });

    return sorted;
  }

  int _extractScore(Map<String, dynamic> user, {int fallback = 0}) {
    for (final String key in const <String>[
      'total_score',
      'score',
      'points',
      'xp',
      'best_score',
      'quiz_score',
    ]) {
      final dynamic value = user[key];
      final int? parsed = int.tryParse((value ?? '').toString());
      if (parsed != null) return parsed;
    }

    return fallback;
  }

  String _extractName(Map<String, dynamic> user, {String fallback = 'Joueur'}) {
    for (final String key in const <String>[
      'name',
      'username',
      'full_name',
      'display_name',
      'pseudo',
      'email',
    ]) {
      final dynamic value = user[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
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
                  _buildWeeklyTab(),
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
    final bool isWeekly = _tabController.index == 1;
    final int? rank = isWeekly ? _weeklyUserRank : _currentUserRank;
    final int? points = isWeekly ? _weeklyPoints : _currentScore;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
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
          if (_tabController.index != 2 && (rank != null || points != null))
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Column(
                children: [
                  Text(
                    rank == null
                        ? 'Ton rang ${isWeekly ? 'cette semaine' : 'général'}: non classé'
                        : 'Ton rang ${isWeekly ? 'cette semaine' : 'général'}: #$rank',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                    ),
                  ),
                  if (points != null)
                    Text(
                      '${isWeekly ? 'Points cette semaine' : 'Meilleur score campagne'}: $points pts',
                      style: GoogleFonts.nunito(fontSize: 12, color: _textGray),
                    ),
                  if (isWeekly && (_weekStart != null || _weekEnd != null))
                    Text(
                      'Période : ${_formatDate(_weekStart)} – ${_formatDate(_weekEnd)}',
                      style: GoogleFonts.nunito(fontSize: 12, color: _textGray),
                    ),
                ],
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const <Widget>[
                Tab(text: 'Général'),
                Tab(text: 'Cette semaine'),
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

    if (_globalError != null) {
      return _buildRankingError(_globalError!, _loadGlobal);
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
        itemCount: _globalList.length + (_globalPage < _globalLastPage ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == _globalList.length) {
            return _buildLoadMore(_isLoadingMoreGlobal, _loadGlobalMore);
          }
          final Map<String, dynamic> user = _globalList[index];
          final int rank = _readInt(user['rank']) ?? index + 1;
          final bool isCurrentUser =
              user['id']?.toString() == _currentUserId?.toString();

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

  Widget _buildWeeklyTab() {
    if (_isLoadingWeekly) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (_weeklyError != null) {
      return _buildRankingError(_weeklyError!, _loadWeekly);
    }
    if (_weeklyList.isEmpty) {
      return Center(
        child: Text('Aucun joueur cette semaine',
            style: GoogleFonts.nunito(color: _textGray)),
      );
    }
    return RefreshIndicator(
      color: _orange,
      onRefresh: _loadWeekly,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _weeklyList.length + (_weeklyPage < _weeklyLastPage ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == _weeklyList.length) {
            return _buildLoadMore(_isLoadingMoreWeekly, _loadWeeklyMore);
          }
          final user = _weeklyList[index];
          return _buildPlayerRow(
            user: user,
            rank: _readInt(user['rank']) ?? index + 1,
            isCurrentUser: user['id']?.toString() == _currentUserId?.toString(),
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildRankingError(String message, Future<void> Function() retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: GoogleFonts.nunito(color: _textGray)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded, color: _orange),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore(bool isLoading, Future<void> Function() loadMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: _orange)
            : TextButton(
                onPressed: loadMore,
                child: const Text('Charger plus de joueurs'),
              ),
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
              onPressed: () => context.go('/friends'),
              icon: const Icon(Icons.person_add_alt_1_rounded, color: _orange),
              label: Text(
                'Ajouter des amis',
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
          final bool isCurrentUser =
              user['id']?.toString() == _currentUserId?.toString();

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
    final String name = _extractName(user);
    final int score = _extractScore(user);
    final String initials = _getInitials(name);

    Widget rankWidget;

    if (rank == 1) {
      rankWidget =
          const Icon(Icons.emoji_events_rounded, color: _gold, size: 24);
    } else if (rank == 2) {
      rankWidget =
          const Icon(Icons.emoji_events_rounded, color: _silver, size: 24);
    } else if (rank == 3) {
      rankWidget =
          const Icon(Icons.emoji_events_rounded, color: _bronze, size: 24);
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
