enum UserRole {
  superAdmin,
  admin,
  supervisor,
  teacher,
  parent,
  student;

  static UserRole fromJson(String value) {
    return switch (value) {
      'super_admin' => UserRole.superAdmin,
      'admin' => UserRole.admin,
      'supervisor' => UserRole.supervisor,
      'teacher' => UserRole.teacher,
      'parent' => UserRole.parent,
      'student' => UserRole.student,
      _ => throw ArgumentError('Unknown role: $value'),
    };
  }

  String get labelAr => switch (this) {
        UserRole.superAdmin => 'مدير أعلى',
        UserRole.admin => 'إدارة',
        UserRole.supervisor => 'مشرف',
        UserRole.teacher => 'معلم',
        UserRole.parent => 'ولي أمر',
        UserRole.student => 'طالب',
      };
}

class AppProfile {
  const AppProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.isActive,
    this.organizationId,
    this.avatarUrl,
    this.email,
  });

  final String id;
  final String? organizationId;
  final UserRole role;
  final String fullName;
  final String? avatarUrl;
  final String? email;
  final bool isActive;

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      role: UserRole.fromJson(json['role'] as String),
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
