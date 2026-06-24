import 'package:flutter/material.dart';
import '../candidate/cv_viewer_screen.dart';


class CandidateProfileViewScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String candidateName;

  const CandidateProfileViewScreen({
    super.key,
    required this.userData,
    required this.candidateName,
  });

  @override
  Widget build(BuildContext context) {
    final email = userData['email'] ?? '';
    final phone = userData['phone'] ?? '';
    final bio = userData['bio'] ?? '';
    final skills = userData['skills'] ?? '';
    final experience = userData['experience'] ?? '';
    final cvUrl = userData['cvUrl'] as String?;
    final cvName = userData['cvName'] as String?;
    final hasCv = cvUrl != null && cvName != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(candidateName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + tên + email
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFF1E88E5),
                    child: Text(
                      candidateName.isNotEmpty
                          ? candidateName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(candidateName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(email,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(phone,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Giới thiệu
            if (bio.isNotEmpty) ...[
              _sectionTitle('Giới thiệu bản thân'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(bio, style: const TextStyle(height: 1.6)),
              ),
              const SizedBox(height: 20),
            ],

            // Kỹ năng
            if (skills.isNotEmpty) ...[
              _sectionTitle('Kỹ năng'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .toString()
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .map((s) => Chip(
                          label: Text(s,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E88E5))),
                          backgroundColor:
                              const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          side: const BorderSide(
                              color: Color(0xFF1E88E5), width: 0.5),
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Kinh nghiệm
            if (experience.isNotEmpty) ...[
              _sectionTitle('Kinh nghiệm làm việc'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(experience,
                    style: const TextStyle(height: 1.6)),
              ),
              const SizedBox(height: 20),
            ],

            // CV
            _sectionTitle('CV / Hồ sơ'),
            const SizedBox(height: 8),
            hasCv
                ? InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CvViewerScreen(
                          cvUrl: cvUrl!,
                          cvName: cvName!,
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description,
                              color: Colors.green, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cvName!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text('Nhấn để xem CV',
                                    style: TextStyle(
                                        color: Colors.green, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new,
                              color: Color(0xFF1E88E5)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined,
                            color: Colors.grey.shade400, size: 32),
                        const SizedBox(width: 12),
                        Text('Ứng viên chưa tải lên CV',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
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
}