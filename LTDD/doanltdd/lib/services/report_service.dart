import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> reportJob({
    required String jobId,
    required String jobTitle,
    required String reporterId,
    required String reason,
  }) async {
    // Kiểm tra đã báo cáo chưa
    final existing = await _db
        .collection('reports')
        .where('jobId', isEqualTo: jobId)
        .where('reporterId', isEqualTo: reporterId)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Bạn đã báo cáo tin này rồi');
    }
    await _db.collection('reports').add({
      'jobId': jobId,
      'jobTitle': jobTitle,
      'reporterId': reporterId,
      'reason': reason,
      'status': 'pending', // pending, resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getAllReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> resolveReport(String reportId) async {
    await _db
        .collection('reports')
        .doc(reportId)
        .update({'status': 'resolved'});
  }

  Future<void> deleteReport(String reportId) async {
    await _db.collection('reports').doc(reportId).delete();
  }
}