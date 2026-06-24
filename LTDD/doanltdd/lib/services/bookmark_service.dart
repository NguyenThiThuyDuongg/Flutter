import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<String>> getBookmarkedJobIds(String uid) {
    return _db
        .collection('bookmarks')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists
            ? List<String>.from(doc.data()?['jobIds'] ?? [])
            : <String>[]);
  }

  // FIX #8: Dùng Firestore transaction để tránh race condition
  // khi 2 thao tác toggle xảy ra đồng thời
  Future<void> toggleBookmark(String uid, String jobId) async {
    final ref = _db.collection('bookmarks').doc(uid);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      final List<String> current =
          doc.exists ? List<String>.from(doc.data()?['jobIds'] ?? []) : [];
      if (current.contains(jobId)) {
        current.remove(jobId);
      } else {
        current.add(jobId);
      }
      transaction.set(ref, {'jobIds': current});
    });
  }

  Future<bool> isBookmarked(String uid, String jobId) async {
    final doc = await _db.collection('bookmarks').doc(uid).get();
    if (!doc.exists) return false;
    return List<String>.from(doc.data()?['jobIds'] ?? []).contains(jobId);
  }
}