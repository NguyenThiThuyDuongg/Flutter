import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Handler cho background message (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init(String uid) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied');
      return;
    }

    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    _fcm.onTokenRefresh.listen((newToken) {
      _saveToken(uid, newToken);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// FIX #10: Wrap deleteToken trong try-catch riêng
  /// để đảm bảo Firestore vẫn được update dù deleteToken thất bại
  Future<void> clearToken(String uid) async {
    try {
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('FCM deleteToken error (ignored): $e');
    }
    // Luôn xóa token trong Firestore dù deleteToken có lỗi hay không
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Firestore clearToken error: $e');
    }
  }
}