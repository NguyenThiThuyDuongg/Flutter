import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
export '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int pageSize = 10;

  // ── Stream realtime ───────────────────────────────────────────────────────

  Stream<List<JobModel>> getJobs({String? category}) {
    Query query = _db.collection('jobs');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snap) {
      final jobs = snap.docs
          .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  Stream<List<JobModel>> getJobsByEmployer(String employerId) {
    return _db
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snap) {
      final jobs = snap.docs
          .map((d) => JobModel.fromMap(d.data(), d.id))
          .toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  Future<({List<JobModel> jobs, DocumentSnapshot? lastDoc, bool hasMore})>
      getJobsPaginated({
    String? category,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _db.collection('jobs').orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = _db
          .collection('jobs')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(pageSize);

    final snap = await query.get();
    final jobs = snap.docs
        .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    return (
      jobs: jobs,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length >= pageSize,
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addJob(JobModel job) async {
    await _db.collection('jobs').add(job.toMap());
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await _db.collection('jobs').doc(jobId).update(data);
  }

  Future<void> deleteJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).delete();
  }

  // ── Applications ──────────────────────────────────────────────────────────

  Future<void> applyJob(
      String jobId, String candidateId, String candidateName) async {
    final existing = await _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('candidateId', isEqualTo: candidateId)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Bạn đã ứng tuyển công việc này rồi');
    }
    await _db.collection('applications').add({
      'jobId': jobId,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMyApplications(String candidateId) {
    return _db
        .collection('applications')
        .where('candidateId', isEqualTo: candidateId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> getApplicationsByJob(String jobId) {
    return _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    await _db
        .collection('applications')
        .doc(applicationId)
        .update({'status': status});
  }
}