import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../models/job_model.dart';
import '../../models/filter_model.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';
import 'saved_jobs_screen.dart';
import 'profile_screen.dart';
import 'filter_sheet.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../auth/login_screen.dart';

class CandidateHomeScreen extends StatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  State<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends State<CandidateHomeScreen> {
  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notifService = NotificationService();
  String _keyword = '';
  String _locationFilter = '';
  JobFilter _activeFilter = const JobFilter();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().userModel?.uid;
      if (uid != null) FcmService().init(uid);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _openFilter() async {
    final result = await showModalBottomSheet<JobFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterSheet(current: _activeFilter),
    );
    if (result != null) {
      setState(() => _activeFilter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final jobVM = context.watch<JobViewModel>();
    final uid = auth.userModel?.uid ?? '';

    final pages = [
      _buildJobList(auth, jobVM, uid),
      const MyApplicationsScreen(),
      const SavedJobsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Tìm việc'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Đơn của tôi'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'Đã lưu'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Tin nhắn'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildJobList(AuthViewModel auth, JobViewModel jobVM, String uid) {
    final hasFilter = !_activeFilter.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tìm việc làm',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Xin chào, ${auth.userModel?.fullName ?? ''}!',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // Nút filter nâng cao
          Stack(
            children: [
              IconButton(
                icon: Icon(hasFilter ? Icons.filter_alt : Icons.filter_alt_outlined),
                tooltip: 'Bộ lọc nâng cao',
                onPressed: _openFilter,
              ),
              if (hasFilter)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Nút thông báo
          StreamBuilder<int>(
            stream: _notifService.getUnreadCount(uid),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Nút đăng xuất
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
                final uid = auth.userModel?.uid;
                if (uid != null) await FcmService().clearToken(uid);
                await auth.logout();
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
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm việc làm, công ty...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _keyword = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _keyword = v.trim().toLowerCase()),
            ),
          ),
          // Location filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: 'Lọc theo địa điểm (VD: Hồ Chí Minh)',
                prefixIcon: const Icon(Icons.location_on, size: 20),
                suffixIcon: _locationFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _locationCtrl.clear();
                          setState(() => _locationFilter = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _locationFilter = v.trim().toLowerCase()),
            ),
          ),
          // Active filter chips
          if (hasFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (_activeFilter.experience != null)
                          _filterChip(_activeFilter.experience!, () {
                            setState(() => _activeFilter =
                                JobFilter(contractType: _activeFilter.contractType));
                          }),
                        if (_activeFilter.contractType != null)
                          _filterChip(_activeFilter.contractType!, () {
                            setState(() => _activeFilter =
                                JobFilter(experience: _activeFilter.experience));
                          }),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _activeFilter = const JobFilter()),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('Xóa tất cả',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          // Category chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: jobVM.categories.length,
              itemBuilder: (_, i) {
                final cat = jobVM.categories[i];
                final selected = jobVM.selectedCategory == cat ||
                    (jobVM.selectedCategory.isEmpty && cat == 'Tất cả');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        jobVM.setCategory(cat == 'Tất cả' ? '' : cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // Job list
          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: jobVM.getJobs(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var jobs = snap.data ?? [];

                // 1. Filter keyword — tìm trong title, company, description, category
                if (_keyword.isNotEmpty) {
                  jobs = jobs.where((j) {
                    return j.title.toLowerCase().contains(_keyword) ||
                        j.company.toLowerCase().contains(_keyword) ||
                        j.description.toLowerCase().contains(_keyword) ||
                        j.category.toLowerCase().contains(_keyword);
                  }).toList();
                }

                // 2. Filter location
                if (_locationFilter.isNotEmpty) {
                  jobs = jobs
                      .where((j) =>
                          j.location.toLowerCase().contains(_locationFilter))
                      .toList();
                }

                // 3. Filter nâng cao — job không có field sẽ bị loại
                if (!_activeFilter.isEmpty) {
                  jobs = jobs.where((j) {
                    if (_activeFilter.experience != null) {
                      if (j.experience == null || j.experience!.isEmpty) {
                        return false;
                      }
                      if (j.experience != _activeFilter.experience) {
                        return false;
                      }
                    }
                    if (_activeFilter.contractType != null) {
                      if (j.contractType == null || j.contractType!.isEmpty) {
                        return false;
                      }
                      if (j.contractType != _activeFilter.contractType) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();
                }

                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _keyword.isNotEmpty || _locationFilter.isNotEmpty || hasFilter
                              ? 'Không tìm thấy việc làm phù hợp'
                              : 'Chưa có tin tuyển dụng nào',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        if (hasFilter || _keyword.isNotEmpty || _locationFilter.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              _locationCtrl.clear();
                              setState(() {
                                _keyword = '';
                                _locationFilter = '';
                                _activeFilter = const JobFilter();
                              });
                            },
                            child: const Text('Xóa tất cả bộ lọc'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _JobCard(job: jobs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.orange)),
      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.orange),
      onDeleted: onRemove,
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      side: const BorderSide(color: Colors.orange),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1E88E5),
                child: Text(
                  job.company.isNotEmpty ? job.company[0].toUpperCase() : 'J',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(job.company,
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _tag(Icons.location_on, job.location, Colors.red),
                        _tag(Icons.attach_money, job.salary, Colors.green),
                        if (job.experience != null && job.experience!.isNotEmpty)
                          _tag(Icons.work_history_outlined,
                              job.experience!, Colors.purple),
                        if (job.contractType != null && job.contractType!.isNotEmpty)
                          _tag(Icons.description_outlined,
                              job.contractType!, Colors.teal),
                        _tag(Icons.access_time, _timeAgo(job.createdAt), Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(job.category, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.shade50,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}