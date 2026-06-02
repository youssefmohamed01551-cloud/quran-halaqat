import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../dashboard/presentation/home_shell.dart';
import 'sign_in_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = ref.watch(supabaseProvider).auth.currentSession;

    return authState.when(
      data: (_) {
        final currentSession = ref.watch(supabaseProvider).auth.currentSession;
        return currentSession == null ? const SignInPage() : const HomeShell();
      },
      loading: () {
        if (session != null) return const HomeShell();
        return const _Splash();
      },
      error: (_, __) => const SignInPage(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
