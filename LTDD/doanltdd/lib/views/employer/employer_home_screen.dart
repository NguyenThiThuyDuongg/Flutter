import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../models/job_model.dart';
import 'applicants_screen.dart';
import 'edit_job_sheet.dart';
import '../chat/chat_list_screen.dart';
import '../auth/login_screen.dart';

class EmployerHomeScreen extends StatelessWidget {
  const EmployerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhà tuyển dụng',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(auth.userModel?.fullName ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Tin nhắn',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đăng xuất',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.work), text: 'Tin tuyển dụng'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Thống kê'),
            ],
          ),
        ),
        body: auth.userModel == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _JobsTab(employerId: auth.userModel!.uid),
                  _StatsTab(employerId: auth.userModel!.uid),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Đăng tin'),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const _PostJobSheet(),
          ),
        ),
      ),
    );
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final String employerId;
  const _StatsTab({required this.employerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: employerId)
          .snapshots(),
      builder: (context, jobSnap) {
        if (!jobSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = jobSnap.data!.docs;
        final totalJobs = jobs.length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .snapshots(),
          builder: (context, appSnap) {
            if (!appSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allApps = appSnap.data!.docs;
            final jobIds = jobs.map((j) => j.id).toSet();

            // Lọc applications thuộc về employer này
            final myApps = allApps
                .where((a) =>
                    jobIds.contains((a.data() as Map)['jobId']))
                .toList();

            final totalApps = myApps.length;
            final pending = myApps
                .where((a) =>
                    (a.data() as Map)['status'] == 'pending')
                .length;
            final accepted = myApps
                .where((a) =>
                    (a.data() as Map)['status'] == 'accepted')
                .length;
            final rejected = myApps
                .where((a) =>
                    (a.data() as Map)['status'] == 'rejected')
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng quan',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Row 1: Tổng tin, tổng đơn
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: totalJobs,
                          label: 'Tin tuyển dụng',
                          icon: Icons.work,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: totalApps,
                          label: 'Tổng đơn ứng tuyển',
                          icon: Icons.assignment,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Trạng thái đơn
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: pending,
                          label: 'Chờ duyệt',
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                          small: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: accepted,
                          label: 'Đã duyệt',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          small: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: rejected,
                          label: 'Từ chối',
                          icon: Icons.cancel,
                          color: Colors.red,
                          small: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Số đơn theo từng tin',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Danh sách từng tin + số đơn
                  ...jobs.map((jobDoc) {
                    final jobData =
                        jobDoc.data() as Map<String, dynamic>;
                    final jobAppCount = myApps
                        .where((a) =>
                            (a.data() as Map)['jobId'] == jobDoc.id)
                        .length;
                    final pendingCount = myApps
                        .where((a) =>
                            (a.data() as Map)['jobId'] == jobDoc.id &&
                            (a.data() as Map)['status'] == 'pending')
                        .length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                (jobData['company'] ?? 'C')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(jobData['title'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(jobData['category'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5)
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$jobAppCount đơn',
                                    style: const TextStyle(
                                        color: Color(0xFF1E88E5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pendingCount chờ duyệt',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final bool small;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(small ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: small ? 24 : 32),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: small ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Jobs Tab ──────────────────────────────────────────────────────────────

class _JobsTab extends StatelessWidget {
  final String employerId;
  const _JobsTab({required this.employerId});

  @override
  Widget build(BuildContext context) {
    final jobVM = context.watch<JobViewModel>();

    return StreamBuilder<List<JobModel>>(
      stream: jobVM.getJobsByEmployer(employerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snap.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Chưa có tin tuyển dụng nào',
                    style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text('Nhấn nút + bên dưới để đăng tin',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: jobs.length,
          itemBuilder: (_, i) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  jobs[i].company.isNotEmpty
                      ? jobs[i].company[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(jobs[i].title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${jobs[i].location} • ${jobs[i].salary}'),
                  Text(jobs[i].category,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  if (jobs[i].experience != null)
                    Text(jobs[i].experience!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.purple)),
                  if (jobs[i].contractType != null)
                    Text(jobs[i].contractType!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.teal)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.orange),
                    tooltip: 'Chỉnh sửa',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      builder: (_) => EditJobSheet(job: jobs[i]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    tooltip: 'Xóa tin',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: Text(
                              'Bạn có chắc muốn xóa tin "${jobs[i].title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Xóa',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await jobVM.deleteJob(jobs[i].id);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.people_outline,
                        color: Color(0xFF1E88E5)),
                    tooltip: 'Xem ứng viên',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicantsScreen(
                          jobId: jobs[i].id,
                          jobTitle: jobs[i].title,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Post Job Sheet ────────────────────────────────────────────────────────

class _PostJobSheet extends StatefulWidget {
  const _PostJobSheet();

  @override
  State<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<_PostJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'IT';
  String? _experience;
  String? _contractType;
  bool _loading = false;

  final List<String> _categories = [
    'IT', 'Marketing', 'Kế toán', 'Kinh doanh', 'Thiết kế', 'Khác'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _salaryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthViewModel>();
    final jobVM = context.read<JobViewModel>();
    await jobVM.addJob(JobModel(
      id: '',
      title: _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      salary: _salaryCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      employerId: auth.userModel!.uid,
      createdAt: DateTime.now(),
      experience: _experience,
      contractType: _contractType,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đăng tin tuyển dụng',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên vị trí *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên vị trí'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tên công ty *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên công ty'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration:
                    const InputDecoration(labelText: 'Địa điểm *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập địa điểm'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mức lương (VD: 10-15 triệu) *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập mức lương'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration:
                    const InputDecoration(labelText: 'Ngành nghề'),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _experience,
                decoration: const InputDecoration(
                  labelText: 'Kinh nghiệm',
                  prefixIcon: Icon(Icons.work_history_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Không chọn')),
                  ...['Không yêu cầu', 'Dưới 1 năm', '1-2 năm', '3-5 năm', '5+ năm']
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e))),
                ],
                onChanged: (v) => setState(() => _experience = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _contractType,
                decoration: const InputDecoration(
                  labelText: 'Loại hợp đồng',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Không chọn')),
                  ...['Toàn thời gian', 'Bán thời gian', 'Thực tập', 'Remote', 'Freelance']
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e))),
                ],
                onChanged: (v) => setState(() => _contractType = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mô tả công việc *'),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập mô tả công việc'
                    : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Đăng tin'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}