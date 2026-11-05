import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/game_map.dart';

class FirstJourneyIntro extends StatefulWidget {
  const FirstJourneyIntro({super.key, required this.map, required this.onDone});
  final GameMap map;
  final Future<void> Function() onDone;

  @override
  State<FirstJourneyIntro> createState() => _FirstJourneyIntroState();
}

class _FirstJourneyIntroState extends State<FirstJourneyIntro> {
  late final PageController _controller;
  int _page = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 2) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onDone();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de valider l’introduction. Réessaie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFCF7),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  const _IntroPage(
                    icon: Icons.explore_rounded,
                    title: 'Bienvenue dans IvoireQuiz',
                    text: 'Découvre la Côte d’Ivoire, défi après défi.',
                  ),
                  const _NationalMapPage(),
                  _IntroPage(
                    icon: Icons.location_city_rounded,
                    title: widget.map.world.name,
                    eyebrow: 'MONDE ${widget.map.world.number}',
                    text: widget.map.world.subtitle ??
                        'La perle des lagunes t’attend. Commence ton aventure.',
                    mascot: true,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final active = index == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.orange : AppColors.neutral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _next,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_page == 2 ? 'COMMENCER L’AVENTURE' : 'CONTINUER'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.text,
    this.eyebrow,
    this.mascot = false,
  });
  final IconData icon;
  final String title;
  final String text;
  final String? eyebrow;
  final bool mascot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x33F77F00), Color(0x08F77F00)],
              ),
            ),
            child: mascot
                ? Image.asset(
                    'assets/Effobi salutation.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      icon,
                      color: AppColors.orange,
                      size: 82,
                    ),
                  )
                : Icon(icon, color: AppColors.orange, size: 90),
          ),
          const SizedBox(height: 28),
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: GoogleFonts.nunito(
                color: AppColors.orange,
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontSize: 29,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textGray,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NationalMapPage extends StatelessWidget {
  const _NationalMapPage();
  static const _worlds = [
    ('Abidjan', true),
    ('Yamoussoukro', false),
    ('Bouaké', false),
    ('Korhogo', false),
    ('Man', false),
    ('San Pedro', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'La Côte d’Ivoire t’attend',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 27,
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ton aventure commence ici : Abidjan.',
            style: GoogleFonts.nunito(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _worlds.map((world) {
              final unlocked = world.$2;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: unlocked ? const Color(0xFFFFF0DF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked ? AppColors.orange : AppColors.neutral,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      unlocked ? Icons.location_on_rounded : Icons.lock_rounded,
                      size: 18,
                      color: unlocked ? AppColors.orange : AppColors.textGray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      world.$1,
                      style: GoogleFonts.nunito(
                        color:
                            unlocked ? AppColors.textDark : AppColors.textGray,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
