import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _deviceIdKey = 'push_device_id';
  static const _channelId = 'special_remarks';
  static const _channelName = 'Special Remarks';
  static const openActionId = 'open_special_remarks';

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _ready = false;
  bool _initializing = false;
  bool _tapsBound = false;

  bool get isReady => _ready;

  Future<void> initialize() async {
    if (_ready || kIsWeb) return;
    if (_initializing) {
      while (_initializing && !_ready) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _initializing = true;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final darwinCategory = DarwinNotificationCategory(
        _channelId,
        actions: [
          DarwinNotificationAction.plain(openActionId, 'Open'),
        ],
      );

      await _local.initialize(
        InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            notificationCategories: [darwinCategory],
          ),
        ),
        onDidReceiveNotificationResponse: _onLocalTap,
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Remarks sent to your children',
        importance: Importance.high,
      );
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.requestNotificationsPermission();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForeground);

      final launched = await messaging.getInitialMessage();
      if (launched != null) {
        await NotificationRouter.instance.handleData(launched.data);
      }

      _ready = true;
    } catch (error, stack) {
      _ready = false;
      debugPrint('Push initialize failed: $error\n$stack');
    } finally {
      _initializing = false;
    }
  }

  void bindTapHandler() {
    if (_tapsBound || kIsWeb) return;
    _tapsBound = true;
    _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationRouter.instance.handleData(message.data);
    });
  }

  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey)?.trim() ?? '';
    if (existing.isNotEmpty) return existing;

    final created = _newDeviceId();
    await prefs.setString(_deviceIdKey, created);
    return created;
  }

  String platformName() {
    if (kIsWeb) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<String?> token() async {
    if (kIsWeb) return null;
    if (!_ready) {
      await initialize();
    }
    if (!_ready) return null;

    try {
      if (Platform.isIOS) {
        await _waitForApnsToken();
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('FCM getToken failed: $error');
      return null;
    }
  }

  void listenForTokenRefresh(void Function(String token) onToken) {
    if (!_ready) return;
    _tokenSub?.cancel();
    _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
  }

  Future<void> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) return;
      } catch (error) {
        debugPrint('APNs token wait failed: $error');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  void _onLocalTap(NotificationResponse response) {
    NotificationRouter.instance.handlePayload(response.payload);
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final kind = '${message.data['kind'] ?? ''}'.trim();
    final isFee = kind == NotificationRouter.kindFeeCollection ||
        kind == 'fee_receipt';
    final isAnnouncement = kind == NotificationRouter.kindAnnouncement;
    final isSalary = kind == NotificationRouter.kindSalaryPaid;
    final payload = NotificationRouter.encodePayload({
      ...message.data,
      'kind': kind.isEmpty
          ? NotificationRouter.kindSpecialRemark
          : kind,
    });

    _local.show(
      notification?.hashCode ?? message.hashCode,
      title ??
          (isFee
              ? 'Fee received'
              : isAnnouncement
                  ? 'Announcement'
                  : isSalary
                      ? 'Salary paid'
                      : 'Special Remarks'),
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Remarks sent to your children',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: [
            AndroidNotificationAction(
              openActionId,
              'Open',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _channelId,
        ),
      ),
      payload: payload,
    );
  }

  String _newDeviceId() {
    final random = Random.secure();
    String hex(int length) => List.generate(
          length,
          (_) => random.nextInt(16).toRadixString(16),
        ).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${hex(4)}-${hex(12)}';
  }
}
