class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'candidate', 'employer', 'admin'
  final String? photoUrl;
  final String? phone;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.photoUrl,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'candidate',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'photoUrl': photoUrl,
      'phone': phone,
    };
  }
}