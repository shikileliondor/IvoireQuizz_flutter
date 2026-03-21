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
  late PageController _pageController;
  int _currentPage = 0;
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await _storage.write(key: 'onboarding_done', value: 'true');
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(
            painter: KentePatternPainter(),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    children: [
                      _buildSlide1(),
                      _buildSlide2(),
                      _buildSlide3(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 48,
      child: _currentPage == 1
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Passer',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSlide1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/kwame.png',
            height: 220,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, duration: 600.ms),
          const SizedBox(height: 32),
          Text(
            'Bienvenue sur IvoireQuiz !',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 12),
          Text(
            'Le quiz qui célèbre la culture
et l\'histoire de la Côte d\'Ivoire',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/kwame.png',
                  height: 180,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, duration: 600.ms),
                Positioned(
                  left: 20,
                  top: 20,
                  child: _buildFloatingIcon(
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFFF77F00),
                    bgColor: const Color(0xFFFFF3E8),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideX(begin: -0.3, delay: 300.ms),
                ),
                Positioned(
                  left: 10,
                  bottom: 20,
                  child: _buildFloatingIcon(
                    icon: Icons.restaurant,
                    color: const Color(0xFFF77F00),
                    bgColor: const Color(0xFFFFF3E8),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideX(begin: -0.3, delay: 400.ms),
                ),
                Positioned(
                  right: 20,
                  top: 40,
                  child: _buildFloatingIcon(
                    icon: Icons.location_on,
                    color: const Color(0xFF22C55E),
                    bgColor: const Color(0xFFE8F5E9),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms)
                      .slideX(begin: 0.3, delay: 350.ms),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Teste tes connaissances',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, delay: 200.ms),
          const SizedBox(height: 12),
          Text(
            '10 questions par session — Histoire,
Géographie, Gastronomie. Réponds vite
pour gagner plus de points !',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPill('10', 'questions'),
              const SizedBox(width: 12),
              _buildPill('20 sec /', 'question'),
              const SizedBox(width: 12),
              _buildPill('Bonus', 'rapidité'),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 400.ms)
              .slideY(begin: 0.2, delay: 400.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSlide3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/kwame.png',
            height: 160,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, duration: 600.ms),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodiumColumn(
                rank: 2,
                height: 80,
                color: const Color(0xFFD3D1C7),
              ),
              const SizedBox(width: 8),
              _buildPodiumColumn(
                rank: 1,
                height: 110,
                color: const Color(0xFFF77F00),
                isWinner: true,
              ),
              const SizedBox(width: 8),
              _buildPodiumColumn(
                rank: 3,
                height: 65,
                color: const Color(0xFF8B6914),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                delay: 200.ms,
              ),
          const SizedBox(height: 24),
          Text(
            'Défie tes amis',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.2, delay: 300.ms),
          const SizedBox(height: 12),
          Text(
            'Ajoute tes amis via leur code unique
et monte dans le classement ivoirien !',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageIndicator(),
          const SizedBox(height: 20),
          if (_currentPage < 2)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF77F00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Commencer',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_currentPage == 2)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF77F00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Créer mon compte',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _finishOnboarding,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'J\'ai déjà un compte — ',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        TextSpan(
                          text: 'Connexion',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFFF77F00),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFF77F00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == i
                ? const Color(0xFFF77F00)
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildFloatingIcon({
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildPill(String line1, String line2) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line1,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            line2,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required int rank,
    required double height,
    required Color color,
    bool isWinner = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isWinner ? 44 : 36,
          height: isWinner ? 44 : 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: isWinner
              ? ClipOval(
                  child: Image.asset(
                    'assets/images/kwame.png',
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    rank.toString(),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class KentePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF77F00).withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const double diamondSize = 16;
    const double spacing = 10;
    const double step = diamondSize + spacing;

    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - diamondSize / 2)
          ..lineTo(x + diamondSize / 2, y)
          ..lineTo(x, y + diamondSize / 2)
          ..lineTo(x - diamondSize / 2, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
