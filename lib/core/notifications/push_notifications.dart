import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../router/app_router.dart';

/// Notifications push via Firebase Cloud Messaging (projet Firebase
/// « notifquizz »). Android lit sa configuration dans
/// `android/app/google-services.json`.
///
/// Le jeton de l'appareil est envoyé au backend (`POST /v1/devices`), qui
/// envoie les notifications : défi reçu, demande d'ami reçue ou acceptée.
/// Elles s'affichent quand l'app est fermée ou en arrière-plan ; au premier
/// plan, rien n'est encore affiché.
class PushNotifications {
  PushNotifications._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Completer<void> _initialMessageChecked = Completer<void>();
  static String? _pendingInitialLocation;

  /// Initialise Firebase, demande l'autorisation d'afficher des notifications
  /// (Android 13 et plus) et enregistre l'appareil si le joueur est connecté.
  ///
  /// N'échoue jamais : sans Google Play Services, sans réseau ou sur iOS (pas
  /// encore configuré), l'app continue de fonctionner sans notifications.
  static Future<void> init({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    try {
      await Firebase.initializeApp();
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) => _showForegroundMessage(
          message,
          messengerKey,
        ),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);

      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      _pendingInitialLocation = targetForData(initialMessage?.data);
      if (!_initialMessageChecked.isCompleted) {
        _initialMessageChecked.complete();
      }

      final String? token = await messaging.getToken();
      if (kDebugMode) debugPrint('[FCM] jeton : $token');
      if (token != null) await _sendToBackend(token);
      messaging.onTokenRefresh.listen(_sendToBackend);
    } catch (error) {
      if (!_initialMessageChecked.isCompleted) {
        _initialMessageChecked.complete();
      }
      debugPrint('[FCM] notifications indisponibles : $error');
    }
  }

  /// Attend brièvement que Firebase indique si une notification a lancé l'app.
  static Future<void> waitUntilInitialMessageChecked() async {
    await _initialMessageChecked.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  }

  /// Retourne la destination d'une notification ayant lancé l'application.
  /// Le splash la consomme après avoir vérifié que le joueur est connecté.
  static String? takeInitialLocation() {
    final String? location = _pendingInitialLocation;
    _pendingInitialLocation = null;
    return location;
  }

  /// Traduit les données FCM envoyées par Laravel en route Flutter.
  @visibleForTesting
  static String? targetForData(Map<String, dynamic>? data) {
    if (data == null) return null;

    switch (data['type']?.toString()) {
      case 'challenge':
        final String code = data['code']?.toString().trim() ?? '';
        return code.isEmpty
            ? '/friends'
            : '/challenge/${Uri.encodeComponent(code)}';
      case 'friend_request':
      case 'friend_accepted':
        return '/friends';
      default:
        return null;
    }
  }

  static void _showForegroundMessage(
    RemoteMessage message,
    GlobalKey<ScaffoldMessengerState> messengerKey,
  ) {
    final String? location = targetForData(message.data);
    final RemoteNotification? notification = message.notification;
    final String title = notification?.title ?? 'IvoireQuiz';
    final String body =
        notification?.body ?? 'Tu as une nouvelle notification.';
    final ScaffoldMessengerState? messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(body),
            ],
          ),
          action: location == null
              ? null
              : SnackBarAction(
                  label: 'Voir',
                  onPressed: () => _navigate(location),
                ),
        ),
      );
  }

  static void _openMessage(RemoteMessage message) {
    final String? location = targetForData(message.data);
    if (location != null) _navigate(location);
  }

  static void _navigate(String location) {
    final BuildContext? context = appNavigatorKey.currentContext;
    if (context == null) {
      _pendingInitialLocation = location;
      return;
    }
    GoRouter.of(context).go(location);
  }

  /// À appeler juste après une connexion : rattache cet appareil au compte.
  static Future<void> registerDevice() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToBackend(token);
    } catch (error) {
      debugPrint('[FCM] appareil non enregistré : $error');
    }
  }

  /// À appeler avant la déconnexion, tant que le jeton de connexion est
  /// encore valide : le joueur ne reçoit plus de notifications sur cet appareil.
  static Future<void> unregisterDevice() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final String? authToken = await _storage.read(key: 'auth_token');
      final String? token = await FirebaseMessaging.instance.getToken();
      if (authToken == null || authToken.isEmpty || token == null) return;
      await ApiConfig.createDio(authToken: authToken).delete<dynamic>(
        '/v1/devices',
        data: <String, String>{'token': token},
      );
    } catch (error) {
      debugPrint('[FCM] appareil non retiré : $error');
    }
  }

  static Future<void> _sendToBackend(String token) async {
    try {
      final String? authToken = await _storage.read(key: 'auth_token');
      if (authToken == null || authToken.isEmpty) return;
      await ApiConfig.createDio(authToken: authToken).post<dynamic>(
        '/v1/devices',
        data: <String, String>{
          'token': token,
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
    } catch (error) {
      debugPrint('[FCM] appareil non enregistré : $error');
    }
  }
}
