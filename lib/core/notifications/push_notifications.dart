import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Notifications push via Firebase Cloud Messaging (projet Firebase
/// « notifquizz »). Android lit sa configuration dans
/// `android/app/google-services.json`.
///
/// Le jeton de l'appareil est envoyé au backend (`POST /v1/devices`), qui
/// envoie les notifications : défi reçu, demande d'ami reçue ou acceptée.
///
/// App fermée ou en arrière-plan, le système les affiche lui-même. Au premier
/// plan, Firebase ne les transmet qu'à l'app : sur Android, elle les publie
/// alors dans le volet via flutter_local_notifications ; sur iOS, les options
/// de présentation suffisent. Pendant une partie, elles arrivent sans bannière
/// ni son pour ne pas masquer le minuteur.
class PushNotifications {
  PushNotifications._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final Completer<void> _initialMessageChecked = Completer<void>();
  static String? _pendingInitialLocation;
  static String? _registrationId;

  /// Canal Android partagé avec les notifications reçues app fermée (voir
  /// `default_notification_channel_id` dans AndroidManifest.xml). Une fois créé
  /// sur un appareil, seul le joueur peut en changer l'importance.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'defis_amis',
    'Défis et amis',
    description: "Défis reçus, demandes d'ami et demandes acceptées.",
    importance: Importance.high,
  );

  /// Initialise Firebase, demande l'autorisation d'afficher des notifications
  /// (Android 13 et plus) et enregistre l'appareil si le joueur est connecté.
  ///
  /// N'échoue jamais : sans Google Play Services, sans réseau ou sur iOS (pas
  /// encore configuré), l'app continue de fonctionner sans notifications.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final String? localLaunchLocation = await _initLocalNotifications();
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);

      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      _pendingInitialLocation =
          targetForData(initialMessage?.data) ?? localLaunchLocation;
      if (!_initialMessageChecked.isCompleted) {
        _initialMessageChecked.complete();
      }

      messaging.onRegistered.listen((String registrationId) {
        _registrationId = registrationId;
        if (kDebugMode) {
          debugPrint('[FCM] identifiant d\'installation : $registrationId');
        }
        unawaited(_sendToBackend(registrationId));
      });
      await messaging.register();
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

  /// Écrans de partie chronométrée, où une bannière masquerait le minuteur.
  @visibleForTesting
  static bool isPlayingLocation(String? location) {
    if (location == null) return false;
    return location == '/campaign/quiz' ||
        location.startsWith('/quiz/') ||
        location.startsWith('/challenge/');
  }

  /// Prépare l'affichage des notifications au premier plan (Android seulement)
  /// et retourne la destination de celle qui a lancé l'app, s'il y en a une.
  /// Un échec ici n'empêche pas l'enregistrement de l'appareil.
  static Future<String?> _initLocalNotifications() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final String? location = response.payload;
          if (location != null) _navigate(location);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      final NotificationAppLaunchDetails? launch =
          await _local.getNotificationAppLaunchDetails();
      if (launch == null || !launch.didNotificationLaunchApp) return null;
      return launch.notificationResponse?.payload;
    } catch (error) {
      debugPrint('[FCM] affichage au premier plan indisponible : $error');
      return null;
    }
  }

  static Future<void> _showForegroundMessage(RemoteMessage message) async {
    // Sans bloc « notification », c'est un simple signal de données : rien
    // n'est affiché, comme en arrière-plan. Sur iOS, le système s'en charge.
    final RemoteNotification? notification = message.notification;
    if (notification == null ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _local.show(
        id: (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
                .hashCode &
            0x7fffffff,
        title: notification.title ?? 'IvoireQuiz',
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            color: AppColors.orange,
            // Pendant une partie : dans le volet seulement, sans bannière
            // ni son.
            silent: isPlayingLocation(_currentLocation()),
          ),
        ),
        payload: targetForData(message.data),
      );
    } catch (error) {
      debugPrint('[FCM] notification non affichée : $error');
    }
  }

  static String? _currentLocation() {
    final BuildContext? context = appNavigatorKey.currentContext;
    if (context == null) return null;
    return GoRouter.of(context).state.matchedLocation;
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
      final String registrationId = await _getRegistrationId();
      await _sendToBackend(registrationId);
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
      if (authToken == null || authToken.isEmpty) return;
      final String registrationId = await _getRegistrationId();
      await ApiConfig.createDio(authToken: authToken).delete<dynamic>(
        '/v1/devices',
        data: <String, String>{'token': registrationId},
      );
      await FirebaseMessaging.instance.unregister();
      _registrationId = null;
    } catch (error) {
      debugPrint('[FCM] appareil non retiré : $error');
    }
  }

  static Future<String> _getRegistrationId() async {
    final String? current = _registrationId;
    if (current != null) return current;

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final Future<String> registered = messaging.onRegistered.first.timeout(
      const Duration(seconds: 15),
    );
    await messaging.register();
    final String registrationId = await registered;
    _registrationId = registrationId;
    return registrationId;
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
