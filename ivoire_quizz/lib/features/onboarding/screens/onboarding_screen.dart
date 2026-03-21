import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _orange = Color(0xFFF77F00);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textGray = Color(0xFF6B7280);

  final PageController _pageController = PageController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    await _storage.write(key: 'onboarding_done', value: 'true');
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: KentePattern()),
          SafeArea(
            child: Column(
              children: [
                _buildSkipButton(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) {
                      setState(() => _currentPage = value);
                    },
                    children: [
                      _buildSlide1(),
                      _buildSlide2(),
                      _buildSlide3(),
                    ],
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    final showSkip = _currentPage == 1;
    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: showSkip
              ? TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Passer',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textGray,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    return _buildSlideLayout(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMascotAsset('assets/images/kwame_welcome.png', height: 220)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms),
          const SizedBox(height: 32),
          Text(
            'Bienvenue sur IvoireQuiz !',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Le quiz qui célèbre la culture et l\'histoire de la Côte d\'Ivoire',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _textGray,
                height: 1.45,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return _buildSlideLayout(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _buildMascotAsset('assets/images/kwame_thinking.png', height: 180)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms),
                _floatingCard(
                  icon: Icons.menu_book_rounded,
                  backgroundColor: const Color(0xFFFFF3E8),
                  iconColor: _orange,
                  left: 12,
                  top: 20,
                ),
                _floatingCard(
                  icon: Icons.restaurant_rounded,
                  backgroundColor: const Color(0xFFFFF3E8),
                  iconColor: _orange,
                  left: 24,
                  bottom: 28,
                ),
                _floatingCard(
                  icon: Icons.location_on_outlined,
                  backgroundColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  right: 12,
                  top: 48,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Teste tes connaissances',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '10 questions par session — Histoire, Géographie, Gastronomie. Réponds vite pour gagner plus de points !',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _textGray,
                height: 1.45,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill('10\nquestions'),
              const SizedBox(width: 12),
              _pill('20 sec /\nquestion'),
              const SizedBox(width: 12),
              _pill('Bonus\nrapidité'),
            ],
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 300.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildSlide3() {
    return _buildSlideLayout(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMascotAsset('assets/images/kwame_correct.png', height: 180)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms),
          const SizedBox(height: 16),
          _buildPodium()
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                delay: 200.ms,
                duration: 500.ms,
              ),
          const SizedBox(height: 24),
          Text(
            'Défie tes amis',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Ajoute tes amis via leur code unique et monte dans le classement ivoirien !',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _textGray,
                height: 1.45,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSlideLayout({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    final ctaText = _currentPage == 2 ? 'Créer mon compte' : 'Commencer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageIndicator(),
          const SizedBox(height: 20),
          _buildCTAButton(
            ctaText,
            () {
              if (_currentPage == 0 || _currentPage == 1) {
                _pageController.nextPage(
                  duration: 300.ms,
                  curve: Curves.easeOut,
                );
              } else {
                _finishOnboarding();
              }
            },
          ),
          if (_currentPage == 2) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _finishOnboarding,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _textGray,
                  ),
                  children: [
                    const TextSpan(text: 'J\'ai déjà un compte — '),
                    TextSpan(
                      text: 'Connexion',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _orange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: 250.ms,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _orange : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildCTAButton(String text, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _textDark,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _floatingCard({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildPodium() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _podiumItem(
          rank: '2',
          columnColor: const Color(0xFFD3D1C7),
          avatarColor: const Color(0xFFA8AFBA),
          columnHeight: 80,
          avatarSize: 36,
        ),
        const SizedBox(width: 8),
        _podiumItem(
          rank: '1',
          columnColor: _orange,
          avatarColor: _orange,
          columnHeight: 110,
          avatarSize: 44,
          crown: true,
        ),
        const SizedBox(width: 8),
        _podiumItem(
          rank: '3',
          columnColor: const Color(0xFF8B6914),
          avatarColor: const Color(0xFFB66900),
          columnHeight: 65,
          avatarSize: 36,
        ),
      ],
    );
  }

  Widget _podiumItem({
    required String rank,
    required Color columnColor,
    required Color avatarColor,
    required double columnHeight,
    required double avatarSize,
    bool crown = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: crown
              ? ClipOval(
                  child: Image.asset(
                    'assets/images/kwame_mini.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('👑', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    rank,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: columnHeight,
          decoration: BoxDecoration(
            color: columnColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotAsset(String path, {required double height}) {
    return Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        width: 200,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF3E8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '🐘',
            style: TextStyle(fontSize: 80),
          ),
        ),
      ),
    );
  }
}

class KentePattern extends StatelessWidget {
  const KentePattern({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KentePatternPainter(),
      size: Size.infinite,
    );
  }
}

class _KentePatternPainter extends CustomPainter {
  static const Color _patternColor = Color(0xFFF77F00);

  @override
  void paint(Canvas canvas, Size size) {
    const diamondSize = 20.0;
    const spacing = 8.0;
    const step = diamondSize + spacing;

    final paint = Paint()..color = _patternColor.withOpacity(0.04);

    for (double y = -step; y <= size.height + step; y += step) {
      for (double x = -step; x <= size.width + step; x += step) {
        final center = Offset(x, y);
        final path = Path()
          ..moveTo(center.dx, center.dy - diamondSize / 2)
          ..lineTo(center.dx + diamondSize / 2, center.dy)
          ..lineTo(center.dx, center.dy + diamondSize / 2)
          ..lineTo(center.dx - diamondSize / 2, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
