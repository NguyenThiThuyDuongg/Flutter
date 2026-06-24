import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/cv_service.dart';
import 'cv_viewer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvService = CvService();

  bool _loading = false;
  bool _editing = false;
  bool _cvLoading = false;

  String? _cvUrl;
  String? _cvName;
  String? _cvPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = context.read<AuthViewModel>().userModel?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null) {
      _nameCtrl.text = data['fullName'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _bioCtrl.text = data['bio'] ?? '';
      _skillsCtrl.text = data['skills'] ?? '';
      _expCtrl.text = data['experience'] ?? '';
      _cvUrl = data['cvUrl'];
      _cvName = data['cvName'];
      _cvPath = data['cvPath'];
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final uid = context.read<AuthViewModel>().userModel?.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fullName': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'skills': _skillsCtrl.text.trim(),
      'experience': _expCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _loading = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
    );
  }

  Future<void> _pickAndUploadCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, // luôn lấy bytes, dùng được cả Web lẫn Mobile
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final fileName = file.name;
    final bytes = file.bytes;

    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đọc được file, thử lại')),
      );
      return;
    }

    if (!mounted) return;
    final uid = context.read<AuthViewModel>().userModel!.uid;
    setState(() => _cvLoading = true);

    try {
      final url = await _cvService.uploadCvBytes(uid, bytes, fileName);
      if (!mounted) return;
      // Reload cvPath từ Firestore sau upload
      final info = await _cvService.getCvInfo(uid);
      if (!mounted) return;
      setState(() {
        _cvUrl = url;
        _cvName = fileName;
        _cvPath = info['cvPath'];
        _cvLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload CV thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cvLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCv() async {
    if (_cvPath == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa CV'),
        content: const Text('Bạn có chắc muốn xóa CV này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final uid = context.read<AuthViewModel>().userModel!.uid;
    final cvPath = _cvPath!;
    setState(() => _cvLoading = true);

    await _cvService.deleteCv(uid, cvPath);

    if (!mounted) return;
    setState(() {
      _cvUrl = null;
      _cvName = null;
      _cvPath = null;
      _cvLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa CV')),
    );
  }

  void _openCv() {
    if (_cvUrl == null || _cvName == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CvViewerScreen(
          cvUrl: _cvUrl!,
          cvName: _cvName!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            )
          else
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Hủy',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF1E88E5),
                      child: Text(
                        (user?.fullName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(user?.email ?? '',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Ứng viên',
                          style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('Thông tin cá nhân'),
              const SizedBox(height: 12),
              _buildField(
                controller: _nameCtrl,
                label: 'Họ và tên',
                icon: Icons.person,
                enabled: _editing,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập họ tên'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _phoneCtrl,
                label: 'Số điện thoại',
                icon: Icons.phone,
                enabled: _editing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _bioCtrl,
                label: 'Giới thiệu bản thân',
                icon: Icons.info_outline,
                enabled: _editing,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _sectionTitle('Kỹ năng & Kinh nghiệm'),
              const SizedBox(height: 12),
              _buildField(
                controller: _skillsCtrl,
                label: 'Kỹ năng (VD: Flutter, Firebase, Java...)',
                icon: Icons.star_outline,
                enabled: _editing,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _expCtrl,
                label: 'Kinh nghiệm làm việc',
                icon: Icons.work_history_outlined,
                enabled: _editing,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              _sectionTitle('CV / Hồ sơ đính kèm'),
              const SizedBox(height: 12),
              _buildCvSection(),
              const SizedBox(height: 28),
              if (_editing)
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu hồ sơ'),
                        onPressed: _save,
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCvSection() {
    if (_cvLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cvUrl != null && _cvName != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.description, color: Colors.green, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cvName!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('Đã tải lên (Cloudinary)',
                      style:
                          TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  color: Color(0xFF1E88E5)),
              tooltip: 'Xem CV',
              onPressed: _openCv,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa CV',
              onPressed: _deleteCv,
            ),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text('Tải lên CV (PDF / Word)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: Color(0xFF1E88E5)),
      ),
      onPressed: _pickAndUploadCv,
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: !enabled,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}