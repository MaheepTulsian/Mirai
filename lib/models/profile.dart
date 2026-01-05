class UserProfile {
  final String graduatingYear;
  final String collegeName;
  final String? collegeId;

  UserProfile({
    required this.graduatingYear,
    required this.collegeName,
    this.collegeId,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      graduatingYear: data['graduatingYear'] ?? '',
      collegeName: data['collegeName'] ?? '',
      collegeId: data['collegeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'graduatingYear': graduatingYear,
      'collegeName': collegeName,
      'collegeId': collegeId,
    };
  }
}

class College {
  final String collegeId;
  final String name;

  College({
    required this.collegeId,
    required this.name,
  });

  factory College.fromFirestore(Map<String, dynamic> data, String id) {
    return College(
      collegeId: data['collegeId'] ?? id,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collegeId': collegeId,
      'name': name,
    };
  }
}
