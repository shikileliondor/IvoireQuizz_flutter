import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.resultData, super.key});

  final Map<String, dynamic> resultData;

  @override
  Widget build(BuildContext context) {
    final int score = resultData['score'] as int? ?? 0;
    final int total = resultData['total'] as int? ?? 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    '$score / $total',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    score >= (total / 2) ? 'Bravo ! Continue comme ça.' : 'Bien joué ! Tu peux faire encore mieux.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
