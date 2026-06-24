import 'package:flutter/material.dart';
import '../../models/filter_model.dart';

class FilterSheet extends StatefulWidget {
  final JobFilter current;
  const FilterSheet({super.key, required this.current});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _experience;
  String? _contractType;

  @override
  void initState() {
    super.initState();
    _experience = widget.current.experience;
    _contractType = widget.current.contractType;
  }

  int get _activeCount =>
      (_experience != null ? 1 : 0) + (_contractType != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Bộ lọc nâng cao',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_activeCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _experience = null;
                    _contractType = null;
                  }),
                  child: const Text('Xóa tất cả',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection(
                  title: 'Kinh nghiệm',
                  icon: Icons.work_history_outlined,
                  options: JobFilter.experiences,
                  selected: _experience,
                  onSelect: (v) =>
                      setState(() => _experience = _experience == v ? null : v),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Loại hợp đồng',
                  icon: Icons.description_outlined,
                  options: JobFilter.contractTypes,
                  selected: _contractType,
                  onSelect: (v) => setState(
                      () => _contractType = _contractType == v ? null : v),
                ),
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                JobFilter(
                  experience: _experience,
                  contractType: _contractType,
                ),
              ),
              child: Text(
                _activeCount > 0
                    ? 'Áp dụng ($_activeCount bộ lọc)'
                    : 'Áp dụng',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((opt) => ChoiceChip(
                    label: Text(opt),
                    selected: selected == opt,
                    selectedColor:
                        const Color(0xFF1E88E5).withValues(alpha: 0.15),
                    side: BorderSide(
                      color: selected == opt
                          ? const Color(0xFF1E88E5)
                          : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: selected == opt
                          ? const Color(0xFF1E88E5)
                          : Colors.black87,
                      fontWeight: selected == opt
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    onSelected: (_) => onSelect(opt),
                  ))
              .toList(),
        ),
      ],
    );
  }
}