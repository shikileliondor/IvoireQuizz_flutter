import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';

const _campaignOrange = Color(0xFFF77F00);
const _campaignInk = Color(0xFF1A1A2E);
const _campaignMuted = Color(0xFF6B7280);
const _campaignLine = Color(0xFFE5E7EB);
const _campaignGreen = Color(0xFF22C55E);

String? _campaignImageUrl(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  try {
    final uri = Uri.parse(value.trim());
    final resolved =
        uri.hasScheme ? uri : Uri.parse(ApiConfig.baseUrl).resolveUri(uri);
    if (resolved.scheme != 'http' && resolved.scheme != 'https') return null;
    return resolved.toString();
  } on FormatException {
    return null;
  }
}

class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key});

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  static const _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _regions = <Map<String, dynamic>>[];
  Map<String, dynamic> _currentPosition = <String, dynamic>{};
  bool _isLoading = true;
  String? _error;

  Future<Dio> _dio() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw const _CampaignAuthException();
    }
    return ApiConfig.createDio(authToken: token);
  }

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await (await _dio()).get<dynamic>('/v1/game/map');
      final dynamic envelope = response.data;
      final dynamic data = envelope is Map ? envelope['data'] : null;
      final dynamic regions = data is Map ? data['regions'] : null;
      final dynamic position = data is Map ? data['current_position'] : null;
      if (response.statusCode != 200 || data is! Map || regions is! List) {
        throw const FormatException('Réponse de carte invalide.');
      }
      if (!mounted) return;
      setState(() {
        _regions = regions
            .whereType<Map>()
            .map((region) => _stringMap(region))
            .toList();
        _currentPosition = position is Map ? _stringMap(position) : {};
        _isLoading = false;
      });
    } on _CampaignAuthException {
      if (!mounted) return;
      context.go('/auth');
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        if (!mounted) return;
        context.go('/auth');
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = _apiMessage(error);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is FormatException
            ? error.message
            : 'Impossible de charger la carte Campagne.';
        _isLoading = false;
      });
    }
  }

  String _apiMessage(DioException error) {
    final dynamic body = error.response?.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connexion impossible. Vérifie ton réseau puis réessaie.';
    }
    return 'La carte Campagne est momentanément indisponible.';
  }

  static Map<String, dynamic> _stringMap(Map<dynamic, dynamic> source) =>
      source.map((key, value) => MapEntry(key.toString(), value));

  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map(_stringMap).toList()
      : <Map<String, dynamic>>[];

  int _int(dynamic value, [int fallback = 0]) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;

  bool _bool(dynamic value) => value == true || value == 1 || value == '1';

  double _progress(dynamic value) {
    final double parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return (parsed / 100).clamp(0.0, 1.0);
  }

  Future<void> _showLevelDetails(Map<String, dynamic> level,
      {String? cityName, String? cityImageUrl}) async {
    final id = _int(level['id'], -1);
    if (id < 0) return;
    final session = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _LevelDetailsSheet(
        level: level,
        cityName: cityName,
        cityImageUrl: cityImageUrl,
        loadDetails: () async {
          final dio = await _dio();
          final response = await dio.get<dynamic>('/v1/levels/$id');
          final dynamic envelope = response.data;
          final dynamic data = envelope is Map ? envelope['data'] : null;
          final dynamic detail =
              data is Map && data['level'] is Map ? data['level'] : data;
          if (detail is! Map) {
            throw const FormatException('Détails du niveau invalides.');
          }
          return _stringMap(detail);
        },
        startLevel: (details) => _startLevel(sheetContext, details),
      ),
    );
    if (session == null || !mounted) return;
    context.push('/campaign/quiz', extra: session);
  }

  Future<Map<String, dynamic>?> _startLevel(
    BuildContext sheetContext,
    Map<String, dynamic> level,
  ) async {
    if (!_bool(level['is_unlocked'])) return null;
    final id = _int(level['id'], -1);
    if (id < 0) return null;
    try {
      final dio = await _dio();
      final response = await dio.post<dynamic>(
        '/v1/levels/$id/start',
        data: const <String, String>{'mode': 'level'},
      );
      final dynamic envelope = response.data;
      final dynamic session = envelope is Map ? envelope['data'] : null;
      final dynamic rawQuestions = session is Map ? session['questions'] : null;
      final questions = _maps(rawQuestions);
      final sessionId = session is Map ? _int(session['id'], -1) : -1;
      if (sessionId < 0 || questions.isEmpty) {
        throw const FormatException(
          'Le serveur n’a pas renvoyé de session avec des questions.',
        );
      }
      if (!sheetContext.mounted) return null;
      return <String, dynamic>{
        'session_id': sessionId,
        'level': level,
        'questions': questions,
      };
    } on DioException catch (error) {
      if (!sheetContext.mounted) return null;
      final dynamic body = error.response?.data;
      final String message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Impossible de démarrer ce niveau.';
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return null;
    } catch (error) {
      if (!sheetContext.mounted) return null;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Impossible de démarrer ce niveau.',
          ),
        ),
      );
      return null;
    }
  }

  Widget _buildLevel(Map<String, dynamic> level,
      {String? cityName, String? cityImageUrl}) {
    final bool unlocked = _bool(level['is_unlocked']);
    final bool completed = _bool(level['is_completed']);
    final int stars = _int(level['stars']).clamp(0, 3);
    final double progress = _progress(level['progress_percent']);
    final String name = level['name']?.toString().trim().isNotEmpty == true
        ? level['name'].toString()
        : 'Niveau ${_int(level['order'], 1)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: unlocked ? Colors.white : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _campaignLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLevelDetails(
          level,
          cityName: cityName,
          cityImageUrl: cityImageUrl,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFE8F5E9)
                      : unlocked
                          ? const Color(0xFFFFF3E8)
                          : const Color(0xFFEDEEF0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  !unlocked
                      ? Icons.lock_outline_rounded
                      : completed
                          ? Icons.check_rounded
                          : _bool(level['is_boss'])
                              ? Icons.workspace_premium_rounded
                              : Icons.flag_rounded,
                  color: !unlocked
                      ? _campaignMuted
                      : completed
                          ? _campaignGreen
                          : _campaignOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _campaignInk)),
                    const SizedBox(height: 3),
                    Text(
                      '${_int(level['questions_count'])} questions · '
                      '+${_int(level['xp_reward'])} XP',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: _campaignMuted,
                      ),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: _campaignLine,
                        color: _campaignOrange,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (stars > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (index) => Icon(
                      index < stars ? Icons.star_rounded : Icons.star_border,
                      size: 15,
                      color: const Color(0xFFFFB300),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: unlocked ? _campaignOrange : _campaignMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCity(Map<String, dynamic> city) {
    final cities = _maps(city['levels']);
    final unlocked = _bool(city['is_unlocked']);
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, bottom: 6),
      child: ExpansionTile(
        key: PageStorageKey<String>('campaign-city-${city['id']}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: _cityImage(city['image_url']),
        title: Text(city['name']?.toString() ?? 'Ville',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: _campaignInk)),
        subtitle: Text(
          '${cities.length} niveaux · '
          '${_bool(city['is_completed']) ? 'Terminée' : unlocked ? 'Accessible' : 'Verrouillée'}',
          style: GoogleFonts.nunito(fontSize: 12, color: _campaignMuted),
        ),
        trailing: _progressRing(city['progress_percent']),
        children: [
          if (cities.isEmpty)
            _emptyInline('Aucun niveau actif dans cette ville.')
          else
            ...cities.map((level) => _buildLevel(
                  level,
                  cityName: city['name']?.toString(),
                  cityImageUrl: city['image_url']?.toString(),
                )),
        ],
      ),
    );
  }

  Widget _cityImage(dynamic value) {
    final imageUrl = _campaignImageUrl(value);
    final fallback = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.location_city_rounded, color: _campaignOrange),
    );

    if (imageUrl == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _buildRegion(Map<String, dynamic> region) {
    final cities = _maps(region['cities']);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _campaignLine),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('campaign-region-${region['id']}'),
        leading: const _FallbackRegionIcon(),
        title: Text(region['name']?.toString() ?? 'Région',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: _campaignInk)),
        subtitle: Text(
          '${cities.length} villes · '
          '${_bool(region['is_completed']) ? 'Terminée' : _bool(region['is_unlocked']) ? 'Accessible' : 'Verrouillée'}',
          style: GoogleFonts.nunito(fontSize: 12, color: _campaignMuted),
        ),
        trailing: _progressRing(region['progress_percent']),
        children: [
          if (cities.isEmpty)
            _emptyInline('Aucune ville disponible dans cette région.')
          else
            ...cities.map(_buildCity),
        ],
      ),
    );
  }

  Widget _progressRing(dynamic value) {
    final progress = _progress(value);
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: _campaignLine,
            color: _campaignOrange,
          ),
          Center(
            child: Text('${(progress * 100).round()}',
                style: GoogleFonts.nunito(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: _campaignInk)),
          ),
        ],
      ),
    );
  }

  Widget _emptyInline(String message) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Text(message,
            style: GoogleFonts.nunito(color: _campaignMuted, fontSize: 13)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Campagne',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900, color: _campaignInk)),
        actions: [
          IconButton(
            tooltip: 'Actualiser la carte',
            onPressed: _isLoading ? null : _loadMap,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _campaignOrange))
          : _error != null
              ? _errorView()
              : _regions.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _loadMap,
                      color: _campaignOrange,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          _mapIntro(),
                          const SizedBox(height: 16),
                          ..._regions.map(_buildRegion),
                        ],
                      ),
                    ),
    );
  }

  Widget _mapIntro() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3E8), Color(0xFFFFFAF5)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const _FallbackRegionIcon(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore la Côte d’Ivoire',
                      style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _campaignInk)),
                  const SizedBox(height: 3),
                  Text(
                    'Choisis une région, découvre ses villes et progresse niveau par niveau.',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: _campaignMuted, height: 1.4),
                  ),
                  if (_currentPosition.isNotEmpty)
                    Text(
                      'Ta progression est synchronisée.',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: _campaignOrange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 52, color: _campaignMuted),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: _campaignInk)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMap,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(backgroundColor: _campaignOrange),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView() => RefreshIndicator(
        onRefresh: _loadMap,
        color: _campaignOrange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            const Icon(Icons.map_outlined, size: 56, color: _campaignMuted),
            const SizedBox(height: 12),
            Center(
              child: Text('Aucune région Campagne disponible.',
                  style: GoogleFonts.nunito(color: _campaignMuted)),
            ),
          ],
        ),
      );
}

