import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/game_map/models/game_map.dart';

void main() {
  test('parses the guided map projection', () {
    final map = GameMap.fromJson({
      'world': {'id': 1, 'number': 1, 'name': 'Abidjan'},
      'progress': {'percent': 25, 'completed_levels': 1, 'total_levels': 4},
      'next_playable_level_id': 12,
      'nodes': [
        {
          'node_id': 'level-11',
          'type': 'level',
          'level_id': 11,
          'title': 'Niveau 1',
          'state': 'completed'
        },
        {
          'node_id': 'chest-1',
          'type': 'chest',
          'title': 'Coffre',
          'state': 'claimable'
        },
        {
          'node_id': 'level-12',
          'type': 'level',
          'level_id': 12,
          'title': 'Niveau 2',
          'state': 'current'
        },
      ],
    });

    expect(map.world.name, 'Abidjan');
    expect(map.progressPercent, 25);
    expect(map.nextPlayable?.title, 'Niveau 2');
    expect(map.nodes[1].type, MapNodeType.chest);
    expect(map.nodes[1].levelId, isNull);
  });

  test('adapts the legacy city payload without exposing city names', () {
    final map = GameMap.fromLegacyRegions([
      {
        'id': 1,
        'name': 'Abidjan',
        'cities': [
          {
            'id': 8,
            'name': 'Cocody',
            'levels': [
              {'id': 20, 'title': 'Niveau 1', 'is_unlocked': true},
            ],
          },
        ],
      },
    ]);

    expect(map.world.name, 'Abidjan');
    expect(map.nodes.single.title, 'Niveau 1');
    expect(map.nodes.single.state, MapNodeState.current);
  });

  test('parses the official API V1 game map contract', () {
    final map = GameMap.fromJson({
      'first_time_intro': true,
      'current_region': {
        'id': 1,
        'name': 'Abidjan',
        'description': 'La perle des lagunes t’attend.',
        'progress_percent': 35,
      },
      'next_playable_level': {'id': 2, 'title': 'Plateau institutions'},
      'stats': {
        'lives': 5,
        'max_lives': 5,
        'streak': 12,
        'xp_total': 1280,
        'coins': 42,
        'gems': 3,
        'league': 'Bronze',
      },
      'path_nodes': [
        {
          'type': 'chest',
          'id': 9,
          'title': 'Coffre Bronze',
          'is_unlocked': false,
          'order': 3,
        },
        {
          'type': 'review',
          'id': 3,
          'title': 'Révision',
          'is_unlocked': false,
          'order': 4,
        },
        {
          'type': 'level',
          'id': 2,
          'title': 'Plateau institutions',
          'chapter_name': 'Plateau',
          'is_unlocked': true,
          'order': 2,
        },
        {
          'type': 'mystery',
          'id': 99,
          'title': 'Futur nœud',
          'is_unlocked': true,
          'order': 5,
        },
      ],
    });

    expect(map.firstTimeIntro, isTrue);
    expect(map.world.name, 'Abidjan');
    expect(map.world.subtitle, 'La perle des lagunes t’attend.');
    expect(map.progressPercent, 35);
    expect(map.stats.lives, 5);
    expect(map.stats.coins, 42);
    expect(map.nextPlayable?.levelId, 2);
    expect(map.nextPlayable?.state, MapNodeState.current);
    expect(map.nodes.map((node) => node.order), orderedEquals([2, 3, 4, 5]));
    expect(map.nodes[1].type, MapNodeType.chest);
    expect(map.nodes[2].type, MapNodeType.review);
    expect(map.nodes[3].type, MapNodeType.unknown);
    expect(map.nodes[3].levelId, isNull);
  });
}
