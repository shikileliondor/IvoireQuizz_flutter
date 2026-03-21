import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Quiz du jour',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('10 questions pour tester ta culture ivoirienne.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/quiz/1/daily'),
                    child: const Text('Commencer'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CategoryTile(
            title: 'Histoire',
            subtitle: 'Rois, indépendance, grands moments',
            icon: Icons.menu_book_rounded,
            onTap: () => context.go('/quiz/2/classic'),
          ),
          _CategoryTile(
            title: 'Géographie',
            subtitle: 'Villes, régions et monuments',
            icon: Icons.public,
            onTap: () => context.go('/quiz/3/classic'),
          ),
          _CategoryTile(
            title: 'Gastronomie',
            subtitle: 'Saveurs et plats traditionnels',
            icon: Icons.restaurant,
            onTap: () => context.go('/quiz/4/classic'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.orange.withOpacity(0.1),
          child: Icon(icon, color: AppColors.orange),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
