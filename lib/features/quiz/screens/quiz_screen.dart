import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';

const _orange    = Color(0xFFF77F00);
const _textDark  = Color(0xFF1A1A2E);
const _textGray  = Color(0xFF6B7280);
const _cardBg    = Color(0xFFF8F9FA);
const _neutral   = Color(0xFFE5E7EB);
const _correct   = Color(0xFF22C55E);
const _incorrect = Color(0xFFEF4444);

class QuizScreen extends StatefulWidget {
  final int? categoryId;
  final String mode;
  const QuizScreen({
    super.key,
    this.categoryId,
    required this.mode,
  });

  @override
  State<QuizScreen> createState() =>
    _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String,dynamic>> _questions = [];
  int _currentIndex = 0;
  int? _selectedOptionId;
  bool _answered = false;
  bool _isCorrectAnswer = false;
  bool _hasStarted = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  int _timeLeft = 20;
  int _sessionStartTime = 0;
  Timer? _timer;
  List<Map<String,dynamic>> _answers = [];
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now()
      .millisecondsSinceEpoch;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    if (_isLoading || _hasStarted) return;
    setState(() {
      _hasStarted = true;
      _isLoading = true;
    });
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final token = await _storage
        .read(key: 'auth_token');

      debugPrint('=== QUIZ DEBUG ===');
      debugPrint('TOKEN: $token');
      debugPrint('CATEGORY: ${widget.categoryId}');
      debugPrint('MODE: ${widget.mode}');

      if (token == null) {
        if (mounted) context.go('/auth');
        return;
      }

      final dio = ApiConfig.createDio(authToken: token);

      final Map<String,dynamic> params = {
        'mode': widget.mode,
      };
      if (widget.categoryId != null) {
        params['category_id'] =
          widget.categoryId.toString();
      }

      debugPrint('PARAMS: $params');

