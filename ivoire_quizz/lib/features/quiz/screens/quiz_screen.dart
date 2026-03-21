import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({required this.categoryId, required this.mode, super.key});

  final int? categoryId;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Catégorie: ${categoryId ?? 'Libre'}'),
            Text('Mode: ${mode.isEmpty ? 'classic' : mode}'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Quel est le plus grand district de Côte d\'Ivoire en superficie ?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <String>['Abidjan', 'Savanes', 'Yamoussoukro', 'Bas-Sassandra']
                          .map(
                            (String answer) => ChoiceChip(
                              label: Text(answer),
                              selected: false,
                              onSelected: (_) {},
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.go('/result', extra: <String, dynamic>{
                'score': 7,
                'total': 10,
                'categoryId': categoryId,
              }),
              child: const Text('Valider et voir le résultat'),
            ),
          ],
        ),
      ),
    );
  }
}
