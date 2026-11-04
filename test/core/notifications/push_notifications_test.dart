import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/core/notifications/push_notifications.dart';

void main() {
  group('PushNotifications.targetForData', () {
    test('ouvre directement un défi quand son code est fourni', () {
      expect(
        PushNotifications.targetForData(
          <String, dynamic>{'type': 'challenge', 'code': 'ABC123'},
        ),
        '/challenge/ABC123',
      );
    });

    test('ouvre les amis pour une demande ou une acceptation', () {
      expect(
        PushNotifications.targetForData(
          <String, dynamic>{'type': 'friend_request'},
        ),
        '/friends',
      );
      expect(
        PushNotifications.targetForData(
          <String, dynamic>{'type': 'friend_accepted'},
        ),
        '/friends',
      );
    });

    test('retombe sur les amis si un défi ne contient pas de code', () {
      expect(
        PushNotifications.targetForData(
          <String, dynamic>{'type': 'challenge'},
        ),
        '/friends',
      );
    });

    test('ignore un type inconnu', () {
      expect(
        PushNotifications.targetForData(
          <String, dynamic>{'type': 'unknown'},
        ),
        isNull,
      );
    });
  });
}
