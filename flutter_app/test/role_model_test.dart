import 'package:flutter_test/flutter_test.dart';
import 'package:quran_halaqat/features/auth/domain/app_profile.dart';

void main() {
  test('parses super admin role from database enum', () {
    expect(UserRole.fromJson('super_admin'), UserRole.superAdmin);
  });
}
