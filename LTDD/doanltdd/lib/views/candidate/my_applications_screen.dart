import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final Map<String, Map<String, dynamic>?> _jobCache = {};

  Future<Map<String, dynamic>?> _getJobInfo(String jobId) async {
    if (_jobCache.containsKey(jobId)) return _jobCache[jobId];
    final doc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .get();
    _jobCache[jobId] = doc.exists ? doc.data() : null;
    return _jobCache[jobId];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted': return 'Đã duyệt';
      case 'rejected': return 'Từ chối';
      default: return 'Chờ duyệt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final jobVM = context.read<JobViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn ứng tuyển của tôi')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: jobVM.getMyApplications(auth.userModel!.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snap.data ?? [];
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Bạn chưa ứng tuyển công việc nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final app = apps[i];
              final status = app['status'] ?? 'pending';
              final appliedDate = (app['appliedAt'] as dynamic)
                  ?.toDate()
                  .toString()
                  .substring(0, 10) ?? '';

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getJobInfo(app['jobId'] ?? ''),
                builder: (context, jobSnap) {
                  final jobTitle = jobSnap.data?['title'] ?? 'Đang tải...';
                  final company = jobSnap.data?['company'] ?? '';
                  final category = jobSnap.data?['category'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1E88E5),
                        child: Text(
                          company.isNotEmpty ? company[0].toUpperCase() : 'J',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(jobTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (company.isNotEmpty) Text(company),
                          if (category.isNotEmpty)
                            Text(category,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          Text('Ngày nộp: $appliedDate',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _statusColor(status).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}