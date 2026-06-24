import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/bookmark_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/job_model.dart';
import 'job_detail_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final bookmarkService = BookmarkService();
    final uid = auth.userModel!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Việc làm đã lưu')),
      body: StreamBuilder<List<String>>(
        stream: bookmarkService.getBookmarkedJobIds(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobIds = snap.data ?? [];

          if (jobIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có việc làm nào được lưu',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn biểu tượng bookmark khi xem việc làm để lưu lại',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobIds.length,
            itemBuilder: (_, i) => _SavedJobCard(
              jobId: jobIds[i],
              uid: uid,
              bookmarkService: bookmarkService,
            ),
          );
        },
      ),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  final String jobId;
  final String uid;
  final BookmarkService bookmarkService;

  const _SavedJobCard({
    required this.jobId,
    required this.uid,
    required this.bookmarkService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Đang tải...'),
            ),
          );
        }

        if (!snap.data!.exists) {
          return const SizedBox.shrink(); // Job đã bị xóa
        }

        final job = JobModel.fromMap(
          snap.data!.data() as Map<String, dynamic>,
          snap.data!.id,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: job)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1E88E5),
                    child: Text(
                      job.company.isNotEmpty
                          ? job.company[0].toUpperCase()
                          : 'J',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(job.company,
                            style:
                                TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            _tag(Icons.location_on, job.location,
                                Colors.red),
                            _tag(Icons.attach_money, job.salary,
                                Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Nút xóa bookmark
                  IconButton(
                    icon: const Icon(Icons.bookmark,
                        color: Color(0xFF1E88E5)),
                    tooltip: 'Bỏ lưu',
                    onPressed: () async {
                      await bookmarkService.toggleBookmark(uid, jobId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã bỏ lưu việc làm'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}