class _LevelDetailsSheet extends StatefulWidget {
  const _LevelDetailsSheet({
    required this.level,
    this.cityName,
    this.cityImageUrl,
    required this.loadDetails,
    required this.startLevel,
  });

  final Map<String, dynamic> level;
  final String? cityName;
  final String? cityImageUrl;
  final Future<Map<String, dynamic>> Function() loadDetails;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic>) startLevel;

  @override
  State<_LevelDetailsSheet> createState() => _LevelDetailsSheetState();
}

class _LevelDetailsSheetState extends State<_LevelDetailsSheet>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _detailsFuture;
  late final AnimationController _buttonPulse;
  late final Animation<double> _buttonScale;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = widget.loadDetails();
    _buttonPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _buttonScale = Tween<double>(begin: .99, end: 1.01).animate(
      CurvedAnimation(parent: _buttonPulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonPulse.dispose();
    super.dispose();
  }

  int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  bool _unlocked(Map<String, dynamic> level) =>
      level['is_unlocked'] == true || level['is_unlocked'] == 1;

  String? _cityImageUrl(Map<String, dynamic> level) {
    final city = level['city'];
    final value = city is Map ? city['image_url'] : null;
    return _campaignImageUrl(value) ?? _campaignImageUrl(widget.cityImageUrl);
  }

  String? _cityName(Map<String, dynamic> level) {
    final city = level['city'];
    final detailName = city is Map ? city['name'] : null;
    if (detailName is String && detailName.trim().isNotEmpty) {
      return detailName.trim();
    }
    final fallback = widget.cityName?.trim();
    return fallback == null || fallback.isEmpty ? null : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            final level = snapshot.data ?? widget.level;
            final unlocked = _unlocked(level) && _unlocked(widget.level);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _campaignLine,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                _CampaignArrivalScene(
                  cityName: _cityName(level),
                  imageUrl: _cityImageUrl(level),
                  levelName: level['name']?.toString() ?? 'Niveau Campagne',
                ),
                const SizedBox(height: 14),
                _objectives(level)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 450.ms)
                    .slideY(begin: .12, end: 0),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: _campaignOrange),
                    ),
                  )
                else if (snapshot.hasError)
                  Text(
                    'Les détails ne sont pas disponibles. Les informations de la carte restent affichées.',
                    style:
                        GoogleFonts.nunito(color: _campaignMuted, fontSize: 13),
                  )
                else
                  _summary(level)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 650.ms)
                      .slideY(begin: .12, end: 0),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ScaleTransition(
                    scale: _buttonScale,
                    child: FilledButton.icon(
                      onPressed: !unlocked || _isStarting
                          ? null
                          : () async {
                              setState(() => _isStarting = true);
                              final session = await widget.startLevel(level);
                              if (session != null && context.mounted) {
                                Navigator.of(context).pop(session);
                                return;
                              }
                              if (context.mounted) {
                                setState(() => _isStarting = false);
                              }
                            },
                      icon: _isStarting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(unlocked
                              ? Icons.play_arrow_rounded
                              : Icons.lock_outline_rounded),
                      label: Text(
                          unlocked ? 'Je suis prêt !' : 'Niveau verrouillé'),
                      style: FilledButton.styleFrom(
                          backgroundColor: _campaignOrange,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          foregroundColor: Colors.white),
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _objectives(Map<String, dynamic> level) {
    final items = <String>[
      '${_int(level['questions_count'])} questions',
      if (level['is_boss'] == true || level['is_boss'] == 1) 'Boss',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.nunito(
                    color: _campaignInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _summary(Map<String, dynamic> level) {
    final stars = _int(level['stars']).clamp(0, 3);
    final progress = _int(level['progress_percent']).clamp(0, 100);
    final completed =
        level['is_completed'] == true || level['is_completed'] == 1;
    final status = completed
        ? 'Niveau terminé'
        : _unlocked(level)
            ? 'À poursuivre'
            : 'Niveau verrouillé';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.flag_rounded,
              color: completed ? Colors.green : _campaignOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(status,
                  style: GoogleFonts.nunito(
                      color: _campaignInk, fontWeight: FontWeight.w800)),
            ),
            Row(
              children: List.generate(
                3,
                (index) => Icon(
                  index < stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFFB300),
                  size: 19,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progression',
                style: GoogleFonts.nunito(color: _campaignMuted, fontSize: 12)),
            Text('$progress%',
                style: GoogleFonts.nunito(
                    color: _campaignInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 7,
            color: _campaignOrange,
            backgroundColor: _campaignLine,
          ),
        ),
      ],
    );
  }
}

class _CampaignArrivalScene extends StatelessWidget {
  const _CampaignArrivalScene({
    required this.cityName,
    required this.imageUrl,
    required this.levelName,
  });

  final String? cityName;
  final String? imageUrl;
  final String levelName;

  @override
  Widget build(BuildContext context) {
    final rawCity = cityName?.trim();
    final place =
        rawCity == null || rawCity.isEmpty ? 'Côte d’Ivoire' : rawCity;
    return Container(
      height: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1A12), Color(0xFF9A4B12), Color(0xFFF77F00)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xCC000000)],
              ),
            ),
          ),
          const Positioned(
            right: -12,
            bottom: -36,
            child: Icon(Icons.location_city_rounded,
                size: 190, color: Color(0x33FFFFFF)),
          ),
          const Positioned(
            right: 68,
            top: 22,
            child: Icon(Icons.circle, size: 7, color: Color(0xFFFFD166)),
          ),
          const Positioned(
            right: 34,
            top: 58,
            child: Icon(Icons.circle, size: 5, color: Color(0xFFFFE3A3)),
          ),
          const Positioned(
            right: 110,
            top: 42,
            child: Icon(Icons.circle, size: 4, color: Color(0xFFFFD166)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  place.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFFD166),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -.08),
                const SizedBox(height: 3),
                Text(
                  levelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0x66FFD166), blurRadius: 12),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 180.ms).scale(
                      begin: const Offset(.96, .96),
                      duration: 500.ms,
                      delay: 180.ms,
                    ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(1.04, 1.04), duration: 900.ms);
  }
}

class _FallbackRegionIcon extends StatelessWidget {
  const _FallbackRegionIcon({this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E8),
          borderRadius: BorderRadius.circular(size * .28),
        ),
        child:
            Icon(Icons.map_rounded, size: size * .56, color: _campaignOrange),
      );
}

class _CampaignAuthException implements Exception {
  const _CampaignAuthException();
}
