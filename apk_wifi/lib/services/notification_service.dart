import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('[Notification] User tapped: ${details.payload}');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'simanet_channel',
        'Notifikasi Sima.net',
        channelDescription: 'Pengingat tagihan dan status verifikasi ISP',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show error: $e');
    }
  }

  Future<void> notifyDueDate({
    required String period,
    required String amount,
    required String dueDate,
  }) async {
    await showNotification(
      id: 101,
      title: '⚠️ Pengingat Tagihan Sima.net ($period)',
      body: 'Tagihan internet sebesar $amount jatuh tempo pada $dueDate. Mohon segera lakukan pembayaran.',
    );
  }

  Future<void> notifyPaymentVerified({required String invoicePeriod}) async {
    await showNotification(
      id: 202,
      title: '✅ Pembayaran Diverifikasi & Dicatat ke Ledger!',
      body: 'Pembayaran tagihan $invoicePeriod telah diverifikasi admin dan tercatat permanen di blockchain SHA-256.',
    );
  }
}
