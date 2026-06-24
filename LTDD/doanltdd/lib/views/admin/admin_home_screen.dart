import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import '../../services/report_service.dart';
import '../../services/notification_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị viên'),
          actions: [
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
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthViewModel>().logout();
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
              Tab(text: 'Thống kê'),
              Tab(text: 'Người dùng'),
              Tab(text: 'Tin tuyển dụng'),
              Tab(text: 'Báo cáo'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_StatsTab(), _UsersTab(), _JobsTab(), _ReportsTab()],
        ),
      ),
    );
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  Stream<int> _countStream(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> _countByRole(String role) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> _countByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  stream: _countStream('users'),
                  label: 'Người dùng',
                  icon: Icons.people,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countStream('jobs'),
                  label: 'Tin tuyển dụng',
                  icon: Icons.work,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countStream('applications'),
                  label: 'Đơn ứng tuyển',
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Người dùng theo vai trò',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  stream: _countByRole('candidate'),
                  label: 'Ứng viên',
                  icon: Icons.person,
                  color: const Color(0xFF1E88E5),
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByRole('employer'),
                  label: 'Nhà tuyển dụng',
                  icon: Icons.business,
                  color: Colors.green,
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByRole('admin'),
                  label: 'Admin',
                  icon: Icons.admin_panel_settings,
                  color: Colors.red,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Đơn ứng tuyển theo trạng thái',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  stream: _countByStatus('pending'),
                  label: 'Chờ duyệt',
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByStatus('accepted'),
                  label: 'Đã duyệt',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  small: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  stream: _countByStatus('rejected'),
                  label: 'Từ chối',
                  icon: Icons.cancel,
                  color: Colors.red,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Hoạt động gần đây',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Text('Chưa có tin tuyển dụng nào');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '5 tin tuyển dụng mới nhất',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as dynamic)?.toDate();
                    final timeStr = createdAt != null
                        ? _timeAgo(createdAt)
                        : '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(
                          Icons.work,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        data['title'] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        data['company'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }
}

class _StatCard extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  final IconData icon;
  final Color color;
  final bool small;

  const _StatCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
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
                '$count',
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
      },
    );
  }
}

// ── Users Tab ─────────────────────────────────────────────────────────────

/// Filter + sort state for the Users tab.
enum _UserRoleFilter { all, candidate, employer }

enum _UserStatusFilter { all, active, blocked }

