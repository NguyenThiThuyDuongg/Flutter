import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../services/bookmark_service.dart';
import '../../services/report_service.dart';
import '../chat/chat_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  void _showReportDialog(BuildContext context, String uid) {
    String? selectedReason;
    final reasons = [
      'Tin tuyển dụng giả mạo',
      'Nội dung không phù hợp',
      'Lừa đảo / Scam',
      'Thông tin sai lệch',
      'Khác',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Báo cáo tin tuyển dụng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lý do báo cáo tin "${job.title}":',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) =>
                        setDialogState(() => selectedReason = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await ReportService().reportJob(
                          jobId: job.id,
                          jobTitle: job.title,
                          reporterId: uid,
                          reason: selectedReason!,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Đã gửi báo cáo, cảm ơn bạn!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e
                                  .toString()
                                  .replaceAll('Exception: ', '')),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Gửi báo cáo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final jobVM = context.read<JobViewModel>();
    final bookmarkService = BookmarkService();
    final uid = auth.userModel!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
        actions: [
          // Nút bookmark
          StreamBuilder<List<String>>(
            stream: bookmarkService.getBookmarkedJobIds(uid),
            builder: (context, snap) {
              final ids = snap.data ?? [];
              final isSaved = ids.contains(job.id);
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                tooltip: isSaved ? 'Bỏ lưu' : 'Lưu việc làm',
                onPressed: () async {
                  await bookmarkService.toggleBookmark(uid, job.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSaved
                            ? 'Đã bỏ lưu việc làm'
                            : 'Đã lưu việc làm'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
          // Nút báo cáo
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            tooltip: 'Báo cáo tin này',
            onPressed: () => _showReportDialog(context, uid),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF1E88E5),
                      child: Text(
                        job.company.isNotEmpty
                            ? job.company[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(job.company,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard([
              _infoRow(Icons.location_on, 'Địa điểm', job.location,
                  Colors.red),
              _infoRow(Icons.attach_money, 'Mức lương', job.salary,
                  Colors.green),
              _infoRow(Icons.category, 'Ngành nghề', job.category,
                  Colors.blue),
              if (job.experience != null && job.experience!.isNotEmpty)
                _infoRow(Icons.work_history_outlined, 'Kinh nghiệm',
                    job.experience!, Colors.purple),
              if (job.contractType != null && job.contractType!.isNotEmpty)
                _infoRow(Icons.description_outlined, 'Loại hợp đồng',
                    job.contractType!, Colors.teal),
            ]),
            const SizedBox(height: 16),
            const Text('Mô tả công việc',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.description, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Ứng tuyển ngay'),
              onPressed: () async {
                try {
                  await jobVM.applyJob(
                    job.id,
                    auth.userModel!.uid,
                    auth.userModel!.fullName,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ứng tuyển thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Nhắn tin với nhà tuyển dụng'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: job.employerId,
                    otherUserName: job.company,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}