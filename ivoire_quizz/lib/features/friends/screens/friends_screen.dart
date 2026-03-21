import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> friends = <String>['Fatou', 'Kader', 'Mariame', 'Ismaël'];

    return Scaffold(
      appBar: AppBar(title: const Text('Amis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ajouter'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (BuildContext context, int index) {
          final String name = friends[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.gold,
                child: Text(name.characters.first),
              ),
              title: Text(name),
              subtitle: const Text('En ligne récemment'),
              trailing: FilledButton.tonal(
                onPressed: () {},
                child: const Text('Défier'),
              ),
            ),
          );
        },
      ),
    );
  }
}