enum _UserSort { az, za, newest }

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _UserRoleFilter _roleFilter = _UserRoleFilter.all;
  _UserStatusFilter _statusFilter = _UserStatusFilter.all;
  _UserSort _sort = _UserSort.az;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    final query = _searchQuery.toLowerCase().trim();

    var filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['fullName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? 'candidate').toString();
      final isBlocked = data['isBlocked'] == true;

      // Search by name or email
      if (query.isNotEmpty && !name.contains(query) && !email.contains(query)) {
        return false;
      }

      // Role filter
      if (_roleFilter == _UserRoleFilter.candidate && role != 'candidate') {
        return false;
      }
      if (_roleFilter == _UserRoleFilter.employer && role != 'employer') {
        return false;
      }

      // Status filter
      if (_statusFilter == _UserStatusFilter.active && isBlocked) return false;
      if (_statusFilter == _UserStatusFilter.blocked && !isBlocked) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aName = (aData['fullName'] ?? '').toString().toLowerCase();
      final bName = (bData['fullName'] ?? '').toString().toLowerCase();
      if (_sort == _UserSort.az) return aName.compareTo(bName);
      if (_sort == _UserSort.za) return bName.compareTo(aName);
      return 0; // newest: keep Firestore order
    });

    return filtered;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sắp xếp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _SortTile(
              label: 'Tên A → Z',
              icon: Icons.sort_by_alpha,
              selected: _sort == _UserSort.az,
              onTap: () {
                setState(() => _sort = _UserSort.az);
                Navigator.pop(context);
              },
            ),
            _SortTile(
              label: 'Tên Z → A',
              icon: Icons.sort_by_alpha,
              iconFlip: true,
              selected: _sort == _UserSort.za,
              onTap: () {
                setState(() => _sort = _UserSort.za);
                Navigator.pop(context);
              },
            ),
            _SortTile(
              label: 'Mới nhất (theo Firestore)',
              icon: Icons.access_time,
              selected: _sort == _UserSort.newest,
              onTap: () {
                setState(() => _sort = _UserSort.newest);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _roleFilter != _UserRoleFilter.all ||
      _statusFilter != _UserStatusFilter.all ||
      _sort != _UserSort.az;

  void _resetFilters() {
    setState(() {
      _roleFilter = _UserRoleFilter.all;
      _statusFilter = _UserStatusFilter.all;
      _sort = _UserSort.az;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc email...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _searchCtrl.clear();
                      }),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ── Filter chips + sort button ──────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              // Role filters
              _FilterChip(
                label: 'Tất cả',
                selected: _roleFilter == _UserRoleFilter.all,
                onTap: () => setState(() => _roleFilter = _UserRoleFilter.all),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Ứng viên',
                icon: Icons.person_outline,
                selected: _roleFilter == _UserRoleFilter.candidate,
                color: Colors.blue,
                onTap: () =>
                    setState(() => _roleFilter = _UserRoleFilter.candidate),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Nhà tuyển dụng',
                icon: Icons.business_outlined,
                selected: _roleFilter == _UserRoleFilter.employer,
                color: Colors.green,
                onTap: () =>
                    setState(() => _roleFilter = _UserRoleFilter.employer),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 10),
              // Status filters
              _FilterChip(
                label: 'Đang hoạt động',
                icon: Icons.check_circle_outline,
                selected: _statusFilter == _UserStatusFilter.active,
                color: Colors.teal,
                onTap: () => setState(
                  () =>
                      _statusFilter = _statusFilter == _UserStatusFilter.active
                      ? _UserStatusFilter.all
                      : _UserStatusFilter.active,
                ),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Đã khóa',
                icon: Icons.lock_outline,
                selected: _statusFilter == _UserStatusFilter.blocked,
                color: Colors.red,
                onTap: () => setState(
                  () =>
                      _statusFilter = _statusFilter == _UserStatusFilter.blocked
                      ? _UserStatusFilter.all
                      : _UserStatusFilter.blocked,
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 10),
              // Sort button
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showSortSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sort != _UserSort.az
                        ? const Color(0xFF1E88E5).withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _sort != _UserSort.az
                          ? const Color(0xFF1E88E5)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort,
                        size: 16,
                        color: _sort != _UserSort.az
                            ? const Color(0xFF1E88E5)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sort == _UserSort.az
                            ? 'A → Z'
                            : _sort == _UserSort.za
                            ? 'Z → A'
                            : 'Mới nhất',
                        style: TextStyle(
                          fontSize: 12,
                          color: _sort != _UserSort.az
                              ? const Color(0xFF1E88E5)
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Reset button (shows only when filters active)
              if (_hasActiveFilters || _searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _resetFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── User list ───────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _applyFilters(snap.data!.docs);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Không tìm thấy người dùng nào',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      if (_hasActiveFilters || _searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Xóa bộ lọc'),
                        ),
                    ],
                  ),
                );
              }

              // Result count badge
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${filtered.length} người dùng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final data = filtered[i].data() as Map<String, dynamic>;
                        final role = data['role'] ?? 'candidate';
                        final isBlocked = data['isBlocked'] ?? false;
                        final uid = filtered[i].id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBlocked
                                  ? Colors.grey.shade400
                                  : role == 'employer'
                                  ? Colors.green
                                  : Colors.blue,
                              child: Text(
                                (data['fullName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['fullName'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isBlocked ? Colors.grey : null,
                                      decoration: isBlocked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isBlocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Đã khóa',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              data['email'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    role == 'employer'
                                        ? 'NTD'
                                        : role == 'admin'
                                        ? 'Admin'
                                        : 'UV',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: role == 'employer'
                                      ? Colors.green.shade100
                                      : role == 'admin'
                                      ? Colors.red.shade100
                                      : Colors.blue.shade100,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(
                                    isBlocked ? Icons.lock_open : Icons.lock,
                                    color: isBlocked
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: isBlocked
                                      ? 'Mở khóa'
                                      : 'Khóa tài khoản',
                                  onPressed: () async {
                                    final authVM = context
                                        .read<AuthViewModel>();
                                    if (uid == authVM.userModel?.uid) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Không thể khóa tài khoản của chính mình',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update({'isBlocked': !isBlocked});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isBlocked
                                                ? 'Đã mở khóa tài khoản'
                                                : 'Đã khóa tài khoản',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Reusable filter chip widget.
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF1E88E5);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? activeColor : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? activeColor : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sort option tile for the bottom sheet.
class _SortTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconFlip;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.iconFlip = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Transform.scale(
        scaleX: iconFlip ? -1 : 1,
        child: Icon(
          icon,
          color: selected ? const Color(0xFF1E88E5) : Colors.grey.shade600,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF1E88E5) : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF1E88E5))
          : null,
      onTap: onTap,
    );
  }
}

// ── Jobs Tab ──────────────────────────────────────────────────────────────

