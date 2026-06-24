class JobFilter {
  final String? experience;
  final String? contractType;

  const JobFilter({
    this.experience,
    this.contractType,
  });

  bool get isEmpty => experience == null && contractType == null;

  static const List<String> experiences = [
    'Không yêu cầu',
    'Dưới 1 năm',
    '1-2 năm',
    '3-5 năm',
    '5+ năm',
  ];

  static const List<String> contractTypes = [
    'Toàn thời gian',
    'Bán thời gian',
    'Thực tập',
    'Remote',
    'Freelance',
  ];

  /// Kiểm tra job có khớp filter không (filter phía client)
  bool matches({
    String? jobExperience,
    String? jobContractType,
  }) {
    if (experience != null &&
        jobExperience != null &&
        jobExperience != experience) {
      return false;
    }
    if (contractType != null &&
        jobContractType != null &&
        jobContractType != contractType) {
      return false;
    }
    return true;
  }

  JobFilter copyWith({
    String? experience,
    String? contractType,
  }) {
    return JobFilter(
      experience: experience ?? this.experience,
      contractType: contractType ?? this.contractType,
    );
  }
}