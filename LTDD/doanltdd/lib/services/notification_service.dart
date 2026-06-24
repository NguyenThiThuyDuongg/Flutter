import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Gửi thông báo vào collection 'notifications'
  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    await _db.collection('notifications').add({
      'toUserId': toUserId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream thông báo của user
  Stream<List<Map<String, dynamic>>> getMyNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // Đếm thông báo chưa đọc
  Stream<int> getUnreadCount(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}