      final response = await dio.get(
        '/quiz/questions',
        queryParameters: params,
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('DATA TYPE: ${response.data.runtimeType}');
      debugPrint('DATA: ${response.data}');

      final list = _extractQuestionsPayload(response.data);
      final questions = list
        .asMap()
        .entries
        .map((entry) => _normalizeQuestion(entry.value, entry.key))
        .whereType<Map<String,dynamic>>()
        .toList();

      debugPrint('QUESTIONS PAYLOAD TYPE: ${list.runtimeType}');
      debugPrint('QUESTIONS: ${questions.length}');

      if (questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
        _startTimer();
      } else {
        debugPrint('Aucune question exploitable dans la réponse API.');
        setState(() => _isLoading = false);
      }
    } on DioException catch (e) {
      debugPrint('DIO ERROR: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('DATA: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        if (mounted) context.go('/auth');
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  dynamic _decodeIfJsonString(dynamic payload) {
    if (payload is! String) return payload;
    try {
      final decoded = jsonDecode(payload);
      debugPrint('DATA DECODED TYPE: ${decoded.runtimeType}');
      return decoded;
    } on FormatException catch (e) {
      debugPrint('DATA JSON DECODE ERROR: $e');
      return payload;
    }
  }

  List<dynamic> _extractQuestionsPayload(dynamic payload) {
    final data = _decodeIfJsonString(payload);
    debugPrint('ROOT PAYLOAD TYPE: ${data.runtimeType}');

    if (data is List) {
      debugPrint('ROOT PAYLOAD IS LIST: ${data.length} item(s)');
      return data;
    }

    if (data is Map) {
      debugPrint('ROOT PAYLOAD KEYS: ${data.keys.join(', ')}');
      final nestedData = data['data'];
      debugPrint('NESTED DATA TYPE: ${nestedData.runtimeType}');

      if (nestedData is List) return nestedData;

      if (nestedData is Map && nestedData['data'] is List) {
        final nestedList = nestedData['data'] as List;
        debugPrint('SECOND LEVEL DATA LIST: ${nestedList.length} item(s)');
        return nestedList;
      }
    }

    return const [];
  }

  Map<String,dynamic>? _normalizeQuestion(dynamic json, int index) {
    if (json is! Map) {
      debugPrint(
        'QUESTION[$index] ignorée: type ${json.runtimeType} non supporté',
      );
      return null;
    }

    final question = _stringKeyMap(json);
    final options = _normalizeOptions(question['options']);

    question['id'] = _parseInt(question['id']) ?? index + 1;
    question['question_text'] = _firstText(
      question,
      const ['question_text', 'question', 'text', 'label'],
    );
    question['explanation'] = _firstText(question, const ['explanation']);
    question['difficulty'] = _parseInt(question['difficulty']) ?? 1;
    question['options'] = options;

    debugPrint(
      'QUESTION[$index]: id=${question['id']}, '
      'options=${options.length}, keys=${question.keys.join(', ')}',
    );
    return question;
  }

  List<Map<String,dynamic>> _normalizeOptions(dynamic json) {
    if (json is! List) return <Map<String,dynamic>>[];
    return json
      .asMap()
      .entries
      .map((entry) => _normalizeOption(entry.value, entry.key))
      .toList();
  }

  Map<String,dynamic> _normalizeOption(dynamic json, int index) {
    if (json is String) {
      return <String,dynamic>{
        'id': index + 1,
        'option_text': json,
        'text': json,
        'label': json,
        'is_correct': false,
      };
    }

    if (json is Map) {
      final option = _stringKeyMap(json);
      final text = _firstText(
        option,
        const ['option_text', 'text', 'label'],
      );
      option['id'] = _parseInt(option['id']) ?? index + 1;
      option['option_text'] = text;
      option['text'] = option['text']?.toString() ?? text;
      option['label'] = option['label']?.toString() ?? text;
      option['is_correct'] = _parseBool(option['is_correct']);
      return option;
    }

    debugPrint(
      'OPTION[$index] remplacée par une option vide: '
      'type ${json.runtimeType} non supporté',
    );
    return <String,dynamic>{
      'id': index + 1,
      'option_text': '',
      'text': '',
      'label': '',
      'is_correct': false,
    };
  }

  List<Map<String,dynamic>> _optionsOf(Map<String,dynamic> question) {
    final options = question['options'];
    if (options is List<Map<String,dynamic>>) return options;
    if (options is List) return _normalizeOptions(options);
    return <Map<String,dynamic>>[];
  }

  Map<String,dynamic> _stringKeyMap(Map<dynamic,dynamic> json) {
    return json.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  String _firstText(Map<String,dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  String _optionText(Map<String,dynamic> option) {
    return _firstText(option, const ['option_text', 'text', 'label']);
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 20;
    _timer = Timer.periodic(
      const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_timeLeft <= 0) {
        timer.cancel();
        _onOptionSelected(null);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _stopTimer() => _timer?.cancel();

  void _onOptionSelected(int? optionId) {
    if (_answered) return;
    _stopTimer();
    final responseTime = 20 - _timeLeft;
    final question = _questions[_currentIndex];
    bool isCorrect = false;
    if (optionId != null) {
      final options = _optionsOf(question);
      final selected = options.firstWhere(
        (o) => o['id'] == optionId,
        orElse: () => <String, dynamic>{},
      );
      isCorrect = selected['is_correct'] == true;
    }
    setState(() {
      _selectedOptionId = optionId;
      _answered = true;
      _isCorrectAnswer = isCorrect;
    });
    _answers.add({
      'question_id': question['id'],
      'selected_option_id': optionId,
      'response_time_seconds': responseTime,
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _answered = false;
        _isCorrectAnswer = false;
        _timeLeft = 20;
      });
      _startTimer();
    } else {
      _submitSession();
    }
  }

  Future<void> _submitSession() async {
    setState(() => _isSubmitting = true);
    try {
      final token = await _storage
        .read(key: 'auth_token');
      final dio = ApiConfig.createDio(authToken: token);
      final durationSeconds =
        ((DateTime.now().millisecondsSinceEpoch -
          _sessionStartTime) / 1000).round();
      final response = await dio.post(
        '/sessions',
        data: {
          'category_id': widget.categoryId,
          'mode': widget.mode,
          'duration_seconds': durationSeconds,
          'answers': _answers,
        },
      );
      debugPrint('SESSION: ${response.data}');
      final sessionData = _decodeIfJsonString(response.data);
      if (sessionData is Map && sessionData['success'] == true) {
        final prefs = await SharedPreferences
          .getInstance();
        await prefs.remove('home_cache');
        debugPrint('Cache Home invalidé');
        if (mounted) {
          context.go('/result',
            extra: sessionData['data']);
        }
      }
    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStartScreen() {
    final bool isMixed = widget.mode == 'mixed';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _neutral),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: _textGray),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMixed ? Icons.shuffle_rounded : Icons.play_arrow_rounded,
                  color: _orange,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isMixed ? 'Mode mixte' : 'Quiz par catégorie',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Les questions seront téléchargées uniquement quand vous démarrez la partie.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  height: 1.5,
                  color: _textGray,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startQuiz,
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: Text(
                    'Lancer la partie',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              _QuizSkeletonBox(width: double.infinity, height: 40, radius: 12),
              SizedBox(height: 32),
              _QuizSkeletonBox(width: 120, height: 28, radius: 20),
              SizedBox(height: 16),
              _QuizSkeletonBox(width: double.infinity, height: 170, radius: 20),
              SizedBox(height: 24),
              _QuizSkeletonBox(width: double.infinity, height: 64, radius: 16),
              SizedBox(height: 12),
              _QuizSkeletonBox(width: double.infinity, height: 64, radius: 16),
              SizedBox(height: 12),
              _QuizSkeletonBox(width: double.infinity, height: 64, radius: 16),
              SizedBox(height: 12),
              _QuizSkeletonBox(width: double.infinity, height: 64, radius: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(int difficulty) {
    Color bgColor;
    Color textColor;
    String label;
    switch (difficulty) {
      case 1:
        bgColor = const Color(0xFFE8F5E9);
        textColor = _correct;
        label = 'Facile';
        break;
      case 2:
        bgColor = const Color(0xFFFFF3E8);
        textColor = _orange;
        label = 'Moyen';
        break;
      case 3:
        bgColor = const Color(0xFFFFEBEB);
        textColor = _incorrect;
        label = 'Difficile';
        break;
      default:
        bgColor = _cardBg;
        textColor = _textGray;
        label = 'Question';
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        )),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: _neutral),
            ),
            child: const Icon(Icons.close_rounded,
              color: _textGray, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: _questions.isEmpty ? 0 :
                (_currentIndex + 1) /
                _questions.length,
              backgroundColor: _neutral,
              valueColor: const AlwaysStoppedAnimation(
                _orange),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _timeLeft <= 5
              ? const Color(0xFFFFEBEB) : _cardBg,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(
              color: _timeLeft <= 5
                ? _incorrect : _neutral),
          ),
          child: Row(children: [
            Icon(Icons.timer_outlined,
              color: _timeLeft <= 5
                ? _incorrect : _textGray,
              size: 16),
            const SizedBox(width: 4),
            Text('$_timeLeft s',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _timeLeft <= 5
                  ? _incorrect : _textDark,
              )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuestionCounter() {
    return Text(
      'Question ${_currentIndex + 1} sur ${_questions.length}',
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textGray,
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = _questions[_currentIndex];
    final questionText = '${question['question_text'] ?? question['question'] ?? question['text'] ?? ''}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isCompact = screenHeight < 700 || constraints.maxWidth < 360;
        final isLongQuestion = questionText.length > 150;
        final mascotSize = isCompact || isLongQuestion ? 34.0 : 50.0;
        final cardPadding = isCompact ? 18.0 : 22.0;
        final questionFontSize = isCompact ? 16.0 : 18.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isCompact ? 150 : 180,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(color: _neutral),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildDifficultyBadge(
                          _parseInt(question['difficulty']) ?? 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/avecfodn.jpeg',
                        width: mascotSize,
                        height: mascotSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return Container(
                            width: mascotSize,
                            height: mascotSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pets,
                              color: _orange,
                              size: mascotSize * 0.58,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 14 : 18),
                Text(
                  questionText,
                  softWrap: true,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.nunito(
                    fontSize: questionFontSize,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanationCard() {
    final question = _questions[_currentIndex];
    final options = _optionsOf(question);
    final correctOption = options.firstWhere(
      (o) => o['is_correct'] == true,
      orElse: () => <String, dynamic>{
        'option_text': '',
      },
    );
    final correctText = _optionText(correctOption);
    final explanation = '${question['explanation'] ?? ''}';
    final statusColor = _isCorrectAnswer ? _correct : _incorrect;
    final backgroundColor = _isCorrectAnswer
      ? const Color(0xFFE8F5E9)
      : const Color(0xFFFFF7ED);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isCorrectAnswer
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isCorrectAnswer
                    ? 'Bonne réponse ! +points'
                    : 'Mauvaise réponse',
                  softWrap: true,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (!_isCorrectAnswer && correctText.isNotEmpty) ...[
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _textDark,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Bonne réponse : '),
                  TextSpan(
                    text: correctText,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Explication',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              explanation,
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.visible,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: _textDark,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.12);
  }

  Widget _buildOptions() {
    final question = _questions[_currentIndex];
    final options = _optionsOf(question);
    final letters = ['A', 'B', 'C', 'D'];
    return Column(
      children: List.generate(options.length, (i) {
        final option = options[i];
        final optionId = _parseInt(option['id']) ?? i + 1;
        final isSelected =
          _selectedOptionId == optionId;
        final isCorrectOption =
          option['is_correct'] == true;
        final isWrongSelected =
          isSelected && !isCorrectOption;
        final isRightOption =
          isCorrectOption && _answered;
        final isNotSelected =
          _answered && !isSelected &&
          !isRightOption;

        Color bgColor;
        Color borderColor;
        Color circleColor;
        Color letterColor;
        Widget? trailingIcon;

        if (_answered) {
          if (isRightOption) {
            bgColor = const Color(0xFFE8F5E9);
            borderColor = const Color(0xFF22C55E);
            circleColor = const Color(0xFF22C55E);
            letterColor = Colors.white;
            trailingIcon = const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 22,
            );
          } else if (isWrongSelected) {
            bgColor = const Color(0xFFFFEBEB);
            borderColor = const Color(0xFFEF4444);
            circleColor = const Color(0xFFEF4444);
            letterColor = Colors.white;
            trailingIcon = const Icon(
              Icons.cancel_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            );
          } else {
            bgColor = Colors.white;
            borderColor = _neutral;
            circleColor = _cardBg;
            letterColor = _textGray;
            trailingIcon = null;
          }
        } else {
          bgColor = isSelected
            ? const Color(0xFFFFF3E8)
            : Colors.white;
          borderColor = isSelected ? _orange : _neutral;
          circleColor = isSelected ? _orange : _cardBg;
          letterColor = isSelected ? Colors.white : _textGray;
          trailingIcon = isSelected
            ? const Icon(
                Icons.radio_button_checked,
                color: _orange,
                size: 20,
              )
            : null;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: i == options.length - 1 ? 0 : 12,
          ),
          child: GestureDetector(
            onTap: _answered
              ? null
              : () => _onOptionSelected(optionId),
            child: AnimatedOpacity(
              duration:
                const Duration(milliseconds: 300),
              opacity: isNotSelected ? 0.4 : 1.0,
              child: AnimatedContainer(
                duration:
                  const Duration(milliseconds: 300),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                    BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: (_answered && isRightOption) ||
                        (_answered && isWrongSelected) ||
                        (!_answered && isSelected)
                      ? 2
                      : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        border: Border.all(
                          color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          i < letters.length
                            ? letters[i] : '?',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: letterColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _optionText(option),
                        softWrap: true,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 10),
                      trailingIcon,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuizBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 560;
        final horizontalPadding = isWide ? 32.0 : 20.0;
        final maxContentWidth = isWide ? 560.0 : double.infinity;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCounter(),
                  const SizedBox(height: 18),
                  _buildQuestionCard(),
                  const SizedBox(height: 24),
                  _buildOptions(),
                  if (_answered) ...[
                    const SizedBox(height: 20),
                    _buildExplanationCard(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return _buildStartScreen();
    }
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: _orange),
            const SizedBox(height: 16),
            Text('Calcul de votre score...',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textGray)),
          ],
        )),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined,
              size: 64, color: _neutral),
            const SizedBox(height: 16),
            Text('Aucune question disponible',
              style: GoogleFonts.nunito(
                fontSize: 16, color: _textGray)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius:
                    BorderRadius.circular(14)),
              ),
              child: Text('Retour',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
            ),
          ],
        )),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(child: _buildQuizBody()),
        ]),
      ),
    );
  }
}


class _QuizSkeletonBox extends StatefulWidget {
  const _QuizSkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_QuizSkeletonBox> createState() => _QuizSkeletonBoxState();
}

class _QuizSkeletonBoxState extends State<_QuizSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
            color: _neutral.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
