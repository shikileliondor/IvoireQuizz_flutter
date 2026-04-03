import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _orange = Color(0xFFF77F00);
const _gold = Color(0xFFFFD700);
const _textDark = Color(0xFF1A1A2E);
const _textGray = Color(0xFF6B7280);
const _cardBg = Color(0xFFF8F9FA);
const _neutral = Color(0xFFE5E7EB);
const _correct = Color(0xFF22C55E);
const _incorrect = Color(0xFFEF4444);

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultScreen({
    super.key,
    required this.resultData,
  });

  String _getMessage(int correct) {
    if (correct == 10) return 'Parfait ! Tu es un vrai Ivoirien !';
    if (correct >= 7) return 'Très bien ! Tu connais bien ton pays !';
    if (correct >= 4) return 'Pas mal ! Continue à apprendre !';
    return 'Courage ! Tu feras mieux la prochaine fois !';
  }

  String _getEmoji(int correct) {
    if (correct == 10) return 'assets/effobi reflechit.png';
    if (correct >= 7) return 'assets/effobi reflechit.png';
    if (correct >= 4) return 'assets/effobi reflechit.png';
    return 'assets/effobi reflechit.png';
  }

  @override
  Widget build(BuildContext context) {
    final int correctAnswers = resultData['correct_answers'] ?? 0;
    const int totalQuestions = 10;
    final int totalScore = resultData['total_score'] ?? 0;
    final int bonusScore = resultData['bonus_score'] ?? 0;
    final int baseScore = resultData['score'] ?? 0;
    final String categoryName = resultData['category']?['name'] ?? 'Quiz mixte';
    final List answers = resultData['answers'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(correctAnswers, totalQuestions, categoryName),
              _buildScoreCard(correctAnswers, totalScore, bonusScore, baseScore),
              _buildAnswersList(answers),
              _buildButtons(context, resultData),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int correctAnswers, int totalQuestions, String categoryName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            _getEmoji(correctAnswers),
            height: correctAnswers >= 7 ? 120 : 90,
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
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$correctAnswers',
                style: GoogleFonts.nunito(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: correctAnswers >= 7 ? _correct : _incorrect,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 10),
                child: Text(
                  '/$totalQuestions',
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _textGray,
                    height: 1,
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.3, delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            _getMessage(correctAnswers),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _neutral,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Text(
              categoryName,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _textGray,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    int correctAnswers,
    int totalScore,
    int bonusScore,
    int baseScore,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _textDark,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points gagnés cette session',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalScore',
                  style: GoogleFonts.nunito(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: _gold,
                    height: 1,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'pts',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score de base',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$baseScore pts',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bonus rapidité',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+$bonusScore pts',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 700.ms)
                .slideY(begin: 0.2, delay: 700.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersList(List answers) {
    if (answers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détail des réponses',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(answers.length, (i) {
            final answer = answers[i] as Map<String, dynamic>;
            final isCorrect = answer['is_correct'] == true;
            final questionText = answer['question']?['question_text'] ?? '';
            final explanation = answer['question']?['explanation'] ?? '';
            final selectedText =
                answer['selected_option']?['option_text'] ?? 'Pas de réponse';
            final correctText = answer['correct_option']?['option_text'] ?? '';
            final pointsEarned = answer['points_earned'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEB),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(
                  color: isCorrect ? _correct : _incorrect,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect ? _correct : _incorrect,
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${i + 1}. $questionText',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Ta réponse : ',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _textGray,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                selectedText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCorrect ? _correct : _incorrect,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isCorrect) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Bonne réponse : ',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _textGray,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  correctText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _correct,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          explanation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _textGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isCorrect ? '+' : ''}$pointsEarned pts',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCorrect ? _correct : _incorrect,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: 100 * i),
                )
                .slideX(
                  begin: 0.1,
                  delay: Duration(milliseconds: 100 * i),
                );
          }),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Map<String, dynamic> resultData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final categoryId = resultData['category']?['id'];
                final mode = resultData['mode'] ?? 'category';
                context.go('/quiz/$categoryId/$mode');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.replay_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rejouer',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                backgroundColor: _cardBg,
                side: const BorderSide(color: _neutral, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: _textDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Retour à l\'accueil',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