class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _selectedCategory = 'Tất cả';
  String _selectedLocation = 'Tất cả';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        // Lấy danh sách category
        final categories = <String>{'Tất cả'};
        final locations = <String>{'Tất cả'};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          if ((data['category'] ?? '').toString().isNotEmpty) {
            categories.add(data['category']);
          }

          if ((data['location'] ?? '').toString().isNotEmpty) {
            locations.add(data['location']);
          }
        }

        // Filter
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final title = (data['title'] ?? '').toString().toLowerCase();

          final company = (data['company'] ?? '').toString().toLowerCase();

          final category = (data['category'] ?? '').toString();

          final location = (data['location'] ?? '').toString();

          final keyword = _searchText.toLowerCase();

          final matchSearch =
              title.contains(keyword) ||
              company.contains(keyword) ||
              category.toLowerCase().contains(keyword);

          final matchCategory =
              _selectedCategory == 'Tất cả' || category == _selectedCategory;

          final matchLocation =
              _selectedLocation == 'Tất cả' || location == _selectedLocation;

          return matchSearch && matchCategory && matchLocation;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm tên công việc, công ty hoặc danh mục...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Ngành nghề',
                            border: OutlineInputBorder(),
                          ),
                          items: categories
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value ?? 'Tất cả';
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedLocation,
                          decoration: const InputDecoration(
                            labelText: 'Địa điểm',
                            border: OutlineInputBorder(),
                          ),
                          items: locations
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLocation = value ?? 'Tất cả';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: filteredDocs.isEmpty
                  ? const Center(child: Text('Không tìm thấy tin tuyển dụng'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredDocs.length,
                      itemBuilder: (_, i) {
                        final data =
                            filteredDocs[i].data() as Map<String, dynamic>;

                        final jobId = filteredDocs[i].id;

                        return Card(
                          child: ListTile(
                            title: Text(data['title'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['company']} • ${data['category']}',
                                ),
                                Text(
                                  data['location'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: Text(
                                      'Bạn có chắc muốn xóa tin "${data['title']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Xóa',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(jobId)
                                      .delete();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã xóa tin tuyển dụng'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Reports Tab ───────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final notifService = NotificationService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: reportService.getAllReports(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snap.data!;
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có báo cáo nào',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final pendingCount = reports
            .where((r) => r['status'] == 'pending')
            .length;

        return Column(
          children: [
            if (pendingCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount báo cáo đang chờ xử lý',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (_, i) {
                  final r = reports[i];
                  final status = r['status'] ?? 'pending';
                  final isPending = status == 'pending';
                  final createdAt =
                      (r['createdAt'] as dynamic)
                          ?.toDate()
                          .toString()
                          .substring(0, 10) ??
                      '';
                  final reporterId = r['reporterId'] ?? '';
                  final jobId = r['jobId'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isPending
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                                child: Icon(
                                  isPending ? Icons.flag : Icons.check,
                                  color: isPending ? Colors.red : Colors.green,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['jobTitle'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Lý do: ${r['reason']}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      'Ngày báo cáo: $createdAt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? Colors.orange.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPending
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                child: Text(
                                  isPending ? 'Chờ xử lý' : 'Đã xử lý',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPending
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          if (reporterId.isNotEmpty)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(reporterId)
                                  .get(),
                              builder: (context, userSnap) {
                                final userData =
                                    userSnap.data?.data()
                                        as Map<String, dynamic>?;
                                final reporterName =
                                    userData?['fullName'] ?? 'Đang tải...';
                                final reporterEmail = userData?['email'] ?? '';
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Báo cáo bởi: $reporterName${reporterEmail.isNotEmpty ? ' ($reporterEmail)' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 10),

                          if (isPending)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Đã xử lý',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.green,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await reportService.resolveReport(
                                            r['id'],
                                          );
                                          if (reporterId.isNotEmpty) {
                                            await notifService.sendNotification(
                                              toUserId: reporterId,
                                              title: 'Báo cáo đã được xử lý',
                                              body:
                                                  'Báo cáo của bạn về tin "${r['jobTitle']}" đã được admin xem xét và xử lý.',
                                              type: 'general',
                                            );
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Đã đánh dấu xử lý',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Xóa tin',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                'Xác nhận xóa tin',
                                              ),
                                              content: Text(
                                                'Xóa tin "${r['jobTitle']}" và đánh dấu báo cáo đã xử lý?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Xóa',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;

                                          if (jobId.isNotEmpty) {
                                            await FirebaseFirestore.instance
                                                .collection('jobs')
                                                .doc(jobId)
                                                .delete();
                                          }

                                          await reportService.resolveReport(
                                            r['id'],
                                          );

                                          if (reporterId.isNotEmpty) {
                                            await notifService.sendNotification(
                                              toUserId: reporterId,
                                              title: 'Báo cáo đã được xử lý',
                                              body:
                                                  'Tin tuyển dụng "${r['jobTitle']}" bạn báo cáo đã bị gỡ khỏi hệ thống.',
                                              type: 'general',
                                            );
                                          }

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Đã xóa tin và xử lý báo cáo',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Xóa báo cáo',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await reportService.deleteReport(r['id']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã xóa báo cáo'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Xóa báo cáo',
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                                onPressed: () async {
                                  await reportService.deleteReport(r['id']);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã xóa báo cáo'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
