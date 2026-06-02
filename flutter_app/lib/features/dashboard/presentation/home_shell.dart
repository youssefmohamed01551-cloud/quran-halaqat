import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_profile.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../memorization/presentation/memorization_page.dart';
import '../../reports/presentation/student_report_page.dart';
import '../../students/presentation/student_list_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final profileState = ref.watch(currentProfileProvider);

    return profileState.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final destinations = _destinationsFor(profile.role, strings);
        final pages = _pagesFor(profile.role);
        final safeIndex = _index.clamp(0, pages.length - 1);

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Scaffold(
              appBar: AppBar(
                title: Text(strings.dashboard),
                actions: [
                  Tooltip(
                    message: profile.role.labelAr,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Chip(
                        avatar: const Icon(Icons.verified_user_outlined, size: 18),
                        label: Text(profile.fullName),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.signOut,
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.invalidate(currentProfileProvider);
                    },
                    icon: const Icon(Icons.logout_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Row(
                children: [
                  if (wide)
                    NavigationRail(
                      selectedIndex: safeIndex,
                      onDestinationSelected: (value) => setState(() => _index = value),
                      labelType: NavigationRailLabelType.all,
                      destinations: destinations
                          .map(
                            (item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: Text(item.label),
                            ),
                          )
                          .toList(),
                    ),
                  Expanded(child: pages[safeIndex]),
                ],
              ),
              bottomNavigationBar: wide
                  ? null
                  : NavigationBar(
                      selectedIndex: safeIndex,
                      onDestinationSelected: (value) => setState(() => _index = value),
                      destinations: destinations
                          .map(
                            (item) => NavigationDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: item.label,
                            ),
                          )
                          .toList(),
                    ),
            );
          },
        );
      },
      error: (error, _) => Scaffold(
        body: Center(child: Text(error.toString())),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<_Destination> _destinationsFor(UserRole role, AppStrings strings) {
    if (role == UserRole.student || role == UserRole.parent) {
      return [
        _Destination(strings.dashboard, Icons.dashboard_outlined, Icons.dashboard),
        _Destination(strings.reports, Icons.insights_outlined, Icons.insights),
      ];
    }

    return [
      _Destination(strings.dashboard, Icons.dashboard_outlined, Icons.dashboard),
      _Destination(strings.students, Icons.groups_outlined, Icons.groups),
      _Destination(strings.memorization, Icons.menu_book_outlined, Icons.menu_book),
      _Destination(strings.attendance, Icons.fact_check_outlined, Icons.fact_check),
      _Destination(strings.reports, Icons.insights_outlined, Icons.insights),
    ];
  }

  List<Widget> _pagesFor(UserRole role) {
    if (role == UserRole.student || role == UserRole.parent) {
      return const [
        _DashboardOverview(readOnly: true),
        StudentReportPage(),
      ];
    }

    return const [
      _DashboardOverview(readOnly: false),
      StudentListPage(),
      MemorizationPage(),
      AttendancePage(),
      StudentReportPage(),
    ];
  }
}

class _DashboardOverview extends ConsumerWidget {
  const _DashboardOverview({required this.readOnly});

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: 'طلاب نشطون',
              value: readOnly ? '1' : '248',
              icon: Icons.groups_rounded,
              color: colorScheme.primary,
            ),
            _MetricCard(
              title: 'متوسط الإتقان',
              value: '86%',
              icon: Icons.trending_up_rounded,
              color: Colors.teal,
            ),
            _MetricCard(
              title: 'نسبة الحضور',
              value: '92%',
              icon: Icons.event_available_rounded,
              color: Colors.indigo,
            ),
            _MetricCard(
              title: 'نقاط التحفيز',
              value: '12.4K',
              icon: Icons.workspace_premium_rounded,
              color: Colors.amber.shade800,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile == null ? 'مرحبا' : 'مرحبا ${profile.fullName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(label: readOnly ? 'عرض فقط' : 'تشغيل'),
                    const _StatusChip(label: 'Realtime'),
                    const _StatusChip(label: 'RLS'),
                    const _StatusChip(label: 'PDF'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
