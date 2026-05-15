import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';

const _orange = Color(0xFFF77F00);
const _textDark = Color(0xFF1A1A2E);
const _textGray = Color(0xFF6B7280);
const _cardBg = Color(0xFFF8F9FA);
const _neutral = Color(0xFFE5E7EB);
const _correct = Color(0xFF22C55E);
const _incorrect = Color(0xFFEF4444);

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> _friends = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isAddingFriend = false;
  Future<void>? _loadDataFuture;
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadFriendsOnce();
  }

  @override
  void dispose() {
    _loadDataFuture = null;
    super.dispose();
  }

  Future<Dio> _createDio() async {
    final token = await _storage.read(key: 'auth_token');
    return ApiConfig.createDio(authToken: token);
  }

  Future<void> _loadFriendsOnce() {
    final Future<void>? runningLoad = _loadDataFuture;
    if (runningLoad != null) return runningLoad;

    final Future<void> load = _loadFriends();
    _loadDataFuture = load;
    return load;
  }

  Future<void> _reloadFriendsAfterMutation() async {
    final Future<void>? runningLoad = _loadDataFuture;
    if (runningLoad != null) {
      await runningLoad;
      if (!mounted) return;
    }

    await _loadFriendsOnce();
    if (!mounted) return;
  }

  Future<void> _loadFriends() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final Dio dio = await _createDio();
      if (!mounted) return;

      final List<Response<dynamic>> results = await Future.wait<Response<dynamic>>(
        <Future<Response<dynamic>>>[
          dio.get<dynamic>('/friends'),
          dio.get<dynamic>('/friends/requests'),
        ],
      );
      if (!mounted) return;

      final List<Map<String, dynamic>> friendsData = _extractList(results[0].data);
      final List<Map<String, dynamic>> requestsData = _extractList(results[1].data);

      setState(() {
        _friends = friendsData;
        _requests = requestsData;
      });
    } catch (e) {
      debugPrint('FRIENDS ERROR: $e');
      if (!mounted) return;
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadDataFuture = null;
      });
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    final data = responseData is Map<String, dynamic> ? responseData['data'] : null;
    if (data is! List) {
      return <Map<String, dynamic>>[];
    }

    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<bool> _addFriend(String friendCode) async {
    final code = friendCode.trim().toUpperCase();

    if (code.isEmpty) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez entrer un code ami.',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _incorrect,
        ),
      );
      return false;
    }

    if (_isAddingFriend) return false;

    if (!mounted) return false;
    setState(() {
      _isAddingFriend = true;
    });

    try {
      final Dio dio = await _createDio();
      if (!mounted) return false;

      await dio.post<dynamic>(
        '/friends/add',
        data: <String, String>{'friend_code': code},
      );
      if (!mounted) return false;
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande envoyée !',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _correct,
        ),
      );

      await _reloadFriendsAfterMutation();
      if (!mounted) return false;

      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      if (!context.mounted) return false;

      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ?? 'Erreur lors de l'ajout')
          : 'Erreur lors de l'ajout';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _incorrect,
        ),
      );
      return false;
    } catch (e) {
      debugPrint('ADD FRIEND ERROR: $e');
      if (!mounted) return false;
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’envoyer la demande.',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: _incorrect,
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isAddingFriend = false;
        });
      }
    }
  }

  Future<void> _acceptRequest(int id) async {
    try {
      final Dio dio = await _createDio();
      if (!mounted) return;

      await dio.put<dynamic>('/friends/$id/accept');
      if (!mounted) return;

      await _reloadFriendsAfterMutation();
      if (!mounted) return;
    } catch (e) {
      debugPrint('ACCEPT ERROR: $e');
    }
  }

  Future<void> _deleteRequest(int id) async {
    try {
      final Dio dio = await _createDio();
      if (!mounted) return;

      await dio.delete<dynamic>('/friends/$id');
      if (!mounted) return;

      await _reloadFriendsAfterMutation();
      if (!mounted) return;
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
    }
  }

  void _showAddFriendModal() {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _neutral,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/avecfodn.jpeg',
                  height: 80,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ajouter un ami',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entre le code de ton ami',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: _textGray,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABOU42',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 24,
                      letterSpacing: 8,
                      color: _neutral,
                    ),
                    filled: true,
                    fillColor: _cardBg,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _neutral),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _orange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final code = controller.text.trim().toUpperCase();
                            if (code.length != 6) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Veuillez entrer un code ami valide.',
                                    style: GoogleFonts.nunito(),
                                  ),
                                  backgroundColor: _incorrect,
                                ),
                              );
                              return;
                            }

                            setModalState(() {
                              isSubmitting = true;
                            });

                            final bool added = await _addFriend(code);
                            if (!mounted) return;
                            if (!sheetContext.mounted) return;

                            if (added) {
                              controller.clear();
                              Navigator.of(sheetContext).pop();
                              return;
                            }

                            setModalState(() {
                              isSubmitting = false;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Ajouter',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: _orange,
          onRefresh: _loadFriendsOnce,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Amis',
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAddFriendModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ajouter',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _orange),
                  ),
                ),
              if (!_isLoading) ...<Widget>[
                if (_requests.isNotEmpty) ...<Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Demandes reçues (${_requests.length})',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final req = _requests[index];
                        final requesterRaw = req['requester'];
                        final requester = requesterRaw is Map<String, dynamic>
                            ? requesterRaw
                            : req;

                        final name = requester['name']?.toString() ?? '';
                        final id = req['id'];
                        final requestId = id is int ? id : int.tryParse(id.toString()) ?? -1;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _orange,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _orange,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getInitials(name),
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: requestId > 0 ? () => _acceptRequest(requestId) : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _correct,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Accepter',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: requestId > 0 ? () => _deleteRequest(requestId) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: _incorrect,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
                        );
                      },
                      childCount: _requests.length,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Mes amis (${_friends.length})',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                ),
                if (_friends.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: <Widget>[
                            const Icon(
                              Icons.group_outlined,
                              size: 64,
                              color: _neutral,
                            ),
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
                              'Ajoute des amis avec\nleur code unique',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: _textGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final friend = _friends[index];
                      final name = friend['name']?.toString() ?? '';
                      final score = friend['total_score'] ?? 0;
                      final id = friend['id'];
                      final friendId = id is int ? id : int.tryParse(id.toString()) ?? -1;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _neutral),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _cardBg,
                                  border: Border.all(color: _neutral),
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(name),
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      name,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    Text(
                                      '$score pts',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: _textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: friendId > 0 ? () => _deleteRequest(friendId) : null,
                                child: const Icon(
                                  Icons.person_remove_outlined,
                                  color: _textGray,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: Duration(milliseconds: 50 * index),
                            )
                            .slideX(
                              begin: 0.05,
                              delay: Duration(milliseconds: 50 * index),
                            ),
                      );
                    },
                    childCount: _friends.length,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final sanitized = name.trim();
    if (sanitized.isEmpty) {
      return '?';
    }

    final parts = sanitized.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    if (sanitized.length == 1) {
      return sanitized.toUpperCase();
    }

    return sanitized.substring(0, 2).toUpperCase();
  }
}
