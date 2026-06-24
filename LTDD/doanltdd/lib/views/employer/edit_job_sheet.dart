import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../viewmodels/job_viewmodel.dart';

class EditJobSheet extends StatefulWidget {
  final JobModel job;
  const EditJobSheet({super.key, required this.job});

  @override
  State<EditJobSheet> createState() => _EditJobSheetState();
}

class _EditJobSheetState extends State<EditJobSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  // FIX: Thêm experience và contractType vào form chỉnh sửa
  String? _experience;
  String? _contractType;
  bool _loading = false;

  final List<String> _categories = [
    'IT', 'Marketing', 'Kế toán', 'Kinh doanh', 'Thiết kế', 'Khác'
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.job.title);
    _companyCtrl = TextEditingController(text: widget.job.company);
    _locationCtrl = TextEditingController(text: widget.job.location);
    _salaryCtrl = TextEditingController(text: widget.job.salary);
    _descCtrl = TextEditingController(text: widget.job.description);
    _category = _categories.contains(widget.job.category)
        ? widget.job.category
        : 'IT';
    _experience = widget.job.experience;
    _contractType = widget.job.contractType;
  }

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
    final jobVM = context.read<JobViewModel>();
    await jobVM.updateJob(widget.job.id, {
      'title': _titleCtrl.text.trim(),
      'company': _companyCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'salary': _salaryCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      if (_experience != null) 'experience': _experience,
      if (_contractType != null) 'contractType': _contractType,
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật tin tuyển dụng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa tin tuyển dụng',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên vị trí *',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên vị trí'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên công ty *',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên công ty'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập địa điểm'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mức lương (VD: 10-15 triệu) *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập mức lương'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Ngành nghề',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              // FIX: Thêm dropdown Experience
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
              // FIX: Thêm dropdown ContractType
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
                  labelText: 'Mô tả công việc *',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập mô tả công việc'
                    : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu thay đổi'),
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}