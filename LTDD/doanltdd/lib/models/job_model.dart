class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String description;
  final String category;
  final String employerId;
  final DateTime createdAt;
  // FIX #3: Thêm 2 field còn thiếu để filter nâng cao hoạt động
  final String? experience;
  final String? contractType;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.description,
    required this.category,
    required this.employerId,
    required this.createdAt,
    this.experience,
    this.contractType,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      salary: map['salary'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      employerId: map['employerId'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      experience: map['experience'],
      contractType: map['contractType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'description': description,
      'category': category,
      'employerId': employerId,
      'createdAt': createdAt,
      if (experience != null) 'experience': experience,
      if (contractType != null) 'contractType': contractType,
    };
  }
}