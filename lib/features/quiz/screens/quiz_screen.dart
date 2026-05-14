import 'dart:async';
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
  bool _isLoading = true;
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
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

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
      debugPrint('DATA: ${response.data}');

      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        debugPrint('QUESTIONS: ${list.length}');
        setState(() {
          _questions = list.map((e) =>
            Map<String,dynamic>.from(e)).toList();
          _isLoading = false;
        });
        _startTimer();
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
      final options = question['options'] as List;
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
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));
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
      if (response.data['success'] == true) {
        final prefs = await SharedPreferences
          .getInstance();
        await prefs.remove('home_cache');
        debugPrint('Cache Home invalidé');
        if (mounted) {
          context.go('/result',
            extra: response.data['data']);
        }
      }
    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');
      setState(() => _isSubmitting = false);
    }
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

  Widget _buildQuestion() {
    final question = _questions[_currentIndex];
    final options = question['options'] as List;
    final correctOption = options.firstWhere(
      (o) => o['is_correct'] == true,
      orElse: () => <String, dynamic>{
        'option_text': '',
      },
    );
    final correctText = correctOption['option_text'] ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Question ${_currentIndex + 1} '
            'sur ${_questions.length}',
            style: GoogleFonts.nunito(
              fontSize: 13, color: _textGray)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: _neutral),
            ),
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDifficultyBadge(
                      question['difficulty'] ?? 1),
                    Image.asset(
                      'assets/avecfodn.jpeg',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) {
                        return Container(
                          color: const Color(0xFFFFF3E8),
                          child: const Icon(
                            Icons.pets,
                            color: Color(0xFFF77F00),
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question['question_text'] ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                    height: 1.5,
                  )),
              ],
            ),
          ),
          if (_answered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCorrectAnswer
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEB),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(
                  color: _isCorrectAnswer
                    ? _correct : _incorrect),
              ),
              child: Row(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isCorrectAnswer
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                    color: _isCorrectAnswer
                      ? _correct : _incorrect,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                        CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCorrectAnswer
                            ? 'Bonne réponse ! +points'
                            : 'Mauvaise réponse',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isCorrectAnswer
                              ? _correct : _incorrect,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!_isCorrectAnswer) ...[
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: _textDark,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Bonne réponse : ',
                                ),
                                TextSpan(
                                  text: '$correctText',
                                  style:
                                    GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight:
                                      FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          question['explanation'] ?? '',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: _isCorrectAnswer
                              ? _textDark : _textGray,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate()
             .fadeIn(duration: 300.ms)
             .slideY(begin: 0.2),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final question = _questions[_currentIndex];
    final options = question['options'] as List;
    final letters = ['A', 'B', 'C', 'D'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20, 0, 20, 24),
      child: Column(
        children: List.generate(options.length, (i) {
          final option =
            Map<String,dynamic>.from(options[i]);
          final optionId = option['id'] as int;
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
            padding: const EdgeInsets.only(bottom: 10),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius:
                      BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: (_answered && isRightOption) ||
                          (_answered && isWrongSelected) ||
                          (!_answered && isSelected)
                        ? 2
                        : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
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
                            fontWeight: FontWeight.w700,
                            color: letterColor,
                          ))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option['option_text'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ))),
                    if (trailingIcon != null) trailingIcon,
                  ]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: _orange),
            const SizedBox(height: 16),
            Text('Chargement des questions...',
              style: GoogleFonts.nunito(
                fontSize: 14, color: _textGray)),
          ],
        )),
      );
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
          Expanded(child: _buildQuestion()),
          _buildOptions(),
        ]),
      ),
    );
  }
}
