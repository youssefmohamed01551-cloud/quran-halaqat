import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static const delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get appName => isArabic ? 'منصة الحلقات' : 'Halaqat Platform';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get dashboard => isArabic ? 'لوحة المتابعة' : 'Dashboard';
  String get students => isArabic ? 'الطلاب' : 'Students';
  String get memorization => isArabic ? 'الحفظ' : 'Memorization';
  String get attendance => isArabic ? 'الحضور' : 'Attendance';
  String get reports => isArabic ? 'التقارير' : 'Reports';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get search => isArabic ? 'بحث' : 'Search';
  String get signOut => isArabic ? 'خروج' : 'Sign out';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppStrings.supportedLocales.any((item) => item.languageCode == locale.languageCode);
  }

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
