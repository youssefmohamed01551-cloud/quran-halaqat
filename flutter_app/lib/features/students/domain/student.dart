class Student {
  const Student({
    required this.id,
    required this.fullName,
    required this.level,
    required this.status,
    this.avatarUrl,
    this.birthDate,
    this.circleName,
  });

  final String id;
  final String fullName;
  final String level;
  final String status;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? circleName;

  factory Student.fromJson(Map<String, dynamic> json) {
    final circleStudents = json['circle_students'];
    String? circleName;
    if (circleStudents is List && circleStudents.isNotEmpty) {
      final circle = circleStudents.first['circles'];
      if (circle is Map<String, dynamic>) circleName = circle['name'] as String?;
    }

    return Student(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      level: json['level'] as String,
      status: json['status'] as String,
      avatarUrl: json['avatar_url'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.tryParse(json['birth_date'] as String),
      circleName: circleName,
    );
  }
}
