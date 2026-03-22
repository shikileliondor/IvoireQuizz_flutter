import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_LeaderEntry> entries = <_LeaderEntry>[
      const _LeaderEntry(name: 'Aminata', points: 1280),
      const _LeaderEntry(name: 'Yao', points: 1170),
      const _LeaderEntry(name: 'Kouassi', points: 1090),
      const _LeaderEntry(name: 'Toi', points: 980),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Classement')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final _LeaderEntry entry = entries[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('#${index + 1}')),
              title: Text(entry.name),
              subtitle: Text('${entry.points} points'),
              trailing: index == 3 ? const Icon(Icons.person, color: Colors.orange) : null,
            ),
          );
        },
      ),
    );
  }
}

class _LeaderEntry {
  const _LeaderEntry({required this.name, required this.points});

  final String name;
  final int points;
}
